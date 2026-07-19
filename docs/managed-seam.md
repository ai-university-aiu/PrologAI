# The managed_seam — a first-class managed cross-stratal seam (Wave 10 Stage 4, WP-433)

Closes the Requirements Ledger's **Theme B** (cross-stratal seams and managed skips) —
the program's most-recurring gap, six sightings: P1 (seam facet), P2, STRATA-2,
ARBITER-2, HIPPO-3, CEREBELLUM-2, AMYGDALA-2.

## The gap

A process legitimately spans NON-ADJACENT strata (a hormone descends ten levels;
consolidation rises from molecule to region). PrologAI honestly recorded the jump with
a `skips:true` boolean, but a boolean could not: (a) distinguish "a mechanism exists
but is deliberately unmodeled here" from "no mechanism exists"; (b) draw the intervening
mechanism as a chain of adjacent-stratum steps; or (c) give a cross-stratal (edge)
construct a checkable home.

## What it adds

A first-class managed seam carrying a **mechanism_status**:

- `absent` — no intervening mechanism exists; the jump is genuinely direct.
- `unmodeled` — an intervening mechanism EXISTS but is deliberately unmodeled here (the
  **honest-ignorance** distinction a boolean could not draw).
- `modeled` — the intervening mechanism is drawn as a chain of adjacent-stratum steps.

The chain is **coupled** to the status: `modeled` requires a non-empty chain; `absent`
and `unmodeled` forbid one — so the absent-plus-chain contradiction is unrepresentable.

Well-formedness (the Causalontology 3.0.0 **Algorithm F**: non-adjacent endpoints
sharing a scheme; an intervening, strictly-monotone chain) and the **HOME rule** (the
coarsest, max-ordinal endpoint stratum) delegate to the frozen `causal_core` engine.
`managed_seam_home_check/5` lets a stratum pack **verify** a spanning construct's home
rather than piling it in arbitrarily (STRATA-2). And `managed_seam_emit/2` records the
seam as a **queryable Lattice event**, so a skip is visible to the runtime, not merely
legible to the static structure (P1/P2).

## Interface

| Predicate | Meaning |
|-----------|---------|
| `managed_seam_new(+Source, +Target, +Status, +Chain, -Seam)` | Build a seam; the chain is coupled to the status. |
| `managed_seam_status(?Status)` | The recognised statuses: absent, unmodeled, modeled. |
| `managed_seam_status_meaning(+Status, -Meaning)` | The glass-box English of a status. |
| `managed_seam_mechanism_status(+Seam, -Status)` | A seam's mechanism status. |
| `managed_seam_is_honest_ignorance(+Seam)` | True iff the status is `unmodeled`. |
| `managed_seam_wellformed(+Seam, +OccMap, +StratumMap, -Result)` | Algorithm F check (`ok`/`invalid`). |
| `managed_seam_home(+Seam, +OccMap, +StratumMap, -HomeStratum)` | The coarsest endpoint. |
| `managed_seam_home_check(+Seam, +OccMap, +StratumMap, +ProposedHome, -Result)` | Verify a proposed home. |
| `managed_seam_emit(+Nexus, +Seam)` | Emit the seam as a queryable Lattice event. |
| `managed_seam_events(+Nexus, -Seams)` | Every emitted seam event. |
| `managed_seam_events_by_status(+Nexus, +Status, -Seams)` | Emitted seams of one status. |

`OccMap` maps each occurrent id to `_{stratum: StratumId}`; `StratumMap` maps each
stratum id to `_{scheme: Scheme, ordinal: Ordinal}` — the same maps the `causal_core`
seam engine consumes. Base infrastructure at layer 0; depends on `lattice` and
`causal_core`; touches no ARC state.
