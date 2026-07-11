/*  Tests for co_hypo — Hypothesis Management with anti-drift commitment (WP-406)

    Each acceptance criterion prints PASS or FAIL.

    Run:
      swipl -p library=packs/co_hypo/prolog -g run_tests -t halt \
            packs/co_hypo/test/test_co_hypo.pl
*/

:- use_module('../prolog/co_hypo').
:- use_module(library(lists), [member/2]).

report(Id, Goal) :-
    ( catch(Goal, E, (format("  error: ~q~n", [E]), fail))
    -> V = 'PASS' ; V = 'FAIL' ),
    format("~w: ~w~n", [Id, V]).

% Give a hypothesis N net supporting observations.
support_n(_, _, 0) :- !.
support_n(M, H, N) :- N > 0, hy_support(M, H), N1 is N - 1, support_n(M, H, N1).

run_tests :-
    format("~n=== co_hypo — Hypothesis Management ===~n~n", []),
    hy_reset,
    G = game,

    % AC-HY-001: a proposed hypothesis with no evidence scores 0.5.
    report('AC-HY-001',
        ( hy_propose(G, rule(mirror), _), hy_score(G, rule(mirror), S), abs(S - 0.5) < 1.0e-9 )),

    % AC-HY-002: support raises the score, contradiction lowers it.
    report('AC-HY-002',
        ( support_n(G, rule(mirror), 8), hy_score(G, rule(mirror), S1), S1 > 0.8,
          hy_contradict(G, rule(rotate)), hy_score(G, rule(rotate), S2), S2 < 0.5 )),

    % AC-HY-003: ranking puts the best-supported hypothesis first.
    report('AC-HY-003',
        ( hy_propose(G, rule(gravity), _), support_n(G, rule(gravity), 3),
          hy_ranked(G, [hyp(Best, _) | _]), Best == rule(mirror) )),

    % AC-HY-004: the best hypothesis, once it clears the threshold and lead, is
    % committed by hy_update_commitment.
    report('AC-HY-004',
        ( hy_update_commitment(G), hy_committed(G, rule(mirror)) )),

    % AC-HY-005: HYSTERESIS — a challenger that merely EDGES ahead does NOT steal
    % the commitment (the cure for drift). Bring gravity slightly above mirror and
    % confirm mirror stays committed.
    report('AC-HY-005',
        ( support_n(G, rule(gravity), 6),   % gravity now slightly ahead
          hy_score(G, rule(gravity), SG), hy_score(G, rule(mirror), SM), SG > SM,
          hy_update_commitment(G),
          hy_committed(G, rule(mirror)) )),   % still mirror — hysteresis held

    % AC-HY-006: once the committed hypothesis is genuinely CONTRADICTED (its score
    % falls) and a challenger leads it by the switch margin, the commitment moves —
    % revision, not stubbornness. Contradict mirror until gravity leads by >= 0.15.
    report('AC-HY-006',
        ( forall(between(1, 7, _), hy_contradict(G, rule(mirror))),
          hy_score(G, rule(mirror), SM2), hy_score(G, rule(gravity), SG2),
          SG2 - SM2 >= 0.15, SM2 >= 0.40,   % mirror still above abandon: a true switch
          hy_update_commitment(G),
          hy_committed(G, rule(gravity)) )),

    % AC-HY-007: when the committed hypothesis's score COLLAPSES below the abandon
    % floor, it is dropped (revision, not stubborn drift the other way).
    report('AC-HY-007',
        ( hy_reset, hy_propose(G, rule(only), _), support_n(G, rule(only), 10),
          hy_update_commitment(G), hy_committed(G, rule(only)),
          forall(between(1, 60, _), hy_contradict(G, rule(only))),
          hy_update_commitment(G), \+ hy_committed(G, _) )),

    % AC-HY-008: hy_stale flags a committed hypothesis under real pressure.
    report('AC-HY-008',
        ( hy_reset, hy_propose(G, rule(x), _), support_n(G, rule(x), 10),
          hy_update_commitment(G),
          forall(between(1, 12, _), hy_contradict(G, rule(x))),
          hy_stale(G) )),

    % AC-HY-009: stats report the count and the committed hypothesis.
    report('AC-HY-009',
        ( hy_stats(G, stats(N, _)), N >= 1 )),

    format("~n", []).

:- use_module(library(lists), [between/3]).
