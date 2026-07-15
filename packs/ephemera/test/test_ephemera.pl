/*  PrologAI — Ephemera Unit Tests  (PR 53)

    Acceptance criteria:
        AC-EP-001: ephemera_eval/3 returns success when the goal succeeds
        AC-EP-002: ephemera_eval/3 returns fail when the goal fails
        AC-EP-003: ephemera_eval/3 returns error(E) when the goal throws E
        AC-EP-004: ephemera_eval/3 returns timeout when time is exceeded
        AC-EP-005: ephemera_eval/3 binds variables in the goal on success
        AC-EP-006: ephemera_scratch/4 evaluates a Prolog code atom
        AC-EP-007: ephemera_shell/3 captures stdout of a simple command
        AC-EP-008: ephemera_shell/3 captures exit code zero on success
        AC-EP-009: ephemera_next_trace_id/1 returns unique IDs on successive calls
        AC-EP-010: ephemera_trace_record/4 and ephemera_trace_get/2 round-trip correctly
        AC-EP-011: ephemera_skill_save/4 stores a skill in the database
        AC-EP-012: ephemera_skill_lookup/3 retrieves language and code by name
        AC-EP-013: ephemera_skill_run/3 executes a saved skill by name
        AC-EP-014: ephemera_skill_list/1 lists all saved skills
        AC-EP-015: ephemera_skill_forget/1 removes a skill; second lookup fails
*/

% Declare this file as the 'test_ephemera' module.
:- module(test_ephemera, []).

% Load the PLUnit testing framework.
:- use_module(library(plunit)).
% Load the ephemera module under test.
:- use_module(library(ephemera)).

% Begin the test suite.
:- begin_tests(ephemera).

% AC-EP-001: ephemera_eval/3 returns success when the goal succeeds.
test(eval_success, []) :-
    % Evaluate a goal that always succeeds.
    ephemera_eval(true, 5, R),
    % The result must be success.
    R = success.

% AC-EP-002: ephemera_eval/3 returns fail when the goal fails.
test(eval_fail, []) :-
    % Evaluate a goal that always fails.
    ephemera_eval(fail, 5, R),
    % The result must be fail.
    R = fail.

% AC-EP-003: ephemera_eval/3 returns error(E) when the goal throws E.
test(eval_error, []) :-
    % Evaluate a goal that throws a known exception.
    ephemera_eval(throw(my_test_error), 5, R),
    % The result must be wrapped in error/1.
    R = error(my_test_error).

% AC-EP-004: ephemera_eval/3 returns timeout when time is exceeded.
test(eval_timeout, []) :-
    % Evaluate a goal that never terminates within 0.1 seconds.
    ephemera_eval((repeat, fail), 0.1, R),
    % The result must be timeout.
    R = timeout.

% AC-EP-005: ephemera_eval/3 binds variables in the goal term on success.
test(eval_binds_vars, []) :-
    % Evaluate a goal that binds X to 4.
    ephemera_eval((X is 2 + 2), 5, R),
    % The result must be success.
    R = success,
    % The variable X must now be bound to 4.
    X =:= 4.

% AC-EP-006: ephemera_scratch/4 evaluates a Prolog code atom.
test(scratch_eval, []) :-
    % Evaluate the arithmetic expression given as an atom.
    ephemera_scratch('Y is 3 * 7', ['Y'=Y], 5, R),
    % The result must be success with the binding.
    R = success(['Y'=21]),
    % The variable Y must be bound to 21.
    Y =:= 21.

% AC-EP-007: ephemera_shell/3 captures stdout of a simple echo command.
test(shell_stdout, []) :-
    % Run 'echo hello' and capture its output.
    ephemera_shell(['echo', 'hello'], 10, shell_result(_, Out, _)),
    % The stdout must contain the word 'hello'.
    atom_codes(Out, Codes),
    atom_codes('hello', HelloCodes),
    % Verify the output starts with 'hello'.
    append(HelloCodes, _, Codes).

% AC-EP-008: ephemera_shell/3 captures exit code zero on a successful command.
test(shell_exit_code, []) :-
    % Run 'true' which exits with code zero.
    ephemera_shell(['true'], 10, shell_result(Code, _, _)),
    % The exit code must be zero.
    Code =:= 0.

% AC-EP-009: ephemera_next_trace_id/1 returns unique IDs on successive calls.
test(trace_id_unique,
     [setup(true), cleanup(true)]) :-
    % Allocate the first trace ID.
    ephemera_next_trace_id(Id1),
    % Allocate the second trace ID.
    ephemera_next_trace_id(Id2),
    % The two IDs must be different.
    Id1 \= Id2.

% AC-EP-010: ephemera_trace_record/4 and ephemera_trace_get/2 round-trip correctly.
test(trace_roundtrip,
     [setup(ephemera_next_trace_id(TId)),
      cleanup(retractall(ephemera:ephemera_trace_entry(TId, _, _, _)))]) :-
    % Record two steps to the trace.
    ephemera_trace_record(TId, 1, 'X is 1', success),
    ephemera_trace_record(TId, 2, 'Y is 2', success),
    % Retrieve the trace and check it has exactly two entries.
    ephemera_trace_get(TId, Entries),
    length(Entries, 2).

% AC-EP-011: ephemera_skill_save/4 stores a skill in the database.
test(skill_save,
     [cleanup(ephemera_skill_forget(test_skill_011))]) :-
    % Save a Python skill with a description.
    ephemera_skill_save(test_skill_011, python, 'print("ok")', 'Test skill 011'),
    % Verify the fact is present in the database.
    ephemera:ephemera_skill_db(test_skill_011, python, 'print("ok")', 'Test skill 011').

% AC-EP-012: ephemera_skill_lookup/3 retrieves language and code by name.
test(skill_lookup,
     [setup(ephemera_skill_save(test_skill_012, bash, 'echo found', 'Test skill 012')),
      cleanup(ephemera_skill_forget(test_skill_012))]) :-
    % Retrieve the stored skill.
    ephemera_skill_lookup(test_skill_012, Lang, Code),
    % Verify the language.
    Lang = bash,
    % Verify the code.
    Code = 'echo found'.

% AC-EP-013: ephemera_skill_run/3 executes a saved skill by name.
test(skill_run,
     [setup(ephemera_skill_save(test_skill_013, python, 'print("skill_run_ok")', 'Test skill 013')),
      cleanup(ephemera_skill_forget(test_skill_013))]) :-
    % Run the saved skill.
    ephemera_skill_run(test_skill_013, 10, shell_result(Code, Out, _)),
    % Verify exit code zero.
    Code =:= 0,
    % Verify the output contains the expected text.
    atom_codes(Out, OutCodes),
    atom_codes('skill_run_ok', ExpCodes),
    append(ExpCodes, _, OutCodes).

% AC-EP-014: ephemera_skill_list/1 lists all saved skills (at least the saved one).
test(skill_list,
     [setup(ephemera_skill_save(test_skill_014, bash, 'echo list', 'Test skill 014')),
      cleanup(ephemera_skill_forget(test_skill_014))]) :-
    % Retrieve the full skill list.
    ephemera_skill_list(Skills),
    % The saved skill must appear in the list.
    member(skill(test_skill_014, bash, 'Test skill 014'), Skills).

% AC-EP-015: ephemera_skill_forget/1 removes a skill; lookup afterwards fails.
test(skill_forget,
     [setup(ephemera_skill_save(test_skill_015, python, 'print("bye")', 'Test skill 015')),
      cleanup(true)]) :-
    % Forget the skill.
    ephemera_skill_forget(test_skill_015),
    % Lookup must now fail.
    \+ ephemera_skill_lookup(test_skill_015, _, _).

% End the test suite.
:- end_tests(ephemera).
