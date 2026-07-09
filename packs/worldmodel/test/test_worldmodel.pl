/*  PrologAI — World Model Pack Test Suite  (WP-385)

    Acceptance tests for all wm_* predicates.

    Run with:
        swipl -g "run_tests, halt" test_worldmodel.pl
*/

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module('../prolog/worldmodel').

% ===========================================================================
% TEST FIXTURE DOMAIN — A ROBOT, THREE ROOMS, AND A BALL
% ===========================================================================

% The action repertoire of the robot domain.
robot_actions(Actions) :-
    % Build the move action schema.
    wm_action(move(X, Y), [at(rob, X), door(X, Y)], [at(rob, Y)], [at(rob, X)], Move),
    % Build the pick action schema.
    wm_action(pick(R), [at(rob, R), in(ball, R), empty_hand], [holding(ball)], [in(ball, R), empty_hand], Pick),
    % Build the drop action schema.
    wm_action(drop(R), [at(rob, R), holding(ball)], [in(ball, R), empty_hand], [holding(ball)], Drop),
    % Collect the three schemas.
    Actions = [Move, Pick, Drop].

% The initial state: robot in room one, ball in room three.
robot_start(State) :-
    % Normalize the fluent list into a canonical state.
    wm_state([at(rob, room1), in(ball, room3), empty_hand,
              door(room1, room2), door(room2, room1),
              door(room2, room3), door(room3, room2)], State).

% ===========================================================================
% STATES, ACTIONS, AND SIMULATION
% ===========================================================================

:- begin_tests(worldmodel_core).

% States are sorted and duplicate-free.
test(state_canonical) :-
    % Normalize a messy fluent list.
    wm_state([b, a, b, c, a], State),
    % The canonical form is sorted with duplicates removed.
    State == [a, b, c].

% A fluent present in the state holds.
test(holds) :-
    % Build the initial state.
    robot_start(S),
    % The robot starts in room one.
    wm_holds(S, at(rob, room1)).

% A goal holds exactly when all its fluents are present.
test(goal_holds) :-
    % Build the initial state.
    robot_start(S),
    % A two-fluent goal that is satisfied.
    wm_goal_holds(S, [at(rob, room1), empty_hand]).

% An unsatisfied goal is rejected.
test(goal_fails, [fail]) :-
    % Build the initial state.
    robot_start(S),
    % The ball is not in room one yet.
    wm_goal_holds(S, [in(ball, room1)]).

% Taking a step binds the action parameters against the state.
test(step_binds_parameters) :-
    % Build the fixtures.
    robot_start(S),
    % Fetch the action repertoire.
    robot_actions(As),
    % Ask for any applicable step.
    wm_step(S, As, Name, S2),
    % The only applicable action is moving to room two.
    Name == move(room1, room2),
    % The robot arrived in room two.
    wm_holds(S2, at(rob, room2)),
    % Only one grounded step exists from the start.
    !.

% Applying an action adds and deletes the right fluents.
test(apply_effects) :-
    % Build the fixtures.
    robot_start(S),
    % Fetch the action repertoire.
    robot_actions(As),
    % Take the opening move.
    wm_step(S, As, move(room1, room2), S2),
    % The new location holds.
    wm_holds(S2, at(rob, room2)),
    % The old location was deleted.
    \+ wm_holds(S2, at(rob, room1)).

% The successor set enumerates every grounded next state.
test(successors) :-
    % Build the fixtures.
    robot_start(S),
    % Fetch the action repertoire.
    robot_actions(As),
    % Compute the successor pairs.
    wm_successors(S, As, Pairs),
    % Only the single move is applicable at the start.
    Pairs = [move(room1, room2)-_].

% Simulating a plan returns the full state trajectory.
test(simulate_full_plan) :-
    % Build the fixtures.
    robot_start(S),
    % Fetch the action repertoire.
    robot_actions(As),
    % The six-step fetch-the-ball plan.
    Plan = [move(room1, room2), move(room2, room3), pick(room3),
            move(room3, room2), move(room2, room1), drop(room1)],
    % Run the simulation.
    wm_simulate(S, As, Plan, Trajectory),
    % Six steps visit seven states.
    length(Trajectory, 7),
    % Read the final state.
    last(Trajectory, Final),
    % The ball ended up in room one.
    wm_holds(Final, in(ball, room1)),
    % The robot's hand is free again.
    wm_holds(Final, empty_hand).

% An inapplicable plan step makes simulation fail honestly.
test(simulate_inapplicable, [fail]) :-
    % Build the fixtures.
    robot_start(S),
    % Fetch the action repertoire.
    robot_actions(As),
    % The ball is in room three, so picking in room one is impossible.
    wm_simulate(S, As, [pick(room1)], _).

% The state difference reports additions and removals.
test(diff) :-
    % Compare two small states.
    wm_diff([a, b, c], [b, c, d], Added, Removed),
    % One fluent was added.
    Added == [d],
    % One fluent was removed.
    Removed == [a].

:- end_tests(worldmodel_core).

% ===========================================================================
% PLANNING SEARCH AND ROLLOUT
% ===========================================================================

:- begin_tests(worldmodel_planning).

% Breadth-first search finds the shortest fetch-the-ball plan.
test(plan_bfs_shortest, [nondet]) :-
    % Build the fixtures.
    robot_start(S),
    % Fetch the action repertoire.
    robot_actions(As),
    % Search for a plan that brings the ball to room one.
    wm_plan_bfs(S, As, [in(ball, room1)], 8, Plan),
    % The shortest plan takes exactly six steps.
    length(Plan, 6),
    % The plan must actually work when simulated.
    wm_simulate(S, As, Plan, Trajectory),
    % Read the final state.
    last(Trajectory, Final),
    % The goal holds at the end.
    wm_goal_holds(Final, [in(ball, room1)]).

% A goal that already holds needs the empty plan.
test(plan_bfs_trivial) :-
    % Build the fixtures.
    robot_start(S),
    % Fetch the action repertoire.
    robot_actions(As),
    % The robot is already in room one.
    wm_plan_bfs(S, As, [at(rob, room1)], 3, Plan),
    % No steps are needed.
    Plan == [].

% A goal beyond the depth bound is not found.
test(plan_bfs_depth_bound, [fail]) :-
    % Build the fixtures.
    robot_start(S),
    % Fetch the action repertoire.
    robot_actions(As),
    % Two steps are not enough to fetch the ball.
    wm_plan_bfs(S, As, [in(ball, room1)], 2, _).

% Reachability counts the start state and its one successor at depth one.
test(reachable_depth_one, [nondet]) :-
    % Build the fixtures.
    robot_start(S),
    % Fetch the action repertoire.
    robot_actions(As),
    % All states within one step.
    wm_reachable(S, As, 1, States),
    % The start plus the single move.
    length(States, 2).

% Rollouts enumerate the empty sequence and each one-step sequence.
test(rollout_depth_one) :-
    % Build the fixtures.
    robot_start(S),
    % Fetch the action repertoire.
    robot_actions(As),
    % All rollouts of length at most one.
    wm_rollout(S, As, 1, Rollouts),
    % The empty rollout plus the single applicable step.
    length(Rollouts, 2),
    % The empty rollout ends where it started.
    memberchk([]-S, Rollouts).

:- end_tests(worldmodel_planning).

% ===========================================================================
% MODEL LEARNING AND NOVELTY
% ===========================================================================

:- begin_tests(worldmodel_learning).

% Learning generalizes preconditions and effects across observations.
test(learn_action_model) :-
    % Two observations of the heat action in different contexts.
    Transitions = [
        tr(heat, [power(on), temp(cold)], [power(on), temp(warm)]),
        tr(heat, [power(on), temp(cold), window(open)],
                 [power(on), temp(warm), window(open)])
    ],
    % Induce the action models.
    wm_learn(Transitions, Models),
    % Exactly one action was observed.
    Models = [act(heat, Pre, Add, Del)],
    % The shared preconditions survive the intersection.
    Pre == [power(on), temp(cold)],
    % The gained fluent is the add effect.
    Add == [temp(warm)],
    % The lost fluent is the delete effect.
    Del == [temp(cold)].

% A learned model predicts the next state in a new context.
test(predict_with_learned_model, [nondet]) :-
    % The same two observations as above.
    Transitions = [
        tr(heat, [power(on), temp(cold)], [power(on), temp(warm)]),
        tr(heat, [power(on), temp(cold), window(open)],
                 [power(on), temp(warm), window(open)])
    ],
    % Induce the action models.
    wm_learn(Transitions, Models),
    % Predict in a state never observed during learning.
    wm_predict(Models, [power(on), radio(on), temp(cold)], heat, S2),
    % The temperature changed.
    wm_holds(S2, temp(warm)),
    % The unrelated fluent survived.
    wm_holds(S2, radio(on)),
    % The old temperature is gone.
    \+ wm_holds(S2, temp(cold)).

% Prediction fails when the learned preconditions do not hold.
test(predict_preconditions, [fail]) :-
    % A single observation suffices to learn the model.
    wm_learn([tr(heat, [power(on), temp(cold)], [power(on), temp(warm)])], Models),
    % The room is already warm, so the model must not fire.
    wm_predict(Models, [power(on), temp(warm)], heat, _).

% Novelty is the fraction of fluents never seen before.
test(novelty_fraction) :-
    % Two states have been seen so far.
    Known = [[a, b], [b, c]],
    % Half of this state is new.
    wm_novelty(Known, [a, d], Half),
    % Check the fraction.
    abs(Half - 0.5) < 1.0e-9,
    % A fully familiar state scores zero.
    wm_novelty(Known, [a, b, c], Zero),
    % Check the zero score.
    Zero =:= 0.0,
    % A fully novel state scores one.
    wm_novelty(Known, [x, y], One),
    % Check the full score.
    abs(One - 1.0) < 1.0e-9.

% An empty state carries no novelty.
test(novelty_empty) :-
    % Score the empty state.
    wm_novelty([[a]], [], Score),
    % The guard returns zero rather than dividing by zero.
    Score =:= 0.0.

:- end_tests(worldmodel_learning).
