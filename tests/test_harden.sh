#!/usr/bin/env bash
# Tests for hardening hooks (detect-loop.sh, memory nudge, working-knowledge pruning).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOOP_HOOK="$REPO_ROOT/templates/.claude/hooks/detect-loop.sh"
START_HOOK="$REPO_ROOT/templates/.claude/hooks/session-start.sh"
# fires: detect-loop.sh session-start.sh memory-nudge.sh   # (coverage gate — see test_hook_firing_coverage.sh)

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

# --- Memory nudge structural checks ---

test_start "memory-nudge: uses correct column name (active, not is_active)"
NUDGE_HOOK="$REPO_ROOT/templates/.claude/hooks/session-start.d/memory-nudge.sh"
if grep -q 'is_active' "$NUDGE_HOOK"; then
  test_fail "memory-nudge.sh still uses is_active instead of active"
elif ! grep -qE 'WHERE.*\bactive\b' "$NUDGE_HOOK"; then
  test_fail "memory-nudge.sh missing active column reference"
else
  test_pass
fi

test_start "session-start: uses project-relative .memory/memory.db path"
if grep -qF 'memory_server/memory.db' "$START_HOOK"; then
  test_fail "session-start.sh still uses wrong memory_server/ path"
elif ! grep -qF '.memory/memory.db' "$START_HOOK"; then
  test_fail "session-start.sh missing .memory/memory.db path"
else
  test_pass
fi

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

# --- Memory nudge: DIRECT firing tests (Phase 67 — close the coverage gap; above it is only grepped
#     for column-name + fired transitively for the cooldown/suppression path). Source the function and
#     call it, asserting an OBSERVABLE nudge, not just exit code. ---

# Load-bearing: MCP registered (settings.json) but no DB yet -> "no database" nudge. No dependency on
# `timeout`/`sqlite3`, but the hook parses settings.json via python3 — guard it like the other tool deps
# (python3 is a hard kit dependency, so this runs in practice; the guard is for symmetry/portability).
if command -v python3 >/dev/null 2>&1; then
  test_start "memory-nudge: nudges when MCP is registered but the DB is absent"
  T=$(mktemp -d) && mkdir -p "$T/.claude"
  printf '{"mcpServers":{"memory":{"command":"x"}}}' > "$T/.claude/settings.json"
  OUTPUT=$( HOME="$T"; source "$NUDGE_HOOK"; check_memory_consolidation "$T/nonexistent.db" "$T/.ts" 2>/dev/null )
  if echo "$OUTPUT" | grep -q 'No memory database found'; then test_pass; else test_fail "no nudge when MCP registered + DB absent (out=$OUTPUT)"; fi
  rm -rf "$T"
else
  echo "  (note: python3 unavailable — memory-nudge's MCP-registered-no-DB path is unasserted on this host)"
fi

test_start "memory-nudge: silent when DB absent AND no MCP registered (not always-fire)"
T=$(mktemp -d) && mkdir -p "$T/.claude"   # no settings.json
OUTPUT=$( HOME="$T"; source "$NUDGE_HOOK"; check_memory_consolidation "$T/nonexistent.db" "$T/.ts" 2>/dev/null )
if [ -z "$OUTPUT" ]; then test_pass; else test_fail "nudged with no MCP registered (out=$OUTPUT)"; fi
rm -rf "$T"

# The consolidation-nudge (>500 active entries) path depends on `timeout` (stock macOS lacks it ->
# the hook's `timeout 2 sqlite3 ... || echo 0` silently yields 0). Exercise it only where `timeout`
# exists, so we don't assert a path the env can't run; the gap is reported, never silently skipped.
if command -v timeout >/dev/null 2>&1 && command -v sqlite3 >/dev/null 2>&1; then
  test_start "memory-nudge: fires consolidation nudge past 500 active entries"
  T=$(mktemp -d)
  sqlite3 "$T/m.db" "CREATE TABLE memories(active INTEGER); WITH RECURSIVE c(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM c WHERE n<501) INSERT INTO memories(active) SELECT 1 FROM c;" 2>/dev/null
  OUTPUT=$( source "$NUDGE_HOOK"; check_memory_consolidation "$T/m.db" "$T/.ts" 2>/dev/null )
  if echo "$OUTPUT" | grep -q 'active entries' && [ -f "$T/.ts" ]; then test_pass; else test_fail "no consolidation nudge past 500 (out=$OUTPUT)"; fi
  rm -rf "$T"
else
  echo "  (note: 'timeout' unavailable — memory-nudge's >500-entries consolidation path is unasserted on this host)"
fi

test_summary "harden"
