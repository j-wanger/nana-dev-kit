#!/usr/bin/env bash
# Phase 86 — corpus manifest validator (spec exit criterion 6, anchor clause).
# The mechanical manifest must reproduce the pre-registered hand count for the
# anchor phase: Phase 85 session 74a6533b = 8 ceremony dispatches (pre-registration
# ## Corpus; manual label inspection, wiki-add excluded). Detects pipeline
# under/over-enumeration of the denominator.
set -uo pipefail
cd "$(dirname "$0")"
M=corpus-manifest.md
FAIL=0
[ -f "$M" ] || { echo "check-corpus-manifest: $M missing"; exit 1; }

ANCHOR_SESSION="74a6533b-66aa-426d-9da0-b2a6d22a0197.jsonl"
PIN_ANCHOR_COUNT=8

actual=$(grep -cE "^\| $ANCHOR_SESSION \|.*\| (dev-plan-orchestration|spec-generation|approach-reviewer|plan-reviewer|review-gate-reviewer|debrief-capture) \|$" "$M")
if [ "$actual" = "$PIN_ANCHOR_COUNT" ]; then
  echo "  PASS: anchor phase (Ph85) ceremony dispatch count == $PIN_ANCHOR_COUNT"
else
  echo "  FAIL: anchor count expected=$PIN_ANCHOR_COUNT actual=$actual"; FAIL=1
fi

# Structural: every data row has 4 cells and a known class
bad=$(grep -E '^\| ' "$M" | grep -v '^\| session ' | grep -vcE '\| (dev-plan-orchestration|spec-generation|approach-reviewer|plan-reviewer|review-gate-reviewer|debrief-capture|non-ceremony) \|$' || true)
if [ "$bad" = "0" ]; then
  echo "  PASS: all rows carry a closed-enum class"
else
  echo "  FAIL: $bad rows with unknown class"; FAIL=1
fi

# Denominator visible: total ceremony dispatch count line present
if grep -qE '^CEREMONY-DISPATCHES-TOTAL: [0-9]+$' "$M"; then
  echo "  PASS: denominator line present"
else
  echo "  FAIL: CEREMONY-DISPATCHES-TOTAL line missing"; FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then echo "check-corpus-manifest: ALL PASS"; exit 0; else echo "check-corpus-manifest: FAILURES"; exit 1; fi
