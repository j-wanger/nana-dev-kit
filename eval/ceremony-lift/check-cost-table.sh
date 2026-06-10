#!/usr/bin/env bash
# Phase 86 — cost-table structural check (spec exit criterion 5).
# One row per pre-registered Step-list step x {tokens-raw, tokens-cache-adjusted,
# wall-clock, interruptions}, no empty cells, AND the materiality verdict lines.
set -uo pipefail
cd "$(dirname "$0")"
T=cost-table.md
FAIL=0
[ -f "$T" ] || { echo "check-cost-table: $T missing"; exit 1; }

STEPS="dev-plan-orchestration spec-generation approach-reviewer plan-reviewer review-gate-reviewer debrief-capture"
for s in $STEPS; do
  # Markdown row: | step | msgs | in | cw | cr | out | raw | cache_adj | wall_s | interrupts | ...
  row=$(grep -E "^\| $s \|" "$T" | head -1)
  if [ -z "$row" ]; then echo "  FAIL: missing row for $s"; FAIL=1; continue; fi
  # cells 7..10 (raw, cache_adj, wall_s, interrupts) must be non-empty numerics
  ok=$(echo "$row" | awk -F'|' '{gsub(/ /,"",$8); gsub(/ /,"",$9); gsub(/ /,"",$10); gsub(/ /,"",$11);
    if ($8 ~ /^[0-9]+$/ && $9 ~ /^[0-9]+$/ && $10 ~ /^[0-9]+$/ && $11 ~ /^[0-9]+$/) print "ok"}')
  if [ "$ok" = "ok" ]; then echo "  PASS: $s row complete"; else echo "  FAIL: $s has empty/non-numeric cost cells"; FAIL=1; fi
done

# Materiality verdict lines (closed vocabulary)
if grep -qE '^MATERIALITY-VERDICT: [a-z-]+=(material|immaterial)( [a-z-]+=(material|immaterial))*$' "$T"; then
  echo "  PASS: materiality verdict line present (closed vocabulary)"
else
  echo "  FAIL: MATERIALITY-VERDICT line missing or malformed"; FAIL=1
fi
if grep -qE '^EARLY-EXIT: (yes|no)$' "$T"; then
  echo "  PASS: early-exit line present"
else
  echo "  FAIL: EARLY-EXIT line missing or malformed"; FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then echo "check-cost-table: ALL PASS"; exit 0; else echo "check-cost-table: FAILURES"; exit 1; fi
