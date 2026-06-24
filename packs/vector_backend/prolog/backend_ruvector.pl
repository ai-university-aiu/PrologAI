/*  PrologAI — RuVector HTTP Backend (PR 2, update)

    Implements the six-predicate vector-backend interface by calling the
    RuVector (https://github.com/ruvnet/ruvector) HTTP REST server.

    RuVector provides HNSW (Hierarchical Navigable Small World) indexing
    with SIMD (Single Instruction, Multiple Data) acceleration and a
    self-learning GNN (Graph Neural Network) reranking layer.

    Start the RuVector server before using this backend:
        bash packs/vector_backend/scripts/ruvector_server.sh
    or, if you have the ruvector-server binary:
        ruvector-server --port 8080

    Then register and run the bakeoff:
        ?- vb_set_backend(ruvector).
        ?- run_bakeoff([prolog, ruvector], [100, 1000]).

    HTTP API used (ruvector-server, port 8080 by default):
        POST   /collections                      — create collection
        POST   /collections/{name}/vectors       — insert vector
        POST   /collections/{name}/search        — k-NN search
        DELETE /collections/{name}/vectors/{id}  — delete vector
        DELETE /collections/{name}               — drop collection (close)

    Predicate naming: vbr_* (vector backend ruvector).
*/

% Declare this file as the 'backend_ruvector' module and list its exported predicates.
:- module(backend_ruvector, [
    % Supply 'vbr_create/4' as the next argument to the expression above.
    vbr_create/4,           % +Name, +Dim, +Opts, -Ref
    % Supply 'vbr_insert/4' as the next argument to the expression above.
    vbr_insert/4,           % +Ref, +Id, +Vec, +Meta
    % Supply 'vbr_search/4' as the next argument to the expression above.
    vbr_search/4,           % +Ref, +QueryVec, +K, -Results
    % Supply 'vbr_delete/2' as the next argument to the expression above.
    vbr_delete/2,           % +Ref, +Id
    % Supply 'vbr_update_weights/3' as the next argument to the expression above.
    vbr_update_weights/3,   % +Ref, +Id, +Delta  (no-op: RuVector manages its own weights)
    % Supply 'vbr_close/1' as the next argument to the expression above.
    vbr_close/1             % +Ref  (drops the collection from the server)
% Close the expression opened above.
]).

% Import [http_post/4, http_open/3] from the HTTP client library.
:- use_module(library(http/http_client), [http_post/4, http_open/3]).
% Import [atom_json_dict/3] from the JSON library.
:- use_module(library(http/json),        [atom_json_dict/3, json_read_dict/2]).
% Import [atomic_list_concat/2, atomic_list_concat/3] from the built-in library.
:- use_module(library(lists),            [member/2]).

% ---------------------------------------------------------------------------
% Configuration
% ---------------------------------------------------------------------------

% Declare 'ruvector_base_url/1' as dynamic so callers can override the server address.
:- dynamic ruvector_base_url/1.
% Default: RuVector server at localhost port 8080.
ruvector_base_url('http://localhost:8080').

% ---------------------------------------------------------------------------
% vbr_create/4
% Create a collection on the RuVector server and return a Ref term.
% Ref = rv_ref(CollectionName, BaseUrl)
% ---------------------------------------------------------------------------

% Define a clause for 'vbr create': POST /collections to create a new index.
vbr_create(Name, Dim, _Opts, Ref) :-
    % Retrieve the configured server base URL.
    ruvector_base_url(BaseUrl),
    % Build the collections endpoint URL.
    atomic_list_concat([BaseUrl, '/collections'], Url),
    % Convert the index name to a string suitable for JSON.
    term_to_atom(Name, NameAtom),
    % Build the JSON request body as a Prolog dict.
    Body = _{name: NameAtom, dimensions: Dim, distance_metric: "cosine"},
    % Encode the dict to a JSON atom.
    atom_json_dict(BodyAtom, Body, []),
    % POST the JSON body to the collections endpoint; ignore the response body.
    catch(
        http_post(Url, atom('application/json', BodyAtom), _Reply, []),
        _,
        true
    ),
    % Bind the Ref term to carry both the collection name and the server URL.
    Ref = rv_ref(NameAtom, BaseUrl).

% ---------------------------------------------------------------------------
% vbr_insert/4
% Insert one vector into the RuVector collection.
% ---------------------------------------------------------------------------

% Define a clause for 'vbr insert': POST /collections/{name}/vectors.
vbr_insert(rv_ref(CollName, BaseUrl), Id, Vec, Meta) :-
    % Build the vector insertion endpoint URL.
    atomic_list_concat([BaseUrl, '/collections/', CollName, '/vectors'], Url),
    % Convert the numeric or atom Id to a string.
    term_to_atom(Id, IdAtom),
    % Convert the Prolog float list to a JSON-encodable list.
    maplist(vbr_coerce_float, Vec, FloatVec),
    % Convert the metadata term to a string for JSON storage.
    term_to_atom(Meta, MetaAtom),
    % Build the JSON insertion body.
    Body = _{id: IdAtom, vector: FloatVec, metadata: _{prologai_meta: MetaAtom}},
    % Encode the body to a JSON atom.
    atom_json_dict(BodyAtom, Body, []),
    % POST the vector to the server; ignore the response.
    catch(
        http_post(Url, atom('application/json', BodyAtom), _Reply, []),
        _,
        true
    ).

% Define a clause for 'vbr coerce float': ensure a number is a float.
vbr_coerce_float(N, F) :-
    % Evaluate the arithmetic expression 'float(N)' and bind the result to 'F'.
    F is float(N).

% ---------------------------------------------------------------------------
% vbr_search/4
% Search for the K nearest neighbours of QueryVec.
% Returns Results as a list of result(Id, Score) terms.
% ---------------------------------------------------------------------------

% Define a clause for 'vbr search': POST /collections/{name}/search.
vbr_search(rv_ref(CollName, BaseUrl), QueryVec, K, Results) :-
    % Build the search endpoint URL.
    atomic_list_concat([BaseUrl, '/collections/', CollName, '/search'], Url),
    % Coerce the query vector elements to floats.
    maplist(vbr_coerce_float, QueryVec, FloatVec),
    % Build the JSON search body.
    Body = _{vector: FloatVec, k: K},
    % Encode the body to a JSON atom.
    atom_json_dict(BodyAtom, Body, []),
    % POST the search query and capture the raw response text.
    catch(
        (   http_post(Url, atom('application/json', BodyAtom), ReplyAtom, []),
            % Parse the JSON response dict.
            atom_json_dict(ReplyAtom, ReplyDict, []),
            % Extract the results list from the response dict.
            ResultsList = ReplyDict.results,
            % Convert each result dict to a PrologAI result/2 term.
            maplist(vbr_parse_result, ResultsList, Results)
        ),
        _,
        % On any error, return an empty result list.
        Results = []
    ).

% Define a clause for 'vbr parse result': convert a RuVector result dict to result(Id, Score).
vbr_parse_result(RDict, result(Id, Score)) :-
    % Extract the id field from the result dict.
    atom_string(Id, RDict.id),
    % Extract the score field from the result dict.
    Score = RDict.score.

% ---------------------------------------------------------------------------
% vbr_delete/2
% Remove one vector from the collection by Id.
% ---------------------------------------------------------------------------

% Define a clause for 'vbr delete': DELETE /collections/{name}/vectors/{id}.
vbr_delete(rv_ref(CollName, BaseUrl), Id) :-
    % Convert the Id to an atom for URL embedding.
    term_to_atom(Id, IdAtom),
    % Build the deletion endpoint URL.
    atomic_list_concat([BaseUrl, '/collections/', CollName, '/vectors/', IdAtom], Url),
    % Open the URL with the DELETE method; close the stream immediately.
    catch(
        (   http_open(Url, Stream, [method(delete)]),
            close(Stream)
        ),
        _,
        true
    ).

% ---------------------------------------------------------------------------
% vbr_update_weights/3
% RuVector manages its own GNN-learned edge weights automatically.
% This predicate is a deliberate no-op: the backend self-improves on each
% query without requiring external weight adjustments.
% ---------------------------------------------------------------------------

% Define a clause for 'vbr update weights': no-op — RuVector is self-learning.
vbr_update_weights(_Ref, _Id, _Delta) :- true.

% ---------------------------------------------------------------------------
% vbr_close/1
% Drop the collection from the RuVector server (frees server-side memory).
% ---------------------------------------------------------------------------

% Define a clause for 'vbr close': DELETE /collections/{name}.
vbr_close(rv_ref(CollName, BaseUrl)) :-
    % Build the collection deletion endpoint URL.
    atomic_list_concat([BaseUrl, '/collections/', CollName], Url),
    % Send a DELETE request to drop the collection; ignore errors.
    catch(
        (   http_open(Url, Stream, [method(delete)]),
            close(Stream)
        ),
        _,
        true
    ).
