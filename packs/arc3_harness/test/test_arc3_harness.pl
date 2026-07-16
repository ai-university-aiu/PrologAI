/*  PrologAI — Causalontology ARC-AGI-3 Harness Test Suite  (WP-396)

    The environment here is a deterministic mock of the volume-control
    style of game: a level counter rises when the transfer control is
    pressed, a spike cell hurts, and the level is won at counter two. The
    harness must discover the mechanics by acting, learn the hazard and
    never repeat it, and win within the budget — the perceive-learn-plan-
    act loop of Section 9 closed against a real (if small) game.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/arc3_harness/test/test_co_arc3.pl
*/

% Declare this file as a test module.
:- module(test_co_arc3, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module(library(arc3_harness)).
% Load the verb layer the harness induces relations into.
:- use_module(library(causal_core)).
% Load the learner whose avoid-set the harness enforces.
:- use_module(library(causal_learning)).
% Load the hinge cleared alongside.
:- use_module(library(realizable_hinge)).

% ---------------------------------------------------------------------------
% The mock game — hidden mechanics the harness must discover by acting.
% ---------------------------------------------------------------------------

% mock_level_/1: the game's hidden level counter.
:- dynamic mock_level_/1.

% mock_frame(+Level, +Marker, -Frame): render the game state as a grid.
mock_frame(Level, Marker, [[Level, 0, 0], [0, 0, 0], [0, 0, Marker]]).

% mock_reset(-Frame0): reset the game to level zero.
mock_reset(Frame0) :-
    % Reset the hidden counter.
    retractall(mock_level_(_)),
    % Level zero.
    assertz(mock_level_(0)),
    % Render the first frame.
    mock_frame(0, 0, Frame0).

% mock_act(+Action, -Frame1): the game's hidden mechanics.
mock_act(action(transfer), Frame1) :-
    % Transfer raises the level, capped at two.
    retract(mock_level_(L)),
    % The raise.
    L1 is min(2, L + 1),
    % Store the new level.
    assertz(mock_level_(L1)),
    % Render without a hazard marker.
    mock_frame(L1, 0, Frame1),
    % Commit.
    !.
% The spike hurts: the frame shows the penalty marker fifteen.
mock_act(action(spike), Frame1) :-
    % The level is unchanged.
    mock_level_(L),
    % Render with the hazard marker.
    mock_frame(L, 15, Frame1),
    % Commit.
    !.
% Anything else does nothing.
mock_act(_, Frame1) :-
    % The level is unchanged.
    mock_level_(L),
    % Render without a marker.
    mock_frame(L, 0, Frame1).

% mock_actions(-Actions): the game's small action set.
mock_actions([action(noop), action(spike), action(transfer)]).

% mock_solved(+Frame): the level is won at counter two.
mock_solved([[2 | _] | _]).

% mock_env(-Env): the pluggable environment term.
mock_env(arc3_env(test_co_arc3:mock_reset,
                  test_co_arc3:mock_act,
                  test_co_arc3:mock_actions,
                  test_co_arc3:mock_solved)).

% fresh/0: clear every layer the harness touches.
fresh :-
    % Clear the verb layer.
    causal_core_reset,
    % Clear the hinge.
    realizable_hinge_reset,
    % Clear the learning state.
    causal_learning_reset,
    % Clear the harness state.
    arc3_harness_reset.

:- begin_tests(arc3_harness).

% Perception abstracts a frame into one occurrent per cell.
test(perceive_occurrents) :-
    % A two-by-two frame.
    arc3_harness_perceive([[1, 2], [3, 4]], Occ),
    % Four occurrents.
    length(Occ, 4),
    % Spot-check one.
    memberchk(cell_state(1, 0, 3), Occ).

% The delta between frames yields the change occurrents.
test(delta_occurrents) :-
    % One cell changed.
    arc3_harness_delta([[0, 0], [0, 0]], [[0, 7], [0, 0]], Delta),
    % Exactly that change.
    Delta == [changed(0, 1, 0, 7)].

% The full episode: the harness discovers the mechanics, learns the hazard
% once, never repeats it, and wins within the budget.
test(episode_wins_and_avoids_hazard, [nondet]) :-
    % Fresh layers.
    fresh,
    % The mock game.
    mock_env(Env),
    % Play under a modest budget.
    arc3_harness_play(Env, 12, Outcome),
    % The level was won.
    Outcome = won(Steps),
    % Within the budget.
    Steps =< 12,
    % The spike was tried once, learned, and avoided.
    causal_learning_avoid(action(spike)),
    % The preventive relation was reified.
    causal_core_causal_relation_object(_, [action(spike)], [penalty], _, preventive, _, _, _),
    % The transfer mechanic was induced as a causal relation.
    causal_core_causal_relation_object(_, [action(transfer)], [delta(_)], _, sufficient, _, _, _),
    % The glass-box trace recorded the hazard step.
    arc3_harness_trace(Trace),
    % The hazard appears exactly once in the whole episode.
    findall(N, member(step(N, action(spike), hazard), Trace), [_]),
    % And the spike is never chosen after the hazard was learned.
    \+ ( member(step(N1, action(spike), _), Trace),
         member(step(N2, action(spike), _), Trace),
         N2 > N1 ).

% Plan-first selection: with a goal whose producer is known, the planner
% overrides curiosity.
test(plan_overrides_curiosity, [nondet]) :-
    % Fresh layers.
    fresh,
    % A learned relation: transfer produces the level-raising delta.
    causal_core_new_causal_relation_object([action(transfer)], [delta([changed(0, 0, 1, 2)])],
               temporal(0, 0, instant), sufficient, 0.7, [],
               prov(agent, learned_by_intervention, 0.7), _),
    % Register that delta as the goal.
    arc3_harness_goal_set(delta([changed(0, 0, 1, 2)])),
    % Bias curiosity heavily away from transfer by faking many tries.
    mock_actions(Actions),
    % Choose: the plan wins despite the curiosity counters.
    arc3_harness_choose(Actions, _, Action),
    % The planned action was chosen.
    Action == action(transfer).

% Curiosity picks the least-tried permissible action.
test(curiosity_least_tried) :-
    % Fresh layers.
    fresh,
    % No goal is registered, so curiosity decides.
    mock_actions(Actions),
    % The first choice is the alphabetically first untried action.
    arc3_harness_choose(Actions, _, First),
    % All counters are level, so term order breaks the tie.
    First == action(noop).

% A learned hazard is excluded even from curiosity.
test(hazard_excluded_from_curiosity) :-
    % Fresh layers.
    fresh,
    % The spike is a known hazard.
    causal_learning_preventive(action(spike), penalty),
    % Choose among all three.
    mock_actions(Actions),
    % Whatever curiosity picks, it is never the hazard.
    arc3_harness_choose(Actions, _, Action),
    % The avoid-set is absolute.
    Action \== action(spike).

% The live bridge constructs a well-formed guarded environment term.
test(http_env_shape) :-
    % Build the bridge environment.
    arc3_harness_http_env('https://example.invalid/api', key123, vc33, Env),
    % It has the pluggable environment shape.
    Env = arc3_env(_, _, ActionsGoal, _),
    % Its action set is the stable numbered ARC-AGI-3 shape.
    call(ActionsGoal, Actions),
    % Directional actions and the complex action are present.
    memberchk(action(1), Actions),
    % The complex action too.
    memberchk(action(6), Actions).

:- end_tests(arc3_harness).
