/*  PrologAI — Vector Backend Interface (PR 2)
    Backend-agnostic six-predicate contract between the Lattice and any
    vector-similarity store.  The default backend is the pure-Prolog
    fallback; when the prologai-core Rust crate is compiled and linked,
    the routing predicate vector_backend_backend/1 is retracted/asserted to point at
    the native backend instead.

    Six interface predicates (Architecture Section 6.1):
        vector_backend_create/4   – create a named index of declared dimension
        vector_backend_insert/4   – store a vector with its node-fact id and metadata
        vector_backend_search/4   – return the K nearest neighbours
        vector_backend_delete/2   – remove a vector by id
        vector_backend_update_weights/3 – adjust a vector's learned edge weight
        vector_backend_close/1    – flush and release an index
*/

% Declare this file as the 'vector_backend' module and list its exported predicates.
:- module(vector_backend, [
    % Continue the multi-line expression started above.
    vector_backend_create/4,           % +Name, +Dim, +Opts, -Ref
    % Continue the multi-line expression started above.
    vector_backend_insert/4,           % +Ref, +Id, +Vec, +Meta
    % Continue the multi-line expression started above.
    vector_backend_search/4,           % +Ref, +QueryVec, +K, -Results
    % Continue the multi-line expression started above.
    vector_backend_delete/2,           % +Ref, +Id
    % Continue the multi-line expression started above.
    vector_backend_update_weights/3,   % +Ref, +Id, +Delta
    % Continue the multi-line expression started above.
    vector_backend_close/1,            % +Ref
    % Continue the multi-line expression started above.
    vector_backend_set_backend/1,      % +BackendAtom
    % Continue the multi-line expression started above.
    vector_backend_current_backend/1,  % -BackendAtom
    % Continue the multi-line expression started above.
    vector_backend_rebuild/1           % +Ref  (backend-agnostic rebuild; ruvector only for now)
% Close the expression opened above.
]).

% Load the built-in 'backend_prolog' library so its predicates are available here.
:- use_module(library(backend_prolog)).
% Load the 'backend_ruvector' module — HTTP REST client for the RuVector HNSW server.
:- use_module(library(backend_ruvector)).

% ---------------------------------------------------------------------------
% Backend routing
% ---------------------------------------------------------------------------

% Declare 'vector_backend_active_backend/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic vector_backend_active_backend/1.
% State a fact for 'vb active backend' with the arguments listed below.
vector_backend_active_backend(prolog).          % default: pure-Prolog fallback

%! vector_backend_set_backend(+Backend) is det.
%  Switch the active backend.  Supported: prolog, ruvector.
% Define a clause for 'vb set backend': succeed when the following conditions hold.
vector_backend_set_backend(Backend) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(vector_backend_active_backend(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(vector_backend_active_backend(Backend)).

%! vector_backend_current_backend(-Backend) is det.
% Define a clause for 'vb current backend': succeed when the following conditions hold.
vector_backend_current_backend(B) :- vector_backend_active_backend(B).

% ---------------------------------------------------------------------------
% Routing layer — dispatches to the active backend module
% ---------------------------------------------------------------------------

% Define a clause for 'vb create': succeed when the following conditions hold.
vector_backend_create(Name, Dim, Opts, Ref) :-
    % State a fact for 'vb active backend' with the arguments listed below.
    vector_backend_active_backend(B),
    % State the fact: vb dispatch create(B, Name, Dim, Opts, Ref).
    vector_backend_dispatch_create(B, Name, Dim, Opts, Ref).

% Define a clause for 'vb insert': succeed when the following conditions hold.
vector_backend_insert(Ref, Id, Vec, Meta) :-
    % State a fact for 'vb active backend' with the arguments listed below.
    vector_backend_active_backend(B),
    % State the fact: vb dispatch insert(B, Ref, Id, Vec, Meta).
    vector_backend_dispatch_insert(B, Ref, Id, Vec, Meta).

% Define a clause for 'vb search': succeed when the following conditions hold.
vector_backend_search(Ref, Query, K, Results) :-
    % State a fact for 'vb active backend' with the arguments listed below.
    vector_backend_active_backend(B),
    % State the fact: vb dispatch search(B, Ref, Query, K, Results).
    vector_backend_dispatch_search(B, Ref, Query, K, Results).

% Define a clause for 'vb delete': succeed when the following conditions hold.
vector_backend_delete(Ref, Id) :-
    % State a fact for 'vb active backend' with the arguments listed below.
    vector_backend_active_backend(B),
    % State the fact: vb dispatch delete(B, Ref, Id).
    vector_backend_dispatch_delete(B, Ref, Id).

% Define a clause for 'vb update weights': succeed when the following conditions hold.
vector_backend_update_weights(Ref, Id, Delta) :-
    % State a fact for 'vb active backend' with the arguments listed below.
    vector_backend_active_backend(B),
    % State the fact: vb dispatch update weights(B, Ref, Id, Delta).
    vector_backend_dispatch_update_weights(B, Ref, Id, Delta).

% Define a clause for 'vb close': succeed when the following conditions hold.
vector_backend_close(Ref) :-
    % State a fact for 'vb active backend' with the arguments listed below.
    vector_backend_active_backend(B),
    % State the fact: vb dispatch close(B, Ref).
    vector_backend_dispatch_close(B, Ref).

%! vector_backend_rebuild(+Ref) is det.
%  Rebuild the server-side vector index from the in-process shadow store.
%  For backends that do not support rebuild, this predicate succeeds silently.
% Define a clause for 'vb rebuild': dispatch rebuild to the active backend.
vector_backend_rebuild(Ref) :-
    % Retrieve the currently active backend atom.
    vector_backend_active_backend(B),
    % Dispatch to the backend-specific rebuild implementation.
    vector_backend_dispatch_rebuild(B, Ref).

% ---------------------------------------------------------------------------
% Dispatch to prolog backend
% ---------------------------------------------------------------------------

% Define a clause for 'vb dispatch create': succeed when the following conditions hold.
vector_backend_dispatch_create(prolog, Name, Dim, Opts, Ref) :-
    % State the fact: vbp create(Name, Dim, Opts, Ref).
    backend_prolog_create(Name, Dim, Opts, Ref).
% Define a clause for 'vb dispatch insert': succeed when the following conditions hold.
vector_backend_dispatch_insert(prolog, Ref, Id, Vec, Meta) :-
    % State the fact: vbp insert(Ref, Id, Vec, Meta).
    backend_prolog_insert(Ref, Id, Vec, Meta).
% Define a clause for 'vb dispatch search': succeed when the following conditions hold.
vector_backend_dispatch_search(prolog, Ref, Query, K, Results) :-
    % State the fact: vbp search(Ref, Query, K, Results).
    backend_prolog_search(Ref, Query, K, Results).
% Define a clause for 'vb dispatch delete': succeed when the following conditions hold.
vector_backend_dispatch_delete(prolog, Ref, Id) :-
    % State the fact: vbp delete(Ref, Id).
    backend_prolog_delete(Ref, Id).
% Define a clause for 'vb dispatch update weights': succeed when the following conditions hold.
vector_backend_dispatch_update_weights(prolog, Ref, Id, Delta) :-
    % State the fact: vbp update weights(Ref, Id, Delta).
    backend_prolog_update_weights(Ref, Id, Delta).
% Define a clause for 'vb dispatch close': succeed when the following conditions hold.
vector_backend_dispatch_close(prolog, Ref) :-
    % State the fact: vbp close(Ref).
    backend_prolog_close(Ref).
% Define a clause for 'vb dispatch rebuild' for the prolog backend: no-op (pure-Prolog is always in-memory and intact).
vector_backend_dispatch_rebuild(prolog, _Ref) :- true.

% ---------------------------------------------------------------------------
% Dispatch to ruvector backend (HTTP REST client for the RuVector HNSW server)
% ---------------------------------------------------------------------------

% Define a clause for 'vb dispatch create' for the ruvector backend.
vector_backend_dispatch_create(ruvector, Name, Dim, Opts, Ref) :-
    % Delegate to backend_ruvector_create from the backend_ruvector module.
    backend_ruvector_create(Name, Dim, Opts, Ref).
% Define a clause for 'vb dispatch insert' for the ruvector backend.
vector_backend_dispatch_insert(ruvector, Ref, Id, Vec, Meta) :-
    % Delegate to backend_ruvector_insert from the backend_ruvector module.
    backend_ruvector_insert(Ref, Id, Vec, Meta).
% Define a clause for 'vb dispatch search' for the ruvector backend.
vector_backend_dispatch_search(ruvector, Ref, Query, K, Results) :-
    % Delegate to backend_ruvector_search from the backend_ruvector module.
    backend_ruvector_search(Ref, Query, K, Results).
% Define a clause for 'vb dispatch delete' for the ruvector backend.
vector_backend_dispatch_delete(ruvector, Ref, Id) :-
    % Delegate to backend_ruvector_delete from the backend_ruvector module.
    backend_ruvector_delete(Ref, Id).
% Define a clause for 'vb dispatch update weights' for the ruvector backend.
vector_backend_dispatch_update_weights(ruvector, Ref, Id, Delta) :-
    % Delegate to backend_ruvector_update_weights (no-op — RuVector is self-learning).
    backend_ruvector_update_weights(Ref, Id, Delta).
% Define a clause for 'vb dispatch close' for the ruvector backend.
vector_backend_dispatch_close(ruvector, Ref) :-
    % Delegate to backend_ruvector_close — drops the collection from the RuVector server.
    backend_ruvector_close(Ref).
% Define a clause for 'vb dispatch rebuild' for the ruvector backend.
vector_backend_dispatch_rebuild(ruvector, Ref) :-
    % Delegate to backend_ruvector_rebuild — recreates the collection and re-inserts all shadows.
    backend_ruvector_rebuild(Ref).
