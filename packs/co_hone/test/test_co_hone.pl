/*  PrologAI — Causalontology Regulation Test Suite  (WP-423)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_hone/test/test_co_hone.pl
*/

% Declare this file as a test module.
:- module(test_co_hone, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(co_hone)).

% Open the test block.
:- begin_tests(co_hone).

% Reliability is successes over attempts.
test(reliability) :-
    co_hone:ho_reset,
    co_hone:ho_rule_add(r, push, any),
    co_hone:ho_feedback(r, success, [a]),
    co_hone:ho_feedback(r, success, [b]),
    co_hone:ho_feedback(r, failure, [c]),
    co_hone:ho_reliability(r, Rel),
    assertion(abs(Rel - 0.6666666666666666) < 1e-9).

% A predicted success that happens is confirming; a predicted success that
% fails is shocking (reliability high => success is expected).
test(flavour_expected_success) :-
    co_hone:ho_reset,
    co_hone:ho_rule_add(r, push, any),
    co_hone:ho_feedback(r, success, [x]),
    co_hone:ho_feedback(r, success, [y]),
    co_hone:ho_feedback(r, success, [z]),   % reliability 1.0 => predict success
    co_hone:ho_classify(r, success, F1),
    assertion(F1 == confirming),
    co_hone:ho_classify(r, failure, F2),
    assertion(F2 == shocking).

% When failure is expected, a success is serendipitous and a failure disappointing.
test(flavour_expected_failure) :-
    co_hone:ho_reset,
    co_hone:ho_rule_add(r, push, any),
    co_hone:ho_feedback(r, failure, [x]),
    co_hone:ho_feedback(r, failure, [y]),
    co_hone:ho_feedback(r, success, [z]),   % reliability 1/3 => predict failure
    co_hone:ho_classify(r, success, F1),
    assertion(F1 == serendipitous),
    co_hone:ho_classify(r, failure, F2),
    assertion(F2 == disappointing).

% A rule with no history classifies its first result as novel.
test(flavour_novel) :-
    co_hone:ho_reset,
    co_hone:ho_rule_add(r, push, any),
    co_hone:ho_classify(r, success, F),
    assertion(F == novel).

% A rule that both wins and loses needs discriminating.
test(needs_discrimination) :-
    co_hone:ho_reset,
    co_hone:ho_rule_add(r, push, any),
    co_hone:ho_feedback(r, success, [wall_ahead, clear_left]),
    co_hone:ho_feedback(r, failure, [pit_ahead]),
    assertion(co_hone:ho_needs_discrimination(r)),
    co_hone:ho_reset,
    co_hone:ho_rule_add(r, push, any),
    co_hone:ho_feedback(r, success, [ok]),
    assertion(\+ co_hone:ho_needs_discrimination(r)).

% Discrimination finds a feature present in every win and no loss.
test(discriminate_success_feature) :-
    co_hone:ho_reset,
    co_hone:ho_rule_add(r, push, any),
    co_hone:ho_feedback(r, success, [wall_ahead, clear_left]),
    co_hone:ho_feedback(r, success, [wall_ahead, open]),
    co_hone:ho_feedback(r, failure, [pit_ahead]),
    co_hone:ho_feedback(r, failure, [pit_ahead, dark]),
    co_hone:ho_discriminate(r, D),
    assertion(D == discriminator(wall_ahead, present_predicts(success))).

% Refining on a success discriminator adds it as a required condition.
test(refine_requires_feature) :-
    co_hone:ho_reset,
    co_hone:ho_rule_add(r, push, any),
    co_hone:ho_refine(r, discriminator(wall_ahead, present_predicts(success)), RC),
    assertion(RC == [wall_ahead]).

% Refining on a failure discriminator adds the negated condition to avoid it.
test(refine_avoids_feature) :-
    co_hone:ho_reset,
    co_hone:ho_rule_add(r, push, [base]),
    co_hone:ho_refine(r, discriminator(pit_ahead, present_predicts(failure)), RC),
    assertion(RC == [base, not(pit_ahead)]).

% Discrimination reports none when nothing cleanly separates wins from losses.
test(discriminate_none) :-
    co_hone:ho_reset,
    co_hone:ho_rule_add(r, push, any),
    co_hone:ho_feedback(r, success, [shared]),
    co_hone:ho_feedback(r, failure, [shared]),
    co_hone:ho_discriminate(r, D),
    assertion(D == none).

% Close the test block.
:- end_tests(co_hone).
