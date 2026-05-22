#!/usr/bin/env bash
# Tests for hardening hooks (detect-loop.sh, memory nudge, working-knowledge pruning).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOOP_HOOK="$REPO_ROOT/templates/.claude/hooks/detect-loop.sh"
START_HOOK="$REPO_ROOT/templates/.claude/hooks/session-start.sh"

ORIG_HOME="$HOME"

run_loop_hook() {
  local fixture="$1" json="$2"
  echo "$json" | HOME="$fixture" bash -c "cd '$fixture' && bash '$LOOP_HOOK'" 2>/dev/null || true
}

BASH_JSON_FAIL='{"tool_name":"Bash","input":{"command":"make test"},"output":{"exit_code":1}}'
BASH_JSON_DIFF='{"tool_name":"Bash","input":{"command":"other_cmd"},"output":{"exit_code":1}}'

echo "=== Hardening Tests ==="

# --- Loop detection tests ---

test_start "loop: below threshold — no warning"
T=$(mktemp -d) && mkdir -p "$T/.claude" && touch "$T/.claude/enforce"
printf 'make test:1\n' > "$T/.claude/.loop-state"
OUTPUT=$(run_loop_hook "$T" "$BASH_JSON_FAIL")
if echo "$OUTPUT" | grep -qi 'loop'; then
  test_fail "should not warn at 2 consecutive"
else
  test_pass
fi
rm -rf "$T"

test_start "loop: at threshold — emits warning"
T=$(mktemp -d) && mkdir -p "$T/.claude" && touch "$T/.claude/enforce"
printf 'make test:1\nmake test:1\n' > "$T/.claude/.loop-state"
OUTPUT=$(run_loop_hook "$T" "$BASH_JSON_FAIL")
if echo "$OUTPUT" | grep -qi 'loop'; then
  test_pass
else
  test_fail "expected loop warning at 3 consecutive"
fi
rm -rf "$T"

test_start "loop: different command resets counter"
T=$(mktemp -d) && mkdir -p "$T/.claude" && touch "$T/.claude/enforce"
printf 'make test:1\nmake test:1\n' > "$T/.claude/.loop-state"
OUTPUT=$(run_loop_hook "$T" "$BASH_JSON_DIFF")
if echo "$OUTPUT" | grep -qi 'loop'; then
  test_fail "different command should reset counter"
else
  test_pass
fi
rm -rf "$T"

# --- Memory nudge tests ---

test_start "nudge: cooldown suppresses"
T=$(mktemp -d) && mkdir -p "$T/.claude"
# Set last nudge to 1 hour ago (within 7-day cooldown)
date +%s > "$T/.claude/.memory-nudge-ts"
OUTPUT=$(HOME="$T" bash -c "cd '$T' && bash '$START_HOOK'" 2>/dev/null || true)
if echo "$OUTPUT" | grep -q 'memory_consolidate'; then
  test_fail "should suppress within cooldown"
else
  test_pass
fi
rm -rf "$T"

# --- Working-knowledge pruning tests ---

test_start "prune: old uses:1 entry → stale-queue"
T=$(mktemp -d) && mkdir -p "$T/.claude/rules" "$T/.dev-wiki"
cat > "$T/.claude/rules/working-knowledge.md" <<'WKEOF'
# Working Knowledge
- [uses: 1] old entry description
  source: [[old-source]] | activated: 2025-01-01
- [uses: 3] kept entry description
  source: [[kept-source]] | activated: 2025-01-01
WKEOF
OUTPUT=$(HOME="$T" bash -c "cd '$T' && bash '$START_HOOK'" 2>/dev/null || true)
if [ -f "$T/.dev-wiki/.stale-queue" ] && grep -q 'old entry' "$T/.dev-wiki/.stale-queue"; then
  test_pass
else
  test_fail "old uses:1 entry should move to stale-queue"
fi
rm -rf "$T"

test_start "prune: [pinned] entry survives"
T=$(mktemp -d) && mkdir -p "$T/.claude/rules" "$T/.dev-wiki"
cat > "$T/.claude/rules/working-knowledge.md" <<'WKEOF'
# Working Knowledge
- [uses: 1] [pinned] important invariant
  source: [[pinned-source]] | activated: 2025-01-01
WKEOF
HOME="$T" bash -c "cd '$T' && bash '$START_HOOK'" >/dev/null 2>&1 || true
if grep -q 'important invariant' "$T/.claude/rules/working-knowledge.md"; then
  test_pass
else
  test_fail "pinned entry should survive pruning"
fi
rm -rf "$T"

test_start "prune: uses:2+ entry survives"
T=$(mktemp -d) && mkdir -p "$T/.claude/rules" "$T/.dev-wiki"
cat > "$T/.claude/rules/working-knowledge.md" <<'WKEOF'
# Working Knowledge
- [uses: 3] frequently used entry
  source: [[freq-source]] | activated: 2025-01-01
WKEOF
HOME="$T" bash -c "cd '$T' && bash '$START_HOOK'" >/dev/null 2>&1 || true
if grep -q 'frequently used' "$T/.claude/rules/working-knowledge.md"; then
  test_pass
else
  test_fail "uses:3 entry should survive pruning"
fi
rm -rf "$T"

test_start "prune: <30 day entry survives"
T=$(mktemp -d) && mkdir -p "$T/.claude/rules" "$T/.dev-wiki"
TODAY=$(date +%Y-%m-%d)
cat > "$T/.claude/rules/working-knowledge.md" <<WKEOF
# Working Knowledge
- [uses: 1] recent entry
  source: [[recent-source]] | activated: $TODAY
WKEOF
HOME="$T" bash -c "cd '$T' && bash '$START_HOOK'" >/dev/null 2>&1 || true
if grep -q 'recent entry' "$T/.claude/rules/working-knowledge.md"; then
  test_pass
else
  test_fail "entry from today should survive pruning"
fi
rm -rf "$T"

test_summary "harden"
