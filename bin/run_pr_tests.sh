#!/usr/bin/env bash
# run_pr_tests.sh — run the legacy tests/prNN acceptance suites and report.
# These suites live OUTSIDE packs/ and so are not in the per-pack regression;
# without this runner they drift silently (they had accumulated years of stale
# references before 2026-07-15). Each suite runs in its own swipl process with a
# per-suite timeout so one hanging integration suite cannot block the whole run.
#
# Usage:  bin/run_pr_tests.sh            # run every tests/*/*.pl
#         bin/run_pr_tests.sh pr43 pr49  # run named suites
# Exit 0 = all green; exit 1 = at least one suite failed or timed out.
set -u
cd "$(dirname "$0")/.." || exit 2
TIMEOUT="${PR_TEST_TIMEOUT:-40}"

# Build the full library path over every pack.
LIB=""
for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done

# Resolve the target suites.
if [ "$#" -gt 0 ]; then
  targets=(); for n in "$@"; do targets+=("tests/$n/test_$n.pl"); done
else
  targets=(tests/*/test_*.pl)
fi

pass=0; fail=0; timeout_n=0; failed=""
for f in "${targets[@]}"; do
  [ -f "$f" ] || continue
  pr=$(basename "$(dirname "$f")")
  timeout "$TIMEOUT" swipl $LIB -g "run_tests, halt" -t "halt(1)" "$f" >/tmp/pr_$pr.log 2>&1
  rc=$?
  if [ "$rc" -eq 124 ]; then
    timeout_n=$((timeout_n+1)); failed="$failed $pr(timeout)"
  elif grep -qiE '[0-9]+ tests failed|test .* failed|Unknown procedure|does not exist|not exported' /tmp/pr_$pr.log; then
    fail=$((fail+1)); failed="$failed $pr(fail)"
  elif grep -qE 'tests passed' /tmp/pr_$pr.log; then
    pass=$((pass+1))
  else
    fail=$((fail+1)); failed="$failed $pr(no-result)"
  fi
done
echo "tests/prNN: $pass passed, $fail failed, $timeout_n timed out.${failed:+  NON-GREEN:$failed}"
[ "$fail" -eq 0 ] && [ "$timeout_n" -eq 0 ] && exit 0 || exit 1
