/*  PrologAI — Causalontology Priming  (WP-422, Layer 397)

    THE_BUILDING_FILES give a mind a network of associations and a way for
    activation to flow across it: when something becomes active, the things it is
    linked to become relevant too, more weakly the further away they are. That is
    priming — the reason "salt" brings "pepper" to mind. co_salience already picks
    the single most salient item from things offered to it; this pack is the
    complementary faculty that decides WHAT becomes relevant in the first place,
    by spreading activation over a graph of associations.

    An association is a weighted directed link:

        link(From, To, Weight)     Weight in (0, 1]

    Given a set of source nodes (each active at 1.0 by default, or at a supplied
    level), activation flows outward. A node's activation is the strongest path
    to it: the source level times the product of the link weights along the way,
    each hop also multiplied by a decay in [0, 1] that fades distant associations.
    This is a widest-path relaxation — deterministic, terminating, and fully
    inspectable, never a trained weight.

    Predicates:
      pr_reset/0            -- forget every association
      pr_link_add/3         -- +From, +To, +Weight
      pr_link/3             -- ?From, ?To, ?Weight
      pr_neighbors/2        -- +Node, -Neighbours
      pr_node_count/1       -- -N
      pr_spread/3           -- +Sources, +Decay, -Activations   (Node-Level, sorted by node)
      pr_activation/4       -- +Sources, +Decay, +Node, -Level   (0.0 if unreached)
      pr_primed/4           -- +Sources, +Decay, +K, -TopK       (best K primed non-sources)
*/

% Declare this module and its exported predicates.
:- module(co_prime, [
    % pr_reset/0: forget every association.
    pr_reset/0,
    % pr_link_add/3: add a weighted association.
    pr_link_add/3,
    % pr_link/3: query the associations.
    pr_link/3,
    % pr_neighbors/2: the nodes a node links to.
    pr_neighbors/2,
    % pr_node_count/1: how many distinct nodes appear in the graph.
    pr_node_count/1,
    % pr_spread/3: activation of every reached node from the sources.
    pr_spread/3,
    % pr_activation/4: the activation level of one node.
    pr_activation/4,
    % pr_primed/4: the best K primed nodes (excluding the sources).
    pr_primed/4
]).

% Use the list library.
:- use_module(library(lists)).
% Use the association-list library for the activation map.
:- use_module(library(assoc)).

% link/3 is one weighted association; it changes at runtime, so it is dynamic.
:- dynamic link/3.

% pr_reset/0: forget every association.
pr_reset :-
    % Remove all links.
    retractall(link(_,_,_)).

% pr_link_add/3: add a weighted association, without duplication.
pr_link_add(From, To, Weight) :-
    % Store it unless the exact same link already exists.
    ( link(From, To, Weight) -> true ; assertz(link(From, To, Weight)) ).

% pr_link/3: expose the associations.
pr_link(From, To, Weight) :-
    % Read the stored link.
    link(From, To, Weight).

% pr_neighbors/2: the distinct nodes a node links to.
pr_neighbors(Node, Neighbours) :-
    % Collect the targets of the node's outgoing links.
    findall(To, link(Node, To, _), Raw),
    % Sort to a distinct, ordered set.
    sort(Raw, Neighbours).

% pr_node_count/1: how many distinct nodes appear in the graph.
pr_node_count(N) :-
    % Gather every node from both ends of every link.
    pr_graph_nodes(Nodes),
    % Count them.
    length(Nodes, N).

% pr_spread/3: spread activation from the sources across the graph.
pr_spread(Sources, Decay, Activations) :-
    % Normalise the sources into Node-Level pairs (default level 1.0).
    pr_norm_sources(Sources, Pairs),
    % Seed the activation map with the source levels.
    pr_seed(Pairs, Seed),
    % Convergence needs at most as many passes as there are nodes.
    pr_all_nodes(Pairs, AllNodes),
    length(AllNodes, Passes),
    % Relax the graph that many times.
    pr_relax_n(Passes, Decay, Seed, Final),
    % Return the activations as a node-sorted Node-Level list.
    assoc_to_list(Final, Activations).

% pr_activation/4: the activation level of one node (0.0 if it was never reached).
pr_activation(Sources, Decay, Node, Level) :-
    % Spread once, then look the node up.
    pr_spread(Sources, Decay, Activations),
    ( memberchk(Node-L, Activations) -> Level = L ; Level = 0.0 ).

% pr_primed/4: the best K primed nodes, excluding the sources themselves.
pr_primed(Sources, Decay, K, TopK) :-
    % Spread the activation.
    pr_spread(Sources, Decay, Activations),
    % Remember which nodes were sources, so they can be excluded.
    pr_norm_sources(Sources, Pairs),
    findall(S, member(S-_, Pairs), SourceNodes),
    % Keep the non-source nodes as Level-Node so they sort by strength.
    findall(Level-Node,
            ( member(Node-Level, Activations),
              \+ memberchk(Node, SourceNodes) ),
            Ranked0),
    % Sort by activation descending, keeping ties.
    sort(1, @>=, Ranked0, Ranked),
    % Take the best K and present them as Node-Level.
    pr_take(Ranked, K, Best),
    findall(Node-Level, member(Level-Node, Best), TopK).

% ---- internal --------------------------------------------------------------

% pr_norm_sources/2: turn a source list into Node-Level pairs (default 1.0).
pr_norm_sources([], []).
% Each element is either a Node-Level pair or a bare node (level 1.0).
pr_norm_sources([X | Xs], [Node-Level | Rest]) :-
    % Split a pair, or default a bare node to full activation.
    ( X = N0-L0 -> Node = N0, Level = L0 ; Node = X, Level = 1.0 ),
    % Normalise the remaining sources.
    pr_norm_sources(Xs, Rest).

% pr_seed/2: build the initial activation map from the source pairs.
pr_seed(Pairs, Seed) :-
    % Start from an empty association map.
    empty_assoc(Empty),
    % Fold each source's level into the map.
    foldl(pr_put_source, Pairs, Empty, Seed).

% pr_put_source/3: put one source level into the activation map.
pr_put_source(Node-Level, In, Out) :-
    % Record the node at its seed level.
    put_assoc(Node, In, Level, Out).

% pr_all_nodes/2: every node in the graph plus every source node.
pr_all_nodes(SourcePairs, AllNodes) :-
    % The graph's own nodes.
    pr_graph_nodes(GraphNodes),
    % The source nodes.
    findall(S, member(S-_, SourcePairs), SourceNodes),
    % Their union, distinct and ordered.
    append(GraphNodes, SourceNodes, Both),
    sort(Both, AllNodes).

% pr_graph_nodes/1: every distinct node appearing in a link.
pr_graph_nodes(Nodes) :-
    % Collect both ends of every link.
    findall(N, ( link(A, B, _), ( N = A ; N = B ) ), Raw),
    % Sort to a distinct, ordered set.
    sort(Raw, Nodes).

% pr_relax_n/4: run the relaxation pass a fixed number of times.
pr_relax_n(0, _, A, A) :-
    % Zero passes leave the map unchanged (committed).
    !.
pr_relax_n(K, Decay, A, Out) :-
    % With passes remaining, run one pass and recurse.
    K > 0,
    pr_pass(Decay, A, A1),
    K1 is K - 1,
    pr_relax_n(K1, Decay, A1, Out).

% pr_pass/3: one relaxation pass — every link may raise its target's activation.
pr_pass(Decay, Ain, Aout) :-
    % Gather every link as a relaxable edge.
    findall(edge(F, T, W), link(F, T, W), Edges),
    % Relax each edge, reading source levels from the pass's start snapshot.
    foldl(pr_relax_edge(Decay, Ain), Edges, Ain, Aout).

% pr_relax_edge/5: raise the target's activation if this edge offers more.
pr_relax_edge(Decay, Ain, edge(From, To, Weight), AccIn, AccOut) :-
    % The source's activation is read from the start-of-pass snapshot.
    ( get_assoc(From, Ain, LFrom) -> true ; LFrom = 0.0 ),
    % The candidate activation flows along the weight and fades by the decay.
    Cand is min(1.0, LFrom * Weight * Decay),
    % The target's current activation in the accumulator.
    ( get_assoc(To, AccIn, LTo) -> true ; LTo = 0.0 ),
    % Keep the stronger of the two.
    ( Cand > LTo
      -> put_assoc(To, AccIn, Cand, AccOut)
      ;  AccOut = AccIn ).

% pr_take/3: take at most K elements from the front of a list.
pr_take(_, K, []) :-
    % Taking zero or fewer yields the empty list (committed).
    K =< 0,
    !.
% Taking from an empty list yields the empty list.
pr_take([], _, []) :-
    !.
% Otherwise keep the head and take K-1 more from the tail.
pr_take([X | Xs], K, [X | Ys]) :-
    % One fewer to take from the rest.
    K1 is K - 1,
    pr_take(Xs, K1, Ys).
