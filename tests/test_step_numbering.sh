#!/usr/bin/env bash
# Step-numbering continuity invariant (Phase 61 T6).
# For each lifecycle skill template (dev-plan, dev-debrief, spec):
#   1. NO decimal (Step 2.5) or alpha-postfix (Step 6a) STEP HEADINGS remain.
#   2. The whole-number STEP HEADINGS across the skill dir form a gap-free 1..N
#      (counting cross-file steps, e.g. dev-debrief 13-15 live in a companion).
# Deterministic structural check — no judge. Guards against decimal-step creep,
# the pattern that accreted across Phases 8-60.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers.sh"

SKILLS_DIR="$PROJECT_ROOT/templates/.claude/skills"

echo "=== test_step_numbering.sh ==="

for skill in dev-plan dev-debrief spec; do
  dir="$SKILLS_DIR/$skill"

  # (1) No decimal / alpha-postfix Step headings anywhere in the skill dir.
  test_start "$skill: no decimal/postfix Step headings"
  if grep -rqE '^#{2,4} Step [0-9]+(\.[0-9]|[a-z])' "$dir" 2>/dev/null; then
    test_fail "decimal/postfix Step heading found: $(grep -rnE '^#{2,4} Step [0-9]+(\.[0-9]|[a-z])' "$dir" | head -1)"
  else
    test_pass
  fi

  # (2) Whole-number Step headings form a gap-free 1..N across the dir.
  nums="$(grep -rhoE '^#{2,4} Step [0-9]+:' "$dir" 2>/dev/null | grep -oE '[0-9]+' | sort -n | uniq)"
  max="$(echo "$nums" | tail -1)"
  expected="$(seq 1 "$max")"
  test_start "$skill: Step headings gap-free 1..$max"
  assert_eq "$(echo "$expected" | tr '\n' ' ')" "$(echo "$nums" | tr '\n' ' ')" "non-contiguous step numbering"
done

test_summary "test_step_numbering.sh"
