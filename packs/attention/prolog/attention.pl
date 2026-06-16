/*  PrologAI — The Attention Economy (ECAN Adaptation)  (Specification PR 32)

    Adapts Economic Attention Networks (ECAN) to PrologAI's node_fact Lattice.
    Every node_fact carries two attention values:
        sti — short-term importance: who gets processor attention NOW
        lti — long-term importance:  who stays in memory

    Economy mechanics:
        Wages   — when a node_fact participates in a confirmed outcome,
                  credit sti and lti proportional to contribution.
        Rent    — each banker cycle, every node_fact pays decay;
                  lti decays 10× slower than sti; rent returns to reserve.
        Spread  — each node_fact passes a fraction of sti to co-activated
                  neighbors (Hebbian-style links).
        Conservation — total sti + reserve is capped; runaway feedback
                  is structurally impossible.
        Economic forgetting — evict lowest-lti node_facts first.

    Predicates:
        pai_attention/3        — +NodeId, +(sti|lti), -Value  OR  set
        pai_wage/3             — +NodeId, +Contribution, -Credits
        pai_attention_spread/2 — +NodeId, +Neighbors
        pai_banker_cycle/0     — one full cycle: rent + spread
        pai_attention_metrics/1— -metrics(TotalSTI, TotalLTI, Reserve)
        pai_evict_lowest_lti/1 — +MaxItems
        pai_attention_link/2   — +NodeId, +NeighborId
*/

% Declare this file as the 'attention' module and list its exported predicates.
:- module(attention, [
    % Supply 'pai_attention/3' as the next argument to the expression above.
    pai_attention/3,
    % Supply 'pai_wage/3' as the next argument to the expression above.
    pai_wage/3,
    % Supply 'pai_attention_spread/2' as the next argument to the expression above.
    pai_attention_spread/2,
    % Supply 'pai_banker_cycle/0' as the next argument to the expression above.
    pai_banker_cycle/0,
    % Supply 'pai_attention_metrics/1' as the next argument to the expression above.
    pai_attention_metrics/1,
    % Supply 'pai_evict_lowest_lti/1' as the next argument to the expression above.
    pai_evict_lowest_lti/1,
    % Supply 'pai_attention_link/2' as the next argument to the expression above.
    pai_attention_link/2
% Close the expression opened above.
]).

% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),     [member/2]).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate), [aggregate_all/3]).

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
% pai_attention/3
% ---------------------------------------------------------------------------

% Define a clause for 'pai attention': succeed when the following conditions hold.
pai_attention(NodeId, Field, Value) :-
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
% pai_wage/3
% ---------------------------------------------------------------------------

% Define a clause for 'pai wage': succeed when the following conditions hold.
pai_wage(NodeId, Contribution, credits(ActualSTI, LTIWage)) :-
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
% pai_attention_spread/2
% ---------------------------------------------------------------------------

% Define a clause for 'pai attention spread': succeed when the following conditions hold.
pai_attention_spread(NodeId, Neighbors) :-
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
% pai_banker_cycle/0
% ---------------------------------------------------------------------------

% Execute: pai_banker_cycle :-.
pai_banker_cycle :-
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
    pai_attention_spread(NId, Nbrs).

% ---------------------------------------------------------------------------
% pai_attention_metrics/1
% ---------------------------------------------------------------------------

% Define a clause for 'pai attention metrics': succeed when the following conditions hold.
pai_attention_metrics(metrics(TotalSTI, TotalLTI, Reserve)) :-
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
% pai_evict_lowest_lti/1
% ---------------------------------------------------------------------------

% Define a clause for 'pai evict lowest lti': succeed when the following conditions hold.
pai_evict_lowest_lti(MaxItems) :-
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
% pai_attention_link/2
% ---------------------------------------------------------------------------

% Define a clause for 'pai attention link': succeed when the following conditions hold.
pai_attention_link(NodeId, NeighborId) :-
    % Execute: ( co_activation_edge(NodeId, NeighborId) -> true.
    ( co_activation_edge(NodeId, NeighborId) -> true
    % Otherwise (else branch), perform the following action.
    ; assertz(co_activation_edge(NodeId, NeighborId))
    % Close the expression opened above.
    ).
