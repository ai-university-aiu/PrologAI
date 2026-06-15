/*  PrologAI — Pure-Prolog Vector Backend (PR 2)
    Implements the six-predicate interface using dynamic Prolog facts.
    This is the development fallback; the prologai-core Rust crate provides
    a production HNSW backend (RuVector or hnswlib) once compiled.

    Predicate naming: vbp_* (vector backend prolog).
*/

:- module(backend_prolog, [
    vbp_create/4,
    vbp_insert/4,
    vbp_search/4,
    vbp_delete/2,
    vbp_update_weights/3,
    vbp_close/1,
    hash_project/3,        % +Term, +Dim, -UnitVector
    cosine_similarity/3,   % +VecA, +VecB, -Score
    magnitude/2            % +Vec, -Magnitude
]).

:- use_module(library(apply),  [maplist/3, foldl/4]).
:- use_module(library(lists),  [nth1/3]).

% ---------------------------------------------------------------------------
% Internal store
% ---------------------------------------------------------------------------

% vbp_index(Ref, Name, Dimension)
:- dynamic vbp_index/3.

% vbp_entry(Ref, Id, Vector, Meta, Weight)
:- dynamic vbp_entry/5.

% Index reference counter
:- dynamic vbp_ref_counter/1.
vbp_ref_counter(0).

next_ref(Ref) :-
    retract(vbp_ref_counter(N)),
    N1 is N + 1,
    assertz(vbp_ref_counter(N1)),
    Ref = vb_ref(N1).

% ---------------------------------------------------------------------------
% Interface predicates
% ---------------------------------------------------------------------------

%! vbp_create(+Name, +Dimension, +Options, -Ref) is det.
vbp_create(Name, Dim, _Opts, Ref) :-
    next_ref(Ref),
    assertz(vbp_index(Ref, Name, Dim)).

%! vbp_insert(+Ref, +Id, +Vector, +Meta) is det.
vbp_insert(Ref, Id, Vec, Meta) :-
    ( vbp_entry(Ref, Id, _, _, _)
    -> retract(vbp_entry(Ref, Id, _, _, _))
    ;  true
    ),
    assertz(vbp_entry(Ref, Id, Vec, Meta, 1.0)).

%! vbp_search(+Ref, +QueryVec, +K, -Results) is det.
%  Results is a list of Id-Score pairs, sorted by descending cosine similarity.
vbp_search(Ref, Query, K, Results) :-
    findall(Score-Id,
            ( vbp_entry(Ref, Id, Vec, _, _W),
              cosine_similarity(Query, Vec, Score)
            ),
            Pairs),
    msort(Pairs, Sorted),
    reverse(Sorted, Desc),
    length(Desc, Total),
    Take is min(K, Total),
    length(TopK, Take),
    append(TopK, _, Desc),
    Results = TopK.

%! vbp_delete(+Ref, +Id) is det.
vbp_delete(Ref, Id) :-
    retractall(vbp_entry(Ref, Id, _, _, _)).

%! vbp_update_weights(+Ref, +Id, +Delta) is det.
vbp_update_weights(Ref, Id, Delta) :-
    ( retract(vbp_entry(Ref, Id, Vec, Meta, W))
    ->  W1 is max(0.0, W + Delta),
        assertz(vbp_entry(Ref, Id, Vec, Meta, W1))
    ;   true
    ).

%! vbp_close(+Ref) is det.
vbp_close(Ref) :-
    retractall(vbp_entry(Ref, _, _, _, _)),
    retractall(vbp_index(Ref, _, _)).

% ---------------------------------------------------------------------------
% Vector arithmetic
% ---------------------------------------------------------------------------

%! cosine_similarity(+VecA, +VecB, -Score) is det.
%  Score in [-1.0, 1.0].  Returns 0.0 if either vector is all-zero.
cosine_similarity(A, B, Score) :-
    dot_product(A, B, Dot),
    magnitude(A, MagA),
    magnitude(B, MagB),
    (   (MagA =:= 0.0 ; MagB =:= 0.0)
    ->  Score = 0.0
    ;   Raw is Dot / (MagA * MagB),
        Score is max(-1.0, min(1.0, Raw))
    ).

dot_product([], [], 0.0).
dot_product([H1|T1], [H2|T2], D) :-
    dot_product(T1, T2, D0),
    D is D0 + H1 * H2.

magnitude(Vec, Mag) :-
    foldl([X, Acc, NAcc]>>(NAcc is Acc + X*X), Vec, 0.0, SumSq),
    Mag is sqrt(SumSq).

%! l2_distance(+VecA, +VecB, -Dist) is det.
l2_distance(A, B, Dist) :-
    maplist([X, Y, D]>>(D is (X-Y)*(X-Y)), A, B, Diffs),
    foldl([D, Acc, NAcc]>>(NAcc is Acc + D), Diffs, 0.0, SumSq),
    Dist is sqrt(SumSq).

%! hash_project(+Term, +Dim, -Vector) is det.
%  Structural (not semantic) projection: maps a term to a unit vector of
%  length Dim by hashing its functor and arity.  Labeled 'structural' per
%  spec Flag 2 / PR 16.
hash_project(Term, Dim, Vector) :-
    term_to_atom(Term, Atom),
    atom_codes(Atom, Codes),
    length(Codes, Len),
    ( Len =:= 0 -> Seed = 0 ; Seed = Len ),
    numlist(1, Dim, Indices),
    maplist([I, V]>>(
        Code is (Seed * 1000003 + I * 31337) mod 65536,
        V is (Code - 32768) / 32768.0
    ), Indices, Raw),
    magnitude(Raw, Mag),
    ( Mag =:= 0.0
    ->  Vector = Raw
    ;   maplist([X, N]>>(N is X / Mag), Raw, Vector)
    ).
