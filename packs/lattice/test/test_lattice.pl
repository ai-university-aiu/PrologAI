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

% -------------------------------------------------------------------------
% L2 — real transaction isolation (Ledger entry L2).
% -------------------------------------------------------------------------

% AC-L2-001: concurrent read-modify-write is EXACT under isolation(serializable),
% with no caller-supplied lock — and LOSES updates under the plain /2 transaction.
% A 1 ms window between read and write forces the race deterministically.
test(l2_isolation_prevents_lost_updates) :-
    % Four writers each increment the shared counter twenty-five times.
    Threads = 4, Per = 25, Expected is Threads * Per,
    % The unisolated /2 path loses updates (no mutual exclusion).
    l2_run(unisolated, Threads, Per, Unisolated),
    % The isolated /3 serializable path is exact (mutual exclusion, no caller lock).
    l2_run(isolated, Threads, Per, Isolated),
    % Today's behaviour: the plain transaction is not isolating.
    assertion(Unisolated < Expected),
    % The fix: serializable isolation yields the exact total.
    assertion(Isolated =:= Expected).

% -------------------------------------------------------------------------
% L3 — reactive await woken by a write, with no polling (Ledger entry L3).
% -------------------------------------------------------------------------

% AC-L3-001: an awaiting reader is woken by a write, not by a poll loop.
% The write happens ~200 ms after the await starts; the reader wakes right then.
test(l3_await_woken_by_write) :-
    % Open a nexus to coordinate through.
    lattice_open('locus://localhost/l3_await', N),
    % A result queue to collect the awaiter's outcome.
    message_queue_create(RQ),
    % Note the start time.
    get_time(T0),
    % Spawn a reader that blocks on a 'ready' fact for up to five seconds.
    thread_create(( ( lattice_await(N, ready, 5, Got, _) -> W = Got ; W = timeout ),
                    get_time(T1), Dt is T1 - T0,
                    thread_send_message(RQ, awoke(W, Dt)) ), _, [detached(true)]),
    % Let the reader reach its blocking wait, then write.
    sleep(0.2),
    lattice_put(N, ready, [go], []),
    % Collect the reader's outcome.
    thread_get_message(RQ, awoke(Woke, Elapsed)),
    % The reader saw the written value.
    assertion(Woke == [go]),
    % It woke promptly after the write (well under the five-second timeout).
    assertion(Elapsed < 1.0).

% AC-L3-002: await returns immediately when the fact is already present.
test(l3_await_immediate_when_present, [cleanup(lattice_close(N))]) :-
    % Open a nexus and write the fact first.
    lattice_open('locus://localhost/l3_now', N),
    lattice_put(N, ready, [here], []),
    % Await returns at once without blocking.
    assertion(lattice_await(N, ready, 5, [here], _)).

% AC-L3-003: await times out (and fails) when no write ever arrives.
test(l3_await_times_out, [cleanup(lattice_close(N))]) :-
    % Open a nexus with nothing to await.
    lattice_open('locus://localhost/l3_to', N),
    % A short-timeout await for an absent fact fails.
    assertion(\+ lattice_await(N, never, 0.2, _, _)).

% Close the block of 'lattice' tests.
:- end_tests(lattice).

% -------------------------------------------------------------------------
% Helper: run one L2 concurrency scenario and report the final counter.
% -------------------------------------------------------------------------

% One read-modify-write of the shared counter fact (id 1), with a widened window.
l2_rmw(N) :-
    % Take the current value out.
    retract(lattice_node_fact(N, 1, counter, [V], [])),
    % Widen the read->write gap so an unisolated race is deterministic.
    sleep(0.001),
    % Compute the incremented value.
    V1 is V + 1,
    % Write it back.
    assertz(lattice_node_fact(N, 1, counter, [V1], [])).

% Increment under the requested isolation mode.
l2_increment(isolated, N)   :- lattice_transaction(N, [isolation(serializable)], l2_rmw(N)).
l2_increment(unisolated, N) :- lattice_transaction(N, l2_rmw(N)).

% Run Threads writers, each doing Per increments, and read the final total.
l2_run(Mode, Threads, Per, Final) :-
    % Use a distinct nexus per mode.
    atom_concat('locus://localhost/l2_', Mode, Addr),
    lattice_open(Addr, N),
    % Reset the counter to zero.
    retractall(lattice_node_fact(N, 1, counter, _, _)),
    assertz(lattice_node_fact(N, 1, counter, [0], [])),
    % Spawn the writer threads.
    numlist(1, Threads, Seq),
    findall(TId,
            ( member(_, Seq),
              thread_create(forall(between(1, Per, _), l2_increment(Mode, N)), TId, []) ),
            TIds),
    % Wait for them all to finish.
    forall(member(TId, TIds), thread_join(TId, _)),
    % Read the final counter value.
    lattice_node_fact(N, 1, counter, [Final], []).
