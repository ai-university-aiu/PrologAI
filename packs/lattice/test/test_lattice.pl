/*  In-pack PLUnit suite for the 'lattice' dual-index store  (PR 3 core).

    Exercises the exported nexus lifecycle: open (with address validation and
    idempotence), status reporting, integrity verify, transactional commit,
    and close. Real assertions on outputs — no trivially-passing tests.

    Run (from repo root):
      LIB=""; for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
      swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/lattice/test/test_lattice.pl
*/

% Declare this file as the 'test_lattice' module, exporting nothing.
:- module(test_lattice, []).
% Load the built-in PLUnit test framework so test/1 blocks are recognised.
:- use_module(library(plunit)).
% Load the pack under test so its exported predicates are callable here.
:- use_module(library(lattice)).
% Import memberchk/2 for checking membership in the status list.
:- use_module(library(lists), [memberchk/2]).

% Open the block of tests grouped under the name 'lattice'.
:- begin_tests(lattice).

% A valid locus:// address opens a live nexus that reports itself open.
test(open_valid_address, [cleanup(lattice_close(Nexus))]) :-
    % Open a nexus at a well-formed locus:// address.
    lattice_open('locus://localhost/open_valid', Nexus),
    % Assert the freshly opened nexus is reported open.
    assertion(nexus_is_open(Nexus)),
    % Assert its recorded address round-trips through nexus_address/2.
    assertion(nexus_address(Nexus, 'locus://localhost/open_valid')),
    % Assert its lifecycle state is 'open'.
    assertion(nexus_state(Nexus, open)).

% Opening the same address twice returns the identical nexus handle.
test(open_idempotent, [cleanup(lattice_close(N1))]) :-
    % Open a nexus at a chosen address.
    lattice_open('locus://localhost/idem', N1),
    % Open the same address again.
    lattice_open('locus://localhost/idem', N2),
    % Assert both opens yielded the very same handle.
    assertion(N1 == N2).

% A non-locus address is rejected with a domain_error.
test(open_rejects_bad_address, [throws(error(domain_error(nexus_address, bad), _))]) :-
    % Attempt to open an address that is not a locus:// URI.
    lattice_open(bad, _).

% Closing an open nexus flips its lifecycle state to 'closed'.
test(close_marks_closed) :-
    % Open a nexus to close.
    lattice_open('locus://localhost/close_me', N),
    % Close it.
    lattice_close(N),
    % Assert the nexus now reports the 'closed' state.
    assertion(nexus_state(N, closed)).

% Verify sets a hash baseline on first call and matches it on the second.
test(verify_empty_nexus, [cleanup(lattice_close(N))]) :-
    % Open an empty nexus.
    lattice_open('locus://localhost/verify_me', N),
    % First verify records the SHA-256 baseline over its (empty) node-facts.
    assertion(lattice_verify(N)),
    % Second verify recomputes the same hash and matches the baseline.
    assertion(lattice_verify(N)).

% A transaction whose goal succeeds commits and leaves its side effect in place.
test(transaction_commits, [cleanup(lattice_close(N))]) :-
    % Seed a global flag to a known starting value.
    nb_setval(test_lattice_flag, 0),
    % Open a nexus to run the transaction against.
    lattice_open('locus://localhost/tx_ok', N),
    % Run a transaction that flips the flag to 1.
    lattice_transaction(N, nb_setval(test_lattice_flag, 1)),
    % Read the flag back after commit.
    nb_getval(test_lattice_flag, After),
    % Assert the committed side effect persisted.
    assertion(After == 1).

% A transaction whose goal throws re-throws the error out to the caller.
test(transaction_rollback, [throws(error(test_lattice_boom, _)), cleanup(lattice_close(N))]) :-
    % Open a nexus for the failing transaction.
    lattice_open('locus://localhost/tx_bad', N),
    % Run a transaction whose goal throws; the error must propagate.
    lattice_transaction(N, throw(error(test_lattice_boom, ctx))).

% Status reports the address, the open state, and a zero node-fact count.
test(status_fields, [cleanup(lattice_close(N))]) :-
    % Open a nexus to query.
    lattice_open('locus://localhost/status_me', N),
    % Fetch its status list.
    lattice_status(N, Status),
    % Assert the address field is present.
    assertion(memberchk(address('locus://localhost/status_me'), Status)),
    % Assert the state field reports 'open'.
    assertion(memberchk(state(open), Status)),
    % Assert an empty nexus reports zero node-facts.
    assertion(memberchk(node_facts(0), Status)).

% -------------------------------------------------------------------------
% L1 — lightweight, backend-free write/read door (Ledger entry L1).
% -------------------------------------------------------------------------

% AC-L1-001: a fact can be put and read back with NO vector backend loaded.
test(l1_put_get_backend_free, [cleanup(lattice_close(N))]) :-
    % Open a coordination nexus.
    lattice_open('locus://localhost/l1_pg', N),
    % Store a non-semantic coordination token directly (no embedding index).
    lattice_put(N, beat, [lap(0), phase(0)], []),
    % Read it back with a non-destructive peek.
    assertion(lattice_get(N, beat, [lap(0), phase(0)], [])),
    % The vector backend module must NOT have been pulled in by the write path.
    assertion(\+ current_module(vector_backend)).

% AC-L1-002: replace keeps exactly one fact per relation (a bounded token).
test(l1_replace_bounded, [cleanup(lattice_close(N))]) :-
    % Open a nexus.
    lattice_open('locus://localhost/l1_rep', N),
    % Put an initial beat, then replace it twice.
    lattice_put(N, beat, [lap(0)], []),
    lattice_replace(N, beat, [lap(1)], []),
    lattice_replace(N, beat, [lap(2)], []),
    % Exactly one beat fact remains, holding the latest value.
    findall(A, lattice_get(N, beat, A, _), All),
    assertion(All == [[lap(2)]]).

% AC-L1-003: take reads and removes one matching fact.
test(l1_take_removes, [cleanup(lattice_close(N))]) :-
    % Open a nexus and store one token.
    lattice_open('locus://localhost/l1_take', N),
    lattice_put(N, token, [x], []),
    % Take it: the value comes back and the fact is gone.
    lattice_take(N, token, [x], []),
    assertion(\+ lattice_get(N, token, _, _)).

% Close the block of 'lattice' tests.
:- end_tests(lattice).
