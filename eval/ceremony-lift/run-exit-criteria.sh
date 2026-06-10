#!/usr/bin/env bash
# Phase 86 — exit-criteria runner (spec: 8 machine-checkable criteria).
# Early-exit mode (pre-registration ## Early-exit reporting): if cost-table.md says
# EARLY-EXIT: yes, criteria 2/4/6 report N/A-EARLY-EXIT and the runner passes on
# 5/5 + 3 N/A. Otherwise all 8 must pass.
set -uo pipefail
cd "$(dirname "$0")"
PASS=0; FAILN=0; NA=0
declare -a RESULTS

EARLY_EXIT=no
[ -f cost-table.md ] && grep -qE '^EARLY-EXIT: yes$' cost-table.md && EARLY_EXIT=yes

run_c() { # run_c <n> <desc> <na-on-early-exit> <cmd...>
  local n="$1" desc="$2" na="$3"; shift 3
  if [ "$EARLY_EXIT" = "yes" ] && [ "$na" = "na" ]; then
    RESULTS+=("criterion $n: N/A-EARLY-EXIT — $desc"); NA=$((NA+1)); return
  fi
  if "$@" >/dev/null 2>&1; then
    RESULTS+=("criterion $n: PASS — $desc"); PASS=$((PASS+1))
  else
    RESULTS+=("criterion $n: FAIL — $desc"); FAILN=$((FAILN+1))
  fi
}

c1() {
  test -f pre-registration.md || return 1
  for s in '## Corpus' '## Admissibility' '## Token attribution' '## MDE' \
           '## Verdict menu' '## Stage-2 parameters' '## Step list' '## Class membership'; do
    grep -q "$s" pre-registration.md || return 1
  done
}
c2() {
  local pr ev
  pr=$(git log --diff-filter=A --format=%H -1 -- eval/ceremony-lift/pre-registration.md)
  ev=$(git log --diff-filter=A --format=%H -1 -- eval/ceremony-lift/evidence-table.md)
  [ -n "$pr" ] && [ -n "$ev" ] || return 1
  git merge-base --is-ancestor "$pr" "$ev" || return 1
  git diff --quiet "$pr" "$ev" -- eval/ceremony-lift/pre-registration.md
}

run_c 1 "pre-registration sections present"            no  c1
run_c 2 "pre-reg strictly precedes evidence, byte-frozen" na bash -c 'cd ../.. && pr=$(git log --diff-filter=A --format=%H -1 -- eval/ceremony-lift/pre-registration.md); ev=$(git log --diff-filter=A --format=%H -1 -- eval/ceremony-lift/evidence-table.md); [ -n "$pr" ] && [ -n "$ev" ] && git merge-base --is-ancestor "$pr" "$ev" && git diff --quiet "$pr" "$ev" -- eval/ceremony-lift/pre-registration.md'
run_c 3 "cost-extractor positive control"              no  bash ./test-cost-extractor-control.sh
run_c 4 "blind tabulator controls (5 seeds)"           na  bash ./test-tabulator-controls.sh
run_c 5 "cost table structure + materiality verdict"   no  bash ./check-cost-table.sh
run_c 6 "evidence table + manifest anchor + pointers"  na  bash ./check-evidence-table.sh
run_c 7 "maintainer verdict block (closed enum)"       no  bash ./check-verdict-block.sh
run_c 8 "verdicts-only invariant (pinned base)"        no  bash ./check-verdicts-only.sh

printf '%s\n' "${RESULTS[@]}"
TOTAL_REQ=$((8 - NA))
if [ "$FAILN" -eq 0 ]; then
  if [ "$NA" -gt 0 ]; then
    echo "run-exit-criteria: $PASS/$TOTAL_REQ PASS + $NA N/A-EARLY-EXIT (early-exit mode)"
  else
    echo "run-exit-criteria: 8/8 PASS"
  fi
  exit 0
else
  echo "run-exit-criteria: $FAILN FAILURES ($PASS/$TOTAL_REQ pass)"
  exit 1
fi
