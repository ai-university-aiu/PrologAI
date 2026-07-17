/*  PrologAI — Mini Regression Driver  (10 percent ARC-AGI spot-check)

    ADDITIVE HARNESS. This driver sits BESIDE the full ARC-AGI benchmark
    runners in the Mentova repository; it does not modify, replace, or
    duplicate them. It loads the SAME solving core and the SAME task facts
    the full runners use, then attempts ONLY the task identifiers listed in
    a fixed, committed manifest.

    Honesty note carried in the output: a green mini run detects GROSS
    breakage only. A regression confined to the 90 percent of tasks NOT in
    the manifest passes the mini run and is caught only by the final full
    regression. The mini result must never be used to assert or refresh the
    400/400 or 120/120 claims — those rest on the last FULL run alone.

    Entry points (selected by the shell runner):
        run_mini(arc1, ManifestPath) — ARC-AGI-1 spot-check
        run_mini(arc2, ManifestPath) — ARC-AGI-2 spot-check
    Each prints a glass-box per-task report and halts 0 iff every manifest
    task passes, non-zero otherwise.
*/

% Declare this file as the mini_regression_driver module, exporting run_mini/2.
:- module(mini_regression_driver, [run_mini/2]).

% Load list utilities for membership and length work.
:- use_module(library(lists), [member/2, exclude/3]).
% Load readutil for reading the manifest file line by line.
:- use_module(library(readutil), [read_line_to_string/2]).

% Resolve the PrologAI repository root from $PROLOGAI_HOME, or the local default.
prologai_home(Dir) :-
    % Prefer the PROLOGAI_HOME environment variable when it is set and non-empty.
    (   getenv('PROLOGAI_HOME', Env), Env \== ''
    ->  % Use the environment value verbatim.
        Dir = Env
    ;   % Fall back to the local development checkout path.
        Dir = '/home/ccaitwo/PrologAI'
    ).

% Resolve the Mentova repository root from $MENTOVA_HOME, or the local default.
% Mentova holds the ARC solving core and task facts; it is loaded read-only.
mentova_home(Dir) :-
    % Prefer the MENTOVA_HOME environment variable when it is set and non-empty.
    (   getenv('MENTOVA_HOME', Env), Env \== ''
    ->  % Use the environment value verbatim.
        Dir = Env
    ;   % Fall back to the local development checkout path.
        Dir = '/home/ccaitwo/Mentova'
    ).

% prologai_packs_dir(-Dir): the PrologAI pack directory (the core's libraries).
prologai_packs_dir(Dir) :-
    % Join the PrologAI root with the packs subdirectory.
    prologai_home(Home),
    % Build the absolute packs path.
    atomic_list_concat([Home, '/packs'], Dir).

% mentova_src_dir(-Dir): the Mentova source tree (the ARC solving core).
mentova_src_dir(Dir) :-
    % Join the Mentova root with the source subdirectory.
    mentova_home(Home),
    % Build the absolute source path.
    atomic_list_concat([Home, '/src/mentova'], Dir).

% arc1_tasks_file(-File): the ARC-AGI-1 task facts file (400 tasks).
arc1_tasks_file(File) :-
    % Join the Mentova root with the ARC-AGI-1 facts path.
    mentova_home(Home),
    % Build the absolute facts path.
    atomic_list_concat([Home, '/data/arc_agi_1/arc_tasks.pl'], File).

% arc2_tasks_file(-File): the ARC-AGI-2 task facts file (120 tasks).
arc2_tasks_file(File) :-
    % Join the Mentova root with the ARC-AGI-2 facts path.
    mentova_home(Home),
    % Build the absolute facts path.
    atomic_list_concat([Home, '/data/arc_agi_2/arc_tasks_2.pl'], File).

% arc1_runner_file(-File): the ARC-AGI-1 benchmark runner module.
arc1_runner_file(File) :-
    % Join the Mentova root with the ARC-AGI-1 runner path.
    mentova_home(Home),
    % Build the absolute runner path.
    atomic_list_concat([Home, '/src/mentova/games/arc_benchmark.pl'], File).

% arc2_runner_file(-File): the ARC-AGI-2 benchmark runner module.
arc2_runner_file(File) :-
    % Join the Mentova root with the ARC-AGI-2 runner path.
    mentova_home(Home),
    % Build the absolute runner path.
    atomic_list_concat([Home, '/src/mentova/games/arc_benchmark_2.pl'], File).

% run_mini(+Benchmark, +ManifestPath): top-level entry; boots the core, runs, halts.
run_mini(Benchmark, ManifestPath) :-
    % Attach the whole PrologAI pack directory so every library(...) resolves.
    prologai_packs_dir(Packs),
    % Register all packs, replacing any duplicate pack registration.
    attach_packs(Packs, [duplicate(replace)]),
    % Register the Mentova source path so library(...) imports resolve.
    mentova_src_dir(Src),
    % Make the Mentova source tree the first library search path.
    asserta(file_search_path(library, Src)),
    % Read the manifest identifiers (comments and blanks stripped).
    read_manifest(ManifestPath, Ids),
    % Report how many identifiers the manifest holds.
    length(Ids, Count),
    % Print the header naming the benchmark and manifest.
    format("~n=== Mini Regression: ~w (10 percent spot-check) ===~n", [Benchmark]),
    % Echo the manifest path for auditability.
    format("Manifest: ~w  (~w task ids)~n", [ManifestPath, Count]),
    % Verify the Mentova solving core is present before attempting to load it.
    preflight_core(Benchmark),
    % Dispatch to the benchmark-specific loader and runner.
    run_benchmark(Benchmark, Ids, Passed, Total),
    % Print the plain-language spot-check disclaimer required by the honesty rule.
    print_disclaimer,
    % Emit a stable machine-readable summary line for the shell runner to parse.
    format("MINI_RESULT ~w ~w ~w~n", [Benchmark, Passed, Total]),
    % Halt 0 when every manifest task passed, non-zero otherwise.
    ( Passed =:= Total -> halt(0) ; halt(1) ).

% preflight_core(+Benchmark): confirm the Mentova core files exist; halt clearly if not.
preflight_core(Benchmark) :-
    % Select the runner and tasks files for the requested benchmark.
    ( Benchmark == arc1 -> arc1_runner_file(Runner), arc1_tasks_file(Tasks)
    ; arc2_runner_file(Runner), arc2_tasks_file(Tasks) ),
    % Both the runner module and the task facts must be present on disk.
    (   exists_file(Runner), exists_file(Tasks)
    ->  % Core present: continue.
        true
    ;   % Core absent: explain the likely cause and halt with a distinct code.
        mentova_home(Home),
        % Print a plain-language diagnostic.
        format("~nERROR: the ARC solving core was not found.~n"),
        % Show where the driver looked.
        format("  Expected under MENTOVA_HOME = ~w~n", [Home]),
        % Name the two files it needs.
        format("  Missing one of:~n    ~w~n    ~w~n", [Runner, Tasks]),
        % Tell the operator how to fix it.
        format("  Set MENTOVA_HOME to the Mentova checkout, or clone Mentova beside PrologAI.~n"),
        % Halt with code 3 to distinguish a setup error from a real task failure.
        halt(3)
    ).

% read_manifest(+Path, -Ids): read non-comment, non-blank lines as atom ids.
read_manifest(Path, Ids) :-
    % Open the manifest file for reading.
    setup_call_cleanup(
        % Open the stream.
        open(Path, read, Stream),
        % Read every content line into a list of atoms.
        read_lines(Stream, Ids),
        % Always close the stream when done.
        close(Stream)
    ).

% read_lines(+Stream, -Ids): accumulate manifest ids, skipping headers and blanks.
read_lines(Stream, Ids) :-
    % Read the next line as a string, or end_of_file at the end.
    read_line_to_string(Stream, Line),
    % Branch on whether the stream is exhausted.
    (   Line == end_of_file
    ->  % No more lines: the id list is empty at this tail.
        Ids = []
    ;   % Trim leading and trailing whitespace from the line.
        normalize_space(atom(Trimmed), Line),
        % Decide whether this line carries a task id.
        (   is_id_line(Trimmed)
        ->  % Keep the id and continue reading the rest.
            Ids = [Trimmed | Rest],
            % Recurse on the remaining lines.
            read_lines(Stream, Rest)
        ;   % Skip this line (comment or blank) and continue.
            read_lines(Stream, Ids)
        )
    ).

% is_id_line(+Atom): true when the trimmed line is a real id, not a comment or blank.
is_id_line(Atom) :-
    % Reject the empty atom (blank line).
    Atom \== '',
    % Grab the first character code of the line.
    atom_codes(Atom, [First | _]),
    % Reject lines whose first character is the comment marker '#'.
    First \== 0'#.

% run_benchmark(+Benchmark, +Ids, -Passed, -Total): load the right core and run.
% ARC-AGI-1 branch: load task facts and runner, then attempt each manifest id.
run_benchmark(arc1, Ids, Passed, Total) :-
    % Locate the ARC-AGI-1 task facts file.
    arc1_tasks_file(TasksFile),
    % Load the 400 ARC-AGI-1 task facts into the arc_tasks module.
    use_module(TasksFile, [arc_agi_task/4]),
    % Locate the ARC-AGI-1 benchmark runner file.
    arc1_runner_file(RunnerFile),
    % Load the ARC-AGI-1 benchmark runner module (the solving core).
    use_module(RunnerFile),
    % Boot the Mentova stack the same way the full demo does.
    boot_mentova,
    % Attempt every manifest id through the ARC-AGI-1 attempt predicate.
    run_ids(arc1, Ids, Passed, Total).
% ARC-AGI-2 branch: load task facts and runner, then attempt each manifest id.
run_benchmark(arc2, Ids, Passed, Total) :-
    % Locate the ARC-AGI-2 task facts file.
    arc2_tasks_file(TasksFile),
    % Load the 120 ARC-AGI-2 task facts into the arc_tasks_2 module.
    use_module(TasksFile, [arc2_task/4]),
    % Locate the ARC-AGI-2 benchmark runner file.
    arc2_runner_file(RunnerFile),
    % Load the ARC-AGI-2 benchmark runner module (the solving core).
    use_module(RunnerFile),
    % Boot the Mentova stack the same way the full demo does.
    boot_mentova,
    % Attempt every manifest id through the ARC-AGI-2 attempt predicate.
    run_ids(arc2, Ids, Passed, Total).

% boot_mentova: boot the Mentova top level if it is available; ignore if absent.
boot_mentova :-
    % Boot Mentova when mentova_boot/0 is loaded and callable.
    (   current_predicate(mentova:mentova_boot/0)
    ->  % Call the boot entry point.
        mentova:mentova_boot
    ;   % Nothing to boot; proceed without it.
        true
    ).

% run_ids(+Benchmark, +Ids, -Passed, -Total): attempt each id, print, tally.
run_ids(Benchmark, Ids, Passed, Total) :-
    % Print the per-task results heading.
    format("~n--- Per-task results ---~n"),
    % Attempt each id, collecting a pass/fail outcome atom per id.
    attempt_all(Benchmark, Ids, Outcomes),
    % Count how many ids passed.
    include_pass(Outcomes, Passes),
    % The number of passes is the passed count.
    length(Passes, Passed),
    % The number of ids is the total count.
    length(Ids, Total),
    % Print the count summary line.
    format("~n--- Count ---~n  ~w / ~w tasks passed~n", [Passed, Total]).

% attempt_all(+Benchmark, +Ids, -Outcomes): map each id to pass(Id)/fail(Id).
% Base case: no ids left, no outcomes.
attempt_all(_, [], []).
% Recursive case: attempt the head id, then the tail.
attempt_all(Benchmark, [Id | Rest], [Outcome | More]) :-
    % Attempt this single id.
    attempt_one(Benchmark, Id, Outcome),
    % Attempt the remaining ids.
    attempt_all(Benchmark, Rest, More).

% attempt_one(+Benchmark, +Id, -Outcome): run one task; print PASS/FAIL/MISSING.
attempt_one(Benchmark, Id, Outcome) :-
    % Fetch the task facts for this id from the loaded core.
    (   task_of(Benchmark, Id, Task)
    ->  % Attempt the task through the benchmark's own attempt predicate.
        (   catch(attempt_task(Benchmark, Task, Rule), _E, fail),
            % A pass carries a named rule; a fail unifies Rule with the atom fail.
            Rule \== fail
        ->  % Record and print a pass with its glass-box rule name.
            Outcome = pass(Id),
            % Print the PASS line with the rule that solved it.
            format("  PASS     ~w   rule: ~w~n", [Id, Rule])
        ;   % Record and print a fail (task attempted but not solved).
            Outcome = fail(Id),
            % Print the FAIL line.
            format("  FAIL     ~w~n", [Id])
        )
    ;   % The id was not found among the loaded task facts.
        Outcome = fail(Id),
        % Print a MISSING line so a bad manifest id is visible, and count it as a fail.
        format("  MISSING  ~w   (id not present in loaded task facts)~n", [Id])
    ).

% task_of(+Benchmark, +Id, -Task): retrieve the task/4 term for an id.
% ARC-AGI-1: pull the four-argument task from the arc_tasks module.
task_of(arc1, Id, task(Id, TP, TI, TO)) :-
    % Look up the ARC-AGI-1 task facts by id.
    arc_tasks:arc_agi_task(Id, TP, TI, TO).
% ARC-AGI-2: pull the four-argument task from the arc_tasks_2 module.
task_of(arc2, Id, task(Id, TP, TI, TO)) :-
    % Look up the ARC-AGI-2 task facts by id.
    arc_tasks_2:arc2_task(Id, TP, TI, TO).

% attempt_task(+Benchmark, +Task, -Rule): call the core's own attempt predicate.
% ARC-AGI-1: dispatch through arc_benchmark:arc_attempt_task/2.
attempt_task(arc1, Task, Rule) :-
    % Run the ARC-AGI-1 attempt predicate on this task term.
    arc_benchmark:arc_attempt_task(Task, result(_, Result)),
    % Extract the rule name from a pass, or the atom fail from a fail.
    outcome_rule(Result, Rule).
% ARC-AGI-2: dispatch through arc_benchmark_2:arc2_attempt_task_/2.
attempt_task(arc2, Task, Rule) :-
    % Run the ARC-AGI-2 attempt predicate on this task term.
    arc_benchmark_2:arc2_attempt_task_(Task, result(_, Result)),
    % Extract the rule name from a pass, or the atom fail from a fail.
    outcome_rule(Result, Rule).

% outcome_rule(+Result, -Rule): unwrap pass(Rule) to Rule, fail to the atom fail.
% A passing result carries the solving rule.
outcome_rule(pass(R), R) :- !.
% Any other result is a failure, signalled by the atom fail.
outcome_rule(_, fail).

% include_pass(+Outcomes, -Passes): keep only the pass(_) outcomes.
include_pass(Outcomes, Passes) :-
    % Retain outcomes that unify with pass(_).
    exclude(is_fail_outcome, Outcomes, Passes).

% is_fail_outcome(+Outcome): true for a fail(_) outcome.
is_fail_outcome(fail(_)).

% print_disclaimer: print the plain-language spot-check honesty statement.
print_disclaimer :-
    % Blank line before the disclaimer block.
    format("~n--- Scope of this check ---~n"),
    % State plainly that this is a 10 percent spot-check.
    format("  This is a 10 percent spot-check of the ARC-AGI benchmark.~n"),
    % State plainly that the full regression is deferred.
    format("  The full regression is DEFERRED and run separately.~n"),
    % State plainly the blind spot: the untested 90 percent.
    format("  A regression confined to the untested 90 percent is NOT caught here.~n"),
    % State plainly that the benchmark claims rest on the last full run only.
    format("  The 400/400 and 120/120 claims rest on the last FULL run only.~n").
