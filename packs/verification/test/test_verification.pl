/*  Tests for verification — Verify-Before-Act (WP-405, Layer 380)

    A standard PLUnit suite exercising exact fatal memory, the generalisation
    to broadly-fatal actions, predictive verification before acting, safe-first
    ranking, and planning one step in a caller-supplied transition model.

    Run:
      swipl -p library=packs/verification/prolog -g "run_tests, halt" \
            packs/verification/test/test_verification.pl
*/

% Declare the test module, exporting nothing.
:- module(test_verification, []).

% Bring in the PLUnit test framework.
:- use_module(library(plunit)).
% Load the pack under test from the library path.
:- use_module(library(verification)).
% List helpers used inside the assertions.
:- use_module(library(lists), [member/2, memberchk/2, last/2]).

% A tiny deterministic transition model for the plan-in-model tests: stepping
% right from a cell state moves to the next cell; cell 9 is a cliff (leads to the
% dead state 'dead').
step(cell(N), right, Next) :-
    % From cell 9 or beyond, stepping right falls into the dead state.
    ( N >= 9 -> Next = dead ; N1 is N + 1, Next = cell(N1) ).
% Stepping left holds position at the same non-negative cell.
step(cell(N), left, cell(N)) :- N >= 0.

% Open the verification test suite.
:- begin_tests(verification).

% AC-VB-001: an exact fatal transition is remembered.
test(exact_fatal_remembered) :-
    % Start from a clean fatality model.
    verification_reset,
    % Record that action(3) ended a run from state s(a).
    verification_note_fatal(game1, s(a), action(3)),
    % The exact recorded-fatal test finds it.
    assertion(verification_fatal_here(game1, s(a), action(3))).

% AC-VB-002: an action fatal in one state only is NOT yet broadly fatal.
test(one_state_not_broadly_fatal) :-
    % Clean model.
    verification_reset,
    % A single fatal transition.
    verification_note_fatal(game1, s(a), action(3)),
    % One state is below the default threshold of two, so not broadly fatal.
    assertion(\+ verification_broadly_fatal(game1, action(3))).

% AC-VB-003: after the SAME action ends a run in a second distinct state, it is
% counted fatal in two states.
test(two_distinct_states_counted) :-
    % Clean model.
    verification_reset,
    % First fatal state.
    verification_note_fatal(game1, s(a), action(3)),
    % A second, distinct fatal state.
    verification_note_fatal(game1, s(b), action(3)),
    % The distinct-state count is two.
    assertion(verification_fatal_count(game1, action(3), 2)).

% AC-VB-004: it is now broadly fatal (threshold 2), the generalisation.
test(broadly_fatal_at_threshold) :-
    % Clean model.
    verification_reset,
    % Two distinct fatal states for action(3).
    verification_note_fatal(game1, s(a), action(3)),
    verification_note_fatal(game1, s(b), action(3)),
    % Two distinct deaths reach the threshold, so it generalises to broadly fatal.
    assertion(verification_broadly_fatal(game1, action(3))).

% AC-VB-005: THE KEY CHECK — action(3) is predicted fatal in a NEW state never
% seen before, purely by generalisation, before it is tried there.
test(predict_fatal_in_new_state) :-
    % Clean model.
    verification_reset,
    % Two distinct fatal states for action(3).
    verification_note_fatal(game1, s(a), action(3)),
    verification_note_fatal(game1, s(b), action(3)),
    % In a brand-new state it is still predicted fatal, before being tried here.
    assertion(verification_predict_fatal(game1, s(brand_new), action(3))).

% AC-VB-006: an action that has never killed is not predicted fatal.
test(never_killed_not_predicted_fatal) :-
    % Clean model.
    verification_reset,
    % Only action(3) is ever fatal.
    verification_note_fatal(game1, s(a), action(3)),
    verification_note_fatal(game1, s(b), action(3)),
    % action(1) has never killed, so it is not predicted fatal.
    assertion(\+ verification_predict_fatal(game1, s(brand_new), action(1))).

% AC-VB-007: ranking puts the predicted-fatal action last but does not drop it.
test(ranking_puts_fatal_last) :-
    % Clean model.
    verification_reset,
    % Make action(3) broadly fatal.
    verification_note_fatal(game1, s(a), action(3)),
    verification_note_fatal(game1, s(b), action(3)),
    % Rank a mixed action set.
    verification_rank(game1, s(x), [action(1), action(3), action(2)], Ranked),
    % The predicted-fatal action falls to the back.
    assertion(last(Ranked, action(3))),
    % The safe actions are still present, nothing is dropped.
    assertion(memberchk(action(1), Ranked)),
    assertion(memberchk(action(2), Ranked)).

% AC-VB-008: partition separates safe from risky.
test(partition_safe_from_risky) :-
    % Clean model.
    verification_reset,
    % Make action(3) broadly fatal.
    verification_note_fatal(game1, s(a), action(3)),
    verification_note_fatal(game1, s(b), action(3)),
    % Partition splits the safe action(1) from the risky action(3).
    assertion(verification_partition(game1, s(x), [action(1), action(3)],
                           [action(1)], [action(3)])).

% AC-VB-009: PLAN IN THE MODEL — stepping right from cell 9 simulates into the
% dead state, so the lookahead flags it fatal WITHOUT it ever being recorded.
test(lookahead_into_dead_state) :-
    % Clean model.
    verification_reset,
    % Record that 'dead' is a terminal state.
    verification_note_dead_state(game1, dead),
    % Stepping right from cell 9 simulates into 'dead', so it looks fatal.
    assertion(verification_lookahead_fatal(step, game1, cell(9), right)).

% AC-VB-010: stepping right from a safe cell does not look fatal.
test(lookahead_safe_cell) :-
    % Clean model.
    verification_reset,
    % 'dead' is terminal.
    verification_note_dead_state(game1, dead),
    % Stepping right from cell 2 lands in cell 3, which is not dead.
    assertion(\+ verification_lookahead_fatal(step, game1, cell(2), right)).

% AC-VB-011: choose-safe avoids the cliff step and picks a surviving action.
test(choose_safe_avoids_cliff) :-
    % Clean model.
    verification_reset,
    % 'dead' is terminal.
    verification_note_dead_state(game1, dead),
    % Choose between the fatal 'right' and the surviving 'left' at cell 9.
    verification_choose_safe(step, game1, cell(9), [right, left], Best),
    % The surviving action 'left' is chosen.
    assertion(Best == left).

% AC-VB-012: the generalisation threshold is configurable.
test(threshold_configurable) :-
    % Clean model.
    verification_reset,
    % Two distinct fatal states for action(3).
    verification_note_fatal(game1, s(a), action(3)),
    verification_note_fatal(game1, s(b), action(3)),
    % Raise the threshold to three: two deaths no longer generalise.
    verification_set_threshold(3),
    assertion(\+ verification_broadly_fatal(game1, action(3))),
    % Lower it back to two: two deaths generalise again.
    verification_set_threshold(2),
    assertion(verification_broadly_fatal(game1, action(3))).

% Close the verification test suite.
:- end_tests(verification).
