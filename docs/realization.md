# The realization construct — binding structure to dynamics (Wave 10 Stage 5, WP-434)

Closes the Requirements Ledger's **Theme C** (the structure-to-dynamics seam / grounding
fit): P1's dynamics facet (which finishes P1), P3, P4, and STRATA-5. With Theme C closed,
the four load-bearing walls (Themes A–D) are all closed.

## The gap

Every neurochemical and every computing construct is TWO things at once: a grounded
Causalontology STRUCTURE record and a native DYNAMICAL law or variable. The grounding
rule (ground the structure, keep the dynamics native) is correct — but the two halves
were related only by a shared English word. The glass box could not trace from "what a
synapse computes" (structure) to "how it computes it" (dynamics) through one identity.

## What it adds

A binding registry. `realization_bind(+StructureId, +Realizer)` records that a realizer
realizes a structure record. A **realizer** is one of:

- `native_law(PredicateIndicator)` — a named native predicate (`Name/Arity` or
  `Module:Name/Arity`) that realizes the record's transform (P1, P3).
- `lattice_signal(Nexus, Relation)` — a typed signal on the Lattice carrying a value, a
  source port, and a timestamp (P4).

The binding is **checkably real**, not a shared English word:

- `realization_realizer_exists/1` — the realizer actually exists (a defined predicate;
  an open nexus).
- `realization_check/2` — a bound-but-missing realizer is reported as a **finding**
  (`invalid(dangling(...))`), an unbound structure as `invalid(unbound(...))`; a real
  binding is `ok(Realizers)`.
- `realization_trace/2` — a glass-box trace `_{structure, realized_by: [_{realizer, exists}]}`.

Because the binding is itself the cross-cut, structure and dynamics need not share a
stratum pack — which, per the grounding rule, they never can, since the native dynamics
are ungrounded and have no stratum (STRATA-5). The realization pack declares no stratum
and heals the seam all the same.

## Interface

| Predicate | Meaning |
|-----------|---------|
| `realization_bind(+StructureId, +Realizer)` | Register that `Realizer` realizes `StructureId`. |
| `realization_unbind(+StructureId)` | Remove every binding of a structure record. |
| `realization_realized_by(?StructureId, ?Realizer)` | A structure record's realizer(s). |
| `realization_realizes(?Realizer, ?StructureId)` | The inverse — what a realizer realizes. |
| `realization_realizer_exists(+Realizer)` | The realizer is real (defined predicate; open nexus). |
| `realization_check(+StructureId, -Result)` | `ok`/`invalid(dangling)`/`invalid(unbound)`. |
| `realization_check_all(-Report)` | One check line per bound structure. |
| `realization_trace(+StructureId, -Trace)` | A glass-box trace to the realizing dynamics. |
| `realization_emit_signal(+Nexus, +Relation, +Value, +SourcePort, +Timestamp)` | Write a typed signal (P4). |
| `realization_signal(+Nexus, +Relation, ?Value, ?SourcePort, ?Timestamp)` | Read typed signals. |

Base infrastructure at layer 0; depends on `lattice`; touches no ARC state.
