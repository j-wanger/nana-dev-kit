#!/usr/bin/env bash
# Phase 83 spec exit-criteria aggregator — one PASS/FAIL line per criterion, exit nonzero on any FAIL.
# Mirrors specs/phase-83-prune-on-value-subtraction.md ## Exit Criteria.
set -uo pipefail
cd "$(dirname "$0")/../.."   # repo root
DIR=eval/prune-on-value
TABLE=$DIR/verdict-table.md
LOG=$DIR/liveness-grep.log
CANDS='enforce-memory|memory-reinforcement|memory-mcp-scaffold|audit-log-model-field|orphan-companions|harness-audit'
fail=0
check() { # check <name> <command...>
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "PASS: $name"; else echo "FAIL: $name"; fail=1; fi
}

c1() { [ "$(grep -oE "^\| ($CANDS) " "$TABLE" | sort -u | wc -l | tr -d ' ')" = 6 ]; }
c2() { ! grep -E "^\| ($CANDS) " "$TABLE" | grep -vE '\| (keep|cut|harden|disable-at-boundary) \|' | grep -q .; }
c3() { ! grep -E "^\| ($CANDS) " "$TABLE" | grep -E '\| (cut|disable-at-boundary) \|' | grep -vE 'couldnt-fire|didnt-fire' | grep -q .; }
c4() { [ -f "$LOG" ] && head -5 "$LOG" | grep -q edge-screener; }
c5() { make test 2>&1 | grep -q 'All tests passed'; }
c6() { local s; s=$(make eval 2>&1 | grep -oE 'Score: [0-9]+/[0-9]+' | tail -1 | grep -oE '[0-9]+/[0-9]+'); [ -n "$s" ] && { [ "${s%/*}" = "${s#*/}" ] || grep -q 'denominator' "$TABLE"; }; }
c7() { bash scripts/check-install-drift.sh; }
c8() { bash tests/test_settings_template.sh; }
c9() { [ "$(grep -c '^DEREG .*: absent$' "$LOG")" -ge "$(grep -cE "^\| ($CANDS) .*\| (cut|disable-at-boundary) \|" "$TABLE")" ]; }
c10() { [ "$(git log --oneline --grep='^Phase 83 cut:' | wc -l | tr -d ' ')" = "$(grep -cE "^\| ($CANDS) .*\| (cut|disable-at-boundary) \|" "$TABLE")" ]; }

check "EC1 verdict table has exactly the 6 candidate rows" c1
check "EC2 every candidate row carries a closed-enum verdict (universal)" c2
check "EC3 every cut/disable row carries a zero-class token" c3
check "EC4 liveness log committed with discovered roots (edge-screener in head -5)" c4
check "EC5 make test green at reduced surface" c5
check "EC6 make eval runs (denominator documented in verdict table if changed)" c6
check "EC7 check-install-drift exits 0" c7
check "EC8 settings template matches modules.json (no hand-edits)" c8
check "EC9 one DEREG absent-line per executed cut/disable (vacuous at zero cuts)" c9
check "EC10 one 'Phase 83 cut:' commit per executed cut/disable" c10

exit "$fail"
