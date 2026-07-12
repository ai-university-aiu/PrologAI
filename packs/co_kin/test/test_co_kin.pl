/*  PrologAI — Causalontology Theory of Mind Test Suite  (WP-418)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_kin/test/test_co_kin.pl
*/

% Declare this file as a test module.
:- module(test_co_kin, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(co_kin)).

% Open the test block.
:- begin_tests(co_kin).

% Net approach measures how much distance the agent closed toward a target.
test(approach_measures_closing) :-
    co_kin:kn_reset,
    co_kin:kn_candidate_add(rival, cell(0,0)),
    % Two steps heading toward the origin: (5,0)->(4,0)->(3,0).
    co_kin:kn_note_move(rival, cell(5,0), cell(4,0)),
    co_kin:kn_note_move(rival, cell(4,0), cell(3,0)),
    co_kin:kn_approach(rival, cell(0,0), Net),
    assertion(Net =:= 2).

% The inferred goal is the target the agent moves toward, not away from.
test(infer_goal_toward) :-
    co_kin:kn_reset,
    co_kin:kn_candidate_add(rival, cell(0,0)),   % the agent approaches this
    co_kin:kn_candidate_add(rival, cell(9,9)),   % the agent moves away from this
    co_kin:kn_note_move(rival, cell(5,5), cell(4,4)),
    co_kin:kn_note_move(rival, cell(4,4), cell(3,3)),
    co_kin:kn_infer_goal(rival, Goal),
    assertion(Goal == cell(0,0)).

% The predicted next step reduces the larger-axis gap to the goal.
test(predict_next_step) :-
    co_kin:kn_reset,
    co_kin:kn_candidate_add(rival, cell(0,0)),
    co_kin:kn_note_move(rival, cell(5,2), cell(4,2)),
    % From (4,2) the row gap (4) exceeds the column gap (2): step in row.
    co_kin:kn_predict_next(rival, cell(4,2), Next),
    assertion(Next == cell(3,2)).

% With no net approach to any candidate, no goal is inferred.
test(no_goal_when_not_approaching) :-
    co_kin:kn_reset,
    co_kin:kn_candidate_add(rival, cell(0,0)),
    % A step directly away from the target.
    co_kin:kn_note_move(rival, cell(1,0), cell(2,0)),
    assertion(\+ co_kin:kn_infer_goal(rival, _)).

% A belief the true state contradicts is a false belief (Sally-Anne).
test(false_belief) :-
    co_kin:kn_reset,
    % Sally believes the ball is in the basket.
    co_kin:kn_belief_add(sally, location(ball, basket)),
    % In truth it was moved to the box.
    co_kin:kn_truth_add(location(ball, box)),
    assertion(co_kin:kn_false_belief(sally, location(ball, basket))).

% A belief that matches the truth is not a false belief.
test(true_belief_not_false) :-
    co_kin:kn_reset,
    co_kin:kn_belief_add(anne, location(ball, box)),
    co_kin:kn_truth_add(location(ball, box)),
    assertion(\+ co_kin:kn_false_belief(anne, location(ball, box))).

% Two agents can hold different beliefs about the same world.
test(agents_differ) :-
    co_kin:kn_reset,
    co_kin:kn_belief_add(sally, location(ball, basket)),
    co_kin:kn_belief_add(anne, location(ball, box)),
    co_kin:kn_truth_add(location(ball, box)),
    assertion(co_kin:kn_false_belief(sally, location(ball, basket))),
    assertion(\+ co_kin:kn_false_belief(anne, _)).

% Close the test block.
:- end_tests(co_kin).
