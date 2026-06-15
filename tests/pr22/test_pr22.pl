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

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],       LatticePath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActorsPath),
   atomic_list_concat([ProjectRoot, '/packs/synthesis/prolog'],      SynthPath),
   assertz(file_search_path(library, LatticePath)),
   assertz(file_search_path(library, VBPath)),
   assertz(file_search_path(library, ActorsPath)),
   assertz(file_search_path(library, SynthPath)).

:- use_module(library(plunit)).
:- use_module(library(lattice),   [lattice_open/2, lattice_close/1]).
:- use_module(library(node_facts),[set_default_nexus/1]).
:- use_module(library(synthesis), [
    pai_observe_event/2,
    pai_model_synthesize/3,
    pai_model_score/2,
    pai_model_compose/3,
    pai_model_gc/0,
    pai_lifecycle_advance/2,
    pai_symbolic_regress/3
]).

:- begin_tests(pr22, [setup(pr22_setup), cleanup(pr22_cleanup)]).

pr22_setup :-
    lattice_open('locus://localhost/pr22', N),
    nb_setval(pr22_nexus_ref, N),
    set_default_nexus(N),
    retractall(synthesis:observed_event(_, _, _)),
    retractall(synthesis:synthesized_model(_, _, _, _, _, _, _)),
    retractall(synthesis:model_prediction(_, _, _, _)),
    retractall(synthesis:model_id_counter(_)),
    retractall(synthesis:obs_id_counter(_)),
    assertz(synthesis:model_id_counter(0)),
    assertz(synthesis:obs_id_counter(0)).

pr22_cleanup :-
    nb_getval(pr22_nexus_ref, N),
    retractall(synthesis:observed_event(_, _, _)),
    retractall(synthesis:synthesized_model(_, _, _, _, _, _, _)),
    retractall(synthesis:model_prediction(_, _, _, _)),
    lattice_close(N).

%  AC-PR22-001: 20 switch_press → light_on pairs (~1 second apart)
%               → synthesize produces a model for this causal pattern
test(model_synthesize_light_switch) :-
    forall(
        between(1, 20, I),
        ( T1 is float(I) * 2.0,
          T2 is T1 + 1.0,
          pai_observe_event(switch_press, T1),
          pai_observe_event(light_on,     T2)
        )
    ),
    pai_model_synthesize([], [], Models),
    Models \= [],
    once((
        member(MId, Models),
        synthesis:synthesized_model(MId, switch_press, light_on, Delta, _, _, _),
        Delta =< 1500
    )).

%  AC-PR22-002: symbolic regressor on linear garden sensor data → R² >= 0.99
test(symbolic_regress_linear) :-
    numlist(1, 10, Xs),
    maplist([X, x_y(X, Y)]>>(Y is 3.0 * X + 7.0), Xs, Points),
    pai_symbolic_regress(Points, [], Formula),
    Formula = linear(Slope, Intercept, r_squared(R2)),
    abs(Slope     - 3.0) < 0.01,
    abs(Intercept - 7.0) < 0.01,
    R2 >= 0.99.

%  AC-PR22-003: fresh model has score 0.5 (no predictions)
test(model_score_no_predictions) :-
    assertz(synthesis:synthesized_model(test_model_003,
            pattern_a, pattern_b, 500, [], 0.5, feature)),
    pai_model_score(test_model_003, Score),
    Score =:= 0.5.

%  AC-PR22-004: 8 hits + 2 misses → score 0.8
test(model_score_from_predictions) :-
    assertz(synthesis:synthesized_model(test_model_004,
            pattern_c, pattern_d, 200, [], 0.5, feature)),
    forall(between(1, 8, _),
           assertz(synthesis:model_prediction(test_model_004, 0, p_d, hit))),
    forall(between(1, 2, _),
           assertz(synthesis:model_prediction(test_model_004, 0, p_d, miss))),
    pai_model_score(test_model_004, Score),
    abs(Score - 0.8) < 0.001.

%  AC-PR22-005: score >= 0.7 → lifecycle advances from feature to subtask
test(lifecycle_advance_succeeds) :-
    assertz(synthesis:synthesized_model(test_model_005,
            pat_e, pat_f, 300, [], 0.75, feature)),
    pai_lifecycle_advance(test_model_005, NewStage),
    NewStage = subtask.

%  AC-PR22-006: score < 0.7 → lifecycle stays at feature
test(lifecycle_advance_blocked_low_score) :-
    assertz(synthesis:synthesized_model(test_model_006,
            pat_g, pat_h, 300, [], 0.5, feature)),
    pai_lifecycle_advance(test_model_006, NewStage),
    NewStage = feature.

%  AC-PR22-007: GC deletes model with score < 0.2 and >= 5 predictions
test(model_gc_removes_low_score) :-
    assertz(synthesis:synthesized_model(test_model_007,
            pat_i, pat_j, 400, [], 0.1, subtask)),
    forall(between(1, 5, _),
           assertz(synthesis:model_prediction(test_model_007, 0, p_j, miss))),
    pai_model_gc,
    \+ synthesis:synthesized_model(test_model_007, _, _, _, _, _, _).

%  AC-PR22-008: model compose returns a plan step for subtask-stage model
test(model_compose_returns_plan) :-
    assertz(synthesis:synthesized_model(test_model_008,
            situation_dark, situation_lit, 1000, [], 0.8, subtask)),
    pai_model_compose(situation_lit, situation_dark, Plan),
    Plan = [model_step(test_model_008, situation_dark, situation_lit, 1000)].

%  AC-PR22-009: degenerate dataset (all X identical) → constant/1 formula
%  When all inputs share the same X, linear regression is undefined;
%  the regressor falls back to constant(Mean).
test(symbolic_regress_constant) :-
    Points = [x_y(0,5.0), x_y(0,5.0), x_y(0,5.0), x_y(0,5.0)],
    pai_symbolic_regress(Points, [], Formula),
    Formula = constant(Mean),
    abs(Mean - 5.0) < 0.001.

:- end_tests(pr22).
