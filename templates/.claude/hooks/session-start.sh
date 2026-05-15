#!/usr/bin/env bash
# SessionStart hook — loads project context into Claude's context.
# Reads: dev-wiki state, memory snapshot, project state, session state.
# All reads are optional — graceful silent skip when files are missing.

set -euo pipefail

# --- Dev-wiki lifecycle state ---
DEVWIKI_STATE=".dev-wiki/_CURRENT_STATE.md"
if [ -f "$DEVWIKI_STATE" ]; then
  echo "=== Dev-Wiki State ==="
  grep -A2 '## Recommended Next Action' "$DEVWIKI_STATE" 2>/dev/null | head -3 || true
  grep -A3 '## Active Phase' "$DEVWIKI_STATE" 2>/dev/null | head -4 || true
  echo ""
fi

# --- Memory snapshot ---
MEMORY_FILE=".memory/MEMORY.md"
if [ -f "$MEMORY_FILE" ]; then
  echo "=== Project Memory ==="
  head -50 "$MEMORY_FILE"
  echo ""
fi

# --- Project state (manual cross-session) ---
STATE_FILE="PROJECT_STATE.md"
if [ -f "$STATE_FILE" ]; then
  echo "=== Project State ==="
  cat "$STATE_FILE"
  echo ""
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

exit 0
