#!/usr/bin/env bash
# check_layers.sh — enforce the STRICT LAYER RULE (Ledger entry L4).
#
# A lower-layer pack may not depend on a higher-layer one. Each pack declares
# its layer with a `layer(N)` fact in its pack.pl; this checker parses the
# ACTUAL use_module(library(...)) import graph across every pack and reports any
# pack that imports a strictly-higher-layer pack.
#
# Packs with no layer(N) fact are UNDECLARED (a gap to fill), never a violation:
# adoption is incremental and never breaks a working build.
#
# Exit 0 = clean (no upward edges among declared packs); exit 1 = at least one
# violation; exit 2 = could not run. Runs in Continuous Integration (CI).
#
# CROSS-REPOSITORY REACH (Wave 10 Stage 6, Ledger Theme E). By default the checker
# scans THIS repository's packs/ directory. A downstream repository can point the
# checker at its own packs directory by passing it as the first argument:
#   bin/check_layers.sh /path/to/other/repo/packs
# so the CI entry point is no longer hard-wired to PrologAI's own packs (P5/ATOMIC-5/
# LOOPS-4). The library path always includes THIS repo's packs so library(layer)
# resolves; the SCANNED directory is the argument when given, else this repo's packs.
set -u
# Resolve the repository root from this script's location.
cd "$(dirname "$0")/.." || exit 2
# The directory to SCAN is the first argument, or this repository's packs/ by default.
SCAN_DIR="${1:-packs}"
# Build the library path over every pack so use_module(library(layer)) resolves.
LIB=""
for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
# Run the layer report over the chosen directory, then set the exit code from the violations.
swipl -q $LIB \
  -g "use_module(library(layer)), layer_report_dir('$SCAN_DIR'), layer_check_dir('$SCAN_DIR', V), (V==[] -> halt(0) ; halt(1))" \
  -t "halt(2)" 2>&1
# Propagate swipl's exit code as the gate result.
exit $?
