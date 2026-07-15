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

    Skill persistence:
       - ephemera_skill_save/4 names, stores, and indexes a useful ephemeron so it
         can be retrieved and re-run by name rather than re-synthesized.
       - ephemera_skill_lookup/3 retrieves a saved skill's language and code.
       - ephemera_skill_run/3 looks up a skill by name and runs it immediately.
       - ephemera_skill_list/1 returns all saved skills as indexed terms.
       - ephemera_skill_forget/1 removes a saved skill when it is no longer needed.

    Three execution modes:

    1. Prolog goal evaluation (ephemera_eval/3)
       - GoalTerm is a Prolog compound term already in memory.
       - call_with_time_limit evaluates it with a hard wall-clock limit.
       - Variable bindings from the goal survive in the caller's scope.
       - This is the fastest and most integrated mode; no subprocess.

    2. Shell execution (ephemera_shell/3)
       - Argv = [Command | Args] where Command is on PATH.
       - process_create launches it; stdout and stderr are captured.
       - Exit code, stdout atom, and stderr atom are returned.
       - Used for any OS-level operation: ls, grep, python3, swipl, etc.

    3. Ephemeral scripting (ephemera_ephemeral/4)
       - PrologAI writes Code to a uniquely named temp file.
       - The file is executed via ephemera_shell and then deleted unconditionally.
       - Supported languages: prolog, python, bash.
       - Used when code is produced as text (a string or atom) rather than
         as a goal term already in memory.

    Iteration (ephemera_iterate/5):
       - Calls SynthGoal to produce code, ExecGoal to run it, CheckGoal to
         test success.  Repeats up to MaxIter times.
       - Models the write-run-observe-improve loop used by coding agents.

    Trace log:
       - ephemera_trace_record/4 writes a step to the trace log.
       - ephemera_trace_get/2 retrieves the full trace for a run.
       - ephemera_next_trace_id/1 allocates a fresh trace id.

    Predicates:
      ephemera_eval/3          -- evaluate a Prolog goal term with timeout
      ephemera_scratch/4       -- evaluate a Prolog code atom in the current process
      ephemera_shell/3         -- execute an argv list with timeout, capture output
      ephemera_ephemeral/4     -- write temp script, execute, clean up
      ephemera_iterate/5       -- iterate synth-exec-check until success or limit
      ephemera_trace_record/4  -- record one step to the trace log
      ephemera_trace_get/2     -- retrieve all trace entries for a trace id
      ephemera_next_trace_id/1 -- allocate a fresh unique trace id
      ephemera_skill_save/4    -- save a named, reusable skill with description
      ephemera_skill_lookup/3  -- retrieve a saved skill by name
      ephemera_skill_run/3     -- execute a saved skill by name
      ephemera_skill_list/1    -- list all saved skills
      ephemera_skill_forget/1  -- remove a saved skill by name
*/

% Declare this file as the 'ephemera' module and list its exported predicates.
:- module(ephemera, [
    % Export 'ephemera_eval/3': evaluate a Prolog goal term with a timeout.
    ephemera_eval/3,          % +GoalTerm, +TimeoutSecs, -EvalResult
    % Export 'ephemera_scratch/4': evaluate a Prolog code atom in the current process.
    ephemera_scratch/4,       % +CodeAtom, +Vars, +TimeoutSecs, -EvalResult
    % Export 'ephemera_shell/3': execute a command argv list with timeout.
    ephemera_shell/3,         % +Argv, +TimeoutSecs, -ShellResult
    % Export 'ephemera_ephemeral/4': write temp script, execute, clean up.
    ephemera_ephemeral/4,     % +Language, +Code, +TimeoutSecs, -ShellResult
    % Export 'ephemera_iterate/5': iterate synth-exec-check until success or limit.
    ephemera_iterate/5,       % :SynthGoal, :ExecGoal, :CheckGoal, +MaxIter, -IterResult
    % Export 'ephemera_trace_record/4': record one step to the trace log.
    ephemera_trace_record/4,  % +TraceId, +Iter, +Code, +Output
    % Export 'ephemera_trace_get/2': retrieve all trace entries for a trace id.
    ephemera_trace_get/2,     % +TraceId, -Entries
    % Export 'ephemera_next_trace_id/1': allocate a fresh unique trace id.
    ephemera_next_trace_id/1, % -TraceId
    % Export 'ephemera_skill_save/4': save a named, reusable skill with description.
    ephemera_skill_save/4,    % +Name, +Language, +Code, +Description
    % Export 'ephemera_skill_lookup/3': retrieve a saved skill by name.
    ephemera_skill_lookup/3,  % +Name, -Language, -Code
    % Export 'ephemera_skill_run/3': execute a saved skill by name.
    ephemera_skill_run/3,     % +Name, +TimeoutSecs, -ShellResult
    % Export 'ephemera_skill_list/1': list all saved skills.
    ephemera_skill_list/1,    % -Skills
    % Export 'ephemera_skill_forget/1': remove a saved skill by name.
    ephemera_skill_forget/1   % +Name
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

% Declare ephemera_trace_entry/4 as dynamic: (TraceId, Iter, Code, Output).
:- dynamic ephemera_trace_entry/4.
% Declare ephemera_trace_counter/1 as dynamic for allocating trace IDs.
:- dynamic ephemera_trace_counter/1.
% Initialize the trace counter at zero.
ephemera_trace_counter(0).

% ---------------------------------------------------------------------------
% ephemera_next_trace_id/1 -- allocate a fresh unique trace ID
% ---------------------------------------------------------------------------

% Define ephemera_next_trace_id: retract the counter, increment, reassert, build atom.
ephemera_next_trace_id(Id) :-
    % Remove the current counter fact.
    retract(ephemera_trace_counter(N)),
    % Increment the counter.
    N1 is N + 1,
    % Store the new counter value.
    assertz(ephemera_trace_counter(N1)),
    % Build the trace ID atom from the prefix and counter.
    atomic_list_concat([ephemera_trace_, N1], Id).

% ---------------------------------------------------------------------------
% ephemera_trace_record/4 -- record one synthesis-execution step to the trace log
% ---------------------------------------------------------------------------

% Define ephemera_trace_record: assert one entry into the trace log.
ephemera_trace_record(TraceId, Iter, Code, Output) :-
    % Assert the trace entry as a dynamic fact.
    assertz(ephemera_trace_entry(TraceId, Iter, Code, Output)).

% ---------------------------------------------------------------------------
% ephemera_trace_get/2 -- retrieve all trace entries for a given trace id
% ---------------------------------------------------------------------------

% Define ephemera_trace_get: collect all entries for a TraceId into Entries.
ephemera_trace_get(TraceId, Entries) :-
    % Collect all matching trace entries.
    findall(step(Iter, Code, Output),
            ephemera_trace_entry(TraceId, Iter, Code, Output),
            Entries).

% ---------------------------------------------------------------------------
% ephemera_eval/3 -- evaluate a Prolog goal term with a wall-clock time limit
%
% EvalResult is one of:
%   success          -- GoalTerm succeeded; any variable bindings are live
%   fail             -- GoalTerm failed; no variable bindings
%   timeout          -- time limit exceeded before GoalTerm returned
%   error(Exception) -- GoalTerm threw an exception
%
% Example:
%   ?- ephemera_eval((X is 2 + 2), 5, R).
%   X = 4, R = success.
% ---------------------------------------------------------------------------

% Define ephemera_eval: evaluate GoalTerm with a time limit, classify the outcome.
ephemera_eval(GoalTerm, TimeoutSecs, EvalResult) :-
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
        ephemera_classify_exception(Exception, EvalResult)
    ).

% Define ephemera_classify_exception for time_limit_exceeded: return timeout.
ephemera_classify_exception(time_limit_exceeded, timeout) :- !.
% Define ephemera_classify_exception for all other exceptions: wrap in error/1.
ephemera_classify_exception(E, error(E)).

% ---------------------------------------------------------------------------
% ephemera_scratch/4 -- evaluate a Prolog code atom in the current process
%
% CodeAtom is a Prolog term written as an atom, e.g. 'X is 2 + 2'.
% Vars is a list of Name=Var pairs for variables you want to inspect.
% TimeoutSecs is the wall-clock limit.
% EvalResult is success(Bindings), fail, timeout, or error(E).
%   Bindings = list of Name=Value pairs for variables named in Vars.
%
% Example:
%   ?- ephemera_scratch('X is 2 + 2', ['X'=X], 5, R).
%   R = success(['X'=4]).
% ---------------------------------------------------------------------------

% Define ephemera_scratch: parse the code atom into a goal, evaluate, extract bindings.
ephemera_scratch(CodeAtom, Vars, TimeoutSecs, EvalResult) :-
    % Parse the atom into a goal term with named variable bindings.
    catch(
        atom_to_term(CodeAtom, Goal, _NamedVars),
        ParseError,
        ( EvalResult = error(parse_error(ParseError)), ! )
    ),
    % Evaluate the parsed goal with a time limit.
    ( var(EvalResult)
    ->  ephemera_eval(Goal, TimeoutSecs, Outcome),
        % If the goal succeeded, extract the requested variable values.
        ( Outcome = success
        ->  ephemera_extract_vars(Vars, Bindings),
            EvalResult = success(Bindings)
        ;   EvalResult = Outcome
        )
    ;   true
    ).

% Define ephemera_extract_vars: collect Name=Value pairs for the given Vars list.
ephemera_extract_vars([], []).
% Define ephemera_extract_vars: build a Name=Value pair for each element.
ephemera_extract_vars([Name=Var | Rest], [Name=Var | Bindings]) :-
    % Recurse over the rest of the variables.
    ephemera_extract_vars(Rest, Bindings).

% ---------------------------------------------------------------------------
% ephemera_shell/3 -- execute a command argv list, capture stdout/stderr/exitcode
%
% Argv = [Command | Args] where Command is found on the system PATH.
% TimeoutSecs is the wall-clock limit; exit code 124 signals a timeout.
% ShellResult = shell_result(ExitCode, Stdout, Stderr)
%   where Stdout and Stderr are atoms containing the captured output.
%
% Example:
%   ?- ephemera_shell(['echo', 'hello'], 5, shell_result(0, Out, Err)).
%   Out = 'hello\n', Err = ''.
% ---------------------------------------------------------------------------

% Define ephemera_shell: run the command with a time limit, return all outputs.
ephemera_shell(Argv, TimeoutSecs, ShellResult) :-
    % Destructure Argv into command and argument list.
    Argv = [Cmd | Args],
    % Attempt the subprocess with a time limit; catch timeout.
    catch(
        call_with_time_limit(
            TimeoutSecs,
            ephemera_shell_run(Cmd, Args, ShellResult)
        ),
        time_limit_exceeded,
        % Return exit code 124 (the standard timeout exit code) on timeout.
        ShellResult = shell_result(124, '', 'timeout exceeded')
    ).

% Define ephemera_shell_run: start process, drain pipes, wait for exit.
ephemera_shell_run(Cmd, Args, shell_result(ExitCode, Stdout, Stderr)) :-
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
    ephemera_exit_code(ExitStatus, ExitCode),
    % Convert the code lists to atoms.
    atom_codes(Stdout, OutCodes),
    atom_codes(Stderr, ErrCodes).

% Define ephemera_exit_code for a normal exit: extract the integer code.
ephemera_exit_code(exit(Code), Code) :- !.
% Define ephemera_exit_code for a signal kill: map to 128+Signal (Unix convention).
ephemera_exit_code(killed(Signal), Code) :-
    % Compute Unix-style exit code for signal termination.
    Code is 128 + Signal.
% Define ephemera_exit_code for any other status: return 1 (generic failure).
ephemera_exit_code(_, 1).

% ---------------------------------------------------------------------------
% ephemera_ephemeral/4 -- write a temp script, execute it, and clean up
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
%   ?- ephemera_ephemeral(python, 'print(2 + 2)', 10, R).
%   R = shell_result(0, '4\n', '').
% ---------------------------------------------------------------------------

% Define ephemera_ephemeral: write temp file, run it, delete it.
ephemera_ephemeral(Language, Code, TimeoutSecs, ShellResult) :-
    % Build a unique temp file path for this language.
    ephemera_temp_path(Language, TmpPath),
    % Write the code to the temp file.
    ephemera_write_temp(TmpPath, Code),
    % Build the argv list for executing this language and file.
    ephemera_language_argv(Language, TmpPath, Argv),
    % Execute the temp file via ephemera_shell.
    ephemera_shell(Argv, TimeoutSecs, ShellResult),
    % Delete the temp file (ignore any delete error).
    catch(delete_file(TmpPath), _, true).

% Define ephemera_temp_path: generate a unique temp file path for a language.
ephemera_temp_path(Language, TmpPath) :-
    % Look up the file extension for this language.
    ephemera_language_ext(Language, Ext),
    % Generate a unique temp file path (SWI-Prolog built-in tmp_file/2).
    tmp_file(prologai_ep, Base),
    % Append the extension to make the final path.
    atomic_list_concat([Base, '.', Ext], TmpPath).

% Define ephemera_language_ext for prolog: use .pl extension.
ephemera_language_ext(prolog, 'pl').
% Define ephemera_language_ext for python: use .py extension.
ephemera_language_ext(python, 'py').
% Define ephemera_language_ext for bash: use .sh extension.
ephemera_language_ext(bash, 'sh').

% Define ephemera_language_argv for prolog: run with swipl as a script.
ephemera_language_argv(prolog, TmpPath, ['swipl', TmpPath]).
% Define ephemera_language_argv for python: run with python3.
ephemera_language_argv(python, TmpPath, ['python3', TmpPath]).
% Define ephemera_language_argv for bash: run with bash.
ephemera_language_argv(bash, TmpPath, ['bash', TmpPath]).

% Define ephemera_write_temp: open a file, write the code atom, close.
ephemera_write_temp(TmpPath, Code) :-
    % Open the temp file for writing.
    open(TmpPath, write, Stream, [encoding(utf8)]),
    % Write the code to the file.
    write_term(Stream, Code, [quoted(false)]),
    % Close the file so the subprocess can read it.
    close(Stream).

% ---------------------------------------------------------------------------
% ephemera_iterate/5 -- iterate synth-exec-check until CheckGoal succeeds or limit
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
%   ExecGoal  = (ephemera_eval(Code, 5, Output)),
%   CheckGoal = (Output = success),
%   ephemera_iterate(SynthGoal, ExecGoal, CheckGoal, 5, R).
% ---------------------------------------------------------------------------

% Define ephemera_iterate: delegate to the loop with iteration counter at 1.
ephemera_iterate(SynthGoal, ExecGoal, CheckGoal, MaxIter, IterResult) :-
    % Start the iteration loop at step 1.
    ephemera_iterate_loop(SynthGoal, ExecGoal, CheckGoal, MaxIter, 1,
                    _LastCode, _LastOutput, IterResult).

% Base case: iteration limit reached; return exhausted result.
ephemera_iterate_loop(_Synth, _Exec, _Check, MaxIter, N, LastCode, LastOutput,
                iter_exhausted(MaxIter, LastCode, LastOutput)) :-
    % When the current iteration number exceeds the maximum, stop.
    N > MaxIter, !.
% Recursive case: synthesize, execute, check, then decide.
ephemera_iterate_loop(SynthGoal, ExecGoal, CheckGoal, MaxIter, N, _, _,
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
        ephemera_iterate_loop(SynthGoal, ExecGoal, CheckGoal, MaxIter, N1,
                        Code, Output, IterResult)
    ).

% ---------------------------------------------------------------------------
% Skill persistence -- name, save, index, retrieve, run, and forget ephemera
%
% An ephemeron that proves useful can be promoted to a named skill.  Skills
% are stored in the ephemera_skill_db/4 dynamic fact and are retrievable by name
% at any point in the session.  Naming a skill allows the same computation
% to be reused without re-synthesis.
%
% Skill database schema:
%   ephemera_skill_db(Name, Language, Code, Description)
%     Name        -- unique atom identifying the skill
%     Language    -- prolog | python | bash (same as ephemera_ephemeral/4)
%     Code        -- the source text of the skill as an atom
%     Description -- human-readable label for indexing and search
% ---------------------------------------------------------------------------

% Declare ephemera_skill_db/4 as dynamic: the in-memory skill index.
:- dynamic ephemera_skill_db/4.

% ---------------------------------------------------------------------------
% ephemera_skill_save/4 -- save a named, reusable skill with a description
%
% Replaces any existing skill with the same Name so that updating a skill
% is idempotent (save it again with corrected code and the old version is gone).
%
% Example:
%   ephemera_skill_save(greet, python, 'print("Hello from Mentova")',
%                 'Print a greeting from Mentova').
% ---------------------------------------------------------------------------

% Define ephemera_skill_save/4: replace any existing entry, then store the new one.
ephemera_skill_save(Name, Language, Code, Description) :-
    % Remove any previous skill registered under this name.
    retractall(ephemera_skill_db(Name, _, _, _)),
    % Store the new skill in the database.
    assertz(ephemera_skill_db(Name, Language, Code, Description)).

% ---------------------------------------------------------------------------
% ephemera_skill_lookup/3 -- retrieve a saved skill's language and code by name
%
% Fails silently if no skill with Name has been saved.
%
% Example:
%   ephemera_skill_lookup(greet, Lang, Code).
%   Lang = python, Code = 'print("Hello from Mentova")'.
% ---------------------------------------------------------------------------

% Define ephemera_skill_lookup/3: unify Language and Code from the skill database.
ephemera_skill_lookup(Name, Language, Code) :-
    % Look up the named skill; ignore the description field.
    ephemera_skill_db(Name, Language, Code, _).

% ---------------------------------------------------------------------------
% ephemera_skill_run/3 -- execute a saved skill by name
%
% Looks up the skill for Name and passes its code to ephemera_ephemeral/4.
% ShellResult = shell_result(ExitCode, Stdout, Stderr).
%
% Example:
%   ephemera_skill_run(greet, 10, shell_result(0, Out, _)).
%   Out = 'Hello from Mentova\n'.
% ---------------------------------------------------------------------------

% Define ephemera_skill_run/3: look up and run a named skill as an ephemeron.
ephemera_skill_run(Name, TimeoutSecs, ShellResult) :-
    % Retrieve the skill's language and source code.
    ephemera_skill_lookup(Name, Language, Code),
    % Execute the code via the standard ephemeral path.
    ephemera_ephemeral(Language, Code, TimeoutSecs, ShellResult).

% ---------------------------------------------------------------------------
% ephemera_skill_list/1 -- return all saved skills as a list of indexed terms
%
% Each element is skill(Name, Language, Description).
% Returns an empty list when no skills have been saved.
%
% Example:
%   ephemera_skill_list(Ss).
%   Ss = [skill(greet, python, 'Print a greeting from Mentova')].
% ---------------------------------------------------------------------------

% Define ephemera_skill_list/1: collect all skill entries into a structured list.
ephemera_skill_list(Skills) :-
    % Gather every skill's name, language, and description (not code).
    findall(skill(Name, Language, Description),
            ephemera_skill_db(Name, Language, _, Description),
            Skills).

% ---------------------------------------------------------------------------
% ephemera_skill_forget/1 -- remove a saved skill by name
%
% Succeeds silently if no skill with Name exists.
%
% Example:
%   ephemera_skill_forget(greet).
% ---------------------------------------------------------------------------

% Define ephemera_skill_forget/1: retract all entries for the given skill name.
ephemera_skill_forget(Name) :-
    % Remove every fact for this skill name from the database.
    retractall(ephemera_skill_db(Name, _, _, _)).
