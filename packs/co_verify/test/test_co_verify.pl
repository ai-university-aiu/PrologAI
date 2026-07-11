/*  Tests for co_verify — Verify-Before-Act (WP-405, Layer 380)

    Each acceptance criterion prints PASS or FAIL.

    Run:
      swipl -p library=packs/co_verify/prolog -g run_tests -t halt \
            packs/co_verify/test/test_co_verify.pl
*/

% Load the pack under test.
:- use_module('../prolog/co_verify').
% List helpers.
:- use_module(library(lists), [member/2, memberchk/2]).

% report(+Id, +Goal): print PASS or FAIL for one criterion.
report(Id, Goal) :-
    ( catch(Goal, E, (format("  error: ~q~n", [E]), fail))
    -> V = 'PASS' ; V = 'FAIL' ),
    format("~w: ~w~n", [Id, V]).

% A tiny deterministic transition model for the plan-in-model tests: stepping
% right from a cell state moves to the next cell; cell 9 is a cliff (leads to the
% dead state 'dead').
step(cell(N), right, Next) :-
    ( N >= 9 -> Next = dead ; N1 is N + 1, Next = cell(N1) ).
step(cell(N), left, cell(N)) :- N >= 0.

% run_tests: exercise prediction, generalisation, ranking, and plan-in-model.
run_tests :-
    % Announce.
    format("~n=== co_verify — Verify-Before-Act ===~n~n", []),
    % A clean model.
    vb_reset,
    % The model tag (a game).
    G = game1,

    % AC-VB-001: an exact fatal transition is remembered.
    report('AC-VB-001',
        ( vb_note_fatal(G, s(a), action(3)),
          vb_fatal_here(G, s(a), action(3)) )),

    % AC-VB-002: an action fatal in one state only is NOT yet broadly fatal.
    report('AC-VB-002', \+ vb_broadly_fatal(G, action(3))),

    % AC-VB-003: after the SAME action ends a run in a second distinct state, it is
    % counted fatal in two states.
    report('AC-VB-003',
        ( vb_note_fatal(G, s(b), action(3)),
          vb_fatal_count(G, action(3), 2) )),

    % AC-VB-004: it is now broadly fatal (threshold 2), the generalisation.
    report('AC-VB-004', vb_broadly_fatal(G, action(3))),

    % AC-VB-005: THE KEY CHECK — action(3) is predicted fatal in a NEW state never
    % seen before, purely by generalisation, before it is tried there.
    report('AC-VB-005', vb_predict_fatal(G, s(brand_new), action(3))),

    % AC-VB-006: an action that has never killed is not predicted fatal.
    report('AC-VB-006', \+ vb_predict_fatal(G, s(brand_new), action(1))),

    % AC-VB-007: ranking puts the predicted-fatal action last but does not drop it.
    report('AC-VB-007',
        ( vb_rank(G, s(x), [action(1), action(3), action(2)], Ranked),
          last(Ranked, action(3)),
          memberchk(action(1), Ranked), memberchk(action(2), Ranked) )),

    % AC-VB-008: partition separates safe from risky.
    report('AC-VB-008',
        ( vb_partition(G, s(x), [action(1), action(3)], [action(1)], [action(3)]) )),

    % AC-VB-009: PLAN IN THE MODEL — stepping right from cell 9 simulates into the
    % dead state, so the lookahead flags it fatal WITHOUT it ever being recorded.
    report('AC-VB-009',
        ( vb_note_dead_state(G, dead),
          vb_lookahead_fatal(step, G, cell(9), right) )),

    % AC-VB-010: stepping right from a safe cell does not look fatal.
    report('AC-VB-010', \+ vb_lookahead_fatal(step, G, cell(2), right)),

    % AC-VB-011: choose-safe avoids the cliff step and picks a surviving action.
    report('AC-VB-011',
        ( vb_choose_safe(step, G, cell(9), [right, left], Best), Best == left )),

    % AC-VB-012: the generalisation threshold is configurable.
    report('AC-VB-012',
        ( vb_set_threshold(3),
          \+ vb_broadly_fatal(G, action(3)),     % 2 deaths < new threshold 3
          vb_set_threshold(2),
          vb_broadly_fatal(G, action(3)) )),

    format("~n", []).

% Bring in last/2.
:- use_module(library(lists), [last/2]).
