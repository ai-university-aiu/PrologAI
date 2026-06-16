/*  PrologAI — Vector Backend Interface (PR 2)
    Backend-agnostic six-predicate contract between the Lattice and any
    vector-similarity store.  The default backend is the pure-Prolog
    fallback; when the prologai-core Rust crate is compiled and linked,
    the routing predicate vb_backend/1 is retracted/asserted to point at
    the native backend instead.

    Six interface predicates (Architecture Section 6.1):
        vb_create/4   – create a named index of declared dimension
        vb_insert/4   – store a vector with its node-fact id and metadata
        vb_search/4   – return the K nearest neighbours
        vb_delete/2   – remove a vector by id
        vb_update_weights/3 – adjust a vector's learned edge weight
        vb_close/1    – flush and release an index
*/

% Declare this file as the 'vector_backend' module and list its exported predicates.
:- module(vector_backend, [
    % Continue the multi-line expression started above.
    vb_create/4,           % +Name, +Dim, +Opts, -Ref
    % Continue the multi-line expression started above.
    vb_insert/4,           % +Ref, +Id, +Vec, +Meta
    % Continue the multi-line expression started above.
    vb_search/4,           % +Ref, +QueryVec, +K, -Results
    % Continue the multi-line expression started above.
    vb_delete/2,           % +Ref, +Id
    % Continue the multi-line expression started above.
    vb_update_weights/3,   % +Ref, +Id, +Delta
    % Continue the multi-line expression started above.
    vb_close/1,            % +Ref
    % Continue the multi-line expression started above.
    vb_set_backend/1,      % +BackendAtom
    % Continue the multi-line expression started above.
    vb_current_backend/1   % -BackendAtom
% Close the expression opened above.
]).

% Load the built-in 'backend_prolog' library so its predicates are available here.
:- use_module(library(backend_prolog)).

% ---------------------------------------------------------------------------
% Backend routing
% ---------------------------------------------------------------------------

% Declare 'vb_active_backend/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic vb_active_backend/1.
% State a fact for 'vb active backend' with the arguments listed below.
vb_active_backend(prolog).          % default: pure-Prolog fallback

%! vb_set_backend(+Backend) is det.
%  Switch the active backend.  Supported: prolog, rust (when compiled).
% Define a clause for 'vb set backend': succeed when the following conditions hold.
vb_set_backend(Backend) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(vb_active_backend(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(vb_active_backend(Backend)).

%! vb_current_backend(-Backend) is det.
% Define a clause for 'vb current backend': succeed when the following conditions hold.
vb_current_backend(B) :- vb_active_backend(B).

% ---------------------------------------------------------------------------
% Routing layer — dispatches to the active backend module
% ---------------------------------------------------------------------------

% Define a clause for 'vb create': succeed when the following conditions hold.
vb_create(Name, Dim, Opts, Ref) :-
    % State a fact for 'vb active backend' with the arguments listed below.
    vb_active_backend(B),
    % State the fact: vb dispatch create(B, Name, Dim, Opts, Ref).
    vb_dispatch_create(B, Name, Dim, Opts, Ref).

% Define a clause for 'vb insert': succeed when the following conditions hold.
vb_insert(Ref, Id, Vec, Meta) :-
    % State a fact for 'vb active backend' with the arguments listed below.
    vb_active_backend(B),
    % State the fact: vb dispatch insert(B, Ref, Id, Vec, Meta).
    vb_dispatch_insert(B, Ref, Id, Vec, Meta).

% Define a clause for 'vb search': succeed when the following conditions hold.
vb_search(Ref, Query, K, Results) :-
    % State a fact for 'vb active backend' with the arguments listed below.
    vb_active_backend(B),
    % State the fact: vb dispatch search(B, Ref, Query, K, Results).
    vb_dispatch_search(B, Ref, Query, K, Results).

% Define a clause for 'vb delete': succeed when the following conditions hold.
vb_delete(Ref, Id) :-
    % State a fact for 'vb active backend' with the arguments listed below.
    vb_active_backend(B),
    % State the fact: vb dispatch delete(B, Ref, Id).
    vb_dispatch_delete(B, Ref, Id).

% Define a clause for 'vb update weights': succeed when the following conditions hold.
vb_update_weights(Ref, Id, Delta) :-
    % State a fact for 'vb active backend' with the arguments listed below.
    vb_active_backend(B),
    % State the fact: vb dispatch update weights(B, Ref, Id, Delta).
    vb_dispatch_update_weights(B, Ref, Id, Delta).

% Define a clause for 'vb close': succeed when the following conditions hold.
vb_close(Ref) :-
    % State a fact for 'vb active backend' with the arguments listed below.
    vb_active_backend(B),
    % State the fact: vb dispatch close(B, Ref).
    vb_dispatch_close(B, Ref).

% ---------------------------------------------------------------------------
% Dispatch to prolog backend
% ---------------------------------------------------------------------------

% Define a clause for 'vb dispatch create': succeed when the following conditions hold.
vb_dispatch_create(prolog, Name, Dim, Opts, Ref) :-
    % State the fact: vbp create(Name, Dim, Opts, Ref).
    vbp_create(Name, Dim, Opts, Ref).
% Define a clause for 'vb dispatch insert': succeed when the following conditions hold.
vb_dispatch_insert(prolog, Ref, Id, Vec, Meta) :-
    % State the fact: vbp insert(Ref, Id, Vec, Meta).
    vbp_insert(Ref, Id, Vec, Meta).
% Define a clause for 'vb dispatch search': succeed when the following conditions hold.
vb_dispatch_search(prolog, Ref, Query, K, Results) :-
    % State the fact: vbp search(Ref, Query, K, Results).
    vbp_search(Ref, Query, K, Results).
% Define a clause for 'vb dispatch delete': succeed when the following conditions hold.
vb_dispatch_delete(prolog, Ref, Id) :-
    % State the fact: vbp delete(Ref, Id).
    vbp_delete(Ref, Id).
% Define a clause for 'vb dispatch update weights': succeed when the following conditions hold.
vb_dispatch_update_weights(prolog, Ref, Id, Delta) :-
    % State the fact: vbp update weights(Ref, Id, Delta).
    vbp_update_weights(Ref, Id, Delta).
% Define a clause for 'vb dispatch close': succeed when the following conditions hold.
vb_dispatch_close(prolog, Ref) :-
    % State the fact: vbp close(Ref).
    vbp_close(Ref).
