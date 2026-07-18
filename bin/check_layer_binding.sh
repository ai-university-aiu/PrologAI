#!/usr/bin/env bash
# check_layer_binding.sh — gate the LAYER-TO-STRATUM BINDING (Ledger entry N6).
#
# The strict layer rule (L4) checks that pack layers are ORDERED correctly. This
# additional gate checks that a stratum-primary pack's declared layer is
# CONSISTENT with the ordinal of the stratum it declares — an order-preserving
# correspondence, not equality (stratum ordinals are sparse; layers are dense).
# It closes the strata arm's STRATA-3 finding: without it, the "pack layer tracks
# stratum ordinal" alignment the Wave 3 verdict rests on is a hand-maintained
# convention that a single mis-declared layer would silently break (and L4 would
# not notice, because a mis-declared layer can disguise an ordinal-upward
# dependency as a layer-downward one).
#
# Usage: bin/check_layer_binding.sh [PACKS_DIR] [STRATA_SOURCE]
#   PACKS_DIR      a directory of packs (each with a pack.pl); default: this repo's packs/
#   STRATA_SOURCE  a directory of Causalontology stratum records (JSON) from which the
#                  authoritative stratum ordinals are read; default: none (every pack
#                  is then UNBOUND — a gap, never a violation — so the gate is a clean
#                  no-op for a repository that declares no strata yet, e.g. PrologAI itself).
#
# Exit 0 = clean (no binding violation, unbound packs are gaps); 1 = a violation; 2 = error.
set -u
# Resolve the repository root from this script's location.
cd "$(dirname "$0")/.." || exit 2
# The packs directory to check (default: this repository's own packs).
PACKS_DIR="${1:-$PWD/packs}"
# The strata source directory (default: empty, meaning no strata are known → all unbound).
STRATA_SOURCE="${2:-}"
# Build the SWI-Prolog library path so use_module(library(layer)) resolves.
LIB=""
for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
# Load the layer construct, print the binding report, and exit non-zero on any violation.
swipl -q $LIB \
  -g "use_module(library(layer)), layer_bind_report_dir('$PACKS_DIR', '$STRATA_SOURCE'), layer_bind_check_dir('$PACKS_DIR', '$STRATA_SOURCE', V), (V==[] -> halt(0) ; halt(1))" \
  -t "halt(2)" 2>&1
# Propagate swipl's exit code as the gate result.
exit $?
