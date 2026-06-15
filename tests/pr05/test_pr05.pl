/*  PrologAI — PR 5 Scopes and Zones Acceptance Tests

    AC-PR05-001: node_fact in scope_alice NOT found in scope_bob scan.
    AC-PR05-002: scope_open with invalid zone throws.
    AC-PR05-003: scope_seal makes a scope read-only.
    AC-PR05-004: scope_merge copies node_facts from possible to present.
    AC-PR05-005: present_zone → possible_zone merge is blocked.
    AC-PR05-006: scope_scan returns node_facts only from the named scope.
    AC-PR05-007: all nine zone types are valid.
    AC-PR05-008: scope_activate sets the current scope.
    AC-PR05-009: scope_inscribe returns a nonzero Id.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatticePath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   assertz(file_search_path(library, LatticePath)),
   assertz(file_search_path(library, VBPath)).

:- use_module(library(plunit)).
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1]).
:- use_module(library(node_facts), [set_default_nexus/1]).
:- use_module(library(scopes)).

:- begin_tests(pr05,
    [ setup(pr05_setup),
      cleanup(pr05_cleanup)
    ]).

pr05_setup :-
    lattice_open('locus://localhost/pr05', N),
    nb_setval(pr05_nexus, N),
    set_default_nexus(N).

pr05_cleanup :-
    nb_getval(pr05_nexus, N),
    lattice_close(N).

test(scope_isolation) :-
    scope_open(scope_alice, present_zone),
    scope_open(scope_bob, present_zone),
    scope_inscribe(scope_alice, percept, [apple], [visible], Id),
    scope_scan(scope_bob, node_fact(percept, [apple], [visible]), 10, [], Rs),
    \+ member(_-Id, Rs),
    \+ member(Id-_, Rs).

test(invalid_zone_throws,
     [throws(error(domain_error(zone, nonexistent_zone), _))]) :-
    scope_open(bad_scope, nonexistent_zone).

test(sealed_scope_blocks_inscribe,
     [throws(error(permission_error(inscribe, sealed_scope, seal_test), _))]) :-
    scope_open(seal_test, present_zone),
    scope_seal(seal_test),
    scope_inscribe(seal_test, percept, [x], [], _).

test(scope_merge_possible_to_present) :-
    scope_open(src_scope, possible_zone),
    scope_open(dst_scope, present_zone),
    scope_inscribe(src_scope, percept, [merged_item], [], _OrigId),
    scope_merge(src_scope, dst_scope, []),
    scope_scan(dst_scope, node_fact(percept, [merged_item], []), 5, [], Rs),
    Rs \= [].

test(merge_present_to_possible_blocked,
     [throws(error(permission_error(merge, present_to_possible, _), _))]) :-
    scope_open(from_present, present_zone),
    scope_open(to_possible, possible_zone),
    scope_merge(from_present, to_possible, []).

test(scope_scan_isolation) :-
    scope_open(scan_a, present_zone),
    scope_open(scan_b, present_zone),
    scope_inscribe(scan_a, concept, [unique_to_a], [], Id),
    scope_scan(scan_b, node_fact(concept, [unique_to_a], []), 10, [], Rs),
    \+ member(_-Id, Rs).

test(all_nine_zones) :-
    forall(member(Z, [present_zone, possible_zone, past_zone,
                      desired_zone, expected_zone, imagined_zone,
                      recalled_zone, attained_zone, confirmed_zone]),
           valid_zone(Z)).

test(scope_activate_sets_current) :-
    scope_open(active_scope, present_zone),
    scope_activate(active_scope),
    current_scope(active_scope).

test(scope_inscribe_returns_id) :-
    scope_open(id_test, present_zone),
    scope_inscribe(id_test, rel, [a], [b], Id),
    integer(Id),
    Id > 0.

:- end_tests(pr05).
