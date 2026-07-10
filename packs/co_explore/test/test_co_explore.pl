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

% Close the test unit.
:- end_tests(co_explore).
