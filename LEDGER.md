# LEDGER.md — PrologAI Requirements Ledger (living continuation)

> The **canonical, original** Ledger lives in the frozen `prologai-loops` spike
> (`LEDGER.md` and `RESULT.md`, answered 2026-07-17, tagged and read-only). That
> copy must never be modified and nothing may depend on it. **This file is its
> living continuation inside PrologAI**: it cites the spike's entries by their
> identifiers (L1–L9) and records what PrologAI did about them — what was
> delivered, the closing commit, and how the delivery compares to the request.
>
> Spike source of each entry: `prologai-loops/LEDGER.md`.
> This continuation is maintained on the PrologAI side from Wave 1 onward.

Legend: **S** = the spike's severity for the Connectome plan (H/M/L).
Status: **CLOSED** · **PARTIALLY CLOSED** · **STILL OPEN**.

---

## Wave 1 — the layer construct and the Lattice affordances (2026-07-17)

Branch `ledger/wave-1-layer-and-lattice`. Rollback tag `pre-wave-1`. All work
additive; the ARC-AGI solving core was not modified. Gates held unchanged from
baseline throughout: ARC-AGI-1 400/400, ARC-AGI-2 120/120, Causalontology
conformance 107/107.

### L4 — a construct that expresses the strict layer rule · S=H · **CLOSED**
- **Requested (spike).** A pack could not declare its layer, nothing checked the
  rule, no violation was ever reported; the spike hand-built a static checker.
  Minimum remedy: an optional `layer(N)` field in `pack.pl` plus a load-time
  check that no pack imports a strictly-higher-layer pack, runnable in CI.
- **Delivered.** New `layer` pack (WP-426, base infrastructure, imports only
  SWI-Prolog standard libraries — beneath the Lattice, actors, and Causalontology
  packs). (1) **Declare** — a `layer(N)` fact in a pack's own `pack.pl`, no
  external registry. (2) **Check** — `layer_check/1` parses the *actual*
  `use_module(library(...))` graph across every pack and reports each upward edge
  among declared packs, one readable line per violation naming the rule, both
  packs, both layer numbers, and the breaking dependency. (3) **Enforce at load
  time** — `layer_enforce(strict)` throws (refuses a violating load);
  `layer_enforce(report)` lists without refusing (incremental adoption).
  Undeclared packs are gaps, never violations. (4) **CI** — `bin/check_layers.sh`
  (exit 0 clean, 1 on violation, 2 on error) and
  `.github/workflows/layer-rule.yml`.
- **Delivered vs requested.** Fully as specified, plus more: the check reads the
  real import graph (not merely a declared `requires` list), so it cannot be
  gamed by a stale manifest; and the two arms of the frozen spike, snapshotted
  read-only under the pack's `fixtures/`, are shown *by construct* to have **zero
  upward static edges** — reproducing the spike's hand proof (14/14 PLUnit tests).
- **Closing commit.** `5f9b099`.

### L5 — an upward (reentrant) reference kept alive as data · S=H · **PARTIALLY CLOSED**
- **Requested (spike).** Mailbox addressing lets a lower actor hold the literal
  address of a higher one; nothing flags that a lower-layer actor addresses a
  higher-layer one. Remedy: a layer-aware send that warns/denies on upward
  addressing, or a topic registry.
- **Delivered (partial).** The layer pack ships an **opt-in heuristic lint**,
  `layer_data_references/2` (and `layer_data_references_files/2`), that flags a
  quoted literal in a lower-layer pack's source which embeds a higher-layer
  pack's name. On the spike fixtures it flags the mailbox arm's
  `next_address('signal://mbx/cortex')` (thalamus layer 1 → cortex layer 3) and
  flags nothing in the stigmergy arm — exactly the distinction the spike drew.
- **Why not fully closed (stated plainly).** A **load-time import checker cannot
  see an upward reference carried as runtime data** in the general case: the
  address may be computed, read from a fact, or assembled at run time, and it
  never appears in the static import graph. Fully closing L5 needs a *runtime*,
  layer-aware transport (a send that knows the layers of both endpoints), which
  is a different construct from a load-time layer checker. **L5 therefore remains
  open for the general case**; the heuristic lint closes only the concrete
  literal-address case the spike cited.
- **Closing commit (partial).** `5f9b099`.

### L1 — no lightweight, non-semantic write door on the Lattice · S=H · **CLOSED**
- **Requested (spike).** `anchor_node/4` hard-requires the vector-embedding
  backend, so a non-semantic coordination fact drags in the whole similarity
  index. Remedy: `lattice_put/4` + `lattice_take/4` (or a node-fact write that
  skips the vector index).
- **Delivered.** Four backend-free predicates on the base `lattice` module (which
  imports no backend): `lattice_put/4`, `lattice_get/4` (peek), `lattice_take/4`
  (read-and-remove), `lattice_replace/4` (one fact per relation — a bounded
  coordination token). A test proves a fact writes and reads back with
  `current_module(vector_backend)` **false**. `anchor_node/4` is unchanged.
- **Delivered vs requested.** As specified, plus `lattice_get/4` and
  `lattice_replace/4` for the stigmergy blackboard pattern (bounded to one fact).
- **Closing commit.** `17bdf77`.

### L2 — `lattice_transaction/2` gives journaling but not isolation · S=H · **CLOSED**
- **Requested (spike).** The transaction takes no lock; two actors can interleave
  a read and a write and corrupt a shared fact. Remedy: a serializable
  `lattice_transaction/3` with `isolation(serializable)`, or document that
  callers must serialise writes.
- **Delivered.** `lattice_transaction/3`: with `isolation(serializable)` it wraps
  the journaled transaction in a per-nexus reentrant mutex, serialising
  concurrent read-modify-write with **no caller-supplied lock**.
  `lattice_transaction/2` is unchanged and is now documented, honestly, as the
  **non-isolating** mode. A deterministic concurrency test (a 1 ms read→write
  window) reaches exactly 100 under isolation and loses updates (25/100) without
  it.
- **Honesty note (cost).** Measured uncontended overhead of the isolation mutex:
  **~1.6 microseconds per transaction (~11% over plain journaling)** — reported,
  not hidden.
- **Closing commit.** `41393f7`.

### L3 — no reactive read / await → stigmergy must busy-poll · S=H · **CLOSED**
- **Requested (spike).** No blocking "await a fact matching a pattern"; stigmergic
  actors busy-poll (O(actors × poll-rate) waste). Remedy: `await_node_fact/2`, or
  a Lattice-write → publish bridge so readers subscribe instead of poll.
- **Delivered.** `lattice_await/5` blocks with **no CPU** on a private message
  queue and is woken the instant a write calls `lattice_notify/1`; every L1 write
  (`lattice_put`/`take`/`replace`) now notifies. This is the **hybrid bridge** the
  spike recommended: stigmergy for STATE plus a write-triggers-notification path
  for REACTIVITY. A reader awaits a **pattern**, never an actor's address, so
  **actor-to-actor references remain zero**. A waiter registers before its first
  existence check, so no wake is lost. Tests: prompt wake on a write (no poll),
  immediate return when already present, clean timeout on absence.
- **Implementation note.** SWI-Prolog's `thread_wait/2` modification signal does
  **not** fire on this platform (9.0.4) — its wake is only its `retry_every`
  poll — so a genuine message-queue condition variable is used instead.
- **Closing commit.** `bc4d9c7`.

### L6, L7, L8 (actors-pack ergonomics) · S=M/M/L · **STILL OPEN**
Not in Wave 1 scope (this wave built L4 first, then the three Lattice
affordances). `publish/2` fire-and-forget (L6), `cyclic_actor` bounded lifecycle
(L7), and a built-in glass-box hop trace (L8) remain as recorded in the spike.

### L9 — opening any nexus writes a growing `/tmp` journal · S=L · **STILL OPEN**
The new lightweight write door still journals through `lattice_transaction/2`,
which appends to a `/tmp` journal. An in-memory / `journal(none)` nexus option was
out of Wave 1 scope; L9 stands.

---

## New gaps discovered while building Wave 1 (be greedy)

- **N1 — `lattice_transaction/2` is module-transparent but not declared
  `meta_predicate`.** Its goal argument resolves in the caller's module by an
  implicit transparency, undocumented and easy to break: wrapping it in
  `lattice_transaction/3` silently ran the goal in the wrong module until `/3`
  was itself declared `:- meta_predicate lattice_transaction(?, ?, 0)`. Remedy:
  declare `/2` a meta-predicate explicitly and document the goal's module
  semantics, so future wrappers are not footguns.
- **N2 — `thread_wait/2`'s modification wake does not fire on SWI 9.0.4.** The
  builtin advertised for reactive database waits only re-checks on its
  `retry_every` timer here (measured: a 30 s retry never woke on a write). Any
  code that assumed `thread_wait` gives push reactivity is really polling.
  Remedy (used in L3): a message-queue condition variable. Worth an upstream
  check and a platform note.
- **N3 — the layer rule is declared for only 3 of 299 packs.** The construct is
  correct and adoption is deliberately incremental, but until many more packs
  carry a `layer(N)` fact the rule *guarantees little in practice* — 296 packs
  are undeclared gaps. Remedy: a standing adoption program that assigns and
  declares layers pack by pack (the checker already reports the gap list).
- **N4 — L5 needs a runtime layer-aware transport, not a lint.** Closing the
  data-reference gap for real (computed/dynamic addresses) requires a send/notify
  path that knows both endpoints' layers and can warn or deny on an upward
  address at run time. That is a new construct, distinct from the load-time
  checker delivered here.
- **N5 — no fairness or bound on the L3 waiter set.** `lattice_notify/1`
  broadcasts to all registered waiters with no ordering guarantee and no cap on
  the waiter registry. Fine at current scale; worth a bound and a fairness note
  before the 140-construct Connectome.
