/*  PrologAI — Ephemera Unit Tests  (PR 53)

    Acceptance criteria:
        AC-EP-001: ep_eval/3 returns success when the goal succeeds
        AC-EP-002: ep_eval/3 returns fail when the goal fails
        AC-EP-003: ep_eval/3 returns error(E) when the goal throws E
        AC-EP-004: ep_eval/3 returns timeout when time is exceeded
        AC-EP-005: ep_eval/3 binds variables in the goal on success
        AC-EP-006: ep_scratch/4 evaluates a Prolog code atom
        AC-EP-007: ep_shell/3 captures stdout of a simple command
        AC-EP-008: ep_shell/3 captures exit code zero on success
        AC-EP-009: ep_next_trace_id/1 returns unique IDs on successive calls
        AC-EP-010: ep_trace_record/4 and ep_trace_get/2 round-trip correctly
*/

% Declare this file as the 'test_ephemera' module.
:- module(test_ephemera, []).

% Load the PLUnit testing framework.
:- use_module(library(plunit)).
% Load the ephemera module under test.
:- use_module(library(ephemera)).

% Begin the test suite.
:- begin_tests(ephemera).

% AC-EP-001: ep_eval/3 returns success when the goal succeeds.
test(eval_success, []) :-
    % Evaluate a goal that always succeeds.
    ep_eval(true, 5, R),
    % The result must be success.
    R = success.

% AC-EP-002: ep_eval/3 returns fail when the goal fails.
test(eval_fail, []) :-
    % Evaluate a goal that always fails.
    ep_eval(fail, 5, R),
    % The result must be fail.
    R = fail.

% AC-EP-003: ep_eval/3 returns error(E) when the goal throws E.
test(eval_error, []) :-
    % Evaluate a goal that throws a known exception.
    ep_eval(throw(my_test_error), 5, R),
    % The result must be wrapped in error/1.
    R = error(my_test_error).

% AC-EP-004: ep_eval/3 returns timeout when time is exceeded.
test(eval_timeout, []) :-
    % Evaluate a goal that never terminates within 0.1 seconds.
    ep_eval((repeat, fail), 0.1, R),
    % The result must be timeout.
    R = timeout.

% AC-EP-005: ep_eval/3 binds variables in the goal term on success.
test(eval_binds_vars, []) :-
    % Evaluate a goal that binds X to 4.
    ep_eval((X is 2 + 2), 5, R),
    % The result must be success.
    R = success,
    % The variable X must now be bound to 4.
    X =:= 4.

% AC-EP-006: ep_scratch/4 evaluates a Prolog code atom.
test(scratch_eval, []) :-
    % Evaluate the arithmetic expression given as an atom.
    ep_scratch('Y is 3 * 7', ['Y'=Y], 5, R),
    % The result must be success with the binding.
    R = success(['Y'=21]),
    % The variable Y must be bound to 21.
    Y =:= 21.

% AC-EP-007: ep_shell/3 captures stdout of a simple echo command.
test(shell_stdout, []) :-
    % Run 'echo hello' and capture its output.
    ep_shell(['echo', 'hello'], 10, shell_result(_, Out, _)),
    % The stdout must contain the word 'hello'.
    atom_codes(Out, Codes),
    atom_codes('hello', HelloCodes),
    % Verify the output starts with 'hello'.
    append(HelloCodes, _, Codes).

% AC-EP-008: ep_shell/3 captures exit code zero on a successful command.
test(shell_exit_code, []) :-
    % Run 'true' which exits with code zero.
    ep_shell(['true'], 10, shell_result(Code, _, _)),
    % The exit code must be zero.
    Code =:= 0.

% AC-EP-009: ep_next_trace_id/1 returns unique IDs on successive calls.
test(trace_id_unique,
     [setup(true), cleanup(true)]) :-
    % Allocate the first trace ID.
    ep_next_trace_id(Id1),
    % Allocate the second trace ID.
    ep_next_trace_id(Id2),
    % The two IDs must be different.
    Id1 \= Id2.

% AC-EP-010: ep_trace_record/4 and ep_trace_get/2 round-trip correctly.
test(trace_roundtrip,
     [setup(ep_next_trace_id(TId)),
      cleanup(retractall(ephemera:ep_trace_entry(TId, _, _, _)))]) :-
    % Record two steps to the trace.
    ep_trace_record(TId, 1, 'X is 1', success),
    ep_trace_record(TId, 2, 'Y is 2', success),
    % Retrieve the trace and check it has exactly two entries.
    ep_trace_get(TId, Entries),
    length(Entries, 2).

% End the test suite.
:- end_tests(ephemera).
