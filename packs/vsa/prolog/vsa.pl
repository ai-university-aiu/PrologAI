/*  PrologAI — Compositional Vector Binding (Vector Symbolic Architectures)  (PR 38)

    Gives the vector memory the ability to represent STRUCTURE, not just
    similarity, by implementing VSA (hyperdimensional computing) operations.

    Two interchangeable algebras:
        map — Multiply-Accumulate-Permute (element-wise product, ±1 bipolar).
               bind is its own inverse: unbind(bind(r,f), r) = f exactly.
        hrr — Holographic Reduced Representations (circular convolution).
               unbind uses the conjugate-reversal trick.

    Compositional embedding:
        A compound term fun(A1, …, An) is embedded by binding each argument's
        vector to its positional role vector (role_1, role_2, …) and bundling
        the results with the relation's vector.
        This lets unbinding role_k recover the k-th argument's vector.

    Predicates:
        pai_bind/3            — +RoleVec, +FillerVec, -BoundVec
        pai_unbind/3          — +BoundVec, +RoleVec, -FillerVec
        pai_bundle/2          — +VecList, -BundledVec
        pai_cleanup/3         — +QueryVec, +Lexicon, -NearestId
        vsa_embed/2           — +Term, -Vec
        vsa_embed_compound/2  — +CompoundTerm, -Vec
        vsa_role_vector/2     — +PositionIndex, -Vec
        vsa_set_algebra/1     — +algebra(map|hrr)
        vsa_current_algebra/1 — -Algebra
        vsa_set_dimension/1   — +Dim
*/

% Declare this file as the 'vsa' module and list its exported predicates.
:- module(vsa, [
    % Supply 'pai_bind/3' as the next argument to the expression above.
    pai_bind/3,
    % Supply 'pai_unbind/3' as the next argument to the expression above.
    pai_unbind/3,
    % Supply 'pai_bundle/2' as the next argument to the expression above.
    pai_bundle/2,
    % Supply 'pai_cleanup/3' as the next argument to the expression above.
    pai_cleanup/3,
    % Supply 'vsa_embed/2' as the next argument to the expression above.
    vsa_embed/2,
    % Supply 'vsa_embed_compound/2' as the next argument to the expression above.
    vsa_embed_compound/2,
    % Supply 'vsa_role_vector/2' as the next argument to the expression above.
    vsa_role_vector/2,
    % Supply 'vsa_set_algebra/1' as the next argument to the expression above.
    vsa_set_algebra/1,
    % Supply 'vsa_current_algebra/1' as the next argument to the expression above.
    vsa_current_algebra/1,
    % Supply 'vsa_set_dimension/1' as the next argument to the expression above.
    vsa_set_dimension/1,
    % Supply 'vsa_cosine/3' as the next argument to the expression above.
    vsa_cosine/3
% Close the expression opened above.
]).

% Import [member/2, numlist/3, nth0/3, reverse/2, append/3, last/2] from the built-in 'lists' library.
:- use_module(library(lists),  [member/2, numlist/3, nth0/3, reverse/2, append/3, last/2]).
% Import [maplist/2, maplist/3, maplist/4, foldl/4] from the built-in 'apply' library.
:- use_module(library(apply),  [maplist/2, maplist/3, maplist/4, foldl/4]).

% Declare 'vsa_active_algebra/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic vsa_active_algebra/1.
% Declare 'vsa_dim/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic vsa_dim/1.
% State the fact: vsa active algebra(map).
vsa_active_algebra(map).
% State the fact: vsa dim(64).
vsa_dim(64).

% Define a clause for 'vsa set algebra': succeed when the following conditions hold.
vsa_set_algebra(Alg) :-
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(Alg, [map, hrr]),
    % Remove all matching facts from the runtime knowledge base.
    retractall(vsa_active_algebra(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(vsa_active_algebra(Alg)).

% Define a clause for 'vsa current algebra': succeed when the following conditions hold.
vsa_current_algebra(Alg) :- vsa_active_algebra(Alg).

% Define a clause for 'vsa set dimension': succeed when the following conditions hold.
vsa_set_dimension(Dim) :-
    % Check that 'integer(Dim), Dim' is greater than '0'.
    integer(Dim), Dim > 0,
    % Remove all matching facts from the runtime knowledge base.
    retractall(vsa_dim(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(vsa_dim(Dim)).

% ---------------------------------------------------------------------------
% Vector utilities
% ---------------------------------------------------------------------------

% Define a clause for 'vsa cosine': succeed when the following conditions hold.
vsa_cosine(A, B, Score) :-
    % State a fact for 'maplist' with the arguments listed below.
    maplist([X, Y, P]>>(P is X * Y), A, B, Prods),
    % State a fact for 'foldl' with the arguments listed below.
    foldl([P, Acc, NAcc]>>(NAcc is Acc + P), Prods, 0.0, Dot),
    % State a fact for 'foldl' with the arguments listed below.
    foldl([X, Acc, NAcc]>>(NAcc is Acc + X*X), A, 0.0, SumA),
    % State a fact for 'foldl' with the arguments listed below.
    foldl([X, Acc, NAcc]>>(NAcc is Acc + X*X), B, 0.0, SumB),
    % Evaluate the arithmetic expression 'sqrt(SumA)' and bind the result to 'MagA'.
    MagA is sqrt(SumA),
    % Evaluate the arithmetic expression 'sqrt(SumB)' and bind the result to 'MagB'.
    MagB is sqrt(SumB),
    % Check that '( (MagA' is less than '1.0e-10 ; MagB < 1.0e-10)'.
    ( (MagA < 1.0e-10 ; MagB < 1.0e-10)
    % If the condition above succeeded, perform the following action.
    ->  Score = 0.0
    % Otherwise (else branch), perform the following action.
    ;   Raw is Dot / (MagA * MagB),
        % Continue the multi-line expression started above.
        Score is max(-1.0, min(1.0, Raw))
    % Close the expression opened above.
    ).

% Define a clause for 'vsa normalize': succeed when the following conditions hold.
vsa_normalize(Vec, Norm) :-
    % State a fact for 'foldl' with the arguments listed below.
    foldl([X, Acc, NAcc]>>(NAcc is Acc + X*X), Vec, 0.0, SumSq),
    % Evaluate the arithmetic expression 'sqrt(SumSq)' and bind the result to 'Mag'.
    Mag is sqrt(SumSq),
    % Check that '( Mag' is less than '1.0e-10'.
    ( Mag < 1.0e-10
    % If the condition above succeeded, perform the following action.
    ->  Norm = Vec
    % Otherwise (else branch), perform the following action.
    ;   maplist([X, Y]>>(Y is X / Mag), Vec, Norm)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Deterministic bipolar (±1) vector derived from a term via hash.
%
%   djb2 variant for the per-atom seed; Murmur2 finalizer per position so
%   that high bits are well-mixed even when seeds share low-bit parity.
% ---------------------------------------------------------------------------

% Define a clause for 'vsa embed': succeed when the following conditions hold.
vsa_embed(Term, Vec) :-
    % State a fact for 'vsa dim' with the arguments listed below.
    vsa_dim(Dim),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(Term, Atom),
    % State a fact for 'atom codes' with the arguments listed below.
    atom_codes(Atom, Codes),
    % State a fact for 'foldl' with the arguments listed below.
    foldl([C, S0, S1]>>(S1 is ((S0 << 5) + S0 + C) /\ 0xFFFFFFFF),
          % Continue the multi-line expression started above.
          Codes, 5381, Seed),
    % State a fact for 'numlist' with the arguments listed below.
    numlist(1, Dim, Indices),
    % State a fact for 'maplist' with the arguments listed below.
    maplist([I, V]>>(
        % Continue the multi-line expression started above.
        H0 is (Seed xor (I * 2654435761)) /\ 0xFFFFFFFF,
        % Continue the multi-line expression started above.
        H1 is H0 xor (H0 >> 16),
        % Continue the multi-line expression started above.
        H2 is (H1 * 2246822519) /\ 0xFFFFFFFF,
        % Continue the multi-line expression started above.
        H3 is H2 xor (H2 >> 13),
        % Continue the multi-line expression started above.
        H4 is (H3 * 3266489917) /\ 0xFFFFFFFF,
        % Continue the multi-line expression started above.
        H5 is H4 xor (H4 >> 16),
        % Continue the multi-line expression started above.
        ( H5 /\ 1 =:= 0 -> V = 1.0 ; V = -1.0 )
    % Continue the multi-line expression started above.
    ), Indices, Vec).

% Positional role vector — derived from role_N atom
% Define a clause for 'vsa role vector': succeed when the following conditions hold.
vsa_role_vector(Pos, Vec) :-
    % State a fact for 'atom concat' with the arguments listed below.
    atom_concat(role_, Pos, RoleName),
    % State the fact: vsa embed(RoleName, Vec).
    vsa_embed(RoleName, Vec).

% ---------------------------------------------------------------------------
% pai_bind/3 — binding operator
%
%   MAP:  element-wise product   bind(r,f)[i] = r[i]*f[i]
%         Self-inverse for ±1 bipolar: bind(bind(r,f),r) = f exactly.
%   HRR:  circular convolution   bind(r,f)[k] = Σ_j r[j]*f[(k-j) mod N]
% ---------------------------------------------------------------------------

% Define a clause for 'pai bind': succeed when the following conditions hold.
pai_bind(A, B, C) :-
    % State a fact for 'vsa active algebra' with the arguments listed below.
    vsa_active_algebra(Alg),
    % State the fact: bind alg(Alg, A, B, C).
    bind_alg(Alg, A, B, C).

% Define a clause for 'bind alg': succeed when the following conditions hold.
bind_alg(map, A, B, C) :-
    % State the fact: maplist([X, Y, Z]>>(Z is X * Y), A, B, C).
    maplist([X, Y, Z]>>(Z is X * Y), A, B, C).
% Define a clause for 'bind alg': succeed when the following conditions hold.
bind_alg(hrr, A, B, C) :-
    % State the fact: circ convolve(A, B, C).
    circ_convolve(A, B, C).

% ---------------------------------------------------------------------------
% pai_unbind/3 — unbinding operator (approximate inverse of bind)
%
%   MAP:  same as bind  (±1 bipolar role is self-inverse)
%   HRR:  convolve with conjugate-reversal of role vector
% ---------------------------------------------------------------------------

% Define a clause for 'pai unbind': succeed when the following conditions hold.
pai_unbind(Bound, Role, Filler) :-
    % State a fact for 'vsa active algebra' with the arguments listed below.
    vsa_active_algebra(Alg),
    % State the fact: unbind alg(Alg, Bound, Role, Filler).
    unbind_alg(Alg, Bound, Role, Filler).

% Define a clause for 'unbind alg': succeed when the following conditions hold.
unbind_alg(map, Bound, Role, Filler) :-
    % State the fact: maplist([R, B, F]>>(F is R * B), Role, Bound, Filler).
    maplist([R, B, F]>>(F is R * B), Role, Bound, Filler).
% Define a clause for 'unbind alg': succeed when the following conditions hold.
unbind_alg(hrr, Bound, Role, Filler) :-
    % State a fact for 'hrr inv' with the arguments listed below.
    hrr_inv(Role, RoleInv),
    % State the fact: circ convolve(Bound, RoleInv, Filler).
    circ_convolve(Bound, RoleInv, Filler).

% ---------------------------------------------------------------------------
% pai_bundle/2 — superposition (element-wise sum, then normalize)
% ---------------------------------------------------------------------------

% Define a clause for 'pai bundle': succeed when the following conditions hold.
pai_bundle([V|Vs], Bundled) :-
    % State a fact for 'foldl' with the arguments listed below.
    foldl([Vec, Acc, NAcc]>>(
        % Continue the multi-line expression started above.
        maplist([X, Y, Z]>>(Z is X + Y), Vec, Acc, NAcc)
    % Continue the multi-line expression started above.
    ), Vs, V, Sum),
    % State the fact: vsa normalize(Sum, Bundled).
    vsa_normalize(Sum, Bundled).

% ---------------------------------------------------------------------------
% pai_cleanup/3 — nearest clean vector in a lexicon
%
%   Lexicon: list of Id-Vec pairs.
%   Returns the Id whose vector has highest cosine similarity to QueryVec.
% ---------------------------------------------------------------------------

% Define a clause for 'pai cleanup': succeed when the following conditions hold.
pai_cleanup(QueryVec, Lexicon, NearestId) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Sim-Id, (
        % Continue the multi-line expression started above.
        member(Id-Vec, Lexicon),
        % Continue the multi-line expression started above.
        vsa_cosine(QueryVec, Vec, Sim)
    % Continue the multi-line expression started above.
    ), Pairs),
    % Check that '( Pairs' is unifiable with '[]'.
    ( Pairs = []
    % If the condition above succeeded, perform the following action.
    ->  NearestId = none
    % Otherwise (else branch), perform the following action.
    ;   msort(Pairs, Sorted),
        % Continue the multi-line expression started above.
        last(Sorted, _-NearestId)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% vsa_embed_compound/2 — compositional embedding of a compound term
%
%   fun(A1, …, An) is embedded as:
%       bundle(embed(fun), bind(role_1, embed(A1)), …, bind(role_N, embed(An)))
% ---------------------------------------------------------------------------

% Define a clause for 'vsa embed compound': succeed when the following conditions hold.
vsa_embed_compound(Term, Vec) :-
    % Execute: Term =.. [Functor|Args],.
    Term =.. [Functor|Args],
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(Functor, RelVec),
    % State a fact for 'embed args' with the arguments listed below.
    embed_args(Args, 1, BoundVecs),
    % State the fact: pai bundle([RelVec|BoundVecs], Vec).
    pai_bundle([RelVec|BoundVecs], Vec).

% State the fact: embed args([], _, []).
embed_args([], _, []).
% Define a clause for 'embed args': succeed when the following conditions hold.
embed_args([Arg|Rest], Pos, [Bound|Bounds]) :-
    % State a fact for 'vsa role vector' with the arguments listed below.
    vsa_role_vector(Pos, RoleVec),
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(Arg, FillerVec),
    % State a fact for 'pai bind' with the arguments listed below.
    pai_bind(RoleVec, FillerVec, Bound),
    % Evaluate the arithmetic expression 'Pos + 1' and bind the result to 'Pos1'.
    Pos1 is Pos + 1,
    % State the fact: embed args(Rest, Pos1, Bounds).
    embed_args(Rest, Pos1, Bounds).

% ---------------------------------------------------------------------------
% HRR helpers — circular convolution and conjugate inverse
% ---------------------------------------------------------------------------

% circ_convolve(+A, +B, -C): C[k] = Σ_j A[j] * B[(k-j) mod N]
% Define a clause for 'circ convolve': succeed when the following conditions hold.
circ_convolve(A, B, C) :-
    % Unify 'N' with the number of elements in list 'A'.
    length(A, N),
    % Evaluate the arithmetic expression 'N - 1' and bind the result to 'N1'.
    N1 is N - 1,
    % State a fact for 'numlist' with the arguments listed below.
    numlist(0, N1, Ks),
    % State a fact for 'maplist' with the arguments listed below.
    maplist([K, CK]>>(
        % Continue the multi-line expression started above.
        foldl([J, Acc, NAcc]>>(
            % Continue the multi-line expression started above.
            nth0(J, A, AJ),
            % Continue the multi-line expression started above.
            JB is (K - J + N) mod N,
            % Continue the multi-line expression started above.
            nth0(JB, B, BJ),
            % Continue the multi-line expression started above.
            NAcc is Acc + AJ * BJ
        % Continue the multi-line expression started above.
        ), Ks, 0.0, CK)
    % Continue the multi-line expression started above.
    ), Ks, C).

% hrr_inv(+Vec, -Inv): conjugate reversal — Inv[0]=Vec[0], Inv[k]=Vec[N-k]
% Define a clause for 'hrr inv': succeed when the following conditions hold.
hrr_inv([A0|ARest], Inv) :-
    % State a fact for 'reverse' with the arguments listed below.
    reverse(ARest, RevRest),
    % Check that 'Inv' is unifiable with '[A0|RevRest]'.
    Inv = [A0|RevRest].
