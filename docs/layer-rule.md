# The Strict Layer Rule — declare, check, enforce

*Where a newcomer should look to understand how PrologAI keeps its dependency
graph acyclic, and how to bring a pack into the rule.*

---

## What the rule is, and why

PrologAI is built like a building: every pack sits on a numbered **layer**, and
a pack may depend only on packs at **strictly lower** layers. A layer-N pack may
call into any pack below N; it may not call a pack at its own level or above.

The payoff is a guarantee, not a convention: the static import graph is
**acyclic**. Packs build from the bottom up, each new pack resting on a fully
tested foundation, and no cycle of dependencies can form. That acyclicity is
what lets 299 packs compose without a load-order tangle.

Until Wave 1 this rule was honoured by convention only — no pack could *declare*
its layer, nothing *checked* the rule, and no violation was ever *reported*. The
`layer` pack (WP-426, itself at layer 0) makes the rule first-class: declare,
check, enforce.

---

## How a pack declares its layer

A pack states its layer with a single `layer(N)` fact in its own `pack.pl`
manifest, beside `name/1`, `version/1`, and `requires/1`:

```prolog
% State the fact: layer(0) — base infrastructure, may depend on nothing above.
layer(0).
```

The declaration lives **inside the pack**. There is no external registry to keep
in sync, so a pack's layer cannot drift away from the pack itself.

`N` is a non-negative integer. Lower numbers are deeper foundations (the `layer`
pack and the `lattice` pack are at 0; the `actors` pack is at 1).

---

## How to run the checker

```bash
bin/check_layers.sh
```

The script builds the library path over every pack, then runs the checker over
the **actual** `use_module(library(...))` import graph parsed from every pack's
real source — not a declared `requires` list, so a stale manifest cannot hide a
real edge. It prints a report and sets its exit code:

- **exit 0** — clean: no upward edges among declared packs.
- **exit 1** — at least one violation.
- **exit 2** — could not run (e.g. SWI-Prolog missing).

It runs in Continuous Integration (CI) on every push and pull request
(`.github/workflows/layer-rule.yml`); a red run blocks the merge.

---

## Strict mode vs reporting mode — and when to use each

The construct enforces at load time through `layer_enforce/1`:

- **`layer_enforce(strict)`** — prints the report and then **throws**
  `error(layer_rule_violation(Violations), _)` if any violation is present, so a
  `:- initialization(layer_enforce(strict))` **refuses to finish loading** a
  violating configuration. Use strict mode for a subsystem whose packs are all
  declared and must never regress: a bad edge fails the load loudly.
- **`layer_enforce(report)`** — prints the same report but **never refuses**.
  Use report mode while adoption is still spreading: you see the violations and
  the gaps without breaking a working build.

`layer_enforce_dir/2` is the same enforcement over an explicit packs directory
(`layer_enforce_dir(+PacksDir, +Mode)`); `layer_enforce/1` is simply
`layer_enforce_dir` over the repository's own `packs/`.

---

## How undeclared packs are treated (and why adoption is incremental)

A pack with **no** `layer(N)` fact is **UNDECLARED**. Undeclared is a **gap to
fill, never an error**. The checker lists undeclared packs so you know what is
left to bring in, but it never fails the build over one. Only an edge between
**two declared packs** can be a violation.

This is deliberate. Assigning a correct layer to a pack is a real judgement about
where it sits in the dependency order; getting it wrong is worse than leaving it
undeclared. So the rule is adopted **incrementally** — pack by pack, each layer
assigned when it is understood — and a working build is never broken by a pack
that has not yet been placed. Do **not** mass-declare layers to make the checked
count look larger; a guessed layer is a future false guarantee.

---

## How to read a violation line

Each violation prints as one readable, glass-box line naming the rule, both
packs, both layer numbers, and the exact import that breaks the rule:

```
layer_rule violation: pack 'base' (layer 0) depends on higher pack 'cortex' (layer 3) via use_module(library(cortex))
```

Read it as: *the low pack `base` (layer 0) imports the higher pack `cortex`
(layer 3), which the rule forbids.* The fix is always one of three: lower the
target's layer if it truly is a deeper dependency, raise the source's layer if
it truly sits above, or remove the upward import.

---

## Adoption reality — stated plainly

The layer construct is **live and gated in CI**. But honesty about what a green
badge currently means:

- **3 of 299 packs declare a layer** today (`layer` and `lattice` at layer 0,
  `actors` at layer 1). The remaining **296 packs are undeclared gaps** — not
  violations, but not yet checked either.
- Because only three packs are declared, a passing check verifies **only those
  three**. The suite's `test(repo_is_clean)` passes, but with 296 packs
  unplaced it is currently a check over a small declared core, not over the whole
  library.
- **Adoption is deliberately incremental** (see the section above). Until many
  more packs carry a `layer(N)` fact, the rule **guarantees little in practice** —
  it guarantees the declared packs, and reports the rest as gaps.

The remedy is not to inflate the number by guessing: it is a standing adoption
program that assigns and declares layers pack by pack, using the checker's own
gap list as the worklist (Ledger **N3**). The construct is correct; adoption is
the work that remains.

---

## See also

- [`docs/lattice-hybrid-pattern.md`](lattice-hybrid-pattern.md) — how a runtime
  loop is closed *under* this rule by demoting the reentrant edge out of the
  static import graph.
- `LEDGER.md` — Wave 1 entry **L4** (this construct) and **N3** (the adoption
  gap).
- `packs/layer/prolog/layer.pl` — the construct itself, with its full public
  predicate list.
