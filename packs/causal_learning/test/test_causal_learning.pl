/*  PrologAI — Causalontology Learning Test Suite  (WP-394)

    The micro-world of the specification's runnable core: three buttons
    that light lamps, and a spike that hurts.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/causal_learning/test/test_co_learn.pl
*/

% Declare this file as a test module.
:- module(test_co_learn, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module(library(causal_learning)).
% Load the verb layer the learner writes into.
:- use_module(library(causal_core)).
% Load the hinge the learner populates from the bottom up.
:- use_module(library(realizable_hinge)).

% ---------------------------------------------------------------------------
% The ground-truth micro-world, hidden from the agent.
% ---------------------------------------------------------------------------

% world_act(+Action, -Effect): the environment's answer to an intervention.
world_act(press(b_red), light(red, on)) :- !.
% The green button.
world_act(press(b_green), light(green, on)) :- !.
% The blue button.
world_act(press(b_blue), light(blue, on)) :- !.
% The spike hurts.
world_act(touch(spike), penalty) :- !.
% Everything else does nothing.
world_act(_, none).

% fresh/0: reset every layer the learner touches.
fresh :-
    % Clear the verb layer.
    causal_core_reset,
    % Clear the hinge.
    realizable_hinge_reset,
    % Clear the learning state.
    causal_learning_reset.

:- begin_tests(causal_learning).

% Induction: a first intervention creates the relation at strength 0.70.
test(induce_at_seventy) :-
    % A fresh world.
    fresh,
    % The first press.
    causal_learning_intervene(test_co_learn:world_act, press(b_red), learned(light(red, on))),
    % The relation exists at the canonical initial strength.
    causal_core_cro(_, [press(b_red)], [light(red, on)], _, sufficient, 0.7, _,
           prov(agent, learned_by_intervention, _)).

% Confirmation: a repeated intervention raises the strength by 0.2.
test(confirm_raises_strength) :-
    % A fresh world.
    fresh,
    % The first press induces.
    causal_learning_intervene(test_co_learn:world_act, press(b_red), _),
    % The second press confirms.
    causal_learning_intervene(test_co_learn:world_act, press(b_red), _),
    % The strength rose from 0.70 to 0.90.
    causal_core_cro(_, [press(b_red)], [light(red, on)], _, _, S, _, _),
    % Check the rise.
    abs(S - 0.9) < 1.0e-9.

% The bottom-up hinge: inducing press(b_red) posits a pressable disposition.
test(disposition_posited, [nondet]) :-
    % A fresh world.
    fresh,
    % The first press induces.
    causal_learning_intervene(test_co_learn:world_act, press(b_red), _),
    % The button now bears a disposition on the noun side.
    realizable_hinge_realizable(D, disposition, b_red),
    % Realized in the pressing occurrent — the seam holds.
    realizable_hinge_realized_in(D, press(b_red)).

% A hazard is tagged preventive and enters the avoid-set.
test(hazard_avoided) :-
    % A fresh world.
    fresh,
    % Touching the spike hurts.
    causal_learning_intervene(test_co_learn:world_act, touch(spike), hazard),
    % The action is on the avoid-set.
    causal_learning_avoid(touch(spike)),
    % The preventive relation was reified at hazard strength.
    causal_core_cro(Id, [touch(spike)], [penalty], _, preventive, 0.9, _, _),
    % Queryable as preventive.
    causal_core_preventive(Id),
    % A repeated hazard is not double-recorded.
    causal_learning_intervene(test_co_learn:world_act, touch(spike), hazard),
    % Still exactly one preventive relation for it.
    findall(I, causal_core_cro(I, [touch(spike)], [penalty], _, preventive, _, _, _), [_]).

% Null effects are stored compactly as counters, not as relations.
test(null_effects_compact) :-
    % A fresh world.
    fresh,
    % Waving produces nothing, twice.
    causal_learning_intervene(test_co_learn:world_act, wave(hand), none),
    % Again.
    causal_learning_intervene(test_co_learn:world_act, wave(hand), none),
    % The counter holds two.
    causal_learning_null_effects(wave(hand), 2),
    % No relation was reified for the non-effect.
    \+ causal_core_cro(_, [wave(hand)], _, _, _, _, _, _).

% Doing versus seeing: an observed relation is flagged and weighted down.
test(observation_weighted_down) :-
    % A fresh world.
    fresh,
    % A relation learned by intervention.
    causal_learning_intervene(test_co_learn:world_act, press(b_red), _),
    % A relation merely observed.
    causal_learning_observe(clouds, rain),
    % The interventional relation is marked as such.
    causal_core_cro(IdI, [press(b_red)], _, _, _, _, _, _),
    % The mark holds.
    causal_learning_interventional(IdI),
    % The observational relation is flagged and weak.
    causal_core_cro(IdO, [clouds], [rain], _, contributory, 0.3, Context, _),
    % The flag is in its context.
    memberchk(observational, Context),
    % And it is not interventional.
    \+ causal_learning_interventional(IdO).

:- end_tests(causal_learning).
