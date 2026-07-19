# The coordination construct — ergonomic coordination affordances (Wave 10 Stage 8, WP-437)

Closes the Requirements Ledger's **Theme F** (coordination and closure primitives) — the
bounded ergonomics gaps the Wave 1 closure hybrid left: L5, L6, L7, L8, L9, P8, P9, P10,
N1, N2, N4, N5. Coordination in the connectome is single-threaded and reentrant (a step
function drives a loop that settles), so the pack provides its affordances over an
**in-memory, journal-free store driven synchronously** — no blocking-thread primitives,
no push-reactivity.

## What it adds

| Finding | Affordance |
|---------|-----------|
| **L9** | An in-memory store that writes no journal (`coordination_open`/`put`/`get`/`take`). |
| **P8** | A keyed lookup `coordination_get_key/4` — a fact of relation `R` whose first argument is `K` (the match `lattice_await/5` could not express). |
| **P8, N5** | A **bounded** keyed await `coordination_await_key/6` — check, run a producer step, re-check, up to a step bound; it can never spin and needs no fairness scheduler. |
| **L6** | An ordered, durable FIFO channel `coordination_publish_ordered/3` + `coordination_consume_ordered/3` (vs fire-and-forget). |
| **L7, P9** | A bounded reentrant-loop driver `coordination_bounded_loop/6` with an until-condition and a completion signal (`completed(N)` / `bounded_stop(Max)`). |
| **P10** | A reentrant-loop descriptor `coordination_declare_loop/4` + `coordination_loop_check/2` — two checks (acyclic forward graph, genuine back-edge closure) on **one** declared object. |
| **L5, N4** | A **runtime** layer-aware transport `coordination_register_actor/2` + `coordination_send/4` that refuses a send from a lower-layer actor up to a higher-layer one, checked at send time — so a computed or dynamic address a load-time checker cannot see is still refused. |
| **L8** | A glass-box hop trace `coordination_trace_hop/3` + `coordination_trace/2`. |
| **N1** | On the `lattice` pack, `lattice_transaction/2` is now a `meta_predicate` (was an undocumented footgun). |
| **N2** | The SWI-Prolog `thread_wait/2` behaviour is documented and avoided — this construct is driven synchronously and never relies on push-reactivity. |

## The runtime layer wall (L5, N4)

The load-time layer rule cannot see an upward reference carried as runtime **data** (a
computed or dynamic address). The transport closes the general case: a `coordination_send`
looks up the addressed actor's registered layer at send time and refuses an upward send.

```prolog
coordination_register_actor(striatum_actor, 2),
coordination_register_actor(cortex_actor, 4),
coordination_send(cortex_actor, striatum_actor, go, sent),              % downward: delivered
coordination_send(striatum_actor, cortex_actor, go,
                  refused(upward_send(striatum_actor, 2, cortex_actor, 4))).  % upward: refused
```

Base infrastructure at layer 0; depends only on SWI-Prolog standard libraries; touches no
ARC state.
