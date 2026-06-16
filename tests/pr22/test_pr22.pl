/*  PrologAI — PR 22 Self-Programming Seed: Model Synthesis Acceptance Tests

    AC-PR22-001: After 20 switch_press → light_on observations (~1 second apart),
                 pai_model_synthesize produces a model with APattern=switch_press
                 and DeltaMs <= 1500.
    AC-PR22-002: pai_symbolic_regress on linear garden sensor data produces a
                 linear/3 formula with R² >= 0.99.
    AC-PR22-003: pai_model_score returns 0.5 for a model with no predictions.
    AC-PR22-004: After 8 hits and 2 misses, pai_model_score returns 0.8.
    AC-PR22-005: pai_lifecycle_advance promotes a model with score >= 0.7.
    AC-PR22-006: pai_lifecycle_advance does NOT promote a model with score < 0.7.
    AC-PR22-007: pai_model_gc deletes a model with score < 0.2 that has >= 5 predictions.
    AC-PR22-008: pai_model_compose returns a non-empty plan when a subtask model
                 links current situation to goal.
    AC-PR22-009: pai_symbolic_regress on a constant dataset returns constant/1.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],       LatticePath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActorsPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/synthesis/prolog'],      SynthPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatticePath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ActorsPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, SynthPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [lattice_open/2, lattice_close/1] from the built-in 'lattice' library.
:- use_module(library(lattice),   [lattice_open/2, lattice_close/1]).
% Import [set_default_nexus/1] from the built-in 'node_facts' library.
:- use_module(library(node_facts),[set_default_nexus/1]).
% Load the built-in 'synthesis' library so its predicates are available here.
:- use_module(library(synthesis), [
    % Supply 'pai_observe_event/2' as the next argument to the expression above.
    pai_observe_event/2,
    % Supply 'pai_model_synthesize/3' as the next argument to the expression above.
    pai_model_synthesize/3,
    % Supply 'pai_model_score/2' as the next argument to the expression above.
    pai_model_score/2,
    % Supply 'pai_model_compose/3' as the next argument to the expression above.
    pai_model_compose/3,
    % Supply 'pai_model_gc/0' as the next argument to the expression above.
    pai_model_gc/0,
    % Supply 'pai_lifecycle_advance/2' as the next argument to the expression above.
    pai_lifecycle_advance/2,
    % Supply 'pai_symbolic_regress/3' as the next argument to the expression above.
    pai_symbolic_regress/3
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr22, [setup(pr22_setup), cleanup(pr22_cleanup)]).
:- begin_tests(pr22, [setup(pr22_setup), cleanup(pr22_cleanup)]).

% Execute: pr22_setup :-.
pr22_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr22', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr22_nexus_ref, N),
    % State a fact for 'set default nexus' with the arguments listed below.
    set_default_nexus(N),
    % Remove all matching facts from the runtime knowledge base.
    retractall(synthesis:observed_event(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(synthesis:synthesized_model(_, _, _, _, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(synthesis:model_prediction(_, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(synthesis:model_id_counter(_)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(synthesis:obs_id_counter(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(synthesis:model_id_counter(0)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(synthesis:obs_id_counter(0)).

% Execute: pr22_cleanup :-.
pr22_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr22_nexus_ref, N),
    % Remove all matching facts from the runtime knowledge base.
    retractall(synthesis:observed_event(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(synthesis:synthesized_model(_, _, _, _, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(synthesis:model_prediction(_, _, _, _)),
    % State the fact: lattice close(N).
    lattice_close(N).

%  AC-PR22-001: 20 switch_press → light_on pairs (~1 second apart)
%               → synthesize produces a model for this causal pattern
% Define a clause for 'test': succeed when the following conditions hold.
test(model_synthesize_light_switch) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        between(1, 20, I),
        % Continue the multi-line expression started above.
        ( T1 is float(I) * 2.0,
          % Continue the multi-line expression started above.
          T2 is T1 + 1.0,
          % Continue the multi-line expression started above.
          pai_observe_event(switch_press, T1),
          % Continue the multi-line expression started above.
          pai_observe_event(light_on,     T2)
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ),
    % State a fact for 'pai model synthesize' with the arguments listed below.
    pai_model_synthesize([], [], Models),
    % Check that 'Models' is not unifiable with '[]'.
    Models \= [],
    % State a fact for 'once' with the arguments listed below.
    once((
        % Continue the multi-line expression started above.
        member(MId, Models),
        % Continue the multi-line expression started above.
        synthesis:synthesized_model(MId, switch_press, light_on, Delta, _, _, _),
        % Continue the multi-line expression started above.
        Delta =< 1500
    % Close the expression opened above.
    )).

%  AC-PR22-002: symbolic regressor on linear garden sensor data → R² >= 0.99
% Define a clause for 'test': succeed when the following conditions hold.
test(symbolic_regress_linear) :-
    % State a fact for 'numlist' with the arguments listed below.
    numlist(1, 10, Xs),
    % State a fact for 'maplist' with the arguments listed below.
    maplist([X, x_y(X, Y)]>>(Y is 3.0 * X + 7.0), Xs, Points),
    % State a fact for 'pai symbolic regress' with the arguments listed below.
    pai_symbolic_regress(Points, [], Formula),
    % Check that 'Formula' is unifiable with 'linear(Slope, Intercept, r_squared(R2))'.
    Formula = linear(Slope, Intercept, r_squared(R2)),
    % Check that 'abs(Slope     - 3.0)' is less than '0.01'.
    abs(Slope     - 3.0) < 0.01,
    % Check that 'abs(Intercept - 7.0)' is less than '0.01'.
    abs(Intercept - 7.0) < 0.01,
    % Check that 'R2' is greater than or equal to '0.99'.
    R2 >= 0.99.

%  AC-PR22-003: fresh model has score 0.5 (no predictions)
% Define a clause for 'test': succeed when the following conditions hold.
test(model_score_no_predictions) :-
    % Add a new fact or rule to the runtime knowledge base.
    assertz(synthesis:synthesized_model(test_model_003,
            % Continue the multi-line expression started above.
            pattern_a, pattern_b, 500, [], 0.5, feature)),
    % State a fact for 'pai model score' with the arguments listed below.
    pai_model_score(test_model_003, Score),
    % Check that 'Score' is numerically equal to '0.5'.
    Score =:= 0.5.

%  AC-PR22-004: 8 hits + 2 misses → score 0.8
% Define a clause for 'test': succeed when the following conditions hold.
test(model_score_from_predictions) :-
    % Add a new fact or rule to the runtime knowledge base.
    assertz(synthesis:synthesized_model(test_model_004,
            % Continue the multi-line expression started above.
            pattern_c, pattern_d, 200, [], 0.5, feature)),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 8, _),
           % Continue the multi-line expression started above.
           assertz(synthesis:model_prediction(test_model_004, 0, p_d, hit))),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 2, _),
           % Continue the multi-line expression started above.
           assertz(synthesis:model_prediction(test_model_004, 0, p_d, miss))),
    % State a fact for 'pai model score' with the arguments listed below.
    pai_model_score(test_model_004, Score),
    % Check that 'abs(Score - 0.8)' is less than '0.001'.
    abs(Score - 0.8) < 0.001.

%  AC-PR22-005: score >= 0.7 → lifecycle advances from feature to subtask
% Define a clause for 'test': succeed when the following conditions hold.
test(lifecycle_advance_succeeds) :-
    % Add a new fact or rule to the runtime knowledge base.
    assertz(synthesis:synthesized_model(test_model_005,
            % Continue the multi-line expression started above.
            pat_e, pat_f, 300, [], 0.75, feature)),
    % State a fact for 'pai lifecycle advance' with the arguments listed below.
    pai_lifecycle_advance(test_model_005, NewStage),
    % Check that 'NewStage' is unifiable with 'subtask'.
    NewStage = subtask.

%  AC-PR22-006: score < 0.7 → lifecycle stays at feature
% Define a clause for 'test': succeed when the following conditions hold.
test(lifecycle_advance_blocked_low_score) :-
    % Add a new fact or rule to the runtime knowledge base.
    assertz(synthesis:synthesized_model(test_model_006,
            % Continue the multi-line expression started above.
            pat_g, pat_h, 300, [], 0.5, feature)),
    % State a fact for 'pai lifecycle advance' with the arguments listed below.
    pai_lifecycle_advance(test_model_006, NewStage),
    % Check that 'NewStage' is unifiable with 'feature'.
    NewStage = feature.

%  AC-PR22-007: GC deletes model with score < 0.2 and >= 5 predictions
% Define a clause for 'test': succeed when the following conditions hold.
test(model_gc_removes_low_score) :-
    % Add a new fact or rule to the runtime knowledge base.
    assertz(synthesis:synthesized_model(test_model_007,
            % Continue the multi-line expression started above.
            pat_i, pat_j, 400, [], 0.1, subtask)),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 5, _),
           % Continue the multi-line expression started above.
           assertz(synthesis:model_prediction(test_model_007, 0, p_j, miss))),
    % Call the goal 'pai_model_gc'.
    pai_model_gc,
    % Succeed only if 'synthesis:synthesized_model(test_model_007, _, _, _, _, _, _' cannot be proved (negation as failure).
    \+ synthesis:synthesized_model(test_model_007, _, _, _, _, _, _).

%  AC-PR22-008: model compose returns a plan step for subtask-stage model
% Define a clause for 'test': succeed when the following conditions hold.
test(model_compose_returns_plan) :-
    % Add a new fact or rule to the runtime knowledge base.
    assertz(synthesis:synthesized_model(test_model_008,
            % Continue the multi-line expression started above.
            situation_dark, situation_lit, 1000, [], 0.8, subtask)),
    % State a fact for 'pai model compose' with the arguments listed below.
    pai_model_compose(situation_lit, situation_dark, Plan),
    % Check that 'Plan' is unifiable with '[model_step(test_model_008, situation_dark, situation_lit, 1000)]'.
    Plan = [model_step(test_model_008, situation_dark, situation_lit, 1000)].

%  AC-PR22-009: degenerate dataset (all X identical) → constant/1 formula
%  When all inputs share the same X, linear regression is undefined;
%  the regressor falls back to constant(Mean).
% Define a clause for 'test': succeed when the following conditions hold.
test(symbolic_regress_constant) :-
    % Check that 'Points' is unifiable with '[x_y(0,5.0), x_y(0,5.0), x_y(0,5.0), x_y(0,5.0)]'.
    Points = [x_y(0,5.0), x_y(0,5.0), x_y(0,5.0), x_y(0,5.0)],
    % State a fact for 'pai symbolic regress' with the arguments listed below.
    pai_symbolic_regress(Points, [], Formula),
    % Check that 'Formula' is unifiable with 'constant(Mean)'.
    Formula = constant(Mean),
    % Check that 'abs(Mean - 5.0)' is less than '0.001'.
    abs(Mean - 5.0) < 0.001.

% Execute the compile-time directive: end_tests(pr22).
:- end_tests(pr22).
