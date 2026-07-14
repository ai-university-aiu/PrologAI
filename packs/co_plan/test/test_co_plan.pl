/*  PrologAI — Causalontology Planning Test Suite  (WP-395)

    The door of the specification's runnable core: a sequence of three
    presses opens it, and a learned hazard is never planned through.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/co_plan/test/test_co_plan.pl
*/

% Declare this file as a test module.
:- module(test_co_plan, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module(library(co_plan)).
% Load the verb layer the planner reads.
:- use_module(library(causal_core)).
% Load the learner whose avoid-set the planner respects.
:- use_module(library(co_learn)).
% Load the hinge cleared alongside.
:- use_module(library(co_hinge)).

% world_act(+Action, -Effect): the same micro-world as the learning tests.
world_act(press(b_red), light(red, on)) :- !.
% The green button.
world_act(press(b_green), light(green, on)) :- !.
% The blue button.
world_act(press(b_blue), light(blue, on)) :- !.
% The spike hurts.
world_act(touch(spike), penalty) :- !.
% Everything else does nothing.
world_act(_, none).

% fresh/0: reset every layer, then learn the three presses.
fresh :-
    % Clear the verb layer.
    co_core_reset,
    % Clear the hinge.
    co_hinge_reset,
    % Clear the learning state.
    co_learn_reset,
    % Learn the three button relations by intervention.
    co_intervene(test_co_plan:world_act, press(b_red), _),
    % The green button.
    co_intervene(test_co_plan:world_act, press(b_green), _),
    % The blue button.
    co_intervene(test_co_plan:world_act, press(b_blue), _).

% executor(+Step, -Result): a toy executor that performs a press.
executor(press(B), pressed(B)).

:- begin_tests(co_plan).

% A composed procedure plans backward from its goal.
test(procedure_plans, [nondet]) :-
    % Learn the world.
    fresh,
    % Compose the unlock procedure.
    co_compose_procedure([press(b_red), press(b_green), press(b_blue)],
                         door(open), Id),
    % It is queryable as a procedure.
    co_procedure(Id, [press(b_red), press(b_green), press(b_blue)], door(open)),
    % Planning to the goal returns the sequence.
    co_plan(door(open), [press(b_red), press(b_green), press(b_blue)]).

% Composing the same procedure twice returns the same relation.
test(procedure_idempotent) :-
    % Learn the world.
    fresh,
    % Compose once.
    co_compose_procedure([press(b_red)], lamp(on), Id1),
    % Compose again.
    co_compose_procedure([press(b_red)], lamp(on), Id2),
    % The identifiers agree.
    Id1 == Id2.

% The planner refuses a plan through a learned hazard.
test(hazard_never_planned, [fail]) :-
    % Learn the world.
    fresh,
    % Learn the hazard.
    co_intervene(test_co_plan:world_act, touch(spike), hazard),
    % Compose a procedure that would pass through the spike.
    co_compose_procedure([press(b_red), touch(spike)], door(open), _),
    % No safe plan exists.
    co_plan(door(open), _).

% A plan is refused when a step is not achievable at all.
test(unachievable_refused, [fail]) :-
    % Learn the world.
    fresh,
    % A procedure with a step the agent knows nothing about.
    co_compose_procedure([press(b_red), utter(spell)], door(open), _),
    % No plan: the spell is not achievable.
    co_plan(door(open), _).

% Backward chaining assembles a plan the agent was never given.
test(chain_assembles_plan, [nondet]) :-
    % A fresh verb layer without procedures.
    co_core_reset,
    % Clear the learning state.
    co_learn_reset,
    % A two-link causal chain: flip causes power; power causes light.
    causal_core_new_cro([flip(switch)], [power(on)], temporal(0, 0, instant),
               sufficient, 0.9, [], prov(agent, learned_by_intervention, 0.9), _),
    % The second link.
    causal_core_new_cro([power(on)], [light(on)], temporal(0, 0, instant),
               sufficient, 0.9, [], prov(kb, asserted, 0.9), _),
    % Chain backward from the light to the flip.
    co_plan_chain(light(on), 5, Plan),
    % The assembled plan starts with the performable action.
    Plan == [flip(switch), power(on)].

% Execution runs each step through the caller's executor.
test(execute_runs_steps) :-
    % Run a two-step plan through the toy executor.
    co_execute(test_co_plan:executor, [press(b_red), press(b_green)], Result),
    % The last step's outcome is the result.
    Result == pressed(b_green).

% A failing step stops the plan honestly.
test(execute_fails_honestly) :-
    % The executor knows only presses.
    co_execute(test_co_plan:executor, [press(b_red), utter(spell)], Result),
    % The failure names the step.
    Result == failed_at(utter(spell)).

:- end_tests(co_plan).
