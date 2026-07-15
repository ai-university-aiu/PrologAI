/*  PrologAI — Vector Backend Interface Test Suite  (PR 2)

    Exercises the backend-agnostic six-predicate contract of the
    vector_backend pack through its default pure-Prolog backend, which is
    fully in-memory and deterministic (no RuVector server required).

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/vector_backend/test/test_vector_backend.pl

    Acceptance criteria:
        AC-VB-001: the default active backend is the pure-Prolog fallback
        AC-VB-002: create/4 yields a Ref that close/1 accepts
        AC-VB-003: search/4 returns the nearest neighbour first by cosine
        AC-VB-004: search/4 honours the K cap on the number of results
        AC-VB-005: delete/2 removes an id from subsequent search results
        AC-VB-006: update_weights/3 succeeds on a stored entry
        AC-VB-007: set_backend/1 switches, current_backend/1 reads it back
*/

% Declare this file as a test module.
:- module(test_vector_backend, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(vector_backend)).

% Open the test block for vector_backend.
:- begin_tests(vector_backend).

% AC-VB-001: the pack ships with the pure-Prolog backend active by default.
test(default_backend_is_prolog) :-
    % Read the currently active backend atom.
    vector_backend_current_backend(B),
    % It must be the pure-Prolog fallback.
    assertion(B == prolog).

% AC-VB-002: create/4 returns a usable Ref and close/1 accepts it.
test(create_then_close) :-
    % Create a four-dimensional index and bind its Ref.
    vector_backend_create(idx_create, 4, [], Ref),
    % The Ref is bound (create actually produced a handle).
    assertion(nonvar(Ref)),
    % Close the index using that Ref.
    vector_backend_close(Ref).

% AC-VB-003: nearest-neighbour search ranks the closest vector first.
test(search_ranks_nearest_first) :-
    % Create a fresh four-dimensional index.
    vector_backend_create(idx_search, 4, [], Ref),
    % Store a vector aligned with the first axis.
    vector_backend_insert(Ref, id_x, [1.0, 0.0, 0.0, 0.0], meta(x)),
    % Store a vector aligned with the second axis.
    vector_backend_insert(Ref, id_y, [0.0, 1.0, 0.0, 0.0], meta(y)),
    % Store a vector aligned with the third axis.
    vector_backend_insert(Ref, id_z, [0.0, 0.0, 1.0, 0.0], meta(z)),
    % Query with the first-axis vector, asking for the top two matches.
    vector_backend_search(Ref, [1.0, 0.0, 0.0, 0.0], 2, Results),
    % The best match must be the identical first-axis vector.
    Results = [_TopScore-TopId | _Rest],
    % Confirm the winner is the first-axis entry.
    assertion(TopId == id_x),
    % Release the index.
    vector_backend_close(Ref).

% AC-VB-004: search/4 never returns more than K results.
test(search_respects_k_cap) :-
    % Create a fresh four-dimensional index.
    vector_backend_create(idx_cap, 4, [], Ref),
    % Store three distinct vectors.
    vector_backend_insert(Ref, c1, [1.0, 0.0, 0.0, 0.0], meta(1)),
    vector_backend_insert(Ref, c2, [0.0, 1.0, 0.0, 0.0], meta(2)),
    vector_backend_insert(Ref, c3, [0.0, 0.0, 1.0, 0.0], meta(3)),
    % Ask for only the single best neighbour.
    vector_backend_search(Ref, [1.0, 0.0, 0.0, 0.0], 1, Results),
    % Exactly one result may come back.
    length(Results, N),
    % Confirm the K cap of one was honoured.
    assertion(N =:= 1),
    % Release the index.
    vector_backend_close(Ref).

% AC-VB-005: a deleted id must not appear in later search results.
test(delete_removes_from_search) :-
    % Create a fresh four-dimensional index.
    vector_backend_create(idx_delete, 4, [], Ref),
    % Store two vectors, one of which will be deleted.
    vector_backend_insert(Ref, keep, [1.0, 0.0, 0.0, 0.0], meta(k)),
    vector_backend_insert(Ref, drop, [0.9, 0.1, 0.0, 0.0], meta(d)),
    % Delete the 'drop' entry.
    vector_backend_delete(Ref, drop),
    % Search across the whole (small) index.
    vector_backend_search(Ref, [1.0, 0.0, 0.0, 0.0], 5, Results),
    % The deleted id must be absent from the results.
    assertion(\+ member(_-drop, Results)),
    % The kept id must still be present.
    assertion(member(_-keep, Results)),
    % Release the index.
    vector_backend_close(Ref).

% AC-VB-006: update_weights/3 succeeds on a stored entry.
test(update_weights_succeeds) :-
    % Create a fresh four-dimensional index.
    vector_backend_create(idx_weights, 4, [], Ref),
    % Store a single vector to re-weight.
    vector_backend_insert(Ref, w1, [1.0, 0.0, 0.0, 0.0], meta(w)),
    % Nudge its learned edge weight upward; this must succeed.
    assertion(vector_backend_update_weights(Ref, w1, 0.05)),
    % Release the index.
    vector_backend_close(Ref).

% AC-VB-007: set_backend/1 switches the backend and current_backend/1 reads it.
test(set_backend_round_trips,
     [cleanup(vector_backend_set_backend(prolog))]) :-
    % Switch the active backend to ruvector.
    vector_backend_set_backend(ruvector),
    % Reading it back must report ruvector.
    vector_backend_current_backend(After),
    % Confirm the switch took effect.
    assertion(After == ruvector),
    % Switch back to the pure-Prolog default.
    vector_backend_set_backend(prolog),
    % Reading it back must report prolog again.
    vector_backend_current_backend(Restored),
    % Confirm the restore took effect.
    assertion(Restored == prolog).

% Close the test block for vector_backend.
:- end_tests(vector_backend).
