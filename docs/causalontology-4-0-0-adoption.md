# Adopting Causalontology 4.0.0 (2026-07-22)

PrologAI rests on the Causalontology data-structure standard. **Causalontology
4.0.0** is a coordinated major release adding the standard's first three
**mental-life kinds** — what an agent believes, what an agent expects, and how
wrong an expectation turned out to be. This change is PrologAI's **adoption** of
4.0.0: it does not change the standard; it re-vendors the 4.0.0 conformance
suite and makes the three new kinds usable from PrologAI's vocabulary layer.

## What changed

- **The vendored conformance suite** under `tests/causalontology_conformance/`
  went from the **119**-vector 3.0.0 set to the **137**-vector 4.0.0 set
  (V01–V137). The eighteen new vectors cover the predicted occurrence
  (V120–V123), the prediction error (V124–V127), the attitude (V128–V135), the
  frozen-identifier re-pin (V136), and the whole-word-scheme rejection of
  `att:`/`prd:`/`err:` (V137). The schemas went from **18** to **21** (the new
  `attitude.schema.json`, `predicted_occurrence.schema.json`, and
  `prediction_error.schema.json`, plus the amended `assertion` schema, whose
  `about` pattern now names the three new kinds AND the `cross_stratal_seam` — a
  3.0.0 drift the major version repairs). Vendored from the causalontology
  repository at commit `64b1d1a105f91b5fb45df98d0b6583a5ab9e8769` (main at tag
  `v4.0.0`).

- **`causal_core` (the vocabulary pack)** was additively bumped **1.0.0 →
  1.1.0** so the three kinds are usable:
  - **`attitude` (the nineteenth kind).** A first-class propositional attitude —
    what a holder's mind CONTAINS, never what is true: a `holder` (a modeled
    continuant or token individual, never a signing key — Rule 25 keeps the
    holder of an attitude distinct from the SOURCE that signs an assertion about
    it), a CLOSED `attitude_type` enumeration (`believes`, `desires`, `intends`,
    `knows`, `expects`, `fears`), and a `content` reference by identity to ANY
    content object — which may be FALSE (a believed relation that contradicts
    the actual record raises NO conflict: the quarantine that makes a false
    belief first-class and shareable) and may itself be another attitude
    (nesting). Per Principle P4 an attitude bears no strength; it is asserted,
    graded, and retracted through the ordinary provenance layer. Identity row:
    `holder`, `attitude_type`, `content`.
  - **`predicted_occurrence` (the twentieth kind).** A forecast: `instantiates`
    (the occurrent type), an `interval` carrying EXACTLY ONE temporal dimension
    (a wall-clock `start` or an ordinal `start_tick` — Rule 24: both is a
    `dimension_conflict`, neither a `missing_dimension`, both enforced as local
    clauses in `causal_core_semantic_error/3`), the `predictor`, and an OPTIONAL
    `strength` that is identity-bearing when present. A forecast is NOT a
    report — it identifies under the `predicted_occurrence` scheme, never as a
    `token_occurrence`. Identity row: `instantiates`, `interval`, `predictor`,
    `strength`.
  - **`prediction_error` (the twenty-first kind).** The grade of a prediction:
    the `predicted` reference, an OPTIONAL `observed` token occurrence (absent
    when the prediction went unfulfilled), and a SIGNED `discrepancy`, with the
    Rule 24 pairing rule that an observed token must instantiate the occurrent
    the prediction named. Identity row: `predicted`, `observed`, `discrepancy`.
  - A dict of one of the three new kinds names its kind with an explicit `type`
    field; no shape heuristic was added, and the existing heuristics for the
    eighteen earlier kinds are untouched.

- **The additive harness layers** follow: `schema_check.pl` interprets the
  twenty-one schemas, `store.pl` accepts the three new content kinds, and
  `run_conformance.pl` ports the reference runner's `v120()`–`v137()` semantics
  exactly. The in-pack suite `test_causal_core.pl` grows from thirteen to
  nineteen tests (a new `co_core_causalontology_4_0_0` block).

## The gate

- `bin/run_causalontology_conformance.sh` exits 0 at **137/137** (the 119
  earlier vectors preserved, plus the 18 new). Run in Continuous Integration by
  `.github/workflows/causalontology-conformance.yml`.
- The frozen earlier identifiers **re-pin byte-for-byte** (V136), so 4.0.0 is
  identity-preserving: everything already stored keeps its identity.
- Pack tests and the naming gate are green; the ARC-AGI solving core was not
  touched. Per the standing benchmark-honesty rule (`REGRESSION_DEBT.md`):
  mini regression green: ARC-AGI-1 40/40, ARC-AGI-2 12/12 (10 percent
  spot-check; full regression deferred).

## What this enables

The three kinds give the glass-box cognitive packs a standard, content-addressed
way to record a mind's own stance: `theory_of_mind` and `imagination` gain a
first-class, quarantined false belief; `world_model`, `verification`, and
`curiosity` gain a reified forecast and its graded error — the raw material of
learning from surprise — all speakable through the shared store like any other
Causalontology record.
