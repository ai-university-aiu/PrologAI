/*  PrologAI — Causalontology World Model Test Suite  (WP-407)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_wm/test/test_co_wm.pl
*/

% Declare this file as a test module.
:- module(test_co_wm, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(co_wm)).

% Open the test block for co_wm.
:- begin_tests(co_wm).

% AC-WM-001: after observing a transition, the model predicts it.
test(observe_then_predict) :-
    % Start from an empty model.
    wm_reset,
    % Record a single right -> move_east transition.
    wm_observe(game, any, right, move_east),
    % Predict the effect of right in that context.
    wm_predict(game, any, right, E),
    % The prediction is the observed effect.
    assertion(E == move_east).

% AC-WM-002: the majority effect wins, with a confidence share.
test(majority_wins_with_confidence) :-
    % Start from an empty model.
    wm_reset,
    % Record move_east twice and blocked once for right.
    wm_observe(game, any, right, move_east),
    wm_observe(game, any, right, move_east),
    wm_observe(game, any, right, blocked),
    % Predict the effect and read the confidence share.
    wm_predict(game, any, right, E, C),
    % The majority effect is move_east.
    assertion(E == move_east),
    % Its share of the observations exceeds sixty percent.
    assertion(C > 0.6).

% AC-WM-003: a context-specific effect overrides the general one.
test(context_specific_overrides) :-
    % Start from an empty model.
    wm_reset,
    % A general right -> move_east observation.
    wm_observe(game, any, right, move_east),
    % Two on_ice right -> slide_far observations.
    wm_observe(game, on_ice, right, slide_far),
    wm_observe(game, on_ice, right, slide_far),
    % Predicting in the on_ice context uses its own tallies.
    wm_predict(game, on_ice, right, E),
    % The context-specific effect wins there.
    assertion(E == slide_far).

% AC-WM-004: an UNSEEN context falls back to the action-general rule.
test(unseen_context_falls_back) :-
    % Start from an empty model.
    wm_reset,
    % Record right -> move_east in a known context.
    wm_observe(game, any, right, move_east),
    % Predict right in a context never observed with it.
    wm_predict(game, brand_new_context, right, E),
    % The action-general rule supplies move_east.
    assertion(E == move_east).

% AC-WM-005: verify reports a match when reality agrees with the prediction.
test(verify_match) :-
    % Start from an empty model.
    wm_reset,
    % Record right -> move_east.
    wm_observe(game, any, right, move_east),
    % Verify the prediction against an agreeing observation.
    wm_verify(game, any, right, move_east, R),
    % Reality agrees, so the result is a match.
    assertion(R == match).

% AC-WM-006: verify reports a mismatch (the repair signal) when it disagrees.
test(verify_mismatch) :-
    % Start from an empty model.
    wm_reset,
    % Record right -> move_east.
    wm_observe(game, any, right, move_east),
    % Verify the prediction against a disagreeing observation.
    wm_verify(game, any, right, teleport, R),
    % The result names both the predicted and observed effects.
    assertion(R == mismatch(move_east, teleport)).

% AC-WM-007: repair folds the truth in; enough repairs flip the prediction.
test(repair_flips_prediction) :-
    % Start from an empty model.
    wm_reset,
    % Record right -> move_east once.
    wm_observe(game, any, right, move_east),
    % Repair with the contradicting truth ten times.
    forall(between(1, 10, _), wm_repair(game, any, right, teleport)),
    % Predict right again after the repairs.
    wm_predict(game, any, right, E),
    % The majority has shifted, so the prediction is now teleport.
    assertion(E == teleport).

% AC-WM-008: rollout predicts a whole action sequence (plan-in-model).
test(rollout_predicts_sequence) :-
    % Start from an empty model.
    wm_reset,
    % Record a -> x and b -> y.
    wm_observe(game, any, a, x),
    wm_observe(game, any, b, y),
    % Roll the action sequence a, b, a forward in the model.
    once(wm_rollout(game, any, [a, b, a], Effects)),
    % Each step predicts its learned effect.
    assertion(Effects == [x, y, x]).

% AC-WM-009: a context-free action is surfaced as a general LAW; a context-
% dependent one is not.
test(law_only_when_context_free) :-
    % Start from an empty model.
    wm_reset,
    % up -> jump in two different contexts (context-free).
    wm_observe(game, c1, up, jump),
    wm_observe(game, c2, up, jump),
    % down -> fall in one context and sink in another (context-dependent).
    wm_observe(game, c1, down, fall),
    wm_observe(game, c2, down, sink),
    % up is a general law with a single effect everywhere.
    assertion(wm_law(game, up, jump)),
    % down has conflicting effects, so it is not a law.
    assertion(\+ wm_law(game, down, _)).

% Close the test block for co_wm.
:- end_tests(co_wm).
