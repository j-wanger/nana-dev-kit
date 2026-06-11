#!/usr/bin/env bash
# Phase 88 stage-2 freeze guard. The routed tightening may touch ONLY the three files
# named by the Phase-87 review-gate routing; everything else under eval/ceremony-lift/
# (incl. the pre-registration) must be byte-identical to the phase base. The base SHA is
# read from the verdict table header — single source, no drift.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$DIR" rev-parse --show-toplevel)"
cd "$ROOT"

BASE=$(grep -E '^phase-base: ' eval/trim-round/verdict-table.md | awk '{print $2}')
[ -n "${BASE:-}" ] || { echo "FAIL: phase-base SHA not found in verdict-table.md"; exit 1; }

ALLOW="eval/ceremony-lift/stage2/run-exit-criteria.sh
eval/ceremony-lift/stage2/check-instrument.sh
eval/ceremony-lift/stage2/check-ship-table.sh"

fail=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  grep -qxF "$f" <<< "$ALLOW" || { echo "FAIL: non-routed stage-2/ceremony-lift file changed vs $BASE: $f"; fail=1; }
done < <(git diff --name-only "$BASE" HEAD -- eval/ceremony-lift/; git diff --name-only -- eval/ceremony-lift/)

# Byte-identity on the pre-registration, re-derived with cmp against the base blob
# (not grep, not trust): working tree vs the base commit's blob.
if ! git show "$BASE:eval/ceremony-lift/pre-registration.md" 2>/dev/null | cmp -s - eval/ceremony-lift/pre-registration.md; then
  echo "FAIL: pre-registration.md differs from base $BASE (cmp)"; fail=1
fi

[ "$fail" -eq 0 ] && echo "ALLOWLIST: PASS (diff vs $BASE confined to the 3 routed files)" || echo "ALLOWLIST: FAIL"
exit "$fail"
