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
    lattice_node_fact/5      % +Nexus, ?Id, ?Relation, ?Args, ?Referents
% Close the expression opened above.
]).

% Import [crypto_data_hash/3] from the built-in 'crypto' library.
:- use_module(library(crypto),  [crypto_data_hash/3]).
% Import [maplist/2] from the built-in 'apply' library.
:- use_module(library(apply),   [maplist/2]).
% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),   [member/2]).

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
