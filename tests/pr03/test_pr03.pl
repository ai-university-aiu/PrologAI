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

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatticePath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatticePath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [memberchk/2] from the built-in 'lists' library.
:- use_module(library(lists), [memberchk/2]).
% Load the built-in 'lattice' library so its predicates are available here.
:- use_module(library(lattice)).

% Execute the compile-time directive: begin_tests(pr03).
:- begin_tests(pr03).

% Define a clause for 'test': succeed when the following conditions hold.
test(open_valid_address, [setup(true), cleanup(lattice_close(Nexus))]) :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/test', Nexus),
    % State the fact: nexus is open(Nexus).
    nexus_is_open(Nexus).

% Define a clause for 'test': succeed when the following conditions hold.
test(open_idempotent) :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/idempotent', N1),
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/idempotent', N2),
    % Check that 'N1' is structurally identical to 'N2'.
    N1 == N2,
    % State the fact: lattice close(N1).
    lattice_close(N1).

% Define a clause for 'test': succeed when the following conditions hold.
test(open_rejects_bad_address, [throws(error(domain_error(nexus_address, bad), _))]) :-
    % State the fact: lattice open(bad, _).
    lattice_open(bad, _).

% Define a clause for 'test': succeed when the following conditions hold.
test(close_marks_closed) :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/close_test', N),
    % State a fact for 'lattice close' with the arguments listed below.
    lattice_close(N),
    % State the fact: nexus state(N, closed).
    nexus_state(N, closed).

% Define a clause for 'test': succeed when the following conditions hold.
test(verify_empty_nexus) :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/verify_test', N),
    % State a fact for 'lattice verify' with the arguments listed below.
    lattice_verify(N),    % sets baseline
    % State a fact for 'lattice verify' with the arguments listed below.
    lattice_verify(N),    % compare matches
    % State the fact: lattice close(N).
    lattice_close(N).

% Define a clause for 'test': succeed when the following conditions hold.
test(transaction_commits) :-
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr03_tx_flag, 0),
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/tx_test', N),
    % State a fact for 'lattice transaction' with the arguments listed below.
    lattice_transaction(N, nb_setval(pr03_tx_flag, 1)),
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr03_tx_flag, 1),
    % State the fact: lattice close(N).
    lattice_close(N).

% Define a clause for 'test': succeed when the following conditions hold.
test(transaction_rollback, [throws(error(tx_test_error, _))]) :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/tx_rollback', N),
    % State a fact for 'lattice transaction' with the arguments listed below.
    lattice_transaction(N, throw(error(tx_test_error, tx_rollback))),
    % State the fact: lattice close(N).
    lattice_close(N).

% Define a clause for 'test': succeed when the following conditions hold.
test(status_fields) :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/status_test', N),
    % State a fact for 'lattice status' with the arguments listed below.
    lattice_status(N, Status),
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(address('locus://localhost/status_test'), Status),
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(state(open), Status),
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(node_facts(0), Status),
    % State the fact: lattice close(N).
    lattice_close(N).

% Define a clause for 'test': succeed when the following conditions hold.
test(dump_writes_file) :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/dump_test', N),
    % Check that 'Tmp' is unifiable with ''/tmp/prologai_test_dump.pl''.
    Tmp = '/tmp/prologai_test_dump.pl',
    % State a fact for 'lattice dump' with the arguments listed below.
    lattice_dump(N, Tmp),
    % State a fact for 'exists file' with the arguments listed below.
    exists_file(Tmp),
    % State the fact: lattice close(N).
    lattice_close(N).

% Execute the compile-time directive: end_tests(pr03).
:- end_tests(pr03).
