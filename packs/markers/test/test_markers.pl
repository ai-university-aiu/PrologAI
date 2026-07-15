/*  PrologAI — Somatic Markers Test Suite  (PR 24)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/markers/test/test_markers.pl

    Exercises the five exported predicates of the markers pack: stamping an
    episode's valence/arousal onto a plan, reading back the aggregated marker,
    filtering deliberation candidates by marker, decaying markers toward
    neutral, and registering an explicit override that suppresses pruning.
*/

% Declare this file as a test module.
:- module(test_markers, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(markers)).

% Clear the pack's dynamic state so each run starts from an empty marker store.
markers_test_reset :-
    % Remove every accumulated plan marker.
    retractall(markers:plan_marker(_, _, _, _)),
    % Remove every registered override.
    retractall(markers:marker_override(_, _)).

% Open the test block for markers, resetting state before and after the suite.
:- begin_tests(markers, [setup(markers_test_reset), cleanup(markers_test_reset)]).

% AC-MARK-001: a plan stamped three times with strong negative valence is pruned.
test(negative_plan_pruned) :-
    % Stamp the bad plan three times with strongly negative valence.
    forall(between(1, 3, _), markers_marker_stamp(bad_plan, episode(-0.9, 0.5))),
    % Filter a candidate list containing the marked plan and an unmarked one.
    markers_marker_filter([bad_plan, good_plan], [], Filtered),
    % The strongly negative plan is pruned from the survivors.
    assertion(\+ memberchk(bad_plan, Filtered)),
    % The unmarked plan passes through unchanged.
    assertion(memberchk(good_plan, Filtered)).

% AC-MARK-002: a strongly positive plan sorts to the front of the filtered list.
test(positive_plan_first) :-
    % Stamp the great plan three times with strongly positive valence.
    forall(between(1, 3, _), markers_marker_stamp(great_plan, episode(0.8, 0.6))),
    % Filter a candidate list containing a neutral plan and the great plan.
    markers_marker_filter([neutral_plan, great_plan], [], Filtered),
    % The highest-valence plan appears first in the result.
    assertion(Filtered = [great_plan | _]).

% AC-MARK-003: an unknown plan yields the neutral marker (0.0, 0.0, 0).
test(unknown_plan_neutral_marker) :-
    % Read the marker for a plan that was never stamped.
    markers_marker_of(never_stamped_plan, Marker),
    % An unseen plan reads back as exactly neutral with a zero count.
    assertion(Marker == marker(0.0, 0.0, 0)).

% AC-MARK-004: three identical stamps drive the running mean to that value.
test(marker_stamp_updates_mean) :-
    % Stamp the same plan three times with valence -1.0.
    forall(between(1, 3, _), markers_marker_stamp(stamp_test, episode(-1.0, 0.0))),
    % Read back the aggregated marker and its count.
    markers_marker_of(stamp_test, marker(MeanV, _, Count)),
    % Exactly three stamps were counted.
    assertion(Count =:= 3),
    % The mean valence converged to -1.0.
    assertion(abs(MeanV - (-1.0)) < 0.001).

% AC-MARK-005: decay moves a marker's mean strictly toward neutral (0.0).
test(decay_moves_toward_neutral) :-
    % Stamp a plan with a strong negative valence.
    markers_marker_stamp(decay_plan, episode(-0.8, 0.6)),
    % Read the valence before decaying.
    markers_marker_of(decay_plan, marker(V0, _, _)),
    % Run one decay tick over all markers.
    markers_marker_decay,
    % Read the valence after decaying.
    markers_marker_of(decay_plan, marker(V1, _, _)),
    % The magnitude shrank toward zero.
    assertion(abs(V1) < abs(V0)).

% AC-MARK-006: an explicit override keeps an otherwise-pruned negative plan.
test(marker_override_keeps_plan) :-
    % Stamp a plan three times with strongly negative valence.
    forall(between(1, 3, _), markers_marker_stamp(reg_plan, episode(-0.9, 0.5))),
    % Register an explicit override for that plan.
    markers_marker_override(reg_plan, explicit_safety_evidence),
    % Filter with the override in force.
    markers_marker_filter([reg_plan], [], Filtered),
    % The override suppresses the prune, so the plan survives.
    assertion(memberchk(reg_plan, Filtered)).

% Close the test block for markers.
:- end_tests(markers).
