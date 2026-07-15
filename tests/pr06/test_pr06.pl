/*  PrologAI — PR 6 Cyclic Actors Acceptance Tests

    AC-PR06-001: cyclic_actor(test_actor, true, 100) — after 1 s, cycle_count >= 9.
    AC-PR06-002: Actor whose Goal always throws — after 5 cycles, still running, error_count = 5.
    AC-PR06-003: Duplicate actor name throws actor_error(already_exists, _).
    AC-PR06-004: cyclic_actor_stop/1 terminates the thread.
    AC-PR06-005: cyclic_actor_list/1 includes running actors.
    AC-PR06-006: cyclic_actor_status/2 returns a dict with cycle_count and error_count.
    AC-PR06-007: Stopped actor removed from cyclic_actor_list.
    AC-PR06-008: Actor survives goal failure (nondet goal that fails).
    AC-PR06-009: actors_declare_actor/3 starts a cyclic actor.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'], ActorsPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ActorsPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [member/2, memberchk/2] from the built-in 'lists' library.
:- use_module(library(lists), [member/2, memberchk/2]).
% Load the built-in 'cyclic_actor' library so its predicates are available here.
:- use_module(library(cyclic_actor)).

% Execute the compile-time directive: begin_tests(pr06).
:- begin_tests(pr06).

% Define a clause for 'test': succeed when the following conditions hold.
test(cycle_count_grows) :-
    % State a fact for 'cyclic actor' with the arguments listed below.
    cyclic_actor(count_actor, true, 50),
    % State a fact for 'sleep' with the arguments listed below.
    sleep(0.6),
    % State a fact for 'cyclic actor status' with the arguments listed below.
    cyclic_actor_status(count_actor, S),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(cycle_count, S, CC),
    % Check that 'CC' is greater than or equal to '9'.
    CC >= 9,
    % State the fact: cyclic actor stop(count_actor).
    cyclic_actor_stop(count_actor).

% Define a clause for 'test': succeed when the following conditions hold.
test(error_actor_survives) :-
    % State a fact for 'cyclic actor' with the arguments listed below.
    cyclic_actor(error_actor, throw(deliberate_error), 50),
    % State a fact for 'sleep' with the arguments listed below.
    sleep(0.35),
    % State a fact for 'cyclic actor status' with the arguments listed below.
    cyclic_actor_status(error_actor, S),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(state, S, running),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(error_count, S, EC),
    % Check that 'EC' is greater than or equal to '5'.
    EC >= 5,
    % State the fact: cyclic actor stop(error_actor).
    cyclic_actor_stop(error_actor).

% State a fact for 'test' with the arguments listed below.
test(duplicate_throws,
     % Continue the multi-line expression started above.
     [throws(error(actor_error(already_exists, dup_actor), _))]) :-
    % State a fact for 'cyclic actor' with the arguments listed below.
    cyclic_actor(dup_actor, true, 200),
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        cyclic_actor(dup_actor, true, 200),
        % Supply 'Err' as the next argument to the expression above.
        Err,
        % Continue the multi-line expression started above.
        ( cyclic_actor_stop(dup_actor), throw(Err) )
    % Close the expression opened above.
    ).

% Define a clause for 'test': succeed when the following conditions hold.
test(stop_terminates) :-
    % State a fact for 'cyclic actor' with the arguments listed below.
    cyclic_actor(stop_actor, true, 100),
    % State a fact for 'cyclic actor stop' with the arguments listed below.
    cyclic_actor_stop(stop_actor),
    % State a fact for 'cyclic actor list' with the arguments listed below.
    cyclic_actor_list(Ls),
    % Succeed only if 'memberchk(stop_actor, Ls' cannot be proved (negation as failure).
    \+ memberchk(stop_actor, Ls).

% Define a clause for 'test': succeed when the following conditions hold.
test(list_includes_running) :-
    % State a fact for 'cyclic actor' with the arguments listed below.
    cyclic_actor(list_actor, true, 100),
    % State a fact for 'cyclic actor list' with the arguments listed below.
    cyclic_actor_list(Ls),
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(list_actor, Ls),
    % State the fact: cyclic actor stop(list_actor).
    cyclic_actor_stop(list_actor).

% Define a clause for 'test': succeed when the following conditions hold.
test(status_has_fields) :-
    % State a fact for 'cyclic actor' with the arguments listed below.
    cyclic_actor(fields_actor, true, 100),
    % State a fact for 'sleep' with the arguments listed below.
    sleep(0.15),
    % State a fact for 'cyclic actor status' with the arguments listed below.
    cyclic_actor_status(fields_actor, S),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(cycle_count, S, CC), integer(CC),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(error_count, S, EC), integer(EC),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(state, S, St), atom(St),
    % State the fact: cyclic actor stop(fields_actor).
    cyclic_actor_stop(fields_actor).

% Define a clause for 'test': succeed when the following conditions hold.
test(stopped_removed_from_list) :-
    % State a fact for 'cyclic actor' with the arguments listed below.
    cyclic_actor(gone_actor, true, 100),
    % State a fact for 'cyclic actor stop' with the arguments listed below.
    cyclic_actor_stop(gone_actor),
    % State a fact for 'cyclic actor list' with the arguments listed below.
    cyclic_actor_list(Ls),
    % Succeed only if 'memberchk(gone_actor, Ls' cannot be proved (negation as failure).
    \+ memberchk(gone_actor, Ls).

% Define a clause for 'test': succeed when the following conditions hold.
test(goal_failure_survives) :-
    % State a fact for 'cyclic actor' with the arguments listed below.
    cyclic_actor(fail_actor, fail, 50),
    % State a fact for 'sleep' with the arguments listed below.
    sleep(0.25),
    % State a fact for 'cyclic actor status' with the arguments listed below.
    cyclic_actor_status(fail_actor, S),
    % Check that 'S.state' is structurally identical to 'running'.
    S.state == running,
    % State the fact: cyclic actor stop(fail_actor).
    cyclic_actor_stop(fail_actor).

% Define a clause for 'test': succeed when the following conditions hold.
test(pai_declare_actor_starts) :-
    % State a fact for 'pai declare actor' with the arguments listed below.
    actors_declare_actor(pai_test_actor, true, 100),
    % State a fact for 'cyclic actor list' with the arguments listed below.
    cyclic_actor_list(Ls),
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(pai_test_actor, Ls),
    % State the fact: cyclic actor stop(pai_test_actor).
    cyclic_actor_stop(pai_test_actor).

% Execute the compile-time directive: end_tests(pr06).
:- end_tests(pr06).
