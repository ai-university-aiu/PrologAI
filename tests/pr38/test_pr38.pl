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

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/vsa/prolog'], VSAPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VSAPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'vsa' library so its predicates are available here.
:- use_module(library(vsa), [
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

% Execute the compile-time directive: begin_tests(pr38, [setup(pr38_setup), cleanup(pr38_cleanup)]).
:- begin_tests(pr38, [setup(pr38_setup), cleanup(pr38_cleanup)]).

% Execute: pr38_setup :-.
pr38_setup :-
    % Execute: vsa:retractall(vsa:vsa_active_algebra(_)),.
    vsa:retractall(vsa:vsa_active_algebra(_)),
    % Execute: vsa:retractall(vsa:vsa_dim(_)),.
    vsa:retractall(vsa:vsa_dim(_)),
    % Execute: vsa:assertz(vsa:vsa_active_algebra(map)),.
    vsa:assertz(vsa:vsa_active_algebra(map)),
    % Execute: vsa:assertz(vsa:vsa_dim(64))..
    vsa:assertz(vsa:vsa_dim(64)).

% Execute: pr38_cleanup :-.
pr38_cleanup :-
    % Execute: vsa:retractall(vsa:vsa_active_algebra(_)),.
    vsa:retractall(vsa:vsa_active_algebra(_)),
    % Execute: vsa:retractall(vsa:vsa_dim(_)),.
    vsa:retractall(vsa:vsa_dim(_)),
    % Execute: vsa:assertz(vsa:vsa_active_algebra(map)),.
    vsa:assertz(vsa:vsa_active_algebra(map)),
    % Execute: vsa:assertz(vsa:vsa_dim(64))..
    vsa:assertz(vsa:vsa_dim(64)).

%  AC-PR38-001: whole-structure vectors differ; unbinding OBJECT returns book
% Define a clause for 'test': succeed when the following conditions hold.
test(compound_embedding_and_unbind, [setup(pr38_setup)]) :-
    % State a fact for 'vsa embed compound' with the arguments listed below.
    vsa_embed_compound(give(alice, book, bob), V1),
    % State a fact for 'vsa embed compound' with the arguments listed below.
    vsa_embed_compound(give(bob,   book, alice), V2),
    % Whole-structure vectors differ substantially
    % State a fact for 'vsa cosine' with the arguments listed below.
    vsa_cosine(V1, V2, Sim),
    % Check that 'Sim' is less than '0.95'.
    Sim < 0.95,
    % Unbind position 2 (OBJECT = arg 2) from each compound
    % State a fact for 'vsa role vector' with the arguments listed below.
    vsa_role_vector(2, Role2),
    % State a fact for 'pai unbind' with the arguments listed below.
    pai_unbind(V1, Role2, U1),
    % State a fact for 'pai unbind' with the arguments listed below.
    pai_unbind(V2, Role2, U2),
    % Build a lexicon of all atoms involved
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(alice, AliceVec),
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(book,  BookVec),
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(bob,   BobVec),
    % Check that 'Lexicon' is unifiable with '[alice-AliceVec, book-BookVec, bob-BobVec]'.
    Lexicon = [alice-AliceVec, book-BookVec, bob-BobVec],
    % State a fact for 'pai cleanup' with the arguments listed below.
    pai_cleanup(U1, Lexicon, Nearest1),
    % State a fact for 'pai cleanup' with the arguments listed below.
    pai_cleanup(U2, Lexicon, Nearest2),
    % Check that 'Nearest1' is structurally identical to 'book'.
    Nearest1 == book,
    % Check that 'Nearest2' is structurally identical to 'book'.
    Nearest2 == book.

%  AC-PR38-002: bind/unbind round-trip under MAP algebra
% Define a clause for 'test': succeed when the following conditions hold.
test(map_bind_unbind_roundtrip, [setup(pr38_setup)]) :-
    % State a fact for 'vsa set algebra' with the arguments listed below.
    vsa_set_algebra(map),
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(agent_role, RoleVec),
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(alice, FillerVec),
    % State a fact for 'pai bind' with the arguments listed below.
    pai_bind(RoleVec, FillerVec, Bound),
    % State a fact for 'pai unbind' with the arguments listed below.
    pai_unbind(Bound, RoleVec, Recovered),
    % State a fact for 'vsa cosine' with the arguments listed below.
    vsa_cosine(Recovered, FillerVec, Sim),
    % Check that 'Sim' is greater than '0.99'.
    Sim > 0.99.

%  AC-PR38-003: bind/unbind round-trip under HRR algebra (approximate recovery)
% Define a clause for 'test': succeed when the following conditions hold.
test(hrr_bind_unbind_roundtrip, [setup(pr38_setup)]) :-
    % State a fact for 'vsa set algebra' with the arguments listed below.
    vsa_set_algebra(hrr),
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(agent_role, RoleVec),
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(alice, FillerVec),
    % State a fact for 'pai bind' with the arguments listed below.
    pai_bind(RoleVec, FillerVec, Bound),
    % State a fact for 'pai unbind' with the arguments listed below.
    pai_unbind(Bound, RoleVec, Recovered),
    % State a fact for 'vsa cosine' with the arguments listed below.
    vsa_cosine(Recovered, FillerVec, Sim),
    % HRR with bipolar ±1 vectors is approximate; random noise ≈ 0
    % Check that 'Sim' is greater than '0.50'.
    Sim > 0.50.

%  AC-PR38-004: pai_bundle produces a normalized vector
% Define a clause for 'test': succeed when the following conditions hold.
test(bundle_is_normalized, [setup(pr38_setup)]) :-
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(a38, VA),
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(b38, VB),
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(c38, VC),
    % State a fact for 'pai bundle' with the arguments listed below.
    pai_bundle([VA, VB, VC], Bundled),
    % State a fact for 'foldl' with the arguments listed below.
    foldl([X, Acc, NAcc]>>(NAcc is Acc + X*X), Bundled, 0.0, SumSq),
    % Evaluate the arithmetic expression 'sqrt(SumSq)' and bind the result to 'Mag'.
    Mag is sqrt(SumSq),
    % Check that 'abs(Mag - 1.0)' is less than '1.0e-9'.
    abs(Mag - 1.0) < 1.0e-9.

%  AC-PR38-005: vsa_embed is deterministic
% Define a clause for 'test': succeed when the following conditions hold.
test(embed_deterministic, [setup(pr38_setup)]) :-
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(some_atom_38, V1),
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(some_atom_38, V2),
    % Check that 'V1' is structurally identical to 'V2'.
    V1 == V2.

%  AC-PR38-006: pai_cleanup returns nearest lexicon item
% Define a clause for 'test': succeed when the following conditions hold.
test(cleanup_nearest, [setup(pr38_setup)]) :-
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(cat38, CatVec),
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(dog38, DogVec),
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(fish38, FishVec),
    % Query close to cat
    % State a fact for 'pai bundle' with the arguments listed below.
    pai_bundle([CatVec, CatVec, CatVec], NearCat),
    % State a fact for 'pai cleanup' with the arguments listed below.
    pai_cleanup(NearCat, [cat38-CatVec, dog38-DogVec, fish38-FishVec], Nearest),
    % Check that 'Nearest' is structurally identical to 'cat38'.
    Nearest == cat38.

%  AC-PR38-007: vsa_embed_compound produces vector of correct dimension
% Define a clause for 'test': succeed when the following conditions hold.
test(compound_dimension, [setup(pr38_setup)]) :-
    % State a fact for 'vsa embed compound' with the arguments listed below.
    vsa_embed_compound(foo38(x38, y38), Vec),
    % Unify 'Dim' with the number of elements in list 'Vec'.
    length(Vec, Dim),
    % Execute: vsa:vsa_dim(Dim)..
    vsa:vsa_dim(Dim).

%  AC-PR38-008: switching algebra changes bind behavior
% Define a clause for 'test': succeed when the following conditions hold.
test(algebra_switch, [setup(pr38_setup)]) :-
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(role38, R),
    % State a fact for 'vsa embed' with the arguments listed below.
    vsa_embed(filler38, F),
    % State a fact for 'vsa set algebra' with the arguments listed below.
    vsa_set_algebra(map),
    % State a fact for 'pai bind' with the arguments listed below.
    pai_bind(R, F, BoundMap),
    % State a fact for 'vsa set algebra' with the arguments listed below.
    vsa_set_algebra(hrr),
    % State a fact for 'pai bind' with the arguments listed below.
    pai_bind(R, F, BoundHRR),
    % MAP and HRR produce different bound vectors for non-trivial inputs
    % State a fact for 'vsa cosine' with the arguments listed below.
    vsa_cosine(BoundMap, BoundHRR, Sim),
    % Check that 'Sim' is less than '0.99.  % they differ (unless very small dimension by coincidence)'.
    Sim < 0.99.  % they differ (unless very small dimension by coincidence)

%  AC-PR38-009: vsa_role_vector is deterministic and same dimension
% Define a clause for 'test': succeed when the following conditions hold.
test(role_vector_consistent, [setup(pr38_setup)]) :-
    % State a fact for 'vsa role vector' with the arguments listed below.
    vsa_role_vector(1, RV1a),
    % State a fact for 'vsa role vector' with the arguments listed below.
    vsa_role_vector(1, RV1b),
    % State a fact for 'vsa role vector' with the arguments listed below.
    vsa_role_vector(2, RV2),
    % Check that 'RV1a' is structurally identical to 'RV1b,       % deterministic'.
    RV1a == RV1b,       % deterministic
    % Check that 'RV1a' is structurally not identical to 'RV2,       % different roles → different vectors'.
    RV1a \== RV2,       % different roles → different vectors
    % Unify 'D' with the number of elements in list 'RV1a'.
    length(RV1a, D),
    % Unify 'D' with the number of elements in list 'RV2'.
    length(RV2, D).     % same dimension

% Execute the compile-time directive: end_tests(pr38).
:- end_tests(pr38).
