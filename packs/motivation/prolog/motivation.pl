/*  PrologAI — Motivation  (WP-411, Layer 386; converged with Motivational Modulation Psi, PR 27)

    One motivation faculty in two complementary halves, unioned by the
    unification program (absorb-and-supersede: the Causalontology motivation
    pack absorbed the older Psi modulator pack; neither sub-faculty is lost).

    HALF ONE — DRIVE AGENDA (from the Causalontology motivation pack).
    A mind acts because something inside it is out of balance. A NEED is a
    quantity the system wants to hold at a target set-point; the gap between
    target and current reading is felt as PRESSURE, and a pressure turns into a
    goal. The AGENDA is the pressing needs ranked most-pressing-first, and it is
    never empty: an idle mind explores rather than stalls.

        need(Name, Target, Actual)   pressure = abs(Target - Actual)

    HALF TWO — MODULATOR BUS (from the Psi motivation pack).
    A global bus carries three dials every actor reads: arousal,
    execution_speed, and resolution (depth/breadth of processing). Strong
    urgent needs raise arousal and speed and narrow resolution; calm widens it.
    Affective states are named REGIONS in modulator space, not separate modules.
    A MOTIVE is an urge bound to a goal, appetitive (approach) or aversive
    (avoid); conflicting motives blend rather than switch. Modulators decay
    toward baseline each tick; a daydream actor's budget is proportional to
    (1 - arousal).

    Predicates:
      motivation_reset/0             -- forget all needs, restore the default threshold
      motivation_set_threshold/1     -- +Epsilon    (pressure at or below this = satisfied)
      motivation_threshold/1         -- ?Epsilon
      motivation_need_add/3          -- +Name, +Target, +Actual
      motivation_set_actual/2        -- +Name, +Actual  (update a need's current reading)
      motivation_need/3              -- ?Name, ?Target, ?Actual
      motivation_pressure/2          -- +Name, -Pressure
      motivation_satisfied/1         -- +Name        (pressure at or below threshold)
      motivation_goal_of/2           -- +Name, -Goal (the goal that would restore it)
      motivation_agenda/1            -- -Goals       (Pressure-Goal, most pressing first)
      motivation_top_goal/1          -- -Goal        (single most pressing; explore if none)
      motivation_count/1             -- -N           (how many needs registered)
      motivation_modulator/2         -- +Dial, -Value  OR  +Dial, +NewValue (set)
      motivation_affect_region/2     -- +Name, -Region  OR  +Name, +Region (define)
      motivation_motive/3            -- +Goal, +Type, -Motive
      motivation_modulator_update/1  -- +Needs (list of need(Cat,Urgency)) -> update bus
      motivation_modulator_decay/0   -- tick: decay toward baseline
      motivation_daydream_budget/1   -- -Budget  (0-1, inversely proportional to arousal)
*/

% Declare this module and its exported predicates (the union of both faculties).
:- module(motivation, [
    % motivation_reset/0: forget all needs and restore the default threshold.
    motivation_reset/0,
    % motivation_set_threshold/1: set the satisfied-pressure threshold.
    motivation_set_threshold/1,
    % motivation_threshold/1: read the satisfied-pressure threshold.
    motivation_threshold/1,
    % motivation_need_add/3: register a homeostatic need.
    motivation_need_add/3,
    % motivation_set_actual/2: update a need's current reading.
    motivation_set_actual/2,
    % motivation_need/3: query registered needs.
    motivation_need/3,
    % motivation_pressure/2: the gap size of a need.
    motivation_pressure/2,
    % motivation_satisfied/1: whether a need's pressure is at or below threshold.
    motivation_satisfied/1,
    % motivation_goal_of/2: the goal that would restore a need.
    motivation_goal_of/2,
    % motivation_agenda/1: the prioritized, never-empty goal agenda.
    motivation_agenda/1,
    % motivation_top_goal/1: the single most pressing goal.
    motivation_top_goal/1,
    % motivation_count/1: how many needs are registered.
    motivation_count/1,
    % motivation_modulator/2: read or set a modulator dial.
    motivation_modulator/2,
    % motivation_affect_region/2: define or query a named affect region.
    motivation_affect_region/2,
    % motivation_motive/3: the motive bound to a goal.
    motivation_motive/3,
    % motivation_modulator_update/1: blend a list of needs into the dials.
    motivation_modulator_update/1,
    % motivation_modulator_decay/0: decay every dial toward baseline.
    motivation_modulator_decay/0,
    % motivation_daydream_budget/1: the daydream actor's share of the cycle.
    motivation_daydream_budget/1
]).

% Import member/2 for list walking.
:- use_module(library(lists), [member/2]).
% Import aggregate_all/3 for counting and summing.
:- use_module(library(aggregate), [aggregate_all/3]).

% need/3 stores one homeostatic variable; it changes at runtime, so it is dynamic.
:- dynamic need/3.
% epsilon/1 stores the satisfied threshold; dynamic so the caller may tune it.
:- dynamic epsilon/1.

% motivation_reset/0: forget every need and restore the default threshold.
motivation_reset :-
    % Remove all needs.
    retractall(need(_,_,_)),
    % Remove any existing threshold.
    retractall(epsilon(_)),
    % A tiny default: a gap this small or smaller counts as satisfied.
    assertz(epsilon(0.001)).

% motivation_set_threshold/1: replace the satisfied-pressure threshold.
motivation_set_threshold(E) :-
    % Drop the old threshold.
    retractall(epsilon(_)),
    % Store the new one.
    assertz(epsilon(E)).

% motivation_threshold/1: read the threshold, defaulting if unset.
motivation_threshold(E) :-
    % Read it, or fall back to the default.
    ( epsilon(E0) -> E = E0 ; E = 0.001 ).

% motivation_need_add/3: register a homeostatic need with its target and current reading.
motivation_need_add(Name, Target, Actual) :-
    % Re-registering a name replaces the earlier need.
    retractall(need(Name, _, _)),
    % Store the need.
    assertz(need(Name, Target, Actual)).

% motivation_set_actual/2: update just the current reading of an existing need.
motivation_set_actual(Name, Actual) :-
    % Retract the old reading, keeping the target.
    retract(need(Name, Target, _)),
    % Re-assert with the new reading.
    assertz(need(Name, Target, Actual)).

% motivation_need/3: expose the registered needs.
motivation_need(Name, Target, Actual) :-
    % Read the stored need.
    need(Name, Target, Actual).

% motivation_pressure/2: the size of a need's gap from its set-point.
motivation_pressure(Name, Pressure) :-
    % Fetch the need.
    need(Name, Target, Actual),
    % Pressure is the magnitude of the gap.
    Pressure is abs(Target - Actual).

% motivation_satisfied/1: a need is satisfied when its pressure is at or below threshold.
motivation_satisfied(Name) :-
    % Read the current threshold.
    motivation_threshold(E),
    % Compute the pressure.
    motivation_pressure(Name, P),
    % Satisfied means the gap is within the threshold.
    P =< E.

% motivation_goal_of/2: the goal that would restore a need is to close its gap.
motivation_goal_of(Name, restore(Name)) :-
    % A need is a valid subject only if it exists.
    need(Name, _, _).

% motivation_agenda/1: the pressing needs as Pressure-Goal pairs, most pressing first.
motivation_agenda(Goals) :-
    % Read the threshold once.
    motivation_threshold(E),
    % Collect every need whose pressure exceeds the threshold, as a goal.
    findall(P-restore(Name),
            ( need(Name, _, _),
              motivation_pressure(Name, P),
              P > E ),
            Raw),
    % Sort by pressure descending, keeping ties.
    sort(1, @>=, Raw, Sorted),
    % Guarantee a non-empty agenda: if nothing presses, the goal is to explore.
    ( Sorted == [] -> Goals = [0.0-explore] ; Goals = Sorted ).

% motivation_top_goal/1: the single most pressing goal (explore when nothing presses).
motivation_top_goal(Goal) :-
    % Take the head of the ranked agenda.
    motivation_agenda([_-Goal|_]).

% motivation_count/1: how many needs are registered.
motivation_count(N) :-
    % Count the need facts.
    aggregate_all(count, need(_,_,_), N).

% ---------------------------------------------------------------------------
% Modulator bus — three dials
% ---------------------------------------------------------------------------

% Declare 'modulator_value/2.  % Dial, Value  (arousal, speed, resolution)' as dynamic — its facts may be added or removed at runtime.
:- dynamic modulator_value/2.  % Dial, Value  (arousal, speed, resolution)

% State the fact: modulator baseline(arousal,          0.3).
modulator_baseline(arousal,          0.3).
% State the fact: modulator baseline(execution_speed,  0.5).
modulator_baseline(execution_speed,  0.5).
% State the fact: modulator baseline(resolution,       0.7).
modulator_baseline(resolution,       0.7).

% State the fact: modulator clamp(arousal,         0.0, 1.0).
modulator_clamp(arousal,         0.0, 1.0).
% State the fact: modulator clamp(execution_speed, 0.1, 1.0).
modulator_clamp(execution_speed, 0.1, 1.0).
% State a fact for 'modulator clamp' with the arguments listed below.
modulator_clamp(resolution,      0.1, 1.0).  % never collapses to zero

% State the fact: modulator decay rate(0.05).
modulator_decay_rate(0.05).

% Initialize bus if not yet set
% Define a clause for 'ensure modulator': succeed when the following conditions hold.
ensure_modulator(Dial) :-
    % Execute: ( modulator_value(Dial, _).
    ( modulator_value(Dial, _)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   modulator_baseline(Dial, V),
        % Continue the multi-line expression started above.
        assertz(modulator_value(Dial, V))
    % Close the expression opened above.
    ).

% Define a clause for 'pai modulator': succeed when the following conditions hold.
motivation_modulator(Dial, Value) :-
    % Execute: ( number(Value).
    ( number(Value)
    % If the condition above succeeded, perform the following action.
    ->  % Set mode
        % Continue the multi-line expression started above.
        modulator_clamp(Dial, Lo, Hi),
        % Continue the multi-line expression started above.
        Clamped is max(Lo, min(Hi, Value)),
        % Continue the multi-line expression started above.
        retractall(modulator_value(Dial, _)),
        % Continue the multi-line expression started above.
        assertz(modulator_value(Dial, Clamped))
    % Otherwise (else branch), perform the following action.
    ;   % Get mode
        % Continue the multi-line expression started above.
        ensure_modulator(Dial),
        % Continue the multi-line expression started above.
        modulator_value(Dial, Value)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Affect regions — named regions in modulator space
%
%   Region = region(MinArousal, MaxArousal, MinSpeed, MaxSpeed,
%                   MinResolution, MaxResolution)
% ---------------------------------------------------------------------------

% Declare 'affect_region_def/2.   % Name, region(...)' as dynamic — its facts may be added or removed at runtime.
:- dynamic affect_region_def/2.   % Name, region(...)

% Define a clause for 'pai affect region': succeed when the following conditions hold.
motivation_affect_region(Name, Region) :-
    % Check that '( Region' is unifiable with 'region(_, _, _, _, _, _)'.
    ( Region = region(_, _, _, _, _, _)
    % If the condition above succeeded, perform the following action.
    ->  % Define mode
        % Continue the multi-line expression started above.
        retractall(affect_region_def(Name, _)),
        % Continue the multi-line expression started above.
        assertz(affect_region_def(Name, Region))
    % Otherwise (else branch), perform the following action.
    ;   % Query mode
        % Continue the multi-line expression started above.
        ( affect_region_def(Name, Region)
        % If the condition above succeeded, perform the following action.
        ->  true
        % Otherwise (else branch), perform the following action.
        ;   Region = undefined
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% Built-in affect regions (approximate Psi model)
% Execute the compile-time directive: assertz(affect_region_def(calm,      region(0.0, 0.35, 0.1, 0.5, 0.6, 1.0))).
:- assertz(affect_region_def(calm,      region(0.0, 0.35, 0.1, 0.5, 0.6, 1.0))).
% Execute the compile-time directive: assertz(affect_region_def(alert,     region(0.35, 0.65, 0.5, 0.8, 0.4, 0.7))).
:- assertz(affect_region_def(alert,     region(0.35, 0.65, 0.5, 0.8, 0.4, 0.7))).
% Execute the compile-time directive: assertz(affect_region_def(stressed,  region(0.65, 0.85, 0.7, 1.0, 0.1, 0.4))).
:- assertz(affect_region_def(stressed,  region(0.65, 0.85, 0.7, 1.0, 0.1, 0.4))).
% Execute the compile-time directive: assertz(affect_region_def(panicked,  region(0.85, 1.0, 0.9, 1.0, 0.1, 0.2))).
:- assertz(affect_region_def(panicked,  region(0.85, 1.0, 0.9, 1.0, 0.1, 0.2))).

% ---------------------------------------------------------------------------
% Motives
% ---------------------------------------------------------------------------

% Declare 'active_motive/3.   % Goal, Type(appetitive|aversive), Urgency' as dynamic — its facts may be added or removed at runtime.
:- dynamic active_motive/3.   % Goal, Type(appetitive|aversive), Urgency

% Define a clause for 'pai motive': succeed when the following conditions hold.
motivation_motive(Goal, Type, motive(Goal, Type, Urgency)) :-
    % Execute: ( active_motive(Goal, Type, Urgency).
    ( active_motive(Goal, Type, Urgency)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   Urgency = 0.0
    % Close the expression opened above.
    ).

% Define a clause for 'register motive': succeed when the following conditions hold.
register_motive(Goal, Type, Urgency) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(active_motive(Goal, Type, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(active_motive(Goal, Type, Urgency)).

% ---------------------------------------------------------------------------
% motivation_modulator_update/1
%
%   Needs = list of need(Category, Urgency) where Category in
%   {physiological, cognitive, social} and Urgency in [0,1].
%
%   Blending rule (additive, clamped):
%     arousal         += Urgency (weighted average over all needs)
%     execution_speed += 0.5 * Urgency
%     resolution      -= 0.3 * Urgency
%
%   Daydream_actor budget = 1 - arousal.
% ---------------------------------------------------------------------------

% Define a clause for 'pai modulator update': succeed when the following conditions hold.
motivation_modulator_update(Needs) :-
    % Check that '( Needs' is unifiable with '[]'.
    ( Needs = []
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   length(Needs, N),
        % Continue the multi-line expression started above.
        aggregate_all(sum(U), member(need(_, U), Needs), TotalU),
        % Continue the multi-line expression started above.
        AvgU is TotalU / N,
        % Update each dial by blending
        % Continue the multi-line expression started above.
        update_dial(arousal,         AvgU,         0.6),
        % Continue the multi-line expression started above.
        update_dial(execution_speed, AvgU * 0.5,   0.6),
        % Continue the multi-line expression started above.
        update_dial(resolution,     -AvgU * 0.3,   0.6)
    % Close the expression opened above.
    ).

% Define a clause for 'update dial': succeed when the following conditions hold.
update_dial(Dial, Delta, Alpha) :-
    % State a fact for 'ensure modulator' with the arguments listed below.
    ensure_modulator(Dial),
    % State a fact for 'modulator value' with the arguments listed below.
    modulator_value(Dial, Current),
    % Evaluate the arithmetic expression 'Current + Delta' and bind the result to 'Target'.
    Target is Current + Delta,
    % Evaluate the arithmetic expression 'Current + Alpha * (Target - Current)' and bind the result to 'New'.
    New is Current + Alpha * (Target - Current),
    % State a fact for 'pai modulator' with the arguments listed below.
    motivation_modulator(Dial, New).  % set mode (clamped internally)

% ---------------------------------------------------------------------------
% motivation_modulator_decay/0 — decay all modulators toward baseline
% ---------------------------------------------------------------------------

% Execute: motivation_modulator_decay :-.
motivation_modulator_decay :-
    % State a fact for 'modulator decay rate' with the arguments listed below.
    modulator_decay_rate(Rate),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        modulator_baseline(Dial, Base),
        % Continue the multi-line expression started above.
        ( ensure_modulator(Dial),
          % Continue the multi-line expression started above.
          modulator_value(Dial, Current),
          % Continue the multi-line expression started above.
          New is Current + Rate * (Base - Current),
          % Continue the multi-line expression started above.
          motivation_modulator(Dial, New)
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% motivation_daydream_budget/1 — daydream's share of the compute cycle
%
%   Budget ∈ [0,1]; high arousal → shrinks budget.
% ---------------------------------------------------------------------------

% Define a clause for 'pai daydream budget': succeed when the following conditions hold.
motivation_daydream_budget(Budget) :-
    % State a fact for 'pai modulator' with the arguments listed below.
    motivation_modulator(arousal, Arousal),
    % Evaluate the arithmetic expression 'max(0.0, 1.0 - Arousal)' and bind the result to 'Budget'.
    Budget is max(0.0, 1.0 - Arousal).
