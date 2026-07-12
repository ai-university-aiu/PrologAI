/*  PrologAI — Causalontology Motivation Test Suite  (WP-411)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_impetus/test/test_co_impetus.pl
*/

% Declare this file as a test module.
:- module(test_co_impetus, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(co_impetus)).

% Open the test block.
:- begin_tests(co_impetus).

% Pressure is the size of the gap between target and actual.
test(pressure_is_gap) :-
    co_impetus:im_reset,
    co_impetus:im_need_add(charge, 100, 70),
    co_impetus:im_pressure(charge, P),
    assertion(P =:= 30).

% Updating the reading changes the pressure.
test(update_actual) :-
    co_impetus:im_reset,
    co_impetus:im_need_add(charge, 100, 70),
    co_impetus:im_set_actual(charge, 95),
    co_impetus:im_pressure(charge, P),
    assertion(P =:= 5).

% A need within threshold is satisfied.
test(satisfied_within_threshold) :-
    co_impetus:im_reset,
    co_impetus:im_need_add(signal, 10, 10),
    assertion(co_impetus:im_satisfied(signal)).

% The agenda ranks the most pressing need first, as a restore goal.
test(agenda_ranks_pressing) :-
    co_impetus:im_reset,
    co_impetus:im_need_add(a, 100, 90),   % pressure 10
    co_impetus:im_need_add(b, 100, 40),   % pressure 60
    co_impetus:im_top_goal(Goal),
    assertion(Goal == restore(b)).

% When every need is satisfied the agenda is still non-empty: explore.
test(agenda_never_empty) :-
    co_impetus:im_reset,
    co_impetus:im_need_add(a, 5, 5),
    co_impetus:im_need_add(b, 8, 8),
    co_impetus:im_top_goal(Goal),
    assertion(Goal == explore).

% With no needs at all, the mind still has a goal.
test(idle_explores) :-
    co_impetus:im_reset,
    co_impetus:im_agenda(Goals),
    assertion(Goals == [0.0-explore]).

% The count reflects registered needs, and re-adding replaces.
test(count_and_replace) :-
    co_impetus:im_reset,
    co_impetus:im_need_add(a, 1, 0),
    co_impetus:im_need_add(a, 2, 0),
    co_impetus:im_count(N),
    assertion(N =:= 1),
    co_impetus:im_need(a, T, _),
    assertion(T =:= 2).

% Close the test block.
:- end_tests(co_impetus).
