/*  PrologAI — Causalontology Exploration Policy Test Suite  (WP-397)

    Checks the four behaviours the pack exists for: a canonical signature that
    recognises a returned-to state as a loop, salient click targeting that
    turns the ACTION6 marker into a handful of object-centroid clicks rather
    than 4096 blind cells, curiosity ranking that prefers the least-tried
    action, and the avoid-set being honoured.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_explore/test/test_co_explore.pl
*/

% Declare this file as a test module.
:- module(test_co_explore, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module(library(co_explore)).
% Load the learner so its avoid-set can be exercised.
:- use_module(library(co_learn)).
% Load the verb layer so its relation store can be cleared between tests.
:- use_module(library(co_core)).

% A small frame with one non-background object of colour one.
sample_frame([[0,0,0],[0,1,1],[0,1,0]]).
% A different frame, all background, used to check novelty.
blank_frame([[0,0,0],[0,0,0],[0,0,0]]).

% ---------------------------------------------------------------------------
% The test unit.
% ---------------------------------------------------------------------------

% Open the test unit for the exploration policy.
:- begin_tests(co_explore).

% A signature is stable and order-free for the same frame.
test(signature_stable) :-
    % Fetch the sample frame.
    sample_frame(F),
    % Compute the signature twice.
    cox_signature(F, S1),
    % And again.
    cox_signature(F, S2),
    % The two signatures must be identical.
    S1 == S2.

% A remembered frame is recognised as a loop; a fresh one is novel.
test(loop_and_novelty) :-
    % Start from an empty memory.
    cox_reset,
    % Fetch the sample and blank frames.
    sample_frame(F), blank_frame(B),
    % Remember the sample frame.
    cox_mark_seen(F),
    % Returning to it counts as a loop.
    cox_would_loop(F),
    % The blank frame has not been seen, so it is novel.
    cox_is_novel(B),
    % Exactly one distinct state is remembered.
    cox_seen_count(1).

% The single object's centroid is the one salient click target.
test(salient_click, [true(Targets == [select(1,1)])]) :-
    % Fetch the sample frame.
    sample_frame(F),
    % Its salient click targets.
    cox_click_targets(F, Targets).

% The click marker expands to concrete targets while other actions pass through.
test(expand_click, [true(E == [action(1), select(1,1)])]) :-
    % Fetch the sample frame.
    sample_frame(F),
    % Expand a mixed action list containing the click marker.
    cox_expand_actions([action(1), click], F, E).

% With no learned effects, curiosity picks the least-tried action.
test(least_tried_first, [true(A == action(2))]) :-
    % Start from an empty memory.
    cox_reset,
    % Fetch the sample frame.
    sample_frame(F),
    % action(1) has been tried three times; action(2) not at all.
    cox_choose([action(1), action(2)], [action(1)-3], F, A).

% An avoided action is never chosen even when it is the least tried.
test(avoid_honoured, [true(A == action(2))]) :-
    % Start from empty exploration memory.
    cox_reset,
    % Clear then seed the learner's avoid-set with a hazard.
    co_learn_reset,
    % Mark action(1) as a hazard to avoid.
    co_learn_preventive(action(1), penalty),
    % Fetch the sample frame.
    sample_frame(F),
    % Even untried, the avoided action(1) must not be chosen.
    cox_choose([action(1), action(2)], [], F, A).

% A frame with two objects of different sizes: the larger object's centroid is
% offered as a click target before the smaller one's.
two_object_frame([[2,2,2,0,0],
                  [2,2,2,0,0],
                  [2,2,2,0,0],
                  [0,0,0,0,5],
                  [0,0,0,0,0]]).

% The salient click targets are ordered largest object first.
test(salient_largest_first, [true(Targets == [select(1,1), select(4,3)])]) :-
    % Fetch the two-object frame.
    two_object_frame(F),
    % The larger colour-2 block (centroid row 1,col 1) precedes the single
    % colour-5 cell (row 3,col 4) -> select(x=col,y=row).
    cox_click_targets(F, Targets).

% A game-keyed causal relation makes its action predicted-to-change for that
% game only — another game with no such relation predicts nothing.
test(game_predicted_change) :-
    % Clear the learner and the verb layer.
    co_core_reset, co_learn_reset,
    % Teach that, in game ls20, action(up) causes a move.
    co_learn_causal(g(ls20, action(up)), moved),
    % In ls20 that action is predicted to change the world.
    cox_predict_change(ls20, action(up)),
    % In a different game the same action is not predicted (no relation there).
    \+ cox_predict_change(vc33, action(up)).

% The game-scoped choice prefers this game's predicted-change action over an
% untried but unknown one.
test(game_prefers_predicted_change, [true(A == action(up))]) :-
    % Start clean.
    co_core_reset, co_learn_reset, cox_reset,
    % Teach ls20 that action(up) changes the world.
    co_learn_causal(g(ls20, action(up)), moved),
    % Fetch the sample frame.
    sample_frame(F),
    % action(up) is predicted-change (tried once); action(down) is unknown (untried).
    cox_choose(ls20, [action(up), action(down)], [action(up)-1], F, A).

% cox_choose_change/5 fails when nothing is predicted to change, so the caller
% can fall back to a graph-frontier search.
test(game_change_fails_when_none) :-
    % Start clean: no learned relations at all.
    co_core_reset, co_learn_reset, cox_reset,
    % Fetch the sample frame.
    sample_frame(F),
    % With no predicted-change action, the causal-first choice fails.
    \+ cox_choose_change(ls20, [action(up), action(down)], [], F, _).

% A hazard the game learned to avoid, keyed g(Game,Action), is never chosen.
test(game_avoid_honoured, [true(A == action(down))]) :-
    % Start clean.
    co_core_reset, co_learn_reset, cox_reset,
    % Mark action(up) a hazard in game ls20 only.
    co_learn_preventive(g(ls20, action(up)), penalty),
    % Fetch the sample frame.
    sample_frame(F),
    % Even untried, the avoided action(up) must not be chosen for ls20.
    cox_choose(ls20, [action(up), action(down)], [], F, A).

% Close the test unit.
:- end_tests(co_explore).
