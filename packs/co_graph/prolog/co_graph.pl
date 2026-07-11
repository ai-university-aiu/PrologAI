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
      cg_reset/0            -- forget the whole graph
      cg_signature/2        -- +Frame, -Signature  (a canonical id of the grid)
      cg_note/3             -- +FromSig, +Action, +ToSig  (record a transition)
      cg_node/1             -- ?Signature
      cg_edge/3             -- ?FromSig, ?Action, ?ToSig
      cg_tested/2           -- ?Signature, ?Action
      cg_dead/2             -- ?Signature, ?Action   (produced no state change)
      cg_untested/3         -- +Signature, +Actions, -Action  (first untested here)
      cg_has_untested/2     -- +Signature, +Actions
      cg_toward_frontier/3  -- +Signature, +Actions, -FirstAction
      cg_choose/3           -- +Signature, +Actions, -Action  (hierarchical rule)
      cg_stats/1            -- -stats(Nodes, Edges, Tested, Dead)
      cg_stats_for/2        -- +Prefix, -stats(Nodes, Edges, Tested, Dead)

    One graph store serves many games at once. A caller keeps games apart by
    prefixing every signature with a game id (for example "ls20::" before the
    frame term), so one game's states can never be confused with another's — the
    breadth-first frontier search only ever reaches nodes sharing the current
    node's prefix, because no edge ever crosses from one game's states to
    another's. cg_stats_for/2 reports the size of just one game's subgraph by
    counting only the nodes and transitions whose source signature carries the
    given prefix.
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(co_graph, [
    % cg_reset/0: forget the whole exploration graph.
    cg_reset/0,
    % cg_signature/2: a canonical id of a frame.
    cg_signature/2,
    % cg_note/3: record a state-action-state transition.
    cg_note/3,
    % cg_node/1: query the known states.
    cg_node/1,
    % cg_edge/3: query the known transitions.
    cg_edge/3,
    % cg_tested/2: query the tried state-action pairs.
    cg_tested/2,
    % cg_dead/2: query the no-change state-action pairs.
    cg_dead/2,
    % cg_untested/3: the first untested action in a state.
    cg_untested/3,
    % cg_has_untested/2: the state has an untested action.
    cg_has_untested/2,
    % cg_toward_frontier/3: the first step toward the nearest frontier.
    cg_toward_frontier/3,
    % cg_choose/3: the hierarchical graph-informed action choice.
    cg_choose/3,
    % cg_stats/1: a summary of the graph's size.
    cg_stats/1,
    % cg_stats_for/2: a summary of one prefixed subgraph's size.
    cg_stats_for/2
]).

% Import list helpers.
:- use_module(library(lists), [member/2, append/3]).
% Import aggregation for the statistics.
:- use_module(library(aggregate), [aggregate_all/3]).

% ---------------------------------------------------------------------------
% The graph
% ---------------------------------------------------------------------------

% cg_node_/1: one fact per known state signature.
:- dynamic cg_node_/1.
% cg_edge_/3: (FromSig, Action, ToSig) — an observed transition.
:- dynamic cg_edge_/3.
% cg_tested_/2: (Sig, Action) — an action already tried from a state.
:- dynamic cg_tested_/2.
% cg_dead_/2: (Sig, Action) — an action that produced no state change.
:- dynamic cg_dead_/2.

% Define cg_reset: forget the whole graph.
cg_reset :-
    % Drop the nodes.
    retractall(cg_node_(_)),
    % Drop the edges.
    retractall(cg_edge_(_, _, _)),
    % Drop the tested markers.
    retractall(cg_tested_(_, _)),
    % Drop the dead markers.
    retractall(cg_dead_(_, _)).

% Define cg_signature: a canonical id of a frame (the exact grid distinguishes
% states, so an object at a new position is a new node).
cg_signature(Frame, Signature) :-
    % The grid term rendered as an atom is a unique, readable identifier.
    term_to_atom(Frame, Signature).

% Define cg_note: record one observed transition and mark it tested (and dead
% when the state did not change).
cg_note(FromSig, Action, ToSig) :-
    % Remember both endpoints as nodes.
    cg_add_node(FromSig),
    % The successor too.
    cg_add_node(ToSig),
    % Record the edge if it is new.
    ( cg_edge_(FromSig, Action, ToSig) -> true ; assertz(cg_edge_(FromSig, Action, ToSig)) ),
    % Mark the action tested from this state.
    ( cg_tested_(FromSig, Action) -> true ; assertz(cg_tested_(FromSig, Action)) ),
    % A transition that returns to the same state is a dead (no-change) action.
    ( FromSig == ToSig
    % Mark it dead so it is never wasted again.
    ->  ( cg_dead_(FromSig, Action) -> true ; assertz(cg_dead_(FromSig, Action)) )
    % A real change is not dead.
    ;   true
    ).

% cg_add_node(+Sig): remember a state once.
cg_add_node(Sig) :-
    % Only if not already known.
    ( cg_node_(Sig) -> true ; assertz(cg_node_(Sig)) ).

% Define cg_node: query the known states.
cg_node(Sig) :-
    % Read the store.
    cg_node_(Sig).

% Define cg_edge: query the known transitions.
cg_edge(From, Action, To) :-
    % Read the store.
    cg_edge_(From, Action, To).

% Define cg_tested: query the tried state-action pairs.
cg_tested(Sig, Action) :-
    % Read the store.
    cg_tested_(Sig, Action).

% Define cg_dead: query the no-change state-action pairs.
cg_dead(Sig, Action) :-
    % Read the store.
    cg_dead_(Sig, Action).

% ---------------------------------------------------------------------------
% The exploration frontier
% ---------------------------------------------------------------------------

% Define cg_untested: the first untested, non-dead action in a state, taking
% the caller's list order as the priority (salient actions first).
cg_untested(Sig, Actions, Action) :-
    % The first afforded action that has neither been tested nor found dead.
    member(Action, Actions),
    % Not already tried here.
    \+ cg_tested_(Sig, Action),
    % Not known to do nothing here.
    \+ cg_dead_(Sig, Action),
    % Commit to the first such action.
    !.

% Define cg_has_untested: the state has some untested, non-dead action.
cg_has_untested(Sig, Actions) :-
    % There is at least one.
    cg_untested(Sig, Actions, _).

% Define cg_toward_frontier: the first step on the shortest path to the nearest
% reachable state that still has an untested action.
cg_toward_frontier(Sig, Actions, FirstAction) :-
    % Seed the breadth-first search with the current state's successors, each
    % tagged by the first action taken to leave the current state.
    findall(q(To, A), cg_edge_(Sig, A, To), Seed),
    % A node-expansion budget so a very large carried-forward graph cannot make the
    % frontier search unbounded; on hitting it the search simply fails and the
    % caller falls through to another rule.
    cg_frontier_budget(Budget),
    % Search outward, never revisiting the start.
    cg_bfs(Seed, [Sig], Actions, Budget, FirstAction).

% cg_frontier_budget(-N): the maximum nodes the frontier search expands.
cg_frontier_budget(4096).

% cg_bfs(+Queue, +Visited, +Actions, +Budget, -FirstAction): breadth-first to a
% frontier. The queue holds q(Node, FirstAction) — the node and the first action
% that led toward it. The first dequeued node that is a frontier yields its first
% action. Budget counts down per node expanded; at zero the search gives up.
cg_bfs(_, _, _, 0, _) :- !, fail.
cg_bfs([q(Node, FirstAction) | Rest], Visited, Actions, Budget, Result) :-
    (   \+ memberchk(Node, Visited), cg_has_untested(Node, Actions)
    % This reachable node still has an untested action: go toward it.
    ->  Result = FirstAction
    % Already visited: skip it.
    ;   memberchk(Node, Visited)
    ->  cg_bfs(Rest, Visited, Actions, Budget, Result)
    % New but fully-tested node: enqueue its successors, keeping the first action.
    ;   findall(q(To, FirstAction), cg_edge_(Node, _A, To), Succ),
        append(Rest, Succ, Queue),
        Budget1 is Budget - 1,
        cg_bfs(Queue, [Node | Visited], Actions, Budget1, Result)
    ).

% ---------------------------------------------------------------------------
% The hierarchical choice (the winning rule)
% ---------------------------------------------------------------------------

% Define cg_choose: probe an untested action here, else head to the frontier.
cg_choose(Sig, Actions, Action) :-
    % First, an untested action in the current state.
    (   cg_untested(Sig, Actions, A)
    % Take it.
    ->  Action = A
    % Otherwise the first step toward the nearest unexplored state.
    ;   cg_toward_frontier(Sig, Actions, A)
    % Take that step.
    ->  Action = A
    % Nothing left to explore from here: let the caller fall back.
    ;   fail
    ).

% ---------------------------------------------------------------------------
% Statistics
% ---------------------------------------------------------------------------

% Define cg_stats: a summary of the graph's size.
cg_stats(stats(Nodes, Edges, Tested, Dead)) :-
    % Count the nodes.
    aggregate_all(count, cg_node_(_), Nodes),
    % Count the edges.
    aggregate_all(count, cg_edge_(_, _, _), Edges),
    % Count the tested pairs.
    aggregate_all(count, cg_tested_(_, _), Tested),
    % Count the dead pairs.
    aggregate_all(count, cg_dead_(_, _), Dead).

% Define cg_stats_for: a summary of just the subgraph whose signatures carry the
% given prefix, so one game's map can be read without another game's bleeding in.
cg_stats_for(Prefix, stats(Nodes, Edges, Tested, Dead)) :-
    % Count the nodes whose signature begins with the prefix.
    aggregate_all(count, ( cg_node_(S), cg_has_prefix(S, Prefix) ), Nodes),
    % Count the edges leaving a node with the prefix.
    aggregate_all(count, ( cg_edge_(S, _, _), cg_has_prefix(S, Prefix) ), Edges),
    % Count the tested pairs at a node with the prefix.
    aggregate_all(count, ( cg_tested_(S, _), cg_has_prefix(S, Prefix) ), Tested),
    % Count the dead pairs at a node with the prefix.
    aggregate_all(count, ( cg_dead_(S, _), cg_has_prefix(S, Prefix) ), Dead).

% cg_has_prefix(+Signature, +Prefix): the signature begins with the prefix.
cg_has_prefix(Signature, Prefix) :-
    % A leading match of the whole prefix.
    sub_atom(Signature, 0, _, _, Prefix).
