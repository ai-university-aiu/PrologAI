/*  PrologAI — Receptors  (Specification Section 3.5, PR 7)

    receptor/2             — create a reactive message-handling endpoint
    send_message/2         — enqueue a message non-blocking
    receptor_decommission/1 — drain backlog then terminate thread
    receptor_backlog_count/2 — count queued messages

    Addresses follow signal://HOST/PATH.
    Implemented on SWI-Prolog message queues and a dedicated handler thread.
*/

:- module(receptor, [
    receptor/2,               % +Address:atom, :Handler
    send_message/2,           % +Address:atom, +Message
    receptor_decommission/1,  % +Address:atom
    receptor_backlog_count/2  % +Address:atom, -Count:integer
]).

:- meta_predicate receptor(+, 1).

:- use_module(library(apply), [maplist/2]).

% ---------------------------------------------------------------------------
% Registry
% ---------------------------------------------------------------------------

:- dynamic receptor_entry/3.   % Address, QueueId, ThreadId

:- initialization(mutex_create(receptor_registry_mutex), now).

reg_lock(Goal) :- with_mutex(receptor_registry_mutex, Goal).

% ---------------------------------------------------------------------------
% receptor/2
% ---------------------------------------------------------------------------

receptor(Address, Handler) :-
    must_be_signal_address(Address),
    ( once(reg_lock(receptor_entry(Address, _, _)))
    ->  true    % idempotent; already registered
    ;   message_queue_create(QueueId, [alias(Address)]),
        term_to_atom(Address, AddrAtom),
        atom_concat(receptor_tid_, AddrAtom, TidAlias),
        thread_create(
            receptor_loop(Address, QueueId, Handler),
            Tid,
            [alias(TidAlias), detached(false)]
        ),
        reg_lock(assertz(receptor_entry(Address, QueueId, Tid)))
    ).

must_be_signal_address(Addr) :-
    ( atom(Addr), atom_concat('signal://', _, Addr)
    ->  true
    ;   throw(error(domain_error(signal_address, Addr), receptor/2))
    ).

% ---------------------------------------------------------------------------
% Handler loop
% ---------------------------------------------------------------------------

receptor_loop(Address, QueueId, Handler) :-
    catch(
        receptor_loop_body(Address, QueueId, Handler),
        receptor_stop(Address),
        true
    ).

receptor_loop_body(Address, QueueId, Handler) :-
    thread_get_message(QueueId, Message),
    catch(
        call(Handler, Message),
        Err,
        print_message(warning, format("receptor ~w handler error: ~w", [Address, Err]))
    ),
    receptor_loop_body(Address, QueueId, Handler).

% ---------------------------------------------------------------------------
% send_message/2  — non-blocking enqueue
% ---------------------------------------------------------------------------

send_message(Address, Message) :-
    ( once(reg_lock(receptor_entry(Address, QueueId, _)))
    ->  thread_send_message(QueueId, Message)
    ;   throw(error(existence_error(receptor, Address), send_message/2))
    ).

% ---------------------------------------------------------------------------
% receptor_decommission/1  — drain backlog, then terminate
% ---------------------------------------------------------------------------

receptor_decommission(Address) :-
    ( once(reg_lock(receptor_entry(Address, QueueId, Tid)))
    ->  % Wait until queue is empty
        drain_queue(QueueId),
        % Signal handler thread to stop
        catch(
            thread_signal(Tid, throw(receptor_stop(Address))),
            _, true
        ),
        catch(thread_join(Tid, _), _, true),
        catch(message_queue_destroy(QueueId), _, true),
        reg_lock(retractall(receptor_entry(Address, _, _)))
    ;   true
    ).

drain_queue(QueueId) :-
    get_time(T0),
    drain_queue_loop(QueueId, T0, 2.0).    % 2-second maximum drain wait

drain_queue_loop(QueueId, T0, MaxWait) :-
    message_queue_property(QueueId, size(N)),
    ( N =:= 0
    ->  true
    ;   get_time(Now),
        Elapsed is Now - T0,
        ( Elapsed < MaxWait
        ->  sleep(0.02),
            drain_queue_loop(QueueId, T0, MaxWait)
        ;   true    % timeout reached; stop waiting
        )
    ).

% ---------------------------------------------------------------------------
% receptor_backlog_count/2
% ---------------------------------------------------------------------------

receptor_backlog_count(Address, Count) :-
    ( once(reg_lock(receptor_entry(Address, QueueId, _)))
    ->  message_queue_property(QueueId, size(Count))
    ;   Count = 0
    ).
