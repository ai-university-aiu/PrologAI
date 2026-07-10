/*  PrologAI — Causalontology Goal Inference Test Suite  (WP-398)

    Feeds the inferencer a stream of deltas labelled with the state each
    produced and checks that the colour common to the wins wins the tally,
    that a colour appearing in both a win and a loss is discounted, and that
    no goal is hypothesised before any win is seen.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_goalinfer/test/test_co_goalinfer.pl
*/

% Declare this file as a test module.
:- module(test_co_goalinfer, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module(library(co_goalinfer)).

% Open the test unit for goal inference.
:- begin_tests(co_goalinfer).

% With no wins yet, no goal can be hypothesised.
test(no_goal_without_win, [fail]) :-
    % Start from a clean slate.
    cgi_reset,
    % An ongoing turn teaches nothing.
    cgi_observe([changed(1,1,0,4)], ongoing),
    % Hypothesising must fail with no win on record.
    cgi_hypothesise_goal(_).

% The colour common to the winning deltas becomes the goal.
test(common_colour_wins, [true(Goal == reach_colour(3))]) :-
    % Start from a clean slate.
    cgi_reset,
    % First win: colour three appears (with an incidental colour five).
    cgi_observe([changed(0,0,0,3), changed(2,2,0,5)], win),
    % Second win: colour three appears again (with a different incidental).
    cgi_observe([changed(1,1,0,3), changed(0,2,0,7)], win),
    % Colour three has the most support across the two wins.
    cgi_hypothesise_goal(Goal).

% A colour that also appears in a loss is discounted below a clean winner.
test(loss_discounts_feature, [true(Goal == reach_colour(3))]) :-
    % Start from a clean slate.
    cgi_reset,
    % A win where both colour three and colour eight appear.
    cgi_observe([changed(0,0,0,3), changed(1,1,0,8)], win),
    % A loss where colour eight appears again, cancelling its support.
    cgi_observe([changed(2,2,0,8)], game_over),
    % Colour three, never seen in a loss, leads.
    cgi_hypothesise_goal(Goal).

% The goal is also available as a changed/4 occurrent carrying the colour.
test(goal_occurrent, [true(C == 3)]) :-
    % Start from a clean slate.
    cgi_reset,
    % One win introducing colour three.
    cgi_observe([changed(0,0,0,3)], win),
    % The occurrent form carries the inferred colour in its fourth argument.
    cgi_goal_occurrent(changed(_, _, _, C)).

% Confidence is one when every win shares the single winning colour.
test(full_confidence, [true(Conf =:= 1.0)]) :-
    % Start from a clean slate.
    cgi_reset,
    % Two wins, both introducing only colour three.
    cgi_observe([changed(0,0,0,3)], win),
    % Second such win.
    cgi_observe([changed(1,1,0,3)], win),
    % Colour three has net two over two wins: full confidence.
    cgi_confidence(Conf).

% Close the test unit.
:- end_tests(co_goalinfer).
