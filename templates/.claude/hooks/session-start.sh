#!/usr/bin/env bash
# SessionStart hook — loads project + session state into Claude's context.
# Reads PROJECT_STATE.md (manual cross-session) and py-session-state.md (compaction anchor).

set -euo pipefail

STATE_FILE="PROJECT_STATE.md"
SESSION_STATE=".claude/rules/py-session-state.md"

if [ -f "$STATE_FILE" ]; then
  echo "=== Project State ==="
  cat "$STATE_FILE"
  echo ""
fi

if [ -f "$SESSION_STATE" ]; then
  FOCUS=$(grep -A1 '## Current Focus' "$SESSION_STATE" 2>/dev/null | tail -1)
  if [ -n "$FOCUS" ] && [ "$FOCUS" != "(not set)" ]; then
    echo "=== Session State ==="
    cat "$SESSION_STATE"
    echo ""
  fi
fi

exit 0
