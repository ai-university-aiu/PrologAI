/*  PrologAI — Receptors  (Specification Section 3.5, PR 7)

    receptor/2             — create a reactive message-handling endpoint
    send_message/2         — enqueue a message non-blocking
    receptor_decommission/1 — drain backlog then terminate thread
    receptor_backlog_count/2 — count queued messages

    Addresses follow signal://HOST/PATH.
    Implemented on SWI-Prolog message queues and a dedicated handler thread.
*/

% Declare this file as the 'receptor' module and list its exported predicates.
:- module(receptor, [
    % Continue the multi-line expression started above.
    receptor/2,               % +Address:atom, :Handler
    % Continue the multi-line expression started above.
    send_message/2,           % +Address:atom, +Message
    % Continue the multi-line expression started above.
    receptor_decommission/1,  % +Address:atom
    % Continue the multi-line expression started above.
    receptor_backlog_count/2  % +Address:atom, -Count:integer
% Close the expression opened above.
]).

% Declare the following predicate as accepting callable (higher-order) arguments.
:- meta_predicate receptor(+, 1).

% Import [maplist/2] from the built-in 'apply' library.
:- use_module(library(apply), [maplist/2]).

% ---------------------------------------------------------------------------
% Registry
% ---------------------------------------------------------------------------

% Declare 'receptor_entry/3.   % Address, QueueId, ThreadId' as dynamic — its facts may be added or removed at runtime.
:- dynamic receptor_entry/3.   % Address, QueueId, ThreadId

% Register the following goal to run automatically at load time.
:- initialization(mutex_create(receptor_registry_mutex), now).

% Define a clause for 'reg lock': succeed when the following conditions hold.
reg_lock(Goal) :- with_mutex(receptor_registry_mutex, Goal).

% ---------------------------------------------------------------------------
% receptor/2
% ---------------------------------------------------------------------------

% Define a clause for 'receptor': succeed when the following conditions hold.
receptor(Address, Handler) :-
    % State a fact for 'must be signal address' with the arguments listed below.
    must_be_signal_address(Address),
    % Execute: ( once(reg_lock(receptor_entry(Address, _, _))).
    ( once(reg_lock(receptor_entry(Address, _, _)))
    % If the condition above succeeded, perform the following action.
    ->  true    % idempotent; already registered
    % Otherwise (else branch), perform the following action.
    ;   message_queue_create(QueueId, [alias(Address)]),
        % Continue the multi-line expression started above.
        term_to_atom(Address, AddrAtom),
        % Continue the multi-line expression started above.
        atom_concat(receptor_tid_, AddrAtom, TidAlias),
        % Continue the multi-line expression started above.
        thread_create(
            % Continue the multi-line expression started above.
            receptor_loop(Address, QueueId, Handler),
            % Supply 'Tid' as the next argument to the expression above.
            Tid,
            % Continue the multi-line expression started above.
            [alias(TidAlias), detached(false)]
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        reg_lock(assertz(receptor_entry(Address, QueueId, Tid)))
    % Close the expression opened above.
    ).

% Define a clause for 'must be signal address': succeed when the following conditions hold.
must_be_signal_address(Addr) :-
    % Execute: ( atom(Addr), atom_concat('signal://', _, Addr).
    ( atom(Addr), atom_concat('signal://', _, Addr)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   throw(error(domain_error(signal_address, Addr), receptor/2))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Handler loop
% ---------------------------------------------------------------------------

% Define a clause for 'receptor loop': succeed when the following conditions hold.
receptor_loop(Address, QueueId, Handler) :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        receptor_loop_body(Address, QueueId, Handler),
        % Continue the multi-line expression started above.
        receptor_stop(Address),
        % Supply 'true' as the next argument to the expression above.
        true
    % Close the expression opened above.
    ).

% Define a clause for 'receptor loop body': succeed when the following conditions hold.
receptor_loop_body(Address, QueueId, Handler) :-
    % State a fact for 'thread get message' with the arguments listed below.
    thread_get_message(QueueId, Message),
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        call(Handler, Message),
        % Supply 'Err' as the next argument to the expression above.
        Err,
        % Continue the multi-line expression started above.
        print_message(warning, format("receptor ~w handler error: ~w", [Address, Err]))
    % Close the expression opened above.
    ),
    % State the fact: receptor loop body(Address, QueueId, Handler).
    receptor_loop_body(Address, QueueId, Handler).

% ---------------------------------------------------------------------------
% send_message/2  — non-blocking enqueue
% ---------------------------------------------------------------------------

% Define a clause for 'send message': succeed when the following conditions hold.
send_message(Address, Message) :-
    % Execute: ( once(reg_lock(receptor_entry(Address, QueueId, _))).
    ( once(reg_lock(receptor_entry(Address, QueueId, _)))
    % If the condition above succeeded, perform the following action.
    ->  thread_send_message(QueueId, Message)
    % Otherwise (else branch), perform the following action.
    ;   throw(error(existence_error(receptor, Address), send_message/2))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% receptor_decommission/1  — drain backlog, then terminate
% ---------------------------------------------------------------------------

% Define a clause for 'receptor decommission': succeed when the following conditions hold.
receptor_decommission(Address) :-
    % Execute: ( once(reg_lock(receptor_entry(Address, QueueId, Tid))).
    ( once(reg_lock(receptor_entry(Address, QueueId, Tid)))
    % If the condition above succeeded, perform the following action.
    ->  % Wait until queue is empty
        % Continue the multi-line expression started above.
        drain_queue(QueueId),
        % Signal handler thread to stop
        % Continue the multi-line expression started above.
        catch(
            % Continue the multi-line expression started above.
            thread_signal(Tid, throw(receptor_stop(Address))),
            % Continue the multi-line expression started above.
            _, true
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        catch(thread_join(Tid, _), _, true),
        % Continue the multi-line expression started above.
        catch(message_queue_destroy(QueueId), _, true),
        % Continue the multi-line expression started above.
        reg_lock(retractall(receptor_entry(Address, _, _)))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Define a clause for 'drain queue': succeed when the following conditions hold.
drain_queue(QueueId) :-
    % State a fact for 'get time' with the arguments listed below.
    get_time(T0),
    % State a fact for 'drain queue loop' with the arguments listed below.
    drain_queue_loop(QueueId, T0, 2.0).    % 2-second maximum drain wait

% Define a clause for 'drain queue loop': succeed when the following conditions hold.
drain_queue_loop(QueueId, T0, MaxWait) :-
    % State a fact for 'message queue property' with the arguments listed below.
    message_queue_property(QueueId, size(N)),
    % Check that '( N' is numerically equal to '0'.
    ( N =:= 0
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   get_time(Now),
        % Continue the multi-line expression started above.
        Elapsed is Now - T0,
        % Continue the multi-line expression started above.
        ( Elapsed < MaxWait
        % If the condition above succeeded, perform the following action.
        ->  sleep(0.02),
            % Continue the multi-line expression started above.
            drain_queue_loop(QueueId, T0, MaxWait)
        % Otherwise (else branch), perform the following action.
        ;   true    % timeout reached; stop waiting
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% receptor_backlog_count/2
% ---------------------------------------------------------------------------

% Define a clause for 'receptor backlog count': succeed when the following conditions hold.
receptor_backlog_count(Address, Count) :-
    % Execute: ( once(reg_lock(receptor_entry(Address, QueueId, _))).
    ( once(reg_lock(receptor_entry(Address, QueueId, _)))
    % If the condition above succeeded, perform the following action.
    ->  message_queue_property(QueueId, size(Count))
    % Otherwise (else branch), perform the following action.
    ;   Count = 0
    % Close the expression opened above.
    ).
