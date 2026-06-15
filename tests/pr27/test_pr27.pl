/*  PrologAI — PR 27 Motivational Modulation (Psi) Acceptance Tests

    AC-PR27-001: Given a battery urge spike (high-urgency physiological need),
                 when modulators update, arousal and speed rise, resolution
                 narrows, and daydream_actor's budget shrinks.
    AC-PR27-002: Extreme arousal is clamped at 1.0; resolution never reaches 0.
    AC-PR27-003: pai_modulator_decay moves values toward baseline.
    AC-PR27-004: Conflicting needs blend (average urgency used).
    AC-PR27-005: pai_affect_region returns a named region definition.
    AC-PR27-006: pai_affect_region can define custom regions.
    AC-PR27-007: pai_motive returns urgency 0.0 for an unknown goal.
    AC-PR27-008: pai_modulator get/set round-trip works.
    AC-PR27-009: daydream budget decreases as arousal increases.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/motivation/prolog'], MotPath),
   assertz(file_search_path(library, MotPath)).

:- use_module(library(plunit)).
:- use_module(library(motivation), [
    pai_modulator/2,
    pai_affect_region/2,
    pai_motive/3,
    pai_modulator_update/1,
    pai_modulator_decay/0,
    pai_daydream_budget/1
]).

:- begin_tests(pr27, [setup(pr27_setup), cleanup(pr27_cleanup)]).

pr27_setup :-
    retractall(motivation:modulator_value(_, _)),
    retractall(motivation:active_motive(_, _, _)).

pr27_cleanup :-
    retractall(motivation:modulator_value(_, _)),
    retractall(motivation:active_motive(_, _, _)).

%  AC-PR27-001: battery urge spike → arousal/speed up, resolution/daydream down
test(battery_urge_raises_arousal) :-
    % Baseline
    pai_modulator(arousal, BaseA),
    pai_modulator(resolution, BaseR),
    pai_daydream_budget(BaseBudget),
    % Spike: high-urgency physiological need
    pai_modulator_update([need(physiological, 0.9)]),
    pai_modulator(arousal, NewA),
    pai_modulator(execution_speed, NewS),
    pai_modulator(resolution, NewR),
    pai_daydream_budget(NewBudget),
    NewA > BaseA,
    NewS > 0.1,
    NewR < BaseR,
    NewBudget < BaseBudget.

%  AC-PR27-002: extreme arousal clamped at 1.0; resolution never zero
test(extreme_arousal_clamped) :-
    pai_modulator_update([need(physiological, 1.0),
                          need(physiological, 1.0),
                          need(physiological, 1.0)]),
    pai_modulator(arousal, A),
    pai_modulator(resolution, R),
    A =< 1.0,
    R > 0.0.

%  AC-PR27-003: decay moves values toward baseline
test(modulator_decay_toward_baseline) :-
    retractall(motivation:modulator_value(_, _)),
    pai_modulator(arousal, 0.99),  % set high (explicit set)
    pai_modulator_decay,
    pai_modulator(arousal, A1),
    pai_modulator_baseline_val(arousal, Base),
    A1 < 0.99,
    A1 > Base.  % one tick: moved toward base but not all the way

pai_modulator_baseline_val(Dial, Base) :-
    motivation:modulator_baseline(Dial, Base).

%  AC-PR27-004: two conflicting needs blend (average urgency)
test(conflicting_needs_blend) :-
    retractall(motivation:modulator_value(_, _)),
    pai_modulator(arousal, 0.3),   % reset to baseline
    pai_modulator_update([need(physiological, 0.8),
                          need(cognitive, 0.2)]),
    pai_modulator(arousal, A),
    % avg urgency = 0.5; arousal rises from 0.3
    A > 0.3,
    A < 0.9.

%  AC-PR27-005: built-in affect region is defined
test(affect_region_defined) :-
    once(pai_affect_region(calm, Region)),
    Region = region(_, _, _, _, _, _).

%  AC-PR27-006: custom affect region can be defined and queried
test(affect_region_custom) :-
    pai_affect_region(my_region, region(0.2, 0.4, 0.3, 0.6, 0.5, 0.8)),
    once(pai_affect_region(my_region, R)),
    R = region(0.2, 0.4, 0.3, 0.6, 0.5, 0.8).

%  AC-PR27-007: unknown goal → urgency 0.0
test(unknown_motive_zero_urgency) :-
    once(pai_motive(totally_unknown_goal_xyz, appetitive, M)),
    M = motive(_, _, 0.0).

%  AC-PR27-008: pai_modulator get/set round-trip
test(modulator_get_set_roundtrip) :-
    pai_modulator(arousal, 0.7),
    pai_modulator(arousal, V),
    abs(V - 0.7) < 0.001.

%  AC-PR27-009: higher arousal → lower daydream budget
test(daydream_budget_inverse_arousal) :-
    pai_modulator(arousal, 0.2),
    pai_daydream_budget(B1),
    pai_modulator(arousal, 0.8),
    pai_daydream_budget(B2),
    B1 > B2.

:- end_tests(pr27).
