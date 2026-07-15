#!/usr/bin/env bash
# check_pack_naming.sh — enforce the NAMING CONVENTION RULE (CLAUDE.md).
# Flags any pack whose exported/defined predicates are NOT prefixed with the
# pack's own whole-word name, and reports terse prefixes shared across packs
# (the wm world-model vs wm wallpaper-motif class of collision).
#
# Usage:   bin/check_pack_naming.sh           # scan every pack
#          bin/check_pack_naming.sh fill grid  # scan named packs only
# Exit 0 = clean; exit 1 = at least one violation (a merge blocker).
set -u
cd "$(dirname "$0")/.." || exit 2
declare -A PREFIX_OF
violations=0
scanned=0
targets=("$@")
[ ${#targets[@]} -eq 0 ] && targets=($(ls -d packs/*/ 2>/dev/null | xargs -n1 basename))
for p in "${targets[@]}"; do
  f="packs/$p/prolog/$p.pl"
  [ -f "$f" ] || continue
  scanned=$((scanned+1))
  # dominant prefix among col-0 clause heads that carry an underscore
  pre=$(grep -oE '^[a-z][a-z0-9]*_' "$f" 2>/dev/null | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
  [ -z "$pre" ] && continue          # no underscored predicates (e.g. tiny fact pack)
  PREFIX_OF["$pre"]="${PREFIX_OF[$pre]:-} $p"
  # OK iff the pack name (plus underscore) starts with, or equals, the prefix
  case "${p}_" in
    "$pre"*) : ;;                     # pack-qualified — good
    *) violations=$((violations+1))
       stub="${pre%_}"
       kind="mismatched"
       [ ${#stub} -le 3 ] && kind="TERSE"
       echo "VIOLATION [$kind]  pack '$p' uses predicate prefix '${pre}' (should be '${p}_')" ;;
  esac
done
echo "---"
# collision report
collisions=0
for pre in "${!PREFIX_OF[@]}"; do
  set -- ${PREFIX_OF[$pre]}
  if [ "$#" -gt 1 ]; then collisions=$((collisions+1)); echo "COLLISION  prefix '${pre}' shared by:$(printf ' %s' "$@")"; fi
done
echo "---"
echo "scanned=$scanned  violations=$violations  colliding_prefixes=$collisions"
[ "$violations" -eq 0 ] && exit 0 || exit 1
