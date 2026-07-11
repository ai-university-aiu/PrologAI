/*  PrologAI — Causalontology State-Graph Exploration Test Suite  (WP-402)

    Builds a small explored graph by hand and checks the winning behaviours: a
    no-change action is marked dead and never probed, an untested action in the
    current state is probed first, and from a fully-explored state the search
    returns the first step on the shortest path to the nearest state that still
    has something untested.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_graph/test/test_co_graph.pl
*/

% Declare this file as a test module.
:- module(test_co_graph, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module(library(co_graph)).

% Three distinct one-cell frames standing for three states.
frame_a([[0]]).
frame_b([[1]]).
frame_c([[2]]).

% Build the explored graph: from A, action move reaches B and action idle does
% nothing (dead); from B, action move reaches C and idle does nothing; C is
% unexplored (a frontier).
build_graph :-
    co_graph:cg_reset,
    frame_a(FA), frame_b(FB), frame_c(FC),
    cg_signature(FA, SA), cg_signature(FB, SB), cg_signature(FC, SC),
    % From A: move changes to B; idle does nothing.
    cg_note(SA, move, SB),
    cg_note(SA, idle, SA),
    % From B: move changes to C; idle does nothing.
    cg_note(SB, move, SC),
    cg_note(SB, idle, SB).

% Open the test unit for the state-graph explorer.
:- begin_tests(co_graph).

% Distinct frames get distinct signatures.
test(signatures_distinct) :-
    frame_a(FA), frame_b(FB),
    cg_signature(FA, SA), cg_signature(FB, SB),
    SA \== SB.

% A no-change action is recorded as dead.
test(no_change_is_dead) :-
    build_graph,
    frame_a(FA), cg_signature(FA, SA),
    % The idle action from A produced no change, so it is dead.
    cg_dead(SA, idle),
    % The move action from A did change the state, so it is not dead.
    \+ cg_dead(SA, move).

% An untested, non-dead action in the current state is probed first.
test(probe_untested_here, [true(A == move)]) :-
    build_graph,
    frame_c(FC), cg_signature(FC, SC),
    % C has no tried actions, so the first afforded action (move) is probed.
    cg_choose(SC, [move, idle], A).

% A dead action is skipped; a genuinely untested action is probed instead.
test(dead_not_probed, [true(A == jump)]) :-
    build_graph,
    frame_a(FA), cg_signature(FA, SA),
    % At A: idle is dead and move is tested, but jump has never been tried here,
    % so jump is the untested action chosen (idle is not offered).
    cg_choose(SA, [idle, jump, move], A).

% From the fully-explored A, head toward the frontier C via the shortest path.
test(toward_frontier, [true(A == move)]) :-
    build_graph,
    frame_a(FA), cg_signature(FA, SA),
    % A has no untested action of its own (move tested, idle dead), so the
    % search returns the first step toward C (which is unexplored): move.
    cg_choose(SA, [move, idle], A).

% The statistics count the graph that was built.
test(stats) :-
    build_graph,
    cg_stats(stats(Nodes, Edges, Tested, Dead)),
    % Three states (A, B, C).
    Nodes =:= 3,
    % Four edges recorded.
    Edges =:= 4,
    % Four tested pairs.
    Tested =:= 4,
    % Two dead pairs (idle at A and at B).
    Dead =:= 2.

% Two games share the one graph store, each prefixing its signatures, and the
% per-game statistics count only that game's subgraph — no bleed between games.
test(prefix_isolation) :-
    co_graph:cg_reset,
    % Game one records two transitions among its own prefixed states.
    cg_note('g1::a', move, 'g1::b'),
    cg_note('g1::b', idle, 'g1::b'),
    % Game two records one transition among its own prefixed states.
    cg_note('g2::a', move, 'g2::b'),
    % Game one sees only its own two nodes, two edges, two tested, one dead.
    cg_stats_for('g1::', stats(N1, E1, T1, D1)),
    N1 =:= 2, E1 =:= 2, T1 =:= 2, D1 =:= 1,
    % Game two sees only its own two nodes, one edge, one tested, no dead.
    cg_stats_for('g2::', stats(N2, E2, T2, D2)),
    N2 =:= 2, E2 =:= 1, T2 =:= 1, D2 =:= 0,
    % A game that has recorded nothing sees an empty subgraph.
    cg_stats_for('g3::', stats(0, 0, 0, 0)).

% The frontier search never crosses game prefixes: from game one's fully-tested
% state the choice stays within game one, and game two's untested state is not
% reachable as a frontier.
test(no_cross_game_frontier, [fail]) :-
    co_graph:cg_reset,
    % Game one is fully explored: move tested, idle dead — no frontier of its own.
    cg_note('g1::a', move, 'g1::b'),
    cg_note('g1::a', idle, 'g1::a'),
    cg_note('g1::b', move, 'g1::a'),
    cg_note('g1::b', idle, 'g1::b'),
    % Game two has an untested frontier, but it is a separate, unlinked subgraph.
    cg_note('g2::a', move, 'g2::b'),
    % From game one there is no untested action and no reachable frontier, so the
    % choice fails rather than wandering into game two.
    cg_choose('g1::a', [move, idle], _).

% Close the test unit.
:- end_tests(co_graph).
