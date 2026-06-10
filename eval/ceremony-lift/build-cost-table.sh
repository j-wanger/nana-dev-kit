#!/usr/bin/env bash
# Phase 86 — build cost-table.md over the frozen corpus (pre-registration: Corpus,
# Token attribution, Cost materiality). Corpus selection is mechanical:
# first-timestamp in [Phase-76 PLAN 2026-05-31T17:00Z, end-commit 5360486 time
# 2026-06-10T15:01:28Z], minus sessions containing 'ceremony-lift' (self-feedback
# exclusion). Materiality: immaterial iff cache_adj < 5% of total AND wall < 5% of
# total AND interruptions within gate allowance (dev-plan/debrief: 1/phase; others 0).
set -euo pipefail
cd "$(dirname "$0")"
SDIR="$HOME/.claude/projects/-Users-jwang-nana-dev-kit"
N_PHASES=10   # Phases 76-85
WINDOW_LO="2026-05-31T17:00"
WINDOW_HI="2026-06-10T15:01:28"

SESSIONS=()
for f in "$SDIR"/*.jsonl; do
  first=$(head -5 "$f" | jq -r 'select(.timestamp != null) | .timestamp' 2>/dev/null | head -1)
  [ -n "$first" ] || continue
  [[ "$first" > "$WINDOW_LO" && "$first" < "$WINDOW_HI" ]] || continue
  grep -qm1 'ceremony-lift' "$f" && continue
  SESSIONS+=("$f")
done
[ "${#SESSIONS[@]}" -gt 0 ] || { echo "build-cost-table: no corpus sessions found"; exit 1; }

python3 ./extract-costs.py "${SESSIONS[@]}" | N_PHASES="$N_PHASES" NSESS="${#SESSIONS[@]}" python3 ./emit-cost-table.py > cost-table.md

echo "build-cost-table: wrote cost-table.md (${#SESSIONS[@]} sessions)"
