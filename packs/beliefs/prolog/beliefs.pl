/*  PrologAI — Belief Structures and Propagators  (Specification PR 29)

    Every node_fact carries a belief scorecard:
        certainty, coherence, likelihood, desirability,
        valence, arousal, attempts, successes

    Propagator specialists run incrementally and locally; global
    recomputation is forbidden in steady state.  Priors ensure
    first-attempt ratios never divide by zero.

    Predicates:
      pai_belief/3         — +NodeId, +Field, -Value  OR  set +NodeId, +Field, +Value
      pai_belief_update/3  — +NodeId, +Field, +Delta
      pai_propagate/2      — +NodeId, +Propagator
      pai_belief_record/2  — +NodeId, -BeliefRecord
      pai_add_neighbor/2   — +NodeId, +NeighborId
      pai_attempt/2        — +NodeId, +Outcome (success|failure)
*/

:- module(beliefs, [
    pai_belief/3,
    pai_belief_update/3,
    pai_propagate/2,
    pai_belief_record/2,
    pai_add_neighbor/2,
    pai_attempt/2
]).

:- use_module(library(lists),     [member/2]).
:- use_module(library(aggregate), [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Storage
% belief_record(NodeId, Ce, Co, L, D, Va, Ar, At, Su)
% ---------------------------------------------------------------------------

:- dynamic belief_record/9.
:- dynamic neighbor_edge/2.

clamp_field(certainty,    Raw, C) :- C is max(0.0, min(1.0, Raw)).
clamp_field(coherence,    Raw, C) :- C is max(0.0, min(1.0, Raw)).
clamp_field(likelihood,   Raw, C) :- C is max(0.0, min(1.0, Raw)).
clamp_field(desirability, Raw, C) :- C is max(-1.0, min(1.0, Raw)).
clamp_field(valence,      Raw, C) :- C is max(-1.0, min(1.0, Raw)).
clamp_field(arousal,      Raw, C) :- C is max(0.0, min(1.0, Raw)).
clamp_field(attempts,     Raw, C) :- C is max(0, Raw).
clamp_field(successes,    Raw, C) :- C is max(0, Raw).

ensure_record(NodeId) :-
    ( belief_record(NodeId, _, _, _, _, _, _, _, _)
    ->  true
    ;   assertz(belief_record(NodeId, 0.5, 0.5, 0.5, 0.0, 0.0, 0.3, 0, 0))
    ).

% ---------------------------------------------------------------------------
% Field access — deterministic via if-then-else
% ---------------------------------------------------------------------------

get_field(NodeId, Field, Value) :-
    belief_record(NodeId, Ce, Co, L, D, Va, Ar, At, Su),
    !,
    ( Field = certainty    -> Value = Ce
    ; Field = coherence    -> Value = Co
    ; Field = likelihood   -> Value = L
    ; Field = desirability -> Value = D
    ; Field = valence      -> Value = Va
    ; Field = arousal      -> Value = Ar
    ; Field = attempts     -> Value = At
    ; Field = successes    -> Value = Su
    ).

set_field(NodeId, Field, NewV) :-
    retract(belief_record(NodeId, Ce, Co, L, D, Va, Ar, At, Su)),
    !,
    ( Field = certainty    -> assertz(belief_record(NodeId, NewV, Co, L, D, Va, Ar, At, Su))
    ; Field = coherence    -> assertz(belief_record(NodeId, Ce, NewV, L, D, Va, Ar, At, Su))
    ; Field = likelihood   -> assertz(belief_record(NodeId, Ce, Co, NewV, D, Va, Ar, At, Su))
    ; Field = desirability -> assertz(belief_record(NodeId, Ce, Co, L, NewV, Va, Ar, At, Su))
    ; Field = valence      -> assertz(belief_record(NodeId, Ce, Co, L, D, NewV, Ar, At, Su))
    ; Field = arousal      -> assertz(belief_record(NodeId, Ce, Co, L, D, Va, NewV, At, Su))
    ; Field = attempts     -> assertz(belief_record(NodeId, Ce, Co, L, D, Va, Ar, NewV, Su))
    ; Field = successes    -> assertz(belief_record(NodeId, Ce, Co, L, D, Va, Ar, At, NewV))
    ).

% ---------------------------------------------------------------------------
% pai_belief/3
% ---------------------------------------------------------------------------

pai_belief(NodeId, Field, Value) :-
    ensure_record(NodeId),
    ( number(Value)
    ->  clamp_field(Field, Value, Clamped),
        set_field(NodeId, Field, Clamped)
    ;   get_field(NodeId, Field, Value)
    ).

% ---------------------------------------------------------------------------
% pai_belief_update/3
% ---------------------------------------------------------------------------

pai_belief_update(NodeId, Field, Delta) :-
    ensure_record(NodeId),
    get_field(NodeId, Field, Current),
    New is Current + Delta,
    clamp_field(Field, New, Clamped),
    set_field(NodeId, Field, Clamped).

% ---------------------------------------------------------------------------
% Propagators
% ---------------------------------------------------------------------------

pai_propagate(NodeId, Propagator) :-
    ensure_record(NodeId),
    ( Propagator = arousal
    ->  findall(A, (neighbor_edge(NodeId, Nbr),
                   ensure_record(Nbr), get_field(Nbr, arousal, A)), NbrA),
        propagate_blend(NodeId, arousal, NbrA)
    ; Propagator = desirability
    ->  findall(D, (neighbor_edge(NodeId, Nbr),
                   ensure_record(Nbr), get_field(Nbr, desirability, D)), NbrD),
        propagate_blend(NodeId, desirability, NbrD)
    ; Propagator = coherence
    ->  propagate_coherence(NodeId)
    ; Propagator = likelihood
    ->  propagate_likelihood(NodeId)
    ).

propagate_blend(NodeId, Field, Vals) :-
    ( Vals = []
    ->  true
    ;   length(Vals, N), sum_list(Vals, Sum), Avg is Sum / N,
        get_field(NodeId, Field, Cur),
        New is Cur + 0.3 * (Avg - Cur),
        pai_belief(NodeId, Field, New)
    ).

propagate_coherence(NodeId) :-
    get_field(NodeId, desirability, MyD),
    findall(Sign, (
        neighbor_edge(NodeId, Nbr),
        ensure_record(Nbr),
        get_field(Nbr, desirability, ND),
        ( MyD >= 0.0, ND >= 0.0
        ->  Sign = 1
        ;   MyD < 0.0, ND < 0.0
        ->  Sign = 1
        ;   Sign = -1
        )
    ), Signs),
    ( Signs = []
    ->  true
    ;   length(Signs, N), sum_list(Signs, SumS),
        Agreement is SumS / N,
        NormAgreement is (Agreement + 1.0) / 2.0,
        pai_belief(NodeId, coherence, NormAgreement)
    ).

propagate_likelihood(NodeId) :-
    get_field(NodeId, attempts, At),
    get_field(NodeId, successes, Su),
    PriorAt is At + 2,
    PriorSu is Su + 1,
    L is PriorSu / PriorAt,
    pai_belief(NodeId, likelihood, L).

% ---------------------------------------------------------------------------
% pai_belief_record/2
% ---------------------------------------------------------------------------

pai_belief_record(NodeId, record(NodeId,
    certainty(Ce), coherence(Co), likelihood(L),
    desirability(D), valence(V), arousal(A),
    attempts(At), successes(Su))) :-
    ensure_record(NodeId),
    belief_record(NodeId, Ce, Co, L, D, V, A, At, Su),
    !.

% ---------------------------------------------------------------------------
% pai_add_neighbor/2
% ---------------------------------------------------------------------------

pai_add_neighbor(NodeId, NeighborId) :-
    ( neighbor_edge(NodeId, NeighborId) -> true
    ; assertz(neighbor_edge(NodeId, NeighborId))
    ).

% ---------------------------------------------------------------------------
% pai_attempt/2
% ---------------------------------------------------------------------------

pai_attempt(NodeId, Outcome) :-
    ensure_record(NodeId),
    pai_belief_update(NodeId, attempts, 1),
    ( Outcome = success -> pai_belief_update(NodeId, successes, 1) ; true ),
    pai_propagate(NodeId, likelihood).

% ---------------------------------------------------------------------------
% Helpers
% ---------------------------------------------------------------------------

sum_list([], 0.0).
sum_list([H|T], Sum) :- sum_list(T, Rest), Sum is H + Rest.
