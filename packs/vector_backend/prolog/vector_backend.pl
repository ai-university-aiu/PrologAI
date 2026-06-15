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

:- module(vector_backend, [
    vb_create/4,           % +Name, +Dim, +Opts, -Ref
    vb_insert/4,           % +Ref, +Id, +Vec, +Meta
    vb_search/4,           % +Ref, +QueryVec, +K, -Results
    vb_delete/2,           % +Ref, +Id
    vb_update_weights/3,   % +Ref, +Id, +Delta
    vb_close/1,            % +Ref
    vb_set_backend/1,      % +BackendAtom
    vb_current_backend/1   % -BackendAtom
]).

:- use_module(library(backend_prolog)).

% ---------------------------------------------------------------------------
% Backend routing
% ---------------------------------------------------------------------------

:- dynamic vb_active_backend/1.
vb_active_backend(prolog).          % default: pure-Prolog fallback

%! vb_set_backend(+Backend) is det.
%  Switch the active backend.  Supported: prolog, rust (when compiled).
vb_set_backend(Backend) :-
    retractall(vb_active_backend(_)),
    assertz(vb_active_backend(Backend)).

%! vb_current_backend(-Backend) is det.
vb_current_backend(B) :- vb_active_backend(B).

% ---------------------------------------------------------------------------
% Routing layer — dispatches to the active backend module
% ---------------------------------------------------------------------------

vb_create(Name, Dim, Opts, Ref) :-
    vb_active_backend(B),
    vb_dispatch_create(B, Name, Dim, Opts, Ref).

vb_insert(Ref, Id, Vec, Meta) :-
    vb_active_backend(B),
    vb_dispatch_insert(B, Ref, Id, Vec, Meta).

vb_search(Ref, Query, K, Results) :-
    vb_active_backend(B),
    vb_dispatch_search(B, Ref, Query, K, Results).

vb_delete(Ref, Id) :-
    vb_active_backend(B),
    vb_dispatch_delete(B, Ref, Id).

vb_update_weights(Ref, Id, Delta) :-
    vb_active_backend(B),
    vb_dispatch_update_weights(B, Ref, Id, Delta).

vb_close(Ref) :-
    vb_active_backend(B),
    vb_dispatch_close(B, Ref).

% ---------------------------------------------------------------------------
% Dispatch to prolog backend
% ---------------------------------------------------------------------------

vb_dispatch_create(prolog, Name, Dim, Opts, Ref) :-
    vbp_create(Name, Dim, Opts, Ref).
vb_dispatch_insert(prolog, Ref, Id, Vec, Meta) :-
    vbp_insert(Ref, Id, Vec, Meta).
vb_dispatch_search(prolog, Ref, Query, K, Results) :-
    vbp_search(Ref, Query, K, Results).
vb_dispatch_delete(prolog, Ref, Id) :-
    vbp_delete(Ref, Id).
vb_dispatch_update_weights(prolog, Ref, Id, Delta) :-
    vbp_update_weights(Ref, Id, Delta).
vb_dispatch_close(prolog, Ref) :-
    vbp_close(Ref).
