/*  PrologAI — Cyclic Actors  (Specification Section 3.5, PR 6)

    cyclic_actor/3     — start a proactive background thread
    cyclic_actor_stop/1  — gracefully stop an actor; blocks until exited
    cyclic_actor_list/1  — list all running actor names
    cyclic_actor_status/2 — cycle_count, error_count, state
    pai_declare_actor/3  — load-time hook called from .pai cyclic_actor/3 expansion

    Actor names are globally unique.  Duplicate creation throws
    actor_error(already_exists, Name).

    The registry mutex (actor_registry_mutex) protects all reads and
    writes of the actor_entry dynamic predicate.
*/

:- module(cyclic_actor, [
    cyclic_actor/3,        % +Name, :Goal, +DelayMs
    cyclic_actor_stop/1,   % +Name
    cyclic_actor_list/1,   % -Names
    cyclic_actor_status/2, % +Name, -Status
    pai_declare_actor/3    % +Name, :Goal, +DelayMs  (expansion hook)
]).

:- meta_predicate cyclic_actor(+, 0, +).
:- meta_predicate pai_declare_actor(+, 0, +).

:- use_module(library(apply), [maplist/2]).

% ---------------------------------------------------------------------------
% Registry
% ---------------------------------------------------------------------------

:- dynamic actor_entry/2.          % Name, ThreadId

:- initialization(mutex_create(actor_registry_mutex), now).

registry_lock(Goal) :-
    with_mutex(actor_registry_mutex, Goal).

register_actor(Name, Tid) :-
    registry_lock(assertz(actor_entry(Name, Tid))).

deregister_actor(Name) :-
    registry_lock(retractall(actor_entry(Name, _))).

% ---------------------------------------------------------------------------
% Per-actor counters using flag/3 (shared atomic integer across threads)
% ---------------------------------------------------------------------------

actor_flag_name(Name, cycle,  K) :- !, atomic_list_concat([pac_, Name, '_c'], K).
actor_flag_name(Name, errors, K) :- !, atomic_list_concat([pac_, Name, '_e'], K).

init_actor_counts(Name) :-
    actor_flag_name(Name, cycle,  KC), flag(KC, _, 0),
    actor_flag_name(Name, errors, KE), flag(KE, _, 0).

increment_actor_count(Name, Type) :-
    actor_flag_name(Name, Type, K),
    catch(flag(K, N, N + 1), _, true).

get_actor_count(Name, Type, N) :-
    actor_flag_name(Name, Type, K),
    catch(flag(K, N, N), _, N = 0).

clear_actor_counts(Name) :-
    actor_flag_name(Name, cycle,  KC), catch(flag(KC, _, 0), _, true),
    actor_flag_name(Name, errors, KE), catch(flag(KE, _, 0), _, true).

% ---------------------------------------------------------------------------
% cyclic_actor/3
% ---------------------------------------------------------------------------

cyclic_actor(Name, Goal, DelayMs) :-
    ( once(registry_lock(actor_entry(Name, _)))
    ->  throw(error(actor_error(already_exists, Name), cyclic_actor/3))
    ;   true
    ),
    init_actor_counts(Name),
    thread_create(
        actor_loop(Name, Goal, DelayMs),
        Tid,
        [alias(Name), detached(false)]
    ),
    register_actor(Name, Tid).

% ---------------------------------------------------------------------------
% Actor loop
% ---------------------------------------------------------------------------

actor_loop(Name, Goal, DelayMs) :-
    catch(
        actor_loop_body(Name, Goal, DelayMs),
        actor_stop(Name),
        deregister_actor(Name)
    ).

actor_loop_body(Name, Goal, DelayMs) :-
    ( catch(
        ( call(Goal) -> true ; log_actor_warn(Name, goal_failed) ),
        Err,
        ( log_actor_error(Name, Err), increment_actor_count(Name, errors) )
      )
    ->  true
    ;   true
    ),
    increment_actor_count(Name, cycle),
    DelayS is DelayMs / 1000.0,
    sleep(DelayS),
    actor_loop_body(Name, Goal, DelayMs).

log_actor_error(Name, Err) :-
    format(atom(_), "~w", [Err]),   % force instantiation check
    catch(
        print_message(warning, format("actor ~w error: ~w", [Name, Err])),
        _,
        true
    ).

log_actor_warn(Name, Msg) :-
    catch(
        print_message(warning, format("actor ~w: ~w", [Name, Msg])),
        _,
        true
    ).

% ---------------------------------------------------------------------------
% cyclic_actor_stop/1
% ---------------------------------------------------------------------------

cyclic_actor_stop(Name) :-
    ( once(registry_lock(actor_entry(Name, Tid)))
    ->  catch(
            thread_signal(Tid, throw(actor_stop(Name))),
            _,
            true
        ),
        catch(
            thread_join(Tid, _),
            _,
            true
        ),
        deregister_actor(Name),
        clear_actor_counts(Name)
    ;   true
    ).

% ---------------------------------------------------------------------------
% cyclic_actor_list/1
% ---------------------------------------------------------------------------

cyclic_actor_list(Names) :-
    registry_lock(findall(N, actor_entry(N, _), Names)).

% ---------------------------------------------------------------------------
% cyclic_actor_status/2
% ---------------------------------------------------------------------------

cyclic_actor_status(Name, Status) :-
    ( once(registry_lock(actor_entry(Name, Tid)))
    ->  get_actor_count(Name, cycle,  CC),
        get_actor_count(Name, errors, EC),
        ( catch(thread_property(Tid, status(running)), _, fail)
        ->  State = running
        ;   State = stopped
        ),
        Status = status{name: Name, state: State,
                        cycle_count: CC, error_count: EC}
    ;   throw(error(existence_error(actor, Name), cyclic_actor_status/2))
    ).

% ---------------------------------------------------------------------------
% pai_declare_actor/3 — called from .pai expansion of cyclic_actor/3
% ---------------------------------------------------------------------------

pai_declare_actor(Name, Goal, DelayMs) :-
    cyclic_actor(Name, Goal, DelayMs).
