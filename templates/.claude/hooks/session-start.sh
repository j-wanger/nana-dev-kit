#!/usr/bin/env bash
# SessionStart hook — loads project context into Claude's context.
# Reads: dev-wiki state, session state. Memory via MCP tools (not file read).
# All reads are optional — graceful silent skip when files are missing.

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$HOOK_DIR/session-start.d/wk-prune.sh"
source "$HOOK_DIR/session-start.d/memory-nudge.sh"
source "$HOOK_DIR/session-start.d/cognitive-readiness.sh"

date +%s > "$HOME/.claude/.session-start-ts" 2>/dev/null || true

# --- Dev-wiki lifecycle state ---
DEVWIKI_STATE=".dev-wiki/_CURRENT_STATE.md"
if [ -f "$DEVWIKI_STATE" ]; then
  echo "=== Dev-Wiki State ==="
  grep -A2 '## Recommended Next Action' "$DEVWIKI_STATE" 2>/dev/null | head -3 || true
  grep -A3 '## Active Phase' "$DEVWIKI_STATE" 2>/dev/null | head -4 || true
  echo ""
fi

# --- Gate check (active phase with unchecked gates) ---
ACTIVE_PHASE=".claude/rules/active-phase.md"
if [ -f "$ACTIVE_PHASE" ] && grep -q 'Status:.*Active' "$ACTIVE_PHASE" 2>/dev/null; then
  UNCHECKED=$(grep -c '\- \[ \]' "$ACTIVE_PHASE" 2>/dev/null || true)
  if [ "$UNCHECKED" -gt 0 ] 2>/dev/null; then
    echo "[nana:gate] $UNCHECKED unchecked gate(s) in active phase. Complete gates before implementing."
  fi
fi

# --- Session state (compaction anchor) ---
SESSION_STATE=".claude/rules/py-session-state.md"
if [ -f "$SESSION_STATE" ]; then
  FOCUS=$(grep -A1 '## Current Focus' "$SESSION_STATE" 2>/dev/null | tail -1)
  if [ -n "$FOCUS" ] && [ "$FOCUS" != "(not set)" ]; then
    echo "=== Session State ==="
    cat "$SESSION_STATE"
    echo ""
  fi
fi

# --- Crash recovery: detect commits since last debrief ---
if [ -f "$DEVWIKI_STATE" ]; then
  STATE_MTIME=$(stat -f %m "$DEVWIKI_STATE" 2>/dev/null || stat -c %Y "$DEVWIKI_STATE" 2>/dev/null || echo 0)
  LATEST_COMMIT=$(git log -1 --format=%ct 2>/dev/null || echo 0)
  if [ "$LATEST_COMMIT" -gt "$STATE_MTIME" ] 2>/dev/null; then
    DEBRIEF_SINCE=$(git log --since="@$STATE_MTIME" --oneline -i --grep="Debrief" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    if [ "$DEBRIEF_SINCE" -eq 0 ] 2>/dev/null; then
      echo "[nana:recovery] Commits detected since last state update. Consider /dev-check or /dev-debrief."
    fi
  fi
fi

# --- Delivery-commit divergence: a phase marked delivery-accepted but never committed ---
# Catches the gate-state-vs-git-state split (a delivery gate ticked while D3's commit never landed —
# agent skipped it or a pre-commit hook aborted it). Deterministic + fail-open; the skill-text commit
# step it backstops can be skipped, this check cannot.
if [ -f "$ACTIVE_PHASE" ] && grep -qE '^- \[x\] Delivery accepted' "$ACTIVE_PHASE" 2>/dev/null; then
  # The phase number may sit right after the colon ("Phase: 2 —") or later ("Phase: NONE — Phase 75
  # COMPLETE", the kit's own completion format) — match a number that follows the word "Phase".
  PHASE_N=$(grep -m1 '^Phase:' "$ACTIVE_PHASE" 2>/dev/null | grep -oiE 'phase[ :_-]*[0-9]+' | grep -oE '[0-9]+' | head -1 || true)
  if [ -n "${PHASE_N:-}" ]; then
    PHASE_COMMITS=$(git log --oneline 2>/dev/null | grep -icE "phase[ _-]?${PHASE_N}\b" || true)
    if [ "${PHASE_COMMITS:-0}" -eq 0 ] 2>/dev/null; then
      echo "[nana:recovery] Phase $PHASE_N marked delivery-accepted but no commit references it — work may be uncommitted. Commit it or run /dev-check."
    fi
  fi
fi

# --- Stale post-commit sidecar ---
if [ -f ".dev-wiki/.pending-commit" ]; then
  echo "[nana:pending] Unprocessed commit detected. Run task matching."
  rm -f ".dev-wiki/.pending-commit"
fi

# --- Clear session state ---
rm -f .claude/.loop-state .claude/.memory-consulted

# --- Module functions ---
check_memory_consolidation ".memory/memory.db" "$HOME/.claude/.memory-nudge-ts"
prune_working_knowledge ".claude/rules/working-knowledge.md" ".dev-wiki/.stale-queue"
check_cognitive_readiness

exit 0
