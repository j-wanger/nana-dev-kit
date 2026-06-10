#!/usr/bin/env bash
# Phase 86 — maintainer verdict block validator (spec exit criterion 7).
# The phase article must carry per-step positions from the CLOSED enum plus a
# stage-2 go/no-go + routing line in closed vocabulary. Stage 1 mints no verdicts —
# this block is the maintainer's (gate A1 round 2).
set -uo pipefail
ART="$(dirname "$0")/../../.dev-wiki/articles/phases/phase-86-ceremony-lift-measurement.md"
FAIL=0
[ -f "$ART" ] || { echo "check-verdict-block: phase article missing"; exit 1; }

ENUM='keep|trim|cut|ambiguous-stage-2|underpowered-decide-by-arithmetic|keep-by-immateriality'
STEPS="dev-plan-orchestration spec-generation approach-reviewer plan-reviewer review-gate-reviewer debrief-capture"

for s in $STEPS; do
  if grep -qE "^VERDICT: $s=($ENUM)$" "$ART"; then
    echo "  PASS: verdict line for $s ($(grep -oE "^VERDICT: $s=[a-z2-]+" "$ART" | cut -d= -f2))"
  else
    echo "  FAIL: missing/malformed verdict line for $s"; FAIL=1
  fi
done

if grep -qE '^STAGE-2: (go|no-go)$' "$ART"; then
  echo "  PASS: stage-2 go/no-go line"
else
  echo "  FAIL: STAGE-2 line missing or malformed"; FAIL=1
fi
if grep -qE '^STAGE-2-ROUTING: (in-phase|follow-on|n\/a)$' "$ART"; then
  echo "  PASS: stage-2 routing line"
else
  echo "  FAIL: STAGE-2-ROUTING line missing or malformed"; FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then echo "check-verdict-block: ALL PASS"; exit 0; else echo "check-verdict-block: FAILURES"; exit 1; fi
