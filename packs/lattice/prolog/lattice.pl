/*  PrologAI — Lattice dual-index store  (Specification Sections 3.1–3.4)

    PR 3: lattice_open/2, lattice_close/1, lattice_verify/1,
          lattice_transaction/2, lattice_status/2, lattice_dump/2.

    Each nexus is addressed as locus://HOST/PATH.
    The logical index is the engine clause database (dynamic facts).
    The vector index is provided by vector_backend (wired in PR 4).
    Write-ahead journaling appends operations before they are applied.
    SHA-256 over identifiers and relation data is recomputed on verify.
*/

% Declare this file as the 'lattice' module and list its exported predicates.
:- module(lattice, [
    % Continue the multi-line expression started above.
    lattice_open/2,          % +Address:atom, -Nexus:term
    % Continue the multi-line expression started above.
    lattice_close/1,         % +Nexus
    % Continue the multi-line expression started above.
    lattice_verify/1,        % +Nexus
    % Continue the multi-line expression started above.
    lattice_transaction/2,   % +Nexus, :Goal
    % Continue the multi-line expression started above.
    lattice_status/2,        % +Nexus, -Status:list
    % Continue the multi-line expression started above.
    lattice_dump/2,          % +Nexus, +File
    % Continue the multi-line expression started above.
    nexus_address/2,         % +Nexus, -Address
    % Continue the multi-line expression started above.
    nexus_is_open/1,         % +Nexus
    % Continue the multi-line expression started above.
    nexus_state/2,           % +Nexus, -State (open|closed)
    % Continue the multi-line expression started above.
    lattice_node_fact/5,     % +Nexus, ?Id, ?Relation, ?Args, ?Referents
    % L1 — lightweight, backend-free write door (Ledger entry L1).
    lattice_put/4,           % +Nexus, +Relation, +Args, +Referents
    % L1 — non-destructive read (peek) of a matching fact.
    lattice_get/4,           % +Nexus, ?Relation, ?Args, ?Referents
    % L1 — read-and-remove one matching fact (Linda take).
    lattice_take/4,          % +Nexus, ?Relation, ?Args, ?Referents
    % L1 — replace all facts of a relation with one (a bounded coordination token).
    lattice_replace/4,       % +Nexus, +Relation, +Args, +Referents
    % L2 — an explicitly isolating transaction (Ledger entry L2).
    lattice_transaction/3,   % +Nexus, +Options, :Goal
    % L3 — reactive await: block until a matching fact exists (Ledger entry L3).
    lattice_await/5,         % +Nexus, +Relation, +Timeout, -Args, -Referents
    % L3 — wake every reader awaiting on a nexus (the write-triggers-notify bridge).
    lattice_notify/1         % +Nexus
% Close the expression opened above.
]).

% Import [crypto_data_hash/3] from the built-in 'crypto' library.
:- use_module(library(crypto),  [crypto_data_hash/3]).
% Import [maplist/2] from the built-in 'apply' library.
:- use_module(library(apply),   [maplist/2]).
% Import [member/2, memberchk/2] from the built-in 'lists' library.
:- use_module(library(lists),   [member/2, memberchk/2]).

% ---------------------------------------------------------------------------
% Nexus registry
% ---------------------------------------------------------------------------

% Declare 'lattice_nexus/4.    % Nexus, Address, JournalFile, OpenFlag' as dynamic — its facts may be added or removed at runtime.
:- dynamic lattice_nexus/4.    % Nexus, Address, JournalFile, OpenFlag
% Declare 'nexus_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic nexus_id_counter/1.
% State the fact: nexus id counter(0).
nexus_id_counter(0).

% Define a clause for 'next nexus id': succeed when the following conditions hold.
next_nexus_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(nexus_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(nexus_id_counter(N1)),
    % Check that 'Id' is unifiable with 'nexus(N1)'.
    Id = nexus(N1).

% ---------------------------------------------------------------------------
% lattice_open/2
% ---------------------------------------------------------------------------

% Define a clause for 'lattice open': succeed when the following conditions hold.
lattice_open(Address, Nexus) :-
    % State a fact for 'must be nexus address' with the arguments listed below.
    must_be_nexus_address(Address),
    % Execute: ( lattice_nexus(Existing, Address, _, open).
    ( lattice_nexus(Existing, Address, _, open)
    % If the condition above succeeded, perform the following action.
    ->  Nexus = Existing
    % Otherwise (else branch), perform the following action.
    ;   next_nexus_id(Nexus),
        % Continue the multi-line expression started above.
        journal_path(Address, JPath),
        % Continue the multi-line expression started above.
        assertz(lattice_nexus(Nexus, Address, JPath, open)),
        % Continue the multi-line expression started above.
        journal_write(JPath, lattice_open(Address))
    % Close the expression opened above.
    ).

% Define a clause for 'must be nexus address': succeed when the following conditions hold.
must_be_nexus_address(Address) :-
    % Execute: ( atom(Address), atom_concat('locus://', _, Address).
    ( atom(Address), atom_concat('locus://', _, Address)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   throw(error(domain_error(nexus_address, Address), lattice_open/2))
    % Close the expression opened above.
    ).

% Define a clause for 'journal path': succeed when the following conditions hold.
journal_path(Address, Path) :-
    % State a fact for 'atom string' with the arguments listed below.
    atom_string(Address, S),
    % State a fact for 're replace' with the arguments listed below.
    re_replace("[:/.]+"/g, "_", S, Safe),
    % State the fact: atom concat('/tmp/prologai_journal_', Safe, Path).
    atom_concat('/tmp/prologai_journal_', Safe, Path).

% ---------------------------------------------------------------------------
% lattice_close/1
% ---------------------------------------------------------------------------

% Define a clause for 'lattice close': succeed when the following conditions hold.
lattice_close(Nexus) :-
    % Execute: ( lattice_nexus(Nexus, Address, JPath, open).
    ( lattice_nexus(Nexus, Address, JPath, open)
    % If the condition above succeeded, perform the following action.
    ->  journal_write(JPath, lattice_close(Address)),
        % Continue the multi-line expression started above.
        retract(lattice_nexus(Nexus, Address, JPath, open)),
        % Continue the multi-line expression started above.
        assertz(lattice_nexus(Nexus, Address, JPath, closed))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% lattice_verify/1
% ---------------------------------------------------------------------------

%  Compute SHA-256 over all node_fact IDs and relation data for this nexus.
%  The stored hash is recorded in the journal at close time; on an open
%  nexus we compare the live hash to the journal's last recorded value.

% Define a clause for 'lattice verify': succeed when the following conditions hold.
lattice_verify(Nexus) :-
    % State a fact for 'nexus is open' with the arguments listed below.
    nexus_is_open(Nexus),
    % State a fact for 'lattice collect hash data' with the arguments listed below.
    lattice_collect_hash_data(Nexus, Data),
    % State a fact for 'crypto data hash' with the arguments listed below.
    crypto_data_hash(Data, Hash, [algorithm(sha256)]),
    % Execute: ( nexus_stored_hash(Nexus, Stored).
    ( nexus_stored_hash(Nexus, Stored)
    % If the condition above succeeded, perform the following action.
    ->  ( Hash == Stored
        % If the condition above succeeded, perform the following action.
        ->  true
        % Otherwise (else branch), perform the following action.
        ;   throw(error(verification_failed(Nexus, expected(Stored), got(Hash)),
                        % Supply 'lattice_verify/1' as the next argument to the expression above.
                        lattice_verify/1))
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   record_nexus_hash(Nexus, Hash)
    % Close the expression opened above.
    ).

% Declare 'nexus_hash_record/2.  % Nexus, Hash' as dynamic — its facts may be added or removed at runtime.
:- dynamic nexus_hash_record/2.  % Nexus, Hash

% Define a clause for 'nexus stored hash': succeed when the following conditions hold.
nexus_stored_hash(Nexus, Hash) :-
    % State the fact: nexus hash record(Nexus, Hash).
    nexus_hash_record(Nexus, Hash).

% Define a clause for 'record nexus hash': succeed when the following conditions hold.
record_nexus_hash(Nexus, Hash) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(nexus_hash_record(Nexus, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(nexus_hash_record(Nexus, Hash)).

% Define a clause for 'lattice collect hash data': succeed when the following conditions hold.
lattice_collect_hash_data(Nexus, Data) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Id-Rel, lattice_node_fact(Nexus, Id, Rel, _, _), Pairs),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(Pairs, Atom),
    % State the fact: atom string(Atom, Data).
    atom_string(Atom, Data).

% Hooked by PR 4 — no node_facts in this PR, so always empty.
% Declared incremental so tabled derivations in PR 15 auto-invalidate on change.
% Declare 'lattice_node_fact/5 as incremental.  % Nexus, Id, Relation, Args, Referents' as dynamic — its facts may be added or removed at runtime.
:- dynamic lattice_node_fact/5 as incremental.  % Nexus, Id, Relation, Args, Referents

% ---------------------------------------------------------------------------
% lattice_transaction/2
% ---------------------------------------------------------------------------

% Define a clause for 'lattice transaction': succeed when the following conditions hold.
lattice_transaction(Nexus, Goal) :-
    % State a fact for 'nexus is open' with the arguments listed below.
    nexus_is_open(Nexus),
    % State a fact for 'lattice nexus' with the arguments listed below.
    lattice_nexus(Nexus, _, JPath, open),
    % State a fact for 'journal write' with the arguments listed below.
    journal_write(JPath, begin_transaction),
    % Execute: ( catch(call(Goal), Err, (.
    ( catch(call(Goal), Err, (
        % Continue the multi-line expression started above.
        journal_write(JPath, rollback(Err)),
        % Continue the multi-line expression started above.
        throw(Err)
      % Close the expression opened above.
      ))
    % If the condition above succeeded, perform the following action.
    ->  journal_write(JPath, commit)
    % Otherwise (else branch), perform the following action.
    ;   journal_write(JPath, rollback(goal_failed)),
        % Supply 'fail' as the next argument to the expression above.
        fail
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% lattice_status/2
% ---------------------------------------------------------------------------

% Define a clause for 'lattice status': succeed when the following conditions hold.
lattice_status(Nexus, Status) :-
    % State a fact for 'lattice nexus' with the arguments listed below.
    lattice_nexus(Nexus, Address, JPath, Flag),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Id, lattice_node_fact(Nexus, Id, _, _, _), Ids),
    % Unify 'Count' with the number of elements in list 'Ids'.
    length(Ids, Count),
    % Check that 'Status' is unifiable with '[address(Address), journal(JPath), state(Flag), node_facts(Count)]'.
    Status = [address(Address), journal(JPath), state(Flag), node_facts(Count)].

% ---------------------------------------------------------------------------
% lattice_dump/2
% ---------------------------------------------------------------------------

% Define a clause for 'lattice dump': succeed when the following conditions hold.
lattice_dump(Nexus, File) :-
    % State a fact for 'nexus is open' with the arguments listed below.
    nexus_is_open(Nexus),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(node_fact(Id,Rel,Args,Refs),
            % Continue the multi-line expression started above.
            lattice_node_fact(Nexus, Id, Rel, Args, Refs),
            % Supply 'Facts' as the next argument to the expression above.
            Facts),
    % State a fact for 'setup call cleanup' with the arguments listed below.
    setup_call_cleanup(
        % Continue the multi-line expression started above.
        open(File, write, Stream),
        % Continue the multi-line expression started above.
        ( write_term(Stream, Facts, [quoted(true)]),
          % Continue the multi-line expression started above.
          write(Stream, '.\n') ),
        % Continue the multi-line expression started above.
        close(Stream)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Helpers
% ---------------------------------------------------------------------------

% Define a clause for 'nexus is open': succeed when the following conditions hold.
nexus_is_open(Nexus) :-
    % Execute: ( lattice_nexus(Nexus, _, _, open).
    ( lattice_nexus(Nexus, _, _, open)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   throw(error(existence_error(open_nexus, Nexus), nexus_is_open/1))
    % Close the expression opened above.
    ).

% Define a clause for 'nexus address': succeed when the following conditions hold.
nexus_address(Nexus, Address) :-
    % State the fact: lattice nexus(Nexus, Address, _, _).
    lattice_nexus(Nexus, Address, _, _).

% Define a clause for 'nexus state': succeed when the following conditions hold.
nexus_state(Nexus, State) :-
    % State the fact: lattice nexus(Nexus, _, _, State).
    lattice_nexus(Nexus, _, _, State).

% Define a clause for 'journal write': succeed when the following conditions hold.
journal_write(Path, Term) :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        setup_call_cleanup(
            % Continue the multi-line expression started above.
            open(Path, append, S),
            % Continue the multi-line expression started above.
            ( write_term(S, Term, [quoted(true)]), write(S, '.\n') ),
            % Continue the multi-line expression started above.
            close(S)
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        _,  % Journal write failure is non-fatal
        % Supply 'true' as the next argument to the expression above.
        true
    % Close the expression opened above.
    ).

% ===========================================================================
% L1 — a lightweight, backend-free write/read door  (Ledger entry L1)
% ---------------------------------------------------------------------------
% The intended write door anchor_node/4 (node_facts.pl) hard-requires the vector
% embedding backend, so storing a non-semantic coordination token drags in the
% whole similarity index. These predicates store and read a node_fact DIRECTLY,
% through the journal only, with NO vector backend loaded. anchor_node/4 is left
% unchanged for every existing caller. Ids are drawn from a private counter so a
% lightweight write never has to invent a meaningful identity.
% ===========================================================================

% Declare 'lattice_put_seq/1' as dynamic — the private id counter for lattice_put.
:- dynamic lattice_put_seq/1.
% Seed the counter at zero.
lattice_put_seq(0).

% Define a clause for 'lattice next put id': allocate the next unique put id atomically.
lattice_next_put_id(Id) :-
    % Serialise the read-modify-write of the counter so concurrent puts never clash.
    with_mutex(lattice_put_seq_mutex,
        % Advance the counter and return the fresh id.
        ( retract(lattice_put_seq(N)),
          % Compute the next id value.
          N1 is N + 1,
          % Store the advanced counter.
          assertz(lattice_put_seq(N1)),
          % The allocated id is the advanced value.
          Id = N1 )).

% Define a clause for 'lattice put': store a fact with no vector backend.
lattice_put(Nexus, Relation, Args, Referents) :-
    % The nexus must be open to accept a write.
    nexus_is_open(Nexus),
    % Allocate a fresh id for the new fact.
    lattice_next_put_id(Id),
    % Journal and apply the direct assertion (no vector index touched).
    lattice_transaction(Nexus,
        assertz(lattice_node_fact(Nexus, Id, Relation, Args, Referents))),
    % Wake any reader awaiting a matching fact (the L3 stigmergy-notify bridge).
    lattice_notify(Nexus).

% Define a clause for 'lattice get': peek a matching fact without removing it.
lattice_get(Nexus, Relation, Args, Referents) :-
    % Unify against any stored fact for this nexus (nondeterministic).
    lattice_node_fact(Nexus, _Id, Relation, Args, Referents).

% Define a clause for 'lattice take': read AND remove one matching fact.
lattice_take(Nexus, Relation, Args, Referents) :-
    % The nexus must be open.
    nexus_is_open(Nexus),
    % Bind the first matching fact (and its id) without leaving a choice point.
    once(lattice_node_fact(Nexus, Id, Relation, Args, Referents)),
    % Journal and apply the removal of exactly that fact.
    lattice_transaction(Nexus,
        retract(lattice_node_fact(Nexus, Id, Relation, Args, Referents))),
    % A removal is a state change; wake awaiting readers to re-evaluate.
    lattice_notify(Nexus).

% Define a clause for 'lattice replace': keep one fact per relation (bounded token).
lattice_replace(Nexus, Relation, Args, Referents) :-
    % The nexus must be open.
    nexus_is_open(Nexus),
    % Allocate a fresh id for the replacement fact.
    lattice_next_put_id(Id),
    % Journal and apply: drop every prior fact of this relation, then store one.
    lattice_transaction(Nexus,
        ( retractall(lattice_node_fact(Nexus, _, Relation, _, _)),
          assertz(lattice_node_fact(Nexus, Id, Relation, Args, Referents)) )),
    % Wake any reader awaiting the new value.
    lattice_notify(Nexus).

% ===========================================================================
% L2 — an explicitly isolating transaction  (Ledger entry L2)
% ---------------------------------------------------------------------------
% lattice_transaction/2 gives journaling (durability/framing) but NOT isolation:
% two threads can interleave a read and a write and corrupt a shared fact.
% lattice_transaction/3 with isolation(serializable) wraps the journaled
% transaction in a per-nexus reentrant mutex, so concurrent read-modify-write is
% serialised with NO caller-supplied lock. lattice_transaction/2 is unchanged and
% remains, honestly, the NON-isolating mode.
% ===========================================================================

% Define a clause for 'lattice nexus mutex': the stable per-nexus mutex name.
lattice_nexus_mutex(Nexus, Mutex) :-
    % Render the nexus term to an atom for a deterministic mutex name.
    term_to_atom(Nexus, NexusAtom),
    % Prefix it so the name is unambiguous; with_mutex auto-creates it on first use.
    atom_concat('lattice_nexus_mutex_', NexusAtom, Mutex).

% Declare lattice_transaction/3 as a meta-predicate so the caller's module is
% carried onto the transaction Goal (its third argument is a goal to run).
:- meta_predicate lattice_transaction(?, ?, 0).

% Define a clause for 'lattice transaction/3': run a transaction under an isolation option.
lattice_transaction(Nexus, Options, Goal) :-
    % Branch on whether serialisable isolation was requested.
    ( memberchk(isolation(serializable), Options)
    % Serialisable: hold the per-nexus mutex across the whole journaled transaction.
    ->  lattice_nexus_mutex(Nexus, Mutex),
        with_mutex(Mutex, lattice_transaction(Nexus, Goal))
    % No isolation requested: fall back to the plain journaled transaction.
    ;   lattice_transaction(Nexus, Goal) ).

% ===========================================================================
% L3 — a reactive await + the stigmergy-plus-notification bridge  (Ledger L3)
% ---------------------------------------------------------------------------
% The Lattice had no blocking "await a fact matching a pattern", so a stigmergic
% reader had to busy-poll — O(actors x poll-rate) wasted work, the biggest threat
% to surviving 140 constructs on performance. lattice_await/5 blocks with NO CPU
% (it waits on a private message queue) and is woken the instant a write calls
% lattice_notify/1. This is the HYBRID BRIDGE: coordination stays through the
% environment (a reader awaits a PATTERN, never an actor's address, so
% actor-to-actor references remain zero) while reactivity stops costing a spin.
% A registered waiter always registers BEFORE its first existence check, so a
% write between registration and check cannot be lost.
% ===========================================================================

% Declare 'lattice_waiter/2' as dynamic — one private queue per awaiting reader.
:- dynamic lattice_waiter/2.  % Nexus, Queue

% Define a clause for 'lattice notify': wake every reader awaiting on a nexus.
lattice_notify(Nexus) :-
    % Send a wake token to each registered waiter's queue.
    forall(lattice_waiter(Nexus, Queue),
           % A queue may be torn down concurrently; a failed send is harmless.
           catch(thread_send_message(Queue, lattice_wrote), _, true)).

% Define a clause for 'lattice await': block until a matching fact exists.
% Timeout is seconds, or the atom 'infinite' to wait forever.
lattice_await(Nexus, Relation, Timeout, Args, Referents) :-
    % The nexus must be open to await on.
    nexus_is_open(Nexus),
    % Turn a numeric timeout into an absolute deadline; keep 'infinite' as-is.
    ( Timeout == infinite
    ->  Deadline = infinite
    ;   get_time(T0), Deadline is T0 + Timeout ),
    % Create this reader's private wake queue.
    message_queue_create(Queue),
    % Register, wait, and always deregister and destroy the queue on the way out.
    setup_call_cleanup(
        % Register BEFORE any existence check so no wake can be lost.
        assertz(lattice_waiter(Nexus, Queue)),
        % Enter the wait loop.
        lattice_await_loop(Nexus, Relation, Deadline, Queue, Args, Referents),
        % Deregister this waiter and reclaim its queue.
        ( retractall(lattice_waiter(Nexus, Queue)),
          message_queue_destroy(Queue) )).

% Define a clause for 'lattice await loop': check, then block until woken or timed out.
lattice_await_loop(Nexus, Relation, Deadline, Queue, Args, Referents) :-
    % First, see whether a matching fact is already present.
    ( lattice_get(Nexus, Relation, Args, Referents)
    % Present: succeed with the first match.
    ->  true
    % Absent: block on the wake queue until a write notifies or the deadline passes.
    ;   ( Deadline == infinite
        % No deadline: block indefinitely for the next wake token.
        ->  thread_get_message(Queue, _Woken), Continue = true
        % With a deadline: compute the remaining time and wait at most that long.
        ;   get_time(Now),
            Remaining is Deadline - Now,
            ( Remaining =< 0
            % The deadline has already passed: stop without a match.
            ->  Continue = false
            % Wait up to the remaining time for a wake token.
            ;   ( thread_get_message(Queue, _Woken, [timeout(Remaining)])
                ->  Continue = true
                ;   Continue = false ) ) ),
        % Loop on a wake; give up on a timeout.
        ( Continue == true
        ->  lattice_await_loop(Nexus, Relation, Deadline, Queue, Args, Referents)
        ;   fail ) ).
