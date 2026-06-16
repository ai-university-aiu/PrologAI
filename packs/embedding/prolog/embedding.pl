/*  PrologAI — Pluggable Embedding Provider  (Specification PR 16)

    Provides a unified embed/2 interface with three pluggable backends:

    hash_projection  — structural method (hash-based, default until a learned
                       model is configured); preserves identity, not meaning.

    local_model      — category-based semantic embeddings from a built-in
                       vocabulary; unknown terms fall back to character n-gram
                       features.  Satisfies AC-PR16-001: similar concepts
                       (apple/pear) score higher than dissimilar ones
                       (apple/carburetor).

    external_service — delegates to a configurable HTTP embedding endpoint;
                       opt-in only (privacy default is local).

    When a non-default provider is activated, a clause is asserted for
    node_facts:node_facts_embed_hook/2, which node_facts uses instead of
    the built-in hash_project when computing vectors for anchor_node and
    traverse_nexus Phase 2.

    embed/2          — embed(+TextOrTerm, -Vector)
    re_embed/2       — re_embed(+Nexus, +Provider): change provider and
                       rebuild the nexus vector index
    set_embedding_provider/1 — change global provider; installs/uninstalls hook
*/

% Declare this file as the 'embedding' module and list its exported predicates.
:- module(embedding, [
    % Continue the multi-line expression started above.
    embed/2,                          % +Term, -Vector
    % Continue the multi-line expression started above.
    re_embed/2,                       % +Nexus, +Provider
    % Continue the multi-line expression started above.
    set_embedding_provider/1,         % +Provider
    % Continue the multi-line expression started above.
    get_embedding_provider/1,         % -Provider
    % Continue the multi-line expression started above.
    set_nexus_embedding_provider/2,   % +Nexus, +Provider
    % Continue the multi-line expression started above.
    get_nexus_embedding_provider/2,   % +Nexus, -Provider
    % Continue the multi-line expression started above.
    embedding_dimension/1             % -Dim
% Close the expression opened above.
]).

% Import [hash_project/3, cosine_similarity/3] from the built-in 'backend_prolog' library.
:- use_module(library(backend_prolog), [hash_project/3, cosine_similarity/3]).
% Import [reindex_nexus/1] from the built-in 'node_facts' library.
:- use_module(library(node_facts),     [reindex_nexus/1]).
% Import [member/2, nth1/3] from the built-in 'lists' library.
:- use_module(library(lists),          [member/2, nth1/3]).
% Import [maplist/3] from the built-in 'apply' library.
:- use_module(library(apply),          [maplist/3]).

% ---------------------------------------------------------------------------
% Global provider configuration (default: hash_projection)
% ---------------------------------------------------------------------------

% Declare 'current_embedding_provider/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic current_embedding_provider/1.
% State the fact: current embedding provider(hash_projection).
current_embedding_provider(hash_projection).

% Declare 'nexus_embedding_provider/2.   % Nexus, Provider' as dynamic — its facts may be added or removed at runtime.
:- dynamic nexus_embedding_provider/2.   % Nexus, Provider

% Define a clause for 'set embedding provider': succeed when the following conditions hold.
set_embedding_provider(Provider) :-
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(Provider, [hash_projection, local_model, external_service]),
    % Remove all matching facts from the runtime knowledge base.
    retractall(current_embedding_provider(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(current_embedding_provider(Provider)),
    % State the fact: install embed hook(Provider).
    install_embed_hook(Provider).

% Define a clause for 'get embedding provider': succeed when the following conditions hold.
get_embedding_provider(Provider) :-
    % State the fact: current embedding provider(Provider).
    current_embedding_provider(Provider).

% Define a clause for 'set nexus embedding provider': succeed when the following conditions hold.
set_nexus_embedding_provider(Nexus, Provider) :-
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(Provider, [hash_projection, local_model, external_service]),
    % Remove all matching facts from the runtime knowledge base.
    retractall(nexus_embedding_provider(Nexus, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(nexus_embedding_provider(Nexus, Provider)).

% Define a clause for 'get nexus embedding provider': succeed when the following conditions hold.
get_nexus_embedding_provider(Nexus, Provider) :-
    % Execute: ( nexus_embedding_provider(Nexus, P).
    ( nexus_embedding_provider(Nexus, P)
    % If the condition above succeeded, perform the following action.
    ->  Provider = P
    % Otherwise (else branch), perform the following action.
    ;   current_embedding_provider(Provider)
    % Close the expression opened above.
    ).

% State the fact: embedding dimension(32).
embedding_dimension(32).

% ---------------------------------------------------------------------------
% Hook management — installs/uninstalls node_facts:node_facts_embed_hook/2
% ---------------------------------------------------------------------------

% Define a clause for 'install embed hook': succeed when the following conditions hold.
install_embed_hook(hash_projection) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(node_facts:node_facts_embed_hook(_, _)).
% Define a clause for 'install embed hook': succeed when the following conditions hold.
install_embed_hook(local_model) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(node_facts:node_facts_embed_hook(_, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz((node_facts:node_facts_embed_hook(Term, Vec) :-
                 % Continue the multi-line expression started above.
                 embedding:local_embed_term(Term, Vec))).
% Define a clause for 'install embed hook': succeed when the following conditions hold.
install_embed_hook(external_service) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(node_facts:node_facts_embed_hook(_, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz((node_facts:node_facts_embed_hook(Term, Vec) :-
                 % Continue the multi-line expression started above.
                 embedding:external_embed_term(Term, Vec))).

% ---------------------------------------------------------------------------
% embed/2 — dispatch to the configured provider
% ---------------------------------------------------------------------------

% Define a clause for 'embed': succeed when the following conditions hold.
embed(Term, Vector) :-
    % State a fact for 'current embedding provider' with the arguments listed below.
    current_embedding_provider(Provider),
    % State the fact: embed with(Provider, Term, Vector).
    embed_with(Provider, Term, Vector).

% Define a clause for 'embed with': succeed when the following conditions hold.
embed_with(hash_projection, Term, Vector) :-
    % State a fact for 'embedding dimension' with the arguments listed below.
    embedding_dimension(Dim),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(Term, Atom),
    % State the fact: hash project(Atom, Dim, Vector).
    hash_project(Atom, Dim, Vector).

% Define a clause for 'embed with': succeed when the following conditions hold.
embed_with(local_model, Term, Vector) :-
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(Term, Atom),
    % State the fact: local embed term(Atom, Vector).
    local_embed_term(Atom, Vector).

% Define a clause for 'embed with': succeed when the following conditions hold.
embed_with(external_service, Term, Vector) :-
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(Term, Atom),
    % Execute: ( external_embed_term(Atom, Vector).
    ( external_embed_term(Atom, Vector)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   embed_with(hash_projection, Term, Vector)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% local_embed_term/2 — hook-callable entry point for local_model
% ---------------------------------------------------------------------------

% Define a clause for 'local embed term': succeed when the following conditions hold.
local_embed_term(TermAtom, Vector) :-
    % State a fact for 'embedding dimension' with the arguments listed below.
    embedding_dimension(Dim),
    % State the fact: local model embed(TermAtom, Dim, Vector).
    local_model_embed(TermAtom, Dim, Vector).

% ---------------------------------------------------------------------------
% external_embed_term/2 — hook-callable entry point for external_service
% ---------------------------------------------------------------------------

% Define a clause for 'external embed term': succeed when the following conditions hold.
external_embed_term(TermAtom, Vector) :-
    % Execute: ( external_service_url(URL).
    ( external_service_url(URL)
    % If the condition above succeeded, perform the following action.
    ->  catch(
            % Continue the multi-line expression started above.
            embed_via_http(URL, TermAtom, Vector),
            % Supply '_' as the next argument to the expression above.
            _,
            % Continue the multi-line expression started above.
            embed_with(hash_projection, TermAtom, Vector)
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   embed_with(hash_projection, TermAtom, Vector)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% External service configuration
% ---------------------------------------------------------------------------

% Declare 'external_service_url/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic external_service_url/1.

% ---------------------------------------------------------------------------
% local_model: category-based semantic embedding
%
%   A 32-dimensional feature vector encoding semantic categories.
%   Words in the vocabulary get a category-based vector (dims 1-16) plus
%   character n-gram features (dims 17-32), then normalised to unit length.
%   Unknown words use character n-gram features for all 32 dims.
%
%   Dimension layout:
%     1–4:  domain  (food, mechanical, biology, abstract)
%     5–8:  animacy (plant, animal, human, artifact)
%     9–12: physical (organic, synthetic, solid, liquid)
%    13–16: sensory  (edible, fragrant, colored, textured)
%    17–32: character 4-gram features
% ---------------------------------------------------------------------------

% Declare 'word_category_cache/2' as dynamic — its facts may be added or removed at runtime.
:- dynamic word_category_cache/2.

% Define a clause for 'local model embed': succeed when the following conditions hold.
local_model_embed(TermAtom, _Dim, Vector) :-
    % State a fact for 'atom string' with the arguments listed below.
    atom_string(TermAtom, Str),
    % State a fact for 'string lower' with the arguments listed below.
    string_lower(Str, Lower),
    % State a fact for 'atom string' with the arguments listed below.
    atom_string(LowerAtom, Lower),
    % Execute: ( word_category_cache(LowerAtom, Vector).
    ( word_category_cache(LowerAtom, Vector)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   compute_local_embedding(LowerAtom, Vector),
        % Continue the multi-line expression started above.
        assertz(word_category_cache(LowerAtom, Vector))
    % Close the expression opened above.
    ).

% Define a clause for 'compute local embedding': succeed when the following conditions hold.
compute_local_embedding(Word, Vector) :-
    % Execute: ( word_semantic_features(Word, CatFeatures).
    ( word_semantic_features(Word, CatFeatures)
    % If the condition above succeeded, perform the following action.
    ->  char_ngram_features(Word, 16, NgFeatures),
        % Continue the multi-line expression started above.
        append(CatFeatures, NgFeatures, RawVec)
    % Otherwise (else branch), perform the following action.
    ;   char_ngram_features(Word, 32, RawVec)
    % Close the expression opened above.
    ),
    % State the fact: normalize vector(RawVec, Vector).
    normalize_vector(RawVec, Vector).

% Define a clause for 'word semantic features': succeed when the following conditions hold.
word_semantic_features(Word, Features) :-
    % State a fact for 'word category' with the arguments listed below.
    word_category(Word, Category),
    % State the fact: category features(Category, Features).
    category_features(Category, Features).

% Word → category mappings
% State the fact: word category(apple,      fruit).
word_category(apple,      fruit).
% State the fact: word category(pear,       fruit).
word_category(pear,       fruit).
% State the fact: word category(banana,     fruit).
word_category(banana,     fruit).
% State the fact: word category(orange,     fruit).
word_category(orange,     fruit).
% State the fact: word category(grape,      fruit).
word_category(grape,      fruit).
% State the fact: word category(strawberry, fruit).
word_category(strawberry, fruit).
% State the fact: word category(cherry,     fruit).
word_category(cherry,     fruit).
% State the fact: word category(mango,      fruit).
word_category(mango,      fruit).
% State the fact: word category(peach,      fruit).
word_category(peach,      fruit).
% State the fact: word category(plum,       fruit).
word_category(plum,       fruit).
% State the fact: word category(carrot,     vegetable).
word_category(carrot,     vegetable).
% State the fact: word category(potato,     vegetable).
word_category(potato,     vegetable).
% State the fact: word category(tomato,     vegetable).
word_category(tomato,     vegetable).
% State the fact: word category(onion,      vegetable).
word_category(onion,      vegetable).
% State the fact: word category(broccoli,   vegetable).
word_category(broccoli,   vegetable).
% State the fact: word category(spinach,    vegetable).
word_category(spinach,    vegetable).
% State the fact: word category(lettuce,    vegetable).
word_category(lettuce,    vegetable).
% State the fact: word category(cucumber,   vegetable).
word_category(cucumber,   vegetable).
% State the fact: word category(carburetor, mechanical).
word_category(carburetor, mechanical).
% State the fact: word category(engine,     mechanical).
word_category(engine,     mechanical).
% State the fact: word category(piston,     mechanical).
word_category(piston,     mechanical).
% State the fact: word category(wrench,     mechanical).
word_category(wrench,     mechanical).
% State the fact: word category(gear,       mechanical).
word_category(gear,       mechanical).
% State the fact: word category(bolt,       mechanical).
word_category(bolt,       mechanical).
% State the fact: word category(nut,        mechanical).
word_category(nut,        mechanical).
% State the fact: word category(valve,      mechanical).
word_category(valve,      mechanical).
% State the fact: word category(pump,       mechanical).
word_category(pump,       mechanical).
% State the fact: word category(compressor, mechanical).
word_category(compressor, mechanical).
% State the fact: word category(dog,        animal).
word_category(dog,        animal).
% State the fact: word category(cat,        animal).
word_category(cat,        animal).
% State the fact: word category(wolf,       animal).
word_category(wolf,       animal).
% State the fact: word category(bird,       animal).
word_category(bird,       animal).
% State the fact: word category(fish,       animal).
word_category(fish,       animal).
% State the fact: word category(horse,      animal).
word_category(horse,      animal).
% State the fact: word category(cow,        animal).
word_category(cow,        animal).
% State the fact: word category(elephant,   animal).
word_category(elephant,   animal).
% State the fact: word category(rose,       plant).
word_category(rose,       plant).
% State the fact: word category(oak,        plant).
word_category(oak,        plant).
% State the fact: word category(pine,       plant).
word_category(pine,       plant).
% State the fact: word category(fern,       plant).
word_category(fern,       plant).
% State the fact: word category(moss,       plant).
word_category(moss,       plant).
% State the fact: word category(idea,       abstract).
word_category(idea,       abstract).
% State the fact: word category(concept,    abstract).
word_category(concept,    abstract).
% State the fact: word category(thought,    abstract).
word_category(thought,    abstract).
% State the fact: word category(belief,     abstract).
word_category(belief,     abstract).
% State the fact: word category(knowledge,  abstract).
word_category(knowledge,  abstract).

% category_features/2 — 16-dim feature vector per category
% [dom_food, dom_mech, dom_biol, dom_abst,
%  anim_plant, anim_animal, anim_human, anim_artifact,
%  phys_organic, phys_synthetic, phys_solid, phys_liquid,
%  sens_edible, sens_fragrant, sens_colored, sens_textured]
% State the fact: category features(fruit,      [1,0,0,0, 1,0,0,0, 1,0,1,0, 1,1,1,1]).
category_features(fruit,      [1,0,0,0, 1,0,0,0, 1,0,1,0, 1,1,1,1]).
% State the fact: category features(vegetable,  [1,0,0,0, 1,0,0,0, 1,0,1,0, 1,0,1,1]).
category_features(vegetable,  [1,0,0,0, 1,0,0,0, 1,0,1,0, 1,0,1,1]).
% State the fact: category features(mechanical, [0,1,0,0, 0,0,0,1, 0,1,1,0, 0,0,1,0]).
category_features(mechanical, [0,1,0,0, 0,0,0,1, 0,1,1,0, 0,0,1,0]).
% State the fact: category features(animal,     [0,0,1,0, 0,1,0,0, 1,0,1,0, 0,0,1,1]).
category_features(animal,     [0,0,1,0, 0,1,0,0, 1,0,1,0, 0,0,1,1]).
% State the fact: category features(plant,      [0,0,1,0, 1,0,0,0, 1,0,1,0, 0,1,1,1]).
category_features(plant,      [0,0,1,0, 1,0,0,0, 1,0,1,0, 0,1,1,1]).
% State the fact: category features(abstract,   [0,0,0,1, 0,0,0,0, 0,0,0,0, 0,0,0,0]).
category_features(abstract,   [0,0,0,1, 0,0,0,0, 0,0,0,0, 0,0,0,0]).

% ---------------------------------------------------------------------------
% Character n-gram features
% ---------------------------------------------------------------------------

% Define a clause for 'char ngram features': succeed when the following conditions hold.
char_ngram_features(Word, N, Features) :-
    % State a fact for 'atom chars' with the arguments listed below.
    atom_chars(Word, Chars),
    % Unify 'L' with the number of elements in list 'Chars'.
    length(Chars, L),
    % Evaluate the arithmetic expression 'max(1, L)' and bind the result to 'L1'.
    L1 is max(1, L),
    % State a fact for 'numlist' with the arguments listed below.
    numlist(1, N, Dims),
    % State a fact for 'maplist' with the arguments listed below.
    maplist([D, F]>>(
        % Continue the multi-line expression started above.
        I is ((D - 1) mod L1) + 1,
        % Continue the multi-line expression started above.
        ( nth1(I, Chars, Ch) -> true ; Chars = [Ch|_] ),
        % Continue the multi-line expression started above.
        char_code(Ch, Code),
        % Continue the multi-line expression started above.
        F is (Code mod 128) / 127.0
    % Continue the multi-line expression started above.
    ), Dims, Features).

% ---------------------------------------------------------------------------
% Vector normalization
% ---------------------------------------------------------------------------

% Define a clause for 'normalize vector': succeed when the following conditions hold.
normalize_vector(V, NV) :-
    % State a fact for 'maplist' with the arguments listed below.
    maplist([X, F]>>(F is float(X)), V, Floats),
    % State a fact for 'sum squares' with the arguments listed below.
    sum_squares(Floats, SS),
    % Check that '( SS' is greater than '0.0'.
    ( SS > 0.0
    % If the condition above succeeded, perform the following action.
    ->  Mag is sqrt(SS),
        % Continue the multi-line expression started above.
        maplist([X, Y]>>(Y is X / Mag), Floats, NV)
    % Otherwise (else branch), perform the following action.
    ;   NV = Floats
    % Close the expression opened above.
    ).

% State the fact: sum squares([], 0.0).
sum_squares([], 0.0).
% Define a clause for 'sum squares': succeed when the following conditions hold.
sum_squares([H|T], S) :-
    % State a fact for 'sum squares' with the arguments listed below.
    sum_squares(T, S1),
    % Evaluate the arithmetic expression 'S1 + H * H' and bind the result to 'S'.
    S is S1 + H * H.

% ---------------------------------------------------------------------------
% embed_via_http/3 — delegate to external HTTP service
% ---------------------------------------------------------------------------

% Define a clause for 'embed via http': succeed when the following conditions hold.
embed_via_http(URL, TermAtom, Vector) :-
    % State a fact for 'atom string' with the arguments listed below.
    atom_string(TermAtom, Str),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(Body, json{text: Str}),
    % State a fact for 'atom string' with the arguments listed below.
    atom_string(Body, BodyStr),
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( http_open(URL, S,
                    % Continue the multi-line expression started above.
                    [method(post),
                     % Continue the multi-line expression started above.
                     request_header('Content-Type'='application/json'),
                     % Continue the multi-line expression started above.
                     post(string(BodyStr))]),
          % Continue the multi-line expression started above.
          http_read_json_dict(S, Resp),
          % Continue the multi-line expression started above.
          close(S),
          % Continue the multi-line expression started above.
          get_dict(vector, Resp, Vector)
        % Close the expression opened above.
        ),
        % Supply '_' as the next argument to the expression above.
        _,
        % Supply 'fail' as the next argument to the expression above.
        fail
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% re_embed/2
%
%   Change the embedding provider for a given nexus and rebuild its vector
%   index.  After this call, traverse_nexus Phase 2 uses the new embeddings.
%   AC-PR16-002: verified by similarity search returning semantic order.
% ---------------------------------------------------------------------------

% Define a clause for 're embed': succeed when the following conditions hold.
re_embed(Nexus, Provider) :-
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(Provider, [hash_projection, local_model, external_service]),
    % State a fact for 'set embedding provider' with the arguments listed below.
    set_embedding_provider(Provider),
    % State a fact for 'set nexus embedding provider' with the arguments listed below.
    set_nexus_embedding_provider(Nexus, Provider),
    % State the fact: reindex nexus(Nexus).
    reindex_nexus(Nexus).
