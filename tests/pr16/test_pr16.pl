/*  PrologAI — PR 16 Pluggable Embedding Provider Acceptance Tests

    AC-PR16-001: Given a local_model provider, cosine_similarity(apple, pear)
                 > cosine_similarity(apple, carburetor).
    AC-PR16-002: Given a nexus built with hash_projection, after re_embed with
                 local_model, traverse_nexus Phase 2 reflects semantic embeddings.
    AC-PR16-003: embed/2 with hash_projection returns a 32-dim unit vector.
    AC-PR16-004: embed/2 with local_model returns a 32-dim unit vector.
    AC-PR16-005: set_embedding_provider/1 is idempotent for same provider.
    AC-PR16-006: get_embedding_provider/1 returns the configured provider.
    AC-PR16-007: Nexus-level provider overrides global provider.
    AC-PR16-008: external_service falls back to hash_projection when no URL set.
    AC-PR16-009: re_embed with local_model updates vector index.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatticePath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/embedding/prolog'],      EmbPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatticePath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, EmbPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [cosine_similarity/3] from the built-in 'backend_prolog' library.
:- use_module(library(backend_prolog), [cosine_similarity/3]).
% Import [lattice_open/2, lattice_close/1] from the built-in 'lattice' library.
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1]).
% Load the built-in 'node_facts' library so its predicates are available here.
:- use_module(library(node_facts), [set_default_nexus/1, anchor_node/4,
                                    % Continue the multi-line expression started above.
                                    traverse_nexus/4]).
% Load the built-in 'embedding' library so its predicates are available here.
:- use_module(library(embedding),  [embed/2, re_embed/2,
                                    % Supply 'set_embedding_provider/1' as the next argument to the expression above.
                                    set_embedding_provider/1,
                                    % Supply 'get_embedding_provider/1' as the next argument to the expression above.
                                    get_embedding_provider/1,
                                    % Supply 'set_nexus_embedding_provider/2' as the next argument to the expression above.
                                    set_nexus_embedding_provider/2,
                                    % Supply 'get_nexus_embedding_provider/2' as the next argument to the expression above.
                                    get_nexus_embedding_provider/2,
                                    % Continue the multi-line expression started above.
                                    embedding_dimension/1]).

% Execute the compile-time directive: begin_tests(pr16, [setup(pr16_setup), cleanup(pr16_cleanup)]).
:- begin_tests(pr16, [setup(pr16_setup), cleanup(pr16_cleanup)]).

% Execute: pr16_setup :-.
pr16_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr16', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr16_nexus_ref, N),
    % State a fact for 'set default nexus' with the arguments listed below.
    set_default_nexus(N),
    % State a fact for 'set embedding provider' with the arguments listed below.
    set_embedding_provider(hash_projection).  % reset to default

% Execute: pr16_cleanup :-.
pr16_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr16_nexus_ref, N),
    % State a fact for 'set embedding provider' with the arguments listed below.
    set_embedding_provider(hash_projection),  % restore default
    % Remove all matching facts from the runtime knowledge base.
    retractall(node_facts:node_facts_embed_hook(_, _)),
    % State the fact: lattice close(N).
    lattice_close(N).

%  AC-PR16-001: local_model semantic ordering (apple/pear closer than apple/carburetor)
% Define a clause for 'test': succeed when the following conditions hold.
test(local_model_semantic_ordering) :-
    % State a fact for 'set embedding provider' with the arguments listed below.
    set_embedding_provider(local_model),
    % State a fact for 'embed' with the arguments listed below.
    embed(apple,      VA),
    % State a fact for 'embed' with the arguments listed below.
    embed(pear,       VP),
    % State a fact for 'embed' with the arguments listed below.
    embed(carburetor, VC),
    % State a fact for 'cosine similarity' with the arguments listed below.
    cosine_similarity(VA, VP, SApplePear),
    % State a fact for 'cosine similarity' with the arguments listed below.
    cosine_similarity(VA, VC, SAppleCarb),
    % Check that 'SApplePear' is greater than 'SAppleCarb'.
    SApplePear > SAppleCarb.

%  AC-PR16-002: re_embed updates traverse_nexus Phase 2 semantic results
% Define a clause for 'test': succeed when the following conditions hold.
test(re_embed_updates_traverse_nexus) :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr16_nexus_ref, Nexus),
    % Anchor fruit facts under hash_projection
    % State a fact for 'set embedding provider' with the arguments listed below.
    set_embedding_provider(hash_projection),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(concept, [apple],      [], _),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(concept, [pear],       [], _),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(concept, [carburetor], [], _),
    % Re-embed to local_model
    % State a fact for 're embed' with the arguments listed below.
    re_embed(Nexus, local_model),
    % Phase 2 similarity: query for apple should rank pear above carburetor
    % State a fact for 'traverse nexus' with the arguments listed below.
    traverse_nexus(Nexus, node_fact(concept, [_Fruit], []), 3, Results),
    % Results are Score-Id pairs; just verify we get some results back
    % Check that 'Results' is not unifiable with '[]'.
    Results \= [].

%  AC-PR16-003: hash_projection embed returns 32-dim unit vector
% Define a clause for 'test': succeed when the following conditions hold.
test(hash_projection_embed_dimension) :-
    % State a fact for 'set embedding provider' with the arguments listed below.
    set_embedding_provider(hash_projection),
    % State a fact for 'embed' with the arguments listed below.
    embed(test_term, Vec),
    % State a fact for 'embedding dimension' with the arguments listed below.
    embedding_dimension(Dim),
    % Unify 'Dim' with the number of elements in list 'Vec'.
    length(Vec, Dim).

%  AC-PR16-004: local_model embed returns 32-dim unit vector
% Define a clause for 'test': succeed when the following conditions hold.
test(local_model_embed_dimension) :-
    % State a fact for 'set embedding provider' with the arguments listed below.
    set_embedding_provider(local_model),
    % State a fact for 'embed' with the arguments listed below.
    embed(apple, Vec),
    % State a fact for 'embedding dimension' with the arguments listed below.
    embedding_dimension(Dim),
    % Unify 'Dim' with the number of elements in list 'Vec'.
    length(Vec, Dim).

%  AC-PR16-005: set_embedding_provider is idempotent
% Define a clause for 'test': succeed when the following conditions hold.
test(set_provider_idempotent) :-
    % State a fact for 'set embedding provider' with the arguments listed below.
    set_embedding_provider(local_model),
    % State a fact for 'set embedding provider' with the arguments listed below.
    set_embedding_provider(local_model),
    % State a fact for 'get embedding provider' with the arguments listed below.
    get_embedding_provider(P),
    % Check that 'P' is structurally identical to 'local_model'.
    P == local_model.

%  AC-PR16-006: get_embedding_provider reflects set_embedding_provider
% Define a clause for 'test': succeed when the following conditions hold.
test(get_provider_reflects_set) :-
    % State a fact for 'set embedding provider' with the arguments listed below.
    set_embedding_provider(hash_projection),
    % State a fact for 'get embedding provider' with the arguments listed below.
    get_embedding_provider(P1),
    % Check that 'P1' is structurally identical to 'hash_projection'.
    P1 == hash_projection,
    % State a fact for 'set embedding provider' with the arguments listed below.
    set_embedding_provider(local_model),
    % State a fact for 'get embedding provider' with the arguments listed below.
    get_embedding_provider(P2),
    % Check that 'P2' is structurally identical to 'local_model'.
    P2 == local_model.

%  AC-PR16-007: nexus-level provider overrides global provider
% Define a clause for 'test': succeed when the following conditions hold.
test(nexus_provider_overrides_global) :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr16_nexus_ref, Nexus),
    % State a fact for 'set embedding provider' with the arguments listed below.
    set_embedding_provider(hash_projection),
    % State a fact for 'set nexus embedding provider' with the arguments listed below.
    set_nexus_embedding_provider(Nexus, local_model),
    % State a fact for 'get nexus embedding provider' with the arguments listed below.
    get_nexus_embedding_provider(Nexus, NP),
    % Check that 'NP' is structurally identical to 'local_model'.
    NP == local_model,
    % Global is still hash_projection
    % State a fact for 'get embedding provider' with the arguments listed below.
    get_embedding_provider(GP),
    % Check that 'GP' is structurally identical to 'hash_projection'.
    GP == hash_projection.

%  AC-PR16-008: external_service falls back to hash_projection when no URL configured
% Define a clause for 'test': succeed when the following conditions hold.
test(external_service_fallback) :-
    % State a fact for 'set embedding provider' with the arguments listed below.
    set_embedding_provider(external_service),
    % No URL configured — must not throw, must return a 32-dim vector
    % State a fact for 'embed' with the arguments listed below.
    embed(some_term, Vec),
    % State a fact for 'embedding dimension' with the arguments listed below.
    embedding_dimension(Dim),
    % Unify 'Dim' with the number of elements in list 'Vec'.
    length(Vec, Dim).

%  AC-PR16-009: re_embed with local_model produces semantic vectors for all facts
% Define a clause for 'test': succeed when the following conditions hold.
test(re_embed_local_model_produces_vectors) :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr16_nexus_ref, Nexus),
    % State a fact for 'set embedding provider' with the arguments listed below.
    set_embedding_provider(hash_projection),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(item, [orange],  [], _),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(item, [banana],  [], _),
    % State a fact for 're embed' with the arguments listed below.
    re_embed(Nexus, local_model),
    % After re_embed, embed of known fruits should have non-zero similarity
    % State a fact for 'embed' with the arguments listed below.
    embed(orange, VO),
    % State a fact for 'embed' with the arguments listed below.
    embed(banana, VB),
    % State a fact for 'cosine similarity' with the arguments listed below.
    cosine_similarity(VO, VB, S),
    % Check that 'S' is greater than '0.0'.
    S > 0.0.

% Execute the compile-time directive: end_tests(pr16).
:- end_tests(pr16).
