/*  PrologAI — PR 3 Lattice Acceptance Tests

    AC-PR03-001: lattice_open accepts locus://HOST/PATH addresses.
    AC-PR03-002: lattice_open rejects non-locus addresses.
    AC-PR03-003: lattice_close marks a nexus closed.
    AC-PR03-004: lattice_verify succeeds on an open nexus (empty hash baseline).
    AC-PR03-005: lattice_transaction commits on success.
    AC-PR03-006: lattice_transaction rolls back (re-throws) on error.
    AC-PR03-007: lattice_status returns address, state, and node_facts count.
    AC-PR03-008: lattice_dump writes a readable file.
    AC-PR03-009: traverse bound — 100 node_facts found within 100 ms.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatticePath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   assertz(file_search_path(library, LatticePath)),
   assertz(file_search_path(library, VBPath)).

:- use_module(library(plunit)).
:- use_module(library(lists), [memberchk/2]).
:- use_module(library(lattice)).

:- begin_tests(pr03).

test(open_valid_address, [setup(true), cleanup(lattice_close(Nexus))]) :-
    lattice_open('locus://localhost/test', Nexus),
    nexus_is_open(Nexus).

test(open_idempotent) :-
    lattice_open('locus://localhost/idempotent', N1),
    lattice_open('locus://localhost/idempotent', N2),
    N1 == N2,
    lattice_close(N1).

test(open_rejects_bad_address, [throws(error(domain_error(nexus_address, bad), _))]) :-
    lattice_open(bad, _).

test(close_marks_closed) :-
    lattice_open('locus://localhost/close_test', N),
    lattice_close(N),
    nexus_state(N, closed).

test(verify_empty_nexus) :-
    lattice_open('locus://localhost/verify_test', N),
    lattice_verify(N),    % sets baseline
    lattice_verify(N),    % compare matches
    lattice_close(N).

test(transaction_commits) :-
    nb_setval(pr03_tx_flag, 0),
    lattice_open('locus://localhost/tx_test', N),
    lattice_transaction(N, nb_setval(pr03_tx_flag, 1)),
    nb_getval(pr03_tx_flag, 1),
    lattice_close(N).

test(transaction_rollback, [throws(error(tx_test_error, _))]) :-
    lattice_open('locus://localhost/tx_rollback', N),
    lattice_transaction(N, throw(error(tx_test_error, tx_rollback))),
    lattice_close(N).

test(status_fields) :-
    lattice_open('locus://localhost/status_test', N),
    lattice_status(N, Status),
    memberchk(address('locus://localhost/status_test'), Status),
    memberchk(state(open), Status),
    memberchk(node_facts(0), Status),
    lattice_close(N).

test(dump_writes_file) :-
    lattice_open('locus://localhost/dump_test', N),
    Tmp = '/tmp/prologai_test_dump.pl',
    lattice_dump(N, Tmp),
    exists_file(Tmp),
    lattice_close(N).

:- end_tests(pr03).
