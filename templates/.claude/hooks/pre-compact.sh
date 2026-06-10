#!/usr/bin/env bash
# PreCompact hook — outputs structured state summary for context injection.
# Reads committed state files only. Does NOT call MCP tools (shell limitation).
# Output is injected into post-compaction context by Claude Code.

set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true  # Phase 79: resolve project-relative refs regardless of CWD

echo "[nana:compact] === Pre-Compaction State Snapshot ==="

# --- Active phase from compaction anchor ---
ACTIVE_PHASE=".claude/rules/active-phase.md"
if [ -f "$ACTIVE_PHASE" ]; then
  echo ""
  echo "## Active Phase"
  grep -E '^(Phase:|Status:|Objective:|Exit criteria:)' "$ACTIVE_PHASE" 2>/dev/null || true
fi

# --- Current task from dev-wiki ---
TASKS=".dev-wiki/tasks.md"
if [ -f "$TASKS" ]; then
  NEXT_TASK=$(grep -m1 '^\- \[ \]' "$TASKS" 2>/dev/null || true)
  if [ -n "$NEXT_TASK" ]; then
    echo ""
    echo "## Next Task"
    echo "$NEXT_TASK"
  fi
fi

# --- Dev-wiki state summary ---
DEVWIKI_STATE=".dev-wiki/_CURRENT_STATE.md"
if [ -f "$DEVWIKI_STATE" ]; then
  echo ""
  echo "## Dev-Wiki State"
  grep -A2 '## Recommended Next Action' "$DEVWIKI_STATE" 2>/dev/null | head -3 || true
  grep -A3 '## Active Phase' "$DEVWIKI_STATE" 2>/dev/null | head -4 || true
fi

# --- Memory guidance ---
if [ -f "$TASKS" ]; then
  TOPIC=$(grep -m1 '^\- \[ \]' "$TASKS" 2>/dev/null | sed 's/^- \[ \] \[.\] //' | sed 's/ —.*//' | head -c 80 || true)
  if [ -n "$TOPIC" ]; then
    echo ""
    echo "[nana:memory] After compaction, run memory_search with query: \"$TOPIC\""
  fi
fi

echo ""
echo "[nana:compact] === End Pre-Compaction Snapshot ==="

exit 0
