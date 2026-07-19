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

> **Consolidated program-wide view (Wave 9).** This file remains the authoritative
> record of PrologAI's own deliveries and native gaps (the N series and the L
> continuations). The single canonical account that gathers EVERY finding across ALL
> the program's repositories — the frozen spike (L), this file (N), the slice (P), the
> three granularity arms (ATOMIC / LOOPS / STRATA), and the region builds (ARBITER,
> HIPPO, CEREBELLUM, AMYGDALA) — into one navigable document, with the open-gaps
> forward agenda and the closed track record, now lives at
> **`docs/PrologAI_Requirements_Ledger_v2.txt`**. That consolidated Ledger cites the
> per-repository Ledgers; it does not replace them.

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

---

## Wave 1.5 — quality-assurance cleanup (2026-07-17)

Branch `ledger/wave-1.5-cleanup`. Rollback tag `pre-wave-1.5`. All work
additive; the ARC-AGI solving core was not modified. Gates held unchanged from
baseline: ARC-AGI-1 400/400, ARC-AGI-2 120/120, Causalontology conformance
107/107. Every item below traces to a finding from the Wave 1 QA sweep; nothing
new was added beyond the findings. Ledger **N1**, **N2**, **N4**, and **N5**
remain **STILL OPEN** — out of scope for this cleanup.

- **The hybrid pattern is now documented where a newcomer looks.** The
  stigmergy-plus-notification bridge (stigmergy for STATE with zero
  actor-to-actor references, notification for REACTIVITY) previously lived only
  in code comments and this Ledger. It is now a newcomer-readable document,
  `docs/lattice-hybrid-pattern.md`, linked from `README.md` — with the
  principle, the evidence (citing the frozen `prologai-loops/RESULT.md`), the
  exact API (`lattice_await/5`, `lattice_notify/1`, `lattice_put/4`,
  `lattice_get/4`, `lattice_take/4`, `lattice_replace/4`), a worked example, the
  await-a-PATTERN-never-an-address rule, and the legibility cost stated honestly.

- **The layer construct is now documented where a newcomer looks.**
  `docs/layer-rule.md` (linked from `README.md`) explains the strict layer rule,
  how a pack declares its layer, how to run `bin/check_layers.sh`, strict vs
  reporting mode, how undeclared packs are treated, and how to read a violation
  line.

- **N3 — adoption reality now stated plainly.** The pack count is reconciled
  (see below) and both `README.md` and `docs/layer-rule.md` now say plainly:
  the layer construct is live and gated in CI; **3 of 299 packs** declare a
  layer today; the remaining 296 are undeclared gaps, not violations; adoption
  is deliberately incremental; and until it spreads, a passing check verifies
  only the declared packs. No layers were mass-declared to inflate the number —
  the honest disclosure is the fix. **N3 stays open** as a standing adoption
  program; this cleanup only made its reality legible.

- **The strict-mode enforcement test now actually tests enforcement.** The Wave
  1 `test(strict_throws_on_violation)` never ran `layer_enforce/1` with a
  violation present — it only re-checked the pure core. It now exercises the real
  throw path: `layer_enforce_dir/2` (the new dir-scoped sibling of
  `layer_check_dir/2` and `layer_report_dir/1`) is run in strict mode over a
  read-only violating fixture (`fixtures/violation_packs/`: `fixture_low` at
  layer 0 importing `fixture_high` at layer 5) and asserted to throw
  `layer_rule_violation`. A companion test confirms report mode over the **same**
  violating configuration does not throw and still reports. The layer suite is
  now 16/16.

- **Pack count reconciled.** `README.md` claimed **315** packs; the true count of
  pack directories carrying a `pack.pl` is **299** (matching this Ledger's N3).
  `README.md` was corrected to 299; N3 was already correct.

- **Layer header inconsistency fixed.** `packs/layer/prolog/layer.pl`'s header
  read `(WP-426, Layer 400)` while `packs/layer/pack.pl` declares `layer(0)`. The
  header now reads `(WP-426, Layer 0)`, agreeing with the declaration.

- **Finding: the Lattice acceptance tests were ungated.** No workflow ran
  `packs/lattice/test/test_lattice.pl` (the L1/L2/L3 acceptance suite), so a
  regression in the Lattice coordination affordances could merge unseen — the
  same class of invisible rot the pack-naming TEST-PRESENCE check exists to
  prevent. A new workflow `.github/workflows/lattice-tests.yml` now runs the
  suite on push and pull request, failing the job on any failure (15/15 green).

---

## Wave 2 — the 10 percent mini regression harness (2026-07-17)

Branch `ledger/mini-regression-harness`. Rollback tag `pre-mini-harness`. All
work additive; the ARC-AGI solving core (in Mentova) was **not** modified, and
the full regression runners were left untouched. Baseline gates held: mini
ARC-AGI-1 40/40, mini ARC-AGI-2 12/12, Causalontology conformance 107/107,
strict layer rule green.

### New standing rule — mini regression as the per-wave gate · **DELIVERED**
- **Why.** The full ARC-AGI regression (400 + 120 tasks through the Mentova
  solving core) is too slow to run every wave. To keep wave velocity, the
  standing per-wave gate becomes a fixed 10 percent spot-check. This is a
  **deferral, not a cancellation** — recorded as debt in `REGRESSION_DEBT.md`.
- **What.** A committed, deterministic sample of one task in ten:
  ARC-AGI-1 40/400 (gate 40/40), ARC-AGI-2 12/120 (gate 12/12). The sample is
  mechanical and auditable — every tenth task id in lexicographic order — so it
  is obviously un-cherry-picked; the selection rule is documented in each
  manifest header (`tests/mini_regression/manifest_arc_agi_{1,2}.txt`).
- **How it runs.** `bin/run_mini_regression.sh` (additive; the full runner is
  untouched) loads the **same** Mentova solving core and the **same** task
  facts the full runners use, and dispatches each manifest task through the
  core's own per-task attempt predicate (`arc_benchmark:arc_attempt_task/2`,
  `arc_benchmark_2:arc2_attempt_task_/2`). Exit 0 iff 40/40 and 12/12. A driver
  (`tests/mini_regression/mini_regression_driver.pl`) does the work; it locates
  the two repos via `$PROLOGAI_HOME`/`$MENTOVA_HOME` (local paths as fallback)
  so it runs both locally and in CI. **Materially faster, measured:** the whole
  mini gate (both benchmarks) runs in ~21s, versus 10:25 (625s) for the full
  ARC-AGI-1 run alone (400/400, measured on this branch) — roughly a 30x
  speedup before the full ARC-AGI-2 run is even added.
- **CI.** New additive workflow `.github/workflows/mini-regression.yml` checks
  out PrologAI and Mentova side by side, points `MENTOVA_HOME` at the Mentova
  checkout, and fails the build on any non-zero exit. No existing workflow was
  removed or disabled.
- **Honesty guardrail.** The blind spot is stated everywhere the mini result is
  reported: the mini gate detects **gross breakage only** and is blind to the
  untested 90 percent. A green mini run **never** asserts or refreshes the
  400/400 or 120/120 claims; those rest on the last **full** run alone. A full
  regression is mandatory at the conclusion of all waves and before any public
  re-assertion of the scores. The README benchmark section now carries a
  one-line pointer to `REGRESSION_DEBT.md` beside the claims.

### Gap discovered while building it
- **The ARC solving core and task data live entirely in Mentova, not PrologAI,
  and PrologAI CI had never run any ARC regression.** The existing PrologAI
  workflows gate conformance, the layer rule, and the Lattice suite — none
  touch ARC. So the mini harness is the *first* time an ARC benchmark runs from
  the PrologAI side, and it structurally depends on a Mentova checkout being
  present. The driver was therefore made repo-root-relative
  (`$PROLOGAI_HOME`/`$MENTOVA_HOME`) rather than pinned to one machine's
  absolute paths, and the CI workflow must check Mentova out beside PrologAI
  (via a `MENTOVA_REPO_TOKEN` secret). Without that checkout the job is red by
  design — there is nothing to gate without the core. This cross-repo coupling
  is the standing constraint the next wave (Part Two) inherits.
- **The full ARC-AGI-2 benchmark had no committed runner script or demo.**
  ARC-AGI-1 ships `demos/arc_agi_benchmark.pl`; ARC-AGI-2 has the
  `arc_benchmark_2` module and `arc2_benchmark_print/0` but no committed
  entry-point script — the 120/120 run was driven ad hoc. The mini driver
  supplies a repeatable entry for the 12-task ARC-AGI-2 subset; a committed
  full ARC-AGI-2 runner remains an open Mentova-side gap (out of scope here —
  Mentova is read-only for this task).

---

## Wave 4, Part One — bind pack layer to stratum ordinal (2026-07-18)

Branch `ledger/wave-4-bind-layer-to-stratum`. Rollback tag `pre-wave-4-bind`.
All work **additive**; the ARC-AGI solving core was **not** modified, and the L4
layer construct's existing predicates and checker behaviour were preserved
byte-for-byte (only the module export list gained a comma to append new exports).
Baseline gates held unchanged: mini ARC-AGI-1 40/40, mini ARC-AGI-2 12/12,
Causalontology conformance 107/107, and the strict layer rule (L4) still reports
3 declared packs, 296 undeclared gaps, 0 violations. This is the Connectome
program's fourth Ledger delivery back into PrologAI: the strata arm found the
gap, and the finding — not the arm's code — is what ships.

### N6 — bind a pack's layer to the ordinal of the stratum it declares · S=H · **DELIVERED** (closes STRATA-3)

- **The gap (STRATA-3, from `connectome-strata`).** A pack can DECLARE its layer
  (L4), and the Causalontology data model has strata with ordinals, but nothing
  bound the two: a pack could declare a layer that contradicts the ordinal of the
  stratum it claims to be, and L4 — which checks that layers are ORDERED
  correctly, not that a layer matches the ordinal it should — would pass. The
  Wave 3 verdict's winning decomposition (one pack per stratum; see
  `WAVE_3_VERDICT.txt`, Part Five — the decision that promoted STRATA-3 into this
  PrologAI requirement) rests on "pack layer tracks stratum ordinal", which was
  maintained BY HAND. Worse, a
  mis-declared layer can DISGUISE an ordinal-upward dependency as a
  layer-downward one, so L4 alone can be fooled into passing a genuine upward
  edge.
- **What was delivered (the minimum that closes it).** An additive extension of
  the `layer` construct (in `packs/layer/prolog/layer.pl`), with no dependency
  beyond SWI-Prolog standard libraries — never the Lattice, actors, or any
  Causalontology pack, exactly as L4 requires:
  - A pack DECLARES the stratum it represents with one cheap fact,
    `stratum(Label)`, in its `pack.pl` beside `layer(N)` — in the pack, so it
    cannot drift into an external registry (`layer_pack_stratum/2`).
  - The stratum ORDINAL is read from the AUTHORITATIVE place it already lives —
    the Causalontology stratum records (`layer_stratum_ordinals/2` reads the
    `label`/`ordinal` of every `type:"stratum"` record from a strata-source
    directory), so a pack cannot claim an ordinal the data disagrees with.
  - An ORDER-PRESERVING consistency check, not equality (stratum ordinals are
    sparse — 4, 6, 7, 9, 14 — while layers are dense 0,1,2,…): for any two bound
    packs, a lower ordinal must not carry a higher layer, and equal ordinals must
    share a layer (`layer_binding_violations/2`, the pure testable core; the
    readable line names both packs, their layers, strata, and ordinals).
  - LOAD-TIME ENFORCEMENT matching L4: `layer_bind_enforce_dir/3` in `strict`
    mode throws on any binding violation and in `report` mode lists without
    refusing, so the binding is adopted incrementally.
  - A CI CHECKER, `bin/check_layer_binding.sh` (exit non-zero on a violation),
    gated by the additive `.github/workflows/layer-binding.yml`. The existing
    `bin/check_layers.sh` (L4) is untouched and independently runnable.
- **The skip is legal; the upward edge is not — and the disguise is caught.**
  Confirmed by fixtures and PLUnit: a legitimate DOWNWARD SKIP (a high-ordinal
  stratum depending on a much lower one — the cortisol channel) PASSES both the
  binding and L4, because it is a downward layer edge across a large ordinal gap,
  not an upward one. A plain UPWARD edge FAILS L4. And the decisive case — an
  upward-ordinal dependency DISGUISED as downward by a mis-declared layer — FOOLS
  L4 (which passes it) but is CAUGHT by the binding (the coarse stratum was given
  a lower layer than a fine one). This is precisely the loophole the binding
  exists to close.
- **Adoption is incremental.** A pack that declares a layer but NO stratum is
  UNBOUND — reported as a gap to fill, never an error that breaks a build (the
  same stigmergic pattern L4 uses for undeclared layers). The construct is a
  no-op for a repository that declares no strata yet — including PrologAI itself
  today, where the binding checker reports every pack unbound and exits clean.
- **Evidence / tests.** 9 new `AC-N6-*` PLUnit tests in
  `packs/layer/test/test_layer.pl` (layer suite now 25/25), over fixtures under
  `packs/layer/test/fixtures/binding/` (a strata source plus consistent, upward,
  mis-bound, and unbound configurations). Documented in `docs/layer-binding.md`.
- **Closing commit.** `ab34fed` (the binding construct), with docs in `0513b9e`;
  merged to main as `798fbe5`.
- **STRATA-3 status: CLOSED.** The alignment "pack layer tracks stratum ordinal"
  is now a checked, load-time, CI-gated invariant rather than a hand-maintained
  convention — the same promotion L4 gave the strict layer rule after the spike.
  It closes for every pack that opts in by declaring its stratum; adoption across
  a codebase is incremental, as with L4.

### New gap discovered while building it (be greedy)

- **N7 — the binding trusts the structure-record ARTIFACTS as its ordinal source,
  with no check that they are current with the pack's minting code.** The ordinal
  is read from the Causalontology stratum records (the JSON the validator writes),
  not from the pack's own stratum-minting Prolog — because reading the ordinal
  from the minting code would mean RUNNING the pack inside a load-time checker,
  which is exactly the kind of heavyweight coupling the layer construct avoids. So
  if a stratum's ordinal changes in the minting code but the structure records are
  not regenerated, the binding checks against STALE ordinals and a real drift
  would pass. The minimum remedy is a freshness check that the strata-source
  records are consistent with the packs that mint them (a records-up-to-date gate),
  or a lighter, load-safe way to read a stratum's ordinal directly from its pack.
  Recorded, not closed — the same "read ordinals out of the data from a load-time
  checker" limit STRATA-3 anticipated.

---

## Wave 5 — a first-class membership contract (2026-07-18)

Branch `ledger/wave-5-membership-contract`. Rollback tag `pre-wave-5`.
All work **additive**; the ARC-AGI solving core was **not** modified, and the two
load-time checkers — the strict layer rule (L4) and the layer-to-stratum binding
(N6) — were preserved byte-for-byte and keep their exact verdicts (0 violations,
exit 0). Baseline gates held unchanged: mini ARC-AGI-1 40/40, mini ARC-AGI-2
12/12, Causalontology conformance 107/107. This is the Connectome program's fifth
Ledger delivery back into PrologAI: the arbiter arm found the gap (`ARBITER-1`),
and the finding — not the arm's code — is what ships. The arbiter repository was
read pinned at commit `58951b9` and **not modified**.

### N8 — express the membership invariant as a first-class checked property · S=H · **DELIVERED** (closes ARBITER-1)

- **The gap (ARBITER-1, from `connectome-arbiter`).** The Wave 4 safety layer's
  basal-ganglia selector must never emit an action nobody offered — its output
  must always be a member of the offered candidate set, or an explicit abstention
  (`no_selection`). The arbiter PROVED that property holds (a 532-attempt
  adversarial battery, 0 escapes), but only BY HAND: a guard predicate
  (`region_stratum_membership_guard/3`), a throwing emit step
  (`region_stratum_emit/3`), and a standalone checker, each output routed through
  them by an author who remembered to. A SECOND selector written without that
  habit would carry no protection, because PrologAI had no way to SAY "the output
  of this predicate must be a member of this input set" and enforce it. The
  membership invariant is a behavioural SAFETY property — the same class of thing
  L4 and N6 promoted from convention to a checked invariant, but about a runtime
  value rather than the static graph.
- **What was delivered (the minimum that closes it).** A new, standalone
  construct, the `membership_contract` pack (`packs/membership_contract/`), with
  no dependency beyond SWI-Prolog standard libraries (`lists`, `prolog_wrap`) —
  never the Lattice, actors, any Causalontology pack, or the arbiter, exactly as
  the layer construct requires of itself:
  - A predicate OPTS IN with one declaration,
    `membership_contract_enforce(:Pred, +OutPos, +InPos, +Abstention)`: its
    OutPos-th argument (the output) must be a member of its InPos-th argument (a
    list — the offered set), or equal to the declared `Abstention` value.
  - It is enforced as a **RUNTIME POSTCONDITION** — the key difference from L4 and
    N6, which are LOAD-TIME properties checkable from the static graph. Membership
    depends on the actual input and the actual output on a given call, so it can
    only be checked when the guarded predicate produces a result. The contract
    wraps the predicate with SWI-Prolog's `wrap_predicate/4` so that on EVERY
    solution the postcondition runs: a member passes, the declared abstention
    passes, and a NON-member is refused with a glass-box error naming the
    predicate, the output, and the set it was not a member of. The guarded
    predicate cannot return a non-member.
  - OPT-IN / INCREMENTAL: a predicate with NO contract is UNGUARDED, not violating
    — it behaves exactly as today (the same adoption pattern L4 uses for
    undeclared layers and N6 for unbound packs).
  - GLASS-BOX: `membership_contract_violation_line/2` renders a violation as one
    readable line.
  - MEMBERSHIP-SPECIFIC: it is about membership of an output in a named input set,
    not a general assertion framework or a type system. Deliberately tight.
  - A pure sibling `membership_contract_check/4` (the postcondition — succeed or
    throw), a boolean `membership_contract_holds/3` (never throws), and a registry
    reader `membership_contract_declared/4` for introspection.
- **The arbiter's hand-rolled guard is re-expressible by DECLARATION.** Confirmed
  PrologAI-side by PLUnit (`test_membership_contract.pl`, `arbiter_guarantee_by_declaration`):
  a stand-in future selector obtains the arbiter's exact guarantee — a selection
  must be a member of the offered candidates, with an explicit no-selection
  allowed — purely by declaring the contract, with no hand-rolled guard, no
  throwing emit, and no bespoke battery. A member passes, `no_selection` passes,
  and an action nobody offered is refused. The frozen arbiter repository was not
  touched.
- **Evidence / tests.** 9 `AC-N8-*` PLUnit tests in
  `packs/membership_contract/test/test_membership_contract.pl` (9/9): member
  passes, declared abstention passes, non-member refused (throws the glass-box
  violation), unguarded predicate unaffected, pure postcondition, boolean holds,
  declared registry introspectable, violation line readable, and the arbiter
  re-expression. Gated in CI by the additive
  `.github/workflows/membership-contract.yml`. Documented in
  `docs/membership-contract.md`.
- **Closing commit.** `efe5049` (the construct, its test, and the CI gate); this
  Ledger entry and the docs ship in the immediately following commit on branch
  `ledger/wave-5-membership-contract`, merged to main.
- **ARBITER-1 status: CLOSED.** The membership invariant — a selector's output is
  a member of the offered set, or an explicit abstention — is now a first-class,
  declarable, glass-box-enforced property rather than a hand-maintained habit. It
  closes for every predicate that opts in by declaring the contract; adoption
  across a codebase is incremental, as with L4 and N6. The distinction from L4/N6
  is intrinsic and recorded: this is the program's first RUNTIME (postcondition)
  invariant, where those two are LOAD-TIME.

### Delivered vs requested

- **Requested:** a first-class construct to declare that a predicate's output must
  be a member of an input set (or a declared abstention), enforced as a runtime
  postcondition, opt-in, glass-box, membership-specific, with no dependency on the
  Lattice/actors/Causalontology/arbiter, plus a PrologAI-side demonstration that
  the arbiter's guard is re-expressible with it. **Delivered:** all of it — the
  `membership_contract` pack, the `wrap_predicate/4` runtime postcondition, the
  opt-in/unguarded adoption model, the readable violation, and the arbiter
  re-expression test — with the four hard gates (mini regression, conformance, L4,
  N6) held unchanged and the ARC solving core untouched.

### New gaps discovered while building it (be greedy)

- **N9 — the contract cannot express membership in a set that is not a plain list
  argument.** The offered set must be one InPos argument that is a proper list at
  call time. A selector whose candidates are, say, the keys of an assoc, the
  solutions of a goal, or a field inside a compound term cannot declare the
  contract directly — it must first project its candidates into a list argument.
  The minimum remedy is an accessor form (a membership contract that names a
  deterministic goal `Candidates(+Args, -List)` to produce the set), so the
  offered set need not already be a bare list argument. **CLOSED by N11** (Wave 7
  Part Two) — delivered as a membership-TEST-goal accessor form that checks
  membership without materialising the set at all, better than the list-producer
  remedy this gap first sketched.
- **N10 — enforcement is per-solution, with no once/deterministic contract mode.**
  `wrap_predicate/4` runs the postcondition on EVERY solution of a
  non-deterministic guarded predicate, which is correct but means a generator that
  yields one bad solution among many throws mid-backtracking rather than being
  filtered. For a selector (deterministic, one answer) this is exactly right; for
  a nondeterministic producer a `once`-style or filtering variant might be wanted.
  Recorded as a scope note, not a defect — the construct is aimed at selectors.
  **CLOSED by N14** (Wave 8 Part One), via the once-deterministic mode; N12 subsumed
  and re-recorded this gap, and N14 closes both.

---

## Wave 7, Part One — documentation governance and a SPARC/Tutorial catch-up (2026-07-18)

Branch `docs/wave-7-governance-and-catchup`. Rollback tag `pre-wave-7-docs`. This
entry is a **documentation-governance note**, not an N-construct — no behaviour
changed. It is the enforce-then-build Part One of Wave 7: it writes the doc rule
down and catches the flagship documents up so Part Two (the accessor-form
membership contract, closing N9) ships under the written rule.

### DOC-GOV-1 — the six-file repository documentation rule was written down · **ADOPTED**

- **What was adopted.** The **Six-File Repository Documentation Rule** was added to
  the governing (not-publicly-tracked) `CLAUDE.md`: every repository that contains
  functional code carries a `docs/` folder with the six versioned files
  `[reponame]_1_Specification` … `_6_Demonstration` (the five SPARC files plus a
  Demonstration plan of intent), the Pseudocode file written in English-Readable
  Code, versioned under the existing SPARC and Archive rules. A repository with no
  functional code (a data-structure or standard, such as `causalontology`) is
  exempt and instead carries a single standalone specification in its root.
- **Why it exists.** The per-construct documentation discipline (a `docs/` page, a
  README paragraph and table row, a Ledger entry, and a Continuous Integration
  workflow) had always held but was never written down, so the SPARC series and the
  Tutorial drifted stale with respect to N6 and N8 without any rule being violated.
  Writing the rule down makes the required documentation set an explicit definition
  of done.

### DOC-GOV-2 — SPARC and the Tutorial caught up to N6 and N8 · **DELIVERED**

- **SPARC.** Applying the scoping rule (an infrastructure construct always touches
  Specification, Architecture, and Completion; it touches Refinement when it adds
  enforcement detail; Pseudocode only on new algorithmic detail; Demonstration only
  when Mentova is affected), four volumes were bumped by copy-and-append and their
  superseded versions moved into `docs/archive/` with `git mv`: Specification
  v411→v412, Architecture v404→v405, Refinement v463→v464, Completion v469→v470.
  Each now states N6 (the load-time layer-to-stratum binding, closing STRATA-3) and
  N8 (the runtime membership contract, closing ARBITER-1). Pseudocode (v403) and the
  Demonstration volume were correctly left untouched (no new algorithmic detail; no
  Mentova effect).
- **Tutorial.** Chapters 360 (the N6 binding) and 361 (the N8 membership contract)
  were appended to `docs/PrologAI_Tutorial.txt`, in the Tutorial's newcomer voice —
  how to declare a stratum and run the binding checker, and how to declare a
  contract, name the abstention, and read a violation.

### DOC-GOV-3 — the two label items, reconciled honestly

- **The README SPARC table was corrected** to the actual current filenames
  (post-bump): Specification v412, Pseudocode v403, Architecture v405, Refinement
  v464, Completion v470, Demonstration_Mentova v4. It had cited stale numbers
  (v263/v255/v256/v315/v321) that matched neither the filenames nor the headers.
- **The "Refinement internal header" is NOT a bug — a finding recorded honestly.**
  The catch-up surfaced that every volume's line-1 internal header sits at an old
  version (Specification header v263, Refinement header v314, and so on), older than
  its filename. This is **correct by design**: the SPARC/copy-and-append rule
  freezes the line-1 internal header at the volume's origin version and advances
  only the filename. So no internal header was edited (doing so would violate the
  rule). The earlier draft of this change order called the Refinement header a bug
  to fix; the governing rule says the opposite, and the rule wins. The header/
  filename divergence is intended, not drift.

- **Closing commit.** Recorded in the squash-merge of
  `docs/wave-7-governance-and-catchup` to main.

---

## Wave 7, Part Two — the membership contract accessor form (2026-07-18)

Branch `feature/wave-7-accessor-contract`. Rollback tag `pre-wave-7-accessor`. All
work **additive**; the ARC-AGI solving core was **not** modified, and only the
`membership_contract` pack changed. Baseline gates held unchanged: mini ARC-AGI-1
40/40, mini ARC-AGI-2 12/12, Causalontology conformance 107/107, the strict layer
rule (L4) and the layer-to-stratum binding (N6) with 0 violations, and — critically
— the N8 plain-list membership form byte-for-byte in behaviour (its nine tests pass
unchanged). This is the enforce-then-build Part Two: the wall a region hit (HIPPO-1)
ships back into PrologAI as a delivery.

### N11 — an accessor form for the membership contract · S=M · **DELIVERED** (closes N9 / HIPPO-1, WP-427)

- **The gap (N9, second-sighted as HIPPO-1).** The N8 membership contract could read
  the offered set only from a plain-LIST argument. A growing store — the Wave 6
  memory region's stored-memory facts on the Lattice — is not a list, so the region
  had to flatten the whole store into a list on every recall (O(store size) per call,
  copying the entire set). It recorded this as an honest workaround, not a fix.
- **What was delivered (the minimum that closes it).** An additive extension of the
  `membership_contract` pack (WP-427), depending only on the same SWI-Prolog standard
  libraries — never the Lattice, actors, any Causalontology pack, or any Connectome
  repository:
  - **The test-goal form (primary, no materialisation).**
    `membership_contract_enforce_goal(:Pred, +OutPos, :TestGoal, +Abstention)` names a
    semi-deterministic membership-TEST goal — a closure that succeeds when called with
    the candidate output appended, iff the candidate is in the set. On every call the
    contract runs that test on the produced output; a member passes, the abstention
    passes, a non-member is refused with a glass-box `membership_contract_goal_violation`
    naming the **goal** (there is no list to print). **The full set is never built** —
    for a fact store, a single lookup, not an O(size) copy. It even guards membership of
    an infinite set no list could hold.
  - **The producer form (convenience, materialises).**
    `membership_contract_enforce_producer/4` names a goal that builds the set as a
    list and reuses the plain-list check; offered for a small set, it still
    materialises, so it does NOT retire N9's cost — the test-goal form does.
  - Boolean sibling `membership_contract_holds_goal/3` (never throws), introspection
    `membership_contract_declared_goal/4`, and a second `membership_contract_violation_line/2`
    clause that renders the goal violation. The plain-list predicates are untouched.
- **The hippocampus recall is re-expressible with no flattening.** A PrologAI-side test
  (`accessor_hippocampus_reexpression`) declares the test-goal form on a recall over a
  fact store and proves, through a materialisation counter that stays at zero, that the
  no-confabulation guarantee is obtained without ever building the store as a list. The
  frozen `connectome-hippocampus` repository was **not** touched.
- **Evidence / tests.** 11 `AC-N11-*` PLUnit tests added to
  `packs/membership_contract/test/test_membership_contract.pl` (the suite is now 20:
  9 plain-list unchanged + 11 accessor), gated by the existing
  `.github/workflows/membership-contract.yml` (it runs the whole suite). Documented in
  `docs/membership-contract.md`; SPARC volumes bumped (Specification v412→v413,
  Pseudocode v403→v404, Architecture v405→v406, Refinement v464→v465, Completion
  v470→v471) with the accessor section; Tutorial chapter 362 added.
- **Closing commit.** Recorded in the squash-merge of `feature/wave-7-accessor-contract`
  to main.
- **N9 status: CLOSED.** Delivered better than N9's own sketch (which proposed a list
  producer): the primary form is a membership-TEST goal that never materialises. The
  supported set is the plain-list form (N8) and the test-goal form (N11); the producer
  form is a materialising convenience, not the fix.

### New gaps discovered while building it (be greedy)

- **N12 — the accessor form checks per solution, and cannot short-circuit a
  nondeterministic producer.** Like N8/N10, the wrapped check runs on every solution;
  the test-goal form has no `once`/filtering mode to accept the first member of a
  nondeterministic guarded predicate and stop. For a selector or a recall
  (deterministic, one answer) this is exactly right; a `once`-style accessor variant is
  the minimum remedy if a nondeterministic producer ever needs it. This subsumes N10 for
  the accessor form. **CLOSED by N14** (Wave 8 Part One) — the once-deterministic mode
  commits to the first solution and checks it once, deterministically. N10 is closed too.
- **N13 — the test goal's cost and purity are the caller's responsibility, unchecked.**
  The contract calls the membership-test goal on every call and trusts it to be cheap
  and side-effect-free; nothing enforces that a named test goal does not mutate state or
  run expensively. Documented as an expectation, but a genuinely destructive or costly
  test goal would silently break the "a check may run on every call" assumption. The
  minimum remedy is a purity/determinism lint or a `\+ \+`-guarded call mode. Recorded,
  not closed.

---

## Wave 8, Part One — the membership contract once-deterministic mode (2026-07-19)

Branch `feature/wave-8-once-mode`. Rollback tag `pre-wave-8-once`. All work
**additive**; the ARC-AGI solving core was **not** modified, and only the
`membership_contract` pack changed. Baseline gates held unchanged: mini ARC-AGI-1
40/40, mini ARC-AGI-2 12/12, conformance 107/107, L4 and N6 with 0 violations, and
BOTH existing membership forms — the plain-list (N8) and the accessor (N11: test-goal
and producer) — byte-for-byte in behaviour (their 20 tests pass unchanged). This is
the enforce-then-build Part One of Wave 8: the once mode lands before the cerebellum
and amygdala regions rest on it.

### N14 — an opt-in once-deterministic mode for the membership contract · S=M · **DELIVERED** (closes N12 / N10, WP-428)

- **The gap (N12, subsuming N10).** The contract checks the membership property on
  EVERY solution the guarded predicate produces. That is right for a predicate that
  yields one answer, but a predicate that GENERATES several candidates on backtracking
  and COMMITS one (a selector; a corrector) wants the guarantee on the COMMITTED
  answer, not a throw partway through its backtracking. There was no once/deterministic
  mode.
- **What was delivered (the minimum that closes it).** An additive ONCE mode on the
  `membership_contract` pack (WP-428), expressed as a MODE ARGUMENT on the enforce
  entry points (not a parallel predicate set): `membership_contract_enforce/5`,
  `membership_contract_enforce_goal/5`, and `membership_contract_enforce_producer/5`
  each take a trailing `+Mode` (`per_solution` — the unchanged default — or `once`),
  plus `membership_contract_declared_mode/2`. A single shared installer,
  `membership_contract_wrap_mode/4`, emits either the base `( original, check )`
  wrapper or a `once(( original, check ))` wrapper. In once mode the guarded predicate
  commits to its FIRST solution, that committed output is checked once, and the
  predicate is left deterministic. Because SWI-Prolog's `once/1` does not catch
  exceptions, a non-member first solution still throws the base glass-box violation —
  commit-to-first is enforced by construction. Once plus the test-goal accessor form
  materialises no set. Depends only on SWI-Prolog standard libraries; no
  Lattice/actors/Causalontology/Connectome dependency. The base `/4` entry points and
  every check/holds predicate are unchanged and shared by both modes — one construct
  with an option.
- **Honest scope.** Once mode commits to the first solution; it is NOT a
  find-the-first-member search over solutions. That larger feature was declined and
  recorded (see the new gap below), per the order's "record the temptation as a
  finding" instruction.
- **Selector-like re-expression.** A PrologAI-side test (`once_selector_reexpression`)
  shows a predicate that generates several candidates and commits one obtains the
  committed-output guarantee by declaring once mode, with no caller-supplied `once/1`.
  No Connectome repository was touched.
- **Evidence / tests.** 9 `AC-N14-*` PLUnit tests added (suite now 29: 9 plain-list +
  11 accessor unchanged + 9 once), gated by the existing
  `.github/workflows/membership-contract.yml` (it runs the whole suite). Documented in
  `docs/membership-contract.md`; SPARC volumes bumped (Specification v413→v414,
  Pseudocode v404→v405, Architecture v406→v407, Refinement v465→v466, Completion
  v471→v472; the Demonstration volume left unchanged, as a language-level mode does not
  change how PrologAI is demonstrated); Tutorial chapter 363 added.
- **Closing commit.** Recorded in the squash-merge of `feature/wave-8-once-mode` to
  main.
- **N12 status: CLOSED (and N10, which N12 subsumed).** The supported modes are
  `per_solution` (default) and `once`, on both the plain-list and accessor forms.

### New gap discovered while building it (be greedy)

- **N15 — no find-first-member (filtering) mode.** Once mode commits to the FIRST
  solution and refuses it if it is a non-member, even when a LATER solution would be a
  member. A predicate that legitimately wants "the first SOLUTION THAT IS A MEMBER,
  skipping non-members" has no mode for it — that is a solution-filtering search, a
  larger feature deliberately not built here (it risks growing the contract into a
  general solution-selection framework). The minimum remedy, if a future region needs
  it, is a distinct `find_member` mode that backtracks the guarded predicate until the
  check passes or solutions are exhausted, kept membership-specific. Recorded, not
  closed.

---

## Wave 10, Stage 1 — adopt Causalontology 3.0.0 into PrologAI (2026-07-19)

Branch `feature/wave-10-stage-1-adopt-causalontology-3-0-0`. Rollback tag
`pre-wave-10-stage-1`. Additive; the ARC-AGI solving core was NOT modified.
Wave 10 turns the program from DISCOVERING requirements to IMPLEMENTING the
consolidated Ledger; Stage 1 is the spine.

### STAGE-1 — PrologAI now rests on Causalontology 3.0.0 · **DELIVERED** (closes no gap; the foundation)

- **What was delivered.** PrologAI adopts Causalontology 3.0.0 (shipped in Wave
  9.5). The vendored conformance suite under
  `tests/causalontology_conformance/` was re-vendored from the causalontology
  repository at its 3.0.0 commit `98ebb33`: the 107-vector 2.0.0 set became
  the **119-vector 3.0.0 set** (V01–V119, adding V108–V119 for the tick unit, the
  cross_stratal_seam kind, and realized_by), and the 17 schemas became **18**
  (adding `cross_stratal_seam.schema.json`; the tick unit and realized_by amend
  the CRO/token_causal_claim and conduit schemas). The `causal_core` vocabulary
  pack was additively extended to make the three elements USABLE: the ordinal
  `ticks` temporal unit (a disjoint dimension — integer-ordered, no wall-clock
  mapping, to_seconds refuses it), the eighteenth kind `cross_stratal_seam` (its
  identity fields, Algorithm F / `causal_core_seam_wellformed`, the coarsest-
  stratum `causal_core_seam_home`, and the drawn-chain contradictory-seam rule),
  and the conduit `realized_by` identity-bearing field. This is adoption
  plumbing, not new runtime cognition.
- **Gate.** `bin/run_causalontology_conformance.sh` green at **119/119** (the 107
  originals preserved plus 12 new); the mini-regression unmoved at **40/40 and
  12/12**; L4/N6/N8/N11/N14 and the closure hybrid unchanged. Every existing
  eighteen-kind record still validates.
- **Closes.** Nothing on its own — it is the foundation. It moves the structure
  halves of Themes A, B, and C from "blocked on adoption" to "buildable", so
  Stage 3 (temporal enactment), Stage 4 (the managed seam), and Stage 5
  (structure-to-dynamics) may now proceed. Stage 2 (affect) may overlap.
- **Pinned Causalontology.** commit `98ebb33` (specification 3.0.0). The
  standard is FROZEN for the whole of Wave 10; only this stage's read-only
  adoption touches it.
