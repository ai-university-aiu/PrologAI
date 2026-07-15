/*  PrologAI — Embedding Pack Test Suite  (WP-16 pluggable embedding provider)

    Behavioural acceptance tests for the exported embedding_* interface, modelled
    on the legacy tests/pr16 suite but scoped to the self-contained provider and
    embedding predicates (no lattice/nexus fixture required):

      embed/2, set_embedding_provider/1, get_embedding_provider/1,
      set_nexus_embedding_provider/2, get_nexus_embedding_provider/2,
      embedding_dimension/1.

    The flagship assertion is AC-PR16-001: under local_model, two fruits
    (apple/pear) embed closer than a fruit and a machine part (apple/carburetor).

    Run with the full library path:
        LIB=""; for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/embedding/test/test_embedding.pl
*/

% Declare this file as a test module that exports nothing.
:- module(test_embedding, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(embedding)).
% Load cosine_similarity/3 from the vector backend to score embedding closeness.
:- use_module(library(backend_prolog), [cosine_similarity/3]).

% vector_magnitude(+Vector, -Magnitude): Euclidean length of a numeric vector.
vector_magnitude(Vector, Magnitude) :-
    % Square every component of the vector.
    maplist([X, Y]>>(Y is X * X), Vector, Squares),
    % Sum the squared components.
    sum_list(Squares, SumOfSquares),
    % The magnitude is the square root of that sum.
    Magnitude is sqrt(SumOfSquares).

% Open the embedding test group; reset to the default provider around each test.
:- begin_tests(embedding, [setup(set_embedding_provider(hash_projection)),
                           % Restore the default provider after the group finishes.
                           cleanup(set_embedding_provider(hash_projection))]).

% The advertised embedding width is 32 dimensions.
test(embedding_dimension_is_32) :-
    % Read the configured dimension.
    embedding_dimension(Dim),
    % It must be exactly 32.
    assertion(Dim == 32).

% Under hash_projection, embed/2 returns a vector of the advertised dimension.
test(hash_projection_embed_dimension) :-
    % Select the structural hash provider.
    set_embedding_provider(hash_projection),
    % Embed an arbitrary term.
    embed(some_test_term, Vector),
    % Read the advertised dimension.
    embedding_dimension(Dim),
    % The returned vector has exactly that many components.
    assertion(length(Vector, Dim)).

% Under local_model, embed/2 returns a 32-dimensional unit vector.
test(local_model_embed_is_unit_vector) :-
    % Select the category-based semantic provider.
    set_embedding_provider(local_model),
    % Embed a known vocabulary word.
    embed(apple, Vector),
    % Read the advertised dimension.
    embedding_dimension(Dim),
    % The returned vector has exactly that many components.
    assertion(length(Vector, Dim)),
    % Compute its Euclidean length.
    vector_magnitude(Vector, Magnitude),
    % local_model normalises to unit length, so the magnitude is 1.0.
    assertion(abs(Magnitude - 1.0) < 1.0e-6).

% AC-PR16-001: local_model places two fruits closer than a fruit and a part.
test(local_model_semantic_ordering) :-
    % Select the category-based semantic provider.
    set_embedding_provider(local_model),
    % Embed a fruit.
    embed(apple, VApple),
    % Embed a second fruit.
    embed(pear, VPear),
    % Embed a mechanical part.
    embed(carburetor, VCarburetor),
    % Score the two fruits against each other.
    cosine_similarity(VApple, VPear, FruitFruit),
    % Score the fruit against the part.
    cosine_similarity(VApple, VCarburetor, FruitPart),
    % Same-category concepts must score strictly higher than cross-category ones.
    assertion(FruitFruit > FruitPart).

% get_embedding_provider/1 reflects set_embedding_provider/1, which is idempotent.
test(get_reflects_set_and_idempotent) :-
    % Select the structural hash provider.
    set_embedding_provider(hash_projection),
    % The reader reports it.
    get_embedding_provider(P1),
    % Confirm the reported provider.
    assertion(P1 == hash_projection),
    % Switch to the semantic provider.
    set_embedding_provider(local_model),
    % Setting the same provider again must not change the result.
    set_embedding_provider(local_model),
    % The reader now reports the semantic provider.
    get_embedding_provider(P2),
    % Confirm the switch took effect and is stable under repetition.
    assertion(P2 == local_model).

% A per-nexus provider overrides the global provider without changing it.
test(nexus_provider_overrides_global) :-
    % Fix the global provider to the structural hash.
    set_embedding_provider(hash_projection),
    % Override just one nexus to the semantic provider.
    set_nexus_embedding_provider(nexus_under_test, local_model),
    % Reading that nexus reports its override.
    get_nexus_embedding_provider(nexus_under_test, NexusProvider),
    % Confirm the override is in force for that nexus.
    assertion(NexusProvider == local_model),
    % The global provider is untouched by the nexus-level override.
    get_embedding_provider(GlobalProvider),
    % Confirm the global default still stands.
    assertion(GlobalProvider == hash_projection).

% A nexus with no override falls back to the current global provider.
test(nexus_provider_falls_back_to_global) :-
    % Fix the global provider to the structural hash.
    set_embedding_provider(hash_projection),
    % Query a nexus that was never given its own provider.
    get_nexus_embedding_provider(nexus_with_no_override, Provider),
    % It resolves to the global provider.
    assertion(Provider == hash_projection).

% external_service with no URL configured falls back to a 32-dim vector, no throw.
test(external_service_falls_back_without_url) :-
    % Select the external HTTP provider (no service URL is configured).
    set_embedding_provider(external_service),
    % Embedding must not throw and must still return a vector.
    embed(some_unlisted_term, Vector),
    % Read the advertised dimension.
    embedding_dimension(Dim),
    % The fallback vector has exactly that many components.
    assertion(length(Vector, Dim)).

% Close the embedding test group.
:- end_tests(embedding).
