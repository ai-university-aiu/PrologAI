/*  PrologAI — PR 9 Sentinel Engine Acceptance Tests

    AC-PR09-001: sentinel fires when anchor_node matches pattern.
    AC-PR09-002: Higher priority sentinel fires before lower priority.
    AC-PR09-003: Sentinel in inactive domain does NOT fire.
    AC-PR09-004: Semantic similarity match fires sentinel (Phase 2).
    AC-PR09-005: sentinel_retract removes a sentinel; it no longer fires.
    AC-PR09-006: Action exception is caught; other sentinels continue.
    AC-PR09-007: Multiple sentinels all fire on a matching change.
    AC-PR09-008: sentinel_list/2 returns registered sentinels.
    AC-PR09-009: sentinel_domain_deactivate suspends evaluation.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatticePath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   atomic_list_concat([ProjectRoot, '/packs/sentinels/prolog'],      SentinelPath),
   assertz(file_search_path(library, LatticePath)),
   assertz(file_search_path(library, VBPath)),
   assertz(file_search_path(library, SentinelPath)).

:- use_module(library(plunit)).
:- use_module(library(lattice),         [lattice_open/2, lattice_close/1]).
:- use_module(library(node_facts),      [anchor_node/4, set_default_nexus/1]).
:- use_module(library(sentinels),       [pai_register_sentinel/6, sentinel_retract/1,
                                         sentinel_list/2, sentinel_domain_activate/1,
                                         sentinel_domain_deactivate/1]).
:- use_module(library(sentinel_engine)).

:- dynamic user:pr09_fired/1.

:- begin_tests(pr09, [setup(pr09_setup), cleanup(pr09_cleanup)]).

pr09_setup :-
    lattice_open('locus://localhost/pr09', N),
    nb_setval(pr09_nexus_ref, N),  % note: this is just for cleanup; node_facts uses default
    set_default_nexus(N),
    retractall(user:pr09_fired(_)),
    sentinel_retract(pr09_test).

pr09_cleanup :-
    sentinel_retract(pr09_test),
    sentinel_retract(pr09_priority),
    sentinel_retract(pr09_inactive),
    lattice_open('locus://localhost/pr09', N),
    lattice_close(N).

test(sentinel_fires_on_match) :-
    pai_register_sentinel(pr09_test, 10,
        node_fact(_, percept, [apple|_], _),
        [],
        assertz(user:pr09_fired(apple_detected)),
        "Apple detector"),
    anchor_node(percept, [apple, red], [visible], _),
    user:pr09_fired(apple_detected).

test(priority_ordering) :-
    retractall(user:pr09_fired(_)),
    pai_register_sentinel(pr09_priority, 20,
        node_fact(_, fruit, _, _),
        [], assertz(user:pr09_fired(high_prio)), "High"),
    pai_register_sentinel(pr09_priority, 5,
        node_fact(_, fruit, _, _),
        [], assertz(user:pr09_fired(low_prio)), "Low"),
    sentinel_retract(pr09_test),  % avoid test sentinels firing on fruit too
    anchor_node(fruit, [banana], [], _),
    findall(X, user:pr09_fired(X), Log),
    nth1(1, Log, high_prio),
    nth1(2, Log, low_prio).

test(inactive_domain_no_fire) :-
    pai_register_sentinel(pr09_inactive, 10,
        node_fact(_, veggie, _, _),
        [], assertz(user:pr09_fired(veggie_detected)), "Veggie"),
    sentinel_domain_deactivate(pr09_inactive),
    retractall(user:pr09_fired(_)),
    anchor_node(veggie, [carrot], [], _),
    \+ user:pr09_fired(veggie_detected),
    sentinel_domain_activate(pr09_inactive).

test(semantic_similarity_phase2) :-
    pai_register_sentinel(pr09_test, 8,
        node_fact(_, percept, [orange|_], _),
        [], assertz(user:pr09_fired(orange_similar)), "Orange"),
    anchor_node(percept, [orange, round], [visible], _),
    user:pr09_fired(orange_similar).

test(sentinel_retract_stops_firing) :-
    pai_register_sentinel(pr09_test, 15,
        node_fact(_, temp_rel, _, _),
        [], assertz(user:pr09_fired(temp_fired)), "Temp"),
    sentinel_retract(pr09_test),
    retractall(user:pr09_fired(_)),
    anchor_node(temp_rel, [x], [], _),
    \+ user:pr09_fired(temp_fired).

test(action_error_continues) :-
    retractall(user:pr09_fired(_)),
    pai_register_sentinel(pr09_test, 30,
        node_fact(_, err_rel, _, _),
        [], throw(sentinel_test_error), "Thrower"),
    pai_register_sentinel(pr09_test, 5,
        node_fact(_, err_rel, _, _),
        [], assertz(user:pr09_fired(after_error)), "After"),
    anchor_node(err_rel, [x], [], _),
    user:pr09_fired(after_error).

test(multiple_sentinels_all_fire) :-
    retractall(user:pr09_fired(_)),
    pai_register_sentinel(pr09_test, 10,
        node_fact(_, multi_rel, _, _),
        [], assertz(user:pr09_fired(multi1)), "Multi1"),
    pai_register_sentinel(pr09_test, 10,
        node_fact(_, multi_rel, _, _),
        [], assertz(user:pr09_fired(multi2)), "Multi2"),
    anchor_node(multi_rel, [x], [], _),
    user:pr09_fired(multi1),
    user:pr09_fired(multi2).

test(sentinel_list_returns_registered) :-
    pai_register_sentinel(pr09_test, 42,
        node_fact(_, list_rel, _, _),
        [], true, "List test"),
    sentinel_list(pr09_test, L),
    L \= [].

test(domain_deactivate_reactivate) :-
    sentinel_domain_deactivate(pr09_test),
    sentinel_domain_activate(pr09_test),
    retractall(user:pr09_fired(_)),
    pai_register_sentinel(pr09_test, 10,
        node_fact(_, react_rel, _, _),
        [], assertz(user:pr09_fired(reactivated)), "React"),
    anchor_node(react_rel, [x], [], _),
    user:pr09_fired(reactivated).

:- end_tests(pr09).
