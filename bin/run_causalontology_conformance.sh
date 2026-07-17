#!/usr/bin/env bash
# run_causalontology_conformance.sh — run the 107 Causalontology 2.0.0
# conformance vectors (V01-V107) against PrologAI's vocabulary packs
# (causal_core, noun_backbone, realizable_hinge) plus the additive conformance
# harness. Exit 0 iff 107/107 pass. This gates Causalontology conformance in CI.
#
# The vectors are vendored under tests/causalontology_conformance/vectors/ from
# the causalontology repository at commit
# 8991c8b5ef12e998ff932855fabe29edf4cc16cc (specification 2.0.0 whole-word
# baseline). This runner does NOT load the ARC grid/ILP/sequence packs.
set -u
# Resolve the repository root from this script's location.
cd "$(dirname "$0")/.." || exit 2
# Build the library path over every pack so use_module(library(...)) resolves.
LIB=""
for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
# Run the suite in its own swipl process and echo its report.
swipl -q $LIB \
  -g "use_module('tests/causalontology_conformance/run_conformance.pl'), (co_run(F), (F==[] -> halt(0) ; halt(1)))" \
  -t "halt(1)" \
  tests/causalontology_conformance/run_conformance.pl 2>&1
# Propagate swipl's exit code as the gate result.
exit $?
