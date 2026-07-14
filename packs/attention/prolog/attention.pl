/*  PrologAI — Attention  (WP-410, Layer 385; converged with the attention-economy and attention-schema packs)

    One attention faculty, unioned from three implementations by the unification
    program (absorb-and-supersede; no sub-faculty is lost).

    HALF ONE — SALIENCE AND SINGLE-WINNER BROADCAST (from co_salience). Candidate
    items are offered with feature scores; a weighted sum ranks them and the
    single most salient wins the cognitive cycle's broadcast.

    HALF TWO — ATTENTION ECONOMY (from the attention pack). An ECAN-style bank of
    short-term (STI) and long-term (LTI) importance: nodes are w8ed and rent-paid
    each banker cycle, importance spreads along co-activation links, and the
    lowest-LTI nodes are evicted to hold circulation within a cap.

    HALF THREE — ATTENTION SCHEMA (from the attention_schema pack). A predictive
    model of the system's own attention (attention schema theory): predict the
    next attended item, score the schema's accuracy, and enable, disable, or
    habituate it.

    All predicates are pack-qualified attention_*.
*/

% Declare this module and its exported predicates (the union of the three attention faculties).
:- module(attention, [
    % attention_broadcast/2: exported attention predicate.
    attention_broadcast/2,
    % attention_candidates/1: exported attention predicate.
    attention_candidates/1,
    % attention_count/1: exported attention predicate.
    attention_count/1,
    % attention_forget/1: exported attention predicate.
    attention_forget/1,
    % attention_offer/4: exported attention predicate.
    attention_offer/4,
    % attention_reset/0: exported attention predicate.
    attention_reset/0,
    % attention_score/2: exported attention predicate.
    attention_score/2,
    % attention_set_weights/3: exported attention predicate.
    attention_set_weights/3,
    % attention_weights/3: exported attention predicate.
    attention_weights/3,
    % attention_working_set/2: exported attention predicate.
    attention_working_set/2,
    % attention_level/3: exported attention predicate.
    attention_level/3,
    % attention_link/2: exported attention predicate.
    attention_link/2,
    % attention_metrics/1: exported attention predicate.
    attention_metrics/1,
    % attention_spread/2: exported attention predicate.
    attention_spread/2,
    % attention_banker_cycle/0: exported attention predicate.
    attention_banker_cycle/0,
    % attention_evict_lowest_lti/1: exported attention predicate.
    attention_evict_lowest_lti/1,
    % attention_wage/3: exported attention predicate.
    attention_wage/3,
    % attention_predict/2: exported attention predicate.
    attention_predict/2,
    % attention_schema/2: exported attention predicate.
    attention_schema/2,
    % attention_schema_disable/0: exported attention predicate.
    attention_schema_disable/0,
    % attention_schema_enable/0: exported attention predicate.
    attention_schema_enable/0,
    % attention_schema_score/3: exported attention predicate.
    attention_schema_score/3
]).

% List utilities used by all three halves.
:- use_module(library(lists)).
% Aggregate for the attention-economy sums.
:- use_module(library(aggregate), [aggregate_all/3]).
% Apply for the schema folds.
:- use_module(library(apply), [foldl/4]).

% ===========================================================================
% HALF ONE — Salience and single-winner broadcast (from co_salience)
% ===========================================================================


% cand/4 stores one offered candidate; it changes at runtime, so it is dynamic.
:- dynamic cand/4.
% weight/3 stores the three salience weights; dynamic so the caller may tune it.
:- dynamic weight/3.

% attention_reset/0: forget every candidate and restore the default weights.
attention_reset :-
    % Remove all candidates.
    retractall(cand(_,_,_,_)),
    % Remove any existing weights.
    retractall(weight(_,_,_)),
    % Restore a sensible default: novelty and relevance weigh 1.0, affect 0.5.
    assertz(weight(1.0, 1.0, 0.5)).

% attention_set_weights/3: replace the three salience weights.
attention_set_weights(Wn, Wr, Wa) :-
    % Drop the old weights.
    retractall(weight(_,_,_)),
    % Store the new ones.
    assertz(weight(Wn, Wr, Wa)).

% attention_weights/3: read the current weights, defaulting if somehow unset.
attention_weights(Wn, Wr, Wa) :-
    % Read them, or fall back to the defaults.
    ( weight(Wn0, Wr0, Wa0) -> Wn = Wn0, Wr = Wr0, Wa = Wa0
    ; Wn = 1.0, Wr = 1.0, Wa = 0.5 ).

% attention_offer/4: a specialist offers a candidate with its three signal values.
attention_offer(Item, Novelty, Relevance, Affect) :-
    % A re-offer of the same item replaces the earlier one.
    retractall(cand(Item, _, _, _)),
    % Store the candidate's three signals.
    assertz(cand(Item, Novelty, Relevance, Affect)).

% attention_score/2: compute an item's salience from its signals and the weights.
attention_score(Item, Salience) :-
    % Fetch the candidate's three signals.
    cand(Item, Novelty, Relevance, Affect),
    % Read the current weights.
    attention_weights(Wn, Wr, Wa),
    % Affect grabs attention by its magnitude, whichever its sign.
    AbsAffect is abs(Affect),
    % Salience is the transparent weighted sum.
    Salience is Wn*Novelty + Wr*Relevance + Wa*AbsAffect.

% attention_candidates/1: every candidate as a Salience-Item pair, most salient first.
attention_candidates(Pairs) :-
    % Score each stored candidate.
    findall(S-Item, ( cand(Item, _, _, _), attention_score(Item, S) ), Raw),
    % Sort by score descending, keeping ties (both remain).
    sort(1, @>=, Raw, Pairs).

% attention_working_set/2: the best K items the mind is holding right now.
attention_working_set(K, Items) :-
    % Rank all candidates.
    attention_candidates(Pairs),
    % Keep only the items, dropping the scores.
    findall(Item, member(_-Item, Pairs), All),
    % Take at most K from the front.
    attention_take(All, K, Items).

% attention_broadcast/2: the single most salient item and its score.
attention_broadcast(Item, Salience) :-
    % Rank all candidates and take the head.
    attention_candidates([Salience-Item|_]).

% attention_forget/1: drop one candidate from the pool.
attention_forget(Item) :-
    % Remove any candidate matching the item.
    retractall(cand(Item, _, _, _)).

% attention_count/1: how many candidates are currently offered.
attention_count(N) :-
    % Count the candidate facts.
    aggregate_all(count, cand(_,_,_,_), N).

% ---- small internal helper -------------------------------------------------

% attention_take/3: take at most K elements from the front of a list.
attention_take(_, K, []) :-
    % Taking zero or fewer yields the empty list.
    K =< 0, !.
% Taking from an empty list yields the empty list.
attention_take([], _, []) :- !.
% Otherwise keep the head and take K-1 more from the tail.
attention_take([X|Xs], K, [X|Ys]) :-
    K1 is K - 1,
    attention_take(Xs, K1, Ys).

% ===========================================================================
% HALF TWO — Attention economy: STI/LTI banker (from the attention pack)
% ===========================================================================

% ---------------------------------------------------------------------------
% Economy parameters
% ---------------------------------------------------------------------------

% State the fact: circulation cap(1000.0).
circulation_cap(1000.0).
% State the fact: sti rent rate(0.05).
sti_rent_rate(0.05).
% State the fact: lti rent rate(0.005).
lti_rent_rate(0.005).
% State the fact: spread fraction(0.1).
spread_fraction(0.1).
% State the fact: wage sti rate(5.0).
wage_sti_rate(5.0).
% State the fact: wage lti rate(0.5).
wage_lti_rate(0.5).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% Declare 'attention_value/3.  % NodeId, sti|lti, Value' as dynamic — its facts may be added or removed at runtime.
:- dynamic attention_value/3.  % NodeId, sti|lti, Value
% Declare 'banker_reserve/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic banker_reserve/1.
% Declare 'co_activation_edge/2' as dynamic — its facts may be added or removed at runtime.
:- dynamic co_activation_edge/2.
% Declare 'protected_node/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic protected_node/1.

% State the fact: banker reserve(1000.0).
banker_reserve(1000.0).

% Define a clause for 'ensure attention': succeed when the following conditions hold.
ensure_attention(NodeId) :-
    % Execute: ( attention_value(NodeId, sti, _) -> true.
    ( attention_value(NodeId, sti, _) -> true
    % Otherwise (else branch), perform the following action.
    ; assertz(attention_value(NodeId, sti, 0.0))
    % Close the expression opened above.
    ),
    % Execute: ( attention_value(NodeId, lti, _) -> true.
    ( attention_value(NodeId, lti, _) -> true
    % Otherwise (else branch), perform the following action.
    ; assertz(attention_value(NodeId, lti, 0.0))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% attention_level/3
% ---------------------------------------------------------------------------

% Define a clause for 'pai attention': succeed when the following conditions hold.
attention_level(NodeId, Field, Value) :-
    % State a fact for 'ensure attention' with the arguments listed below.
    ensure_attention(NodeId),
    % Execute: ( number(Value).
    ( number(Value)
    % If the condition above succeeded, perform the following action.
    ->  clamp_attention(Field, Value, Clamped),
        % Continue the multi-line expression started above.
        retractall(attention_value(NodeId, Field, _)),
        % Continue the multi-line expression started above.
        assertz(attention_value(NodeId, Field, Clamped))
    % Otherwise (else branch), perform the following action.
    ;   attention_value(NodeId, Field, Value)
    % Close the expression opened above.
    ).

% Define a clause for 'clamp attention': succeed when the following conditions hold.
clamp_attention(sti, V, C) :-
    % State a fact for 'circulation cap' with the arguments listed below.
    circulation_cap(Cap),
    % Evaluate the arithmetic expression 'max(0.0, min(Cap, V))' and bind the result to 'C'.
    C is max(0.0, min(Cap, V)).
% Define a clause for 'clamp attention': succeed when the following conditions hold.
clamp_attention(lti, V, C) :-
    % Evaluate the arithmetic expression 'max(0.0, V)' and bind the result to 'C'.
    C is max(0.0, V).

% ---------------------------------------------------------------------------
% attention_wage/3
% ---------------------------------------------------------------------------

% Define a clause for 'pai wage': succeed when the following conditions hold.
attention_wage(NodeId, Contribution, credits(ActualSTI, LTIWage)) :-
    % State a fact for 'ensure attention' with the arguments listed below.
    ensure_attention(NodeId),
    % State a fact for 'wage sti rate' with the arguments listed below.
    wage_sti_rate(BaseSTI),
    % State a fact for 'wage lti rate' with the arguments listed below.
    wage_lti_rate(BaseLTI),
    % Evaluate the arithmetic expression 'BaseSTI * Contribution' and bind the result to 'STIWage'.
    STIWage is BaseSTI * Contribution,
    % Evaluate the arithmetic expression 'BaseLTI * Contribution' and bind the result to 'LTIWage'.
    LTIWage is BaseLTI * Contribution,
    % Conservation: draw from reserve
    % Check that '( retract(banker_reserve(Reserve)) -> true ; Reserve' is unifiable with '0.0 )'.
    ( retract(banker_reserve(Reserve)) -> true ; Reserve = 0.0 ),
    % Evaluate the arithmetic expression 'min(STIWage, Reserve)' and bind the result to 'ActualSTI'.
    ActualSTI is min(STIWage, Reserve),
    % Evaluate the arithmetic expression 'max(0.0, Reserve - ActualSTI)' and bind the result to 'NewReserve'.
    NewReserve is max(0.0, Reserve - ActualSTI),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(banker_reserve(NewReserve)),
    % Credit sti
    % Check that '( attention_value(NodeId, sti, OldSTI) -> true ; OldSTI' is unifiable with '0.0 )'.
    ( attention_value(NodeId, sti, OldSTI) -> true ; OldSTI = 0.0 ),
    % Evaluate the arithmetic expression 'OldSTI + ActualSTI' and bind the result to 'NewSTI'.
    NewSTI is OldSTI + ActualSTI,
    % State a fact for 'clamp attention' with the arguments listed below.
    clamp_attention(sti, NewSTI, ClampedSTI),
    % Remove all matching facts from the runtime knowledge base.
    retractall(attention_value(NodeId, sti, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(attention_value(NodeId, sti, ClampedSTI)),
    % Credit lti (no reserve constraint)
    % Check that '( attention_value(NodeId, lti, OldLTI) -> true ; OldLTI' is unifiable with '0.0 )'.
    ( attention_value(NodeId, lti, OldLTI) -> true ; OldLTI = 0.0 ),
    % Evaluate the arithmetic expression 'OldLTI + LTIWage' and bind the result to 'NewLTI'.
    NewLTI is OldLTI + LTIWage,
    % Remove all matching facts from the runtime knowledge base.
    retractall(attention_value(NodeId, lti, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(attention_value(NodeId, lti, NewLTI)).

% ---------------------------------------------------------------------------
% attention_spread/2
% ---------------------------------------------------------------------------

% Define a clause for 'pai attention spread': succeed when the following conditions hold.
attention_spread(NodeId, Neighbors) :-
    % State a fact for 'ensure attention' with the arguments listed below.
    ensure_attention(NodeId),
    % Check that '( attention_value(NodeId, sti, MySTI) -> true ; MySTI' is unifiable with '0.0 )'.
    ( attention_value(NodeId, sti, MySTI) -> true ; MySTI = 0.0 ),
    % State a fact for 'spread fraction' with the arguments listed below.
    spread_fraction(Frac),
    % Unify 'N' with the number of elements in list 'Neighbors'.
    length(Neighbors, N),
    % Check that '( N' is greater than '0'.
    ( N > 0
    % If the condition above succeeded, perform the following action.
    ->  Share is MySTI * Frac / N,
        % Continue the multi-line expression started above.
        Decay is MySTI * Frac,
        % Continue the multi-line expression started above.
        NewMySTI is max(0.0, MySTI - Decay),
        % Continue the multi-line expression started above.
        retractall(attention_value(NodeId, sti, _)),
        % Continue the multi-line expression started above.
        assertz(attention_value(NodeId, sti, NewMySTI)),
        % Continue the multi-line expression started above.
        forall(
            % Continue the multi-line expression started above.
            member(Nbr, Neighbors),
            % Continue the multi-line expression started above.
            ( ensure_attention(Nbr),
              % Continue the multi-line expression started above.
              ( attention_value(Nbr, sti, NbrSTI) -> true ; NbrSTI = 0.0 ),
              % Continue the multi-line expression started above.
              NewNbrSTI is NbrSTI + Share,
              % Continue the multi-line expression started above.
              clamp_attention(sti, NewNbrSTI, Clamped),
              % Continue the multi-line expression started above.
              retractall(attention_value(Nbr, sti, _)),
              % Continue the multi-line expression started above.
              assertz(attention_value(Nbr, sti, Clamped))
            % Close the expression opened above.
            )
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% attention_banker_cycle/0
% ---------------------------------------------------------------------------

% Execute: attention_banker_cycle :-.
attention_banker_cycle :-
    % State a fact for 'sti rent rate' with the arguments listed below.
    sti_rent_rate(STIRate),
    % State a fact for 'lti rent rate' with the arguments listed below.
    lti_rent_rate(LTIRate),
    % State a fact for 'circulation cap' with the arguments listed below.
    circulation_cap(Cap),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(NId, attention_value(NId, sti, _), AllIds0),
    % Sort list 'AllIds0' into 'AllIds', removing duplicates.
    sort(AllIds0, AllIds),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(NId, AllIds),
        % Continue the multi-line expression started above.
        do_rent_and_spread(NId, STIRate, LTIRate, Cap)
    % Close the expression opened above.
    ).

% Define a clause for 'do rent and spread': succeed when the following conditions hold.
do_rent_and_spread(NId, STIRate, LTIRate, Cap) :-
    % Check that '( attention_value(NId, sti, STI) -> true ; STI' is unifiable with '0.0 )'.
    ( attention_value(NId, sti, STI) -> true ; STI = 0.0 ),
    % Check that '( attention_value(NId, lti, LTI) -> true ; LTI' is unifiable with '0.0 )'.
    ( attention_value(NId, lti, LTI) -> true ; LTI = 0.0 ),
    % Evaluate the arithmetic expression 'STI * STIRate' and bind the result to 'STIRent'.
    STIRent is STI * STIRate,
    % Evaluate the arithmetic expression 'LTI * LTIRate' and bind the result to 'LTIRent'.
    LTIRent is LTI * LTIRate,
    % Evaluate the arithmetic expression 'max(0.0, STI - STIRent)' and bind the result to 'NewSTI'.
    NewSTI is max(0.0, STI - STIRent),
    % Evaluate the arithmetic expression 'max(0.0, LTI - LTIRent)' and bind the result to 'NewLTI'.
    NewLTI is max(0.0, LTI - LTIRent),
    % Return rent to reserve (conservation)
    % Check that '( retract(banker_reserve(R)) -> true ; R' is unifiable with '0.0 )'.
    ( retract(banker_reserve(R)) -> true ; R = 0.0 ),
    % Evaluate the arithmetic expression 'min(Cap, R + STIRent)' and bind the result to 'NewR'.
    NewR is min(Cap, R + STIRent),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(banker_reserve(NewR)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(attention_value(NId, sti, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(attention_value(NId, lti, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(attention_value(NId, sti, NewSTI)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(attention_value(NId, lti, NewLTI)),
    % Spread to co-activation neighbors
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Nbr, co_activation_edge(NId, Nbr), Nbrs),
    % State the fact: pai attention spread(NId, Nbrs).
    attention_spread(NId, Nbrs).

% ---------------------------------------------------------------------------
% attention_metrics/1
% ---------------------------------------------------------------------------

% Define a clause for 'pai attention metrics': succeed when the following conditions hold.
attention_metrics(metrics(TotalSTI, TotalLTI, Reserve)) :-
    % Aggregate solutions using 'sum' and bind the result to a single value.
    aggregate_all(sum(S), attention_value(_, sti, S), TotalSTI0),
    % Aggregate solutions using 'sum' and bind the result to a single value.
    aggregate_all(sum(L), attention_value(_, lti, L), TotalLTI0),
    % Check that '( number(TotalSTI0) -> TotalSTI' is unifiable with 'TotalSTI0 ; TotalSTI = 0.0 )'.
    ( number(TotalSTI0) -> TotalSTI = TotalSTI0 ; TotalSTI = 0.0 ),
    % Check that '( number(TotalLTI0) -> TotalLTI' is unifiable with 'TotalLTI0 ; TotalLTI = 0.0 )'.
    ( number(TotalLTI0) -> TotalLTI = TotalLTI0 ; TotalLTI = 0.0 ),
    % Check that '( banker_reserve(Reserve) -> true ; Reserve' is unifiable with '0.0 )'.
    ( banker_reserve(Reserve) -> true ; Reserve = 0.0 ).

% ---------------------------------------------------------------------------
% attention_evict_lowest_lti/1
% ---------------------------------------------------------------------------

% Define a clause for 'pai evict lowest lti': succeed when the following conditions hold.
attention_evict_lowest_lti(MaxItems) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(LTI-NId, (
        % Continue the multi-line expression started above.
        attention_value(NId, lti, LTI),
        % Continue the multi-line expression started above.
        \+ protected_node(NId)
    % Continue the multi-line expression started above.
    ), Candidates),
    % Sort list 'Candidates' into 'Ascending', keeping duplicates.
    msort(Candidates, Ascending),
    % Unify 'Total' with the number of elements in list 'Candidates'.
    length(Candidates, Total),
    % Check that '( Total' is greater than 'MaxItems'.
    ( Total > MaxItems
    % If the condition above succeeded, perform the following action.
    ->  ToEvict is Total - MaxItems,
        % Continue the multi-line expression started above.
        take_k(ToEvict, Ascending, Evictees),
        % Continue the multi-line expression started above.
        forall(
            % Continue the multi-line expression started above.
            member(_-NId, Evictees),
            % Continue the multi-line expression started above.
            retractall(attention_value(NId, _, _))
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Define a clause for 'take k': succeed when the following conditions hold.
take_k(0, _, []) :- !.
% Define a clause for 'take k': succeed when the following conditions hold.
take_k(_, [], []) :- !.
% Check that 'take_k(K, [H|T], [H|R]) :- K' is greater than '0, K1 is K - 1, take_k(K1, T, R)'.
take_k(K, [H|T], [H|R]) :- K > 0, K1 is K - 1, take_k(K1, T, R).

% ---------------------------------------------------------------------------
% attention_link/2
% ---------------------------------------------------------------------------

% Define a clause for 'pai attention link': succeed when the following conditions hold.
attention_link(NodeId, NeighborId) :-
    % Execute: ( co_activation_edge(NodeId, NeighborId) -> true.
    ( co_activation_edge(NodeId, NeighborId) -> true
    % Otherwise (else branch), perform the following action.
    ; assertz(co_activation_edge(NodeId, NeighborId))
    % Close the expression opened above.
    ).

% ===========================================================================
% HALF THREE — Attention schema: predictive self-model (from attention_schema)
% ===========================================================================

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
% attention_schema/2 — record an attention event; update schema
%
%   Events:
%       win(CycleN, Winner, STI)        — a coalition won the workspace
%       suppress(CycleN, Coalition)     — a coalition was suppressed
%       habituate(NodeId, Delta)        — increase habituation for a node
% ---------------------------------------------------------------------------

% Define a clause for 'pai attention schema': succeed when the following conditions hold.
attention_schema(win(CycleN, Winner, STI), updated) :-
    % Add a new fact or rule to the runtime knowledge base.
    assertz(schema_winner(CycleN, Winner, STI)),
    % State a fact for 'update habituation' with the arguments listed below.
    update_habituation(Winner, 0.05),
    % State a fact for 'update cycle counter' with the arguments listed below.
    update_cycle_counter(CycleN),
    % Execute: ( schema_enabled -> make_prediction(CycleN) ; true )..
    ( schema_enabled -> make_prediction(CycleN) ; true ).

% Define a clause for 'pai attention schema': succeed when the following conditions hold.
attention_schema(suppress(CycleN, Coalition), noted) :-
    % Add a new fact or rule to the runtime knowledge base.
    assertz(schema_suppressed(CycleN, Coalition)).

% Define a clause for 'pai attention schema': succeed when the following conditions hold.
attention_schema(habituate(NodeId, Delta), updated) :-
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
% attention_predict/2 — return the schema's prediction for Cycle
%
%   If schema is disabled or no prediction exists, returns no_prediction.
% ---------------------------------------------------------------------------

% Define a clause for 'pai attention predict': succeed when the following conditions hold.
attention_predict(Cycle, Predicted) :-
    % Execute: ( schema_enabled, schema_prediction(Cycle, P).
    ( schema_enabled, schema_prediction(Cycle, P)
    % If the condition above succeeded, perform the following action.
    ->  Predicted = P
    % Otherwise (else branch), perform the following action.
    ;   Predicted = no_prediction
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% attention_schema_disable/0 and attention_schema_enable/0
% ---------------------------------------------------------------------------

% Execute: attention_schema_disable :-.
attention_schema_disable :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(schema_enabled).

% Execute: attention_schema_enable :-.
attention_schema_enable :-
    % Execute: ( schema_enabled -> true ; assertz(schema_enabled) )..
    ( schema_enabled -> true ; assertz(schema_enabled) ).

% ---------------------------------------------------------------------------
% attention_schema_score/3
%
%   Predictions: list of prediction(Cycle, PredictedWinner)
%   Actuals:     list of actual(Cycle, ActualWinner)
%   Accuracy:    fraction of predictions that matched actual winner
%
%   Chance baseline: 1/N where N = number of distinct recent winners
%   (AC-PR42-001 requires accuracy > chance baseline)
% ---------------------------------------------------------------------------

% Define a clause for 'pai schema score': succeed when the following conditions hold.
attention_schema_score(Predictions, Actuals, score(Accuracy, ChanceBaseline)) :-
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
