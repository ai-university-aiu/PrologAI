/*  PrologAI — PR 38 Compositional Vector Binding (VSA) Acceptance Tests

    AC-PR38-001: Given give(alice, book, bob) and give(bob, book, alice)
                 embedded compositionally, then their whole-structure vectors
                 differ substantially while unbinding OBJECT from each returns
                 the vector nearest to book.
    AC-PR38-002: pai_bind / pai_unbind round-trip under MAP algebra.
    AC-PR38-003: pai_bind / pai_unbind round-trip under HRR algebra.
    AC-PR38-004: pai_bundle produces a normalized (unit) vector.
    AC-PR38-005: vsa_embed is deterministic — same term same vector.
    AC-PR38-006: pai_cleanup returns nearest-lexicon item.
    AC-PR38-007: vsa_embed_compound produces a vector of correct dimension.
    AC-PR38-008: Switching algebra changes bind behavior.
    AC-PR38-009: vsa_role_vector/2 is deterministic and dimension-consistent.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/vsa/prolog'], VSAPath),
   assertz(file_search_path(library, VSAPath)).

:- use_module(library(plunit)).
:- use_module(library(vsa), [
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

:- begin_tests(pr38, [setup(pr38_setup), cleanup(pr38_cleanup)]).

pr38_setup :-
    vsa:retractall(vsa:vsa_active_algebra(_)),
    vsa:retractall(vsa:vsa_dim(_)),
    vsa:assertz(vsa:vsa_active_algebra(map)),
    vsa:assertz(vsa:vsa_dim(64)).

pr38_cleanup :-
    vsa:retractall(vsa:vsa_active_algebra(_)),
    vsa:retractall(vsa:vsa_dim(_)),
    vsa:assertz(vsa:vsa_active_algebra(map)),
    vsa:assertz(vsa:vsa_dim(64)).

%  AC-PR38-001: whole-structure vectors differ; unbinding OBJECT returns book
test(compound_embedding_and_unbind, [setup(pr38_setup)]) :-
    vsa_embed_compound(give(alice, book, bob), V1),
    vsa_embed_compound(give(bob,   book, alice), V2),
    % Whole-structure vectors differ substantially
    vsa_cosine(V1, V2, Sim),
    Sim < 0.95,
    % Unbind position 2 (OBJECT = arg 2) from each compound
    vsa_role_vector(2, Role2),
    pai_unbind(V1, Role2, U1),
    pai_unbind(V2, Role2, U2),
    % Build a lexicon of all atoms involved
    vsa_embed(alice, AliceVec),
    vsa_embed(book,  BookVec),
    vsa_embed(bob,   BobVec),
    Lexicon = [alice-AliceVec, book-BookVec, bob-BobVec],
    pai_cleanup(U1, Lexicon, Nearest1),
    pai_cleanup(U2, Lexicon, Nearest2),
    Nearest1 == book,
    Nearest2 == book.

%  AC-PR38-002: bind/unbind round-trip under MAP algebra
test(map_bind_unbind_roundtrip, [setup(pr38_setup)]) :-
    vsa_set_algebra(map),
    vsa_embed(agent_role, RoleVec),
    vsa_embed(alice, FillerVec),
    pai_bind(RoleVec, FillerVec, Bound),
    pai_unbind(Bound, RoleVec, Recovered),
    vsa_cosine(Recovered, FillerVec, Sim),
    Sim > 0.99.

%  AC-PR38-003: bind/unbind round-trip under HRR algebra (approximate recovery)
test(hrr_bind_unbind_roundtrip, [setup(pr38_setup)]) :-
    vsa_set_algebra(hrr),
    vsa_embed(agent_role, RoleVec),
    vsa_embed(alice, FillerVec),
    pai_bind(RoleVec, FillerVec, Bound),
    pai_unbind(Bound, RoleVec, Recovered),
    vsa_cosine(Recovered, FillerVec, Sim),
    % HRR with bipolar ±1 vectors is approximate; random noise ≈ 0
    Sim > 0.50.

%  AC-PR38-004: pai_bundle produces a normalized vector
test(bundle_is_normalized, [setup(pr38_setup)]) :-
    vsa_embed(a38, VA),
    vsa_embed(b38, VB),
    vsa_embed(c38, VC),
    pai_bundle([VA, VB, VC], Bundled),
    foldl([X, Acc, NAcc]>>(NAcc is Acc + X*X), Bundled, 0.0, SumSq),
    Mag is sqrt(SumSq),
    abs(Mag - 1.0) < 1.0e-9.

%  AC-PR38-005: vsa_embed is deterministic
test(embed_deterministic, [setup(pr38_setup)]) :-
    vsa_embed(some_atom_38, V1),
    vsa_embed(some_atom_38, V2),
    V1 == V2.

%  AC-PR38-006: pai_cleanup returns nearest lexicon item
test(cleanup_nearest, [setup(pr38_setup)]) :-
    vsa_embed(cat38, CatVec),
    vsa_embed(dog38, DogVec),
    vsa_embed(fish38, FishVec),
    % Query close to cat
    pai_bundle([CatVec, CatVec, CatVec], NearCat),
    pai_cleanup(NearCat, [cat38-CatVec, dog38-DogVec, fish38-FishVec], Nearest),
    Nearest == cat38.

%  AC-PR38-007: vsa_embed_compound produces vector of correct dimension
test(compound_dimension, [setup(pr38_setup)]) :-
    vsa_embed_compound(foo38(x38, y38), Vec),
    length(Vec, Dim),
    vsa:vsa_dim(Dim).

%  AC-PR38-008: switching algebra changes bind behavior
test(algebra_switch, [setup(pr38_setup)]) :-
    vsa_embed(role38, R),
    vsa_embed(filler38, F),
    vsa_set_algebra(map),
    pai_bind(R, F, BoundMap),
    vsa_set_algebra(hrr),
    pai_bind(R, F, BoundHRR),
    % MAP and HRR produce different bound vectors for non-trivial inputs
    vsa_cosine(BoundMap, BoundHRR, Sim),
    Sim < 0.99.  % they differ (unless very small dimension by coincidence)

%  AC-PR38-009: vsa_role_vector is deterministic and same dimension
test(role_vector_consistent, [setup(pr38_setup)]) :-
    vsa_role_vector(1, RV1a),
    vsa_role_vector(1, RV1b),
    vsa_role_vector(2, RV2),
    RV1a == RV1b,       % deterministic
    RV1a \== RV2,       % different roles → different vectors
    length(RV1a, D),
    length(RV2, D).     % same dimension

:- end_tests(pr38).
