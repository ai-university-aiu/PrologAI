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

:- module(motivation, [
    pai_modulator/2,
    pai_affect_region/2,
    pai_motive/3,
    pai_modulator_update/1,
    pai_modulator_decay/0,
    pai_daydream_budget/1
]).

:- use_module(library(lists),     [member/2]).
:- use_module(library(aggregate), [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Modulator bus — three dials
% ---------------------------------------------------------------------------

:- dynamic modulator_value/2.  % Dial, Value  (arousal, speed, resolution)

modulator_baseline(arousal,          0.3).
modulator_baseline(execution_speed,  0.5).
modulator_baseline(resolution,       0.7).

modulator_clamp(arousal,         0.0, 1.0).
modulator_clamp(execution_speed, 0.1, 1.0).
modulator_clamp(resolution,      0.1, 1.0).  % never collapses to zero

modulator_decay_rate(0.05).

% Initialize bus if not yet set
ensure_modulator(Dial) :-
    ( modulator_value(Dial, _)
    ->  true
    ;   modulator_baseline(Dial, V),
        assertz(modulator_value(Dial, V))
    ).

pai_modulator(Dial, Value) :-
    ( number(Value)
    ->  % Set mode
        modulator_clamp(Dial, Lo, Hi),
        Clamped is max(Lo, min(Hi, Value)),
        retractall(modulator_value(Dial, _)),
        assertz(modulator_value(Dial, Clamped))
    ;   % Get mode
        ensure_modulator(Dial),
        modulator_value(Dial, Value)
    ).

% ---------------------------------------------------------------------------
% Affect regions — named regions in modulator space
%
%   Region = region(MinArousal, MaxArousal, MinSpeed, MaxSpeed,
%                   MinResolution, MaxResolution)
% ---------------------------------------------------------------------------

:- dynamic affect_region_def/2.   % Name, region(...)

pai_affect_region(Name, Region) :-
    ( Region = region(_, _, _, _, _, _)
    ->  % Define mode
        retractall(affect_region_def(Name, _)),
        assertz(affect_region_def(Name, Region))
    ;   % Query mode
        ( affect_region_def(Name, Region)
        ->  true
        ;   Region = undefined
        )
    ).

% Built-in affect regions (approximate Psi model)
:- assertz(affect_region_def(calm,      region(0.0, 0.35, 0.1, 0.5, 0.6, 1.0))).
:- assertz(affect_region_def(alert,     region(0.35, 0.65, 0.5, 0.8, 0.4, 0.7))).
:- assertz(affect_region_def(stressed,  region(0.65, 0.85, 0.7, 1.0, 0.1, 0.4))).
:- assertz(affect_region_def(panicked,  region(0.85, 1.0, 0.9, 1.0, 0.1, 0.2))).

% ---------------------------------------------------------------------------
% Motives
% ---------------------------------------------------------------------------

:- dynamic active_motive/3.   % Goal, Type(appetitive|aversive), Urgency

pai_motive(Goal, Type, motive(Goal, Type, Urgency)) :-
    ( active_motive(Goal, Type, Urgency)
    ->  true
    ;   Urgency = 0.0
    ).

register_motive(Goal, Type, Urgency) :-
    retractall(active_motive(Goal, Type, _)),
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

pai_modulator_update(Needs) :-
    ( Needs = []
    ->  true
    ;   length(Needs, N),
        aggregate_all(sum(U), member(need(_, U), Needs), TotalU),
        AvgU is TotalU / N,
        % Update each dial by blending
        update_dial(arousal,         AvgU,         0.6),
        update_dial(execution_speed, AvgU * 0.5,   0.6),
        update_dial(resolution,     -AvgU * 0.3,   0.6)
    ).

update_dial(Dial, Delta, Alpha) :-
    ensure_modulator(Dial),
    modulator_value(Dial, Current),
    Target is Current + Delta,
    New is Current + Alpha * (Target - Current),
    pai_modulator(Dial, New).  % set mode (clamped internally)

% ---------------------------------------------------------------------------
% pai_modulator_decay/0 — decay all modulators toward baseline
% ---------------------------------------------------------------------------

pai_modulator_decay :-
    modulator_decay_rate(Rate),
    forall(
        modulator_baseline(Dial, Base),
        ( ensure_modulator(Dial),
          modulator_value(Dial, Current),
          New is Current + Rate * (Base - Current),
          pai_modulator(Dial, New)
        )
    ).

% ---------------------------------------------------------------------------
% pai_daydream_budget/1 — daydream's share of the compute cycle
%
%   Budget ∈ [0,1]; high arousal → shrinks budget.
% ---------------------------------------------------------------------------

pai_daydream_budget(Budget) :-
    pai_modulator(arousal, Arousal),
    Budget is max(0.0, 1.0 - Arousal).
