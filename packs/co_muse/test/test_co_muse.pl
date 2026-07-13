/*  PrologAI — Causalontology Imagination Test Suite  (WP-421)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_muse/test/test_co_muse.pl
*/

% Declare this file as a test module.
:- module(test_co_muse, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(co_muse)).

% Open the test block.
:- begin_tests(co_muse).

% Facts placed in different realities stay in their own partition.
test(realities_partition) :-
    co_muse:mu_reset,
    co_muse:mu_assert(observed, at(a)),
    co_muse:mu_assert(desired, at(z)),
    assertion(co_muse:mu_holds(observed, at(a))),
    assertion(\+ co_muse:mu_holds(observed, at(z))),
    assertion(co_muse:mu_holds(desired, at(z))).

% Imagining rolls a start state forward through the transition model.
test(imagine_rolls_forward) :-
    co_muse:mu_reset,
    co_muse:mu_transition_add(s0, go, s1),
    co_muse:mu_transition_add(s1, go, s2),
    co_muse:mu_imagine(s0, [go, go], Traj),
    assertion(Traj == [s0, s1, s2]).

% Imagining halts cleanly when a transition is unknown.
test(imagine_halts_on_unknown) :-
    co_muse:mu_reset,
    co_muse:mu_transition_add(s0, go, s1),
    co_muse:mu_imagine(s0, [go, go], Traj),
    % The second go has no transition, so the trajectory stops at s1.
    assertion(Traj == [s0, s1]).

% The end state is the last state of the imagined trajectory.
test(reaches_end_state) :-
    co_muse:mu_reset,
    co_muse:mu_transition_add(s0, a, s1),
    co_muse:mu_transition_add(s1, b, s2),
    co_muse:mu_reaches(s0, [a, b], End),
    assertion(End == s2).

% Imagined states are quarantined: present in imagined, absent from observed.
test(quarantine) :-
    co_muse:mu_reset,
    co_muse:mu_transition_add(s0, go, s1),
    co_muse:mu_imagine(s0, [go], _),
    % The imagined visit is sealed off from observed fact.
    assertion(co_muse:mu_quarantined(visited(s1))),
    assertion(\+ co_muse:mu_holds(observed, visited(s1))).

% Evaluation scores a trajectory that reaches the goal.
test(evaluate_reached) :-
    co_muse:mu_reset,
    co_muse:mu_transition_add(s0, go, goal),
    co_muse:mu_imagine(s0, [go], Traj),
    co_muse:mu_evaluate(Traj, goal, Score),
    assertion(Score =:= 1.0),
    co_muse:mu_steps_to(Traj, goal, Steps),
    assertion(Steps =:= 1).

% Best plan picks the candidate that reaches the goal in the fewest steps.
test(best_plan_fewest_steps) :-
    co_muse:mu_reset,
    % A direct route and a scenic route to the same goal.
    co_muse:mu_transition_add(s0, jump, goal),
    co_muse:mu_transition_add(s0, step, m1),
    co_muse:mu_transition_add(m1, step, goal),
    co_muse:mu_best_plan(s0, [[step, step], [jump]], goal, Best),
    assertion(Best == [jump]).

% Best plan fails when no candidate reaches the goal.
test(best_plan_none) :-
    co_muse:mu_reset,
    co_muse:mu_transition_add(s0, go, s1),
    assertion(\+ co_muse:mu_best_plan(s0, [[go]], goal, _)).

% Promotion is the only way an imagined finding crosses into another reality.
test(promote_is_deliberate) :-
    co_muse:mu_reset,
    co_muse:mu_transition_add(s0, go, s1),
    co_muse:mu_imagine(s0, [go], _),
    % Imagining alone did not write into expected.
    assertion(\+ co_muse:mu_holds(expected, visited(s1))),
    % A deliberate promotion copies the finding across.
    co_muse:mu_promote(imagined, visited(s1), expected),
    assertion(co_muse:mu_holds(expected, visited(s1))).

% Close the test block.
:- end_tests(co_muse).
