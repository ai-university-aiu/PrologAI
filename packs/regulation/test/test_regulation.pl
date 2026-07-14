/*  PrologAI — Causalontology Regulation Test Suite  (WP-423)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/regulation/test/test_regulation.pl
*/

% Declare this file as a test module.
:- module(test_regulation, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(regulation)).

% Open the test block.
:- begin_tests(regulation).

% Reliability is successes over attempts.
test(reliability) :-
    regulation:regulation_reset,
    regulation:regulation_rule_add(r, push, any),
    regulation:regulation_feedback(r, success, [a]),
    regulation:regulation_feedback(r, success, [b]),
    regulation:regulation_feedback(r, failure, [c]),
    regulation:regulation_reliability(r, Rel),
    assertion(abs(Rel - 0.6666666666666666) < 1e-9).

% A predicted success that happens is confirming; a predicted success that
% fails is shocking (reliability high => success is expected).
test(flavour_expected_success) :-
    regulation:regulation_reset,
    regulation:regulation_rule_add(r, push, any),
    regulation:regulation_feedback(r, success, [x]),
    regulation:regulation_feedback(r, success, [y]),
    regulation:regulation_feedback(r, success, [z]),   % reliability 1.0 => predict success
    regulation:regulation_classify(r, success, F1),
    assertion(F1 == confirming),
    regulation:regulation_classify(r, failure, F2),
    assertion(F2 == shocking).

% When failure is expected, a success is serendipitous and a failure disappointing.
test(flavour_expected_failure) :-
    regulation:regulation_reset,
    regulation:regulation_rule_add(r, push, any),
    regulation:regulation_feedback(r, failure, [x]),
    regulation:regulation_feedback(r, failure, [y]),
    regulation:regulation_feedback(r, success, [z]),   % reliability 1/3 => predict failure
    regulation:regulation_classify(r, success, F1),
    assertion(F1 == serendipitous),
    regulation:regulation_classify(r, failure, F2),
    assertion(F2 == disappointing).

% A rule with no history classifies its first result as novel.
test(flavour_novel) :-
    regulation:regulation_reset,
    regulation:regulation_rule_add(r, push, any),
    regulation:regulation_classify(r, success, F),
    assertion(F == novel).

% A rule that both wins and loses needs discriminating.
test(needs_discrimination) :-
    regulation:regulation_reset,
    regulation:regulation_rule_add(r, push, any),
    regulation:regulation_feedback(r, success, [wall_ahead, clear_left]),
    regulation:regulation_feedback(r, failure, [pit_ahead]),
    assertion(regulation:regulation_needs_discrimination(r)),
    regulation:regulation_reset,
    regulation:regulation_rule_add(r, push, any),
    regulation:regulation_feedback(r, success, [ok]),
    assertion(\+ regulation:regulation_needs_discrimination(r)).

% Discrimination finds a feature present in every win and no loss.
test(discriminate_success_feature) :-
    regulation:regulation_reset,
    regulation:regulation_rule_add(r, push, any),
    regulation:regulation_feedback(r, success, [wall_ahead, clear_left]),
    regulation:regulation_feedback(r, success, [wall_ahead, open]),
    regulation:regulation_feedback(r, failure, [pit_ahead]),
    regulation:regulation_feedback(r, failure, [pit_ahead, dark]),
    regulation:regulation_discriminate(r, D),
    assertion(D == discriminator(wall_ahead, present_predicts(success))).

% Refining on a success discriminator adds it as a required condition.
test(refine_requires_feature) :-
    regulation:regulation_reset,
    regulation:regulation_rule_add(r, push, any),
    regulation:regulation_refine(r, discriminator(wall_ahead, present_predicts(success)), RC),
    assertion(RC == [wall_ahead]).

% Refining on a failure discriminator adds the negated condition to avoid it.
test(refine_avoids_feature) :-
    regulation:regulation_reset,
    regulation:regulation_rule_add(r, push, [base]),
    regulation:regulation_refine(r, discriminator(pit_ahead, present_predicts(failure)), RC),
    assertion(RC == [base, not(pit_ahead)]).

% Discrimination reports none when nothing cleanly separates wins from losses.
test(discriminate_none) :-
    regulation:regulation_reset,
    regulation:regulation_rule_add(r, push, any),
    regulation:regulation_feedback(r, success, [shared]),
    regulation:regulation_feedback(r, failure, [shared]),
    regulation:regulation_discriminate(r, D),
    assertion(D == none).

% Close the test block.
:- end_tests(regulation).
