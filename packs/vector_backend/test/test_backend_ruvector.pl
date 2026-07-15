/*  PrologAI — RuVector HTTP Backend Unit Tests (PR 2, update)

    These tests exercise the backend_ruvector predicates in isolation.

    The RuVector server does not need to be running for these tests to pass.
    All HTTP calls in the predicates under test use catch/3 to swallow
    connection errors gracefully, so each test verifies that the predicate
    structure and dispatch logic are correct regardless of server availability.

    Shadow store tests (AC-RV-008 through AC-RV-012) access backend_ruvector_shadow/5
    with the module qualifier backend_ruvector:backend_ruvector_shadow/5 because that
    dynamic fact is private to the backend_ruvector module.

    The fake URL 'http://localhost:19999' is used for all shadow/rebuild
    tests so they do not accidentally connect to a live RuVector server and
    can be distinguished from live-server tests.

    Acceptance criteria:
        AC-RV-001: backend_ruvector_create/4 returns a rv_ref/2 Ref term
        AC-RV-002: backend_ruvector_insert/4 succeeds without crashing (server absent)
        AC-RV-003: backend_ruvector_search/4 returns empty list when server is absent
        AC-RV-004: backend_ruvector_delete/2 succeeds without crashing (server absent)
        AC-RV-005: backend_ruvector_update_weights/3 always succeeds (deliberate no-op)
        AC-RV-006: backend_ruvector_close/1 succeeds without crashing (server absent)
        AC-RV-007: vector_backend_set_backend(ruvector) switches the active backend
        AC-RV-008: backend_ruvector_insert/4 records a shadow entry in backend_ruvector_shadow/5
        AC-RV-009: backend_ruvector_delete/2 removes the shadow entry for that Id
        AC-RV-010: backend_ruvector_close/1 removes all shadow entries for the collection
        AC-RV-011: backend_ruvector_rebuild/1 succeeds gracefully when no shadows exist
        AC-RV-012: backend_ruvector_shadow_count/2 returns the correct count after inserts
*/

% Declare this test file as the 'test_backend_ruvector' module.
:- module(test_backend_ruvector, []).

% Load the PLUnit (Prolog Unit testing) framework.
:- use_module(library(plunit)).
% Load the backend_ruvector module under test.
:- use_module(library(backend_ruvector)).
% Load the vector_backend module to test backend switching.
:- use_module(library(vector_backend)).

% Begin the test suite named 'ruvector_backend'.
:- begin_tests(ruvector_backend).

% AC-RV-001: backend_ruvector_create/4 must return a rv_ref/2 term.
test(create_returns_rv_ref, []) :-
    % Call backend_ruvector_create with name, dimension, empty options; bind Ref.
    backend_ruvector_create(test_coll, 4, [], Ref),
    % Verify the Ref functor is rv_ref with two arguments.
    functor(Ref, rv_ref, 2).

% AC-RV-002: backend_ruvector_insert/4 must not throw even when server is absent.
test(insert_no_crash,
     [setup(retractall(backend_ruvector:backend_ruvector_shadow(shadow_coll_2,_,_,_,_))),
      cleanup(retractall(backend_ruvector:backend_ruvector_shadow(shadow_coll_2,_,_,_,_)))]) :-
    % Create a Ref pointing at a port that will refuse connections.
    Ref = rv_ref(shadow_coll_2, 'http://localhost:19999'),
    % Call insert with a 4-element float vector; expect success despite no server.
    backend_ruvector_insert(Ref, vec_1, [0.1, 0.2, 0.3, 0.4], meta(1)).

% AC-RV-003: backend_ruvector_search/4 returns [] when server is absent.
test(search_returns_empty_on_failure, []) :-
    % Create a local Ref term pointing at a non-existent server.
    Ref = rv_ref(test_coll, 'http://localhost:19999'),
    % Call search; expect Results to be unified with [].
    backend_ruvector_search(Ref, [0.1, 0.2, 0.3, 0.4], 5, Results),
    % Verify the result is an empty list.
    Results = [].

% AC-RV-004: backend_ruvector_delete/2 must not throw even when server is absent.
test(delete_no_crash, []) :-
    % Create a local Ref term pointing at a non-existent server.
    Ref = rv_ref(test_coll, 'http://localhost:19999'),
    % Call delete with an arbitrary id; expect success.
    backend_ruvector_delete(Ref, vec_1).

% AC-RV-005: backend_ruvector_update_weights/3 is a deliberate no-op and always succeeds.
test(update_weights_noop, []) :-
    % Create a local Ref term pointing at a non-existent server.
    Ref = rv_ref(test_coll, 'http://localhost:19999'),
    % Verify the no-op predicate succeeds.
    backend_ruvector_update_weights(Ref, vec_1, 0.01).

% AC-RV-006: backend_ruvector_close/1 must not throw even when server is absent.
test(close_no_crash,
     [setup(retractall(backend_ruvector:backend_ruvector_shadow(close_coll_6,_,_,_,_)))]) :-
    % Create a local Ref term pointing at a non-existent server.
    Ref = rv_ref(close_coll_6, 'http://localhost:19999'),
    % Call close; expect success.
    backend_ruvector_close(Ref).

% AC-RV-007: vector_backend_set_backend/1 must accept 'ruvector' without error.
test(set_backend_ruvector, []) :-
    % Switch the active backend to ruvector.
    vector_backend_set_backend(ruvector),
    % Verify the current backend is now ruvector.
    vector_backend_current_backend(ruvector),
    % Restore the default backend for other tests.
    vector_backend_set_backend(prolog).

% AC-RV-008: backend_ruvector_insert/4 must record a backend_ruvector_shadow/5 entry after a call.
test(insert_records_shadow,
     [setup(retractall(backend_ruvector:backend_ruvector_shadow(shadow_coll_8,_,_,_,_))),
      cleanup(retractall(backend_ruvector:backend_ruvector_shadow(shadow_coll_8,_,_,_,_)))]) :-
    % Create a Ref pointing at a port that will refuse connections.
    Ref = rv_ref(shadow_coll_8, 'http://localhost:19999'),
    % Insert a vector; the HTTP call will fail silently but the shadow must be recorded.
    backend_ruvector_insert(Ref, sv_1, [1.0, 2.0, 3.0, 4.0], meta(shadow)),
    % Verify that a shadow entry now exists for this collection and Id.
    backend_ruvector:backend_ruvector_shadow(shadow_coll_8, 'http://localhost:19999', sv_1, _, _).

% AC-RV-009: backend_ruvector_delete/2 must remove the shadow entry for the deleted Id.
test(delete_removes_shadow,
     [setup((retractall(backend_ruvector:backend_ruvector_shadow(shadow_coll_9,_,_,_,_)),
             assertz(backend_ruvector:backend_ruvector_shadow(shadow_coll_9,'http://localhost:19999',sv_del,[1.0],m)))),
      cleanup(retractall(backend_ruvector:backend_ruvector_shadow(shadow_coll_9,_,_,_,_)))]) :-
    % Create a Ref for the test collection.
    Ref = rv_ref(shadow_coll_9, 'http://localhost:19999'),
    % Verify the shadow exists before delete.
    backend_ruvector:backend_ruvector_shadow(shadow_coll_9, 'http://localhost:19999', sv_del, _, _),
    % Call delete to remove the shadow entry.
    backend_ruvector_delete(Ref, sv_del),
    % Verify no shadow remains for this Id.
    \+ backend_ruvector:backend_ruvector_shadow(shadow_coll_9, 'http://localhost:19999', sv_del, _, _).

% AC-RV-010: backend_ruvector_close/1 must remove ALL shadow entries for the collection.
test(close_clears_shadows,
     [setup((retractall(backend_ruvector:backend_ruvector_shadow(shadow_coll_10,_,_,_,_)),
             assertz(backend_ruvector:backend_ruvector_shadow(shadow_coll_10,'http://localhost:19999',a,[1.0],m)),
             assertz(backend_ruvector:backend_ruvector_shadow(shadow_coll_10,'http://localhost:19999',b,[2.0],m)))),
      cleanup(retractall(backend_ruvector:backend_ruvector_shadow(shadow_coll_10,_,_,_,_)))]) :-
    % Create a Ref for the test collection.
    Ref = rv_ref(shadow_coll_10, 'http://localhost:19999'),
    % Verify two shadows exist before close.
    backend_ruvector_shadow_count(Ref, CountBefore),
    CountBefore =:= 2,
    % Call close to drop the collection and clear all shadows.
    backend_ruvector_close(Ref),
    % Verify no shadows remain after close.
    backend_ruvector_shadow_count(Ref, CountAfter),
    CountAfter =:= 0.

% AC-RV-011: backend_ruvector_rebuild/1 must succeed gracefully when no shadows exist.
test(rebuild_no_shadows,
     [setup(retractall(backend_ruvector:backend_ruvector_shadow(empty_coll_11,_,_,_,_)))]) :-
    % Create a Ref pointing at a port that will refuse connections.
    Ref = rv_ref(empty_coll_11, 'http://localhost:19999'),
    % Call rebuild on a collection with no shadows; expect graceful success.
    backend_ruvector_rebuild(Ref).

% AC-RV-012: backend_ruvector_shadow_count/2 must return the correct count after inserts.
test(shadow_count_correct,
     [setup(retractall(backend_ruvector:backend_ruvector_shadow(count_coll_12,_,_,_,_))),
      cleanup(retractall(backend_ruvector:backend_ruvector_shadow(count_coll_12,_,_,_,_)))]) :-
    % Create a Ref for the count test collection.
    Ref = rv_ref(count_coll_12, 'http://localhost:19999'),
    % Verify count starts at zero.
    backend_ruvector_shadow_count(Ref, C0), C0 =:= 0,
    % Insert three vectors (HTTP will fail silently; shadows must be recorded).
    backend_ruvector_insert(Ref, c1, [1.0, 0.0], m1),
    backend_ruvector_insert(Ref, c2, [0.0, 1.0], m2),
    backend_ruvector_insert(Ref, c3, [0.5, 0.5], m3),
    % Verify the count is now three.
    backend_ruvector_shadow_count(Ref, C3), C3 =:= 3.

% End the test suite.
:- end_tests(ruvector_backend).
