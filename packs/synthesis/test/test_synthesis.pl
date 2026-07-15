/*  PrologAI — synthesis pack in-pack PLUnit regression suite

    Behavioural tests for the Self-Programming Seed (model synthesis):
      - synthesis_symbolic_regress/3 recovers a known linear law and its R².
      - synthesis_symbolic_regress/3 falls back to constant/1 on degenerate data.
      - synthesis_model_score/2 returns 0.5 with no predictions and 0.8 for 8/10 hits.
      - synthesis_lifecycle_advance/2 promotes at score >= 0.7 and blocks below it.
      - synthesis_model_gc/0 deletes a low-score model with >= 5 predictions.
      - synthesis_model_compose/3 chains a subtask model from situation to goal.
      - synthesis_observe_event/2 + synthesis_model_synthesize/3 build a causal model.
    The synthesize path anchors a node inside a catch/3, so no lattice is needed.
*/

% Declare this file as the 'test_synthesis' module exporting nothing.
:- module(test_synthesis, []).
% Load the built-in 'plunit' library so its test predicates are available here.
:- use_module(library(plunit)).
% Load the 'synthesis' library under test so its predicates are available here.
:- use_module(library(synthesis), [
    % Supply 'synthesis_observe_event/2' as the next argument to the expression above.
    synthesis_observe_event/2,
    % Supply 'synthesis_model_synthesize/3' as the next argument to the expression above.
    synthesis_model_synthesize/3,
    % Supply 'synthesis_model_score/2' as the next argument to the expression above.
    synthesis_model_score/2,
    % Supply 'synthesis_model_compose/3' as the next argument to the expression above.
    synthesis_model_compose/3,
    % Supply 'synthesis_model_gc/0' as the next argument to the expression above.
    synthesis_model_gc/0,
    % Supply 'synthesis_lifecycle_advance/2' as the next argument to the expression above.
    synthesis_lifecycle_advance/2,
    % Supply 'synthesis_symbolic_regress/3' as the next argument to the expression above.
    synthesis_symbolic_regress/3
% Close the export list opened above.
]).

% Reset every dynamic fact and counter so each test starts from a clean seed.
synthesis_test_reset :-
    % Remove all logged observation events from the synthesis module.
    retractall(synthesis:observed_event(_, _, _)),
    % Remove all synthesized models from the synthesis module.
    retractall(synthesis:synthesized_model(_, _, _, _, _, _, _)),
    % Remove all recorded model predictions from the synthesis module.
    retractall(synthesis:model_prediction(_, _, _, _)),
    % Remove the current model-id counter fact.
    retractall(synthesis:model_id_counter(_)),
    % Remove the current observation-id counter fact.
    retractall(synthesis:obs_id_counter(_)),
    % Re-seed the model-id counter at zero.
    assertz(synthesis:model_id_counter(0)),
    % Re-seed the observation-id counter at zero.
    assertz(synthesis:obs_id_counter(0)).

% Open the 'synthesis' test block, resetting state before each test.
:- begin_tests(synthesis, [setup(synthesis_test_reset)]).

% Linear data y = 3x + 7 should be recovered as linear/3 with R² of one.
test(symbolic_regress_linear) :-
    % Build the integer inputs 1 through 10.
    numlist(1, 10, Xs),
    % Turn each input into an x_y point lying exactly on y = 3x + 7.
    maplist([X, x_y(X, Y)]>>(Y is 3.0 * X + 7.0), Xs, Points),
    % Regress a symbolic formula from the perfectly linear points.
    synthesis_symbolic_regress(Points, [], Formula),
    % Confirm the result is a linear formula with a reported R² value.
    Formula = linear(Slope, Intercept, r_squared(R2)),
    % Assert the recovered slope is three within tolerance.
    assertion(abs(Slope - 3.0) < 0.01),
    % Assert the recovered intercept is seven within tolerance.
    assertion(abs(Intercept - 7.0) < 0.01),
    % Assert the fit quality R² is essentially perfect.
    assertion(R2 >= 0.99).

% Points that share one X are undefined for a line and fall back to constant/1.
test(symbolic_regress_constant) :-
    % Provide four points all at X = 0 with value 5.0.
    Points = [x_y(0, 5.0), x_y(0, 5.0), x_y(0, 5.0), x_y(0, 5.0)],
    % Regress a symbolic formula from the degenerate points.
    synthesis_symbolic_regress(Points, [], Formula),
    % Confirm the regressor returned a constant formula holding the mean.
    Formula = constant(Mean),
    % Assert the constant equals the shared value 5.0.
    assertion(abs(Mean - 5.0) < 0.001).

% A freshly stored model with no predictions scores the neutral prior 0.5.
test(model_score_no_predictions) :-
    % Store a candidate model in the synthesis knowledge base.
    assertz(synthesis:synthesized_model(m_none, pat_a, pat_b, 500, [], 0.5, feature)),
    % Score the model that has zero hit or miss predictions.
    synthesis_model_score(m_none, Score),
    % Assert the score is exactly the 0.5 no-evidence prior.
    assertion(Score =:= 0.5).

% Eight hits out of ten predictions should score the model at 0.8.
test(model_score_from_predictions) :-
    % Store a candidate model to accumulate predictions against.
    assertz(synthesis:synthesized_model(m_hits, pat_c, pat_d, 200, [], 0.5, feature)),
    % Record eight successful (hit) predictions for the model.
    forall(between(1, 8, _), assertz(synthesis:model_prediction(m_hits, 0, pat_d, hit))),
    % Record two failed (miss) predictions for the model.
    forall(between(1, 2, _), assertz(synthesis:model_prediction(m_hits, 0, pat_d, miss))),
    % Score the model from its eight-hit, two-miss record.
    synthesis_model_score(m_hits, Score),
    % Assert the score equals hits over total, that is 0.8.
    assertion(abs(Score - 0.8) < 0.001).

% A model scoring 0.75 (>= 0.7 threshold) advances feature to subtask.
test(lifecycle_advance_succeeds) :-
    % Store a high-scoring model at the earliest lifecycle stage.
    assertz(synthesis:synthesized_model(m_adv, pat_e, pat_f, 300, [], 0.75, feature)),
    % Attempt to advance the model's lifecycle stage.
    synthesis_lifecycle_advance(m_adv, NewStage),
    % Assert the stage advanced from feature to subtask.
    assertion(NewStage == subtask).

% A model scoring 0.5 (below 0.7 threshold) must stay at feature.
test(lifecycle_advance_blocked_low_score) :-
    % Store a low-scoring model at the earliest lifecycle stage.
    assertz(synthesis:synthesized_model(m_stay, pat_g, pat_h, 300, [], 0.5, feature)),
    % Attempt to advance the low-scoring model's lifecycle stage.
    synthesis_lifecycle_advance(m_stay, NewStage),
    % Assert the stage remained at feature because the score was too low.
    assertion(NewStage == feature).

% Garbage collection deletes a model below 0.2 with at least five predictions.
test(model_gc_removes_low_score) :-
    % Store a persistently mispredicting model at score 0.1.
    assertz(synthesis:synthesized_model(m_gc, pat_i, pat_j, 400, [], 0.1, subtask)),
    % Record five miss predictions so the model is eligible for collection.
    forall(between(1, 5, _), assertz(synthesis:model_prediction(m_gc, 0, pat_j, miss))),
    % Run garbage collection over the model set.
    synthesis_model_gc,
    % Assert the low-scoring model was removed from the knowledge base.
    assertion(\+ synthesis:synthesized_model(m_gc, _, _, _, _, _, _)).

% Compose chains a promoted subtask model from current situation to goal.
test(model_compose_returns_plan) :-
    % Store a subtask-stage model linking a dark situation to a lit one.
    assertz(synthesis:synthesized_model(m_plan, situation_dark, situation_lit, 1000, [], 0.8, subtask)),
    % Ask for a plan reaching the lit goal from the dark situation.
    synthesis_model_compose(situation_lit, situation_dark, Plan),
    % Assert the plan is the single expected model step.
    assertion(Plan == [model_step(m_plan, situation_dark, situation_lit, 1000)]).

% Observing repeated switch_press then light_on pairs synthesizes a causal model.
test(observe_and_synthesize_builds_model) :-
    % Log twenty switch_press then light_on observations one second apart.
    forall(between(1, 20, I),
           ( T1 is float(I) * 2.0,
             T2 is T1 + 1.0,
             synthesis_observe_event(switch_press, T1),
             synthesis_observe_event(light_on, T2) )),
    % Synthesize candidate models from all logged observation pairs.
    synthesis_model_synthesize([], [], Models),
    % Assert at least one model was synthesized.
    assertion(Models \= []),
    % Assert one model captures switch_press causing light_on within 1500 ms.
    assertion(once(( member(MId, Models),
                     synthesis:synthesized_model(MId, switch_press, light_on, Delta, _, _, _),
                     Delta =< 1500 ))).

% Close the 'synthesis' test block opened above.
:- end_tests(synthesis).
