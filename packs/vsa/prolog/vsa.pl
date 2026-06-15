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

:- module(vsa, [
    pai_bind/3,
    pai_unbind/3,
    pai_bundle/2,
    pai_cleanup/3,
    vsa_embed/2,
    vsa_embed_compound/2,
    vsa_role_vector/2,
    vsa_set_algebra/1,
    vsa_current_algebra/1,
    vsa_set_dimension/1,
    vsa_cosine/3
]).

:- use_module(library(lists),  [member/2, numlist/3, nth0/3, reverse/2, append/3, last/2]).
:- use_module(library(apply),  [maplist/2, maplist/3, maplist/4, foldl/4]).

:- dynamic vsa_active_algebra/1.
:- dynamic vsa_dim/1.
vsa_active_algebra(map).
vsa_dim(64).

vsa_set_algebra(Alg) :-
    memberchk(Alg, [map, hrr]),
    retractall(vsa_active_algebra(_)),
    assertz(vsa_active_algebra(Alg)).

vsa_current_algebra(Alg) :- vsa_active_algebra(Alg).

vsa_set_dimension(Dim) :-
    integer(Dim), Dim > 0,
    retractall(vsa_dim(_)),
    assertz(vsa_dim(Dim)).

% ---------------------------------------------------------------------------
% Vector utilities
% ---------------------------------------------------------------------------

vsa_cosine(A, B, Score) :-
    maplist([X, Y, P]>>(P is X * Y), A, B, Prods),
    foldl([P, Acc, NAcc]>>(NAcc is Acc + P), Prods, 0.0, Dot),
    foldl([X, Acc, NAcc]>>(NAcc is Acc + X*X), A, 0.0, SumA),
    foldl([X, Acc, NAcc]>>(NAcc is Acc + X*X), B, 0.0, SumB),
    MagA is sqrt(SumA),
    MagB is sqrt(SumB),
    ( (MagA < 1.0e-10 ; MagB < 1.0e-10)
    ->  Score = 0.0
    ;   Raw is Dot / (MagA * MagB),
        Score is max(-1.0, min(1.0, Raw))
    ).

vsa_normalize(Vec, Norm) :-
    foldl([X, Acc, NAcc]>>(NAcc is Acc + X*X), Vec, 0.0, SumSq),
    Mag is sqrt(SumSq),
    ( Mag < 1.0e-10
    ->  Norm = Vec
    ;   maplist([X, Y]>>(Y is X / Mag), Vec, Norm)
    ).

% ---------------------------------------------------------------------------
% Deterministic bipolar (±1) vector derived from a term via hash.
%
%   djb2 variant for the per-atom seed; Murmur2 finalizer per position so
%   that high bits are well-mixed even when seeds share low-bit parity.
% ---------------------------------------------------------------------------

vsa_embed(Term, Vec) :-
    vsa_dim(Dim),
    term_to_atom(Term, Atom),
    atom_codes(Atom, Codes),
    foldl([C, S0, S1]>>(S1 is ((S0 << 5) + S0 + C) /\ 0xFFFFFFFF),
          Codes, 5381, Seed),
    numlist(1, Dim, Indices),
    maplist([I, V]>>(
        H0 is (Seed xor (I * 2654435761)) /\ 0xFFFFFFFF,
        H1 is H0 xor (H0 >> 16),
        H2 is (H1 * 2246822519) /\ 0xFFFFFFFF,
        H3 is H2 xor (H2 >> 13),
        H4 is (H3 * 3266489917) /\ 0xFFFFFFFF,
        H5 is H4 xor (H4 >> 16),
        ( H5 /\ 1 =:= 0 -> V = 1.0 ; V = -1.0 )
    ), Indices, Vec).

% Positional role vector — derived from role_N atom
vsa_role_vector(Pos, Vec) :-
    atom_concat(role_, Pos, RoleName),
    vsa_embed(RoleName, Vec).

% ---------------------------------------------------------------------------
% pai_bind/3 — binding operator
%
%   MAP:  element-wise product   bind(r,f)[i] = r[i]*f[i]
%         Self-inverse for ±1 bipolar: bind(bind(r,f),r) = f exactly.
%   HRR:  circular convolution   bind(r,f)[k] = Σ_j r[j]*f[(k-j) mod N]
% ---------------------------------------------------------------------------

pai_bind(A, B, C) :-
    vsa_active_algebra(Alg),
    bind_alg(Alg, A, B, C).

bind_alg(map, A, B, C) :-
    maplist([X, Y, Z]>>(Z is X * Y), A, B, C).
bind_alg(hrr, A, B, C) :-
    circ_convolve(A, B, C).

% ---------------------------------------------------------------------------
% pai_unbind/3 — unbinding operator (approximate inverse of bind)
%
%   MAP:  same as bind  (±1 bipolar role is self-inverse)
%   HRR:  convolve with conjugate-reversal of role vector
% ---------------------------------------------------------------------------

pai_unbind(Bound, Role, Filler) :-
    vsa_active_algebra(Alg),
    unbind_alg(Alg, Bound, Role, Filler).

unbind_alg(map, Bound, Role, Filler) :-
    maplist([R, B, F]>>(F is R * B), Role, Bound, Filler).
unbind_alg(hrr, Bound, Role, Filler) :-
    hrr_inv(Role, RoleInv),
    circ_convolve(Bound, RoleInv, Filler).

% ---------------------------------------------------------------------------
% pai_bundle/2 — superposition (element-wise sum, then normalize)
% ---------------------------------------------------------------------------

pai_bundle([V|Vs], Bundled) :-
    foldl([Vec, Acc, NAcc]>>(
        maplist([X, Y, Z]>>(Z is X + Y), Vec, Acc, NAcc)
    ), Vs, V, Sum),
    vsa_normalize(Sum, Bundled).

% ---------------------------------------------------------------------------
% pai_cleanup/3 — nearest clean vector in a lexicon
%
%   Lexicon: list of Id-Vec pairs.
%   Returns the Id whose vector has highest cosine similarity to QueryVec.
% ---------------------------------------------------------------------------

pai_cleanup(QueryVec, Lexicon, NearestId) :-
    findall(Sim-Id, (
        member(Id-Vec, Lexicon),
        vsa_cosine(QueryVec, Vec, Sim)
    ), Pairs),
    ( Pairs = []
    ->  NearestId = none
    ;   msort(Pairs, Sorted),
        last(Sorted, _-NearestId)
    ).

% ---------------------------------------------------------------------------
% vsa_embed_compound/2 — compositional embedding of a compound term
%
%   fun(A1, …, An) is embedded as:
%       bundle(embed(fun), bind(role_1, embed(A1)), …, bind(role_N, embed(An)))
% ---------------------------------------------------------------------------

vsa_embed_compound(Term, Vec) :-
    Term =.. [Functor|Args],
    vsa_embed(Functor, RelVec),
    embed_args(Args, 1, BoundVecs),
    pai_bundle([RelVec|BoundVecs], Vec).

embed_args([], _, []).
embed_args([Arg|Rest], Pos, [Bound|Bounds]) :-
    vsa_role_vector(Pos, RoleVec),
    vsa_embed(Arg, FillerVec),
    pai_bind(RoleVec, FillerVec, Bound),
    Pos1 is Pos + 1,
    embed_args(Rest, Pos1, Bounds).

% ---------------------------------------------------------------------------
% HRR helpers — circular convolution and conjugate inverse
% ---------------------------------------------------------------------------

% circ_convolve(+A, +B, -C): C[k] = Σ_j A[j] * B[(k-j) mod N]
circ_convolve(A, B, C) :-
    length(A, N),
    N1 is N - 1,
    numlist(0, N1, Ks),
    maplist([K, CK]>>(
        foldl([J, Acc, NAcc]>>(
            nth0(J, A, AJ),
            JB is (K - J + N) mod N,
            nth0(JB, B, BJ),
            NAcc is Acc + AJ * BJ
        ), Ks, 0.0, CK)
    ), Ks, C).

% hrr_inv(+Vec, -Inv): conjugate reversal — Inv[0]=Vec[0], Inv[k]=Vec[N-k]
hrr_inv([A0|ARest], Inv) :-
    reverse(ARest, RevRest),
    Inv = [A0|RevRest].
