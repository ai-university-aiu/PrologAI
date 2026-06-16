/*  PrologAI — Motivational Modulation (Psi)  (Specification PR 27)

    Defines the global modulator bus that carries three dials read by every
    actor: arousal, execution_speed, and resolution (depth/breadth of
    processing).  Strong urgent needs raise arousal and speed and narrow
    resolution; calm lowers arousal and widens resolution.

    Needs span three categories:
        physiological — homeostatic body variables (energy, temperature, …)
        cognitive     — competence, certainty, exploration
        social        — affiliation signals

    Affective states are named regions in modulator space, not separate modules.

    A motive is an urge bound to a goal: appetitive (approach) or aversive
    (avoid).  Conflicting motives blend their modulation rather than switching
    abruptly.  Extreme arousal is clamped so resolution never collapses to zero.
    Modulators decay toward baseline each tick.

    Actor budgets: daydream_actor's computation budget is proportional to
    (1 - arousal), so urgent arousal spikes shrink its interval.

    Predicates:
      pai_modulator/2         — +Dial, -Value  OR  +Dial, +NewValue (set)
      pai_affect_region/2     — +Name, -Region  OR  +Name, +Region (define)
      pai_motive/3            — +Goal, +Type, -Motive
      pai_modulator_update/1  — +Needs (list of need(Cat,Urgency)) → update bus
      pai_modulator_decay/0   — tick: decay toward baseline
      pai_daydream_budget/1   — -Budget  (0-1, inversely proportional to arousal)
*/

% Declare this file as the 'motivation' module and list its exported predicates.
:- module(motivation, [
    % Supply 'pai_modulator/2' as the next argument to the expression above.
    pai_modulator/2,
    % Supply 'pai_affect_region/2' as the next argument to the expression above.
    pai_affect_region/2,
    % Supply 'pai_motive/3' as the next argument to the expression above.
    pai_motive/3,
    % Supply 'pai_modulator_update/1' as the next argument to the expression above.
    pai_modulator_update/1,
    % Supply 'pai_modulator_decay/0' as the next argument to the expression above.
    pai_modulator_decay/0,
    % Supply 'pai_daydream_budget/1' as the next argument to the expression above.
    pai_daydream_budget/1
% Close the expression opened above.
]).

% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),     [member/2]).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate), [aggregate_all/3]).

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
pai_modulator(Dial, Value) :-
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
pai_affect_region(Name, Region) :-
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
pai_motive(Goal, Type, motive(Goal, Type, Urgency)) :-
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
% pai_modulator_update/1
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
pai_modulator_update(Needs) :-
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
    pai_modulator(Dial, New).  % set mode (clamped internally)

% ---------------------------------------------------------------------------
% pai_modulator_decay/0 — decay all modulators toward baseline
% ---------------------------------------------------------------------------

% Execute: pai_modulator_decay :-.
pai_modulator_decay :-
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
          pai_modulator(Dial, New)
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_daydream_budget/1 — daydream's share of the compute cycle
%
%   Budget ∈ [0,1]; high arousal → shrinks budget.
% ---------------------------------------------------------------------------

% Define a clause for 'pai daydream budget': succeed when the following conditions hold.
pai_daydream_budget(Budget) :-
    % State a fact for 'pai modulator' with the arguments listed below.
    pai_modulator(arousal, Arousal),
    % Evaluate the arithmetic expression 'max(0.0, 1.0 - Arousal)' and bind the result to 'Budget'.
    Budget is max(0.0, 1.0 - Arousal).
