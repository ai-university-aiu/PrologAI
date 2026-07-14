/*  PrologAI — Causalontology Repair  (WP-415, Layer 390)

    In the Piagetian lineage of THE_BUILDING_FILES the central developmental
    mechanism is equilibration: when an action disturbs the world, the mind
    restores balance rather than freezing. It has three moves, tried in order of
    preference:

      inversion       do the opposite action to undo the effect outright
      neutralization  do some other action that cancels the side effect
      re-routing      abandon the blocked goal and head for an alternate one

    The co_ family could plan toward a goal (co_plan) and refuse a hazard
    (co_core, co_verify, safety_governor), but nothing knew how to recover once a wrong
    thing had already happened. This pack is that recovery, as glass-box rules.

    A DISTURBANCE is one of:

      disturbance(Action, Effect)  an action produced an unwanted Effect
      blocked(Goal)                a goal became unreachable

    The caller teaches the pack what undoes what:

      inverse(Action, InverseAction)   InverseAction reverses Action
      neutralizer(Effect, Action)      Action cancels Effect
      reroute(Goal, AlternateGoal)     AlternateGoal replaces a blocked Goal

    and asks for a compensation plan and the grade of repair it represents.

    Predicates:
      repair_reset/0            -- forget all repair knowledge
      repair_inverse_add/2      -- +Action, +InverseAction
      repair_neutralizer_add/2  -- +Effect, +Action
      repair_reroute_add/2      -- +Goal, +AlternateGoal
      repair_inverse/2          -- ?Action, ?InverseAction
      repair_neutralizer/2      -- ?Effect, ?Action
      repair_reroute/2          -- ?Goal, ?AlternateGoal
      repair_classify/2         -- +Disturbance, -Kind   (reversible|side_effect|blocked|unknown)
      repair_compensate/3       -- +Disturbance, -Plan, -Grade
      repair_can_compensate/1   -- +Disturbance          (a real repair exists?)
*/

% Declare this module and its exported predicates.
:- module(repair, [
    % repair_reset/0: forget all repair knowledge.
    repair_reset/0,
    % repair_inverse_add/2: teach that one action reverses another.
    repair_inverse_add/2,
    % repair_neutralizer_add/2: teach that an action cancels an effect.
    repair_neutralizer_add/2,
    % repair_reroute_add/2: teach an alternate goal for a blocked one.
    repair_reroute_add/2,
    % repair_inverse/2: query inverse actions.
    repair_inverse/2,
    % repair_neutralizer/2: query neutralizing actions.
    repair_neutralizer/2,
    % repair_reroute/2: query alternate goals.
    repair_reroute/2,
    % repair_classify/2: name the kind of a disturbance.
    repair_classify/2,
    % repair_compensate/3: the best available repair plan and its grade.
    repair_compensate/3,
    % repair_can_compensate/1: whether a real repair exists.
    repair_can_compensate/1
]).

% inverse/2 relates an action to the action that reverses it; dynamic.
:- dynamic inverse/2.
% neutralizer/2 relates an effect to an action that cancels it; dynamic.
:- dynamic neutralizer/2.
% reroute/2 relates a blocked goal to an alternate goal; dynamic.
:- dynamic reroute/2.

% repair_reset/0: forget every taught repair relation.
repair_reset :-
    % Remove all inverse relations.
    retractall(inverse(_,_)),
    % Remove all neutralizers.
    retractall(neutralizer(_,_)),
    % Remove all reroutes.
    retractall(reroute(_,_)).

% repair_inverse_add/2: teach that InverseAction reverses Action.
repair_inverse_add(Action, InverseAction) :-
    % Store the relation unless it is already known.
    ( inverse(Action, InverseAction) -> true ; assertz(inverse(Action, InverseAction)) ).

% repair_neutralizer_add/2: teach that Action cancels Effect.
repair_neutralizer_add(Effect, Action) :-
    % Store the relation unless it is already known.
    ( neutralizer(Effect, Action) -> true ; assertz(neutralizer(Effect, Action)) ).

% repair_reroute_add/2: teach that AlternateGoal can replace a blocked Goal.
repair_reroute_add(Goal, AlternateGoal) :-
    % Store the relation unless it is already known.
    ( reroute(Goal, AlternateGoal) -> true ; assertz(reroute(Goal, AlternateGoal)) ).

% repair_inverse/2: expose the inverse relations.
repair_inverse(Action, InverseAction) :-
    % Read the stored inverse.
    inverse(Action, InverseAction).

% repair_neutralizer/2: expose the neutralizer relations.
repair_neutralizer(Effect, Action) :-
    % Read the stored neutralizer.
    neutralizer(Effect, Action).

% repair_reroute/2: expose the reroute relations.
repair_reroute(Goal, AlternateGoal) :-
    % Read the stored reroute.
    reroute(Goal, AlternateGoal).

% repair_classify/2: name the kind of a disturbance by the repair it can accept.
% A disturbance with an inverse for its action is reversible.
repair_classify(disturbance(Action, _), reversible) :-
    inverse(Action, _), !.
% Otherwise a disturbance whose effect has a neutralizer is a side_effect.
repair_classify(disturbance(_, Effect), side_effect) :-
    neutralizer(Effect, _), !.
% A blocked goal with an alternate is a blocked disturbance.
repair_classify(blocked(Goal), blocked) :-
    reroute(Goal, _), !.
% Anything else is unknown — no repair is known.
repair_classify(_, unknown).

% repair_compensate/3: the preferred repair plan and its grade for a disturbance.
% First preference: undo the effect with an inverse action.
repair_compensate(disturbance(Action, Effect), Plan, Grade) :-
    ( inverse(Action, Inv)
      -> Plan = undo(Inv), Grade = inversion
    % Second preference: cancel the side effect with a neutralizer.
    ; neutralizer(Effect, Act)
      -> Plan = neutralize(Act), Grade = neutralization
    % Last resort: nothing undoes it, so accept and move on.
    ; Plan = accept, Grade = none ).
% For a blocked goal, re-route to an alternate if one exists.
repair_compensate(blocked(Goal), Plan, Grade) :-
    ( reroute(Goal, Alt)
      -> Plan = reroute(Alt), Grade = reroute
    % Otherwise accept that the goal cannot be reached.
    ; Plan = accept, Grade = none ).

% repair_can_compensate/1: a real repair exists when the grade is not none.
repair_can_compensate(Disturbance) :-
    % Compute the best plan and check its grade.
    repair_compensate(Disturbance, _, Grade),
    Grade \== none.
