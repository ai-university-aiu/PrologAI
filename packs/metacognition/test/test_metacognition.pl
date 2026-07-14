/*  PrologAI — Causalontology Metacognition Test Suite  (WP-413)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/metacognition/test/test_co_gauge.pl
*/

% Declare this file as a test module.
:- module(test_metacognition, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(metacognition)).

% Open the test block.
:- begin_tests(metacognition).

% Calibration is successes over attempts.
test(calibration_rate) :-
    metacognition:metacognition_reset,
    metacognition:metacognition_attempt(alpha, success),
    metacognition:metacognition_attempt(alpha, success),
    metacognition:metacognition_attempt(alpha, failure),
    metacognition:metacognition_calibration(alpha, R),
    assertion(abs(R - 0.6666666666666666) < 0.0001).

% The best strategy is the highest-calibrated one.
test(best_strategy) :-
    metacognition:metacognition_reset,
    metacognition:metacognition_attempt(alpha, success),
    metacognition:metacognition_attempt(alpha, success),
    metacognition:metacognition_attempt(beta, failure),
    metacognition:metacognition_attempt(beta, failure),
    metacognition:metacognition_best_strategy(S, _),
    assertion(S == alpha).

% A strategy that keeps failing with enough attempts is flagged confused.
test(confusion_detected) :-
    metacognition:metacognition_reset,
    metacognition:metacognition_attempt(beta, failure),
    metacognition:metacognition_attempt(beta, failure),
    metacognition:metacognition_attempt(beta, failure),
    assertion(metacognition:metacognition_confused(beta)).

% A strategy with few attempts is not yet judged confused.
test(no_confusion_too_few) :-
    metacognition:metacognition_reset,
    metacognition:metacognition_attempt(beta, failure),
    assertion(\+ metacognition:metacognition_confused(beta)).

% Progress reads later success against earlier failure as improving.
test(progress_improving) :-
    metacognition:metacognition_reset,
    metacognition:metacognition_attempt(s, failure),
    metacognition:metacognition_attempt(s, failure),
    metacognition:metacognition_attempt(s, success),
    metacognition:metacognition_attempt(s, success),
    metacognition:metacognition_progress(Trend),
    assertion(Trend == improving).

% A good-enough strategy is recommended for use.
test(recommend_use) :-
    metacognition:metacognition_reset,
    metacognition:metacognition_attempt(good, success),
    metacognition:metacognition_attempt(good, success),
    metacognition:metacognition_attempt(good, success),
    metacognition:metacognition_recommend(Rec),
    assertion(Rec == use(good)).

% When everything fails and nothing improves, seek guidance.
test(recommend_seek_guidance) :-
    metacognition:metacognition_reset,
    metacognition:metacognition_attempt(x, failure),
    metacognition:metacognition_attempt(x, failure),
    metacognition:metacognition_attempt(x, failure),
    metacognition:metacognition_recommend(Rec),
    assertion(Rec == seek_guidance).

% With no attempts at all, the recommendation is to explore.
test(recommend_explore_when_empty) :-
    metacognition:metacognition_reset,
    metacognition:metacognition_recommend(Rec),
    assertion(Rec == explore).

% Close the test block.
:- end_tests(metacognition).
