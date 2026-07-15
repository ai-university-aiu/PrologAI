/*  PrologAI — Compositional Vector Binding (VSA) In-Pack Test Suite  (PR 38)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/vector_symbolic_architecture/test/test_vector_symbolic_architecture.pl
*/

% Declare this file as a test module.
:- module(test_vector_symbolic_architecture, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(vector_symbolic_architecture)).

% Open the test block for vector_symbolic_architecture.
:- begin_tests(vector_symbolic_architecture).

% AC-VSA-001: embedding a term is deterministic — same term yields the same vector.
test(embed_deterministic) :-
    % Embed an atom once.
    vector_symbolic_architecture_embed(some_atom_vsa, V1),
    % Embed the same atom a second time.
    vector_symbolic_architecture_embed(some_atom_vsa, V2),
    % The two vectors are structurally identical.
    assertion(V1 == V2).

% AC-VSA-002: role vectors are deterministic and share one dimension across positions.
test(role_vector_consistent) :-
    % Build the role vector for position one.
    vector_symbolic_architecture_role_vector(1, RV1a),
    % Build the role vector for position one again.
    vector_symbolic_architecture_role_vector(1, RV1b),
    % Build the role vector for position two.
    vector_symbolic_architecture_role_vector(2, RV2),
    % Repeated construction of the same role is deterministic.
    assertion(RV1a == RV1b),
    % Different positions yield different role vectors.
    assertion(RV1a \== RV2),
    % Measure the length of the position-one role vector.
    length(RV1a, D),
    % The position-two role vector has the same dimension.
    assertion(length(RV2, D)).

% AC-VSA-003: bind then unbind recovers the filler almost exactly under MAP algebra.
test(map_bind_unbind_roundtrip) :-
    % Select the multiply-accumulate-permute algebra.
    vector_symbolic_architecture_set_algebra(map),
    % Embed a role vector.
    vector_symbolic_architecture_embed(agent_role, RoleVec),
    % Embed a filler vector.
    vector_symbolic_architecture_embed(alice, FillerVec),
    % Bind the filler to the role.
    vector_symbolic_architecture_bind(RoleVec, FillerVec, Bound),
    % Unbind the role to recover the filler.
    vector_symbolic_architecture_unbind(Bound, RoleVec, Recovered),
    % Compare the recovered vector to the original filler.
    vector_symbolic_architecture_cosine(Recovered, FillerVec, Sim),
    % MAP binding is self-inverse for bipolar roles, so recovery is near exact.
    assertion(Sim > 0.99).

% AC-VSA-004: bind then unbind approximately recovers the filler under HRR algebra.
test(hrr_bind_unbind_roundtrip) :-
    % Select the holographic-reduced-representations algebra.
    vector_symbolic_architecture_set_algebra(hrr),
    % Embed a role vector.
    vector_symbolic_architecture_embed(agent_role, RoleVec),
    % Embed a filler vector.
    vector_symbolic_architecture_embed(alice, FillerVec),
    % Bind the filler to the role by circular convolution.
    vector_symbolic_architecture_bind(RoleVec, FillerVec, Bound),
    % Unbind via the conjugate-reversal inverse of the role.
    vector_symbolic_architecture_unbind(Bound, RoleVec, Recovered),
    % Compare the recovered vector to the original filler.
    vector_symbolic_architecture_cosine(Recovered, FillerVec, Sim),
    % HRR recovery is approximate but well above the near-zero noise floor.
    assertion(Sim > 0.50),
    % Restore the default MAP algebra for later tests.
    vector_symbolic_architecture_set_algebra(map).

% AC-VSA-005: bundling produces a unit-length (normalized) vector.
test(bundle_is_normalized) :-
    % Embed three distinct atoms.
    vector_symbolic_architecture_embed(a_vsa, VA),
    % Embed the second atom.
    vector_symbolic_architecture_embed(b_vsa, VB),
    % Embed the third atom.
    vector_symbolic_architecture_embed(c_vsa, VC),
    % Superpose the three vectors and normalize the sum.
    vector_symbolic_architecture_bundle([VA, VB, VC], Bundled),
    % Sum the squares of the bundled components.
    foldl([X, Acc, NAcc]>>(NAcc is Acc + X*X), Bundled, 0.0, SumSq),
    % Take the square root to get the magnitude.
    Mag is sqrt(SumSq),
    % The bundled vector has unit magnitude.
    assertion(abs(Mag - 1.0) < 1.0e-9).

% AC-VSA-006: cleanup returns the lexicon id whose vector is nearest the query.
test(cleanup_nearest) :-
    % Embed a cat vector.
    vector_symbolic_architecture_embed(cat_vsa, CatVec),
    % Embed a dog vector.
    vector_symbolic_architecture_embed(dog_vsa, DogVec),
    % Embed a fish vector.
    vector_symbolic_architecture_embed(fish_vsa, FishVec),
    % Build a query strongly biased toward the cat vector.
    vector_symbolic_architecture_bundle([CatVec, CatVec, CatVec], NearCat),
    % Clean the query up against the three-item lexicon.
    vector_symbolic_architecture_cleanup(NearCat, [cat_vsa-CatVec, dog_vsa-DogVec, fish_vsa-FishVec], Nearest),
    % The nearest lexicon id is the cat.
    assertion(Nearest == cat_vsa).

% AC-VSA-007: compositional embedding differs by argument order, yet unbinding a role recovers the filler.
test(compound_embedding_and_unbind) :-
    % Use the self-inverse MAP algebra for exact role recovery.
    vector_symbolic_architecture_set_algebra(map),
    % Embed the give-alice-book-bob structure.
    vector_symbolic_architecture_embed_compound(give(alice, book, bob), V1),
    % Embed the give-bob-book-alice structure.
    vector_symbolic_architecture_embed_compound(give(bob, book, alice), V2),
    % The whole-structure vectors differ substantially.
    vector_symbolic_architecture_cosine(V1, V2, Sim),
    % Their similarity is below the near-identical threshold.
    assertion(Sim < 0.95),
    % Build the role vector for the object position (argument two).
    vector_symbolic_architecture_role_vector(2, Role2),
    % Unbind the object role from the first structure.
    vector_symbolic_architecture_unbind(V1, Role2, U1),
    % Unbind the object role from the second structure.
    vector_symbolic_architecture_unbind(V2, Role2, U2),
    % Embed each atom to form the cleanup lexicon.
    vector_symbolic_architecture_embed(alice, AliceVec),
    % Embed the book atom.
    vector_symbolic_architecture_embed(book, BookVec),
    % Embed the bob atom.
    vector_symbolic_architecture_embed(bob, BobVec),
    % Assemble the lexicon of candidate fillers.
    Lexicon = [alice-AliceVec, book-BookVec, bob-BobVec],
    % Clean up the recovered object from the first structure.
    vector_symbolic_architecture_cleanup(U1, Lexicon, Nearest1),
    % Clean up the recovered object from the second structure.
    vector_symbolic_architecture_cleanup(U2, Lexicon, Nearest2),
    % Both recovered objects resolve to book.
    assertion(Nearest1 == book),
    % The second recovered object also resolves to book.
    assertion(Nearest2 == book).

% Close the test block for vector_symbolic_architecture.
:- end_tests(vector_symbolic_architecture).
