/*  PrologAI — Self-Programming Seed: Model Synthesis  (Specification PR 22)

    Implements the AERA core: a protected seed plus machinery that
    continuously synthesizes, scores, composes, and deletes small
    executable models.

    A model captures: if pattern A at time T, then pattern B by T+Delta,
    with optional guard conditions.  Models are node_facts (code as data)
    with predictable, small execution cost.

    Lifecycle stages for causal competences:
      feature  → subtask → option → model → plan

    Predicates:
      pai_observe_event/2    — log an observation (pattern + timestamp)
      pai_model_synthesize/3 — generate candidate models from event pairs
      pai_model_score/2      — score a model against observed outcomes
      pai_model_compose/3    — chain models from current situation to goal
      pai_model_gc/0         — garbage-collect persistently mispredicting models
      pai_lifecycle_advance/2— advance a competence to the next stage
      pai_symbolic_regress/3 — find a human-readable formula for data points
*/

:- module(synthesis, [
    pai_observe_event/2,      % +Pattern, +Timestamp
    pai_model_synthesize/3,   % +EventPairs, +Opts, -Models
    pai_model_score/2,        % +ModelId, -Score
    pai_model_compose/3,      % +GoalPattern, +CurrentSituation, -Plan
    pai_model_gc/0,
    pai_lifecycle_advance/2,  % +ModelId, -NewStage
    pai_symbolic_regress/3    % +DataPoints, +Opts, -Formula
]).

:- use_module(library(node_facts),  [anchor_node/4]).
:- use_module(library(lists),       [member/2]).
:- use_module(library(aggregate),   [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

:- dynamic observed_event/3.       % Id, Pattern, Timestamp
:- dynamic synthesized_model/7.    % Id, APattern, BPattern, DeltaMs, Guards, Score, Stage
:- dynamic model_prediction/4.     % ModelId, PredTimestamp, BPattern, Outcome(hit|miss)

:- dynamic model_id_counter/1.
model_id_counter(0).
:- dynamic obs_id_counter/1.
obs_id_counter(0).

next_model_id(Id) :-
    retract(model_id_counter(N)),
    N1 is N + 1,
    assertz(model_id_counter(N1)),
    atomic_list_concat([model_, N1], Id).

next_obs_id(Id) :-
    retract(obs_id_counter(N)),
    N1 is N + 1,
    assertz(obs_id_counter(N1)),
    Id = N1.

% Lifecycle stage order
lifecycle_stage_order(feature,  1).
lifecycle_stage_order(subtask,  2).
lifecycle_stage_order(option,   3).
lifecycle_stage_order(model,    4).
lifecycle_stage_order(plan,     5).

next_lifecycle_stage(Current, Next) :-
    lifecycle_stage_order(Current, N),
    N1 is N + 1,
    lifecycle_stage_order(Next, N1).

score_threshold_gc(0.2).           % delete models below this score
score_threshold_advance(0.7).      % advance lifecycle above this score

% ---------------------------------------------------------------------------
% pai_observe_event/2 — log an observation for later synthesis
% ---------------------------------------------------------------------------

pai_observe_event(Pattern, Timestamp) :-
    next_obs_id(Id),
    assertz(observed_event(Id, Pattern, Timestamp)).

% ---------------------------------------------------------------------------
% pai_model_synthesize/3
%
%   Generate candidate models from event pairs in the observation log.
%   For each pair (A at T1, B at T2 > T1) within a 10-second window,
%   propose: if A → B within (T2-T1) ms.
%
%   EventPairs = []  → synthesize from all logged observations
%   EventPairs = [I1-I2|…] → only consider those specific id-pairs
%   Models     = list of model-id atoms for newly synthesized models
% ---------------------------------------------------------------------------

pai_model_synthesize(EventPairs, _Opts, Models) :-
    ( EventPairs = []
    ->  findall(I1-I2, (
            observed_event(I1, _P1, T1),
            observed_event(I2, _P2, T2),
            I1 \= I2,
            T2 > T1,
            T2 - T1 < 10.0
        ), Pairs)
    ;   Pairs = EventPairs
    ),
    findall(MId, (
        member(I1-I2, Pairs),
        observed_event(I1, PatA, T1),
        observed_event(I2, PatB, T2),
        T2 > T1,
        DeltaMs is (T2 - T1) * 1000,
        synthesize_one_model(PatA, PatB, DeltaMs, [], MId)
    ), AllIds),
    sort(AllIds, Models).

synthesize_one_model(APattern, BPattern, DeltaMs, Guards, MId) :-
    ( synthesized_model(ExId, APattern, BPattern, _, Guards, _, _)
    ->  MId = ExId
    ;   next_model_id(MId),
        assertz(synthesized_model(MId, APattern, BPattern,
                                  DeltaMs, Guards, 0.5, feature)),
        catch(
            anchor_node(causal_model,
                        [MId, if(APattern, then(BPattern), within(DeltaMs))],
                        [lifecycle=feature, score=0.5, guards=Guards],
                        _),
            _, true
        )
    ).

% ---------------------------------------------------------------------------
% pai_model_score/2
%
%   Score = hits / (hits + misses), or 0.5 if no predictions yet.
%   Updates the stored score.
% ---------------------------------------------------------------------------

pai_model_score(ModelId, Score) :-
    aggregate_all(count, model_prediction(ModelId, _, _, hit),  Hits),
    aggregate_all(count, model_prediction(ModelId, _, _, miss), Misses),
    Total is Hits + Misses,
    ( Total > 0
    ->  Score is Hits / Total
    ;   Score = 0.5
    ),
    ( retract(synthesized_model(ModelId, A, B, D, G, _, Stage))
    ->  assertz(synthesized_model(ModelId, A, B, D, G, Score, Stage))
    ;   true
    ).

% ---------------------------------------------------------------------------
% pai_model_compose/3
%
%   Chain models backward from GoalPattern to CurrentSituation.
%   Plan = [model_step(MId, APattern, BPattern, Delta) | …]
% ---------------------------------------------------------------------------

pai_model_compose(GoalPattern, CurrentSituation, Plan) :-
    ( synthesized_model(MId, APattern, GoalPattern, Delta, _G, Score, Stage),
      Stage \= feature,
      Score > 0.3
    ->  ( APattern = CurrentSituation
        ->  Plan = [model_step(MId, APattern, GoalPattern, Delta)]
        ;   ( pai_model_compose(APattern, CurrentSituation, SubPlan)
            ->  Plan = [model_step(MId, APattern, GoalPattern, Delta)|SubPlan]
            ;   Plan = [model_step(MId, APattern, GoalPattern, Delta)]
            )
        )
    ;   Plan = []
    ).

% ---------------------------------------------------------------------------
% pai_model_gc/0 — garbage collect persistently mispredicting models
% ---------------------------------------------------------------------------

pai_model_gc :-
    score_threshold_gc(Threshold),
    findall(MId, (
        synthesized_model(MId, _, _, _, _, Score, _),
        Score < Threshold,
        aggregate_all(count, model_prediction(MId, _, _, _), N),
        N >= 5
    ), ToDelete),
    forall(
        member(MId, ToDelete),
        ( retractall(synthesized_model(MId, _, _, _, _, _, _)),
          retractall(model_prediction(MId, _, _, _))
        )
    ).

% ---------------------------------------------------------------------------
% pai_lifecycle_advance/2
%
%   Advance ModelId to its next stage when its score >= threshold.
% ---------------------------------------------------------------------------

pai_lifecycle_advance(ModelId, NewStage) :-
    ( synthesized_model(ModelId, A, B, D, G, Score, Stage)
    ->  score_threshold_advance(Threshold),
        ( Score >= Threshold
        ->  ( next_lifecycle_stage(Stage, NewStage)
            ->  retract(synthesized_model(ModelId, A, B, D, G, Score, Stage)),
                assertz(synthesized_model(ModelId, A, B, D, G, Score, NewStage))
            ;   NewStage = Stage
            )
        ;   NewStage = Stage
        )
    ;   NewStage = unknown
    ).

% ---------------------------------------------------------------------------
% pai_symbolic_regress/3
%
%   Find a human-readable formula fitting DataPoints.
%   DataPoints: list of x-y(X,Y) terms.
%   Opts:       option list (unused; reserved for future domain hints).
%   Formula:    linear(Slope, Intercept) with fit quality annotation,
%               or constant(Mean) when Sx is zero.
%
%   Uses ordinary least-squares for linear regression.
% ---------------------------------------------------------------------------

pai_symbolic_regress(DataPoints, _Opts, Formula) :-
    DataPoints \= [],
    length(DataPoints, N),
    NF is float(N),
    % Sums
    aggregate_all(sum(X),   member(x_y(X, _), DataPoints), Sx),
    aggregate_all(sum(Y),   member(x_y(_, Y), DataPoints), Sy),
    aggregate_all(sum(XX),  (member(x_y(X, _), DataPoints), XX is X*X), Sxx),
    aggregate_all(sum(XY),  (member(x_y(X, Y), DataPoints), XY is X*Y), Sxy),
    Denom is NF * Sxx - Sx * Sx,
    ( abs(Denom) < 1.0e-12
    ->  Mean is Sy / NF,
        Formula = constant(Mean)
    ;   Slope     is (NF * Sxy - Sx * Sy) / Denom,
        Intercept is (Sy - Slope * Sx) / NF,
        % Compute R² for quality annotation
        MeanY is Sy / NF,
        aggregate_all(sum(SSres),
            (member(x_y(X, Y), DataPoints),
             Pred is Slope * X + Intercept,
             Err  is Y - Pred,
             SSres is Err * Err),
            SStot_res),
        aggregate_all(sum(SStot),
            (member(x_y(_, Y), DataPoints),
             Dev is Y - MeanY,
             SStot is Dev * Dev),
            SStot_val),
        ( SStot_val < 1.0e-12
        ->  R2 = 1.0
        ;   R2 is 1.0 - SStot_res / SStot_val
        ),
        Formula = linear(Slope, Intercept, r_squared(R2))
    ).
