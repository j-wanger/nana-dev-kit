#!/usr/bin/env bash
# Phase 96 close-out verifier — deterministic, NO-LLM. Asserts the LIVE end-state of the consumer
# re-sync rollout across all 7 consuming projects (maintainer machine). Exit 0 iff every criterion passes.
#   - every consumer: 17-hook kit set registered in settings.local.json ONLY; settings.json kit-clean;
#     detect-loop ghost-free (no reg in either file, no file); check-install-drift --consumer clean.
#   - arming set exactly matches the A5 decision.
set -uo pipefail
KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DRIFT="$KIT_ROOT/scripts/check-install-drift.sh"
H="${HOME:?}"

ARMED="signal-watch edge-screener aml-substrate edge-analyst aml-casework"
UNARMED="ai-game fate"

fail=0
pass() { echo "PASS: $*"; }
bad()  { echo "FAIL: $*" >&2; fail=1; }

regs() {  # $1 settings file -> hook basenames, one per registration (DUPS KEPT — raw, for DRQ-1 detection)
  [ -f "$1" ] || return 0
  jq -r '(.hooks // {}) | to_entries[] | .value[]? | (.hooks // [])[]? | (.command // .prompt // empty)' \
     "$1" 2>/dev/null | sed 's#.*/##' | sed '/^$/d'
}
has_detectloop() {  # 0 if detect-loop registered/present anywhere
  regs "$1/.claude/settings.json"       | grep -qxF detect-loop.sh && return 0
  regs "$1/.claude/settings.local.json" | grep -qxF detect-loop.sh && return 0
  [ -f "$1/.claude/hooks/detect-loop.sh" ] && return 0
  return 1
}

for d in $ARMED $UNARMED; do
  root="$H/$d"
  [ -d "$root/.claude" ] || { bad "$d: no .claude/"; continue; }
  nraw=$(regs "$root/.claude/settings.local.json" | grep -c '\.sh$')
  ndist=$(regs "$root/.claude/settings.local.json" | sort -u | grep -c '\.sh$')
  njson=$(regs "$root/.claude/settings.json" | sort -u | grep -c '\.sh$')
  [ "$ndist" -ge 17 ]    || bad "$d: settings.local.json has $ndist distinct hook regs (<17 kit set)"
  [ "$nraw" -eq "$ndist" ] || bad "$d: settings.local.json has duplicate registrations (raw $nraw > distinct $ndist) — DRQ-1 cross-entry double-fire"
  [ "$njson" -eq 0 ]     || bad "$d: settings.json still holds $njson hook reg(s) (not consolidated to local)"
  has_detectloop "$root" && bad "$d: detect-loop still registered/present (ghost)"
  bash "$DRIFT" --consumer "$root" >/dev/null 2>&1 || bad "$d: check-install-drift --consumer reports drift"
done
[ "$fail" -eq 0 ] && pass "all 7 consumers consolidated: 17-hook kit set in settings.local only, settings.json kit-clean, detect-loop ghost-free, drift clean"

for d in $ARMED;   do [ -f "$H/$d/.claude/enforce" ] || bad "$d: expected ARMED (.claude/enforce missing)"; done
for d in $UNARMED; do [ -f "$H/$d/.claude/enforce" ] && bad "$d: expected UNARMED (.claude/enforce present)"; done
[ "$fail" -eq 0 ] && pass "arming matches A5: armed={$ARMED} unarmed={$UNARMED}"

if [ "$fail" -eq 0 ]; then echo "Phase 96 exit criteria: ALL-PASS"; exit 0
else echo "Phase 96 exit criteria: FAIL" >&2; exit 1; fi
