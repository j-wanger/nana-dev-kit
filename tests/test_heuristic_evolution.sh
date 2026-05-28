#!/usr/bin/env bash
# Tests for heuristic evolution: counter update logic, lifecycle transitions, dashboard.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DASHBOARD="$REPO_ROOT/scripts/heuristic-dashboard.py"
COUNTER_MD="$REPO_ROOT/templates/.claude/skills/dev-plan/heuristic-counter-update.md"
LIFECYCLE_MD="$REPO_ROOT/templates/.claude/skills/dev-plan/heuristic-lifecycle.md"

make_heuristic() {
  local dir="$1" id="$2" helpful="$3" harmful="$4" status="$5"
  cat > "$dir/$id-test.md" <<EOF
---
id: $id
trigger: "test trigger"
domain: testing
source_phase: 1
confidence: high
helpful: $helpful
harmful: $harmful
status: $status
---

# Heuristic: Test

## When this applies
Test.

## Always
- Test

## Never
- Test

## Why
Test.

## Anti-pattern
Test.

## Source
Test.
EOF
}

# Test 1: Counter companion specifies helpful increment on judge score >= 6
test_start "test_helpful_increment_threshold"
assert_contains "$COUNTER_MD" "judge_score >= 6"

# Test 2: Counter companion specifies harmful condition (judge <= 4 AND reviewer >= 6)
test_start "test_harmful_increment_condition"
assert_contains "$COUNTER_MD" "reviewer_score >= 6"

# Test 3: Counter companion specifies no-update at score 5
test_start "test_no_update_at_score_5"
assert_contains "$COUNTER_MD" "judge_score = 5"

# Test 4: Lifecycle companion states iron status never transitions
test_start "test_iron_immune_to_lifecycle"
assert_exit_code 0 grep -qi 'iron.*never\|never.*transition' "$LIFECYCLE_MD"

# Test 5: Dashboard flags active heuristic with 2/5 harmful ratio as AT RISK
test_start "test_under_review_threshold_fires"
T=$(mktemp -d)
make_heuristic "$T" "HEU-TEST" 3 2 "active"
assert_exit_code 0 bash -c "python3 '$DASHBOARD' --dir '$T' 2>&1 | grep -q 'AT RISK'"
rm -rf "$T"

# Test 6: Dashboard shows ok for heuristic with 1/4 harmful (below minimum sample)
test_start "test_no_transition_below_threshold"
T=$(mktemp -d)
make_heuristic "$T" "HEU-SAFE" 3 1 "active"
assert_exit_code 0 bash -c "python3 '$DASHBOARD' --dir '$T' 2>&1 | grep -q 'ok'"
rm -rf "$T"

# Test 7: Dashboard shows unscored for zero-counter heuristic
test_start "test_dashboard_zero_counter"
T=$(mktemp -d)
make_heuristic "$T" "HEU-ZERO" 0 0 "active"
assert_exit_code 0 bash -c "python3 '$DASHBOARD' --dir '$T' 2>&1 | grep -q 'unscored'"
rm -rf "$T"

# Test 8: Dashboard output keys on heuristic id field
test_start "test_dashboard_keyed_by_id"
T=$(mktemp -d)
make_heuristic "$T" "HEU-IDTEST" 5 1 "active"
assert_exit_code 0 bash -c "python3 '$DASHBOARD' --dir '$T' 2>&1 | grep -q 'HEU-IDTEST'"
rm -rf "$T"

test_summary "heuristic_evolution"
