/*  PrologAI — Causalontology Efficiency Governor Test Suite  (WP-399)

    Pins down the scoring arithmetic (matching the human wins full marks, twice
    the human actions scores a quarter), the budget cap (five times the human
    baseline), the running action counter, and the weighted environment and
    total scores.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_effic/test/test_co_effic.pl
*/

% Declare this file as a test module.
:- module(test_co_effic, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module(library(co_effic)).

% Open the test unit for the efficiency governor.
:- begin_tests(co_effic).

% Matching the human baseline scores the maximum of one.
test(match_human_full_score, [true(S =:= 1.0)]) :-
    % Ten agent actions against a ten-action human baseline.
    cef_level_score(10, 10, S).

% Spending twice the human actions scores a quarter (the square of one half).
test(double_actions_quarter, [true(S =:= 0.25)]) :-
    % Twenty agent actions against a ten-action human baseline.
    cef_level_score(10, 20, S).

% Beating the human is still capped at the maximum score of one.
test(beating_human_capped, [true(S =:= 1.0)]) :-
    % Five agent actions against a ten-action human baseline.
    cef_level_score(10, 5, S).

% The budget cap is five times the human baseline by default.
test(budget_five_times) :-
    % Read the default cap factor.
    cef_default_factor(F),
    % Compute the budget for a ten-action baseline.
    cef_budget(10, F, B),
    % It must be fifty.
    B =:= 50.

% The counter rises with each action and the budget check holds then fails.
test(counter_and_budget) :-
    % Start clean.
    cef_reset,
    % A human baseline of two actions for level one.
    cef_set_baseline(level1, 2),
    % Spend ten actions (exactly the cap of five times two).
    forall(between(1, 10, _), cef_count(level1)),
    % The count is ten.
    cef_actions(level1, 10),
    % Ten is within the cap of ten.
    cef_within_budget(level1),
    % One more action breaks the cap.
    cef_count(level1),
    % Now eleven actions exceed the budget of ten.
    \+ cef_within_budget(level1).

% The environment score is the weighted mean, early levels weighted least.
test(env_weighted_mean, [true(E =:= 0.875)]) :-
    % A level-one score of 0.5 (weight one) and level-two score of 1.0 (weight three).
    % Weighted mean: (1*0.5 + 3*1.0) / (1 + 3) = 3.5 / 4 = 0.875.
    cef_env_score([w(1, 0.5), w(3, 1.0)], E).

% The total score is the mean of environment scores as a percentage.
test(total_percent, [true(T =:= 75.0)]) :-
    % Two environment scores averaging 0.75.
    cef_total_score([0.5, 1.0], T).

% Close the test unit.
:- end_tests(co_effic).
