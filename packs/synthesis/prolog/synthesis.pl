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

% Declare this file as the 'synthesis' module and list its exported predicates.
:- module(synthesis, [
    % Continue the multi-line expression started above.
    pai_observe_event/2,      % +Pattern, +Timestamp
    % Continue the multi-line expression started above.
    pai_model_synthesize/3,   % +EventPairs, +Opts, -Models
    % Continue the multi-line expression started above.
    pai_model_score/2,        % +ModelId, -Score
    % Continue the multi-line expression started above.
    pai_model_compose/3,      % +GoalPattern, +CurrentSituation, -Plan
    % Supply 'pai_model_gc/0' as the next argument to the expression above.
    pai_model_gc/0,
    % Continue the multi-line expression started above.
    pai_lifecycle_advance/2,  % +ModelId, -NewStage
    % Continue the multi-line expression started above.
    pai_symbolic_regress/3    % +DataPoints, +Opts, -Formula
% Close the expression opened above.
]).

% Import [anchor_node/4] from the built-in 'node_facts' library.
:- use_module(library(node_facts),  [anchor_node/4]).
% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),       [member/2]).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate),   [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% Declare 'observed_event/3.       % Id, Pattern, Timestamp' as dynamic — its facts may be added or removed at runtime.
:- dynamic observed_event/3.       % Id, Pattern, Timestamp
% Declare 'synthesized_model/7.    % Id, APattern, BPattern, DeltaMs, Guards, Score, Stage' as dynamic — its facts may be added or removed at runtime.
:- dynamic synthesized_model/7.    % Id, APattern, BPattern, DeltaMs, Guards, Score, Stage
% Declare 'model_prediction/4.     % ModelId, PredTimestamp, BPattern, Outcome(hit|miss)' as dynamic — its facts may be added or removed at runtime.
:- dynamic model_prediction/4.     % ModelId, PredTimestamp, BPattern, Outcome(hit|miss)

% Declare 'model_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic model_id_counter/1.
% State the fact: model id counter(0).
model_id_counter(0).
% Declare 'obs_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic obs_id_counter/1.
% State the fact: obs id counter(0).
obs_id_counter(0).

% Define a clause for 'next model id': succeed when the following conditions hold.
next_model_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(model_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(model_id_counter(N1)),
    % State the fact: atomic list concat([model_, N1], Id).
    atomic_list_concat([model_, N1], Id).

% Define a clause for 'next obs id': succeed when the following conditions hold.
next_obs_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(obs_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(obs_id_counter(N1)),
    % Check that 'Id' is unifiable with 'N1'.
    Id = N1.

% Lifecycle stage order
% State the fact: lifecycle stage order(feature,  1).
lifecycle_stage_order(feature,  1).
% State the fact: lifecycle stage order(subtask,  2).
lifecycle_stage_order(subtask,  2).
% State the fact: lifecycle stage order(option,   3).
lifecycle_stage_order(option,   3).
% State the fact: lifecycle stage order(model,    4).
lifecycle_stage_order(model,    4).
% State the fact: lifecycle stage order(plan,     5).
lifecycle_stage_order(plan,     5).

% Define a clause for 'next lifecycle stage': succeed when the following conditions hold.
next_lifecycle_stage(Current, Next) :-
    % State a fact for 'lifecycle stage order' with the arguments listed below.
    lifecycle_stage_order(Current, N),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % State the fact: lifecycle stage order(Next, N1).
    lifecycle_stage_order(Next, N1).

% State a fact for 'score threshold gc' with the arguments listed below.
score_threshold_gc(0.2).           % delete models below this score
% State a fact for 'score threshold advance' with the arguments listed below.
score_threshold_advance(0.7).      % advance lifecycle above this score

% ---------------------------------------------------------------------------
% pai_observe_event/2 — log an observation for later synthesis
% ---------------------------------------------------------------------------

% Define a clause for 'pai observe event': succeed when the following conditions hold.
pai_observe_event(Pattern, Timestamp) :-
    % State a fact for 'next obs id' with the arguments listed below.
    next_obs_id(Id),
    % Add a new fact or rule to the runtime knowledge base.
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

% Define a clause for 'pai model synthesize': succeed when the following conditions hold.
pai_model_synthesize(EventPairs, _Opts, Models) :-
    % Check that '( EventPairs' is unifiable with '[]'.
    ( EventPairs = []
    % If the condition above succeeded, perform the following action.
    ->  findall(I1-I2, (
            % Continue the multi-line expression started above.
            observed_event(I1, _P1, T1),
            % Continue the multi-line expression started above.
            observed_event(I2, _P2, T2),
            % Continue the multi-line expression started above.
            I1 \= I2,
            % Continue the multi-line expression started above.
            T2 > T1,
            % Continue the multi-line expression started above.
            T2 - T1 < 10.0
        % Continue the multi-line expression started above.
        ), Pairs)
    % Otherwise (else branch), perform the following action.
    ;   Pairs = EventPairs
    % Close the expression opened above.
    ),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(MId, (
        % Continue the multi-line expression started above.
        member(I1-I2, Pairs),
        % Continue the multi-line expression started above.
        observed_event(I1, PatA, T1),
        % Continue the multi-line expression started above.
        observed_event(I2, PatB, T2),
        % Continue the multi-line expression started above.
        T2 > T1,
        % Continue the multi-line expression started above.
        DeltaMs is (T2 - T1) * 1000,
        % Continue the multi-line expression started above.
        synthesize_one_model(PatA, PatB, DeltaMs, [], MId)
    % Continue the multi-line expression started above.
    ), AllIds),
    % Sort list 'AllIds' into 'Models', removing duplicates.
    sort(AllIds, Models).

% Define a clause for 'synthesize one model': succeed when the following conditions hold.
synthesize_one_model(APattern, BPattern, DeltaMs, Guards, MId) :-
    % Execute: ( synthesized_model(ExId, APattern, BPattern, _, Guards, _, _).
    ( synthesized_model(ExId, APattern, BPattern, _, Guards, _, _)
    % If the condition above succeeded, perform the following action.
    ->  MId = ExId
    % Otherwise (else branch), perform the following action.
    ;   next_model_id(MId),
        % Continue the multi-line expression started above.
        assertz(synthesized_model(MId, APattern, BPattern,
                                  % Continue the multi-line expression started above.
                                  DeltaMs, Guards, 0.5, feature)),
        % Continue the multi-line expression started above.
        catch(
            % Continue the multi-line expression started above.
            anchor_node(causal_model,
                        % Continue the multi-line expression started above.
                        [MId, if(APattern, then(BPattern), within(DeltaMs))],
                        % Continue the multi-line expression started above.
                        [lifecycle=feature, score=0.5, guards=Guards],
                        % Supply '_' as the next argument to the expression above.
                        _),
            % Continue the multi-line expression started above.
            _, true
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_model_score/2
%
%   Score = hits / (hits + misses), or 0.5 if no predictions yet.
%   Updates the stored score.
% ---------------------------------------------------------------------------

% Define a clause for 'pai model score': succeed when the following conditions hold.
pai_model_score(ModelId, Score) :-
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count, model_prediction(ModelId, _, _, hit),  Hits),
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count, model_prediction(ModelId, _, _, miss), Misses),
    % Evaluate the arithmetic expression 'Hits + Misses' and bind the result to 'Total'.
    Total is Hits + Misses,
    % Check that '( Total' is greater than '0'.
    ( Total > 0
    % If the condition above succeeded, perform the following action.
    ->  Score is Hits / Total
    % Otherwise (else branch), perform the following action.
    ;   Score = 0.5
    % Close the expression opened above.
    ),
    % Execute: ( retract(synthesized_model(ModelId, A, B, D, G, _, Stage)).
    ( retract(synthesized_model(ModelId, A, B, D, G, _, Stage))
    % If the condition above succeeded, perform the following action.
    ->  assertz(synthesized_model(ModelId, A, B, D, G, Score, Stage))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_model_compose/3
%
%   Chain models backward from GoalPattern to CurrentSituation.
%   Plan = [model_step(MId, APattern, BPattern, Delta) | …]
% ---------------------------------------------------------------------------

% Define a clause for 'pai model compose': succeed when the following conditions hold.
pai_model_compose(GoalPattern, CurrentSituation, Plan) :-
    % Execute: ( synthesized_model(MId, APattern, GoalPattern, Delta, _G, Score, Stage),.
    ( synthesized_model(MId, APattern, GoalPattern, Delta, _G, Score, Stage),
      % Continue the multi-line expression started above.
      Stage \= feature,
      % Continue the multi-line expression started above.
      Score > 0.3
    % If the condition above succeeded, perform the following action.
    ->  ( APattern = CurrentSituation
        % If the condition above succeeded, perform the following action.
        ->  Plan = [model_step(MId, APattern, GoalPattern, Delta)]
        % Otherwise (else branch), perform the following action.
        ;   ( pai_model_compose(APattern, CurrentSituation, SubPlan)
            % If the condition above succeeded, perform the following action.
            ->  Plan = [model_step(MId, APattern, GoalPattern, Delta)|SubPlan]
            % Otherwise (else branch), perform the following action.
            ;   Plan = [model_step(MId, APattern, GoalPattern, Delta)]
            % Close the expression opened above.
            )
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   Plan = []
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_model_gc/0 — garbage collect persistently mispredicting models
% ---------------------------------------------------------------------------

% Execute: pai_model_gc :-.
pai_model_gc :-
    % State a fact for 'score threshold gc' with the arguments listed below.
    score_threshold_gc(Threshold),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(MId, (
        % Continue the multi-line expression started above.
        synthesized_model(MId, _, _, _, _, Score, _),
        % Continue the multi-line expression started above.
        Score < Threshold,
        % Continue the multi-line expression started above.
        aggregate_all(count, model_prediction(MId, _, _, _), N),
        % Continue the multi-line expression started above.
        N >= 5
    % Continue the multi-line expression started above.
    ), ToDelete),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(MId, ToDelete),
        % Continue the multi-line expression started above.
        ( retractall(synthesized_model(MId, _, _, _, _, _, _)),
          % Continue the multi-line expression started above.
          retractall(model_prediction(MId, _, _, _))
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_lifecycle_advance/2
%
%   Advance ModelId to its next stage when its score >= threshold.
% ---------------------------------------------------------------------------

% Define a clause for 'pai lifecycle advance': succeed when the following conditions hold.
pai_lifecycle_advance(ModelId, NewStage) :-
    % Execute: ( synthesized_model(ModelId, A, B, D, G, Score, Stage).
    ( synthesized_model(ModelId, A, B, D, G, Score, Stage)
    % If the condition above succeeded, perform the following action.
    ->  score_threshold_advance(Threshold),
        % Continue the multi-line expression started above.
        ( Score >= Threshold
        % If the condition above succeeded, perform the following action.
        ->  ( next_lifecycle_stage(Stage, NewStage)
            % If the condition above succeeded, perform the following action.
            ->  retract(synthesized_model(ModelId, A, B, D, G, Score, Stage)),
                % Continue the multi-line expression started above.
                assertz(synthesized_model(ModelId, A, B, D, G, Score, NewStage))
            % Otherwise (else branch), perform the following action.
            ;   NewStage = Stage
            % Close the expression opened above.
            )
        % Otherwise (else branch), perform the following action.
        ;   NewStage = Stage
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   NewStage = unknown
    % Close the expression opened above.
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

% Define a clause for 'pai symbolic regress': succeed when the following conditions hold.
pai_symbolic_regress(DataPoints, _Opts, Formula) :-
    % Check that 'DataPoints' is not unifiable with '[]'.
    DataPoints \= [],
    % Unify 'N' with the number of elements in list 'DataPoints'.
    length(DataPoints, N),
    % Evaluate the arithmetic expression 'float(N)' and bind the result to 'NF'.
    NF is float(N),
    % Sums
    % Aggregate solutions using 'sum' and bind the result to a single value.
    aggregate_all(sum(X),   member(x_y(X, _), DataPoints), Sx),
    % Aggregate solutions using 'sum' and bind the result to a single value.
    aggregate_all(sum(Y),   member(x_y(_, Y), DataPoints), Sy),
    % Aggregate solutions using 'sum' and bind the result to a single value.
    aggregate_all(sum(XX),  (member(x_y(X, _), DataPoints), XX is X*X), Sxx),
    % Aggregate solutions using 'sum' and bind the result to a single value.
    aggregate_all(sum(XY),  (member(x_y(X, Y), DataPoints), XY is X*Y), Sxy),
    % Evaluate the arithmetic expression 'NF * Sxx - Sx * Sx' and bind the result to 'Denom'.
    Denom is NF * Sxx - Sx * Sx,
    % Check that '( abs(Denom)' is less than '1.0e-12'.
    ( abs(Denom) < 1.0e-12
    % If the condition above succeeded, perform the following action.
    ->  Mean is Sy / NF,
        % Continue the multi-line expression started above.
        Formula = constant(Mean)
    % Otherwise (else branch), perform the following action.
    ;   Slope     is (NF * Sxy - Sx * Sy) / Denom,
        % Continue the multi-line expression started above.
        Intercept is (Sy - Slope * Sx) / NF,
        % Compute R² for quality annotation
        % Continue the multi-line expression started above.
        MeanY is Sy / NF,
        % Continue the multi-line expression started above.
        aggregate_all(sum(SSres),
            % Continue the multi-line expression started above.
            (member(x_y(X, Y), DataPoints),
             % Continue the multi-line expression started above.
             Pred is Slope * X + Intercept,
             % Continue the multi-line expression started above.
             Err  is Y - Pred,
             % Continue the multi-line expression started above.
             SSres is Err * Err),
            % Supply 'SStot_res' as the next argument to the expression above.
            SStot_res),
        % Continue the multi-line expression started above.
        aggregate_all(sum(SStot),
            % Continue the multi-line expression started above.
            (member(x_y(_, Y), DataPoints),
             % Continue the multi-line expression started above.
             Dev is Y - MeanY,
             % Continue the multi-line expression started above.
             SStot is Dev * Dev),
            % Supply 'SStot_val' as the next argument to the expression above.
            SStot_val),
        % Continue the multi-line expression started above.
        ( SStot_val < 1.0e-12
        % If the condition above succeeded, perform the following action.
        ->  R2 = 1.0
        % Otherwise (else branch), perform the following action.
        ;   R2 is 1.0 - SStot_res / SStot_val
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        Formula = linear(Slope, Intercept, r_squared(R2))
    % Close the expression opened above.
    ).
