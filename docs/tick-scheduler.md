# The tick_scheduler — deferred reactivation on ordinal ticks (Wave 10 Stage 3, WP-432)

Closes the Requirements Ledger's **Theme A** (temporal and scheduling), sightings
**HIPPO-2** and **CEREBELLUM-1**: PrologAI can now schedule and **enact** a future
reactivation, measured in ordinal ticks — never in wall-clock seconds.

## What it is

A Lattice-backed deferred-reactivation construct. In a Lattice nexus (the shared
glass-box store) it holds two things:

- a **monotone logical clock** — the current ordinal tick (a dimensionless integer
  count, the Causalontology 3.0.0 ordinal unit); and
- a set of **scheduled reactivations** — each a due tick, a label, and a payload.

As the clock advances, every reactivation whose due tick has arrived becomes **due**,
fires in **due-tick order**, leaves the schedule, and — in the enact form — is handed
to a caller goal to **enact**. The clock only ever moves forward.

## Why ordinal, not seconds

Timing is measured in ordinal ticks. `tick_scheduler_schedule_after_unit/5` asks the
Causalontology core (`causal_core_dimension/2`) for a unit's dimension and **refuses**
a wall-clock unit with a glass-box category error. This is the concrete closure of
CEREBELLUM-1: a tick is no longer forced into a "seconds" distortion, and a wall-clock
unit has no place on the ordinal timeline.

## Interface

| Predicate | Meaning |
|-----------|---------|
| `tick_scheduler_open(+Address, -Nexus)` | Open a Lattice nexus and initialise it (clock 0, empty schedule). |
| `tick_scheduler_init(+Nexus)` | Initialise an already-open nexus. |
| `tick_scheduler_now(+Nexus, -Tick)` | Read the current ordinal tick. |
| `tick_scheduler_schedule_at(+Nexus, +DueTick, +Label, +Payload)` | Schedule at an absolute future tick. |
| `tick_scheduler_schedule_after(+Nexus, +Delay, +Label, +Payload)` | Schedule `Delay` ticks after now. |
| `tick_scheduler_schedule_after_unit(+Nexus, +Delay, +Unit, +Label, +Payload)` | As above, but the unit must be ordinal (a wall-clock unit is refused). |
| `tick_scheduler_pending(+Nexus, -Reactivations)` | The pending reactivations, in due-tick order. |
| `tick_scheduler_tick(+Nexus, -Fired)` | Advance one tick; return what fired. |
| `tick_scheduler_advance(+Nexus, +Delta, -Fired)` | Advance `Delta` ticks; return and remove what became due. |
| `tick_scheduler_advance_enact(+Nexus, +Delta, :Goal, -Fired)` | Advance and enact each fired reactivation with `Goal`. |

## Worked closure

```prolog
% HIPPO-2: consolidation is scheduled for later and enacted only when its tick arrives.
tick_scheduler_open('locus://demo', N),
tick_scheduler_schedule_after(N, 4, consolidate_episode, trace_42),
tick_scheduler_advance_enact(N, 3, enact, []),          % three ticks pass — nothing fires
tick_scheduler_advance_enact(N, 1, enact,               % the fourth tick enacts it
    [reactivation(4, consolidate_episode, trace_42)]).

% CEREBELLUM-1: ordinal ticks accepted, wall-clock seconds refused.
tick_scheduler_schedule_after_unit(N, 2, ticks, adjust, gain).   % ok
catch(tick_scheduler_schedule_after_unit(N, 2, seconds, adjust, gain),
      error(type_error(ordinal_tick_unit, seconds), _), true).   % refused
```

Base infrastructure at layer 0; depends on the `lattice` store and the `causal_core`
vocabulary; touches no ARC state.
