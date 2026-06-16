/*  PrologAI — Attention Schema and Formal Workspace Correspondence  (PR 42)

    Gives the mind a simplified running model of its own attention dynamics
    (attention schema theory, Graziano), and documents the workspace cycle's
    correspondence with the Conscious Turing Machine (Blum and Blum).

    The attention schema is a MODEL, not the mechanism.  Disabling it
    degrades prediction and pre-emptive control without halting the workspace.

    Schema contents (stored as dynamic facts):
        schema_winner(CycleN, Winner, STI)    — recent broadcast winners
        schema_suppressed(CycleN, Coalition)  — suppressed coalitions
        schema_habituation(NodeId, Level)     — habituation state
        schema_prediction(Cycle, Predicted)   — short-horizon winner predictions

    Predicates:
        pai_attention_schema/2  — +Event, -SchemaUpdate
                                  Record an attention event and update schema
        pai_attention_predict/2 — +Cycle, -Predicted
                                  Predict the next-cycle winner from schema
        pai_schema_disable/0    — Disable the schema (degrades prediction)
        pai_schema_enable/0     — Re-enable the schema
        pai_schema_score/3      — +Predictions, +Actuals, -Accuracy
                                  Score prediction accuracy vs chance baseline
*/

% Declare this file as the 'attention_schema' module and list its exported predicates.
:- module(attention_schema, [
    % Supply 'pai_attention_schema/2' as the next argument to the expression above.
    pai_attention_schema/2,
    % Supply 'pai_attention_predict/2' as the next argument to the expression above.
    pai_attention_predict/2,
    % Supply 'pai_schema_disable/0' as the next argument to the expression above.
    pai_schema_disable/0,
    % Supply 'pai_schema_enable/0' as the next argument to the expression above.
    pai_schema_enable/0,
    % Supply 'pai_schema_score/3' as the next argument to the expression above.
    pai_schema_score/3
% Close the expression opened above.
]).

% Import [member/2, last/2] from the built-in 'lists' library.
:- use_module(library(lists),  [member/2, last/2]).
% Import [foldl/4] from the built-in 'apply' library.
:- use_module(library(apply),  [foldl/4]).

% ---------------------------------------------------------------------------
% Schema state
% ---------------------------------------------------------------------------

% Declare 'schema_winner/3.     % CycleN, Winner, STI' as dynamic — its facts may be added or removed at runtime.
:- dynamic schema_winner/3.     % CycleN, Winner, STI
% Declare 'schema_suppressed/2. % CycleN, Coalition' as dynamic — its facts may be added or removed at runtime.
:- dynamic schema_suppressed/2. % CycleN, Coalition
% Declare 'schema_habituation/2.% NodeId, Level' as dynamic — its facts may be added or removed at runtime.
:- dynamic schema_habituation/2.% NodeId, Level
% Declare 'schema_prediction/2. % Cycle, Predicted' as dynamic — its facts may be added or removed at runtime.
:- dynamic schema_prediction/2. % Cycle, Predicted
% Declare 'schema_enabled/0' as dynamic — its facts may be added or removed at runtime.
:- dynamic schema_enabled/0.
% Declare 'schema_cycle/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic schema_cycle/1.

% Execute: schema_enabled.                 % default: enabled.
schema_enabled.                 % default: enabled
% State the fact: schema cycle(0).
schema_cycle(0).

% ---------------------------------------------------------------------------
% pai_attention_schema/2 — record an attention event; update schema
%
%   Events:
%       win(CycleN, Winner, STI)        — a coalition won the workspace
%       suppress(CycleN, Coalition)     — a coalition was suppressed
%       habituate(NodeId, Delta)        — increase habituation for a node
% ---------------------------------------------------------------------------

% Define a clause for 'pai attention schema': succeed when the following conditions hold.
pai_attention_schema(win(CycleN, Winner, STI), updated) :-
    % Add a new fact or rule to the runtime knowledge base.
    assertz(schema_winner(CycleN, Winner, STI)),
    % State a fact for 'update habituation' with the arguments listed below.
    update_habituation(Winner, 0.05),
    % State a fact for 'update cycle counter' with the arguments listed below.
    update_cycle_counter(CycleN),
    % Execute: ( schema_enabled -> make_prediction(CycleN) ; true )..
    ( schema_enabled -> make_prediction(CycleN) ; true ).

% Define a clause for 'pai attention schema': succeed when the following conditions hold.
pai_attention_schema(suppress(CycleN, Coalition), noted) :-
    % Add a new fact or rule to the runtime knowledge base.
    assertz(schema_suppressed(CycleN, Coalition)).

% Define a clause for 'pai attention schema': succeed when the following conditions hold.
pai_attention_schema(habituate(NodeId, Delta), updated) :-
    % State the fact: update habituation(NodeId, Delta).
    update_habituation(NodeId, Delta).

% Define a clause for 'update habituation': succeed when the following conditions hold.
update_habituation(NodeId, Delta) :-
    % Execute: ( retract(schema_habituation(NodeId, Old)).
    ( retract(schema_habituation(NodeId, Old))
    % If the condition above succeeded, perform the following action.
    ->  New is min(1.0, Old + Delta)
    % Otherwise (else branch), perform the following action.
    ;   New is min(1.0, Delta)
    % Close the expression opened above.
    ),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(schema_habituation(NodeId, New)).

% Define a clause for 'update cycle counter': succeed when the following conditions hold.
update_cycle_counter(CycleN) :-
    % Execute: ( retract(schema_cycle(_)) -> true ; true ),.
    ( retract(schema_cycle(_)) -> true ; true ),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(schema_cycle(CycleN)).

% ---------------------------------------------------------------------------
% Prediction: momentum-based — the most-frequently-winning coalition tends
% to keep winning (highest average STI dominates the workspace).
% Among ties, prefer the coalition with the HIGHEST cumulative STI.
% ---------------------------------------------------------------------------

% Define a clause for 'make prediction': succeed when the following conditions hold.
make_prediction(CycleN) :-
    % Evaluate the arithmetic expression 'CycleN + 1' and bind the result to 'Next'.
    Next is CycleN + 1,
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(W-S, schema_winner(_, W, S), Pairs),
    % Check that '( Pairs' is unifiable with '[]'.
    ( Pairs = []
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   aggregate_sti(Pairs, Scored),
        % Continue the multi-line expression started above.
        msort(Scored, SortedAsc),
        % Continue the multi-line expression started above.
        last(SortedAsc, _-Predicted),
        % Continue the multi-line expression started above.
        retractall(schema_prediction(Next, _)),
        % Continue the multi-line expression started above.
        assertz(schema_prediction(Next, Predicted))
    % Close the expression opened above.
    ).

% Define a clause for 'aggregate sti': succeed when the following conditions hold.
aggregate_sti(Pairs, Scored) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(W, member(W-_, Pairs), AllW),
    % Sort list 'AllW' into 'UniqueW', removing duplicates.
    sort(AllW, UniqueW),
    % State a fact for 'maplist' with the arguments listed below.
    maplist([W, TotalSTI-W]>>(
        % Continue the multi-line expression started above.
        findall(S, member(W-S, Pairs), Ss),
        % Continue the multi-line expression started above.
        foldl([X, Acc, NAcc]>>(NAcc is Acc + X), Ss, 0.0, TotalSTI)
    % Continue the multi-line expression started above.
    ), UniqueW, Scored).

% ---------------------------------------------------------------------------
% pai_attention_predict/2 — return the schema's prediction for Cycle
%
%   If schema is disabled or no prediction exists, returns no_prediction.
% ---------------------------------------------------------------------------

% Define a clause for 'pai attention predict': succeed when the following conditions hold.
pai_attention_predict(Cycle, Predicted) :-
    % Execute: ( schema_enabled, schema_prediction(Cycle, P).
    ( schema_enabled, schema_prediction(Cycle, P)
    % If the condition above succeeded, perform the following action.
    ->  Predicted = P
    % Otherwise (else branch), perform the following action.
    ;   Predicted = no_prediction
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_schema_disable/0 and pai_schema_enable/0
% ---------------------------------------------------------------------------

% Execute: pai_schema_disable :-.
pai_schema_disable :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(schema_enabled).

% Execute: pai_schema_enable :-.
pai_schema_enable :-
    % Execute: ( schema_enabled -> true ; assertz(schema_enabled) )..
    ( schema_enabled -> true ; assertz(schema_enabled) ).

% ---------------------------------------------------------------------------
% pai_schema_score/3
%
%   Predictions: list of prediction(Cycle, PredictedWinner)
%   Actuals:     list of actual(Cycle, ActualWinner)
%   Accuracy:    fraction of predictions that matched actual winner
%
%   Chance baseline: 1/N where N = number of distinct recent winners
%   (AC-PR42-001 requires accuracy > chance baseline)
% ---------------------------------------------------------------------------

% Define a clause for 'pai schema score': succeed when the following conditions hold.
pai_schema_score(Predictions, Actuals, score(Accuracy, ChanceBaseline)) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(1, (
        % Continue the multi-line expression started above.
        member(prediction(C, P), Predictions),
        % Continue the multi-line expression started above.
        member(actual(C, P), Actuals)
    % Continue the multi-line expression started above.
    ), Hits),
    % Unify 'NHits' with the number of elements in list 'Hits'.
    length(Hits, NHits),
    % Unify 'NTotal' with the number of elements in list 'Predictions'.
    length(Predictions, NTotal),
    % Check that '( NTotal' is greater than '0'.
    ( NTotal > 0
    % If the condition above succeeded, perform the following action.
    ->  Accuracy is NHits / NTotal
    % Otherwise (else branch), perform the following action.
    ;   Accuracy = 0.0
    % Close the expression opened above.
    ),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(W, member(actual(_, W), Actuals), AllWinners),
    % Sort list 'AllWinners' into 'UniqueWinners', removing duplicates.
    sort(AllWinners, UniqueWinners),
    % Unify 'NU' with the number of elements in list 'UniqueWinners'.
    length(UniqueWinners, NU),
    % Check that '( NU' is greater than '0'.
    ( NU > 0
    % If the condition above succeeded, perform the following action.
    ->  ChanceBaseline is 1.0 / NU
    % Otherwise (else branch), perform the following action.
    ;   ChanceBaseline = 0.0
    % Close the expression opened above.
    ).
