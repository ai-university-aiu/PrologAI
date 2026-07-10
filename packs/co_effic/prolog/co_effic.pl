/*  PrologAI — Causalontology Efficiency Governor  (WP-399, Layer 374)

    ARC-AGI-3 does not only ask whether an agent can win a level; it asks how
    efficiently. A level is scored by comparing the number of actions the agent
    spent against a human baseline (the second-best human's action count for
    that level), and the benchmark caps spending at a small multiple of the
    human baseline so that brute-force search cannot buy a win. An agent that
    ignores efficiency can complete every level and still score near zero.

    This pack is the governor that keeps the co_arc3 harness efficiency-aware.
    It counts the actions spent per level, holds the human baseline per level,
    turns a baseline into a per-level action budget (the cap), reports whether
    the agent is still within budget, and computes the efficiency scores the
    benchmark uses:

      per-level score   S = min(1, H / A)^2
                        (H human baseline actions, A agent actions; the square
                        is the power-law penalty for straying from the human)
      environment score weighted mean of its level scores, early levels weighted
                        least (weights rise 1, 2, 3, ...)
      total score       mean of environment scores, reported as a percentage

    Everything is explicit and inspectable: cef_actions/2 shows the running
    count, cef_level_score/3 shows the arithmetic, and cef_report/1 gathers the
    whole ledger for a level.

    Predicates:
      cef_reset/0            -- clear counters and baselines
      cef_set_baseline/2     -- +Level, +HumanActions   (register a baseline)
      cef_baseline/2         -- ?Level, ?HumanActions
      cef_count/1            -- +Level  (one action spent on a level)
      cef_actions/2          -- ?Level, ?AgentActions
      cef_default_factor/1   -- -Factor  (the cap multiple, five)
      cef_budget/3           -- +HumanActions, +Factor, -Budget
      cef_within_budget/1    -- +Level  (agent actions still under the cap)
      cef_level_score/3      -- +HumanActions, +AgentActions, -Score
      cef_env_score/2        -- +WeightedScores, -EnvScore  (list of w(W,S))
      cef_total_score/2      -- +EnvScores, -TotalPercent
      cef_report/1           -- +Level  (a ledger term for the level)
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(co_effic, [
    % cef_reset/0: clear counters and baselines.
    cef_reset/0,
    % cef_set_baseline/2: register a human baseline for a level.
    cef_set_baseline/2,
    % cef_baseline/2: query a level's human baseline.
    cef_baseline/2,
    % cef_count/1: record one action spent on a level.
    cef_count/1,
    % cef_actions/2: query the agent action count for a level.
    cef_actions/2,
    % cef_default_factor/1: the benchmark cap multiple.
    cef_default_factor/1,
    % cef_budget/3: turn a baseline and factor into an action budget.
    cef_budget/3,
    % cef_within_budget/1: the agent is still under the level's cap.
    cef_within_budget/1,
    % cef_level_score/3: the RHAE-style per-level efficiency score.
    cef_level_score/3,
    % cef_env_score/2: the weighted mean of a level's scores.
    cef_env_score/2,
    % cef_total_score/2: the mean of environment scores as a percentage.
    cef_total_score/2,
    % cef_report/1: a ledger term for a level.
    cef_report/1
]).

% Import list arithmetic helpers for the weighted means.
:- use_module(library(lists), [sum_list/2, member/2]).

% ---------------------------------------------------------------------------
% Counters and baselines
% ---------------------------------------------------------------------------

% cef_actions_/2: (Level, AgentActions) — actions spent so far on a level.
:- dynamic cef_actions_/2.
% cef_base_/2: (Level, HumanActions) — the human baseline for a level.
:- dynamic cef_base_/2.

% Define cef_reset: clear every counter and baseline.
cef_reset :-
    % Drop the action counters.
    retractall(cef_actions_(_, _)),
    % Drop the baselines.
    retractall(cef_base_(_, _)).

% Define cef_set_baseline: register a human baseline for a level.
cef_set_baseline(Level, Human) :-
    % A baseline must be a positive action count.
    integer(Human), Human > 0,
    % Replace any previous baseline for the level.
    retractall(cef_base_(Level, _)),
    % Record the new one.
    assertz(cef_base_(Level, Human)).

% Define cef_baseline: query a level's human baseline.
cef_baseline(Level, Human) :-
    % Read the stored baseline.
    cef_base_(Level, Human).

% Define cef_count: record one action spent on a level.
cef_count(Level) :-
    % Fetch and remove the current count, defaulting to zero.
    ( retract(cef_actions_(Level, N)) -> true ; N = 0 ),
    % Spend one more action.
    N1 is N + 1,
    % Store the updated count.
    assertz(cef_actions_(Level, N1)).

% Define cef_actions: query the agent action count for a level.
cef_actions(Level, Count) :-
    % Read the counter, zero when nothing has been spent.
    ( cef_actions_(Level, Count) -> true ; Count = 0 ).

% ---------------------------------------------------------------------------
% Budgeting — the cap on how much may be spent
% ---------------------------------------------------------------------------

% Define cef_default_factor: the benchmark's cap multiple over the human baseline.
cef_default_factor(5).

% Define cef_budget: turn a baseline and factor into an action budget.
cef_budget(Human, Factor, Budget) :-
    % The budget is the human baseline scaled by the cap factor.
    Budget is Human * Factor.

% Define cef_within_budget: the agent is still under the level's cap.
cef_within_budget(Level) :-
    % A baseline is needed to define the cap.
    cef_baseline(Level, Human),
    % Use the default cap factor.
    cef_default_factor(Factor),
    % Compute the cap.
    cef_budget(Human, Factor, Budget),
    % Read what has been spent.
    cef_actions(Level, Spent),
    % Spending must not exceed the cap.
    Spent =< Budget.

% ---------------------------------------------------------------------------
% Scoring
% ---------------------------------------------------------------------------

% Define cef_level_score: the RHAE-style per-level efficiency score.
cef_level_score(Human, Agent, Score) :-
    % A run that spent no actions is treated as perfectly efficient.
    ( Agent =< 0
    % No actions spent scores the maximum.
    ->  Ratio = 1.0
    % Otherwise the ratio of human to agent actions, capped at one.
    ;   Ratio is min(1.0, Human / Agent)
    ),
    % The power-law penalty is the square of the capped ratio.
    Score is Ratio * Ratio.

% Define cef_env_score: the weighted mean of a level's scores.
cef_env_score(WeightedScores, EnvScore) :-
    % There must be at least one weighted score.
    WeightedScores \== [],
    % Sum the weighted scores.
    findall(WS, ( member(w(W, S), WeightedScores), WS is W * S ), Products),
    % Sum the weights.
    findall(W, member(w(W, _), WeightedScores), Weights),
    % Total the numerator.
    sum_list(Products, Num),
    % Total the denominator.
    sum_list(Weights, Den),
    % Guard against a zero total weight.
    Den > 0,
    % The environment score is the weighted mean.
    EnvScore is Num / Den.

% Define cef_total_score: the mean of environment scores as a percentage.
cef_total_score(EnvScores, TotalPercent) :-
    % There must be at least one environment score.
    EnvScores \== [],
    % Sum the environment scores.
    sum_list(EnvScores, Sum),
    % Count them.
    length(EnvScores, N),
    % The total is their mean, scaled to a percentage.
    TotalPercent is (Sum / N) * 100.

% ---------------------------------------------------------------------------
% The glass-box ledger
% ---------------------------------------------------------------------------

% Define cef_report: a ledger term for a level.
cef_report(Level) :-
    % Read the human baseline, or mark it unknown.
    ( cef_baseline(Level, Human) -> true ; Human = unknown ),
    % Read the agent action count.
    cef_actions(Level, Agent),
    % Compute the score when a baseline is known.
    ( integer(Human)
    % A known baseline yields a numeric score and budget.
    ->  cef_level_score(Human, Agent, Score),
        cef_default_factor(Factor),
        cef_budget(Human, Factor, Budget)
    % An unknown baseline leaves score and budget unknown.
    ;   Score = unknown, Budget = unknown
    ),
    % Print the ledger for the level.
    format("level ~w: human=~w agent=~w budget=~w score=~w~n",
           [Level, Human, Agent, Budget, Score]).
