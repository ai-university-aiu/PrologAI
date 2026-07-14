/*  PrologAI — Imagination Test Suite  (WP-421; converged with the daydream and imagination packs)

    The quarantined-realities half (from co_muse) is exercised in full; the
    absorbed mind-wandering and mindscape/reverie/tableau predicates (which the
    daydream and imagination packs shipped without tests) are proven present and
    exported under the converged pack-qualified names.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/imagination/test/test_imagination.pl
*/

% Declare this file as a test module.
:- module(test_imagination, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the converged module under test.
:- use_module(library(imagination)).

:- begin_tests(imagination_realities).

% Facts placed in different realities stay in their own partition.
test(realities_partition) :-
    imagination:imagination_reset,
    imagination:imagination_assert(observed, at(a)),
    imagination:imagination_assert(desired, at(z)),
    assertion(imagination:imagination_holds(observed, at(a))),
    assertion(\+ imagination:imagination_holds(observed, at(z))),
    assertion(imagination:imagination_holds(desired, at(z))).

% Imagining rolls a start state forward through the transition model.
test(imagine_rolls_forward) :-
    imagination:imagination_reset,
    imagination:imagination_transition_add(s0, go, s1),
    imagination:imagination_transition_add(s1, go, s2),
    imagination:imagination_imagine(s0, [go, go], Traj),
    assertion(Traj == [s0, s1, s2]).

% Imagining halts cleanly when a transition is unknown.
test(imagine_halts_on_unknown) :-
    imagination:imagination_reset,
    imagination:imagination_transition_add(s0, go, s1),
    imagination:imagination_imagine(s0, [go, go], Traj),
    % The second go has no transition, so the trajectory stops at s1.
    assertion(Traj == [s0, s1]).

% The end state is the last state of the imagined trajectory.
test(reaches_end_state) :-
    imagination:imagination_reset,
    imagination:imagination_transition_add(s0, a, s1),
    imagination:imagination_transition_add(s1, b, s2),
    imagination:imagination_reaches(s0, [a, b], End),
    assertion(End == s2).

% Imagined states are quarantined: present in imagined, absent from observed.
test(quarantine) :-
    imagination:imagination_reset,
    imagination:imagination_transition_add(s0, go, s1),
    imagination:imagination_imagine(s0, [go], _),
    % The imagined visit is sealed off from observed fact.
    assertion(imagination:imagination_quarantined(visited(s1))),
    assertion(\+ imagination:imagination_holds(observed, visited(s1))).

% Evaluation scores a trajectory that reaches the goal.
test(evaluate_reached) :-
    imagination:imagination_reset,
    imagination:imagination_transition_add(s0, go, goal),
    imagination:imagination_imagine(s0, [go], Traj),
    imagination:imagination_evaluate(Traj, goal, Score),
    assertion(Score =:= 1.0),
    imagination:imagination_steps_to(Traj, goal, Steps),
    assertion(Steps =:= 1).

% Best plan picks the candidate that reaches the goal in the fewest steps.
test(best_plan_fewest_steps) :-
    imagination:imagination_reset,
    % A direct route and a scenic route to the same goal.
    imagination:imagination_transition_add(s0, jump, goal),
    imagination:imagination_transition_add(s0, step, m1),
    imagination:imagination_transition_add(m1, step, goal),
    imagination:imagination_best_plan(s0, [[step, step], [jump]], goal, Best),
    assertion(Best == [jump]).

% Best plan fails when no candidate reaches the goal.
test(best_plan_none) :-
    imagination:imagination_reset,
    imagination:imagination_transition_add(s0, go, s1),
    assertion(\+ imagination:imagination_best_plan(s0, [[go]], goal, _)).

% Promotion is the only way an imagined finding crosses into another reality.
test(promote_is_deliberate) :-
    imagination:imagination_reset,
    imagination:imagination_transition_add(s0, go, s1),
    imagination:imagination_imagine(s0, [go], _),
    % Imagining alone did not write into expected.
    assertion(\+ imagination:imagination_holds(expected, visited(s1))),
    % A deliberate promotion copies the finding across.
    imagination:imagination_promote(imagined, visited(s1), expected),
    assertion(imagination:imagination_holds(expected, visited(s1))).

% Close the test block.
:- end_tests(imagination_realities).

% Open the absorbed-predicates presence block (no-loss proof for daydream + imagination).
:- begin_tests(imagination_absorbed).

% Every mind-wandering predicate from the daydream pack is present under its new name.
test(daydream_predicates_present) :-
    assertion(current_predicate(imagination:imagination_control_goal/2)),
    assertion(current_predicate(imagination:imagination_daydream_steer/2)),
    assertion(current_predicate(imagination:imagination_daydream_terminate/1)),
    assertion(current_predicate(imagination:imagination_daydream_product/2)).

% Every mindscape / reverie / tableau predicate from the imagination pack is present.
test(mindscape_predicates_present) :-
    assertion(current_predicate(imagination:imagination_imagine_fresh/4)),
    assertion(current_predicate(imagination:imagination_mindscape_new/2)),
    assertion(current_predicate(imagination:imagination_mindscape_clear/1)),
    assertion(current_predicate(imagination:imagination_mindscape_reality/2)),
    assertion(current_predicate(imagination:imagination_reverie_frames/2)),
    assertion(current_predicate(imagination:imagination_reverie_render/3)),
    assertion(current_predicate(imagination:imagination_tableau_add/3)),
    assertion(current_predicate(imagination:imagination_tableau_ground/3)).

% Close the absorbed-predicates presence block.
:- end_tests(imagination_absorbed).
