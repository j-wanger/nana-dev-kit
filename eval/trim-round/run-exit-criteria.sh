#!/usr/bin/env bash
# Phase 88 exit-criteria runner — the 10 machine-checkable criteria from
# specs/phase-88-trim-follow-on.md. Exit 0 + ALL-PASS iff every criterion passes.
# Testability: TRIM_TABLE overrides the verdict-table path (the seeded-failure RED test
# points it at a bad fixture); TRIM_SKIP_SLOW=1 skips make test/eval (criteria 6-7 report
# SKIPPED and the run CANNOT print ALL-PASS — partial runs are visibly partial).
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$DIR" rev-parse --show-toplevel)"
cd "$ROOT"
TABLE="${TRIM_TABLE:-eval/trim-round/verdict-table.md}"
case "$TABLE" in /*) TABLE_ABS="$TABLE" ;; *) TABLE_ABS="$ROOT/$TABLE" ;; esac
pass=0; failn=0; skipped=0; total=10

run_c() { # <n> <desc> <cmd...>
  local n="$1" desc="$2"; shift 2
  if "$@" >/dev/null 2>&1; then
    echo "criterion $n: PASS — $desc"; pass=$((pass+1))
  else
    echo "criterion $n: FAIL — $desc"; failn=$((failn+1))
  fi
}

run_c 1 "verdict table well-formed (base SHA, closed enums, trim revert fields, executed-row rehearsal logs)" \
  bash eval/trim-round/check-verdict-table.sh "$TABLE_ABS"
run_c 2 "ghost sweep clean across all discovered surfaces (controls-first validated)" \
  bash eval/trim-round/check-ghost-registrations.sh
run_c 3 "stage-2 diff allowlist: only the 3 routed files; pre-registration cmp-byte-identical" \
  bash eval/trim-round/check-stage2-allowlist.sh
run_c 4 "tightened checkers catch their seeded defects + boundary cases (14 controls)" \
  bash eval/trim-round/run-seeded-controls.sh
run_c 5 "check-tests-were-run paired smoke (block AND allow)" \
  bash tests/test_check_tests_were_run.sh

if [ "${TRIM_SKIP_SLOW:-0}" = "1" ]; then
  echo "criterion 6: SKIPPED — make test (TRIM_SKIP_SLOW)"; skipped=$((skipped+1))
  echo "criterion 7: SKIPPED — make eval + denominator (TRIM_SKIP_SLOW)"; skipped=$((skipped+1))
else
  run_c 6 "full test suite green (incl. drift + registration invariants)" make test
  c7() {
    local out count
    out=$(make eval 2>&1) || return 1
    count=$(grep -oE 'Score: [0-9]+/[0-9]+' <<< "$out" | grep -oE '/[0-9]+' | tr -d /)
    [ -n "$count" ] || return 1
    if [ "$count" != "52" ]; then
      grep -q 'denominator' "$TABLE" || return 1   # changed denominator must be explained
    fi
    grep -qE "Score: $count/$count" <<< "$out"
  }
  run_c 7 "make eval all-pass with any denominator change explained in the verdict table" c7
fi

run_c 8 "Phase-87 verdicts-stand pin recorded" \
  grep -q 'Phase-87 verdicts stand' "$TABLE"
run_c 9 "per-executed-row rehearsal logs present with revert SHA" \
  bash -c 'for f in eval/trim-round/rehearsals/*.log; do grep -q "commit: " "$f" || exit 1; grep -q "revert" "$f" || exit 1; done'
run_c 10 "trim-trial Blockers filings present (re-trigger at window end) + A4/A6 deferral filing" \
  bash -c 'grep -q "trim-trial: ak-ride-along" .dev-wiki/_CURRENT_STATE.md && grep -q "trim-trial: wk-seeding" .dev-wiki/_CURRENT_STATE.md && grep -q "A4/A6" .dev-wiki/_CURRENT_STATE.md'

echo "----"
echo "RESULT: $pass PASS / $failn FAIL / $skipped SKIPPED (of $total)"
if [ "$failn" -eq 0 ] && [ "$skipped" -eq 0 ]; then echo "ALL-PASS"; exit 0; fi
exit 1
