/*  PrologAI — Refinery Unit Tests  (PR 55)

    Acceptance criteria:
        AC-RN-001: rn_critique/4 returns empty critique when all criteria pass
        AC-RN-002: rn_critique/4 returns issues for failing criteria
        AC-RN-003: rn_score/3 returns 1.0 when all criteria pass
        AC-RN-004: rn_score/3 returns 0.0 when no criteria pass
        AC-RN-005: rn_score/3 returns partial score for mixed results
        AC-RN-006: rn_optimize/5 stops when quality bar is met
        AC-RN-007: rn_optimize/5 returns best found when MaxIter is exhausted
        AC-RN-008: rn_learn/3 stores a lesson in the lesson database
        AC-RN-009: rn_recall/2 retrieves lessons for a given problem type
        AC-RN-010: rn_forget/1 clears lessons for a given problem type
*/

% Declare this file as the 'test_refinery' module.
:- module(test_refinery, []).

% Load the PLUnit testing framework.
:- use_module(library(plunit)).
% Load the refinery module under test.
:- use_module(library(refinery)).

% Begin the test suite.
:- begin_tests(refinery).

% Shared criteria using lambda goals (YALL >>): fully portable across modules.
% non_empty passes when O is not an empty list.
% short passes when O has fewer than 5 elements.

% AC-RN-001: rn_critique/4 returns empty critique when all criteria pass.
test(critique_all_pass, []) :-
    % A non-empty list passes both criteria.
    Output = [a, b, c],
    % Use YALL lambda goals so they work in any calling module.
    Criteria = [criterion(non_empty, [O]>>(O \= [])),
                criterion(short,     [O]>>(length(O, L), L < 5))],
    rn_critique(Output, Criteria, 5, Critique),
    % Critique must be empty when everything passes.
    Critique = [].

% AC-RN-002: rn_critique/4 returns issues for failing criteria.
test(critique_some_fail, [nondet]) :-
    % An empty list fails the non_empty criterion.
    Output = [],
    Criteria = [criterion(non_empty, [O]>>(O \= [])),
                criterion(short,     [O]>>(length(O, L), L < 5))],
    rn_critique(Output, Criteria, 5, Critique),
    % non_empty must appear in the critique.
    member(found_issue(non_empty, fail), Critique).

% AC-RN-003: rn_score/3 returns 1.0 when all criteria pass.
test(score_all_pass, []) :-
    % A list of two elements passes both criteria.
    Output = [x, y],
    Criteria = [criterion(non_empty, [O]>>(O \= [])),
                criterion(short,     [O]>>(length(O, L), L < 5))],
    rn_score(Output, Criteria, Score),
    % Score must be 1.0.
    Score =:= 1.0.

% AC-RN-004: rn_score/3 returns 0.0 when no criteria pass.
test(score_none_pass, []) :-
    % An empty list fails the non_empty criterion; has_x fails too.
    Output = [],
    Criteria = [criterion(non_empty, [O]>>(O \= [])),
                criterion(has_x,    [O]>>(member(x, O)))],
    rn_score(Output, Criteria, Score),
    % Score must be 0.0.
    Score =:= 0.0.

% AC-RN-005: rn_score/3 returns 0.5 for one passing and one failing criterion.
test(score_partial, []) :-
    % A non-empty list of 6 elements: non_empty passes, short fails.
    Output = [a, b, c, d, e, f],
    Criteria = [criterion(non_empty, [O]>>(O \= [])),
                criterion(short,     [O]>>(length(O, L), L < 5))],
    rn_score(Output, Criteria, Score),
    % Score must be 0.5 (one of two criteria passes).
    Score =:= 0.5.

% AC-RN-006: rn_optimize/5 stops when the quality bar is met.
test(optimize_stops_at_bar, []) :-
    % A generator that always produces [a, b].
    GeneratorGoal = ([O]>>(O = [a, b])),
    % An evaluator that always returns 1.0.
    EvaluatorGoal = ([_O, S]>>(S = 1.0)),
    % Quality bar is 0.9; generator always scores 1.0 so it must stop on iter 1.
    rn_optimize(GeneratorGoal, EvaluatorGoal, 0.9, 10, Best),
    % Best must be what the generator produced.
    Best = [a, b].

% AC-RN-007: rn_optimize/5 returns the best found when MaxIter is exhausted.
test(optimize_returns_best, []) :-
    % A counter for generating incrementally better outputs.
    nb_setval(opt_counter, 0),
    % Generator increments a counter and produces lists of increasing length.
    GeneratorGoal = ([O]>>(
        nb_getval(opt_counter, N),
        N1 is N + 1,
        nb_setval(opt_counter, N1),
        length(O, N1)
    )),
    % Evaluator scores by list length (longer = better, up to 0.9 at length 9).
    EvaluatorGoal = ([O, S]>>(length(O, L), S is float(L) / 10.0)),
    % Quality bar 1.0 is unreachable; MaxIter = 3 forces exhaustion.
    rn_optimize(GeneratorGoal, EvaluatorGoal, 1.0, 3, Best),
    % Best must have 3 elements (the longest produced within 3 iterations).
    length(Best, 3).

% AC-RN-008: rn_learn/3 stores a lesson in the lesson database.
test(learn_stores_lesson,
     [cleanup(rn_forget(test_problem_type))]) :-
    % Store a lesson.
    rn_learn(test_problem_type, failed_with_empty, use_non_empty_generator),
    % Verify the lesson is in the database.
    refinery:rn_lesson_db(test_problem_type,
                          failed_with_empty,
                          use_non_empty_generator).

% AC-RN-009: rn_recall/2 retrieves lessons for a given problem type.
test(recall_retrieves,
     [setup(rn_learn(recall_test, pattern_a, lesson_x)),
      cleanup(rn_forget(recall_test))]) :-
    % Recall lessons for the test problem type.
    rn_recall(recall_test, Lessons),
    % Must find the stored lesson.
    member(lesson(pattern_a, lesson_x), Lessons).

% AC-RN-010: rn_forget/1 clears all lessons for a given problem type.
test(forget_clears,
     [setup((rn_learn(forget_test, p1, l1),
             rn_learn(forget_test, p2, l2))),
      cleanup(true)]) :-
    % Clear all lessons for the test type.
    rn_forget(forget_test),
    % Recall should return empty.
    rn_recall(forget_test, Lessons),
    Lessons = [].

% End the test suite.
:- end_tests(refinery).
