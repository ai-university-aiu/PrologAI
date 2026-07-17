#!/usr/bin/env bash
# run_mini_regression.sh — the 10 percent ARC-AGI mini regression spot-check.
#
# STANDING WAVE GATE. This runs ONLY the fixed manifest tasks:
#   ARC-AGI-1  40 of 400 tasks  (tests/mini_regression/manifest_arc_agi_1.txt)
#   ARC-AGI-2  12 of 120 tasks  (tests/mini_regression/manifest_arc_agi_2.txt)
# Exit 0 iff ARC-AGI-1 is 40/40 AND ARC-AGI-2 is 12/12; any failure exits
# non-zero. It prints a glass-box report: which tasks ran, the counts, and a
# plain statement that this is a 10 percent spot-check with the full
# regression deferred.
#
# ADDITIVE: this harness sits BESIDE the full ARC-AGI benchmark runners in the
# Mentova repository. It does not modify, replace, or disable them. It loads
# the SAME solving core and the SAME task facts and dispatches to the SAME
# per-task attempt predicates the full runners use.
#
# HONESTY: a green mini run detects GROSS breakage only. A regression confined
# to the untested 90 percent of tasks passes this gate and is caught only by
# the final FULL regression. A green mini run MUST NOT be used to assert,
# re-assert, or refresh the 400/400 or 120/120 claims anywhere. Those claims
# rest on the last FULL run only. See REGRESSION_DEBT.md.
set -u
# Resolve the repository root from this script's location.
cd "$(dirname "$0")/.." || exit 2
# Export the PrologAI root so the driver resolves packs from this checkout.
export PROLOGAI_HOME="$PWD"
# Resolve the Mentova checkout: honour MENTOVA_HOME, else guess a sibling, else the local default.
if [ -z "${MENTOVA_HOME:-}" ]; then
  # Try a Mentova checkout beside the PrologAI checkout.
  if [ -d "$PWD/../Mentova" ]; then
    # Use the sibling checkout, normalised to an absolute path.
    export MENTOVA_HOME="$(cd "$PWD/../Mentova" && pwd)"
  else
    # Fall back to the local development path.
    export MENTOVA_HOME="/home/ccaitwo/Mentova"
  fi
fi
# Report which Mentova checkout the ARC solving core will be loaded from.
echo "Mentova core (read-only): $MENTOVA_HOME"
# Locate the mini regression driver and its two committed manifests.
DRIVER="tests/mini_regression/mini_regression_driver.pl"
MANIFEST1="tests/mini_regression/manifest_arc_agi_1.txt"
MANIFEST2="tests/mini_regression/manifest_arc_agi_2.txt"
# Record the wall-clock start so the report can state how fast the mini run is.
START=$(date +%s)

# Print the banner naming this run and its deliberate blind spot.
echo "==============================================================="
echo " PrologAI Mini Regression — 10 percent ARC-AGI spot-check"
echo "==============================================================="
echo " Standing wave gate: ARC-AGI-1 40/400, ARC-AGI-2 12/120."
echo " Detects GROSS breakage only; blind to the untested 90 percent."
echo " Full regression is DEFERRED (see REGRESSION_DEBT.md); the"
echo " 400/400 and 120/120 claims rest on the last FULL run only."
echo "==============================================================="

# Run the ARC-AGI-1 spot-check in its own swipl process; capture exit code.
swipl -q -g "run_mini(arc1,'$MANIFEST1')" -t "halt(2)" "$DRIVER"
RC1=$?
# Run the ARC-AGI-2 spot-check in its own swipl process; capture exit code.
swipl -q -g "run_mini(arc2,'$MANIFEST2')" -t "halt(2)" "$DRIVER"
RC2=$?

# Compute the elapsed wall-clock time for the whole mini run.
END=$(date +%s)
ELAPSED=$((END - START))

# Print the combined gate summary.
echo ""
echo "==============================================================="
echo " Mini Regression Summary"
echo "==============================================================="
# Report the ARC-AGI-1 gate result from its exit code (0 = 40/40).
if [ "$RC1" -eq 0 ]; then echo " ARC-AGI-1 : PASS  40/40"; else echo " ARC-AGI-1 : FAIL  (exit $RC1, not 40/40)"; fi
# Report the ARC-AGI-2 gate result from its exit code (0 = 12/12).
if [ "$RC2" -eq 0 ]; then echo " ARC-AGI-2 : PASS  12/12"; else echo " ARC-AGI-2 : FAIL  (exit $RC2, not 12/12)"; fi
# Report the wall-clock time for the mini run.
echo " Wall clock: ${ELAPSED}s"
# Restate the honest scope so no reader mistakes a green mini for a full run.
echo " Scope     : 10 percent spot-check; full regression DEFERRED."
echo "             Green here does NOT refresh the 400/400 or 120/120 claims."
echo "==============================================================="

# The gate passes only when BOTH spot-checks were fully green.
if [ "$RC1" -eq 0 ] && [ "$RC2" -eq 0 ]; then
  # Announce the green gate and exit success.
  echo " MINI REGRESSION: GREEN — ARC-AGI-1 40/40, ARC-AGI-2 12/12 (10 percent spot-check; full regression deferred)."
  exit 0
else
  # Announce the red gate and exit failure.
  echo " MINI REGRESSION: RED — gross breakage detected; run the full regression."
  exit 1
fi
