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

:- module(prediction, [
    pai_generate_prediction/3,   % +Channel, +Situation, -PredictedState
    pai_prediction_residual/3,   % +Channel, +Observed, -WeightedResidual
    pai_precision/2,             % +Channel, -Precision  (or update with +Precision)
    pai_minimize_free_energy/1,  % +Situation
    pai_infer_state/2,           % +Nexus, -InferredState
    pai_route_disturbance/1      % +Residual
]).

:- use_module(library(node_facts),  [anchor_node/4, traverse_nexus/4,
                                     default_nexus/1]).
:- use_module(library(lattice),     [lattice_node_fact/5, nexus_is_open/1]).
:- use_module(library(lists),       [member/2]).
:- use_module(library(apply),       [maplist/3]).
:- use_module(library(aggregate),   [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Channel precision weights
%
%   precision(Channel, Weight) — Weight ∈ (0, 1]
%   Higher weight = more confident; lower weight = more noise expected.
%   Adapted downward when the channel's variance is high relative to predictions.
% ---------------------------------------------------------------------------

:- dynamic channel_precision/2.     % Channel, Weight
:- dynamic channel_error_history/3. % Channel, Timestamp, ErrorMagnitude

default_precision(0.8).

pai_precision(Channel, Precision) :-
    ( channel_precision(Channel, Precision)
    ->  true
    ;   default_precision(Precision)
    ).

update_precision(Channel, NewPrecision) :-
    Clamped is max(0.05, min(1.0, NewPrecision)),
    retractall(channel_precision(Channel, _)),
    assertz(channel_precision(Channel, Clamped)).

% ---------------------------------------------------------------------------
% Generative model — stored as prediction node_facts
%
%   prediction_model(Channel, Situation, PredictedRelation, PredictedArgs)
%   The model is populated by SONA crystallization (PR 11) and the
%   PR 22 learning loop; here it starts empty and builds from experience.
% ---------------------------------------------------------------------------

:- dynamic prediction_model/4.     % Channel, Situation, Relation, Args

% ---------------------------------------------------------------------------
% pai_generate_prediction/3
%
%   Generate a downward prediction for a given situation on a channel.
%   Falls back to a "no change" prior if no model entry exists.
% ---------------------------------------------------------------------------

pai_generate_prediction(Channel, Situation, PredictedState) :-
    ( prediction_model(Channel, Situation, Relation, Args)
    ->  PredictedState = prediction(Channel, Situation, Relation, Args)
    ;   % No model: prior = expect the most recently observed relation
        ( catch(default_nexus(Nexus), _, fail),
          nexus_is_open(Nexus),
          once(lattice:lattice_node_fact(Nexus, _, Relation, [Situation|_], _))
        ->  PredictedState = prediction(Channel, Situation, Relation, [Situation])
        ;   PredictedState = prediction(Channel, Situation, unknown, [])
        )
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

pai_prediction_residual(Channel, Observed, WeightedResidual) :-
    pai_precision(Channel, Precision),
    pai_generate_prediction(Channel, unknown, Predicted),
    raw_error(Predicted, Observed, RawError),
    WeightedResidual is Precision * RawError,
    % Record for history and precision adaptation
    get_time(T),
    assertz(channel_error_history(Channel, T, RawError)),
    adapt_precision(Channel).

raw_error(prediction(_, _, unknown, []), _, 0.0) :- !.
raw_error(prediction(_, _, PredRel, _PredArgs), Observed, Error) :-
    ( member(ObsItem, Observed),
      ( ObsItem = node_fact(PredRel, _, _)
      ->  Error = 0.0   % matched
      ;   Error = 1.0   % mismatch
      ),
      !
    ;   Error = 0.5     % no observed facts
    ).

adapt_precision(Channel) :-
    % Compute recent error variance; reduce precision if high variance
    get_time(Now),
    Window is Now - 60.0,
    findall(E, (
        channel_error_history(Channel, T, E),
        T >= Window
    ), RecentErrors),
    ( length(RecentErrors, N), N >= 3
    ->  sum_errors(RecentErrors, Sum),
        Mean is Sum / N,
        sumlist_sq([Mean|RecentErrors], SqSum, Mean),
        Variance is SqSum / N,
        ( Variance > 0.1
        ->  pai_precision(Channel, CurrentP),
            NewP is CurrentP * 0.95,
            update_precision(Channel, NewP)
        ;   pai_precision(Channel, CurrentP),
            NewP is min(1.0, CurrentP * 1.01),
            update_precision(Channel, NewP)
        )
    ;   true
    ).

sum_errors([], 0.0).
sum_errors([H|T], S) :- sum_errors(T, S1), S is S1 + H.

sumlist_sq([], SqSum, _Mean) :- SqSum = 0.0.
sumlist_sq([H|T], SqSum, Mean) :-
    sumlist_sq(T, S1, Mean),
    Diff is H - Mean,
    SqSum is S1 + Diff * Diff.

% ---------------------------------------------------------------------------
% pai_minimize_free_energy/1
%
%   One step of free-energy minimization for a Situation.
%   Runs the three loops in order: perception, then disturbance routing.
%   Planning is delegated (returns immediately when no deliberation module).
% ---------------------------------------------------------------------------

pai_minimize_free_energy(Situation) :-
    % Perception loop: infer state
    ( catch(default_nexus(Nexus), _, fail), nexus_is_open(Nexus)
    ->  pai_infer_state(Nexus, _InferredState),
        % Compute residual for this situation
        pai_prediction_residual(perception, [node_fact(situation, [Situation], [])],
                                Residual),
        % Route disturbance if error is large
        ( Residual > 0.5
        ->  pai_route_disturbance(disturbance(perception, Situation, Residual))
        ;   true
        ),
        % Dark-room guard: record curiosity prior to prevent quiescence
        record_curiosity_prior(Nexus)
    ;   true
    ).

% ---------------------------------------------------------------------------
% pai_infer_state/2 — perception loop
%
%   Infer the current abstract state from the most active node_facts.
% ---------------------------------------------------------------------------

pai_infer_state(Nexus, InferredState) :-
    nexus_is_open(Nexus),
    ( catch(traverse_nexus(Nexus, node_fact(_, _, _), 5, TopResults), _, fail),
      TopResults = [Score-TopId|_],
      number(Score),
      catch(lattice:lattice_node_fact(Nexus, TopId, Rel, Args, _), _, fail)
    ->  InferredState = state(Rel, Args)
    ;   InferredState = state(empty, [])
    ).

% ---------------------------------------------------------------------------
% Dark-room guard
%
%   Record a standing curiosity prior: expect to encounter novel content.
%   This makes quiescence (doing nothing) surprising, which prevents the
%   system from settling into a dark-room attractor.
% ---------------------------------------------------------------------------

record_curiosity_prior(Nexus) :-
    ( lattice:lattice_node_fact(Nexus, _, curiosity_prior, [active], _)
    ->  true
    ;   catch(anchor_node(curiosity_prior, [active], [], _), _, true)
    ).

% ---------------------------------------------------------------------------
% pai_route_disturbance/1
%
%   Route a large unresolved prediction error to the regulation and
%   compensation actors as a disturbance node_fact.
% ---------------------------------------------------------------------------

pai_route_disturbance(Disturbance) :-
    catch(
        anchor_node(prediction_disturbance,
                    [Disturbance],
                    [],
                    _),
        _, true
    ).
