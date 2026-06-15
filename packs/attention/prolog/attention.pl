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

:- module(attention, [
    pai_attention/3,
    pai_wage/3,
    pai_attention_spread/2,
    pai_banker_cycle/0,
    pai_attention_metrics/1,
    pai_evict_lowest_lti/1,
    pai_attention_link/2
]).

:- use_module(library(lists),     [member/2]).
:- use_module(library(aggregate), [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Economy parameters
% ---------------------------------------------------------------------------

circulation_cap(1000.0).
sti_rent_rate(0.05).
lti_rent_rate(0.005).
spread_fraction(0.1).
wage_sti_rate(5.0).
wage_lti_rate(0.5).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

:- dynamic attention_value/3.  % NodeId, sti|lti, Value
:- dynamic banker_reserve/1.
:- dynamic co_activation_edge/2.
:- dynamic protected_node/1.

banker_reserve(1000.0).

ensure_attention(NodeId) :-
    ( attention_value(NodeId, sti, _) -> true
    ; assertz(attention_value(NodeId, sti, 0.0))
    ),
    ( attention_value(NodeId, lti, _) -> true
    ; assertz(attention_value(NodeId, lti, 0.0))
    ).

% ---------------------------------------------------------------------------
% pai_attention/3
% ---------------------------------------------------------------------------

pai_attention(NodeId, Field, Value) :-
    ensure_attention(NodeId),
    ( number(Value)
    ->  clamp_attention(Field, Value, Clamped),
        retractall(attention_value(NodeId, Field, _)),
        assertz(attention_value(NodeId, Field, Clamped))
    ;   attention_value(NodeId, Field, Value)
    ).

clamp_attention(sti, V, C) :-
    circulation_cap(Cap),
    C is max(0.0, min(Cap, V)).
clamp_attention(lti, V, C) :-
    C is max(0.0, V).

% ---------------------------------------------------------------------------
% pai_wage/3
% ---------------------------------------------------------------------------

pai_wage(NodeId, Contribution, credits(ActualSTI, LTIWage)) :-
    ensure_attention(NodeId),
    wage_sti_rate(BaseSTI),
    wage_lti_rate(BaseLTI),
    STIWage is BaseSTI * Contribution,
    LTIWage is BaseLTI * Contribution,
    % Conservation: draw from reserve
    ( retract(banker_reserve(Reserve)) -> true ; Reserve = 0.0 ),
    ActualSTI is min(STIWage, Reserve),
    NewReserve is max(0.0, Reserve - ActualSTI),
    assertz(banker_reserve(NewReserve)),
    % Credit sti
    ( attention_value(NodeId, sti, OldSTI) -> true ; OldSTI = 0.0 ),
    NewSTI is OldSTI + ActualSTI,
    clamp_attention(sti, NewSTI, ClampedSTI),
    retractall(attention_value(NodeId, sti, _)),
    assertz(attention_value(NodeId, sti, ClampedSTI)),
    % Credit lti (no reserve constraint)
    ( attention_value(NodeId, lti, OldLTI) -> true ; OldLTI = 0.0 ),
    NewLTI is OldLTI + LTIWage,
    retractall(attention_value(NodeId, lti, _)),
    assertz(attention_value(NodeId, lti, NewLTI)).

% ---------------------------------------------------------------------------
% pai_attention_spread/2
% ---------------------------------------------------------------------------

pai_attention_spread(NodeId, Neighbors) :-
    ensure_attention(NodeId),
    ( attention_value(NodeId, sti, MySTI) -> true ; MySTI = 0.0 ),
    spread_fraction(Frac),
    length(Neighbors, N),
    ( N > 0
    ->  Share is MySTI * Frac / N,
        Decay is MySTI * Frac,
        NewMySTI is max(0.0, MySTI - Decay),
        retractall(attention_value(NodeId, sti, _)),
        assertz(attention_value(NodeId, sti, NewMySTI)),
        forall(
            member(Nbr, Neighbors),
            ( ensure_attention(Nbr),
              ( attention_value(Nbr, sti, NbrSTI) -> true ; NbrSTI = 0.0 ),
              NewNbrSTI is NbrSTI + Share,
              clamp_attention(sti, NewNbrSTI, Clamped),
              retractall(attention_value(Nbr, sti, _)),
              assertz(attention_value(Nbr, sti, Clamped))
            )
        )
    ;   true
    ).

% ---------------------------------------------------------------------------
% pai_banker_cycle/0
% ---------------------------------------------------------------------------

pai_banker_cycle :-
    sti_rent_rate(STIRate),
    lti_rent_rate(LTIRate),
    circulation_cap(Cap),
    findall(NId, attention_value(NId, sti, _), AllIds0),
    sort(AllIds0, AllIds),
    forall(
        member(NId, AllIds),
        do_rent_and_spread(NId, STIRate, LTIRate, Cap)
    ).

do_rent_and_spread(NId, STIRate, LTIRate, Cap) :-
    ( attention_value(NId, sti, STI) -> true ; STI = 0.0 ),
    ( attention_value(NId, lti, LTI) -> true ; LTI = 0.0 ),
    STIRent is STI * STIRate,
    LTIRent is LTI * LTIRate,
    NewSTI is max(0.0, STI - STIRent),
    NewLTI is max(0.0, LTI - LTIRent),
    % Return rent to reserve (conservation)
    ( retract(banker_reserve(R)) -> true ; R = 0.0 ),
    NewR is min(Cap, R + STIRent),
    assertz(banker_reserve(NewR)),
    retractall(attention_value(NId, sti, _)),
    retractall(attention_value(NId, lti, _)),
    assertz(attention_value(NId, sti, NewSTI)),
    assertz(attention_value(NId, lti, NewLTI)),
    % Spread to co-activation neighbors
    findall(Nbr, co_activation_edge(NId, Nbr), Nbrs),
    pai_attention_spread(NId, Nbrs).

% ---------------------------------------------------------------------------
% pai_attention_metrics/1
% ---------------------------------------------------------------------------

pai_attention_metrics(metrics(TotalSTI, TotalLTI, Reserve)) :-
    aggregate_all(sum(S), attention_value(_, sti, S), TotalSTI0),
    aggregate_all(sum(L), attention_value(_, lti, L), TotalLTI0),
    ( number(TotalSTI0) -> TotalSTI = TotalSTI0 ; TotalSTI = 0.0 ),
    ( number(TotalLTI0) -> TotalLTI = TotalLTI0 ; TotalLTI = 0.0 ),
    ( banker_reserve(Reserve) -> true ; Reserve = 0.0 ).

% ---------------------------------------------------------------------------
% pai_evict_lowest_lti/1
% ---------------------------------------------------------------------------

pai_evict_lowest_lti(MaxItems) :-
    findall(LTI-NId, (
        attention_value(NId, lti, LTI),
        \+ protected_node(NId)
    ), Candidates),
    msort(Candidates, Ascending),
    length(Candidates, Total),
    ( Total > MaxItems
    ->  ToEvict is Total - MaxItems,
        take_k(ToEvict, Ascending, Evictees),
        forall(
            member(_-NId, Evictees),
            retractall(attention_value(NId, _, _))
        )
    ;   true
    ).

take_k(0, _, []) :- !.
take_k(_, [], []) :- !.
take_k(K, [H|T], [H|R]) :- K > 0, K1 is K - 1, take_k(K1, T, R).

% ---------------------------------------------------------------------------
% pai_attention_link/2
% ---------------------------------------------------------------------------

pai_attention_link(NodeId, NeighborId) :-
    ( co_activation_edge(NodeId, NeighborId) -> true
    ; assertz(co_activation_edge(NodeId, NeighborId))
    ).
