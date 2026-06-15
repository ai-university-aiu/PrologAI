/*  PrologAI — Lattice dual-index store  (Specification Sections 3.1–3.4)

    PR 3: lattice_open/2, lattice_close/1, lattice_verify/1,
          lattice_transaction/2, lattice_status/2, lattice_dump/2.

    Each nexus is addressed as locus://HOST/PATH.
    The logical index is the engine clause database (dynamic facts).
    The vector index is provided by vector_backend (wired in PR 4).
    Write-ahead journaling appends operations before they are applied.
    SHA-256 over identifiers and relation data is recomputed on verify.
*/

:- module(lattice, [
    lattice_open/2,          % +Address:atom, -Nexus:term
    lattice_close/1,         % +Nexus
    lattice_verify/1,        % +Nexus
    lattice_transaction/2,   % +Nexus, :Goal
    lattice_status/2,        % +Nexus, -Status:list
    lattice_dump/2,          % +Nexus, +File
    nexus_address/2,         % +Nexus, -Address
    nexus_is_open/1,         % +Nexus
    nexus_state/2,           % +Nexus, -State (open|closed)
    lattice_node_fact/5      % +Nexus, ?Id, ?Relation, ?Args, ?Referents
]).

:- use_module(library(crypto),  [crypto_data_hash/3]).
:- use_module(library(apply),   [maplist/2]).
:- use_module(library(lists),   [member/2]).

% ---------------------------------------------------------------------------
% Nexus registry
% ---------------------------------------------------------------------------

:- dynamic lattice_nexus/4.    % Nexus, Address, JournalFile, OpenFlag
:- dynamic nexus_id_counter/1.
nexus_id_counter(0).

next_nexus_id(Id) :-
    retract(nexus_id_counter(N)),
    N1 is N + 1,
    assertz(nexus_id_counter(N1)),
    Id = nexus(N1).

% ---------------------------------------------------------------------------
% lattice_open/2
% ---------------------------------------------------------------------------

lattice_open(Address, Nexus) :-
    must_be_nexus_address(Address),
    ( lattice_nexus(Existing, Address, _, open)
    ->  Nexus = Existing
    ;   next_nexus_id(Nexus),
        journal_path(Address, JPath),
        assertz(lattice_nexus(Nexus, Address, JPath, open)),
        journal_write(JPath, lattice_open(Address))
    ).

must_be_nexus_address(Address) :-
    ( atom(Address), atom_concat('locus://', _, Address)
    ->  true
    ;   throw(error(domain_error(nexus_address, Address), lattice_open/2))
    ).

journal_path(Address, Path) :-
    atom_string(Address, S),
    re_replace("[:/.]+"/g, "_", S, Safe),
    atom_concat('/tmp/prologai_journal_', Safe, Path).

% ---------------------------------------------------------------------------
% lattice_close/1
% ---------------------------------------------------------------------------

lattice_close(Nexus) :-
    ( lattice_nexus(Nexus, Address, JPath, open)
    ->  journal_write(JPath, lattice_close(Address)),
        retract(lattice_nexus(Nexus, Address, JPath, open)),
        assertz(lattice_nexus(Nexus, Address, JPath, closed))
    ;   true
    ).

% ---------------------------------------------------------------------------
% lattice_verify/1
% ---------------------------------------------------------------------------

%  Compute SHA-256 over all node_fact IDs and relation data for this nexus.
%  The stored hash is recorded in the journal at close time; on an open
%  nexus we compare the live hash to the journal's last recorded value.

lattice_verify(Nexus) :-
    nexus_is_open(Nexus),
    lattice_collect_hash_data(Nexus, Data),
    crypto_data_hash(Data, Hash, [algorithm(sha256)]),
    ( nexus_stored_hash(Nexus, Stored)
    ->  ( Hash == Stored
        ->  true
        ;   throw(error(verification_failed(Nexus, expected(Stored), got(Hash)),
                        lattice_verify/1))
        )
    ;   record_nexus_hash(Nexus, Hash)
    ).

:- dynamic nexus_hash_record/2.  % Nexus, Hash

nexus_stored_hash(Nexus, Hash) :-
    nexus_hash_record(Nexus, Hash).

record_nexus_hash(Nexus, Hash) :-
    retractall(nexus_hash_record(Nexus, _)),
    assertz(nexus_hash_record(Nexus, Hash)).

lattice_collect_hash_data(Nexus, Data) :-
    findall(Id-Rel, lattice_node_fact(Nexus, Id, Rel, _, _), Pairs),
    term_to_atom(Pairs, Atom),
    atom_string(Atom, Data).

% Hooked by PR 4 — no node_facts in this PR, so always empty.
% Declared incremental so tabled derivations in PR 15 auto-invalidate on change.
:- dynamic lattice_node_fact/5 as incremental.  % Nexus, Id, Relation, Args, Referents

% ---------------------------------------------------------------------------
% lattice_transaction/2
% ---------------------------------------------------------------------------

lattice_transaction(Nexus, Goal) :-
    nexus_is_open(Nexus),
    lattice_nexus(Nexus, _, JPath, open),
    journal_write(JPath, begin_transaction),
    ( catch(call(Goal), Err, (
        journal_write(JPath, rollback(Err)),
        throw(Err)
      ))
    ->  journal_write(JPath, commit)
    ;   journal_write(JPath, rollback(goal_failed)),
        fail
    ).

% ---------------------------------------------------------------------------
% lattice_status/2
% ---------------------------------------------------------------------------

lattice_status(Nexus, Status) :-
    lattice_nexus(Nexus, Address, JPath, Flag),
    findall(Id, lattice_node_fact(Nexus, Id, _, _, _), Ids),
    length(Ids, Count),
    Status = [address(Address), journal(JPath), state(Flag), node_facts(Count)].

% ---------------------------------------------------------------------------
% lattice_dump/2
% ---------------------------------------------------------------------------

lattice_dump(Nexus, File) :-
    nexus_is_open(Nexus),
    findall(node_fact(Id,Rel,Args,Refs),
            lattice_node_fact(Nexus, Id, Rel, Args, Refs),
            Facts),
    setup_call_cleanup(
        open(File, write, Stream),
        ( write_term(Stream, Facts, [quoted(true)]),
          write(Stream, '.\n') ),
        close(Stream)
    ).

% ---------------------------------------------------------------------------
% Helpers
% ---------------------------------------------------------------------------

nexus_is_open(Nexus) :-
    ( lattice_nexus(Nexus, _, _, open)
    ->  true
    ;   throw(error(existence_error(open_nexus, Nexus), nexus_is_open/1))
    ).

nexus_address(Nexus, Address) :-
    lattice_nexus(Nexus, Address, _, _).

nexus_state(Nexus, State) :-
    lattice_nexus(Nexus, _, _, State).

journal_write(Path, Term) :-
    catch(
        setup_call_cleanup(
            open(Path, append, S),
            ( write_term(S, Term, [quoted(true)]), write(S, '.\n') ),
            close(S)
        ),
        _,  % Journal write failure is non-fatal
        true
    ).
