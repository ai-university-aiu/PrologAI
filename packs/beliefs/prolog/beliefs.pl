/*  PrologAI — Belief Structures and Propagators  (Specification PR 29)

    Every node_fact carries a belief scorecard:
        certainty, coherence, likelihood, desirability,
        valence, arousal, attempts, successes

    Propagator specialists run incrementally and locally; global
    recomputation is forbidden in steady state.  Priors ensure
    first-attempt ratios never divide by zero.

    Predicates:
      beliefs_belief/3         — +NodeId, +Field, -Value  OR  set +NodeId, +Field, +Value
      beliefs_belief_update/3  — +NodeId, +Field, +Delta
      beliefs_propagate/2      — +NodeId, +Propagator
      beliefs_belief_record/2  — +NodeId, -BeliefRecord
      beliefs_add_neighbor/2   — +NodeId, +NeighborId
      beliefs_attempt/2        — +NodeId, +Outcome (success|failure)
*/

% Declare this file as the 'beliefs' module and list its exported predicates.
:- module(beliefs, [
    % Supply 'beliefs_belief/3' as the next argument to the expression above.
    beliefs_belief/3,
    % Supply 'beliefs_belief_update/3' as the next argument to the expression above.
    beliefs_belief_update/3,
    % Supply 'beliefs_propagate/2' as the next argument to the expression above.
    beliefs_propagate/2,
    % Supply 'beliefs_belief_record/2' as the next argument to the expression above.
    beliefs_belief_record/2,
    % Supply 'beliefs_add_neighbor/2' as the next argument to the expression above.
    beliefs_add_neighbor/2,
    % Supply 'beliefs_attempt/2' as the next argument to the expression above.
    beliefs_attempt/2
% Close the expression opened above.
]).

% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),     [member/2]).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate), [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Storage
% belief_record(NodeId, Ce, Co, L, D, Va, Ar, At, Su)
% ---------------------------------------------------------------------------

% Declare 'belief_record/9' as dynamic — its facts may be added or removed at runtime.
:- dynamic belief_record/9.
% Declare 'neighbor_edge/2' as dynamic — its facts may be added or removed at runtime.
:- dynamic neighbor_edge/2.

% Define a clause for 'clamp field': succeed when the following conditions hold.
beliefs_field(certainty,    Raw, C) :- C is max(0.0, min(1.0, Raw)).
% Define a clause for 'clamp field': succeed when the following conditions hold.
beliefs_field(coherence,    Raw, C) :- C is max(0.0, min(1.0, Raw)).
% Define a clause for 'clamp field': succeed when the following conditions hold.
beliefs_field(likelihood,   Raw, C) :- C is max(0.0, min(1.0, Raw)).
% Define a clause for 'clamp field': succeed when the following conditions hold.
beliefs_field(desirability, Raw, C) :- C is max(-1.0, min(1.0, Raw)).
% Define a clause for 'clamp field': succeed when the following conditions hold.
beliefs_field(valence,      Raw, C) :- C is max(-1.0, min(1.0, Raw)).
% Define a clause for 'clamp field': succeed when the following conditions hold.
beliefs_field(arousal,      Raw, C) :- C is max(0.0, min(1.0, Raw)).
% Define a clause for 'clamp field': succeed when the following conditions hold.
beliefs_field(attempts,     Raw, C) :- C is max(0, Raw).
% Define a clause for 'clamp field': succeed when the following conditions hold.
beliefs_field(successes,    Raw, C) :- C is max(0, Raw).

% Define a clause for 'ensure record': succeed when the following conditions hold.
ensure_record(NodeId) :-
    % Execute: ( belief_record(NodeId, _, _, _, _, _, _, _, _).
    ( belief_record(NodeId, _, _, _, _, _, _, _, _)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   assertz(belief_record(NodeId, 0.5, 0.5, 0.5, 0.0, 0.0, 0.3, 0, 0))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Field access — deterministic via if-then-else
% ---------------------------------------------------------------------------

% Define a clause for 'get field': succeed when the following conditions hold.
get_field(NodeId, Field, Value) :-
    % State a fact for 'belief record' with the arguments listed below.
    belief_record(NodeId, Ce, Co, L, D, Va, Ar, At, Su),
    % Commit to this clause — discard all remaining choice points (cut).
    !,
    % Check that '( Field' is unifiable with 'certainty    -> Value = Ce'.
    ( Field = certainty    -> Value = Ce
    % Otherwise (else branch), perform the following action.
    ; Field = coherence    -> Value = Co
    % Otherwise (else branch), perform the following action.
    ; Field = likelihood   -> Value = L
    % Otherwise (else branch), perform the following action.
    ; Field = desirability -> Value = D
    % Otherwise (else branch), perform the following action.
    ; Field = valence      -> Value = Va
    % Otherwise (else branch), perform the following action.
    ; Field = arousal      -> Value = Ar
    % Otherwise (else branch), perform the following action.
    ; Field = attempts     -> Value = At
    % Otherwise (else branch), perform the following action.
    ; Field = successes    -> Value = Su
    % Close the expression opened above.
    ).

% Define a clause for 'set field': succeed when the following conditions hold.
set_field(NodeId, Field, NewV) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(belief_record(NodeId, Ce, Co, L, D, Va, Ar, At, Su)),
    % Commit to this clause — discard all remaining choice points (cut).
    !,
    % Check that '( Field' is unifiable with 'certainty    -> assertz(belief_record(NodeId, NewV, Co, L, D, Va, Ar, At, Su))'.
    ( Field = certainty    -> assertz(belief_record(NodeId, NewV, Co, L, D, Va, Ar, At, Su))
    % Otherwise (else branch), perform the following action.
    ; Field = coherence    -> assertz(belief_record(NodeId, Ce, NewV, L, D, Va, Ar, At, Su))
    % Otherwise (else branch), perform the following action.
    ; Field = likelihood   -> assertz(belief_record(NodeId, Ce, Co, NewV, D, Va, Ar, At, Su))
    % Otherwise (else branch), perform the following action.
    ; Field = desirability -> assertz(belief_record(NodeId, Ce, Co, L, NewV, Va, Ar, At, Su))
    % Otherwise (else branch), perform the following action.
    ; Field = valence      -> assertz(belief_record(NodeId, Ce, Co, L, D, NewV, Ar, At, Su))
    % Otherwise (else branch), perform the following action.
    ; Field = arousal      -> assertz(belief_record(NodeId, Ce, Co, L, D, Va, NewV, At, Su))
    % Otherwise (else branch), perform the following action.
    ; Field = attempts     -> assertz(belief_record(NodeId, Ce, Co, L, D, Va, Ar, NewV, Su))
    % Otherwise (else branch), perform the following action.
    ; Field = successes    -> assertz(belief_record(NodeId, Ce, Co, L, D, Va, Ar, At, NewV))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% beliefs_belief/3
% ---------------------------------------------------------------------------

% Define a clause for 'pai belief': succeed when the following conditions hold.
beliefs_belief(NodeId, Field, Value) :-
    % State a fact for 'ensure record' with the arguments listed below.
    ensure_record(NodeId),
    % Execute: ( number(Value).
    ( number(Value)
    % If the condition above succeeded, perform the following action.
    ->  beliefs_field(Field, Value, Clamped),
        % Continue the multi-line expression started above.
        set_field(NodeId, Field, Clamped)
    % Otherwise (else branch), perform the following action.
    ;   get_field(NodeId, Field, Value)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% beliefs_belief_update/3
% ---------------------------------------------------------------------------

% Define a clause for 'pai belief update': succeed when the following conditions hold.
beliefs_belief_update(NodeId, Field, Delta) :-
    % State a fact for 'ensure record' with the arguments listed below.
    ensure_record(NodeId),
    % State a fact for 'get field' with the arguments listed below.
    get_field(NodeId, Field, Current),
    % Evaluate the arithmetic expression 'Current + Delta' and bind the result to 'New'.
    New is Current + Delta,
    % State a fact for 'clamp field' with the arguments listed below.
    beliefs_field(Field, New, Clamped),
    % State the fact: set field(NodeId, Field, Clamped).
    set_field(NodeId, Field, Clamped).

% ---------------------------------------------------------------------------
% Propagators
% ---------------------------------------------------------------------------

% Define a clause for 'pai propagate': succeed when the following conditions hold.
beliefs_propagate(NodeId, Propagator) :-
    % State a fact for 'ensure record' with the arguments listed below.
    ensure_record(NodeId),
    % Check that '( Propagator' is unifiable with 'arousal'.
    ( Propagator = arousal
    % If the condition above succeeded, perform the following action.
    ->  findall(A, (neighbor_edge(NodeId, Nbr),
                   % Continue the multi-line expression started above.
                   ensure_record(Nbr), get_field(Nbr, arousal, A)), NbrA),
        % Continue the multi-line expression started above.
        propagate_blend(NodeId, arousal, NbrA)
    % Otherwise (else branch), perform the following action.
    ; Propagator = desirability
    % If the condition above succeeded, perform the following action.
    ->  findall(D, (neighbor_edge(NodeId, Nbr),
                   % Continue the multi-line expression started above.
                   ensure_record(Nbr), get_field(Nbr, desirability, D)), NbrD),
        % Continue the multi-line expression started above.
        propagate_blend(NodeId, desirability, NbrD)
    % Otherwise (else branch), perform the following action.
    ; Propagator = coherence
    % If the condition above succeeded, perform the following action.
    ->  propagate_coherence(NodeId)
    % Otherwise (else branch), perform the following action.
    ; Propagator = likelihood
    % If the condition above succeeded, perform the following action.
    ->  propagate_likelihood(NodeId)
    % Close the expression opened above.
    ).

% Define a clause for 'propagate blend': succeed when the following conditions hold.
propagate_blend(NodeId, Field, Vals) :-
    % Check that '( Vals' is unifiable with '[]'.
    ( Vals = []
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   length(Vals, N), sum_list(Vals, Sum), Avg is Sum / N,
        % Continue the multi-line expression started above.
        get_field(NodeId, Field, Cur),
        % Continue the multi-line expression started above.
        New is Cur + 0.3 * (Avg - Cur),
        % Continue the multi-line expression started above.
        beliefs_belief(NodeId, Field, New)
    % Close the expression opened above.
    ).

% Define a clause for 'propagate coherence': succeed when the following conditions hold.
propagate_coherence(NodeId) :-
    % State a fact for 'get field' with the arguments listed below.
    get_field(NodeId, desirability, MyD),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Sign, (
        % Continue the multi-line expression started above.
        neighbor_edge(NodeId, Nbr),
        % Continue the multi-line expression started above.
        ensure_record(Nbr),
        % Continue the multi-line expression started above.
        get_field(Nbr, desirability, ND),
        % Continue the multi-line expression started above.
        ( MyD >= 0.0, ND >= 0.0
        % If the condition above succeeded, perform the following action.
        ->  Sign = 1
        % Otherwise (else branch), perform the following action.
        ;   MyD < 0.0, ND < 0.0
        % If the condition above succeeded, perform the following action.
        ->  Sign = 1
        % Otherwise (else branch), perform the following action.
        ;   Sign = -1
        % Close the expression opened above.
        )
    % Continue the multi-line expression started above.
    ), Signs),
    % Check that '( Signs' is unifiable with '[]'.
    ( Signs = []
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   length(Signs, N), sum_list(Signs, SumS),
        % Continue the multi-line expression started above.
        Agreement is SumS / N,
        % Continue the multi-line expression started above.
        NormAgreement is (Agreement + 1.0) / 2.0,
        % Continue the multi-line expression started above.
        beliefs_belief(NodeId, coherence, NormAgreement)
    % Close the expression opened above.
    ).

% Define a clause for 'propagate likelihood': succeed when the following conditions hold.
propagate_likelihood(NodeId) :-
    % State a fact for 'get field' with the arguments listed below.
    get_field(NodeId, attempts, At),
    % State a fact for 'get field' with the arguments listed below.
    get_field(NodeId, successes, Su),
    % Evaluate the arithmetic expression 'At + 2' and bind the result to 'PriorAt'.
    PriorAt is At + 2,
    % Evaluate the arithmetic expression 'Su + 1' and bind the result to 'PriorSu'.
    PriorSu is Su + 1,
    % Evaluate the arithmetic expression 'PriorSu / PriorAt' and bind the result to 'L'.
    L is PriorSu / PriorAt,
    % State the fact: pai belief(NodeId, likelihood, L).
    beliefs_belief(NodeId, likelihood, L).

% ---------------------------------------------------------------------------
% beliefs_belief_record/2
% ---------------------------------------------------------------------------

% State a fact for 'pai belief record' with the arguments listed below.
beliefs_belief_record(NodeId, record(NodeId,
    % Continue the multi-line expression started above.
    certainty(Ce), coherence(Co), likelihood(L),
    % Continue the multi-line expression started above.
    desirability(D), valence(V), arousal(A),
    % Continue the multi-line expression started above.
    attempts(At), successes(Su))) :-
    % State a fact for 'ensure record' with the arguments listed below.
    ensure_record(NodeId),
    % State a fact for 'belief record' with the arguments listed below.
    belief_record(NodeId, Ce, Co, L, D, V, A, At, Su),
    % Commit to this clause — discard all remaining choice points (cut).
    !.

% ---------------------------------------------------------------------------
% beliefs_add_neighbor/2
% ---------------------------------------------------------------------------

% Define a clause for 'pai add neighbor': succeed when the following conditions hold.
beliefs_add_neighbor(NodeId, NeighborId) :-
    % Execute: ( neighbor_edge(NodeId, NeighborId) -> true.
    ( neighbor_edge(NodeId, NeighborId) -> true
    % Otherwise (else branch), perform the following action.
    ; assertz(neighbor_edge(NodeId, NeighborId))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% beliefs_attempt/2
% ---------------------------------------------------------------------------

% Define a clause for 'pai attempt': succeed when the following conditions hold.
beliefs_attempt(NodeId, Outcome) :-
    % State a fact for 'ensure record' with the arguments listed below.
    ensure_record(NodeId),
    % State a fact for 'pai belief update' with the arguments listed below.
    beliefs_belief_update(NodeId, attempts, 1),
    % Check that '( Outcome' is unifiable with 'success -> beliefs_belief_update(NodeId, successes, 1) ; true )'.
    ( Outcome = success -> beliefs_belief_update(NodeId, successes, 1) ; true ),
    % State the fact: pai propagate(NodeId, likelihood).
    beliefs_propagate(NodeId, likelihood).

% ---------------------------------------------------------------------------
% Helpers
% ---------------------------------------------------------------------------

% State the fact: sum list([], 0.0).
sum_list([], 0.0).
% Define a clause for 'sum list': succeed when the following conditions hold.
sum_list([H|T], Sum) :- sum_list(T, Rest), Sum is H + Rest.
