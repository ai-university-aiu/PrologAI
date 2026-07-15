/*  PrologAI — Resource-Bounded Reasoning Test Suite  (PR 21)

    Exercises the AIKR budget store and evidence-truth machinery: setting and
    getting a task budget with range clamping, the overloaded budget term
    round-trip, one decay step, attaching and querying evidence, incremental
    evidence updates, belief revision by merging, and anytime best-answer
    selection (highest confidence, or no_evidence when nothing is known).

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/budget/test/test_budget.pl
*/

% Declare this file as a test module.
:- module(test_budget, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module(library(budget)).

% Open the test unit for the budget pack.
:- begin_tests(budget).

% A budget set within range is returned unchanged by the getter.
test(set_and_get_in_range) :-
    % Attach a mid-range budget to a task.
    budget_budget_set(task_a, 0.7, 5.0, 0.3),
    % Read the three budget components back.
    budget_budget_get(task_a, P, D, Q),
    % Priority is the value that was stored.
    assertion(P =:= 0.7),
    % Durability is the value that was stored.
    assertion(D =:= 5.0),
    % Quality is the value that was stored.
    assertion(Q =:= 0.3).

% Out-of-range components are clamped: priority to 1.0, durability to at least 1.0, quality to 0.0.
test(set_clamps_out_of_range) :-
    % Attach a budget with every component outside its legal range.
    budget_budget_set(task_b, 2.0, 0.5, -1.0),
    % Read the clamped components back.
    budget_budget_get(task_b, P, D, Q),
    % Priority above one is clamped down to one.
    assertion(P =:= 1.0),
    % Durability below one is clamped up to one.
    assertion(D =:= 1.0),
    % Quality below zero is clamped up to zero.
    assertion(Q =:= 0.0).

% The overloaded budget/3 predicate round-trips a budget(P,D,Q) term and echoes the task id.
test(budget_term_roundtrip) :-
    % Store a budget passed as a budget term, receiving the task id back.
    budget_budget(task_c, budget(0.6, 8.0, 0.2), TaskId),
    % The returned task id is the task we stored under.
    assertion(TaskId == task_c),
    % Read the stored components back with the explicit getter.
    budget_budget_get(task_c, GP, GD, GQ),
    % Priority survives the round-trip.
    assertion(GP =:= 0.6),
    % Durability survives the round-trip.
    assertion(GD =:= 8.0),
    % Quality survives the round-trip.
    assertion(GQ =:= 0.2).

% One decay step scales priority by (1 - 1/Durability).
test(decay_reduces_priority) :-
    % Start a task at full priority with durability ten.
    budget_budget_set(task_d, 1.0, 10.0, 0.0),
    % Apply a single decay step.
    budget_budget_decay(task_d),
    % Read the decayed priority.
    budget_budget_get(task_d, P, _, _),
    % Priority is reduced to 1.0 * (1 - 1/10) = 0.9.
    assertion(P =:= 0.9).

% Evidence set in count mode is returned as frequency and confidence in query mode.
test(evidence_set_and_query) :-
    % Attach three positive out of four total observations to a belief.
    budget_truth_evidence(belief_a, 3, 4),
    % Query the belief's frequency and confidence.
    budget_truth_evidence(belief_a, Freq, Conf),
    % Frequency is positives over total.
    assertion(Freq =:= 0.75),
    % Confidence is the total observation count.
    assertion(Conf =:= 4).

% Adding an observation raises the confidence count by one.
test(evidence_add_increments_confidence) :-
    % Seed a belief with one positive out of two.
    budget_truth_evidence(belief_b, 1, 2),
    % Add one more positive observation.
    budget_truth_evidence_add(belief_b, true, NewConf),
    % The new confidence is the old total plus one.
    assertion(NewConf =:= 3),
    % Re-query the belief after the update.
    budget_truth_evidence(belief_b, Freq, Conf),
    % Confidence now reflects three total observations.
    assertion(Conf =:= 3),
    % Frequency is two positives over three total.
    assertion(abs(Freq - 0.6666666667) < 0.0001).

% Revising a certain belief with contrary evidence merges rather than rejects.
test(revise_merges_contradiction) :-
    % Seed a belief that has been positive once out of once (frequency one).
    budget_truth_evidence(belief_c, 1, 1),
    % Revise it with one negative observation.
    budget_revise(belief_c, false, NewFreq),
    % Frequency drops to one positive over two total.
    assertion(NewFreq =:= 0.5).

% The best answer for a known belief reports its frequency and confidence.
test(best_answer_returns_known_belief) :-
    % Attach two positives out of five to a belief.
    budget_truth_evidence(belief_d, 2, 5),
    % Ask for the best available answer to that belief.
    budget_best_answer(belief_d, Answer),
    % Decompose the answer into belief, frequency, and confidence.
    Answer = answer(belief_d, frequency(F), confidence(C)),
    % Frequency is two over five.
    assertion(F =:= 0.4),
    % Confidence is the total observation count.
    assertion(C =:= 5).

% A question with no evidence yields the honest no_evidence reply.
test(best_answer_no_evidence) :-
    % Ask about a belief that was never observed.
    budget_best_answer(never_seen_belief, Answer),
    % The reply admits no evidence at zero confidence.
    assertion(Answer == no_evidence(never_seen_belief, confidence(0))).

% Close the test unit for the budget pack.
:- end_tests(budget).
