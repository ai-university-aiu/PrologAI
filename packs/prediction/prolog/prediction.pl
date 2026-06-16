/*  PrologAI — Prediction and Active Inference  (Specification PR 19)

    Implements the hierarchical predictive-processing architecture: predictions
    flow down the Lattice tiers, only residual errors flow up, errors are
    precision-weighted so noisy channels do not dominate salience.

    Three explicit loops:
      perception — state inference from situation (pai_infer_state/2)
      learning   — delegated to PR 22 generative model
      planning   — policy selection by expected utility

    Dark-room guard: the system records a standing curiosity prior so that
    doing nothing is itself surprising (prevents a quiescent attractor).

    Predicates:

    pai_generate_prediction/3  — generate downward prediction for a situation
    pai_prediction_residual/3  — compute precision-weighted residual (error)
    pai_precision/2            — query or update channel precision weight
    pai_minimize_free_energy/1 — run one free-energy minimization step
    pai_infer_state/2          — perceive: infer abstract state from node_facts
    pai_route_disturbance/1    — route unresolved error to regulation/compensation
*/

% Declare this file as the 'prediction' module and list its exported predicates.
:- module(prediction, [
    % Continue the multi-line expression started above.
    pai_generate_prediction/3,   % +Channel, +Situation, -PredictedState
    % Continue the multi-line expression started above.
    pai_prediction_residual/3,   % +Channel, +Observed, -WeightedResidual
    % Continue the multi-line expression started above.
    pai_precision/2,             % +Channel, -Precision  (or update with +Precision)
    % Continue the multi-line expression started above.
    pai_minimize_free_energy/1,  % +Situation
    % Continue the multi-line expression started above.
    pai_infer_state/2,           % +Nexus, -InferredState
    % Continue the multi-line expression started above.
    pai_route_disturbance/1      % +Residual
% Close the expression opened above.
]).

% Load the built-in 'node_facts' library so its predicates are available here.
:- use_module(library(node_facts),  [anchor_node/4, traverse_nexus/4,
                                     % Continue the multi-line expression started above.
                                     default_nexus/1]).
% Import [lattice_node_fact/5, nexus_is_open/1] from the built-in 'lattice' library.
:- use_module(library(lattice),     [lattice_node_fact/5, nexus_is_open/1]).
% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),       [member/2]).
% Import [maplist/3] from the built-in 'apply' library.
:- use_module(library(apply),       [maplist/3]).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate),   [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Channel precision weights
%
%   precision(Channel, Weight) — Weight ∈ (0, 1]
%   Higher weight = more confident; lower weight = more noise expected.
%   Adapted downward when the channel's variance is high relative to predictions.
% ---------------------------------------------------------------------------

% Declare 'channel_precision/2.     % Channel, Weight' as dynamic — its facts may be added or removed at runtime.
:- dynamic channel_precision/2.     % Channel, Weight
% Declare 'channel_error_history/3. % Channel, Timestamp, ErrorMagnitude' as dynamic — its facts may be added or removed at runtime.
:- dynamic channel_error_history/3. % Channel, Timestamp, ErrorMagnitude

% State the fact: default precision(0.8).
default_precision(0.8).

% Define a clause for 'pai precision': succeed when the following conditions hold.
pai_precision(Channel, Precision) :-
    % Execute: ( channel_precision(Channel, Precision).
    ( channel_precision(Channel, Precision)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   default_precision(Precision)
    % Close the expression opened above.
    ).

% Define a clause for 'update precision': succeed when the following conditions hold.
update_precision(Channel, NewPrecision) :-
    % Evaluate the arithmetic expression 'max(0.05, min(1.0, NewPrecision))' and bind the result to 'Clamped'.
    Clamped is max(0.05, min(1.0, NewPrecision)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(channel_precision(Channel, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(channel_precision(Channel, Clamped)).

% ---------------------------------------------------------------------------
% Generative model — stored as prediction node_facts
%
%   prediction_model(Channel, Situation, PredictedRelation, PredictedArgs)
%   The model is populated by SONA crystallization (PR 11) and the
%   PR 22 learning loop; here it starts empty and builds from experience.
% ---------------------------------------------------------------------------

% Declare 'prediction_model/4.     % Channel, Situation, Relation, Args' as dynamic — its facts may be added or removed at runtime.
:- dynamic prediction_model/4.     % Channel, Situation, Relation, Args

% ---------------------------------------------------------------------------
% pai_generate_prediction/3
%
%   Generate a downward prediction for a given situation on a channel.
%   Falls back to a "no change" prior if no model entry exists.
% ---------------------------------------------------------------------------

% Define a clause for 'pai generate prediction': succeed when the following conditions hold.
pai_generate_prediction(Channel, Situation, PredictedState) :-
    % Execute: ( prediction_model(Channel, Situation, Relation, Args).
    ( prediction_model(Channel, Situation, Relation, Args)
    % If the condition above succeeded, perform the following action.
    ->  PredictedState = prediction(Channel, Situation, Relation, Args)
    % Otherwise (else branch), perform the following action.
    ;   % No model: prior = expect the most recently observed relation
        % Continue the multi-line expression started above.
        ( catch(default_nexus(Nexus), _, fail),
          % Continue the multi-line expression started above.
          nexus_is_open(Nexus),
          % Continue the multi-line expression started above.
          once(lattice:lattice_node_fact(Nexus, _, Relation, [Situation|_], _))
        % If the condition above succeeded, perform the following action.
        ->  PredictedState = prediction(Channel, Situation, Relation, [Situation])
        % Otherwise (else branch), perform the following action.
        ;   PredictedState = prediction(Channel, Situation, unknown, [])
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_prediction_residual/3
%
%   Compute the precision-weighted prediction error for a channel:
%     residual = precision * |observed - predicted|
%
%   Observed is a list of node_fact terms.
%   Returns a weighted_residual/3 term and records it for history.
%   Adapts the channel's precision based on variance.
% ---------------------------------------------------------------------------

% Define a clause for 'pai prediction residual': succeed when the following conditions hold.
pai_prediction_residual(Channel, Observed, WeightedResidual) :-
    % State a fact for 'pai precision' with the arguments listed below.
    pai_precision(Channel, Precision),
    % State a fact for 'pai generate prediction' with the arguments listed below.
    pai_generate_prediction(Channel, unknown, Predicted),
    % State a fact for 'raw error' with the arguments listed below.
    raw_error(Predicted, Observed, RawError),
    % Evaluate the arithmetic expression 'Precision * RawError' and bind the result to 'WeightedResidual'.
    WeightedResidual is Precision * RawError,
    % Record for history and precision adaptation
    % State a fact for 'get time' with the arguments listed below.
    get_time(T),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(channel_error_history(Channel, T, RawError)),
    % State the fact: adapt precision(Channel).
    adapt_precision(Channel).

% Define a clause for 'raw error': succeed when the following conditions hold.
raw_error(prediction(_, _, unknown, []), _, 0.0) :- !.
% Define a clause for 'raw error': succeed when the following conditions hold.
raw_error(prediction(_, _, PredRel, _PredArgs), Observed, Error) :-
    % Execute: ( member(ObsItem, Observed),.
    ( member(ObsItem, Observed),
      % Continue the multi-line expression started above.
      ( ObsItem = node_fact(PredRel, _, _)
      % If the condition above succeeded, perform the following action.
      ->  Error = 0.0   % matched
      % Otherwise (else branch), perform the following action.
      ;   Error = 1.0   % mismatch
      % Close the expression opened above.
      ),
      % Supply '!' as the next argument to the expression above.
      !
    % Otherwise (else branch), perform the following action.
    ;   Error = 0.5     % no observed facts
    % Close the expression opened above.
    ).

% Define a clause for 'adapt precision': succeed when the following conditions hold.
adapt_precision(Channel) :-
    % Compute recent error variance; reduce precision if high variance
    % State a fact for 'get time' with the arguments listed below.
    get_time(Now),
    % Evaluate the arithmetic expression 'Now - 60.0' and bind the result to 'Window'.
    Window is Now - 60.0,
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(E, (
        % Continue the multi-line expression started above.
        channel_error_history(Channel, T, E),
        % Continue the multi-line expression started above.
        T >= Window
    % Continue the multi-line expression started above.
    ), RecentErrors),
    % Check that '( length(RecentErrors, N), N' is greater than or equal to '3'.
    ( length(RecentErrors, N), N >= 3
    % If the condition above succeeded, perform the following action.
    ->  sum_errors(RecentErrors, Sum),
        % Continue the multi-line expression started above.
        Mean is Sum / N,
        % Continue the multi-line expression started above.
        sumlist_sq([Mean|RecentErrors], SqSum, Mean),
        % Continue the multi-line expression started above.
        Variance is SqSum / N,
        % Continue the multi-line expression started above.
        ( Variance > 0.1
        % If the condition above succeeded, perform the following action.
        ->  pai_precision(Channel, CurrentP),
            % Continue the multi-line expression started above.
            NewP is CurrentP * 0.95,
            % Continue the multi-line expression started above.
            update_precision(Channel, NewP)
        % Otherwise (else branch), perform the following action.
        ;   pai_precision(Channel, CurrentP),
            % Continue the multi-line expression started above.
            NewP is min(1.0, CurrentP * 1.01),
            % Continue the multi-line expression started above.
            update_precision(Channel, NewP)
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% State the fact: sum errors([], 0.0).
sum_errors([], 0.0).
% Define a clause for 'sum errors': succeed when the following conditions hold.
sum_errors([H|T], S) :- sum_errors(T, S1), S is S1 + H.

% Check that 'sumlist_sq([], SqSum, _Mean) :- SqSum' is unifiable with '0.0'.
sumlist_sq([], SqSum, _Mean) :- SqSum = 0.0.
% Define a clause for 'sumlist sq': succeed when the following conditions hold.
sumlist_sq([H|T], SqSum, Mean) :-
    % State a fact for 'sumlist sq' with the arguments listed below.
    sumlist_sq(T, S1, Mean),
    % Evaluate the arithmetic expression 'H - Mean' and bind the result to 'Diff'.
    Diff is H - Mean,
    % Evaluate the arithmetic expression 'S1 + Diff * Diff' and bind the result to 'SqSum'.
    SqSum is S1 + Diff * Diff.

% ---------------------------------------------------------------------------
% pai_minimize_free_energy/1
%
%   One step of free-energy minimization for a Situation.
%   Runs the three loops in order: perception, then disturbance routing.
%   Planning is delegated (returns immediately when no deliberation module).
% ---------------------------------------------------------------------------

% Define a clause for 'pai minimize free energy': succeed when the following conditions hold.
pai_minimize_free_energy(Situation) :-
    % Perception loop: infer state
    % Execute: ( catch(default_nexus(Nexus), _, fail), nexus_is_open(Nexus).
    ( catch(default_nexus(Nexus), _, fail), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  pai_infer_state(Nexus, _InferredState),
        % Compute residual for this situation
        % Continue the multi-line expression started above.
        pai_prediction_residual(perception, [node_fact(situation, [Situation], [])],
                                % Supply 'Residual' as the next argument to the expression above.
                                Residual),
        % Route disturbance if error is large
        % Continue the multi-line expression started above.
        ( Residual > 0.5
        % If the condition above succeeded, perform the following action.
        ->  pai_route_disturbance(disturbance(perception, Situation, Residual))
        % Otherwise (else branch), perform the following action.
        ;   true
        % Close the expression opened above.
        ),
        % Dark-room guard: record curiosity prior to prevent quiescence
        % Continue the multi-line expression started above.
        record_curiosity_prior(Nexus)
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_infer_state/2 — perception loop
%
%   Infer the current abstract state from the most active node_facts.
% ---------------------------------------------------------------------------

% Define a clause for 'pai infer state': succeed when the following conditions hold.
pai_infer_state(Nexus, InferredState) :-
    % State a fact for 'nexus is open' with the arguments listed below.
    nexus_is_open(Nexus),
    % Execute: ( catch(traverse_nexus(Nexus, node_fact(_, _, _), 5, TopResults), _, fail),.
    ( catch(traverse_nexus(Nexus, node_fact(_, _, _), 5, TopResults), _, fail),
      % Continue the multi-line expression started above.
      TopResults = [Score-TopId|_],
      % Continue the multi-line expression started above.
      number(Score),
      % Continue the multi-line expression started above.
      catch(lattice:lattice_node_fact(Nexus, TopId, Rel, Args, _), _, fail)
    % If the condition above succeeded, perform the following action.
    ->  InferredState = state(Rel, Args)
    % Otherwise (else branch), perform the following action.
    ;   InferredState = state(empty, [])
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Dark-room guard
%
%   Record a standing curiosity prior: expect to encounter novel content.
%   This makes quiescence (doing nothing) surprising, which prevents the
%   system from settling into a dark-room attractor.
% ---------------------------------------------------------------------------

% Define a clause for 'record curiosity prior': succeed when the following conditions hold.
record_curiosity_prior(Nexus) :-
    % Execute: ( lattice:lattice_node_fact(Nexus, _, curiosity_prior, [active], _).
    ( lattice:lattice_node_fact(Nexus, _, curiosity_prior, [active], _)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   catch(anchor_node(curiosity_prior, [active], [], _), _, true)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_route_disturbance/1
%
%   Route a large unresolved prediction error to the regulation and
%   compensation actors as a disturbance node_fact.
% ---------------------------------------------------------------------------

% Define a clause for 'pai route disturbance': succeed when the following conditions hold.
pai_route_disturbance(Disturbance) :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        anchor_node(prediction_disturbance,
                    % Continue the multi-line expression started above.
                    [Disturbance],
                    % Continue the multi-line expression started above.
                    [],
                    % Supply '_' as the next argument to the expression above.
                    _),
        % Continue the multi-line expression started above.
        _, true
    % Close the expression opened above.
    ).
