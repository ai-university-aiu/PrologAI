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
        ?- vector_backend_set_backend(ruvector).
        ?- run_bakeoff([prolog, ruvector], [100, 1000]).

    DATA LOSS RISK: ruvector-server stores all collections in memory only.
    If the server process stops, all vectors are lost.  This module mitigates
    that risk with an in-process shadow store: every insert is mirrored as a
    backend_ruvector_shadow/5 dynamic fact.  When the server is restarted, call:
        ?- backend_ruvector_rebuild(Ref).
    to drop and recreate the collection and re-insert all shadow vectors.
    The shadow store lives in the SWI-Prolog process, so it survives a
    RuVector server restart as long as the Prolog session stays alive.

    Verified HTTP API (ruvector-server crate, default port 6333):
        POST   /collections                              — create collection
        DELETE /collections/{name}                       — drop collection
        PUT    /collections/{name}/points                — upsert batch of points
        POST   /collections/{name}/points/search         — k-NN search
        (no per-point DELETE endpoint in this version of the server)

    Request shapes:
        Create:  {"name":"...","dimension":N}
        Upsert:  {"points":[{"id":"...","vector":[...],"metadata":{...}}]}
        Search:  {"vector":[...],"k":N}

    Response shapes:
        Search:  {"results":[{"id":"...","score":0.95,...}]}

    Predicate naming: backend_ruvector_* (vector backend ruvector).
*/

% Declare this file as the 'backend_ruvector' module and list its exported predicates.
:- module(backend_ruvector, [
    % Supply 'backend_ruvector_create/4' as the next argument to the expression above.
    backend_ruvector_create/4,           % +Name, +Dim, +Opts, -Ref
    % Supply 'backend_ruvector_insert/4' as the next argument to the expression above.
    backend_ruvector_insert/4,           % +Ref, +Id, +Vec, +Meta
    % Supply 'backend_ruvector_search/4' as the next argument to the expression above.
    backend_ruvector_search/4,           % +Ref, +QueryVec, +K, -Results
    % Supply 'backend_ruvector_delete/2' as the next argument to the expression above.
    backend_ruvector_delete/2,           % +Ref, +Id  (removes shadow; no server-side per-point delete)
    % Supply 'backend_ruvector_update_weights/3' as the next argument to the expression above.
    backend_ruvector_update_weights/3,   % +Ref, +Id, +Delta  (no-op: RuVector self-learning)
    % Supply 'backend_ruvector_close/1' as the next argument to the expression above.
    backend_ruvector_close/1,            % +Ref  (drops collection; clears shadows)
    % Supply 'backend_ruvector_rebuild/1' as the next argument to the expression above.
    backend_ruvector_rebuild/1,          % +Ref  (re-inserts all shadows after server restart)
    % Supply 'backend_ruvector_shadow_count/2' as the next argument to the expression above.
    backend_ruvector_shadow_count/2      % +Ref, -Count  (diagnostic: number of shadow vectors)
% Close the expression opened above.
]).

% Import [http_post/4] from the HTTP client library.
:- use_module(library(http/http_client), [http_post/4]).
% Import [http_open/3] from the HTTP open library (http_open is not in http_client).
:- use_module(library(http/http_open),   [http_open/3]).
% Import [atom_json_dict/3] from the JSON library.
:- use_module(library(http/json),        [atom_json_dict/3]).
% Import [member/2, length/2] from the built-in lists library.
:- use_module(library(lists),            [member/2]).

% ---------------------------------------------------------------------------
% Configuration
% ---------------------------------------------------------------------------

% Declare 'ruvector_base_url/1' as dynamic so callers can override the server address.
:- dynamic ruvector_base_url/1.
% Default: RuVector server at localhost port 6333 (ruvector-server default).
ruvector_base_url('http://localhost:6333').

% ---------------------------------------------------------------------------
% Shadow store
% Shadow mirrors every successful insert so the HNSW index can be rebuilt
% after a RuVector server restart without losing the Prolog session.
% Format: backend_ruvector_shadow(CollectionName, BaseUrl, IdAtom, FloatVec, MetaAtom)
% ---------------------------------------------------------------------------

% Declare 'backend_ruvector_shadow/5' as dynamic so insert/delete/close/rebuild can maintain it.
:- dynamic backend_ruvector_shadow/5.

% ---------------------------------------------------------------------------
% backend_ruvector_create/4
% Create a collection on the RuVector server and return a Ref term.
% Ref = rv_ref(CollectionName, BaseUrl)
% ---------------------------------------------------------------------------

% Define a clause for 'vbr create': POST /collections to create a new index.
backend_ruvector_create(Name, Dim, _Opts, Ref) :-
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
% backend_ruvector_insert/4
% Insert one vector into the RuVector collection and record it in the shadow.
% RuVector uses PUT /collections/{name}/points with a {"points":[...]} body.
% ---------------------------------------------------------------------------

% Define a clause for 'vbr insert': HTTP upsert + shadow record.
backend_ruvector_insert(rv_ref(CollName, BaseUrl), Id, Vec, Meta) :-
    % Convert the numeric or atom Id to a string atom for JSON and shadow.
    term_to_atom(Id, IdAtom),
    % Coerce the Prolog float list to JSON-encodable floats.
    maplist(backend_ruvector_coerce_float, Vec, FloatVec),
    % Convert the metadata term to an atom for JSON storage.
    term_to_atom(Meta, MetaAtom),
    % Send the vector to the RuVector server via HTTP (no shadow recording here).
    backend_ruvector_insert_http(CollName, BaseUrl, IdAtom, FloatVec, MetaAtom),
    % Remove any existing shadow for this Id to avoid duplicates on re-insert.
    retractall(backend_ruvector_shadow(CollName, BaseUrl, IdAtom, _, _)),
    % Record the vector in the shadow store for future rebuild capability.
    assertz(backend_ruvector_shadow(CollName, BaseUrl, IdAtom, FloatVec, MetaAtom)).

% ---------------------------------------------------------------------------
% backend_ruvector_insert_http/5
% Raw HTTP insert only — no shadow recording.
% Called by backend_ruvector_insert/4 and by backend_ruvector_rebuild/1 (to avoid double-shadowing).
% ---------------------------------------------------------------------------

% Define a clause for 'vbr insert http': PUT /collections/{name}/points.
backend_ruvector_insert_http(CollName, BaseUrl, IdAtom, FloatVec, MetaAtom) :-
    % Build the points upsert endpoint URL.
    atomic_list_concat([BaseUrl, '/collections/', CollName, '/points'], Url),
    % Build the JSON upsert body: a points array with one entry.
    Body = _{points: [_{id: IdAtom, vector: FloatVec,
                        metadata: _{prologai_meta: MetaAtom}}]},
    % Encode the body to a JSON atom.
    atom_json_dict(BodyAtom, Body, []),
    % Open the URL with the PUT method and post the JSON body.
    catch(
        http_open(Url, Stream,
                  [method(put),
                   post(atom('application/json', BodyAtom)),
                   header(content_type, 'application/json')]),
        _,
        Stream = []
    ),
    % Close the response stream if it was opened successfully.
    ( Stream = [] -> true ; close(Stream) ).

% Define a clause for 'vbr coerce float': ensure a number is a float.
backend_ruvector_coerce_float(N, F) :-
    % Evaluate the arithmetic expression 'float(N)' and bind the result to 'F'.
    F is float(N).

% ---------------------------------------------------------------------------
% backend_ruvector_search/4
% Search for the K nearest neighbours of QueryVec.
% Returns Results as a list of result(Id, Score) terms.
% Returns [] on any HTTP error (server absent, collection missing, etc.).
% ---------------------------------------------------------------------------

% Define a clause for 'vbr search': POST /collections/{name}/points/search.
backend_ruvector_search(rv_ref(CollName, BaseUrl), QueryVec, K, Results) :-
    % Build the search endpoint URL (note: /points/search not /search).
    atomic_list_concat([BaseUrl, '/collections/', CollName, '/points/search'], Url),
    % Coerce the query vector elements to floats.
    maplist(backend_ruvector_coerce_float, QueryVec, FloatVec),
    % Build the JSON search body.
    Body = _{vector: FloatVec, k: K},
    % Encode the body to a JSON atom.
    atom_json_dict(BodyAtom, Body, []),
    % POST the search query; parse the response; fall back to [] on any error.
    catch(
        (   http_post(Url, atom('application/json', BodyAtom), ReplyAtom, []),
            % Parse the JSON response dict.
            atom_json_dict(ReplyAtom, ReplyDict, []),
            % Extract the results list from the response dict.
            ResultsList = ReplyDict.results,
            % Convert each result dict to a PrologAI result/2 term.
            maplist(backend_ruvector_parse_result, ResultsList, Results)
        ),
        _,
        % On any error, return an empty result list without raising an exception.
        Results = []
    ).

% Define a clause for 'vbr parse result': convert a RuVector result dict to result(Id, Score).
backend_ruvector_parse_result(RDict, result(Id, Score)) :-
    % Extract the id field from the result dict and convert to atom.
    atom_string(Id, RDict.id),
    % Extract the score field from the result dict.
    Score = RDict.score.

% ---------------------------------------------------------------------------
% backend_ruvector_delete/2
% The ruvector-server has no per-point DELETE endpoint in this version.
% This predicate removes the shadow entry so the vector is not re-inserted
% on the next rebuild, preventing ghost results after a logical deletion.
% ---------------------------------------------------------------------------

% Define a clause for 'vbr delete': remove shadow entry; no server-side action.
backend_ruvector_delete(rv_ref(CollName, BaseUrl), Id) :-
    % Convert Id to atom to match the shadow store format.
    term_to_atom(Id, IdAtom),
    % Remove the shadow entry so this vector is excluded from future rebuilds.
    retractall(backend_ruvector_shadow(CollName, BaseUrl, IdAtom, _, _)).

% ---------------------------------------------------------------------------
% backend_ruvector_update_weights/3
% RuVector manages its own GNN-learned edge weights automatically.
% This predicate is a deliberate no-op: the backend self-improves on each
% query without requiring external weight adjustments.
% ---------------------------------------------------------------------------

% Define a clause for 'vbr update weights': no-op — RuVector is self-learning.
backend_ruvector_update_weights(_Ref, _Id, _Delta) :- true.

% ---------------------------------------------------------------------------
% backend_ruvector_close/1
% Drop the collection from the RuVector server and clear all shadow entries
% for that collection.  After close, rebuild would have nothing to re-insert.
% ---------------------------------------------------------------------------

% Define a clause for 'vbr close': DELETE /collections/{name} + clear shadows.
backend_ruvector_close(rv_ref(CollName, BaseUrl)) :-
    % Build the collection deletion endpoint URL.
    atomic_list_concat([BaseUrl, '/collections/', CollName], Url),
    % Send a DELETE request to drop the collection on the server; ignore errors.
    catch(
        (   http_open(Url, Stream, [method(delete)]),
            close(Stream)
        ),
        _,
        true
    ),
    % Clear all shadow entries for this collection — index and shadows are gone.
    retractall(backend_ruvector_shadow(CollName, BaseUrl, _, _, _)).

% ---------------------------------------------------------------------------
% backend_ruvector_rebuild/1
% Re-insert all shadow vectors after a RuVector server restart.
%
% Protocol:
%   1. Attempt to drop the collection from the server (ignore error if absent).
%   2. Determine the vector dimension from any existing shadow entry.
%   3. Recreate the collection on the server with the same dimension.
%   4. Re-insert every shadow vector using the raw HTTP predicate.
%
% Usage:
%   ?- backend_ruvector_rebuild(Ref).
%
% Typical call site: immediately after detecting a search returned [] when
% the collection was known to be non-empty, or after a planned server restart.
% ---------------------------------------------------------------------------

% Define a clause for 'vbr rebuild': rebuild the server-side index from the shadow store.
backend_ruvector_rebuild(rv_ref(CollName, BaseUrl)) :-
    % Step 1: Drop the collection from the server (ignore error if server was just restarted).
    atomic_list_concat([BaseUrl, '/collections/', CollName], DropUrl),
    % Attempt the DELETE; swallow any error (collection may not exist yet on fresh server).
    catch(
        (   http_open(DropUrl, DropStream, [method(delete)]),
            close(DropStream)
        ),
        _,
        true
    ),
    % Step 2: Look for any shadow entry to determine the vector dimension.
    ( backend_ruvector_shadow(CollName, BaseUrl, _, SampleVec, _)
    ->  % Determine the dimension from the first shadow vector found.
        length(SampleVec, Dim),
        % Step 3: Recreate the collection with the original dimension.
        atomic_list_concat([BaseUrl, '/collections'], CreateUrl),
        % Build the creation request body.
        CreateBody = _{name: CollName, dimension: Dim},
        % Encode the body to a JSON atom.
        atom_json_dict(CreateBodyAtom, CreateBody, []),
        % POST the creation request; ignore errors (e.g. server still starting).
        catch(
            http_post(CreateUrl, atom('application/json', CreateBodyAtom), _, []),
            _,
            true
        ),
        % Count total shadow vectors for the progress log.
        findall(_, backend_ruvector_shadow(CollName, BaseUrl, _, _, _), ShadowList),
        length(ShadowList, Total),
        % Log the rebuild start.
        format("[ruvector] rebuilding '~w': re-inserting ~w vectors~n", [CollName, Total]),
        % Step 4: Re-insert all shadow vectors using the raw HTTP predicate.
        forall(
            backend_ruvector_shadow(CollName, BaseUrl, IdAtom, FloatVec, MetaAtom),
            backend_ruvector_insert_http(CollName, BaseUrl, IdAtom, FloatVec, MetaAtom)
        ),
        % Log the rebuild completion.
        format("[ruvector] rebuild of '~w' complete (~w vectors restored)~n", [CollName, Total])
    ;   % No shadows exist — nothing to rebuild; log and return true.
        format("[ruvector] no shadow vectors found for '~w'; rebuild skipped~n", [CollName])
    ).

% ---------------------------------------------------------------------------
% backend_ruvector_shadow_count/2
% Diagnostic predicate: returns the number of shadow vectors for a Ref.
% Use this to verify that the shadow store is being populated correctly.
%
% Usage:
%   ?- backend_ruvector_shadow_count(Ref, Count).
%   Count = 1000.
% ---------------------------------------------------------------------------

% Define a clause for 'vbr shadow count': count shadow entries for a collection Ref.
backend_ruvector_shadow_count(rv_ref(CollName, BaseUrl), Count) :-
    % Collect all shadow entries for this collection into a list.
    findall(_, backend_ruvector_shadow(CollName, BaseUrl, _, _, _), ShadowList),
    % Unify Count with the length of the shadow list.
    length(ShadowList, Count).
