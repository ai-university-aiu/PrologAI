/*  PrologAI — Causalontology World Model Test Suite  (WP-407)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_wm/test/test_co_wm.pl
*/

% Declare this file as a test module.
:- module(test_co_wm, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(co_wm)).

% Open the test block for co_wm.
:- begin_tests(co_wm).

% AC-WM-001: after observing a transition, the model predicts it.
test(observe_then_predict) :-
    % Start from an empty model.
    wm_reset,
    % Record a single right -> move_east transition.
    wm_observe(game, any, right, move_east),
    % Predict the effect of right in that context.
    wm_predict(game, any, right, E),
    % The prediction is the observed effect.
    assertion(E == move_east).

% AC-WM-002: the majority effect wins, with a confidence share.
test(majority_wins_with_confidence) :-
    % Start from an empty model.
    wm_reset,
    % Record move_east twice and blocked once for right.
    wm_observe(game, any, right, move_east),
    wm_observe(game, any, right, move_east),
    wm_observe(game, any, right, blocked),
    % Predict the effect and read the confidence share.
    wm_predict(game, any, right, E, C),
    % The majority effect is move_east.
    assertion(E == move_east),
    % Its share of the observations exceeds sixty percent.
    assertion(C > 0.6).

% AC-WM-003: a context-specific effect overrides the general one.
test(context_specific_overrides) :-
    % Start from an empty model.
    wm_reset,
    % A general right -> move_east observation.
    wm_observe(game, any, right, move_east),
    % Two on_ice right -> slide_far observations.
    wm_observe(game, on_ice, right, slide_far),
    wm_observe(game, on_ice, right, slide_far),
    % Predicting in the on_ice context uses its own tallies.
    wm_predict(game, on_ice, right, E),
    % The context-specific effect wins there.
    assertion(E == slide_far).

% AC-WM-004: an UNSEEN context falls back to the action-general rule.
test(unseen_context_falls_back) :-
    % Start from an empty model.
    wm_reset,
    % Record right -> move_east in a known context.
    wm_observe(game, any, right, move_east),
    % Predict right in a context never observed with it.
    wm_predict(game, brand_new_context, right, E),
    % The action-general rule supplies move_east.
    assertion(E == move_east).

% AC-WM-005: verify reports a match when reality agrees with the prediction.
test(verify_match) :-
    % Start from an empty model.
    wm_reset,
    % Record right -> move_east.
    wm_observe(game, any, right, move_east),
    % Verify the prediction against an agreeing observation.
    wm_verify(game, any, right, move_east, R),
    % Reality agrees, so the result is a match.
    assertion(R == match).

% AC-WM-006: verify reports a mismatch (the repair signal) when it disagrees.
test(verify_mismatch) :-
    % Start from an empty model.
    wm_reset,
    % Record right -> move_east.
    wm_observe(game, any, right, move_east),
    % Verify the prediction against a disagreeing observation.
    wm_verify(game, any, right, teleport, R),
    % The result names both the predicted and observed effects.
    assertion(R == mismatch(move_east, teleport)).

% AC-WM-007: repair folds the truth in; enough repairs flip the prediction.
test(repair_flips_prediction) :-
    % Start from an empty model.
    wm_reset,
    % Record right -> move_east once.
    wm_observe(game, any, right, move_east),
    % Repair with the contradicting truth ten times.
    forall(between(1, 10, _), wm_repair(game, any, right, teleport)),
    % Predict right again after the repairs.
    wm_predict(game, any, right, E),
    % The majority has shifted, so the prediction is now teleport.
    assertion(E == teleport).

% AC-WM-008: rollout predicts a whole action sequence (plan-in-model).
test(rollout_predicts_sequence) :-
    % Start from an empty model.
    wm_reset,
    % Record a -> x and b -> y.
    wm_observe(game, any, a, x),
    wm_observe(game, any, b, y),
    % Roll the action sequence a, b, a forward in the model.
    once(wm_rollout(game, any, [a, b, a], Effects)),
    % Each step predicts its learned effect.
    assertion(Effects == [x, y, x]).

% AC-WM-009: a context-free action is surfaced as a general LAW; a context-
% dependent one is not.
test(law_only_when_context_free) :-
    % Start from an empty model.
    wm_reset,
    % up -> jump in two different contexts (context-free).
    wm_observe(game, c1, up, jump),
    wm_observe(game, c2, up, jump),
    % down -> fall in one context and sink in another (context-dependent).
    wm_observe(game, c1, down, fall),
    wm_observe(game, c2, down, sink),
    % up is a general law with a single effect everywhere.
    assertion(wm_law(game, up, jump)),
    % down has conflicting effects, so it is not a law.
    assertion(\+ wm_law(game, down, _)).

% Close the test block for co_wm.
:- end_tests(co_wm).

% ===========================================================================
% MODE 2 — the structured simulate-and-plan model (absorbed from worldmodel).
% Fixture domain: a robot, three rooms, and a ball.
% ===========================================================================

% robot_actions(-Actions): the action repertoire of the robot domain.
robot_actions(Actions) :-
    % Build the move action schema.
    wm_action(move(X, Y), [at(rob, X), door(X, Y)], [at(rob, Y)], [at(rob, X)], Move),
    % Build the pick action schema.
    wm_action(pick(R), [at(rob, R), in(ball, R), empty_hand], [holding(ball)], [in(ball, R), empty_hand], Pick),
    % Build the drop action schema.
    wm_action(drop(R), [at(rob, R), holding(ball)], [in(ball, R), empty_hand], [holding(ball)], Drop),
    % Collect the three schemas.
    Actions = [Move, Pick, Drop].

% robot_start(-State): the initial state — robot in room one, ball in room three.
robot_start(State) :-
    % Normalize the fluent list into a canonical state.
    wm_state([at(rob, room1), in(ball, room3), empty_hand,
              door(room1, room2), door(room2, room1),
              door(room2, room3), door(room3, room2)], State).

% Open the Mode-2 core test block.
:- begin_tests(co_wm_planning).

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

% Enumeration lists the empty sequence and each one-step sequence
% (wm_enumerate is the absorbed worldmodel wm_rollout, renamed).
test(enumerate_depth_one) :-
    % Build the fixtures.
    robot_start(S),
    % Fetch the action repertoire.
    robot_actions(As),
    % All rollouts of length at most one.
    wm_enumerate(S, As, 1, Rollouts),
    % The empty rollout plus the single applicable step.
    length(Rollouts, 2),
    % The empty rollout ends where it started.
    memberchk([]-S, Rollouts).

% Close the Mode-2 core test block.
:- end_tests(co_wm_planning).

% Open the Mode-2 learning test block.
:- begin_tests(co_wm_learning).

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

% A learned model predicts the next state in a new context
% (wm_model_predict is the absorbed worldmodel wm_predict, renamed).
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
    wm_model_predict(Models, [power(on), radio(on), temp(cold)], heat, S2),
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
    wm_model_predict(Models, [power(on), temp(warm)], heat, _).

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

% Close the Mode-2 learning test block.
:- end_tests(co_wm_learning).

% Open the Causalontology-bridge test block.
:- begin_tests(co_wm_bridge).

% The learned model can be emitted as reified CROs with correct strengths.
test(as_cros_shape) :-
    % Start from an empty model.
    wm_reset,
    % Two move_east and one blocked observation for right.
    wm_observe(g, any, right, move_east),
    wm_observe(g, any, right, move_east),
    wm_observe(g, any, right, blocked),
    % Emit the learned transitions as CROs.
    wm_as_cros(g, CROs),
    % The move_east transition is a CRO whose cause is the action and whose
    % strength is its share of the observations (two of three).
    memberchk(cro(cro_wm(any, right, move_east), [do(right)], [move_east],
                  temporal(0, 0, instant), sufficient, S,
                  [context(any)], prov(co_wm, learned_by_observation, S)), CROs),
    % Its strength is two thirds.
    assertion(abs(S - 0.6666666666666666) < 1.0e-9).

% Close the Causalontology-bridge test block.
:- end_tests(co_wm_bridge).
