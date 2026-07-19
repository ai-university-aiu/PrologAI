# The layer construct's reach — across repositories and inside packs (Wave 10 Stage 6, WP-435)

An additive extension of the [`layer`](../packs/layer/) pack that closes the Requirements
Ledger's **Theme E**: P5/P6/P7, ATOMIC-5/6/7, LOOPS-1/2/3/4, N3. No existing L4 (layer
rule) or N6 (layer-to-stratum binding) behaviour changes.

## Cross-repository reach (E-1)

The strict layer rule was single-repository: its owner map was built from one packs
directory, its layer integers were a per-repository namespace with no global coordinate,
and its CI entry point was hard-wired to PrologAI's packs.

- **A global coordinate.** `layer_global_layer(+LocalLayer, +Offset, -GlobalLayer)` lifts
  a repository's local layer numbers to a shared global coordinate by adding a
  per-repository offset (a base repo at 0, an arm stacked at 100). An undeclared layer
  stays undeclared. (P7, ATOMIC-7)
- **A unioned scan.** `layer_scan_dirs(+DirSpecs, -Nodes, -Undeclared)` — where
  `DirSpecs` is a list of `dir(PacksDir, Offset)` — unions several packs directories,
  building the owner map across the whole union so a cross-repository import is resolved
  and visible. `layer_check_dirs(+DirSpecs, -Violations)` runs the same pure violation
  core over the union, catching a cross-repository upward edge that per-repository
  namespaces hide. (P5, P6, ATOMIC-6)
- **A packs-directory argument on CI.** `bin/check_layers.sh /path/to/other/packs`
  points the checker at a downstream repository's packs directory, so it no longer needs
  its own wrapper. (P5, ATOMIC-5, LOOPS-4)
- **An adoption report.** `layer_adoption(+PacksDir, -Declared, -Total, -Fraction)`
  reports how many packs declare a layer out of the total — a number for the standing
  adoption program to move. (N3)

## Intra-pack reach (E-2)

The construct was pack-granular, so a coarse pack's internal structure fell below the
language's resolution. A sub-module is `submodule(Name, Rank, Calls, TestTarget)`.

- `layer_submodule_violations(+Submodules, -Violations)` catches an **upward call** to a
  strictly-higher-rank sub-module (`upward_call`, LOOPS-1) and a call to a sub-module
  outside the declared set (`unknown_callee`, a boundary crossing, LOOPS-2). A higher
  rank is more abstract; calls must go to an equal-or-lower rank.
- `layer_submodule_untested(+Submodules, -Untested)` reports any sub-module whose
  declared test target is `none` — an untestable internal region (LOOPS-3).
