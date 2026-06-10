#!/usr/bin/env bash
# Phase 85 — exit-criteria runner: one command per spec criterion
# (specs/phase-85-install-gap-dogfood.md ## Exit Criteria), pass/fail each, exit 0 iff 9/9.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$KIT_ROOT"

PASS=0; TOTAL=0
crit() {  # $1 = label, $2 = command string
  TOTAL=$((TOTAL+1))
  if bash -c "$2" >/dev/null 2>&1; then
    echo "PASS  $1"
    PASS=$((PASS+1))
  else
    echo "FAIL  $1"
  fi
}

crit "1 make test green (incl. dircurrency + install hook_dirs tests)" \
     "make test"
crit "2 seeded controls (deleted dir / stale file / orphan / synced=0 / 2nd mapping)" \
     "bash tests/test_install_drift_dircurrency.sh"
crit "3 rehearsal log: full install + pinned-provenance SessionStart event, GREEN" \
     "grep -q 'PASS: A3' eval/install-gap/rehearsal.log && grep -q 'provenance' eval/install-gap/rehearsal.log && grep -q 'overall: GREEN' eval/install-gap/rehearsal.log"
crit "4 ~/.claude kit hooks == modules.json scope:global set (basename-normalized)" \
     "bash eval/install-gap/assert-global-set.sh"
crit "5 edge-screener union-uniqueness + single-firing (firing-count: 1)" \
     "bash eval/install-gap/assert-edge-screener-registration.sh && grep -qE '^firing-count: 1$' eval/install-gap/checkpoint-2.md"
crit "6 live maintainer root drift 0" \
     "bash scripts/check-install-drift.sh \"\$HOME/.claude\""
crit "7 make eval 52/52 unchanged + committed diff note" \
     "test -f eval/install-gap/eval-diff.md && make eval 2>&1 | grep -q 'Score: 52/52'"
crit "8 dogfood evidence complete (probe + >=2 sessions + 3 event types)" \
     "bash eval/install-gap/check-dogfood-evidence.sh"
crit "9 inventory: every row fixed/exempt (no pending), verdict line present" \
     "bash eval/install-gap/check-inventory.sh && ! grep -q '| pending |' eval/install-gap/inventory.md"

echo ""
echo "exit criteria: $PASS/$TOTAL"
[ "$PASS" -eq "$TOTAL" ]
