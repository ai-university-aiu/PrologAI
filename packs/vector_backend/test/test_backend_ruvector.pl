/*  PrologAI — RuVector HTTP Backend Unit Tests (PR 2, update)

    These tests exercise the backend_ruvector predicates in isolation.

    The RuVector server does not need to be running for these tests to pass.
    All HTTP calls in the predicates under test use catch/3 to swallow
    connection errors gracefully, so each test verifies that the predicate
    structure and dispatch logic are correct regardless of server availability.

    Acceptance criteria:
        AC-RV-001: vbr_create/4 returns a rv_ref/2 Ref term
        AC-RV-002: vbr_insert/4 succeeds without crashing (server absent)
        AC-RV-003: vbr_search/4 returns empty list when server is absent
        AC-RV-004: vbr_delete/2 succeeds without crashing (server absent)
        AC-RV-005: vbr_update_weights/3 always succeeds (deliberate no-op)
        AC-RV-006: vbr_close/1 succeeds without crashing (server absent)
        AC-RV-007: vb_set_backend(ruvector) switches the active backend
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

% AC-RV-001: vbr_create/4 must return a rv_ref/2 term.
test(create_returns_rv_ref, []) :-
    % Call vbr_create with name, dimension, empty options; bind Ref.
    vbr_create(test_coll, 4, [], Ref),
    % Verify the Ref functor is rv_ref with two arguments.
    functor(Ref, rv_ref, 2).

% AC-RV-002: vbr_insert/4 must not throw even when server is absent.
test(insert_no_crash, []) :-
    % Create a local Ref term directly (server may be absent).
    Ref = rv_ref(test_coll, 'http://localhost:8080'),
    % Call insert with a 4-element float vector; expect success.
    vbr_insert(Ref, vec_1, [0.1, 0.2, 0.3, 0.4], meta(1)).

% AC-RV-003: vbr_search/4 returns [] when server is absent.
test(search_returns_empty_on_failure, []) :-
    % Create a local Ref term directly.
    Ref = rv_ref(test_coll, 'http://localhost:8080'),
    % Call search; expect Results to be unified with [].
    vbr_search(Ref, [0.1, 0.2, 0.3, 0.4], 5, Results),
    % Verify the result is an empty list.
    Results = [].

% AC-RV-004: vbr_delete/2 must not throw even when server is absent.
test(delete_no_crash, []) :-
    % Create a local Ref term directly.
    Ref = rv_ref(test_coll, 'http://localhost:8080'),
    % Call delete with an arbitrary id; expect success.
    vbr_delete(Ref, vec_1).

% AC-RV-005: vbr_update_weights/3 is a deliberate no-op and always succeeds.
test(update_weights_noop, []) :-
    % Create a local Ref term directly.
    Ref = rv_ref(test_coll, 'http://localhost:8080'),
    % Verify the no-op predicate succeeds.
    vbr_update_weights(Ref, vec_1, 0.01).

% AC-RV-006: vbr_close/1 must not throw even when server is absent.
test(close_no_crash, []) :-
    % Create a local Ref term directly.
    Ref = rv_ref(test_coll, 'http://localhost:8080'),
    % Call close; expect success.
    vbr_close(Ref).

% AC-RV-007: vb_set_backend/1 must accept 'ruvector' without error.
test(set_backend_ruvector, []) :-
    % Switch the active backend to ruvector.
    vb_set_backend(ruvector),
    % Verify the current backend is now ruvector.
    vb_current_backend(ruvector),
    % Restore the default backend for other tests.
    vb_set_backend(prolog).

% End the test suite.
:- end_tests(ruvector_backend).
