/*  PrologAI — Causalontology Motivation  (WP-411, Layer 386)

    THE_BUILDING_FILES make one point the root of all behaviour: a mind acts
    because something inside it is out of balance. A "need" is a quantity the
    system wants to hold at a target set-point (charge, signal, a task counter).
    The gap between the target and the current reading is felt as a PRESSURE, and
    a pressure is what turns into a goal. The co_ family could already infer an
    environment's goal (co_goalinfer), but it had no goals of its own; this pack
    gives it that inner reason to act.

    A NEED is:

        need(Name, Target, Actual)

    The pressure of a need is the size of its gap, abs(Target - Actual). The
    AGENDA is the needs whose pressure exceeds a small threshold, ranked most
    pressing first, each turned into a goal to restore it. Crucially the agenda
    is never empty: when every need is satisfied the mind still has a goal — to
    explore — so an idle mind investigates rather than stalls.

    Predicates:
      im_reset/0            -- forget all needs, restore the default threshold
      im_set_threshold/1    -- +Epsilon        (pressure at or below this = satisfied)
      im_threshold/1        -- ?Epsilon
      im_need_add/3         -- +Name, +Target, +Actual
      im_set_actual/2       -- +Name, +Actual  (update a need's current reading)
      im_need/3             -- ?Name, ?Target, ?Actual
      im_pressure/2         -- +Name, -Pressure
      im_satisfied/1        -- +Name            (pressure at or below threshold)
      im_goal_of/2          -- +Name, -Goal     (the goal that would restore it)
      im_agenda/1           -- -Goals           (Pressure-Goal, most pressing first)
      im_top_goal/1         -- -Goal            (single most pressing; explore if none)
      im_count/1            -- -N               (how many needs registered)
*/

% Declare this module and its exported predicates.
:- module(co_impetus, [
    % im_reset/0: forget all needs and restore the default threshold.
    im_reset/0,
    % im_set_threshold/1: set the satisfied-pressure threshold.
    im_set_threshold/1,
    % im_threshold/1: read the satisfied-pressure threshold.
    im_threshold/1,
    % im_need_add/3: register a homeostatic need.
    im_need_add/3,
    % im_set_actual/2: update a need's current reading.
    im_set_actual/2,
    % im_need/3: query registered needs.
    im_need/3,
    % im_pressure/2: the gap size of a need.
    im_pressure/2,
    % im_satisfied/1: whether a need's pressure is at or below threshold.
    im_satisfied/1,
    % im_goal_of/2: the goal that would restore a need.
    im_goal_of/2,
    % im_agenda/1: the prioritized, never-empty goal agenda.
    im_agenda/1,
    % im_top_goal/1: the single most pressing goal.
    im_top_goal/1,
    % im_count/1: how many needs are registered.
    im_count/1
]).

% Use the list library.
:- use_module(library(lists)).

% need/3 stores one homeostatic variable; it changes at runtime, so it is dynamic.
:- dynamic need/3.
% epsilon/1 stores the satisfied threshold; dynamic so the caller may tune it.
:- dynamic epsilon/1.

% im_reset/0: forget every need and restore the default threshold.
im_reset :-
    % Remove all needs.
    retractall(need(_,_,_)),
    % Remove any existing threshold.
    retractall(epsilon(_)),
    % A tiny default: a gap this small or smaller counts as satisfied.
    assertz(epsilon(0.001)).

% im_set_threshold/1: replace the satisfied-pressure threshold.
im_set_threshold(E) :-
    % Drop the old threshold.
    retractall(epsilon(_)),
    % Store the new one.
    assertz(epsilon(E)).

% im_threshold/1: read the threshold, defaulting if unset.
im_threshold(E) :-
    % Read it, or fall back to the default.
    ( epsilon(E0) -> E = E0 ; E = 0.001 ).

% im_need_add/3: register a homeostatic need with its target and current reading.
im_need_add(Name, Target, Actual) :-
    % Re-registering a name replaces the earlier need.
    retractall(need(Name, _, _)),
    % Store the need.
    assertz(need(Name, Target, Actual)).

% im_set_actual/2: update just the current reading of an existing need.
im_set_actual(Name, Actual) :-
    % Retract the old reading, keeping the target.
    retract(need(Name, Target, _)),
    % Re-assert with the new reading.
    assertz(need(Name, Target, Actual)).

% im_need/3: expose the registered needs.
im_need(Name, Target, Actual) :-
    % Read the stored need.
    need(Name, Target, Actual).

% im_pressure/2: the size of a need's gap from its set-point.
im_pressure(Name, Pressure) :-
    % Fetch the need.
    need(Name, Target, Actual),
    % Pressure is the magnitude of the gap.
    Pressure is abs(Target - Actual).

% im_satisfied/1: a need is satisfied when its pressure is at or below threshold.
im_satisfied(Name) :-
    % Read the current threshold.
    im_threshold(E),
    % Compute the pressure.
    im_pressure(Name, P),
    % Satisfied means the gap is within the threshold.
    P =< E.

% im_goal_of/2: the goal that would restore a need is to close its gap.
im_goal_of(Name, restore(Name)) :-
    % A need is a valid subject only if it exists.
    need(Name, _, _).

% im_agenda/1: the pressing needs as Pressure-Goal pairs, most pressing first.
im_agenda(Goals) :-
    % Read the threshold once.
    im_threshold(E),
    % Collect every need whose pressure exceeds the threshold, as a goal.
    findall(P-restore(Name),
            ( need(Name, _, _),
              im_pressure(Name, P),
              P > E ),
            Raw),
    % Sort by pressure descending, keeping ties.
    sort(1, @>=, Raw, Sorted),
    % Guarantee a non-empty agenda: if nothing presses, the goal is to explore.
    ( Sorted == [] -> Goals = [0.0-explore] ; Goals = Sorted ).

% im_top_goal/1: the single most pressing goal (explore when nothing presses).
im_top_goal(Goal) :-
    % Take the head of the ranked agenda.
    im_agenda([_-Goal|_]).

% im_count/1: how many needs are registered.
im_count(N) :-
    % Count the need facts.
    aggregate_all(count, need(_,_,_), N).
