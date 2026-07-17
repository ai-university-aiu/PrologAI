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
set -u
# Resolve the repository root from this script's location.
cd "$(dirname "$0")/.." || exit 2
# Build the library path over every pack so use_module(library(layer)) resolves.
LIB=""
for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
# Run the layer report, then set the exit code from the violation list.
swipl -q $LIB \
  -g "use_module(library(layer)), layer_report, layer_check(V), (V==[] -> halt(0) ; halt(1))" \
  -t "halt(2)" 2>&1
# Propagate swipl's exit code as the gate result.
exit $?
