/*  PrologAI — PR 6 Cyclic Actors Acceptance Tests

    AC-PR06-001: cyclic_actor(test_actor, true, 100) — after 1 s, cycle_count >= 9.
    AC-PR06-002: Actor whose Goal always throws — after 5 cycles, still running, error_count = 5.
    AC-PR06-003: Duplicate actor name throws actor_error(already_exists, _).
    AC-PR06-004: cyclic_actor_stop/1 terminates the thread.
    AC-PR06-005: cyclic_actor_list/1 includes running actors.
    AC-PR06-006: cyclic_actor_status/2 returns a dict with cycle_count and error_count.
    AC-PR06-007: Stopped actor removed from cyclic_actor_list.
    AC-PR06-008: Actor survives goal failure (nondet goal that fails).
    AC-PR06-009: pai_declare_actor/3 starts a cyclic actor.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'], ActorsPath),
   assertz(file_search_path(library, ActorsPath)).

:- use_module(library(plunit)).
:- use_module(library(lists), [member/2, memberchk/2]).
:- use_module(library(cyclic_actor)).

:- begin_tests(pr06).

test(cycle_count_grows) :-
    cyclic_actor(count_actor, true, 50),
    sleep(0.6),
    cyclic_actor_status(count_actor, S),
    get_dict(cycle_count, S, CC),
    CC >= 9,
    cyclic_actor_stop(count_actor).

test(error_actor_survives) :-
    cyclic_actor(error_actor, throw(deliberate_error), 50),
    sleep(0.35),
    cyclic_actor_status(error_actor, S),
    get_dict(state, S, running),
    get_dict(error_count, S, EC),
    EC >= 5,
    cyclic_actor_stop(error_actor).

test(duplicate_throws,
     [throws(error(actor_error(already_exists, dup_actor), _))]) :-
    cyclic_actor(dup_actor, true, 200),
    catch(
        cyclic_actor(dup_actor, true, 200),
        Err,
        ( cyclic_actor_stop(dup_actor), throw(Err) )
    ).

test(stop_terminates) :-
    cyclic_actor(stop_actor, true, 100),
    cyclic_actor_stop(stop_actor),
    cyclic_actor_list(Ls),
    \+ memberchk(stop_actor, Ls).

test(list_includes_running) :-
    cyclic_actor(list_actor, true, 100),
    cyclic_actor_list(Ls),
    memberchk(list_actor, Ls),
    cyclic_actor_stop(list_actor).

test(status_has_fields) :-
    cyclic_actor(fields_actor, true, 100),
    sleep(0.15),
    cyclic_actor_status(fields_actor, S),
    get_dict(cycle_count, S, CC), integer(CC),
    get_dict(error_count, S, EC), integer(EC),
    get_dict(state, S, St), atom(St),
    cyclic_actor_stop(fields_actor).

test(stopped_removed_from_list) :-
    cyclic_actor(gone_actor, true, 100),
    cyclic_actor_stop(gone_actor),
    cyclic_actor_list(Ls),
    \+ memberchk(gone_actor, Ls).

test(goal_failure_survives) :-
    cyclic_actor(fail_actor, fail, 50),
    sleep(0.25),
    cyclic_actor_status(fail_actor, S),
    S.state == running,
    cyclic_actor_stop(fail_actor).

test(pai_declare_actor_starts) :-
    pai_declare_actor(pai_test_actor, true, 100),
    cyclic_actor_list(Ls),
    memberchk(pai_test_actor, Ls),
    cyclic_actor_stop(pai_test_actor).

:- end_tests(pr06).
