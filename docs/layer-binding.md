# Binding a pack's layer to its stratum ordinal (Ledger N6)

This construct extends the strict layer rule (see [`layer-rule.md`](layer-rule.md),
Ledger entry L4). L4 lets a pack declare its layer and checks that no lower-layer
pack depends on a higher-layer one. This construct adds one more thing: a
stratum-primary pack can declare the **stratum** it represents, and the checker
verifies that its declared layer is **consistent with that stratum's ordinal**.
It closes the strata arm's finding STRATA-3, promoting an alignment that used to
be maintained by hand into a checked, load-time invariant.

## Why it exists

The Wave 3 granularity experiment decided the Connectome should be carved one
pack per stratum, because then the pack layers track the Causalontology stratum
ordinals and the strict layer rule falls out of the data layer for free. But
"pack layer tracks stratum ordinal" was, until now, only a convention: L4 checks
that layers are **ordered** correctly, not that a layer **matches the ordinal it
is supposed to**. A single mis-declared layer would silently break the alignment,
and L4 would not notice.

Worse, a mis-declared layer can **disguise** an upward dependency as a downward
one. If a coarse stratum (a high ordinal) is given a low layer, a genuine
ordinal-upward import looks layer-downward, and L4 passes it. This binding closes
exactly that loophole.

## How a pack declares its stratum

A stratum-primary pack states, in its own `pack.pl` beside `layer(N)`, the
whole-word label of the stratum it embodies — the same label that stratum carries
in the Causalontology structure records:

```prolog
% State the fact: layer(2) — this pack sits at the macromolecular level.
layer(2).
% State the fact: stratum(macromolecular) — the stratum this pack represents.
stratum(macromolecular).
```

The declaration lives in the pack, so it cannot drift into an external registry.
It is one cheap fact; a pack that does not declare a stratum is simply
**unbound** (see below), never in error.

## Where the ordinals come from

The ordinal of each stratum is **not** typed by hand into the pack. It is read
from the authoritative place stratum ordinals already live: the Causalontology
stratum records. `layer_stratum_ordinals/2` takes a strata-source directory,
reads every JavaScript Object Notation (JSON) record in it, keeps the ones whose
kind is `stratum`, and returns each stratum's `label` paired with its `ordinal`.
Because the ordinal is read from the record, a pack cannot claim an ordinal the
data disagrees with.

For a Connectome repository, the strata source is that repository's own
`structure/` directory of minted records.

## The consistency rule: order-preserving, not equality

The rule is **order-preserving**, not equality. Stratum ordinals are sparse (in
the vertical slice: 4, 6, 7, 9, 14) while layer numbers are dense (0, 1, 2, …),
so a pack's layer is not required to equal its stratum's ordinal. What is required
is that the layer assignment and the stratum ordering **agree in direction and in
ties**. For any two bound packs A and B:

- if A's stratum ordinal is **lower** than B's, A's layer must **not be higher**
  than B's;
- if A's and B's stratum ordinals are **equal**, their layers must be **equal**.

A pair that breaks either clause is a **binding violation**, reported on one
readable line naming both packs, their layers, their strata, and those strata's
ordinals — for example:

```
binding_rule violation (coarser_stratum_has_lower_layer): pack 'pack_sneaky_high'
(layer 0, stratum 'high_stratum' ordinal 14) and pack 'pack_sneaky_low' (layer 1,
stratum 'low_stratum' ordinal 4) — the layer order contradicts the stratum ordinal order
```

## Why a downward skip is legal but an upward edge is not

The binding checks layer/ordinal **consistency**, not dependency **gaps**. The
Connectome's cortisol channel skips from a high stratum (ordinal 14) down to a
much lower one (ordinal 4). That is a **downward** reference across a large
ordinal gap, and it is legal: the strict layer rule forbids lower-to-higher
edges, not gaps, and the two packs' layers are themselves consistent with their
ordinals, so the binding passes it too. The reverse — a low-ordinal pack
depending on a high-ordinal one — is an **upward** edge, and L4 fails it.

The binding's own contribution is to stop that upward edge being disguised as
downward. If a mis-declared layer makes an ordinal-upward import look
layer-downward, L4 is fooled and passes it, but the binding catches the
mis-declaration, because the coarse stratum was given a lower layer than a fine
one. So L4 and the binding together guarantee both that no pack depends on a
higher layer AND that the layers actually track the ordinals they claim.

## Running it

```bash
# Check a packs directory against a strata source; exit non-zero on a violation.
bin/check_layer_binding.sh <packs_dir> <strata_source_dir>

# With no arguments it checks this repository's own packs against no strata source,
# so every pack is unbound (a clean no-op) — correct for a repo that declares no strata yet.
bin/check_layer_binding.sh
```

The public predicates (from `library(layer)`):

- `layer_pack_stratum/2` — the stratum a pack declares, or `unbound`.
- `layer_stratum_ordinals/2` — read label-to-ordinal pairs from a strata source.
- `layer_bind_scan/4` — build the bound-node set and the unbound-gap list.
- `layer_binding_violations/2` — the pure, order-preserving violation core.
- `layer_binding_violation_line/2` — render one violation as a readable line.
- `layer_bind_check_dir/3` — violations for a packs dir against a strata source.
- `layer_bind_report_dir/2` — print bound packs, unbound gaps, and violations.
- `layer_bind_enforce_dir/3` — enforce at load time in `strict` or `report` mode.

## Strict versus reporting mode

Like the strict layer rule, the binding is a load-time property with two
enforcement modes, so it can be adopted incrementally rather than by a flag day:

- `layer_bind_enforce_dir(PacksDir, StrataSource, strict)` **throws** on any
  binding violation, so a `:- initialization(...)` refuses to finish loading a
  mis-bound configuration.
- `layer_bind_enforce_dir(PacksDir, StrataSource, report)` **lists** the
  violations without refusing, so a codebase can turn the binding on and clean up
  gradually.

## Unbound packs are gaps, not errors

A pack that declares a layer but **no** stratum is **unbound**. It is reported as
a gap to fill, exactly as an undeclared layer is under L4 — never as an error that
breaks a working build. This is what makes the binding safe to adopt incrementally:
adding the construct to a repository that has not yet declared any strata changes
nothing, and each pack can be bound one at a time.

## Continuous Integration

The binding is gated by the additive workflow `.github/workflows/layer-binding.yml`,
which runs `bin/check_layer_binding.sh` against a consistent fixture (which must
pass) and a mis-bound fixture (which must be caught), and runs the layer
construct's test suite. It is separate from, and does not alter, the L4
`layer-rule` workflow.

## Limits, stated honestly

The ordinal is read from the structure-record artifacts, not from a pack's own
stratum-minting code, because reading it from the code would mean running the pack
inside a load-time checker. So if a stratum's ordinal changes in the minting code
but the structure records are not regenerated, the binding checks against stale
ordinals. That follow-on gap is recorded as Ledger entry N7. The binding also
enforces itself only for packs that opt in by declaring a stratum; adoption across
a codebase is incremental, as it is for the strict layer rule itself.
