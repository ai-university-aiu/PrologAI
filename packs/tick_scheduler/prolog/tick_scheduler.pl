% tick_scheduler — a Lattice-backed deferred-reactivation construct on ORDINAL ticks.
% Work Package WP-432, Layer 0 (base infrastructure, atop the lattice store).
% Closes the Requirements Ledger's HIPPO-2 (consolidation-over-time had no scheduler)
% and the enactment half of CEREBELLUM-1 (no way to ENACT timing; a tick had been
% forced into a "seconds" distortion). Time here is measured in ordinal ticks — a
% dimensionless integer count, the Causalontology 3.0.0 ordinal unit — never seconds.
%
% The construct holds, in a Lattice nexus (the shared glass-box store), a monotone
% logical clock and a set of scheduled reactivations. As the clock advances, every
% reactivation whose due tick has arrived becomes DUE, fires in due-tick order, is
% removed from the schedule, and (in the enact form) is handed to a caller goal to
% ENACT. Nothing is measured in wall-clock seconds: a wall-clock unit is refused.

% Declare the module and its public interface.
:- module(tick_scheduler,
    [ % Initialise an open nexus: clock to zero, schedule cleared.
      tick_scheduler_init/1,          % +Nexus
      % Open a nexus by address AND initialise it in one step.
      tick_scheduler_open/2,          % +Address, -Nexus
      % Read the current ordinal tick (the logical now).
      tick_scheduler_now/2,           % +Nexus, -Tick
      % Schedule a reactivation at an ABSOLUTE future ordinal tick.
      tick_scheduler_schedule_at/4,   % +Nexus, +DueTick, +Label, +Payload
      % Schedule a reactivation a number of ticks AFTER now.
      tick_scheduler_schedule_after/4,% +Nexus, +Delay, +Label, +Payload
      % Schedule after a delay whose UNIT must be ordinal (a wall-clock unit is refused).
      tick_scheduler_schedule_after_unit/5, % +Nexus, +Delay, +Unit, +Label, +Payload
      % List the still-pending reactivations, ordered by due tick.
      tick_scheduler_pending/2,       % +Nexus, -Reactivations
      % Advance the clock by one tick, returning what fired.
      tick_scheduler_tick/2,          % +Nexus, -Fired
      % Advance the clock by a delta, returning (and removing) what became due.
      tick_scheduler_advance/3,       % +Nexus, +Delta, -Fired
      % Advance the clock and ENACT each fired reactivation with a caller goal.
      tick_scheduler_advance_enact/4  % +Nexus, +Delta, :Goal, -Fired
    ]).

% Use the Lattice store — the shared glass-box memory this scheduler lives in.
:- use_module(library(lattice)).
% Use the Causalontology vocabulary core — its canonical ordinal/wall-clock rule.
:- use_module(library(causal_core)).
% Use the standard list library for sorting the due reactivations.
:- use_module(library(lists)).

% Declare the enact form as a meta-predicate: its third argument is a caller goal
% called with one extra argument (the reactivation term), so the caller's module is carried.
:- meta_predicate tick_scheduler_advance_enact(+, +, 1, -).

% -- The relation name under which the logical clock is stored in the nexus.
% A single-token relation: exactly one clock fact per nexus (kept by lattice_replace).
tick_scheduler_clock_relation(tick_scheduler_clock).

% -- The relation name under which each pending reactivation is stored.
% Many facts per nexus: one per scheduled reactivation.
tick_scheduler_pending_relation(tick_scheduler_reactivation).

% -- tick_scheduler_init(+Nexus): set an open nexus's clock to zero and clear its schedule.
tick_scheduler_init(Nexus) :-
    % Name the clock relation for this nexus.
    tick_scheduler_clock_relation(Clock),
    % Set the logical clock to zero, keeping exactly one clock token.
    lattice_replace(Nexus, Clock, [0], []),
    % Remove any reactivations left from a prior use of this nexus.
    tick_scheduler_clear_pending(Nexus).

% -- tick_scheduler_clear_pending(+Nexus): take every pending reactivation, leaving none.
tick_scheduler_clear_pending(Nexus) :-
    % Name the pending relation for this nexus.
    tick_scheduler_pending_relation(Pending),
    % Snapshot every stored reactivation (arguments and referents) before removing any.
    findall(Args-Refs, lattice_get(Nexus, Pending, Args, Refs), Facts),
    % Remove each snapshotted reactivation by its exact arguments.
    forall(member(Args-Refs, Facts),
           lattice_take(Nexus, Pending, Args, Refs)).

% -- tick_scheduler_open(+Address, -Nexus): open a nexus by address and initialise it.
tick_scheduler_open(Address, Nexus) :-
    % Open (or reuse) the nexus at this Lattice address.
    lattice_open(Address, Nexus),
    % Initialise its clock and clear its schedule.
    tick_scheduler_init(Nexus).

% -- tick_scheduler_now(+Nexus, -Tick): read the current ordinal tick.
tick_scheduler_now(Nexus, Tick) :-
    % Name the clock relation.
    tick_scheduler_clock_relation(Clock),
    % Read the single clock token; an uninitialised nexus reads as tick zero.
    ( lattice_get(Nexus, Clock, [T], []) -> Tick = T ; Tick = 0 ).

% -- tick_scheduler_schedule_at(+Nexus, +DueTick, +Label, +Payload):
% schedule a reactivation to fire at an absolute future ordinal tick.
tick_scheduler_schedule_at(Nexus, DueTick, Label, Payload) :-
    % The due tick must be an ordinal tick count (a plain integer).
    tick_scheduler_check_tick(DueTick),
    % Read the current tick so we can insist the reactivation is genuinely in the future.
    tick_scheduler_now(Nexus, Now),
    % Refuse a due tick that is not strictly after now — the schedule holds only the future.
    ( DueTick > Now
    ->  true
    ;   throw(error(domain_error(future_ordinal_tick, DueTick),
                    context(tick_scheduler_schedule_at/4,
                            'a reactivation must be scheduled strictly after the current tick')))
    ),
    % Name the pending relation.
    tick_scheduler_pending_relation(Pending),
    % Store the reactivation as a Lattice fact: [due tick, label, payload].
    lattice_put(Nexus, Pending, [DueTick, Label, Payload], []).

% -- tick_scheduler_schedule_after(+Nexus, +Delay, +Label, +Payload):
% schedule a reactivation Delay ticks after now.
tick_scheduler_schedule_after(Nexus, Delay, Label, Payload) :-
    % The delay must be a positive ordinal tick count (at least one tick into the future).
    tick_scheduler_check_delay(Delay),
    % Read the current tick.
    tick_scheduler_now(Nexus, Now),
    % The absolute due tick is now plus the delay.
    DueTick is Now + Delay,
    % Delegate to the absolute-tick form.
    tick_scheduler_schedule_at(Nexus, DueTick, Label, Payload).

% -- tick_scheduler_schedule_after_unit(+Nexus, +Delay, +Unit, +Label, +Payload):
% schedule after a delay whose UNIT must be ordinal; a wall-clock unit is refused.
% This is the concrete closure of CEREBELLUM-1: timing is enacted in ordinal ticks,
% and a "seconds" (wall-clock) unit has no place on the ordinal timeline.
tick_scheduler_schedule_after_unit(Nexus, Delay, Unit, Label, Payload) :-
    % Ask the Causalontology core for this unit's dimension (ordinal or wallclock).
    causal_core_dimension(Unit, Dimension),
    % Refuse anything but an ordinal unit — no wall-clock seconds distortion is admitted.
    ( Dimension == ordinal
    ->  true
    ;   throw(error(type_error(ordinal_tick_unit, Unit),
                    context(tick_scheduler_schedule_after_unit/5,
                            'timing is enacted in ordinal ticks; a wall-clock unit has no place on the ordinal timeline')))
    ),
    % With an ordinal unit confirmed, schedule the delay as a tick count.
    tick_scheduler_schedule_after(Nexus, Delay, Label, Payload).

% -- tick_scheduler_check_tick(+Tick): a due tick must be a non-negative integer.
tick_scheduler_check_tick(Tick) :-
    % Accept only a non-negative integer; anything else is a domain error.
    ( integer(Tick), Tick >= 0
    ->  true
    ;   throw(error(domain_error(non_negative_ordinal_tick, Tick),
                    context(tick_scheduler/0, 'ordinal ticks are non-negative integers')))
    ).

% -- tick_scheduler_check_delay(+Delay): a delay must be a positive integer.
tick_scheduler_check_delay(Delay) :-
    % Accept only a strictly positive integer; a reactivation must lie in the future.
    ( integer(Delay), Delay >= 1
    ->  true
    ;   throw(error(domain_error(positive_ordinal_delay, Delay),
                    context(tick_scheduler/0, 'a deferred reactivation is at least one tick into the future')))
    ).

% -- tick_scheduler_pending(+Nexus, -Reactivations): the pending reactivations, due-tick order.
tick_scheduler_pending(Nexus, Reactivations) :-
    % Name the pending relation.
    tick_scheduler_pending_relation(Pending),
    % Collect every stored reactivation keyed by its due tick for a stable sort.
    findall(Due-reactivation(Due, Label, Payload),
            lattice_get(Nexus, Pending, [Due, Label, Payload], []),
            Keyed),
    % Sort by due tick, keeping insertion order among equal ticks (keysort is stable).
    keysort(Keyed, Sorted),
    % Drop the sort keys, leaving the ordered reactivation terms.
    pairs_values(Sorted, Reactivations).

% -- tick_scheduler_tick(+Nexus, -Fired): advance the clock by exactly one tick.
tick_scheduler_tick(Nexus, Fired) :-
    % One tick is an advance of delta one.
    tick_scheduler_advance(Nexus, 1, Fired).

% -- tick_scheduler_advance(+Nexus, +Delta, -Fired): advance the clock by Delta ticks,
% returning the reactivations that became due (in due-tick order) and removing them.
tick_scheduler_advance(Nexus, Delta, Fired) :-
    % The delta must be a non-negative ordinal tick count.
    tick_scheduler_check_tick(Delta),
    % Read the current tick.
    tick_scheduler_now(Nexus, Now),
    % The clock moves forward monotonically to the new now.
    NewNow is Now + Delta,
    % Name the pending relation.
    tick_scheduler_pending_relation(Pending),
    % Collect every reactivation whose due tick has now arrived, keyed for ordering.
    findall(Due-reactivation(Due, Label, Payload),
            ( lattice_get(Nexus, Pending, [Due, Label, Payload], []),
              Due =< NewNow ),
            DueKeyed),
    % Order the fired reactivations by due tick, stable among equal ticks.
    keysort(DueKeyed, DueSorted),
    % Keep just the reactivation terms as the fired list.
    pairs_values(DueSorted, Fired),
    % Remove each fired reactivation from the schedule (it has now been enacted).
    forall(member(reactivation(Due, Label, Payload), Fired),
           lattice_take(Nexus, Pending, [Due, Label, Payload], [])),
    % Commit the advanced clock as the single clock token.
    tick_scheduler_clock_relation(Clock),
    % Store the new now.
    lattice_replace(Nexus, Clock, [NewNow], []).

% -- tick_scheduler_advance_enact(+Nexus, +Delta, :Goal, -Fired): advance and ENACT.
% Advance the clock, then call Goal on each fired reactivation, in due-tick order.
tick_scheduler_advance_enact(Nexus, Delta, Goal, Fired) :-
    % Advance the clock and gather what fired.
    tick_scheduler_advance(Nexus, Delta, Fired),
    % Enact each fired reactivation by handing it to the caller's goal, in order.
    forall(member(Reactivation, Fired),
           call(Goal, Reactivation)).
