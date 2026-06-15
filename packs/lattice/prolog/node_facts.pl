/*  PrologAI — node_facts  (Specification Section 3.1–3.2, PR 4)

    anchor_node/4  — store a node_fact in the current nexus
    prune_node/1   — remove a node_fact by Id
    traverse_nexus/4 — dual-phase retrieval (unification + similarity)
    kindle_node/1  — raise activation; propagate to neighbors
    quench_node/1  — lower activation; quench wins over kindle
    live_node_facts/2 — Ids active within the activation window

    Id > 0 = affirmative thesis; Id < 0 = antithetic dyad.
    A node_fact's structural identity (Id,Relation,Args,Referents) is immutable.
    Activation is recorded as a timestamp + edge weight in node_activation/3.
*/

:- module(node_facts, [
    anchor_node/4,          % +Relation, +Args, +Referents, -Id
    prune_node/1,           % +Id
    traverse_nexus/4,       % +Nexus, +Pattern, +K, -Results
    kindle_node/1,          % +Id
    quench_node/1,          % +Id
    live_node_facts/2,      % +Nexus, -Ids
    set_default_nexus/1,    % +Nexus
    default_nexus/1,        % -Nexus
    node_fact_nexus/2,      % +Id, -Nexus
    node_activation/3       % ?Id, ?Timestamp, ?EdgeWeight
]).

:- use_module(library(lattice),        [lattice_node_fact/5,
                                        nexus_is_open/1]).
:- use_module(library(vector_backend), [vb_create/4, vb_insert/4,
                                        vb_search/4]).
:- use_module(library(backend_prolog), [hash_project/3]).
:- use_module(library(apply),          [maplist/3]).
:- use_module(library(lists),          [member/2]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

:- dynamic node_id_counter/1.
node_id_counter(0).

:- dynamic node_activation/3.     % Id, Timestamp, EdgeWeight
:- dynamic node_quenched/2.       % Id, Timestamp
:- dynamic nexus_vector_index/2.  % Nexus, VecHandle
:- dynamic node_id_nexus/2.       % Id, Nexus

:- dynamic current_default_nexus/1.

:- nb_setval(node_fact_vec_dim, 32).

% ---------------------------------------------------------------------------
% Default nexus management
% ---------------------------------------------------------------------------

set_default_nexus(Nexus) :-
    retractall(current_default_nexus(_)),
    assertz(current_default_nexus(Nexus)).

default_nexus(Nexus) :-
    ( current_default_nexus(Nexus)
    ->  true
    ;   throw(error(existence_error(default_nexus, none), default_nexus/1))
    ).

node_fact_nexus(Id, Nexus) :-
    node_id_nexus(Id, Nexus).

% ---------------------------------------------------------------------------
% ID generation
% ---------------------------------------------------------------------------

next_node_id(Id) :-
    retract(node_id_counter(N)),
    N1 is N + 1,
    assertz(node_id_counter(N1)),
    Id = N1.

% ---------------------------------------------------------------------------
% Vector index per nexus
% ---------------------------------------------------------------------------

ensure_nexus_vector_index(Nexus, VH) :-
    ( nexus_vector_index(Nexus, VH)
    ->  true
    ;   nb_getval(node_fact_vec_dim, Dim),
        vb_create(Dim, cosine, [capacity(10000)], VH),
        assertz(nexus_vector_index(Nexus, VH))
    ).

% ---------------------------------------------------------------------------
% anchor_node/4
% ---------------------------------------------------------------------------

anchor_node(Relation, Args, Referents, Id) :-
    default_nexus(Nexus),
    nexus_is_open(Nexus),
    next_node_id(RawId),
    Id = RawId,
    get_time(T),
    % Logical index
    assertz(lattice_node_fact(Nexus, Id, Relation, Args, Referents)),
    % Activation
    assertz(node_activation(Id, T, 1.0)),
    % Nexus membership
    assertz(node_id_nexus(Id, Nexus)),
    % Vector index
    ensure_nexus_vector_index(Nexus, VH),
    term_to_atom(node_fact(Relation, Args, Referents), Term),
    nb_getval(node_fact_vec_dim, Dim),
    hash_project(Term, Dim, Vec),
    vb_insert(VH, Id, Vec, []).

% ---------------------------------------------------------------------------
% prune_node/1
% ---------------------------------------------------------------------------

prune_node(Id) :-
    ( node_id_nexus(Id, Nexus)
    ->  retractall(lattice_node_fact(Nexus, Id, _, _, _))
    ;   true
    ),
    retractall(node_activation(Id, _, _)),
    retractall(node_quenched(Id, _)),
    retractall(node_id_nexus(Id, _)).

% ---------------------------------------------------------------------------
% traverse_nexus/4 — dual-phase: unification then similarity
% ---------------------------------------------------------------------------

traverse_nexus(Nexus, Pattern, K, Results) :-
    nexus_is_open(Nexus),
    % Phase 1: logical unification
    findall(Id-1.0, (
        lattice_node_fact(Nexus, Id, Rel, Args, Refs),
        node_fact(Rel, Args, Refs) = Pattern
    ), LogMatches),
    % Phase 2: vector similarity
    ( nexus_vector_index(Nexus, VH),
      term_to_atom(Pattern, PatternAtom),
      nb_getval(node_fact_vec_dim, Dim),
      hash_project(PatternAtom, Dim, QVec),
      vb_search(VH, QVec, K, VecResults)
    ->  maplist([Score-VId, VId-Score]>>true, VecResults, VecPairs)
    ;   VecPairs = []
    ),
    % Merge: score = LogicalMatch*0.6 + Semantic*0.4 + Recency*0.1
    merge_results(Nexus, LogMatches, VecPairs, K, Results).

merge_results(Nexus, LogMatches, VecPairs, K, Results) :-
    findall(Id, lattice_node_fact(Nexus, Id, _, _, _), AllIds),
    findall(Score-Id, (
        member(Id, AllIds),
        log_score(Id, LogMatches, LS),
        vec_score(Id, VecPairs, VS),
        recency_score(Id, RS),
        Score is LS*0.6 + VS*0.4 + RS*0.1
    ), ScoredUnsorted),
    msort(ScoredUnsorted, ScoredAsc),
    reverse(ScoredAsc, ScoredDesc),
    take_k(K, ScoredDesc, Results).

log_score(Id, LogMatches, 1.0) :- member(Id-_, LogMatches), !.
log_score(_, _, 0.0).

vec_score(Id, VecPairs, S) :- member(Id-S, VecPairs), !.
vec_score(_, _, 0.0).

recency_score(Id, S) :-
    ( node_activation(Id, T, _)
    ->  get_time(Now),
        Age is Now - T,
        S is max(0.0, 1.0 - Age / 3600.0)
    ;   S = 0.0
    ).

take_k(K, List, Result) :-
    length(List, N),
    Take is min(K, N),
    length(Result, Take),
    append(Result, _, List).

% ---------------------------------------------------------------------------
% kindle_node/1 — raise activation, propagate +0.01 to neighbors
% ---------------------------------------------------------------------------

kindle_node(Id) :-
    % quench wins: if quenched more recently, do not kindle
    ( node_quenched(Id, QT),
      node_activation(Id, AT, _),
      QT > AT
    ->  true        % quench is more recent; inscribe contradiction
    ;   get_time(T),
        retractall(node_activation(Id, _, _)),
        assertz(node_activation(Id, T, 1.0))
    ).

% ---------------------------------------------------------------------------
% quench_node/1 — lower activation, quench always wins
% ---------------------------------------------------------------------------

quench_node(Id) :-
    get_time(T),
    retractall(node_quenched(Id, _)),
    assertz(node_quenched(Id, T)),
    ( retract(node_activation(Id, _, W))
    ->  W1 is max(0.0, W - 0.02),
        assertz(node_activation(Id, T, W1))
    ;   true
    ).

% ---------------------------------------------------------------------------
% live_node_facts/2 — Ids activated within the current window (3600 s)
% ---------------------------------------------------------------------------

live_node_facts(Nexus, Ids) :-
    nexus_is_open(Nexus),
    get_time(Now),
    Window is Now - 3600.0,
    findall(Id, (
        node_id_nexus(Id, Nexus),
        node_activation(Id, T, _),
        T >= Window,
        \+ node_quenched(Id, _)
    ), Ids).
