/*  PrologAI — Motivation Test Suite  (WP-411; converged with Psi modulation PR 27)

    The union proof: the drive-agenda half (from the Causalontology motivation
    pack) and the modulator-bus half (from the older Psi pack) both pass under
    the one converged pack's pack-qualified names.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/motivation/test/test_motivation.pl
*/

% Declare this file as a test module.
:- module(test_motivation, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(motivation)).

% Open the drive-agenda test block.
:- begin_tests(motivation_agenda).

% Pressure is the size of the gap between target and actual.
test(pressure_is_gap) :-
    motivation:motivation_reset,
    motivation:motivation_need_add(charge, 100, 70),
    motivation:motivation_pressure(charge, P),
    assertion(P =:= 30).

% Updating the reading changes the pressure.
test(update_actual) :-
    motivation:motivation_reset,
    motivation:motivation_need_add(charge, 100, 70),
    motivation:motivation_set_actual(charge, 95),
    motivation:motivation_pressure(charge, P),
    assertion(P =:= 5).

% A need within threshold is satisfied.
test(satisfied_within_threshold) :-
    motivation:motivation_reset,
    motivation:motivation_need_add(signal, 10, 10),
    assertion(motivation:motivation_satisfied(signal)).

% The agenda ranks the most pressing need first, as a restore goal.
test(agenda_ranks_pressing) :-
    motivation:motivation_reset,
    motivation:motivation_need_add(a, 100, 90),   % pressure 10
    motivation:motivation_need_add(b, 100, 40),   % pressure 60
    motivation:motivation_top_goal(Goal),
    assertion(Goal == restore(b)).

% When every need is satisfied the agenda is still non-empty: explore.
test(agenda_never_empty) :-
    motivation:motivation_reset,
    motivation:motivation_need_add(a, 5, 5),
    motivation:motivation_need_add(b, 8, 8),
    motivation:motivation_top_goal(Goal),
    assertion(Goal == explore).

% With no needs at all, the mind still has a goal.
test(idle_explores) :-
    motivation:motivation_reset,
    motivation:motivation_agenda(Goals),
    assertion(Goals == [0.0-explore]).

% The count reflects registered needs, and re-adding replaces.
test(count_and_replace) :-
    motivation:motivation_reset,
    motivation:motivation_need_add(a, 1, 0),
    motivation:motivation_need_add(a, 2, 0),
    motivation:motivation_count(N),
    assertion(N =:= 1),
    motivation:motivation_need(a, T, _),
    assertion(T =:= 2).

% Close the drive-agenda test block.
:- end_tests(motivation_agenda).

% Open the modulator-bus test block (the absorbed Psi half, no-loss proof).
:- begin_tests(motivation_modulator).

% A dial reads its baseline before anything sets it (arousal baseline 0.3).
test(dial_reads_baseline) :-
    motivation:motivation_modulator(arousal, V),
    assertion(V =:= 0.3).

% Setting a dial clamps into range and reads back the clamped value.
test(dial_set_and_clamp) :-
    motivation:motivation_modulator(arousal, 5.0),   % above the 1.0 clamp
    motivation:motivation_modulator(arousal, V),
    assertion(V =:= 1.0).

% A built-in affect region resolves to a six-slot region term.
test(affect_region_builtin) :-
    motivation:motivation_affect_region(calm, R),
    assertion(R = region(_,_,_,_,_,_)).

% An unregistered goal has a zero-urgency motive.
test(motive_defaults_zero) :-
    motivation:motivation_motive(nowhere, appetitive, motive(_,_,U)),
    assertion(U =:= 0.0).

% Updating the bus with an urgent need raises arousal above baseline.
test(update_raises_arousal) :-
    motivation:motivation_modulator(arousal, 0.3),   % reset to baseline
    motivation:motivation_modulator_update([need(cognitive, 0.8)]),
    motivation:motivation_modulator(arousal, V),
    assertion(V > 0.3).

% The daydream budget shrinks as arousal rises.
test(daydream_budget_inverse_arousal) :-
    motivation:motivation_modulator(arousal, 0.9),
    motivation:motivation_daydream_budget(B),
    assertion(B =< 0.1 + 1.0e-9).

% Decay moves a raised dial back toward its baseline.
test(decay_moves_toward_baseline) :-
    motivation:motivation_modulator(arousal, 1.0),
    motivation:motivation_modulator_decay,
    motivation:motivation_modulator(arousal, V),
    assertion(V < 1.0).

% Close the modulator-bus test block.
:- end_tests(motivation_modulator).
