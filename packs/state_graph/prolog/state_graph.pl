/*  PrologAI — Causalontology State-Graph Exploration  (WP-402, Layer 377)

    The technique that beat every frontier language model on ARC-AGI-3 was not a
    bigger model — it was systematic, graph-structured exploration. The strongest
    non-language agents (the "graph-based exploration" paper's agent, third on the
    public leaderboard, and the developer-preview winners) all did the same thing:
    keep a directed graph of the states they have seen and the actions they have
    tried, and always move toward the nearest place they have not fully explored.

    This pack is that technique, as glass-box PrologAI. It builds a directed graph
    whose nodes are frame hashes (a canonical id of the exact grid) and whose edges
    are observed transitions state -> action -> next-state. It marks every tried
    (state, action) pair as tested, and marks an action that produced no change as
    dead so it is never wasted again. Its action selection is the winning
    hierarchical rule:

      1. If the current state has an untested, non-dead action, take it
         (probe here, in the caller's priority order — salient clicks first).
      2. Else take the first step on the SHORTEST path (breadth-first over the
         known graph) to the nearest reachable state that still has an untested
         action (go to the frontier).
      3. Else fail, so the caller can fall back (e.g. to least-tried or random).

    The graph persists across attempts of the same game, so a later run carries
    forward everything the earlier run mapped — the carry-forward the benchmark
    rewards.

    Predicates:
      state_graph_reset/0            -- forget the whole graph
      state_graph_signature/2        -- +Frame, -Signature  (a canonical id of the grid)
      state_graph_note/3             -- +FromSig, +Action, +ToSig  (record a transition)
      state_graph_node/1             -- ?Signature
      state_graph_edge/3             -- ?FromSig, ?Action, ?ToSig
      state_graph_tested/2           -- ?Signature, ?Action
      state_graph_dead/2             -- ?Signature, ?Action   (produced no state change)
      state_graph_untested/3         -- +Signature, +Actions, -Action  (first untested here)
      state_graph_has_untested/2     -- +Signature, +Actions
      state_graph_toward_frontier/3  -- +Signature, +Actions, -FirstAction
      state_graph_choose/3           -- +Signature, +Actions, -Action  (hierarchical rule)
      state_graph_stats/1            -- -stats(Nodes, Edges, Tested, Dead)
      state_graph_stats_for/2        -- +Prefix, -stats(Nodes, Edges, Tested, Dead)

    One graph store serves many games at once. A caller keeps games apart by
    prefixing every signature with a game id (for example "ls20::" before the
    frame term), so one game's states can never be confused with another's — the
    breadth-first frontier search only ever reaches nodes sharing the current
    node's prefix, because no edge ever crosses from one game's states to
    another's. state_graph_stats_for/2 reports the size of just one game's subgraph by
    counting only the nodes and transitions whose source signature carries the
    given prefix.
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(state_graph, [
    % state_graph_reset/0: forget the whole exploration graph.
    state_graph_reset/0,
    % state_graph_signature/2: a canonical id of a frame.
    state_graph_signature/2,
    % state_graph_note/3: record a state-action-state transition.
    state_graph_note/3,
    % state_graph_node/1: query the known states.
    state_graph_node/1,
    % state_graph_edge/3: query the known transitions.
    state_graph_edge/3,
    % state_graph_tested/2: query the tried state-action pairs.
    state_graph_tested/2,
    % state_graph_dead/2: query the no-change state-action pairs.
    state_graph_dead/2,
    % state_graph_untested/3: the first untested action in a state.
    state_graph_untested/3,
    % state_graph_has_untested/2: the state has an untested action.
    state_graph_has_untested/2,
    % state_graph_toward_frontier/3: the first step toward the nearest frontier.
    state_graph_toward_frontier/3,
    % state_graph_choose/3: the hierarchical graph-informed action choice.
    state_graph_choose/3,
    % state_graph_stats/1: a summary of the graph's size.
    state_graph_stats/1,
    % state_graph_stats_for/2: a summary of one prefixed subgraph's size.
    state_graph_stats_for/2
]).

% Import list helpers.
:- use_module(library(lists), [member/2, append/3]).
% Import aggregation for the statistics.
:- use_module(library(aggregate), [aggregate_all/3]).

% ---------------------------------------------------------------------------
% The graph
% ---------------------------------------------------------------------------

% state_graph_node_/1: one fact per known state signature.
:- dynamic state_graph_node_/1.
% state_graph_edge_/3: (FromSig, Action, ToSig) — an observed transition.
:- dynamic state_graph_edge_/3.
% state_graph_tested_/2: (Sig, Action) — an action already tried from a state.
:- dynamic state_graph_tested_/2.
% state_graph_dead_/2: (Sig, Action) — an action that produced no state change.
:- dynamic state_graph_dead_/2.

% Define state_graph_reset: forget the whole graph.
state_graph_reset :-
    % Drop the nodes.
    retractall(state_graph_node_(_)),
    % Drop the edges.
    retractall(state_graph_edge_(_, _, _)),
    % Drop the tested markers.
    retractall(state_graph_tested_(_, _)),
    % Drop the dead markers.
    retractall(state_graph_dead_(_, _)).

% Define state_graph_signature: a canonical id of a frame (the exact grid distinguishes
% states, so an object at a new position is a new node).
state_graph_signature(Frame, Signature) :-
    % The grid term rendered as an atom is a unique, readable identifier.
    term_to_atom(Frame, Signature).

% Define state_graph_note: record one observed transition and mark it tested (and dead
% when the state did not change).
state_graph_note(FromSig, Action, ToSig) :-
    % Remember both endpoints as nodes.
    state_graph_add_node(FromSig),
    % The successor too.
    state_graph_add_node(ToSig),
    % Record the edge if it is new.
    ( state_graph_edge_(FromSig, Action, ToSig) -> true ; assertz(state_graph_edge_(FromSig, Action, ToSig)) ),
    % Mark the action tested from this state.
    ( state_graph_tested_(FromSig, Action) -> true ; assertz(state_graph_tested_(FromSig, Action)) ),
    % A transition that returns to the same state is a dead (no-change) action.
    ( FromSig == ToSig
    % Mark it dead so it is never wasted again.
    ->  ( state_graph_dead_(FromSig, Action) -> true ; assertz(state_graph_dead_(FromSig, Action)) )
    % A real change is not dead.
    ;   true
    ).

% state_graph_add_node(+Sig): remember a state once.
state_graph_add_node(Sig) :-
    % Only if not already known.
    ( state_graph_node_(Sig) -> true ; assertz(state_graph_node_(Sig)) ).

% Define state_graph_node: query the known states.
state_graph_node(Sig) :-
    % Read the store.
    state_graph_node_(Sig).

% Define state_graph_edge: query the known transitions.
state_graph_edge(From, Action, To) :-
    % Read the store.
    state_graph_edge_(From, Action, To).

% Define state_graph_tested: query the tried state-action pairs.
state_graph_tested(Sig, Action) :-
    % Read the store.
    state_graph_tested_(Sig, Action).

% Define state_graph_dead: query the no-change state-action pairs.
state_graph_dead(Sig, Action) :-
    % Read the store.
    state_graph_dead_(Sig, Action).

% ---------------------------------------------------------------------------
% The exploration frontier
% ---------------------------------------------------------------------------

% Define state_graph_untested: the first untested, non-dead action in a state, taking
% the caller's list order as the priority (salient actions first).
state_graph_untested(Sig, Actions, Action) :-
    % The first afforded action that has neither been tested nor found dead.
    member(Action, Actions),
    % Not already tried here.
    \+ state_graph_tested_(Sig, Action),
    % Not known to do nothing here.
    \+ state_graph_dead_(Sig, Action),
    % Commit to the first such action.
    !.

% Define state_graph_has_untested: the state has some untested, non-dead action.
state_graph_has_untested(Sig, Actions) :-
    % There is at least one.
    state_graph_untested(Sig, Actions, _).

% Define state_graph_toward_frontier: the first step on the shortest path to the nearest
% reachable state that still has an untested action.
state_graph_toward_frontier(Sig, Actions, FirstAction) :-
    % Seed the breadth-first search with the current state's successors, each
    % tagged by the first action taken to leave the current state.
    findall(q(To, A), state_graph_edge_(Sig, A, To), Seed),
    % A node-expansion budget so a very large carried-forward graph cannot make the
    % frontier search unbounded; on hitting it the search simply fails and the
    % caller falls through to another rule.
    state_graph_frontier_budget(Budget),
    % Search outward, never revisiting the start.
    state_graph_bfs(Seed, [Sig], Actions, Budget, FirstAction).

% state_graph_frontier_budget(-N): the maximum nodes the frontier search expands in one
% step. The graph grows all game (and across attempts), and every expansion does
% a memberchk over the visited set of whole-grid signature atoms, so an unbounded
% (or very loose) budget makes each late-game step re-walk thousands of nodes —
% the cost that helped stall the last sweep. A tight bound keeps per-step frontier
% cost constant no matter how large the map gets: the nearest unexplored state is
% almost always a few edges away, so this still finds it, and when it genuinely
% cannot within the budget the search fails and the caller falls back to another
% exploration rule rather than paying an ever-growing search on every step.
state_graph_frontier_budget(256).

% state_graph_bfs(+Queue, +Visited, +Actions, +Budget, -FirstAction): breadth-first to a
% frontier. The queue holds q(Node, FirstAction) — the node and the first action
% that led toward it. The first dequeued node that is a frontier yields its first
% action. Budget counts down per node expanded; at zero the search gives up.
state_graph_bfs(_, _, _, 0, _) :- !, fail.
% The recursive clause dequeues the front node and either reports it as the
% frontier or expands it.
state_graph_bfs([q(Node, FirstAction) | Rest], Visited, Actions, Budget, Result) :-
    % Test whether the dequeued node is fresh and still has an untested action.
    (   \+ memberchk(Node, Visited), state_graph_has_untested(Node, Actions)
    % This reachable node still has an untested action: go toward it.
    ->  Result = FirstAction
    % Already visited: skip it.
    ;   memberchk(Node, Visited)
    % Drop the seen node and carry on with the rest of the queue.
    ->  state_graph_bfs(Rest, Visited, Actions, Budget, Result)
    % New but fully-tested node: enqueue its successors, keeping the first action.
    ;   findall(q(To, FirstAction), state_graph_edge_(Node, _A, To), Succ),
        % Append those successors to the back of the queue.
        append(Rest, Succ, Queue),
        % Spend one unit of the expansion budget.
        Budget1 is Budget - 1,
        % Recurse with this node now marked visited.
        state_graph_bfs(Queue, [Node | Visited], Actions, Budget1, Result)
    ).

% ---------------------------------------------------------------------------
% The hierarchical choice (the winning rule)
% ---------------------------------------------------------------------------

% Define state_graph_choose: probe an untested action here, else head to the frontier.
state_graph_choose(Sig, Actions, Action) :-
    % First, an untested action in the current state.
    (   state_graph_untested(Sig, Actions, A)
    % Take it.
    ->  Action = A
    % Otherwise the first step toward the nearest unexplored state.
    ;   state_graph_toward_frontier(Sig, Actions, A)
    % Take that step.
    ->  Action = A
    % Nothing left to explore from here: let the caller fall back.
    ;   fail
    ).

% ---------------------------------------------------------------------------
% Statistics
% ---------------------------------------------------------------------------

% Define state_graph_stats: a summary of the graph's size.
state_graph_stats(stats(Nodes, Edges, Tested, Dead)) :-
    % Count the nodes.
    aggregate_all(count, state_graph_node_(_), Nodes),
    % Count the edges.
    aggregate_all(count, state_graph_edge_(_, _, _), Edges),
    % Count the tested pairs.
    aggregate_all(count, state_graph_tested_(_, _), Tested),
    % Count the dead pairs.
    aggregate_all(count, state_graph_dead_(_, _), Dead).

% Define state_graph_stats_for: a summary of just the subgraph whose signatures carry the
% given prefix, so one game's map can be read without another game's bleeding in.
state_graph_stats_for(Prefix, stats(Nodes, Edges, Tested, Dead)) :-
    % Count the nodes whose signature begins with the prefix.
    aggregate_all(count, ( state_graph_node_(S), state_graph_has_prefix(S, Prefix) ), Nodes),
    % Count the edges leaving a node with the prefix.
    aggregate_all(count, ( state_graph_edge_(S, _, _), state_graph_has_prefix(S, Prefix) ), Edges),
    % Count the tested pairs at a node with the prefix.
    aggregate_all(count, ( state_graph_tested_(S, _), state_graph_has_prefix(S, Prefix) ), Tested),
    % Count the dead pairs at a node with the prefix.
    aggregate_all(count, ( state_graph_dead_(S, _), state_graph_has_prefix(S, Prefix) ), Dead).

% state_graph_has_prefix(+Signature, +Prefix): the signature begins with the prefix.
state_graph_has_prefix(Signature, Prefix) :-
    % A leading match of the whole prefix.
    sub_atom(Signature, 0, _, _, Prefix).
