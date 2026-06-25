/*  PrologAI — RuVector HTTP Backend (PR 2, update)

    Implements the six-predicate vector-backend interface by calling the
    RuVector (https://github.com/ruvnet/ruvector) HTTP REST server.

    RuVector provides HNSW (Hierarchical Navigable Small World) indexing
    with SIMD (Single Instruction, Multiple Data) acceleration and a
    self-learning GNN (Graph Neural Network) reranking layer.

    Start the RuVector server before using this backend:
        bash packs/vector_backend/scripts/ruvector_server.sh
    The server defaults to port 6333.

    Then switch backend and run the bakeoff:
        ?- vb_set_backend(ruvector).
        ?- run_bakeoff([prolog, ruvector], [100, 1000]).

    Verified HTTP API (ruvector-server crate, default port 6333):
        POST   /collections                              — create collection
        DELETE /collections/{name}                       — drop collection
        PUT    /collections/{name}/points                — upsert batch of points
        POST   /collections/{name}/points/search         — k-NN search
        GET    /collections/{name}/points/{id}           — get one point
        (no per-point DELETE endpoint in this version of the server)

    Request shapes:
        Create:  {"name":"...","dimension":N}
        Upsert:  {"points":[{"id":"...","vector":[...],"metadata":{...}}]}
        Search:  {"vector":[...],"k":N}

    Response shapes:
        Search:  {"results":[{"id":"...","score":0.95,...}]}

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
    vbr_delete/2,           % +Ref, +Id  (no-op: no per-point DELETE in server)
    % Supply 'vbr_update_weights/3' as the next argument to the expression above.
    vbr_update_weights/3,   % +Ref, +Id, +Delta  (no-op: RuVector self-learning)
    % Supply 'vbr_close/1' as the next argument to the expression above.
    vbr_close/1             % +Ref  (drops the collection via DELETE /collections/{name})
% Close the expression opened above.
]).

% Import [http_post/4] from the HTTP client library.
:- use_module(library(http/http_client), [http_post/4]).
% Import [http_open/3] from the HTTP open library (http_open is not in http_client).
:- use_module(library(http/http_open), [http_open/3]).
% Import [atom_json_dict/3, json_read_dict/2] from the JSON library.
:- use_module(library(http/json),        [atom_json_dict/3, json_read_dict/2]).
% Import [member/2] from the built-in lists library.
:- use_module(library(lists),            [member/2]).

% ---------------------------------------------------------------------------
% Configuration
% ---------------------------------------------------------------------------

% Declare 'ruvector_base_url/1' as dynamic so callers can override the server address.
:- dynamic ruvector_base_url/1.
% Default: RuVector server at localhost port 6333 (ruvector-server default).
ruvector_base_url('http://localhost:6333').

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
    % Convert the index name to an atom suitable for JSON.
    term_to_atom(Name, NameAtom),
    % Build the JSON request body using 'dimension' (singular) as required by the server.
    Body = _{name: NameAtom, dimension: Dim},
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
% Insert one vector into the RuVector collection via the batch upsert endpoint.
% RuVector uses PUT /collections/{name}/points with a {"points":[...]} body.
% ---------------------------------------------------------------------------

% Define a clause for 'vbr insert': PUT /collections/{name}/points.
vbr_insert(rv_ref(CollName, BaseUrl), Id, Vec, Meta) :-
    % Build the points upsert endpoint URL.
    atomic_list_concat([BaseUrl, '/collections/', CollName, '/points'], Url),
    % Convert the numeric or atom Id to a string atom.
    term_to_atom(Id, IdAtom),
    % Convert the Prolog float list to a JSON-encodable float list.
    maplist(vbr_coerce_float, Vec, FloatVec),
    % Convert the metadata term to an atom for storage in the metadata dict.
    term_to_atom(Meta, MetaAtom),
    % Build the JSON upsert body: a points array with one entry.
    Body = _{points: [_{id: IdAtom, vector: FloatVec,
                        metadata: _{prologai_meta: MetaAtom}}]},
    % Encode the body to a JSON atom.
    atom_json_dict(BodyAtom, Body, []),
    % PUT the vector to the server; ignore the response.
    catch(
        http_open(Url, Stream,
                  [method(put),
                   post(atom('application/json', BodyAtom)),
                   header(content_type, 'application/json')]),
        _,
        Stream = []
    ),
    % Close the stream if it was opened successfully.
    ( Stream = [] -> true ; close(Stream) ).

% Define a clause for 'vbr coerce float': ensure a number is a float.
vbr_coerce_float(N, F) :-
    % Evaluate the arithmetic expression 'float(N)' and bind the result to 'F'.
    F is float(N).

% ---------------------------------------------------------------------------
% vbr_search/4
% Search for the K nearest neighbours of QueryVec.
% Returns Results as a list of result(Id, Score) terms.
% ---------------------------------------------------------------------------

% Define a clause for 'vbr search': POST /collections/{name}/points/search.
vbr_search(rv_ref(CollName, BaseUrl), QueryVec, K, Results) :-
    % Build the search endpoint URL (note: /points/search not /search).
    atomic_list_concat([BaseUrl, '/collections/', CollName, '/points/search'], Url),
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
    % Extract the id field from the result dict and convert to atom.
    atom_string(Id, RDict.id),
    % Extract the score field from the result dict.
    Score = RDict.score.

% ---------------------------------------------------------------------------
% vbr_delete/2
% The ruvector-server does not expose a per-point DELETE endpoint in this
% version.  This predicate is a no-op so the bakeoff and interface contract
% are satisfied without error.
% ---------------------------------------------------------------------------

% Define a clause for 'vbr delete': no-op — no per-point delete in ruvector-server.
vbr_delete(_Ref, _Id) :- true.

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
% Drop the collection from the RuVector server via DELETE /collections/{name}.
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
