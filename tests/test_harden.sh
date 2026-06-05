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

# --- Delivery-commit divergence detector (Phase 75) — phase marked delivery-accepted but never
#     committed (the edge-screener dogfood failure: gate-state diverged from git-state silently).
#     Deterministic, fail-open; fires at session-start independent of agent adherence. ---

write_active_phase() {  # $1=dir $2=phase-number $3=delivery-line ([x] or [ ])
  cat > "$1/.claude/rules/active-phase.md" <<APEOF
# Active Phase Context
Phase: $2 — Some Phase
Status: Active
Gates:
- [x] Direction confirmed by user (approach approved)
- $3 Delivery accepted (post-implementation report)
APEOF
}

test_start "delivery-divergence: fires when phase delivery-accepted but uncommitted"
T=$(mktemp -d) && mkdir -p "$T/.claude/rules"
write_active_phase "$T" 2 "[x]"
( cd "$T" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m "initial, no phase ref" )
OUTPUT=$(HOME="$T" bash -c "cd '$T' && bash '$START_HOOK'" 2>/dev/null || true)
if echo "$OUTPUT" | grep -q '\[nana:recovery\]' && echo "$OUTPUT" | grep -qiE 'uncommitted|no commit'; then
  test_pass
else
  test_fail "expected divergence warning for accepted-but-uncommitted Phase 2 (out=$OUTPUT)"
fi
rm -rf "$T"

test_start "delivery-divergence: silent when a Phase-N commit exists"
T=$(mktemp -d) && mkdir -p "$T/.claude/rules"
write_active_phase "$T" 2 "[x]"
( cd "$T" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m "Phase 2: Some Phase — done" )
OUTPUT=$(HOME="$T" bash -c "cd '$T' && bash '$START_HOOK'" 2>/dev/null || true)
if echo "$OUTPUT" | grep -qiE '\[nana:recovery\].*(uncommitted|no commit)'; then
  test_fail "false-positive: Phase 2 IS committed but flagged (out=$OUTPUT)"
else
  test_pass
fi
rm -rf "$T"

test_start "delivery-divergence: silent when delivery gate is unchecked (in-flight phase)"
T=$(mktemp -d) && mkdir -p "$T/.claude/rules"
write_active_phase "$T" 2 "[ ]"
( cd "$T" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m "initial" )
OUTPUT=$(HOME="$T" bash -c "cd '$T' && bash '$START_HOOK'" 2>/dev/null || true)
if echo "$OUTPUT" | grep -qiE '\[nana:recovery\].*(uncommitted|no commit)'; then
  test_fail "fired on an unchecked (in-flight) delivery gate (out=$OUTPUT)"
else
  test_pass
fi
rm -rf "$T"

test_start "delivery-divergence: fail-open when active-phase.md absent / no git / no phase number"
T=$(mktemp -d) && mkdir -p "$T/.claude/rules"   # no active-phase.md, no git repo
if HOME="$T" bash -c "cd '$T' && bash '$START_HOOK'" >/dev/null 2>&1; then test_pass; else test_fail "session-start not fail-open with no active-phase/git"; fi
# accepted gate but no parseable 'Phase: N' line -> must not crash, must not fire
printf '# Active Phase Context\nStatus: Active\n- [x] Delivery accepted\n' > "$T/.claude/rules/active-phase.md"
if OUTPUT=$(HOME="$T" bash -c "cd '$T' && bash '$START_HOOK'" 2>/dev/null) && ! echo "$OUTPUT" | grep -qiE '\[nana:recovery\].*(uncommitted|no commit)'; then test_pass; else test_fail "crashed or fired with no parseable phase number (out=${OUTPUT:-})"; fi
rm -rf "$T"

# Regression: the kit's OWN debrief writes "Phase: NONE — Phase N COMPLETE" (number NOT right after the
# colon). The detector must still extract N and fire when uncommitted — caught by dogfooding the detector
# against nana-dev-kit's own active-phase.md format.
test_start "delivery-divergence: fires on the 'Phase: NONE — Phase N COMPLETE' completion format"
T=$(mktemp -d) && mkdir -p "$T/.claude/rules"
cat > "$T/.claude/rules/active-phase.md" <<'APEOF'
# Active Phase Context
Phase: NONE — Phase 9 COMPLETE (Some Thing).
Status: Active
Gates:
- [x] Direction confirmed by user (approach approved)
- [x] Delivery accepted (post-implementation report)
APEOF
( cd "$T" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m "unrelated, no phase ref" )
OUTPUT=$(HOME="$T" bash -c "cd '$T' && bash '$START_HOOK'" 2>/dev/null || true)
if echo "$OUTPUT" | grep -q '\[nana:recovery\]' && echo "$OUTPUT" | grep -qiE 'Phase 9.*(uncommitted|no commit)'; then
  test_pass
else
  test_fail "expected divergence warning for 'Phase: NONE — Phase 9 COMPLETE' + uncommitted (out=$OUTPUT)"
fi
rm -rf "$T"

# --- Installed-copy-drift advisory (Phase 76) — session-start fires [nana:drift] ONLY in the kit
#     repo (git-root == the ~/.claude/.nana-dev-kit-path marker) when the installed copy has drifted
#     from templates/. Deterministic, fail-open, kit-repo-scoped (signal not noise). ---
DRIFT_SCRIPT_SRC="$REPO_ROOT/scripts/check-install-drift.sh"

setup_drift_kit() {  # $1 = sandbox kit root; minimal self-contained kit with one drifted skill file
  local k="$1"
  mkdir -p "$k/scripts" "$k/templates/.claude/skills/foo" "$k/templates/.claude/rules" "$k/.claude/skills/foo"
  cp "$DRIFT_SCRIPT_SRC" "$k/scripts/check-install-drift.sh"
  printf '{ "modules": [ { "name": "core", "skills": ["foo"], "rules": [] } ], "hooks": [] }\n' > "$k/modules.json"
  printf 'v2 (source)\n'          > "$k/templates/.claude/skills/foo/SKILL.md"
  printf 'v1 (stale installed)\n' > "$k/.claude/skills/foo/SKILL.md"     # the drift
  printf '%s' "$k"                > "$k/.claude/.nana-dev-kit-path"
  ( cd "$k" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init )
}

test_start "drift-advisory: fires [nana:drift] in the kit repo when the installed copy drifted"
T=$(mktemp -d); setup_drift_kit "$T"
OUTPUT=$(HOME="$T" bash -c "cd '$T' && bash '$START_HOOK'" 2>/dev/null || true)
if echo "$OUTPUT" | grep -q '\[nana:drift\]'; then test_pass; else test_fail "expected [nana:drift] in kit repo (out=$OUTPUT)"; fi
rm -rf "$T"

test_start "drift-advisory: SILENT outside the kit repo (consuming project) even when drift exists"
T=$(mktemp -d); setup_drift_kit "$T"
T2=$(mktemp -d); ( cd "$T2" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init )
# HOME=$T (marker → $T) but CWD=$T2 (a different repo): git-root != marker → must stay silent
OUTPUT=$(HOME="$T" bash -c "cd '$T2' && bash '$START_HOOK'" 2>/dev/null || true)
if echo "$OUTPUT" | grep -q '\[nana:drift\]'; then test_fail "fired outside the kit repo (out=$OUTPUT)"; else test_pass; fi
rm -rf "$T" "$T2"

test_start "drift-advisory: SILENT in the kit repo when the installed copy is synced"
T=$(mktemp -d); setup_drift_kit "$T"
cp "$T/templates/.claude/skills/foo/SKILL.md" "$T/.claude/skills/foo/SKILL.md"   # resync away the drift
OUTPUT=$(HOME="$T" bash -c "cd '$T' && bash '$START_HOOK'" 2>/dev/null || true)
if echo "$OUTPUT" | grep -q '\[nana:drift\]'; then test_fail "fired when synced (out=$OUTPUT)"; else test_pass; fi
rm -rf "$T"

test_start "drift-advisory: fail-open (no crash, silent) when the kit-path marker is absent"
T=$(mktemp -d); mkdir -p "$T/.claude"   # no marker, no git repo
if OUTPUT=$(HOME="$T" bash -c "cd '$T' && bash '$START_HOOK'" 2>/dev/null) && ! echo "$OUTPUT" | grep -q '\[nana:drift\]'; then test_pass; else test_fail "crashed or fired without a marker (out=${OUTPUT:-})"; fi
rm -rf "$T"

# --- Phase 79: hook commands resolve from a non-root CWD via ${CLAUDE_PROJECT_DIR} ---
# The hermetic replacement for the unconfirmable live check (edge-screener Stop-hook dogfood): replicate
# how Claude Code runs a registered command — expand ${CLAUDE_PROJECT_DIR} (an env var) and exec via sh —
# from a WRONG cwd. The ${CLAUDE_PROJECT_DIR}-anchored command must resolve; the bare relative path must not.
RESOLVE_HOOK="session-stop.sh"
PROJ=$(mktemp -d); WRONG=$(mktemp -d)
mkdir -p "$PROJ/.claude/hooks"
cp "$REPO_ROOT/templates/.claude/hooks/$RESOLVE_HOOK" "$PROJ/.claude/hooks/$RESOLVE_HOOK"
chmod +x "$PROJ/.claude/hooks/$RESOLVE_HOOK"

test_start "cwd-resolve: \${CLAUDE_PROJECT_DIR}-anchored hook resolves from a non-root CWD"
RC=0
echo '{}' | ( cd "$WRONG" && HOME="$PROJ" CLAUDE_PROJECT_DIR="$PROJ" sh -c '${CLAUDE_PROJECT_DIR}/.claude/hooks/'"$RESOLVE_HOOK" ) >/dev/null 2>&1 || RC=$?
if [ "$RC" -eq 0 ]; then test_pass; else test_fail "anchored command failed to resolve from wrong cwd (rc=$RC)"; fi

test_start "cwd-resolve: the BARE relative path FAILS from a non-root CWD (proves the bug + the fix)"
RC=0
echo '{}' | ( cd "$WRONG" && HOME="$PROJ" CLAUDE_PROJECT_DIR="$PROJ" sh -c '.claude/hooks/'"$RESOLVE_HOOK" ) >/dev/null 2>&1 || RC=$?
if [ "$RC" -ne 0 ]; then test_pass; else test_fail "bare relative path unexpectedly resolved from wrong cwd"; fi
rm -rf "$PROJ" "$WRONG"

# A2 proof: a CWD-relative hook FUNCTIONS from a non-root CWD — session-start's drift advisory only fires
# when git-root == the marker path with drift present, so firing from a WRONG cwd proves its internal refs
# (git-root, templates, marker, the drift script) resolved via the in-hook `cd "${CLAUDE_PROJECT_DIR:-.}"`.
test_start "cwd-resolve: session-start drift advisory FIRES from a non-root CWD (internal refs via cd)"
T=$(mktemp -d); setup_drift_kit "$T"; WD=$(mktemp -d)
OUT=$( cd "$WD" && HOME="$T" CLAUDE_PROJECT_DIR="$T" bash "$START_HOOK" 2>/dev/null || true )
if echo "$OUT" | grep -q '\[nana:drift\]'; then test_pass; else test_fail "internal refs did not resolve from wrong cwd (out=$OUT)"; fi

test_start "cwd-resolve: WITHOUT CLAUDE_PROJECT_DIR the same wrong-cwd run stays silent (differential)"
OUT2=$( cd "$WD" && HOME="$T" bash "$START_HOOK" 2>/dev/null || true )
if echo "$OUT2" | grep -q '\[nana:drift\]'; then test_fail "fired without the var from a wrong cwd"; else test_pass; fi
rm -rf "$T" "$WD"

test_summary "harden"
