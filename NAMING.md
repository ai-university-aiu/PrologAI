# Naming conventions

PrologAI's public naming conventions. These keep the codebase glass-box: an
identifier says what it is, in whole English words, so a justification tree
reads like prose.

## Whole words, never abbreviations

- **Pack names** are lowercase `snake_case` whole words: `world_model`, not
  `wm` or `worldmodel`; `active_inference`, not `actinf`; `jacobian_space`, not
  `jspace`.
- **Predicates** are pack-qualified whole-word `snake_case`: `fill_flood/4`, not
  `fl_flood/4`; `grid_size/3`, not `gd_size/3`. The pack prefix makes every
  predicate globally unique and kills cross-pack collisions (`wm_` once meant
  both world-model and wallpaper-motif). A new pack ships pack-qualified from
  its first commit — no grace period, no temporary short prefix.
- **One allowance:** a branded concept name may persist in PROSE while its code
  identifiers are pack-qualified (the "J-Space" concept in the papers; the pack
  and predicates are `jacobian_space` / `jacobian_space_`).

## The causal-relation primitive: `causal_relation_object`

The reified Causal Relation Object is spelled **`causal_relation_object`** in
full — the `causal_relation_object/8` functor, the `causal_core_…`,
`world_model_…`, and related predicates, the `causal_relation_object_` id
prefix, and prose alike. The former abbreviation **`cro` is retired** and no
longer appears in code or prose. This aligns PrologAI with the Causalontology
standard's whole-word Principle P7 (every identifier scheme is one whole English
word); it is a deliberate exception to the prose-persistence allowance above.

## Alignment with the Causalontology standard

The `causal_core`, `noun_backbone`, and `realizable_hinge` packs implement the
Causalontology vocabulary. Its seventeen object kinds are whole words —
`occurrent`, `continuant`, `realizable`, `causal_relation_object`, `quality`,
`stratum`, `bridge`, `port`, `conduit` (type tier); `token_individual`,
`token_occurrence`, `state_assertion`, `token_causal_claim` (token tier);
`assertion`, `enrichment`, `retraction`, `succession` (provenance). The full
mapping and the field renames (`dmin` → `minimum_delay`, `dmax` →
`maximum_delay`) live in the standard's own
[NAMING.md](https://github.com/ai-university-aiu/causalontology/blob/main/NAMING.md).

## Conformance to Causalontology specification 2.0.0

**PrologAI implements Causalontology specification 2.0.0 and passes all 107
conformance vectors (V01–V107).** The standard's own conformance rule is that
an implementation is conformant if and only if it passes every vector for the
version it declares; PrologAI declares 2.0.0 and passes 107/107.

The vectors are vendored under
[`tests/causalontology_conformance/vectors/`](tests/causalontology_conformance/vectors/),
copied from the causalontology repository at commit
`8991c8b5ef12e998ff932855fabe29edf4cc16cc` (the whole-word 2.0.0 baseline), with
the seventeen JSON schemas under
[`tests/causalontology_conformance/schema/`](tests/causalontology_conformance/schema/).
The harness (`tests/causalontology_conformance/run_conformance.pl`) drives the
`causal_core`, `noun_backbone`, and `realizable_hinge` vocabulary packs across
every vector, exercising:

- **canonicalization** — RFC 8785 (JSON Canonicalization Scheme);
- **content identity** — SHA-256 over the identity-bearing bytes of each kind;
- **schema validity** — for all seventeen kinds, against the vendored schemas;
- **local semantic rules** — acyclicity, temporal admissibility, refinement,
  the conflict test, and the enrichment field table;
- **the five normative algorithms** (Section 12) — bridge closure, bridged
  reachability (the amended Rule 7), stratal classification, the skip decision,
  and unit normalization;
- **provenance** — Ed25519 (RFC 8032) record signing and verification,
  retraction lineage, and succession, implemented in pure Prolog.

The conformance engine (canonicalization, identity, semantics, and the five
algorithms) lives in the `causal_core` vocabulary pack; schema interpretation,
signing, and the in-memory store are additive harness layers that import none of
the ARC grid/ILP/sequence packs. Nothing pending: the full suite passes.

Run it with `bin/run_causalontology_conformance.sh` (exit 0 iff 107/107).

## Exempt external proper names

Whole-word spelling governs PrologAI's own identifiers. It does not rewrite the
proper names of external standards and algorithms, which are kept verbatim:
`ed25519` (Ed25519, RFC 8032), `SHA-256`, `RFC 8785` (JCS), `RFC 3339`, `UCUM`,
`UTC`, `JSON`, `JSON-LD`, `BFO`, `RO`, `PROV`. These are never abbreviated
further or re-minted.

## Enforcement

`bin/check_pack_naming.sh` enforces the pack-name, predicate-qualification, and
standard-library-shadow rules and reports zero violations across all packs.
