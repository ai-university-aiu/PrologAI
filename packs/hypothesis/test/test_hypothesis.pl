/*  Tests for hypothesis — Hypothesis Management with anti-drift commitment (WP-406)

    Standard PLUnit suite. Each test rebuilds exactly the hypothesis state its
    acceptance criterion needs and asserts the SAME property the original bespoke
    checkpoints asserted, against the real hypothesis predicates.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/hypothesis/test/test_hypothesis.pl
*/

% Declare this file as a test module.
:- module(test_hypothesis, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module(library(hypothesis)).

% Load the list membership helper.
:- use_module(library(lists), [member/2]).

% Give a hypothesis N net supporting observations.
support_n(_, _, 0) :- !.
% Recurse: record one support then continue with one fewer to go.
support_n(M, H, N) :- N > 0, hypothesis_support(M, H), N1 is N - 1, support_n(M, H, N1).

% ===========================================================================
% hypothesis — Hypothesis Management
% ===========================================================================

:- begin_tests(hypothesis).

% AC-HY-001: a proposed hypothesis with no evidence scores 0.5.
test(no_evidence_scores_half) :-
    % Start from a clean slate.
    hypothesis_reset,
    % Propose a hypothesis with no evidence yet.
    hypothesis_propose(game, rule(mirror), _),
    % Read its score.
    hypothesis_score(game, rule(mirror), S),
    % A hypothesis with no evidence scores exactly 0.5.
    assertion(abs(S - 0.5) < 1.0e-9).

% AC-HY-002: support raises the score, contradiction lowers it.
test(support_raises_contradict_lowers) :-
    % Start from a clean slate.
    hypothesis_reset,
    % Give the mirror rule eight confirming observations.
    hypothesis_propose(game, rule(mirror), _),
    support_n(game, rule(mirror), 8),
    % Well-supported, its score rises above 0.8.
    hypothesis_score(game, rule(mirror), S1),
    assertion(S1 > 0.8),
    % Give the rotate rule one disconfirming observation.
    hypothesis_contradict(game, rule(rotate)),
    % Contradicted, its score falls below 0.5.
    hypothesis_score(game, rule(rotate), S2),
    assertion(S2 < 0.5).

% AC-HY-003: ranking puts the best-supported hypothesis first.
test(ranking_best_first) :-
    % Start from a clean slate.
    hypothesis_reset,
    % The mirror rule is strongly supported.
    hypothesis_propose(game, rule(mirror), _),
    support_n(game, rule(mirror), 8),
    % The gravity rule is less strongly supported.
    hypothesis_propose(game, rule(gravity), _),
    support_n(game, rule(gravity), 3),
    % Ranking places the best-supported hypothesis at the head.
    hypothesis_ranked(game, [hyp(Best, _) | _]),
    assertion(Best == rule(mirror)).

% AC-HY-004: the best hypothesis, once it clears the threshold and lead, is
% committed by hypothesis_update_commitment.
test(commit_best) :-
    % Start from a clean slate.
    hypothesis_reset,
    % Mirror clearly leads gravity.
    hypothesis_propose(game, rule(mirror), _),
    support_n(game, rule(mirror), 8),
    hypothesis_propose(game, rule(gravity), _),
    support_n(game, rule(gravity), 3),
    % Run the commitment decision.
    hypothesis_update_commitment(game),
    % The best hypothesis becomes committed.
    assertion(hypothesis_committed(game, rule(mirror))).

% AC-HY-005: HYSTERESIS — a challenger that merely EDGES ahead does NOT steal the
% commitment (the cure for drift).
test(hysteresis_holds) :-
    % Start from a clean slate.
    hypothesis_reset,
    % Commit mirror while it leads gravity.
    hypothesis_propose(game, rule(mirror), _),
    support_n(game, rule(mirror), 8),
    hypothesis_propose(game, rule(gravity), _),
    support_n(game, rule(gravity), 3),
    hypothesis_update_commitment(game),
    % Now bring gravity slightly ahead of mirror.
    support_n(game, rule(gravity), 6),
    hypothesis_score(game, rule(gravity), SG),
    hypothesis_score(game, rule(mirror), SM),
    assertion(SG > SM),
    % Re-run the decision: hysteresis keeps mirror despite the narrow lead.
    hypothesis_update_commitment(game),
    assertion(hypothesis_committed(game, rule(mirror))).

% AC-HY-006: once the committed hypothesis is genuinely CONTRADICTED (its score
% falls) and a challenger leads it by the switch margin, the commitment moves —
% revision, not stubbornness.
test(switch_on_real_contradiction) :-
    % Start from a clean slate.
    hypothesis_reset,
    % Commit mirror, then let gravity edge ahead (hysteresis holds).
    hypothesis_propose(game, rule(mirror), _),
    support_n(game, rule(mirror), 8),
    hypothesis_propose(game, rule(gravity), _),
    support_n(game, rule(gravity), 3),
    hypothesis_update_commitment(game),
    support_n(game, rule(gravity), 6),
    hypothesis_update_commitment(game),
    % Contradict mirror until gravity leads it by the switch margin.
    forall(between(1, 7, _), hypothesis_contradict(game, rule(mirror))),
    hypothesis_score(game, rule(mirror), SM2),
    hypothesis_score(game, rule(gravity), SG2),
    % Gravity now leads by at least the switch margin, with mirror still above abandon.
    assertion(SG2 - SM2 >= 0.15),
    assertion(SM2 >= 0.40),
    % The commitment switches to gravity.
    hypothesis_update_commitment(game),
    assertion(hypothesis_committed(game, rule(gravity))).

% AC-HY-007: when the committed hypothesis's score COLLAPSES below the abandon
% floor, it is dropped (revision, not stubborn drift the other way).
test(abandon_on_collapse) :-
    % Start from a clean slate.
    hypothesis_reset,
    % Commit the only hypothesis on strong support.
    hypothesis_propose(game, rule(only), _),
    support_n(game, rule(only), 10),
    hypothesis_update_commitment(game),
    assertion(hypothesis_committed(game, rule(only))),
    % Contradict it until its score collapses below the abandon floor.
    forall(between(1, 60, _), hypothesis_contradict(game, rule(only))),
    % The collapsed commitment is dropped.
    hypothesis_update_commitment(game),
    assertion(\+ hypothesis_committed(game, _)).

% AC-HY-008: hypothesis_stale flags a committed hypothesis under real pressure.
test(stale_flags_pressure) :-
    % Start from a clean slate.
    hypothesis_reset,
    % Commit a hypothesis on strong support.
    hypothesis_propose(game, rule(x), _),
    support_n(game, rule(x), 10),
    hypothesis_update_commitment(game),
    % Contradict it enough to pull its score to the midpoint.
    forall(between(1, 12, _), hypothesis_contradict(game, rule(x))),
    % It is now flagged stale — under real pressure, a signal to re-orient.
    assertion(hypothesis_stale(game)).

% AC-HY-009: stats report the count and the committed hypothesis.
test(stats_count) :-
    % Start from a clean slate.
    hypothesis_reset,
    % Hold at least one hypothesis.
    hypothesis_propose(game, rule(x), _),
    support_n(game, rule(x), 10),
    % Stats report a hypothesis count of at least one.
    hypothesis_stats(game, stats(N, _)),
    assertion(N >= 1).

:- end_tests(hypothesis).
