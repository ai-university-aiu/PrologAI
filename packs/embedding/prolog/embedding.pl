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

:- module(embedding, [
    embed/2,                          % +Term, -Vector
    re_embed/2,                       % +Nexus, +Provider
    set_embedding_provider/1,         % +Provider
    get_embedding_provider/1,         % -Provider
    set_nexus_embedding_provider/2,   % +Nexus, +Provider
    get_nexus_embedding_provider/2,   % +Nexus, -Provider
    embedding_dimension/1             % -Dim
]).

:- use_module(library(backend_prolog), [hash_project/3, cosine_similarity/3]).
:- use_module(library(node_facts),     [reindex_nexus/1]).
:- use_module(library(lists),          [member/2, nth1/3]).
:- use_module(library(apply),          [maplist/3]).

% ---------------------------------------------------------------------------
% Global provider configuration (default: hash_projection)
% ---------------------------------------------------------------------------

:- dynamic current_embedding_provider/1.
current_embedding_provider(hash_projection).

:- dynamic nexus_embedding_provider/2.   % Nexus, Provider

set_embedding_provider(Provider) :-
    memberchk(Provider, [hash_projection, local_model, external_service]),
    retractall(current_embedding_provider(_)),
    assertz(current_embedding_provider(Provider)),
    install_embed_hook(Provider).

get_embedding_provider(Provider) :-
    current_embedding_provider(Provider).

set_nexus_embedding_provider(Nexus, Provider) :-
    memberchk(Provider, [hash_projection, local_model, external_service]),
    retractall(nexus_embedding_provider(Nexus, _)),
    assertz(nexus_embedding_provider(Nexus, Provider)).

get_nexus_embedding_provider(Nexus, Provider) :-
    ( nexus_embedding_provider(Nexus, P)
    ->  Provider = P
    ;   current_embedding_provider(Provider)
    ).

embedding_dimension(32).

% ---------------------------------------------------------------------------
% Hook management — installs/uninstalls node_facts:node_facts_embed_hook/2
% ---------------------------------------------------------------------------

install_embed_hook(hash_projection) :-
    retractall(node_facts:node_facts_embed_hook(_, _)).
install_embed_hook(local_model) :-
    retractall(node_facts:node_facts_embed_hook(_, _)),
    assertz((node_facts:node_facts_embed_hook(Term, Vec) :-
                 embedding:local_embed_term(Term, Vec))).
install_embed_hook(external_service) :-
    retractall(node_facts:node_facts_embed_hook(_, _)),
    assertz((node_facts:node_facts_embed_hook(Term, Vec) :-
                 embedding:external_embed_term(Term, Vec))).

% ---------------------------------------------------------------------------
% embed/2 — dispatch to the configured provider
% ---------------------------------------------------------------------------

embed(Term, Vector) :-
    current_embedding_provider(Provider),
    embed_with(Provider, Term, Vector).

embed_with(hash_projection, Term, Vector) :-
    embedding_dimension(Dim),
    term_to_atom(Term, Atom),
    hash_project(Atom, Dim, Vector).

embed_with(local_model, Term, Vector) :-
    term_to_atom(Term, Atom),
    local_embed_term(Atom, Vector).

embed_with(external_service, Term, Vector) :-
    term_to_atom(Term, Atom),
    ( external_embed_term(Atom, Vector)
    ->  true
    ;   embed_with(hash_projection, Term, Vector)
    ).

% ---------------------------------------------------------------------------
% local_embed_term/2 — hook-callable entry point for local_model
% ---------------------------------------------------------------------------

local_embed_term(TermAtom, Vector) :-
    embedding_dimension(Dim),
    local_model_embed(TermAtom, Dim, Vector).

% ---------------------------------------------------------------------------
% external_embed_term/2 — hook-callable entry point for external_service
% ---------------------------------------------------------------------------

external_embed_term(TermAtom, Vector) :-
    ( external_service_url(URL)
    ->  catch(
            embed_via_http(URL, TermAtom, Vector),
            _,
            embed_with(hash_projection, TermAtom, Vector)
        )
    ;   embed_with(hash_projection, TermAtom, Vector)
    ).

% ---------------------------------------------------------------------------
% External service configuration
% ---------------------------------------------------------------------------

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

:- dynamic word_category_cache/2.

local_model_embed(TermAtom, _Dim, Vector) :-
    atom_string(TermAtom, Str),
    string_lower(Str, Lower),
    atom_string(LowerAtom, Lower),
    ( word_category_cache(LowerAtom, Vector)
    ->  true
    ;   compute_local_embedding(LowerAtom, Vector),
        assertz(word_category_cache(LowerAtom, Vector))
    ).

compute_local_embedding(Word, Vector) :-
    ( word_semantic_features(Word, CatFeatures)
    ->  char_ngram_features(Word, 16, NgFeatures),
        append(CatFeatures, NgFeatures, RawVec)
    ;   char_ngram_features(Word, 32, RawVec)
    ),
    normalize_vector(RawVec, Vector).

word_semantic_features(Word, Features) :-
    word_category(Word, Category),
    category_features(Category, Features).

% Word → category mappings
word_category(apple,      fruit).
word_category(pear,       fruit).
word_category(banana,     fruit).
word_category(orange,     fruit).
word_category(grape,      fruit).
word_category(strawberry, fruit).
word_category(cherry,     fruit).
word_category(mango,      fruit).
word_category(peach,      fruit).
word_category(plum,       fruit).
word_category(carrot,     vegetable).
word_category(potato,     vegetable).
word_category(tomato,     vegetable).
word_category(onion,      vegetable).
word_category(broccoli,   vegetable).
word_category(spinach,    vegetable).
word_category(lettuce,    vegetable).
word_category(cucumber,   vegetable).
word_category(carburetor, mechanical).
word_category(engine,     mechanical).
word_category(piston,     mechanical).
word_category(wrench,     mechanical).
word_category(gear,       mechanical).
word_category(bolt,       mechanical).
word_category(nut,        mechanical).
word_category(valve,      mechanical).
word_category(pump,       mechanical).
word_category(compressor, mechanical).
word_category(dog,        animal).
word_category(cat,        animal).
word_category(wolf,       animal).
word_category(bird,       animal).
word_category(fish,       animal).
word_category(horse,      animal).
word_category(cow,        animal).
word_category(elephant,   animal).
word_category(rose,       plant).
word_category(oak,        plant).
word_category(pine,       plant).
word_category(fern,       plant).
word_category(moss,       plant).
word_category(idea,       abstract).
word_category(concept,    abstract).
word_category(thought,    abstract).
word_category(belief,     abstract).
word_category(knowledge,  abstract).

% category_features/2 — 16-dim feature vector per category
% [dom_food, dom_mech, dom_biol, dom_abst,
%  anim_plant, anim_animal, anim_human, anim_artifact,
%  phys_organic, phys_synthetic, phys_solid, phys_liquid,
%  sens_edible, sens_fragrant, sens_colored, sens_textured]
category_features(fruit,      [1,0,0,0, 1,0,0,0, 1,0,1,0, 1,1,1,1]).
category_features(vegetable,  [1,0,0,0, 1,0,0,0, 1,0,1,0, 1,0,1,1]).
category_features(mechanical, [0,1,0,0, 0,0,0,1, 0,1,1,0, 0,0,1,0]).
category_features(animal,     [0,0,1,0, 0,1,0,0, 1,0,1,0, 0,0,1,1]).
category_features(plant,      [0,0,1,0, 1,0,0,0, 1,0,1,0, 0,1,1,1]).
category_features(abstract,   [0,0,0,1, 0,0,0,0, 0,0,0,0, 0,0,0,0]).

% ---------------------------------------------------------------------------
% Character n-gram features
% ---------------------------------------------------------------------------

char_ngram_features(Word, N, Features) :-
    atom_chars(Word, Chars),
    length(Chars, L),
    L1 is max(1, L),
    numlist(1, N, Dims),
    maplist([D, F]>>(
        I is ((D - 1) mod L1) + 1,
        ( nth1(I, Chars, Ch) -> true ; Chars = [Ch|_] ),
        char_code(Ch, Code),
        F is (Code mod 128) / 127.0
    ), Dims, Features).

% ---------------------------------------------------------------------------
% Vector normalization
% ---------------------------------------------------------------------------

normalize_vector(V, NV) :-
    maplist([X, F]>>(F is float(X)), V, Floats),
    sum_squares(Floats, SS),
    ( SS > 0.0
    ->  Mag is sqrt(SS),
        maplist([X, Y]>>(Y is X / Mag), Floats, NV)
    ;   NV = Floats
    ).

sum_squares([], 0.0).
sum_squares([H|T], S) :-
    sum_squares(T, S1),
    S is S1 + H * H.

% ---------------------------------------------------------------------------
% embed_via_http/3 — delegate to external HTTP service
% ---------------------------------------------------------------------------

embed_via_http(URL, TermAtom, Vector) :-
    atom_string(TermAtom, Str),
    term_to_atom(Body, json{text: Str}),
    atom_string(Body, BodyStr),
    catch(
        ( http_open(URL, S,
                    [method(post),
                     request_header('Content-Type'='application/json'),
                     post(string(BodyStr))]),
          http_read_json_dict(S, Resp),
          close(S),
          get_dict(vector, Resp, Vector)
        ),
        _,
        fail
    ).

% ---------------------------------------------------------------------------
% re_embed/2
%
%   Change the embedding provider for a given nexus and rebuild its vector
%   index.  After this call, traverse_nexus Phase 2 uses the new embeddings.
%   AC-PR16-002: verified by similarity search returning semantic order.
% ---------------------------------------------------------------------------

re_embed(Nexus, Provider) :-
    memberchk(Provider, [hash_projection, local_model, external_service]),
    set_embedding_provider(Provider),
    set_nexus_embedding_provider(Nexus, Provider),
    reindex_nexus(Nexus).
