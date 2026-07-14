/*  PrologAI — Causalontology Priming Test Suite  (WP-422)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/priming/test/test_priming.pl
*/

% Declare this file as a test module.
:- module(test_priming, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(priming)).
% Load list helpers for the assertions.
:- use_module(library(lists)).

% Open the test block.
:- begin_tests(priming).

% Build a small association graph shared by several tests.
setup_graph :-
    priming:priming_reset,
    priming:priming_link_add(key, lock, 0.9),
    priming:priming_link_add(lock, door, 0.8),
    priming:priming_link_add(key, shiny, 0.5).

% Neighbours are the distinct targets of a node's links.
test(neighbors) :-
    setup_graph,
    priming:priming_neighbors(key, Ns),
    assertion(Ns == [lock, shiny]).

% A source keeps full activation and its direct neighbour is weight-scaled.
test(direct_activation) :-
    setup_graph,
    priming:priming_activation([key], 1.0, key, LKey),
    assertion(LKey =:= 1.0),
    priming:priming_activation([key], 1.0, lock, LLock),
    assertion(abs(LLock - 0.9) < 1e-9).

% Activation spreads two hops as the product of the weights.
test(two_hop_activation) :-
    setup_graph,
    priming:priming_activation([key], 1.0, door, LDoor),
    % key(1.0) * 0.9 * 0.8 = 0.72
    assertion(abs(LDoor - 0.72) < 1e-9).

% An unreached node has zero activation.
test(unreached_is_zero) :-
    setup_graph,
    priming:priming_activation([key], 1.0, nowhere, L),
    assertion(L =:= 0.0).

% Decay fades associations by distance.
test(decay_fades) :-
    setup_graph,
    priming:priming_activation([key], 0.5, lock, LLock),
    % key(1.0) * 0.9 * 0.5 = 0.45
    assertion(abs(LLock - 0.45) < 1e-9),
    priming:priming_activation([key], 0.5, door, LDoor),
    % 0.45 * 0.8 * 0.5 = 0.18
    assertion(abs(LDoor - 0.18) < 1e-9).

% Priming ranks the non-source nodes by activation, strongest first.
test(primed_ranking) :-
    setup_graph,
    priming:priming_primed([key], 1.0, 2, Top),
    % lock(0.9) then door(0.72); shiny(0.5) falls outside the top two.
    assertion(Top = [lock-_, door-_]),
    Top = [_-L1, _-L2],
    assertion(L1 > L2).

% The source itself is excluded from the primed list.
test(primed_excludes_source) :-
    setup_graph,
    priming:priming_primed([key], 1.0, 10, Top),
    assertion(\+ memberchk(key-_, Top)).

% A supplied source level scales the whole spread.
test(source_level_scales) :-
    setup_graph,
    priming:priming_activation([key-0.5], 1.0, lock, LLock),
    % 0.5 * 0.9 = 0.45
    assertion(abs(LLock - 0.45) < 1e-9).

% The node count reflects the distinct nodes in the graph.
test(node_count) :-
    setup_graph,
    priming:priming_node_count(N),
    assertion(N =:= 4).

% Close the test block.
:- end_tests(priming).
