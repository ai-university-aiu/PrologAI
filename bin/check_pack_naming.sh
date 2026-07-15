#!/usr/bin/env bash
# check_pack_naming.sh — enforce the NAMING CONVENTION RULE (CLAUDE.md).
# Three checks, all merge blockers:
#   (1) PREDICATE prefix — every pack's predicates must be prefixed with the
#       pack's own whole-word name (world_model_predict, not wm_predict).
#   (2) MINORITY straggler prefix — a pack may not carry a SECOND terse/retired
#       prefix cluster (the pai_ stragglers that the dominant-prefix check of
#       old versions let through: vsa carried both vsa_ and pai_).
#   (3) PACK NAME — the directory/module/manifest name must be whole words, not
#       an abbreviation (arithmetic, not arith) and not an un-underscored
#       concatenation (grid_blend, not gridblend).
#
# Usage:   bin/check_pack_naming.sh            # scan every pack
#          bin/check_pack_naming.sh fill grid  # scan named packs only
# Exit 0 = clean; exit 1 = at least one violation.
set -u
cd "$(dirname "$0")/.." || exit 2

# Abbreviation stems that may never appear as a segment of a pack name.
BANNED_STEMS=" autom seq sym xf xform nbr aggr hist dist pos op ops cmp comp inv sig hyp induct quant crypto ros mcp sona vsa a2a acp anp coocc cooccur rowcol colorop sizeop posop naggr nmode varstat symtab condxf seqinfer ruleinfer objxf objrel objbound iochan multipair multicolor vec2 xsel taskcat transformgen periodfix rowsig gridxform gridtransform "
# Retired shared prefix that must now read prologai_ (the sanctioned namespace).
RETIRED_SHARED=" pai "
# Short helper stubs that are real English words / conventional predicates and
# are fine as minority prefixes (so is_valid, eq_, id_ are not false-flagged).
GENERIC_OK=" is eq ok no id on at up in of to do go my as if "
# SWI-Prolog stdlib module names: a pack must not be named one of these, or the
# pack shadows the stdlib module on the library path (arithmetic shadowed
# library(arithmetic), breaking arithmetic_function/1). Queried live from the
# installed SWI, with a hardcoded core fallback when swipl is unavailable.
SWI_STDLIB=" $(swipl -q -g "absolute_file_name(swi(library),D),atom_concat(D,'/*.pl',P),expand_file_name(P,Fs),forall(member(F,Fs),(file_base_name(F,B),file_name_extension(N,pl,B),write(N),write(' '))),halt" 2>/dev/null) "
[ "${SWI_STDLIB// /}" = "" ] && SWI_STDLIB=" aggregate apply arithmetic assoc broadcast charsio check clpfd csv dcg debug dicts error gensym heaps http lists main option ordsets pairs pcre persistency random rbtrees readutil record settings sgml shell sort statistics strings tables table tabling terms thread ugraphs url when yall "
# Concatenation heads: a pack name starting with one of these followed by more
# letters with NO underscore is a jammed concatenation (gridblend -> grid_blend).
# Only heads that do not themselves begin a common whole word (so 'arithmetic'
# and 'object' are NOT flagged); underscore-separated names never match.
CONCAT_HEADS='^(grid|scene|multi)[a-z]{2,}$'

declare -A PREFIX_OF
violations=0
scanned=0
targets=("$@")
[ ${#targets[@]} -eq 0 ] && targets=($(ls -d packs/*/ 2>/dev/null | xargs -n1 basename))

is_banned_name() { # $1 = pack name -> 0 if the NAME is an abbreviation/concatenation
  local name="$1" seg
  # any underscore-segment that is a banned abbreviation stem
  local IFS='_'
  for seg in $name; do
    case "$BANNED_STEMS" in *" $seg "*) return 0 ;; esac
  done
  # un-underscored concatenation of a known head word plus more letters
  [[ "$name" =~ $CONCAT_HEADS ]] && return 0
  return 1
}

for p in "${targets[@]}"; do
  f="packs/$p/prolog/$p.pl"
  [ -f "$f" ] || continue
  scanned=$((scanned+1))

  # (3) pack NAME must be whole words
  if is_banned_name "$p"; then
    violations=$((violations+1))
    echo "VIOLATION [NAME]  pack '$p' is an abbreviation/concatenation (use whole words, underscore-separated)"
  fi

  # (4) pack NAME must not shadow an SWI-Prolog stdlib module
  case "$SWI_STDLIB" in
    *" $p "*)
      violations=$((violations+1))
      echo "VIOLATION [SWI-STDLIB]  pack '$p' shadows SWI stdlib library($p) (pick a distinct whole-word name)" ;;
  esac

  # collect every col-0 predicate prefix cluster with its count
  mapfile -t clusters < <(grep -oE '^[a-z][a-z0-9]*_' "$f" 2>/dev/null | sort | uniq -c | sort -rn)
  [ ${#clusters[@]} -eq 0 ] && continue
  pre=$(echo "${clusters[0]}" | awk '{print $2}')     # dominant
  PREFIX_OF["$pre"]="${PREFIX_OF[$pre]:-} $p"

  # (1) dominant prefix must be pack-qualified
  case "${p}_" in
    "$pre"*) : ;;
    *) violations=$((violations+1))
       stub="${pre%_}"; kind="mismatched"; [ ${#stub} -le 3 ] && kind="TERSE"
       echo "VIOLATION [$kind]  pack '$p' uses predicate prefix '${pre}' (should be '${p}_')" ;;
  esac

  # (2) minority straggler clusters (count >= 2) that are terse / retired / banned
  for c in "${clusters[@]}"; do
    cnt=$(echo "$c" | awk '{print $1}'); cpre=$(echo "$c" | awk '{print $2}')
    [ "$cpre" = "$pre" ] && continue                  # skip the dominant one
    [ "$cnt" -lt 2 ] && continue                      # ignore one-offs
    case "${p}_" in "$cpre"*) continue ;; esac        # a sub-prefix of the pack name is fine
    stub="${cpre%_}"
    [ "$cpre" = "prologai_" ] && continue             # sanctioned shared namespace
    # Flag only genuine terse/retired/banned prefixes — a 2-letter stub (lc_, wm_),
    # the retired pai_, or a known abbreviation stem. Generic English helper
    # predicates (is_, has_, get_, set_, max_, min_, sum_, run_, map_, ...) are fine.
    flag=0
    case "$GENERIC_OK" in *" $stub "*) ;; *) [ ${#stub} -eq 2 ] && flag=1 ;; esac
    case "$BANNED_STEMS" in *" $stub "*) flag=1 ;; esac
    case "$RETIRED_SHARED" in *" $stub "*) flag=1 ;; esac
    if [ "$flag" -eq 1 ]; then
      violations=$((violations+1))
      echo "VIOLATION [STRAGGLER]  pack '$p' carries a second prefix '${cpre}' (${cnt} preds; should be '${p}_' or prologai_)"
    fi
  done
done
echo "---"
collisions=0
for pre in "${!PREFIX_OF[@]}"; do
  set -- ${PREFIX_OF[$pre]}
  if [ "$#" -gt 1 ]; then collisions=$((collisions+1)); echo "COLLISION  prefix '${pre}' shared by:$(printf ' %s' "$@")"; fi
done
echo "---"
echo "scanned=$scanned  violations=$violations  colliding_prefixes=$collisions"
[ "$violations" -eq 0 ] && exit 0 || exit 1
