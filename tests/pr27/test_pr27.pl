/*  PrologAI — PR 27 Motivational Modulation (Psi) Acceptance Tests

    AC-PR27-001: Given a battery urge spike (high-urgency physiological need),
                 when modulators update, arousal and speed rise, resolution
                 narrows, and daydream_actor's budget shrinks.
    AC-PR27-002: Extreme arousal is clamped at 1.0; resolution never reaches 0.
    AC-PR27-003: motivation_modulator_decay moves values toward baseline.
    AC-PR27-004: Conflicting needs blend (average urgency used).
    AC-PR27-005: motivation_affect_region returns a named region definition.
    AC-PR27-006: motivation_affect_region can define custom regions.
    AC-PR27-007: motivation_motive returns urgency 0.0 for an unknown goal.
    AC-PR27-008: motivation_modulator get/set round-trip works.
    AC-PR27-009: daydream budget decreases as arousal increases.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/motivation/prolog'], MotPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, MotPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'motivation' library so its predicates are available here.
:- use_module(library(motivation), [
    % Supply 'motivation_modulator/2' as the next argument to the expression above.
    motivation_modulator/2,
    % Supply 'motivation_affect_region/2' as the next argument to the expression above.
    motivation_affect_region/2,
    % Supply 'motivation_motive/3' as the next argument to the expression above.
    motivation_motive/3,
    % Supply 'motivation_modulator_update/1' as the next argument to the expression above.
    motivation_modulator_update/1,
    % Supply 'motivation_modulator_decay/0' as the next argument to the expression above.
    motivation_modulator_decay/0,
    % Supply 'motivation_daydream_budget/1' as the next argument to the expression above.
    motivation_daydream_budget/1
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr27, [setup(pr27_setup), cleanup(pr27_cleanup)]).
:- begin_tests(pr27, [setup(pr27_setup), cleanup(pr27_cleanup)]).

% Execute: pr27_setup :-.
pr27_setup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(motivation:modulator_value(_, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(motivation:active_motive(_, _, _)).

% Execute: pr27_cleanup :-.
pr27_cleanup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(motivation:modulator_value(_, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(motivation:active_motive(_, _, _)).

%  AC-PR27-001: battery urge spike → arousal/speed up, resolution/daydream down
% Define a clause for 'test': succeed when the following conditions hold.
test(battery_urge_raises_arousal) :-
    % Baseline
    % State a fact for 'pai modulator' with the arguments listed below.
    motivation_modulator(arousal, BaseA),
    % State a fact for 'pai modulator' with the arguments listed below.
    motivation_modulator(resolution, BaseR),
    % State a fact for 'pai daydream budget' with the arguments listed below.
    motivation_daydream_budget(BaseBudget),
    % Spike: high-urgency physiological need
    % State a fact for 'pai modulator update' with the arguments listed below.
    motivation_modulator_update([need(physiological, 0.9)]),
    % State a fact for 'pai modulator' with the arguments listed below.
    motivation_modulator(arousal, NewA),
    % State a fact for 'pai modulator' with the arguments listed below.
    motivation_modulator(execution_speed, NewS),
    % State a fact for 'pai modulator' with the arguments listed below.
    motivation_modulator(resolution, NewR),
    % State a fact for 'pai daydream budget' with the arguments listed below.
    motivation_daydream_budget(NewBudget),
    % Check that 'NewA' is greater than 'BaseA'.
    NewA > BaseA,
    % Check that 'NewS' is greater than '0.1'.
    NewS > 0.1,
    % Check that 'NewR' is less than 'BaseR'.
    NewR < BaseR,
    % Check that 'NewBudget' is less than 'BaseBudget'.
    NewBudget < BaseBudget.

%  AC-PR27-002: extreme arousal clamped at 1.0; resolution never zero
% Define a clause for 'test': succeed when the following conditions hold.
test(extreme_arousal_clamped) :-
    % State a fact for 'pai modulator update' with the arguments listed below.
    motivation_modulator_update([need(physiological, 1.0),
                          % Continue the multi-line expression started above.
                          need(physiological, 1.0),
                          % Continue the multi-line expression started above.
                          need(physiological, 1.0)]),
    % State a fact for 'pai modulator' with the arguments listed below.
    motivation_modulator(arousal, A),
    % State a fact for 'pai modulator' with the arguments listed below.
    motivation_modulator(resolution, R),
    % Check that 'A' is less than or equal to '1.0'.
    A =< 1.0,
    % Check that 'R' is greater than '0.0'.
    R > 0.0.

%  AC-PR27-003: decay moves values toward baseline
% Define a clause for 'test': succeed when the following conditions hold.
test(modulator_decay_toward_baseline) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(motivation:modulator_value(_, _)),
    % State a fact for 'pai modulator' with the arguments listed below.
    motivation_modulator(arousal, 0.99),  % set high (explicit set)
    % Call the goal 'motivation_modulator_decay'.
    motivation_modulator_decay,
    % State a fact for 'pai modulator' with the arguments listed below.
    motivation_modulator(arousal, A1),
    % State a fact for 'pai modulator baseline val' with the arguments listed below.
    motivation_modulator_baseline_val(arousal, Base),
    % Check that 'A1' is less than '0.99'.
    A1 < 0.99,
    % Check that 'A1' is greater than 'Base.  % one tick: moved toward base but not all the way'.
    A1 > Base.  % one tick: moved toward base but not all the way

% Define a clause for 'pai modulator baseline val': succeed when the following conditions hold.
motivation_modulator_baseline_val(Dial, Base) :-
    % Execute: motivation:modulator_baseline(Dial, Base)..
    motivation:modulator_baseline(Dial, Base).

%  AC-PR27-004: two conflicting needs blend (average urgency)
% Define a clause for 'test': succeed when the following conditions hold.
test(conflicting_needs_blend) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(motivation:modulator_value(_, _)),
    % State a fact for 'pai modulator' with the arguments listed below.
    motivation_modulator(arousal, 0.3),   % reset to baseline
    % State a fact for 'pai modulator update' with the arguments listed below.
    motivation_modulator_update([need(physiological, 0.8),
                          % Continue the multi-line expression started above.
                          need(cognitive, 0.2)]),
    % State a fact for 'pai modulator' with the arguments listed below.
    motivation_modulator(arousal, A),
    % avg urgency = 0.5; arousal rises from 0.3
    % Check that 'A' is greater than '0.3'.
    A > 0.3,
    % Check that 'A' is less than '0.9'.
    A < 0.9.

%  AC-PR27-005: built-in affect region is defined
% Define a clause for 'test': succeed when the following conditions hold.
test(affect_region_defined) :-
    % State a fact for 'once' with the arguments listed below.
    once(motivation_affect_region(calm, Region)),
    % Check that 'Region' is unifiable with 'region(_, _, _, _, _, _)'.
    Region = region(_, _, _, _, _, _).

%  AC-PR27-006: custom affect region can be defined and queried
% Define a clause for 'test': succeed when the following conditions hold.
test(affect_region_custom) :-
    % State a fact for 'pai affect region' with the arguments listed below.
    motivation_affect_region(my_region, region(0.2, 0.4, 0.3, 0.6, 0.5, 0.8)),
    % State a fact for 'once' with the arguments listed below.
    once(motivation_affect_region(my_region, R)),
    % Check that 'R' is unifiable with 'region(0.2, 0.4, 0.3, 0.6, 0.5, 0.8)'.
    R = region(0.2, 0.4, 0.3, 0.6, 0.5, 0.8).

%  AC-PR27-007: unknown goal → urgency 0.0
% Define a clause for 'test': succeed when the following conditions hold.
test(unknown_motive_zero_urgency) :-
    % State a fact for 'once' with the arguments listed below.
    once(motivation_motive(totally_unknown_goal_xyz, appetitive, M)),
    % Check that 'M' is unifiable with 'motive(_, _, 0.0)'.
    M = motive(_, _, 0.0).

%  AC-PR27-008: motivation_modulator get/set round-trip
% Define a clause for 'test': succeed when the following conditions hold.
test(modulator_get_set_roundtrip) :-
    % State a fact for 'pai modulator' with the arguments listed below.
    motivation_modulator(arousal, 0.7),
    % State a fact for 'pai modulator' with the arguments listed below.
    motivation_modulator(arousal, V),
    % Check that 'abs(V - 0.7)' is less than '0.001'.
    abs(V - 0.7) < 0.001.

%  AC-PR27-009: higher arousal → lower daydream budget
% Define a clause for 'test': succeed when the following conditions hold.
test(daydream_budget_inverse_arousal) :-
    % State a fact for 'pai modulator' with the arguments listed below.
    motivation_modulator(arousal, 0.2),
    % State a fact for 'pai daydream budget' with the arguments listed below.
    motivation_daydream_budget(B1),
    % State a fact for 'pai modulator' with the arguments listed below.
    motivation_modulator(arousal, 0.8),
    % State a fact for 'pai daydream budget' with the arguments listed below.
    motivation_daydream_budget(B2),
    % Check that 'B1' is greater than 'B2'.
    B1 > B2.

% Execute the compile-time directive: end_tests(pr27).
:- end_tests(pr27).
