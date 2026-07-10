/*  PrologAI — ARC-AGI-3 Human-Step Ladder Test Suite  (WP-401)

    Checks the ladder is complete and well-formed, that walking it holds the
    current step in the J-Space workspace so the J-Lens reads it back, and that
    the discrete action-response Jacobian locates the controllable object,
    reports its per-action displacement, and ranks the actions toward a goal.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_hsteps/test/test_co_hsteps.pl
*/

% Declare this file as a test module.
:- module(test_co_hsteps, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module(library(co_hsteps)).
% Load the J-Space workspace so the readout can be inspected directly.
:- use_module(library(jspace), [js_active/2]).
% Load list helpers.
:- use_module(library(lists), [member/2]).

% Transitions for a colour-three avatar moving from the centre of a 3x3 grid.
avatar_transitions([
    t(action(1), [[0,0,0],[0,3,0],[0,0,0]], [[0,3,0],[0,0,0],[0,0,0]]),
    t(action(2), [[0,0,0],[0,3,0],[0,0,0]], [[0,0,0],[0,0,0],[0,3,0]]),
    t(action(3), [[0,0,0],[0,3,0],[0,0,0]], [[0,0,0],[3,0,0],[0,0,0]]),
    t(action(4), [[0,0,0],[0,3,0],[0,0,0]], [[0,0,0],[0,0,3],[0,0,0]])
]).

% Open the test unit for the human-step ladder.
:- begin_tests(co_hsteps).

% The ladder has exactly thirty steps, each in a phase from one to six.
test(ladder_complete) :-
    % The full ladder.
    hs_ladder(Steps),
    % It has thirty steps.
    length(Steps, 30),
    % Every step has a known phase in range.
    forall(member(S, Steps),
        ( hs_phase_of(S, P), integer(P), P >= 1, P =< 6, hs_phase(P, _) )).

% There are exactly six phases.
test(six_phases, [true(N == 6)]) :-
    % Count the phases.
    findall(P, hs_phase(P, _), Ps),
    % How many.
    length(Ps, N).

% Resetting opens the workspace at the first step and the J-Lens reads it.
test(reset_holds_first) :-
    % Open a fresh workspace at the first step.
    hs_reset(hs_test),
    % The current step is the first of the ladder.
    hs_current(hs_test, 'I.1'),
    % The J-Lens readout holds the first step.
    hs_reading(hs_test, Reading),
    % It appears in the reading.
    member(hstep('I.1')-_, Reading).

% Advancing moves to the next step and makes it the current one.
test(advance_moves_on, [true(Next == 'I.2')]) :-
    % Fresh workspace.
    hs_reset(hs_test2),
    % Advance one step (deterministically).
    once(hs_advance(hs_test2, Next)),
    % The current step is now the second.
    hs_current(hs_test2, 'I.2').

% The controllable object is the colour whose centroid moves under the actions.
test(controllable_is_avatar, [true(Colour == 3)]) :-
    % The avatar transitions.
    avatar_transitions(Ts),
    % The controllable colour.
    hs_controllable(Ts, Colour).

% The Jacobian records the avatar's displacement for each action.
test(jacobian_displacements) :-
    % The avatar transitions.
    avatar_transitions(Ts),
    % The Jacobian for the avatar colour.
    hs_jacobian(Ts, 3, Jac),
    % Up moves it one row up.
    once(member(jac(action(1), -1, 0), Jac)),
    % Right moves it one column right.
    once(member(jac(action(4), 0, 1), Jac)).

% The goal gradient ranks the action that reaches the goal first.
test(goal_gradient_ranks, [true(Best == action(4))]) :-
    % The avatar transitions.
    avatar_transitions(Ts),
    % The Jacobian.
    hs_jacobian(Ts, 3, Jac),
    % Rank actions from the centre toward the cell one column to the right.
    hs_goal_gradient(Jac, cell(1,1), cell(1,2), [Best | _]).

% Sensitivity reports a change count for every action tried.
test(sensitivity_per_action, [true(N == 4)]) :-
    % The avatar transitions.
    avatar_transitions(Ts),
    % The sensitivity list.
    hs_sensitivity(Ts, Sens),
    % One entry per action.
    length(Sens, N).

% Close the test unit.
:- end_tests(co_hsteps).
