/*  PrologAI — Refinery: Evaluator-Optimizer  (Specification PR 55)

    Gives PrologAI the ability to improve its own outputs through structured
    cycles of evaluation and refinement.  The Refinery is the metacognitive
    quality layer: it examines what was produced, scores it, generates
    improvement feedback, and drives iteration until a quality bar is met.

    Inspired by:
    - Agentic AI Principles Part 3.3 (self-correction and reflection)
    - Agentic AI Patterns Part 5.5 (evaluator-optimizer pattern)
    - Coding Design Principles Parts 11-12 (robustness, testing principles)
    - Coding Design Patterns Part 4.7 (Strategy pattern) and Part 4.8 (State)
    - The silicon-and-code substrate approach: use proven quality-improvement
      patterns (evaluate, critique, improve, repeat) rather than hoping the
      first answer is good enough.

    Core concepts:

    Criteria: a list of criterion(Name, TestGoal) terms where TestGoal is
    called with the output under examination.  A criterion passes if its
    TestGoal succeeds, and fails if it raises an exception or fails.

    Critique: a list of found_issue(CriterionName, Severity) terms produced
    by running all criteria against an output.  An empty list means the
    output passes all criteria.

    Score: a float in [0.0, 1.0] computed as the fraction of criteria that
    pass.  A score of 1.0 means all criteria pass.

    Optimization loop (refinery_optimize/5): repeatedly calls a Generator goal to
    produce candidates, an Evaluator goal to score them, and an Improver goal
    to refine failing candidates.  Stops when the score meets or exceeds a
    quality bar or when MaxIter iterations are exhausted.

    Path exploration (refinery_explore_paths/4): calls an Explorer goal N times,
    each time with a different path ID, scores each path's output, and
    returns the paths ranked by score.  This implements the multi-path
    reasoning strategy.

    Lessons (refinery_learn/3, refinery_recall/2, refinery_forget/1): a small persistent
    knowledge base of lessons learned from past failures.  PrologAI can
    record what went wrong, look up past lessons before tackling a problem,
    and discard lessons that are no longer relevant.

    Predicates:
      refinery_critique/4        -- examine output against criteria
      refinery_score/3           -- score output against criteria (0.0-1.0)
      refinery_improve/5         -- apply one round of improvement using critique
      refinery_optimize/5        -- full evaluator-optimizer loop
      refinery_explore_paths/4   -- explore N paths and rank by score
      refinery_learn/3           -- store a lesson from a failure
      refinery_recall/2          -- recall lessons for a problem type
      refinery_forget/1          -- clear lessons for a problem type
*/

% Declare this file as the 'refinery' module and list its exported predicates.
:- module(refinery, [
    % Export refinery_critique/4: examine output against a criteria list.
    refinery_critique/4,      % +Output, +Criteria, +MaxSteps, -Critique
    % Export refinery_score/3: score output against criteria; returns 0.0-1.0.
    refinery_score/3,         % +Output, +Criteria, -Score
    % Export refinery_improve/5: apply one improvement round using critique feedback.
    refinery_improve/5,       % +Output, +Criteria, :ImproverGoal, +MaxIter, -Improved
    % Export refinery_optimize/5: full evaluator-optimizer loop.
    refinery_optimize/5,      % :GeneratorGoal, :EvaluatorGoal, +QualityBar, +MaxIter, -Best
    % Export refinery_explore_paths/4: explore N paths and return ranked results.
    refinery_explore_paths/4, % +Problem, :ExplorerGoal, +NumPaths, -Ranked
    % Export refinery_learn/3: store a lesson learned from a failure.
    refinery_learn/3,         % +ProblemType, +FailurePattern, +Lesson
    % Export refinery_recall/2: retrieve lessons for a given problem type.
    refinery_recall/2,        % +ProblemType, -Lessons
    % Export refinery_forget/1: clear all lessons for a given problem type.
    refinery_forget/1         % +ProblemType
% Close the module declaration.
]).

% Import lists predicates for sorting and aggregation.
:- use_module(library(lists),     [member/2, last/2]).
% Import aggregate for counting.
:- use_module(library(aggregate), [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% refinery_lesson_db/3: (ProblemType, FailurePattern, Lesson) -- lessons learned.
:- dynamic refinery_lesson_db/3.

% refinery_attempt_log/4: (RunId, Iter, Output, Score) -- optimization run log.
:- dynamic refinery_attempt_log/4.

% refinery_run_counter/1: global counter for unique run IDs.
:- dynamic refinery_run_counter/1.
% Initialize the run counter.
refinery_run_counter(0).

% ---------------------------------------------------------------------------
% refinery_next_run_id/1 -- allocate a unique run ID for an optimization session
% ---------------------------------------------------------------------------

% Define refinery_next_run_id: increment counter, build atom ID.
refinery_next_run_id(RunId) :-
    % Retract the current counter.
    retract(refinery_run_counter(N)),
    % Increment.
    N1 is N + 1,
    % Reassert.
    assertz(refinery_run_counter(N1)),
    % Build the run ID atom.
    atomic_list_concat([refinery_run_, N1], RunId).

% ---------------------------------------------------------------------------
% refinery_critique/4 -- examine an output against a list of criteria
%
% Criteria: list of criterion(Name, TestGoal) where TestGoal is called
%   with the Output and succeeds if the criterion passes.
% Critique: list of found_issue(Name, fail) for each criterion that fails.
%   An empty Critique means the output passes all criteria.
%
% MaxSteps: maximum total evaluation time in seconds across all criteria.
%
% Example:
%   Criteria = [criterion(non_empty, (Output \= []))],
%   refinery_critique([], Criteria, 5, C).
%   C = [found_issue(non_empty, fail)].
% ---------------------------------------------------------------------------

% Define refinery_critique: collect failing criterion names into a critique list.
refinery_critique(Output, Criteria, MaxSteps, Critique) :-
    % Evaluate each criterion and collect failures.
    findall(found_issue(Name, fail),
            ( member(criterion(Name, TestGoal), Criteria),
              % The criterion fails if its TestGoal fails or throws within budget.
              \+ catch(
                     call_with_time_limit(MaxSteps, call(TestGoal, Output)),
                     _,
                     fail
                 )
            ),
            Critique).

% ---------------------------------------------------------------------------
% refinery_score/3 -- score an output against criteria; returns a float in [0.0,1.0]
%
% Score = number of passing criteria / total criteria.
% Returns 1.0 for an empty criteria list (vacuously perfect).
%
% Example:
%   Criteria = [criterion(non_empty, (\= [])), criterion(short, (length(O,L), L < 5))],
%   refinery_score([a,b], Criteria, S).
%   S = 0.5.   % non_empty passes; short fails for length 2... wait, 2 < 5 passes.
%   S = 1.0.
% ---------------------------------------------------------------------------

% Define refinery_score: compute fraction of passing criteria.
refinery_score(Output, Criteria, Score) :-
    % Count total criteria.
    length(Criteria, Total),
    % Handle empty criteria list: vacuously perfect.
    ( Total =:= 0
    ->  Score = 1.0
    % Otherwise count passing criteria.
    ;   aggregate_all(count,
                     ( member(criterion(_, TestGoal), Criteria),
                       catch(call(TestGoal, Output), _, fail)
                     ),
                     Passing),
        Score is float(Passing) / float(Total)
    ).

% ---------------------------------------------------------------------------
% refinery_improve/5 -- apply one improvement round using critique feedback
%
% ImproverGoal is called as: call(ImproverGoal, Output, Critique, Improved).
% Repeats up to MaxIter times.
% Returns the first Improved output that has an empty critique,
% or the best-so-far if MaxIter is exhausted.
%
% Example:
%   Improver = [O, C, I]>>(length(O, L), I = [better|O]),
%   refinery_improve([a], Criteria, Improver, 3, Best).
% ---------------------------------------------------------------------------

% Define refinery_improve: critique → improve → recheck, up to MaxIter rounds.
refinery_improve(Output, Criteria, ImproverGoal, MaxIter, Improved) :-
    % Delegate to the iterative helper with iteration count starting at 1.
    refinery_improve_loop(Output, Criteria, ImproverGoal, MaxIter, 1, Improved).

% Base case: zero or fewer iterations remaining; return what we have.
refinery_improve_loop(Best, _Criteria, _Improver, MaxIter, N, Best) :-
    % When the iteration count exceeds the max, return the best so far.
    N > MaxIter, !.
% Recursive case: critique → if empty, done; else improve and recurse.
refinery_improve_loop(Current, Criteria, ImproverGoal, MaxIter, N, Improved) :-
    % Critique the current output.
    refinery_critique(Current, Criteria, 30, Critique),
    % If critique is empty, the current output passes all criteria.
    ( Critique = []
    ->  Improved = Current
    % Otherwise, apply the improver and recurse.
    ;   call(ImproverGoal, Current, Critique, Next),
        N1 is N + 1,
        refinery_improve_loop(Next, Criteria, ImproverGoal, MaxIter, N1, Improved)
    ).

% ---------------------------------------------------------------------------
% refinery_optimize/5 -- full evaluator-optimizer loop
%
% GeneratorGoal: called as call(GeneratorGoal, -Output); produces a candidate.
% EvaluatorGoal: called as call(EvaluatorGoal, +Output, -Score); scores it.
% QualityBar: a float in [0.0,1.0]; stop when Score >= QualityBar.
% MaxIter: maximum number of iterations.
% Best: the best output found (highest score, or last produced if tied).
%
% Logs each attempt to refinery_attempt_log/4 for inspection.
% ---------------------------------------------------------------------------

% Define refinery_optimize: allocate a run ID and start the optimization loop.
refinery_optimize(GeneratorGoal, EvaluatorGoal, QualityBar, MaxIter, Best) :-
    % Allocate a run ID for logging.
    refinery_next_run_id(RunId),
    % Delegate to the optimization loop.
    refinery_optimize_loop(RunId, GeneratorGoal, EvaluatorGoal,
                     QualityBar, MaxIter, 1, none, 0.0, Best).

% Base case: iteration limit exhausted; return the best seen so far.
refinery_optimize_loop(_RunId, _Gen, _Eval, _Bar, MaxIter, N,
                 CurrentBest, _BestScore, CurrentBest) :-
    % When iterations exceed the max, stop and return the best candidate.
    N > MaxIter, !.
% Recursive case: generate → evaluate → update best → maybe stop.
refinery_optimize_loop(RunId, GeneratorGoal, EvaluatorGoal, QualityBar,
                 MaxIter, N, CurrentBest, BestScore, Best) :-
    % Generate a new candidate.
    call(GeneratorGoal, Candidate),
    % Evaluate the candidate.
    call(EvaluatorGoal, Candidate, Score),
    % Log this attempt.
    assertz(refinery_attempt_log(RunId, N, Candidate, Score)),
    % Update the best candidate if this score is higher.
    ( Score > BestScore
    ->  NewBest = Candidate, NewBestScore = Score
    ;   NewBest = CurrentBest, NewBestScore = BestScore
    ),
    % Check if the quality bar is met.
    ( Score >= QualityBar
    % Quality bar met; return this candidate as the best.
    ->  Best = Candidate
    % Bar not met; continue iterating.
    ;   N1 is N + 1,
        refinery_optimize_loop(RunId, GeneratorGoal, EvaluatorGoal, QualityBar,
                         MaxIter, N1, NewBest, NewBestScore, Best)
    ).

% ---------------------------------------------------------------------------
% refinery_explore_paths/4 -- explore N reasoning paths and rank by score
%
% Problem: any term describing the problem to solve.
% ExplorerGoal: called as call(ExplorerGoal, +Problem, +PathId, -Output, -Score).
% NumPaths: how many paths to explore.
% Ranked: list of ranked_path(PathId, Score, Output) sorted by Score descending.
%
% This implements the multi-path reasoning strategy: try N different
% approaches to the same problem and pick the one that scores highest.
% ---------------------------------------------------------------------------

% Define refinery_explore_paths: explore each path, score it, sort results.
refinery_explore_paths(Problem, ExplorerGoal, NumPaths, Ranked) :-
    % Collect results for all path IDs from 1 to NumPaths.
    findall(
        Score-ranked_path(PathId, Score, Output),
        ( between(1, NumPaths, PathId),
          call(ExplorerGoal, Problem, PathId, Output, Score)
        ),
        ScoredPaths
    ),
    % Sort by score (ascending) to enable largest-first after reversal.
    msort(ScoredPaths, SortedAsc),
    % Reverse to get descending order (highest score first).
    reverse_list(SortedAsc, SortedDesc),
    % Extract just the ranked_path terms, dropping the sort key.
    pairs_values(SortedDesc, Ranked).

% Define reverse_list: helper to reverse a list.
reverse_list(List, Reversed) :-
    % Use the accumulator-style reversal.
    reverse_list_acc(List, [], Reversed).
% Base case: empty input, accumulator is the result.
reverse_list_acc([], Acc, Acc).
% Recursive case: push head onto accumulator.
reverse_list_acc([H|T], Acc, Result) :-
    reverse_list_acc(T, [H|Acc], Result).

% Define pairs_values: extract the second element from each key-value pair.
pairs_values([], []).
% Define pairs_values: head case — extract value from the pair.
pairs_values([_K-V | Rest], [V | Vals]) :-
    pairs_values(Rest, Vals).

% ---------------------------------------------------------------------------
% refinery_learn/3 -- store a lesson learned from a past failure
%
% ProblemType: an atom or term categorizing the type of problem.
% FailurePattern: a term describing the pattern of failure observed.
% Lesson: a term containing the lesson learned (what to do differently).
%
% Lessons are recalled by problem type to inform future attempts.
% ---------------------------------------------------------------------------

% Define refinery_learn: assert a new lesson fact.
refinery_learn(ProblemType, FailurePattern, Lesson) :-
    % Store the lesson as a dynamic fact.
    assertz(refinery_lesson_db(ProblemType, FailurePattern, Lesson)).

% ---------------------------------------------------------------------------
% refinery_recall/2 -- recall all lessons stored for a given problem type
% ---------------------------------------------------------------------------

% Define refinery_recall: collect all lessons matching the problem type.
refinery_recall(ProblemType, Lessons) :-
    % Collect all matching lesson records.
    findall(lesson(FailurePattern, Lesson),
            refinery_lesson_db(ProblemType, FailurePattern, Lesson),
            Lessons).

% ---------------------------------------------------------------------------
% refinery_forget/1 -- clear all lessons for a given problem type
% ---------------------------------------------------------------------------

% Define refinery_forget: retract all lessons for the problem type.
refinery_forget(ProblemType) :-
    % Remove all matching lesson facts.
    retractall(refinery_lesson_db(ProblemType, _, _)).
