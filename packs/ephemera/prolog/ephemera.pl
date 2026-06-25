/*  PrologAI — Ephemera: Code Synthesis and Execution  (Specification PR 53)

    Gives PrologAI the ability to write small, ephemeral programs to solve
    problems it faces, execute them safely, observe the results, and iterate
    until the problem is solved.  This is the silicon-and-code substrate
    answer to the question of agentic code-use: instead of reasoning about
    what the answer might be, synthesize a computation and run it.

    Inspired by:
    - Agentic AI Patterns Part 9.4 (Code and Computer Use Patterns)
    - Coding Design Principles: write, run, observe, improve
    - The practice of writing small ephemeral programs to solve sub-problems

    Three execution modes:

    1. Prolog goal evaluation (ep_eval/3)
       - GoalTerm is a Prolog compound term already in memory.
       - call_with_time_limit evaluates it with a hard wall-clock limit.
       - Variable bindings from the goal survive in the caller's scope.
       - This is the fastest and most integrated mode; no subprocess.

    2. Shell execution (ep_shell/3)
       - Argv = [Command | Args] where Command is on PATH.
       - process_create launches it; stdout and stderr are captured.
       - Exit code, stdout atom, and stderr atom are returned.
       - Used for any OS-level operation: ls, grep, python3, swipl, etc.

    3. Ephemeral scripting (ep_ephemeral/4)
       - PrologAI writes Code to a uniquely named temp file.
       - The file is executed via ep_shell and then deleted unconditionally.
       - Supported languages: prolog, python, bash.
       - Used when code is produced as text (a string or atom) rather than
         as a goal term already in memory.

    Iteration (ep_iterate/5):
       - Calls SynthGoal to produce code, ExecGoal to run it, CheckGoal to
         test success.  Repeats up to MaxIter times.
       - Models the write-run-observe-improve loop used by coding agents.

    Trace log:
       - ep_trace_record/4 writes a step to the trace log.
       - ep_trace_get/2 retrieves the full trace for a run.
       - ep_next_trace_id/1 allocates a fresh trace id.

    Predicates:
      ep_eval/3          -- evaluate a Prolog goal term with timeout
      ep_scratch/4       -- evaluate a Prolog code atom in the current process
      ep_shell/3         -- execute an argv list with timeout, capture output
      ep_ephemeral/4     -- write temp script, execute, clean up
      ep_iterate/5       -- iterate synth-exec-check until success or limit
      ep_trace_record/4  -- record one step to the trace log
      ep_trace_get/2     -- retrieve all trace entries for a trace id
      ep_next_trace_id/1 -- allocate a fresh unique trace id
*/

% Declare this file as the 'ephemera' module and list its exported predicates.
:- module(ephemera, [
    % Export 'ep_eval/3': evaluate a Prolog goal term with a timeout.
    ep_eval/3,          % +GoalTerm, +TimeoutSecs, -EvalResult
    % Export 'ep_scratch/4': evaluate a Prolog code atom in the current process.
    ep_scratch/4,       % +CodeAtom, +Vars, +TimeoutSecs, -EvalResult
    % Export 'ep_shell/3': execute a command argv list with timeout.
    ep_shell/3,         % +Argv, +TimeoutSecs, -ShellResult
    % Export 'ep_ephemeral/4': write temp script, execute, clean up.
    ep_ephemeral/4,     % +Language, +Code, +TimeoutSecs, -ShellResult
    % Export 'ep_iterate/5': iterate synth-exec-check until success or limit.
    ep_iterate/5,       % :SynthGoal, :ExecGoal, :CheckGoal, +MaxIter, -IterResult
    % Export 'ep_trace_record/4': record one step to the trace log.
    ep_trace_record/4,  % +TraceId, +Iter, +Code, +Output
    % Export 'ep_trace_get/2': retrieve all trace entries for a trace id.
    ep_trace_get/2,     % +TraceId, -Entries
    % Export 'ep_next_trace_id/1': allocate a fresh unique trace id.
    ep_next_trace_id/1  % -TraceId
% Close the module declaration.
]).

% Import process_create and process_wait for subprocess management.
:- use_module(library(process),  [process_create/3, process_wait/2]).
% Import readutil for reading entire streams into code lists.
:- use_module(library(readutil), [read_stream_to_codes/2]).
% Import lists for member/2.
:- use_module(library(lists),    [member/2]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% Declare ep_trace_entry/4 as dynamic: (TraceId, Iter, Code, Output).
:- dynamic ep_trace_entry/4.
% Declare ep_trace_counter/1 as dynamic for allocating trace IDs.
:- dynamic ep_trace_counter/1.
% Initialize the trace counter at zero.
ep_trace_counter(0).

% ---------------------------------------------------------------------------
% ep_next_trace_id/1 -- allocate a fresh unique trace ID
% ---------------------------------------------------------------------------

% Define ep_next_trace_id: retract the counter, increment, reassert, build atom.
ep_next_trace_id(Id) :-
    % Remove the current counter fact.
    retract(ep_trace_counter(N)),
    % Increment the counter.
    N1 is N + 1,
    % Store the new counter value.
    assertz(ep_trace_counter(N1)),
    % Build the trace ID atom from the prefix and counter.
    atomic_list_concat([ep_trace_, N1], Id).

% ---------------------------------------------------------------------------
% ep_trace_record/4 -- record one synthesis-execution step to the trace log
% ---------------------------------------------------------------------------

% Define ep_trace_record: assert one entry into the trace log.
ep_trace_record(TraceId, Iter, Code, Output) :-
    % Assert the trace entry as a dynamic fact.
    assertz(ep_trace_entry(TraceId, Iter, Code, Output)).

% ---------------------------------------------------------------------------
% ep_trace_get/2 -- retrieve all trace entries for a given trace id
% ---------------------------------------------------------------------------

% Define ep_trace_get: collect all entries for a TraceId into Entries.
ep_trace_get(TraceId, Entries) :-
    % Collect all matching trace entries.
    findall(step(Iter, Code, Output),
            ep_trace_entry(TraceId, Iter, Code, Output),
            Entries).

% ---------------------------------------------------------------------------
% ep_eval/3 -- evaluate a Prolog goal term with a wall-clock time limit
%
% EvalResult is one of:
%   success          -- GoalTerm succeeded; any variable bindings are live
%   fail             -- GoalTerm failed; no variable bindings
%   timeout          -- time limit exceeded before GoalTerm returned
%   error(Exception) -- GoalTerm threw an exception
%
% Example:
%   ?- ep_eval((X is 2 + 2), 5, R).
%   X = 4, R = success.
% ---------------------------------------------------------------------------

% Define ep_eval: evaluate GoalTerm with a time limit, classify the outcome.
ep_eval(GoalTerm, TimeoutSecs, EvalResult) :-
    % Wrap evaluation in a catch to handle all exception kinds.
    catch(
        % Use call_with_time_limit for the wall-clock bound.
        call_with_time_limit(
            TimeoutSecs,
            % Test the goal: success on true, fail on false.
            ( call(GoalTerm) -> EvalResult = success ; EvalResult = fail )
        ),
        % Classify the exception into a structured result.
        Exception,
        ep_classify_exception(Exception, EvalResult)
    ).

% Define ep_classify_exception for time_limit_exceeded: return timeout.
ep_classify_exception(time_limit_exceeded, timeout) :- !.
% Define ep_classify_exception for all other exceptions: wrap in error/1.
ep_classify_exception(E, error(E)).

% ---------------------------------------------------------------------------
% ep_scratch/4 -- evaluate a Prolog code atom in the current process
%
% CodeAtom is a Prolog term written as an atom, e.g. 'X is 2 + 2'.
% Vars is a list of Name=Var pairs for variables you want to inspect.
% TimeoutSecs is the wall-clock limit.
% EvalResult is success(Bindings), fail, timeout, or error(E).
%   Bindings = list of Name=Value pairs for variables named in Vars.
%
% Example:
%   ?- ep_scratch('X is 2 + 2', ['X'=X], 5, R).
%   R = success(['X'=4]).
% ---------------------------------------------------------------------------

% Define ep_scratch: parse the code atom into a goal, evaluate, extract bindings.
ep_scratch(CodeAtom, Vars, TimeoutSecs, EvalResult) :-
    % Parse the atom into a goal term with named variable bindings.
    catch(
        atom_to_term(CodeAtom, Goal, _NamedVars),
        ParseError,
        ( EvalResult = error(parse_error(ParseError)), ! )
    ),
    % Evaluate the parsed goal with a time limit.
    ( var(EvalResult)
    ->  ep_eval(Goal, TimeoutSecs, Outcome),
        % If the goal succeeded, extract the requested variable values.
        ( Outcome = success
        ->  ep_extract_vars(Vars, Bindings),
            EvalResult = success(Bindings)
        ;   EvalResult = Outcome
        )
    ;   true
    ).

% Define ep_extract_vars: collect Name=Value pairs for the given Vars list.
ep_extract_vars([], []).
% Define ep_extract_vars: build a Name=Value pair for each element.
ep_extract_vars([Name=Var | Rest], [Name=Var | Bindings]) :-
    % Recurse over the rest of the variables.
    ep_extract_vars(Rest, Bindings).

% ---------------------------------------------------------------------------
% ep_shell/3 -- execute a command argv list, capture stdout/stderr/exitcode
%
% Argv = [Command | Args] where Command is found on the system PATH.
% TimeoutSecs is the wall-clock limit; exit code 124 signals a timeout.
% ShellResult = shell_result(ExitCode, Stdout, Stderr)
%   where Stdout and Stderr are atoms containing the captured output.
%
% Example:
%   ?- ep_shell(['echo', 'hello'], 5, shell_result(0, Out, Err)).
%   Out = 'hello\n', Err = ''.
% ---------------------------------------------------------------------------

% Define ep_shell: run the command with a time limit, return all outputs.
ep_shell(Argv, TimeoutSecs, ShellResult) :-
    % Destructure Argv into command and argument list.
    Argv = [Cmd | Args],
    % Attempt the subprocess with a time limit; catch timeout.
    catch(
        call_with_time_limit(
            TimeoutSecs,
            ep_shell_run(Cmd, Args, ShellResult)
        ),
        time_limit_exceeded,
        % Return exit code 124 (the standard timeout exit code) on timeout.
        ShellResult = shell_result(124, '', 'timeout exceeded')
    ).

% Define ep_shell_run: start process, drain pipes, wait for exit.
ep_shell_run(Cmd, Args, shell_result(ExitCode, Stdout, Stderr)) :-
    % Launch the subprocess with pipes for stdout and stderr.
    process_create(path(Cmd), Args,
                   [ stdout(pipe(OutStream)),
                     stderr(pipe(ErrStream)),
                     process(PID) ]),
    % Read all bytes from stdout (blocks until the pipe closes at process exit).
    read_stream_to_codes(OutStream, OutCodes),
    % Close the stdout pipe.
    close(OutStream),
    % Read all bytes from stderr.
    read_stream_to_codes(ErrStream, ErrCodes),
    % Close the stderr pipe.
    close(ErrStream),
    % Wait for the process to finish and capture the exit status.
    process_wait(PID, ExitStatus),
    % Map the exit status to a plain integer exit code.
    ep_exit_code(ExitStatus, ExitCode),
    % Convert the code lists to atoms.
    atom_codes(Stdout, OutCodes),
    atom_codes(Stderr, ErrCodes).

% Define ep_exit_code for a normal exit: extract the integer code.
ep_exit_code(exit(Code), Code) :- !.
% Define ep_exit_code for a signal kill: map to 128+Signal (Unix convention).
ep_exit_code(killed(Signal), Code) :-
    % Compute Unix-style exit code for signal termination.
    Code is 128 + Signal.
% Define ep_exit_code for any other status: return 1 (generic failure).
ep_exit_code(_, 1).

% ---------------------------------------------------------------------------
% ep_ephemeral/4 -- write a temp script, execute it, and clean up
%
% Language is one of: prolog, python, bash.
% Code is an atom containing the program text to execute.
% TimeoutSecs is the wall-clock limit for the subprocess.
% ShellResult = shell_result(ExitCode, Stdout, Stderr)
%
% The temp file is written to /tmp, executed, and deleted regardless of
% whether the script succeeds or fails.
%
% Example:
%   ?- ep_ephemeral(python, 'print(2 + 2)', 10, R).
%   R = shell_result(0, '4\n', '').
% ---------------------------------------------------------------------------

% Define ep_ephemeral: write temp file, run it, delete it.
ep_ephemeral(Language, Code, TimeoutSecs, ShellResult) :-
    % Build a unique temp file path for this language.
    ep_temp_path(Language, TmpPath),
    % Write the code to the temp file.
    ep_write_temp(TmpPath, Code),
    % Build the argv list for executing this language and file.
    ep_language_argv(Language, TmpPath, Argv),
    % Execute the temp file via ep_shell.
    ep_shell(Argv, TimeoutSecs, ShellResult),
    % Delete the temp file (ignore any delete error).
    catch(delete_file(TmpPath), _, true).

% Define ep_temp_path: generate a unique temp file path for a language.
ep_temp_path(Language, TmpPath) :-
    % Look up the file extension for this language.
    ep_language_ext(Language, Ext),
    % Generate a unique temp file name (SWI-Prolog built-in).
    tmp_file_name(prologai_ep, Base),
    % Append the extension to make the final path.
    atomic_list_concat([Base, '.', Ext], TmpPath).

% Define ep_language_ext for prolog: use .pl extension.
ep_language_ext(prolog, 'pl').
% Define ep_language_ext for python: use .py extension.
ep_language_ext(python, 'py').
% Define ep_language_ext for bash: use .sh extension.
ep_language_ext(bash, 'sh').

% Define ep_language_argv for prolog: run with swipl as a script.
ep_language_argv(prolog, TmpPath, ['swipl', TmpPath]).
% Define ep_language_argv for python: run with python3.
ep_language_argv(python, TmpPath, ['python3', TmpPath]).
% Define ep_language_argv for bash: run with bash.
ep_language_argv(bash, TmpPath, ['bash', TmpPath]).

% Define ep_write_temp: open a file, write the code atom, close.
ep_write_temp(TmpPath, Code) :-
    % Open the temp file for writing.
    open(TmpPath, write, Stream, [encoding(utf8)]),
    % Write the code to the file.
    write_term(Stream, Code, [quoted(false)]),
    % Close the file so the subprocess can read it.
    close(Stream).

% ---------------------------------------------------------------------------
% ep_iterate/5 -- iterate synth-exec-check until CheckGoal succeeds or limit
%
% SynthGoal: called once per iteration with -Code; produces the code/goal.
% ExecGoal:  called with +Code and -Output; produces a result.
% CheckGoal: called with +Output; succeeds when the result is good enough.
% MaxIter:   maximum number of iterations before giving up.
% IterResult = iter_result(N, Code, Output) on success.
%              iter_exhausted(MaxIter, LastCode, LastOutput) when limit hit.
%
% Example usage:
%   SynthGoal = (Code = (X is 2+2)),
%   ExecGoal  = (ep_eval(Code, 5, Output)),
%   CheckGoal = (Output = success),
%   ep_iterate(SynthGoal, ExecGoal, CheckGoal, 5, R).
% ---------------------------------------------------------------------------

% Define ep_iterate: delegate to the loop with iteration counter at 1.
ep_iterate(SynthGoal, ExecGoal, CheckGoal, MaxIter, IterResult) :-
    % Start the iteration loop at step 1.
    ep_iterate_loop(SynthGoal, ExecGoal, CheckGoal, MaxIter, 1,
                    _LastCode, _LastOutput, IterResult).

% Base case: iteration limit reached; return exhausted result.
ep_iterate_loop(_Synth, _Exec, _Check, MaxIter, N, LastCode, LastOutput,
                iter_exhausted(MaxIter, LastCode, LastOutput)) :-
    % When the current iteration number exceeds the maximum, stop.
    N > MaxIter, !.
% Recursive case: synthesize, execute, check, then decide.
ep_iterate_loop(SynthGoal, ExecGoal, CheckGoal, MaxIter, N, _, _,
                IterResult) :-
    % Call SynthGoal to produce the code for this iteration.
    call(SynthGoal, Code),
    % Call ExecGoal to execute the code and produce output.
    call(ExecGoal, Code, Output),
    % Check whether the output meets the success criterion.
    ( call(CheckGoal, Output)
    % If CheckGoal succeeds, the result is a success.
    ->  IterResult = iter_result(N, Code, Output)
    % Otherwise, continue to the next iteration.
    ;   N1 is N + 1,
        ep_iterate_loop(SynthGoal, ExecGoal, CheckGoal, MaxIter, N1,
                        Code, Output, IterResult)
    ).
