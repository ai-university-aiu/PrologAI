/*  PrologAI — Causalontology Metacognition Test Suite  (WP-413)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_gauge/test/test_co_gauge.pl
*/

% Declare this file as a test module.
:- module(test_co_gauge, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(co_gauge)).

% Open the test block.
:- begin_tests(co_gauge).

% Calibration is successes over attempts.
test(calibration_rate) :-
    co_gauge:gu_reset,
    co_gauge:gu_attempt(alpha, success),
    co_gauge:gu_attempt(alpha, success),
    co_gauge:gu_attempt(alpha, failure),
    co_gauge:gu_calibration(alpha, R),
    assertion(abs(R - 0.6666666666666666) < 0.0001).

% The best strategy is the highest-calibrated one.
test(best_strategy) :-
    co_gauge:gu_reset,
    co_gauge:gu_attempt(alpha, success),
    co_gauge:gu_attempt(alpha, success),
    co_gauge:gu_attempt(beta, failure),
    co_gauge:gu_attempt(beta, failure),
    co_gauge:gu_best_strategy(S, _),
    assertion(S == alpha).

% A strategy that keeps failing with enough attempts is flagged confused.
test(confusion_detected) :-
    co_gauge:gu_reset,
    co_gauge:gu_attempt(beta, failure),
    co_gauge:gu_attempt(beta, failure),
    co_gauge:gu_attempt(beta, failure),
    assertion(co_gauge:gu_confused(beta)).

% A strategy with few attempts is not yet judged confused.
test(no_confusion_too_few) :-
    co_gauge:gu_reset,
    co_gauge:gu_attempt(beta, failure),
    assertion(\+ co_gauge:gu_confused(beta)).

% Progress reads later success against earlier failure as improving.
test(progress_improving) :-
    co_gauge:gu_reset,
    co_gauge:gu_attempt(s, failure),
    co_gauge:gu_attempt(s, failure),
    co_gauge:gu_attempt(s, success),
    co_gauge:gu_attempt(s, success),
    co_gauge:gu_progress(Trend),
    assertion(Trend == improving).

% A good-enough strategy is recommended for use.
test(recommend_use) :-
    co_gauge:gu_reset,
    co_gauge:gu_attempt(good, success),
    co_gauge:gu_attempt(good, success),
    co_gauge:gu_attempt(good, success),
    co_gauge:gu_recommend(Rec),
    assertion(Rec == use(good)).

% When everything fails and nothing improves, seek guidance.
test(recommend_seek_guidance) :-
    co_gauge:gu_reset,
    co_gauge:gu_attempt(x, failure),
    co_gauge:gu_attempt(x, failure),
    co_gauge:gu_attempt(x, failure),
    co_gauge:gu_recommend(Rec),
    assertion(Rec == seek_guidance).

% With no attempts at all, the recommendation is to explore.
test(recommend_explore_when_empty) :-
    co_gauge:gu_reset,
    co_gauge:gu_recommend(Rec),
    assertion(Rec == explore).

% Close the test block.
:- end_tests(co_gauge).
