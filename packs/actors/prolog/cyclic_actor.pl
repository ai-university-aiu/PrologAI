/*  PrologAI — Cyclic Actors  (Specification Section 3.5, PR 6)

    cyclic_actor/3     — start a proactive background thread
    cyclic_actor_stop/1  — gracefully stop an actor; blocks until exited
    cyclic_actor_list/1  — list all running actor names
    cyclic_actor_status/2 — cycle_count, error_count, state
    actors_declare_actor/3  — load-time hook called from .pai cyclic_actor/3 expansion

    Actor names are globally unique.  Duplicate creation throws
    actor_error(already_exists, Name).

    The registry mutex (actor_registry_mutex) protects all reads and
    writes of the actor_entry dynamic predicate.
*/

% Declare this file as the 'cyclic_actor' module and list its exported predicates.
:- module(cyclic_actor, [
    % Continue the multi-line expression started above.
    cyclic_actor/3,        % +Name, :Goal, +DelayMs
    % Continue the multi-line expression started above.
    cyclic_actor_stop/1,   % +Name
    % Continue the multi-line expression started above.
    cyclic_actor_list/1,   % -Names
    % Continue the multi-line expression started above.
    cyclic_actor_status/2, % +Name, -Status
    % Continue the multi-line expression started above.
    actors_declare_actor/3    % +Name, :Goal, +DelayMs  (expansion hook)
% Close the expression opened above.
]).

% Declare the following predicate as accepting callable (higher-order) arguments.
:- meta_predicate cyclic_actor(+, 0, +).
% Declare the following predicate as accepting callable (higher-order) arguments.
:- meta_predicate actors_declare_actor(+, 0, +).

% Import [maplist/2] from the built-in 'apply' library.
:- use_module(library(apply), [maplist/2]).

% ---------------------------------------------------------------------------
% Registry
% ---------------------------------------------------------------------------

% Declare 'actor_entry/2.          % Name, ThreadId' as dynamic — its facts may be added or removed at runtime.
:- dynamic actor_entry/2.          % Name, ThreadId

% Declare 'actor_stop_requested/1' as dynamic — a per-actor stop flag set by
% cyclic_actor_stop so the loop exits at the next cycle boundary even if the
% thread_signal interrupt is missed while a cycle goal is wedged on a lock.
:- dynamic actor_stop_requested/1.

% Register the following goal to run automatically at load time.
:- initialization(mutex_create(actor_registry_mutex), now).

% Define a clause for 'registry lock': succeed when the following conditions hold.
registry_lock(Goal) :-
    % State the fact: with mutex(actor_registry_mutex, Goal).
    with_mutex(actor_registry_mutex, Goal).

% Define a clause for 'register actor': succeed when the following conditions hold.
register_actor(Name, Tid) :-
    % State the fact: registry lock(assertz(actor_entry(Name, Tid))).
    registry_lock(assertz(actor_entry(Name, Tid))).

% Define a clause for 'deregister actor': succeed when the following conditions hold.
deregister_actor(Name) :-
    % State the fact: registry lock(retractall(actor_entry(Name, _))).
    registry_lock(retractall(actor_entry(Name, _))).

% ---------------------------------------------------------------------------
% Per-actor counters using flag/3 (shared atomic integer across threads)
% ---------------------------------------------------------------------------

% Define a clause for 'actor flag name': succeed when the following conditions hold.
actor_flag_name(Name, cycle,  K) :- !, atomic_list_concat([pac_, Name, '_c'], K).
% Define a clause for 'actor flag name': succeed when the following conditions hold.
actor_flag_name(Name, errors, K) :- !, atomic_list_concat([pac_, Name, '_e'], K).

% Define a clause for 'init actor counts': succeed when the following conditions hold.
init_actor_counts(Name) :-
    % State a fact for 'actor flag name' with the arguments listed below.
    actor_flag_name(Name, cycle,  KC), flag(KC, _, 0),
    % State the fact: actor flag name(Name, errors, KE), flag(KE, _, 0).
    actor_flag_name(Name, errors, KE), flag(KE, _, 0).

% Define a clause for 'increment actor count': succeed when the following conditions hold.
increment_actor_count(Name, Type) :-
    % State a fact for 'actor flag name' with the arguments listed below.
    actor_flag_name(Name, Type, K),
    % State the fact: catch(flag(K, N, N + 1), _, true).
    catch(flag(K, N, N + 1), _, true).

% Define a clause for 'get actor count': succeed when the following conditions hold.
get_actor_count(Name, Type, N) :-
    % State a fact for 'actor flag name' with the arguments listed below.
    actor_flag_name(Name, Type, K),
    % Check that 'catch(flag(K, N, N), _, N' is unifiable with '0)'.
    catch(flag(K, N, N), _, N = 0).

% Define a clause for 'clear actor counts': succeed when the following conditions hold.
clear_actor_counts(Name) :-
    % State a fact for 'actor flag name' with the arguments listed below.
    actor_flag_name(Name, cycle,  KC), catch(flag(KC, _, 0), _, true),
    % State the fact: actor flag name(Name, errors, KE), catch(flag(KE, _, 0), _, true).
    actor_flag_name(Name, errors, KE), catch(flag(KE, _, 0), _, true).

% ---------------------------------------------------------------------------
% cyclic_actor/3
% ---------------------------------------------------------------------------

% Define a clause for 'cyclic actor': succeed when the following conditions hold.
cyclic_actor(Name, Goal, DelayMs) :-
    % Execute: ( once(registry_lock(actor_entry(Name, _))).
    ( once(registry_lock(actor_entry(Name, _)))
    % If the condition above succeeded, perform the following action.
    ->  throw(error(actor_error(already_exists, Name), cyclic_actor/3))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ),
    % State a fact for 'init actor counts' with the arguments listed below.
    init_actor_counts(Name),
    % State a fact for 'thread create' with the arguments listed below.
    thread_create(
        % Continue the multi-line expression started above.
        actor_loop(Name, Goal, DelayMs),
        % Supply 'Tid' as the next argument to the expression above.
        Tid,
        % Detached so a wedged actor can never block halt or thread_join; stop is
        % driven by the stop flag + signal + a bounded wait in cyclic_actor_stop.
        [alias(Name), detached(true)]
    % Close the expression opened above.
    ),
    % State the fact: register actor(Name, Tid).
    register_actor(Name, Tid).

% ---------------------------------------------------------------------------
% Actor loop
% ---------------------------------------------------------------------------

% Define a clause for 'actor loop': succeed when the following conditions hold.
actor_loop(Name, Goal, DelayMs) :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        actor_loop_body(Name, Goal, DelayMs),
        % Continue the multi-line expression started above.
        actor_stop(Name),
        % Continue the multi-line expression started above.
        deregister_actor(Name)
    % Close the expression opened above.
    ).

% Define a clause for 'actor loop body': succeed when the following conditions hold.
actor_loop_body(Name, Goal, DelayMs) :-
    % If a stop was requested, exit cleanly at this cycle boundary (a deterministic
    % exit point that does not depend on the thread_signal interrupt landing).
    ( actor_stop_requested(Name) -> throw(actor_stop(Name)) ; true ),
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( call(Goal) -> true ; log_actor_warn(Name, goal_failed) ),
        % Supply 'Err' as the next argument to the expression above.
        Err,
        % Re-throw the stop signal so the outer catch can handle it cleanly.
        % Continue the multi-line expression started above.
        ( Err = actor_stop(Name)
        % If the condition above succeeded, perform the following action.
        ->  throw(Err)
        % Otherwise (else branch), perform the following action.
        ;   log_actor_error(Name, Err),
            % Continue the multi-line expression started above.
            increment_actor_count(Name, errors)
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ),
    % State a fact for 'increment actor count' with the arguments listed below.
    increment_actor_count(Name, cycle),
    % Evaluate the arithmetic expression 'DelayMs / 1000.0' and bind the result to 'DelayS'.
    DelayS is DelayMs / 1000.0,
    % State a fact for 'sleep' with the arguments listed below.
    sleep(DelayS),
    % State the fact: actor loop body(Name, Goal, DelayMs).
    actor_loop_body(Name, Goal, DelayMs).

% Define a clause for 'log actor error': succeed when the following conditions hold.
log_actor_error(Name, Err) :-
    % Write formatted output to the current output stream.
    format(atom(_), "~w", [Err]),   % force instantiation check
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        print_message(warning, format("actor ~w error: ~w", [Name, Err])),
        % Supply '_' as the next argument to the expression above.
        _,
        % Supply 'true' as the next argument to the expression above.
        true
    % Close the expression opened above.
    ).

% Define a clause for 'log actor warn': succeed when the following conditions hold.
log_actor_warn(Name, Msg) :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        print_message(warning, format("actor ~w: ~w", [Name, Msg])),
        % Supply '_' as the next argument to the expression above.
        _,
        % Supply 'true' as the next argument to the expression above.
        true
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% cyclic_actor_stop/1
% ---------------------------------------------------------------------------

% Define a clause for 'cyclic actor stop': succeed when the following conditions hold.
cyclic_actor_stop(Name) :-
    % Look up the actor's thread id under the registry mutex (released at once).
    ( once(registry_lock(actor_entry(Name, Tid)))
    % If the actor exists, ask it to stop and wait, bounded, for it to exit.
    ->  % Set the stop flag so the loop exits at its next cycle boundary.
        ( actor_stop_requested(Name) -> true ; assertz(actor_stop_requested(Name)) ),
        % Signal the thread to interrupt a current sleep with the stop exception.
        catch(thread_signal(Tid, throw(actor_stop(Name))), _, true),
        % Poll for the thread to exit, up to about three seconds.
        wait_for_actor_exit(Tid, 30),
        % If it is still running (a wedged cycle goal), force an abort and wait more.
        ( catch(thread_property(Tid, status(running)), _, fail)
        ->  catch(thread_signal(Tid, abort), _, true),
            wait_for_actor_exit(Tid, 20)
        ;   true
        ),
        % Reap the thread if joinable (a no-op for a detached or already-gone thread).
        catch(thread_join(Tid, _), _, true),
        % Remove the registry entry, clear the stop flag, and reset the counters.
        deregister_actor(Name),
        retractall(actor_stop_requested(Name)),
        clear_actor_counts(Name)
    % Otherwise there is no such actor; stopping is a no-op.
    ;   true
    ).

% Poll a thread's status until it is no longer running or the budget is spent.
% Budget N is in units of 100 ms; returns as soon as the thread has exited.
wait_for_actor_exit(_, 0) :- !.
wait_for_actor_exit(Tid, N) :-
    % Still running: sleep 100 ms and poll again with one less unit of budget.
    ( catch(thread_property(Tid, status(running)), _, fail)
    ->  sleep(0.1), N1 is N - 1, wait_for_actor_exit(Tid, N1)
    % Not running (exited or gone): done.
    ;   true
    ).

% ---------------------------------------------------------------------------
% cyclic_actor_list/1
% ---------------------------------------------------------------------------

% Define a clause for 'cyclic actor list': succeed when the following conditions hold.
cyclic_actor_list(Names) :-
    % State the fact: registry lock(findall(N, actor_entry(N, _), Names)).
    registry_lock(findall(N, actor_entry(N, _), Names)).

% ---------------------------------------------------------------------------
% cyclic_actor_status/2
% ---------------------------------------------------------------------------

% Define a clause for 'cyclic actor status': succeed when the following conditions hold.
cyclic_actor_status(Name, Status) :-
    % Execute: ( once(registry_lock(actor_entry(Name, Tid))).
    ( once(registry_lock(actor_entry(Name, Tid)))
    % If the condition above succeeded, perform the following action.
    ->  get_actor_count(Name, cycle,  CC),
        % Continue the multi-line expression started above.
        get_actor_count(Name, errors, EC),
        % Continue the multi-line expression started above.
        ( catch(thread_property(Tid, status(running)), _, fail)
        % If the condition above succeeded, perform the following action.
        ->  State = running
        % Otherwise (else branch), perform the following action.
        ;   State = stopped
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        Status = status{name: Name, state: State,
                        % Continue the multi-line expression started above.
                        cycle_count: CC, error_count: EC}
    % Otherwise (else branch), perform the following action.
    ;   throw(error(existence_error(actor, Name), cyclic_actor_status/2))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% actors_declare_actor/3 — called from .pai expansion of cyclic_actor/3
% ---------------------------------------------------------------------------

% Define a clause for 'pai declare actor': succeed when the following conditions hold.
actors_declare_actor(Name, Goal, DelayMs) :-
    % State the fact: cyclic actor(Name, Goal, DelayMs).
    cyclic_actor(Name, Goal, DelayMs).
