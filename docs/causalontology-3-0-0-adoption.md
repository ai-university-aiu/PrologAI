# Adopting Causalontology 3.0.0 (Wave 10, Stage 1, WP-429)

PrologAI rests on the Causalontology data-structure standard. Wave 9.5 shipped
**Causalontology 3.0.0** — a coordinated major release adding three schema
elements the PrologAI Requirements Ledger named. Wave 10 Stage 1 is PrologAI's
**adoption** of 3.0.0: it does not change the standard (the standard is frozen for
the whole of Wave 10); it re-vendors the 3.0.0 conformance suite and makes the
three new elements usable from PrologAI's vocabulary layer.

## What changed

- **The vendored conformance suite** under `tests/causalontology_conformance/`
  went from the **107**-vector 2.0.0 set to the **119**-vector 3.0.0 set
  (V01–V119). The twelve new vectors (V108–V119) cover the ordinal tick unit
  (V108–V111), the cross-stratal seam (V112–V116), and `realized_by`
  (V117–V119). The schemas went from **17** to **18** (the new
  `cross_stratal_seam.schema.json`, plus the amended `causal_relation_object`,
  `token_causal_claim`, and `conduit` schemas). Vendored from the causalontology
  repository at its 3.0.0 tag.

- **`causal_core` (the vocabulary pack)** was additively extended so the three
  elements are usable:
  - **The ordinal `ticks` temporal unit.** A discrete, dimensionless step with no
    wall-clock mapping. `causal_core_dimension/2` names it `ordinal`;
    `causal_core_to_seconds/3` **refuses** it (a category error);
    `causal_core_admissible/3` orders a tick window by integer comparison of tick
    counts; and a tick window and a wall-clock window are disjoint dimensions that
    never overlap and across which no delay is within.
  - **The eighteenth kind `cross_stratal_seam`.** Its identity-bearing fields
    (`source`, `target`, `mechanism_status`, optional `chain`) are registered in
    `causal_core_identity_fields/2`; **Algorithm F**
    (`causal_core_seam_wellformed/4`) checks non-adjacency, the intervening +
    strictly-monotone drawn chain, and the contradictory-seam rule (a drawn chain
    forbids `mechanism_status` `absent`); and `causal_core_seam_home/4` gives the
    home rule (the coarsest, greater-ordinal, endpoint stratum).
  - **The conduit `realized_by` reference.** An optional, identity-bearing,
    scheme-qualified reference to the native law or signal that realizes a
    conduit's transform; registered in `causal_core_identity_fields(conduit, ...)`.

## The gate

- `bin/run_causalontology_conformance.sh` exits 0 at **119/119** (the 107
  originals preserved, plus the 12 new). Run it in Continuous Integration by
  `.github/workflows/causalontology-conformance.yml`.
- The mini-regression (`bin/run_mini_regression.sh`) is unmoved at **40/40 and
  12/12**; the ARC-AGI solving core was not touched; L4, N6, N8, N11, N14, and the
  closure hybrid are unchanged.

## What this unblocks

Stage 1 closes no Requirements-Ledger gap on its own — it is the foundation. With
3.0.0 adopted, the PrologAI constructs that consume the three schema elements can
now be built: **Stage 3** (temporal enactment, on the tick unit), **Stage 4** (the
managed cross-stratal seam), and **Stage 5** (structure-to-dynamics, on
`realized_by`). **Stage 2** (affect) may overlap, as it barely touches the schema.
