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

:- module(attention_schema, [
    pai_attention_schema/2,
    pai_attention_predict/2,
    pai_schema_disable/0,
    pai_schema_enable/0,
    pai_schema_score/3
]).

:- use_module(library(lists),  [member/2, last/2]).
:- use_module(library(apply),  [foldl/4]).

% ---------------------------------------------------------------------------
% Schema state
% ---------------------------------------------------------------------------

:- dynamic schema_winner/3.     % CycleN, Winner, STI
:- dynamic schema_suppressed/2. % CycleN, Coalition
:- dynamic schema_habituation/2.% NodeId, Level
:- dynamic schema_prediction/2. % Cycle, Predicted
:- dynamic schema_enabled/0.
:- dynamic schema_cycle/1.

schema_enabled.                 % default: enabled
schema_cycle(0).

% ---------------------------------------------------------------------------
% pai_attention_schema/2 — record an attention event; update schema
%
%   Events:
%       win(CycleN, Winner, STI)        — a coalition won the workspace
%       suppress(CycleN, Coalition)     — a coalition was suppressed
%       habituate(NodeId, Delta)        — increase habituation for a node
% ---------------------------------------------------------------------------

pai_attention_schema(win(CycleN, Winner, STI), updated) :-
    assertz(schema_winner(CycleN, Winner, STI)),
    update_habituation(Winner, 0.05),
    update_cycle_counter(CycleN),
    ( schema_enabled -> make_prediction(CycleN) ; true ).

pai_attention_schema(suppress(CycleN, Coalition), noted) :-
    assertz(schema_suppressed(CycleN, Coalition)).

pai_attention_schema(habituate(NodeId, Delta), updated) :-
    update_habituation(NodeId, Delta).

update_habituation(NodeId, Delta) :-
    ( retract(schema_habituation(NodeId, Old))
    ->  New is min(1.0, Old + Delta)
    ;   New is min(1.0, Delta)
    ),
    assertz(schema_habituation(NodeId, New)).

update_cycle_counter(CycleN) :-
    ( retract(schema_cycle(_)) -> true ; true ),
    assertz(schema_cycle(CycleN)).

% ---------------------------------------------------------------------------
% Prediction: momentum-based — the most-frequently-winning coalition tends
% to keep winning (highest average STI dominates the workspace).
% Among ties, prefer the coalition with the HIGHEST cumulative STI.
% ---------------------------------------------------------------------------

make_prediction(CycleN) :-
    Next is CycleN + 1,
    findall(W-S, schema_winner(_, W, S), Pairs),
    ( Pairs = []
    ->  true
    ;   aggregate_sti(Pairs, Scored),
        msort(Scored, SortedAsc),
        last(SortedAsc, _-Predicted),
        retractall(schema_prediction(Next, _)),
        assertz(schema_prediction(Next, Predicted))
    ).

aggregate_sti(Pairs, Scored) :-
    findall(W, member(W-_, Pairs), AllW),
    sort(AllW, UniqueW),
    maplist([W, TotalSTI-W]>>(
        findall(S, member(W-S, Pairs), Ss),
        foldl([X, Acc, NAcc]>>(NAcc is Acc + X), Ss, 0.0, TotalSTI)
    ), UniqueW, Scored).

% ---------------------------------------------------------------------------
% pai_attention_predict/2 — return the schema's prediction for Cycle
%
%   If schema is disabled or no prediction exists, returns no_prediction.
% ---------------------------------------------------------------------------

pai_attention_predict(Cycle, Predicted) :-
    ( schema_enabled, schema_prediction(Cycle, P)
    ->  Predicted = P
    ;   Predicted = no_prediction
    ).

% ---------------------------------------------------------------------------
% pai_schema_disable/0 and pai_schema_enable/0
% ---------------------------------------------------------------------------

pai_schema_disable :-
    retractall(schema_enabled).

pai_schema_enable :-
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

pai_schema_score(Predictions, Actuals, score(Accuracy, ChanceBaseline)) :-
    findall(1, (
        member(prediction(C, P), Predictions),
        member(actual(C, P), Actuals)
    ), Hits),
    length(Hits, NHits),
    length(Predictions, NTotal),
    ( NTotal > 0
    ->  Accuracy is NHits / NTotal
    ;   Accuracy = 0.0
    ),
    findall(W, member(actual(_, W), Actuals), AllWinners),
    sort(AllWinners, UniqueWinners),
    length(UniqueWinners, NU),
    ( NU > 0
    ->  ChanceBaseline is 1.0 / NU
    ;   ChanceBaseline = 0.0
    ).
