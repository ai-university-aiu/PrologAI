/*  PrologAI — Pure-Prolog Vector Backend (PR 2)
    Implements the six-predicate interface using dynamic Prolog facts.
    This is the development fallback; the prologai-core Rust crate provides
    a production HNSW backend (RuVector or hnswlib) once compiled.

    Predicate naming: vbp_* (vector backend prolog).
*/

% Declare this file as the 'backend_prolog' module and list its exported predicates.
:- module(backend_prolog, [
    % Supply 'vbp_create/4' as the next argument to the expression above.
    vbp_create/4,
    % Supply 'vbp_insert/4' as the next argument to the expression above.
    vbp_insert/4,
    % Supply 'vbp_search/4' as the next argument to the expression above.
    vbp_search/4,
    % Supply 'vbp_delete/2' as the next argument to the expression above.
    vbp_delete/2,
    % Supply 'vbp_update_weights/3' as the next argument to the expression above.
    vbp_update_weights/3,
    % Supply 'vbp_close/1' as the next argument to the expression above.
    vbp_close/1,
    % Continue the multi-line expression started above.
    hash_project/3,        % +Term, +Dim, -UnitVector
    % Continue the multi-line expression started above.
    cosine_similarity/3,   % +VecA, +VecB, -Score
    % Continue the multi-line expression started above.
    magnitude/2            % +Vec, -Magnitude
% Close the expression opened above.
]).

% Import [maplist/3, foldl/4] from the built-in 'apply' library.
:- use_module(library(apply),  [maplist/3, foldl/4]).
% Import [nth1/3] from the built-in 'lists' library.
:- use_module(library(lists),  [nth1/3]).

% ---------------------------------------------------------------------------
% Internal store
% ---------------------------------------------------------------------------

% vbp_index(Ref, Name, Dimension)
% Declare 'vbp_index/3' as dynamic — its facts may be added or removed at runtime.
:- dynamic vbp_index/3.

% vbp_entry(Ref, Id, Vector, Meta, Weight)
% Declare 'vbp_entry/5' as dynamic — its facts may be added or removed at runtime.
:- dynamic vbp_entry/5.

% Index reference counter
% Declare 'vbp_ref_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic vbp_ref_counter/1.
% State the fact: vbp ref counter(0).
vbp_ref_counter(0).

% Define a clause for 'next ref': succeed when the following conditions hold.
next_ref(Ref) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(vbp_ref_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(vbp_ref_counter(N1)),
    % Check that 'Ref' is unifiable with 'vb_ref(N1)'.
    Ref = vb_ref(N1).

% ---------------------------------------------------------------------------
% Interface predicates
% ---------------------------------------------------------------------------

%! vbp_create(+Name, +Dimension, +Options, -Ref) is det.
% Define a clause for 'vbp create': succeed when the following conditions hold.
vbp_create(Name, Dim, _Opts, Ref) :-
    % State a fact for 'next ref' with the arguments listed below.
    next_ref(Ref),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(vbp_index(Ref, Name, Dim)).

%! vbp_insert(+Ref, +Id, +Vector, +Meta) is det.
% Define a clause for 'vbp insert': succeed when the following conditions hold.
vbp_insert(Ref, Id, Vec, Meta) :-
    % Execute: ( vbp_entry(Ref, Id, _, _, _).
    ( vbp_entry(Ref, Id, _, _, _)
    % If the condition above succeeded, perform the following action.
    -> retract(vbp_entry(Ref, Id, _, _, _))
    % Otherwise (else branch), perform the following action.
    ;  true
    % Close the expression opened above.
    ),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(vbp_entry(Ref, Id, Vec, Meta, 1.0)).

%! vbp_search(+Ref, +QueryVec, +K, -Results) is det.
%  Results is a list of Id-Score pairs, sorted by descending cosine similarity.
% Define a clause for 'vbp search': succeed when the following conditions hold.
vbp_search(Ref, Query, K, Results) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Score-Id,
            % Continue the multi-line expression started above.
            ( vbp_entry(Ref, Id, Vec, _, _W),
              % Continue the multi-line expression started above.
              cosine_similarity(Query, Vec, Score)
            % Close the expression opened above.
            ),
            % Supply 'Pairs' as the next argument to the expression above.
            Pairs),
    % Sort list 'Pairs' into 'Sorted', keeping duplicates.
    msort(Pairs, Sorted),
    % State a fact for 'reverse' with the arguments listed below.
    reverse(Sorted, Desc),
    % Unify 'Total' with the number of elements in list 'Desc'.
    length(Desc, Total),
    % Evaluate the arithmetic expression 'min(K, Total)' and bind the result to 'Take'.
    Take is min(K, Total),
    % Unify 'Take' with the number of elements in list 'TopK'.
    length(TopK, Take),
    % Unify the third argument with the concatenation of the first two lists.
    append(TopK, _, Desc),
    % Check that 'Results' is unifiable with 'TopK'.
    Results = TopK.

%! vbp_delete(+Ref, +Id) is det.
% Define a clause for 'vbp delete': succeed when the following conditions hold.
vbp_delete(Ref, Id) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(vbp_entry(Ref, Id, _, _, _)).

%! vbp_update_weights(+Ref, +Id, +Delta) is det.
% Define a clause for 'vbp update weights': succeed when the following conditions hold.
vbp_update_weights(Ref, Id, Delta) :-
    % Execute: ( retract(vbp_entry(Ref, Id, Vec, Meta, W)).
    ( retract(vbp_entry(Ref, Id, Vec, Meta, W))
    % If the condition above succeeded, perform the following action.
    ->  W1 is max(0.0, W + Delta),
        % Continue the multi-line expression started above.
        assertz(vbp_entry(Ref, Id, Vec, Meta, W1))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

%! vbp_close(+Ref) is det.
% Define a clause for 'vbp close': succeed when the following conditions hold.
vbp_close(Ref) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(vbp_entry(Ref, _, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(vbp_index(Ref, _, _)).

% ---------------------------------------------------------------------------
% Vector arithmetic
% ---------------------------------------------------------------------------

%! cosine_similarity(+VecA, +VecB, -Score) is det.
%  Score in [-1.0, 1.0].  Returns 0.0 if either vector is all-zero.
% Define a clause for 'cosine similarity': succeed when the following conditions hold.
cosine_similarity(A, B, Score) :-
    % State a fact for 'dot product' with the arguments listed below.
    dot_product(A, B, Dot),
    % State a fact for 'magnitude' with the arguments listed below.
    magnitude(A, MagA),
    % State a fact for 'magnitude' with the arguments listed below.
    magnitude(B, MagB),
    % Check that '(   (MagA' is numerically equal to '0.0 ; MagB =:= 0.0)'.
    (   (MagA =:= 0.0 ; MagB =:= 0.0)
    % If the condition above succeeded, perform the following action.
    ->  Score = 0.0
    % Otherwise (else branch), perform the following action.
    ;   Raw is Dot / (MagA * MagB),
        % Continue the multi-line expression started above.
        Score is max(-1.0, min(1.0, Raw))
    % Close the expression opened above.
    ).

% State the fact: dot product([], [], 0.0).
dot_product([], [], 0.0).
% Define a clause for 'dot product': succeed when the following conditions hold.
dot_product([H1|T1], [H2|T2], D) :-
    % State a fact for 'dot product' with the arguments listed below.
    dot_product(T1, T2, D0),
    % Evaluate the arithmetic expression 'D0 + H1 * H2' and bind the result to 'D'.
    D is D0 + H1 * H2.

% Define a clause for 'magnitude': succeed when the following conditions hold.
magnitude(Vec, Mag) :-
    % State a fact for 'foldl' with the arguments listed below.
    foldl([X, Acc, NAcc]>>(NAcc is Acc + X*X), Vec, 0.0, SumSq),
    % Evaluate the arithmetic expression 'sqrt(SumSq)' and bind the result to 'Mag'.
    Mag is sqrt(SumSq).

%! l2_distance(+VecA, +VecB, -Dist) is det.
% Define a clause for 'l2 distance': succeed when the following conditions hold.
l2_distance(A, B, Dist) :-
    % State a fact for 'maplist' with the arguments listed below.
    maplist([X, Y, D]>>(D is (X-Y)*(X-Y)), A, B, Diffs),
    % State a fact for 'foldl' with the arguments listed below.
    foldl([D, Acc, NAcc]>>(NAcc is Acc + D), Diffs, 0.0, SumSq),
    % Evaluate the arithmetic expression 'sqrt(SumSq)' and bind the result to 'Dist'.
    Dist is sqrt(SumSq).

%! hash_project(+Term, +Dim, -Vector) is det.
%  Structural (not semantic) projection: maps a term to a unit vector of
%  length Dim by hashing its functor and arity.  Labeled 'structural' per
%  spec Flag 2 / PR 16.
% Define a clause for 'hash project': succeed when the following conditions hold.
hash_project(Term, Dim, Vector) :-
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(Term, Atom),
    % State a fact for 'atom codes' with the arguments listed below.
    atom_codes(Atom, Codes),
    % Unify 'Len' with the number of elements in list 'Codes'.
    length(Codes, Len),
    % Check that '( Len' is numerically equal to '0 -> Seed = 0 ; Seed = Len )'.
    ( Len =:= 0 -> Seed = 0 ; Seed = Len ),
    % State a fact for 'numlist' with the arguments listed below.
    numlist(1, Dim, Indices),
    % State a fact for 'maplist' with the arguments listed below.
    maplist([I, V]>>(
        % Continue the multi-line expression started above.
        Code is (Seed * 1000003 + I * 31337) mod 65536,
        % Continue the multi-line expression started above.
        V is (Code - 32768) / 32768.0
    % Continue the multi-line expression started above.
    ), Indices, Raw),
    % State a fact for 'magnitude' with the arguments listed below.
    magnitude(Raw, Mag),
    % Check that '( Mag' is numerically equal to '0.0'.
    ( Mag =:= 0.0
    % If the condition above succeeded, perform the following action.
    ->  Vector = Raw
    % Otherwise (else branch), perform the following action.
    ;   maplist([X, N]>>(N is X / Mag), Raw, Vector)
    % Close the expression opened above.
    ).
