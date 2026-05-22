#!/usr/bin/env bash
# SessionStart hook — loads project context into Claude's context.
# Reads: dev-wiki state, session state. Memory via MCP tools (not file read).
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

# --- Gate check (active phase with unchecked gates) ---
ACTIVE_PHASE=".claude/rules/active-phase.md"
if [ -f "$ACTIVE_PHASE" ] && grep -q 'Status:.*Active' "$ACTIVE_PHASE" 2>/dev/null; then
  UNCHECKED=$(grep -c '\- \[ \]' "$ACTIVE_PHASE" 2>/dev/null || true)
  if [ "$UNCHECKED" -gt 0 ] 2>/dev/null; then
    echo "[gate-check] $UNCHECKED unchecked gate(s) in active phase. Complete gates before implementing."
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

# --- Memory search guidance ---
TASKS=".dev-wiki/tasks.md"
if [ -f "$TASKS" ]; then
  TOPIC=$(grep -m1 '^\- \[ \]' "$TASKS" 2>/dev/null | sed 's/^- \[ \] \[.\] //' | sed 's/ —.*//' | head -c 80 || true)
  if [ -n "$TOPIC" ]; then
    echo "[memory] Run memory_search with query: \"$TOPIC\""
  fi
fi

# --- Clear loop detection state ---
rm -f .claude/.loop-state

# --- Memory consolidation nudge ---
MEMORY_DB="$HOME/.claude/memory_server/memory.db"
NUDGE_TS="$HOME/.claude/.memory-nudge-ts"
if [ -f "$MEMORY_DB" ] && command -v sqlite3 >/dev/null 2>&1; then
  SUPPRESS=false
  if [ -f "$NUDGE_TS" ]; then
    LAST=$(cat "$NUDGE_TS" 2>/dev/null || echo "0")
    NOW=$(date +%s)
    DIFF=$(( NOW - LAST ))
    if [ "$DIFF" -lt 604800 ]; then
      SUPPRESS=true
    fi
  fi
  if [ "$SUPPRESS" = false ]; then
    MCOUNT=$(timeout 2 sqlite3 "$MEMORY_DB" "SELECT COUNT(*) FROM memories WHERE is_active=1;" 2>/dev/null || echo "0")
    if [ "$MCOUNT" -gt 500 ] 2>/dev/null; then
      echo "[memory] $MCOUNT active entries. Consider running memory_consolidate."
      date +%s > "$NUDGE_TS"
    fi
  fi
fi

# --- Working-knowledge pruning ---
WK_FILE=".claude/rules/working-knowledge.md"
STALE_QUEUE=".dev-wiki/.stale-queue"
if [ -f "$WK_FILE" ]; then
  TODAY_EPOCH=$(date +%s)
  PRUNED=0
  TMPFILE=$(mktemp)
  STALE_ENTRIES=""
  while IFS= read -r line; do
    if [ "$PRUNED" -ge 5 ]; then
      echo "$line" >> "$TMPFILE"
      continue
    fi
    if echo "$line" | grep -q '^\- \[uses: 1\]' && ! echo "$line" | grep -q '\[pinned\]'; then
      # Read the source line (next line) to get activated date
      read -r source_line || source_line=""
      ACTIVATED=$(echo "$source_line" | grep -oE 'activated: [0-9]{4}-[0-9]{2}-[0-9]{2}' | sed 's/activated: //')
      if [ -n "$ACTIVATED" ]; then
        if python3 -c "
import sys
from datetime import datetime
d=(datetime.now()-datetime.strptime('$ACTIVATED','%Y-%m-%d')).days
sys.exit(0 if d>30 else 1)
" 2>/dev/null; then
          STALE_ENTRIES="${STALE_ENTRIES}[pruned $(date +%Y-%m-%d)] $line
"
          STALE_ENTRIES="${STALE_ENTRIES}[pruned $(date +%Y-%m-%d)] $source_line
"
          PRUNED=$((PRUNED + 1))
          continue
        fi
      fi
      # Not pruned — keep both lines
      echo "$line" >> "$TMPFILE"
      echo "$source_line" >> "$TMPFILE"
      continue
    fi
    echo "$line" >> "$TMPFILE"
  done < "$WK_FILE"
  if [ "$PRUNED" -gt 0 ]; then
    cp "$TMPFILE" "$WK_FILE"
    printf '%s' "$STALE_ENTRIES" >> "$STALE_QUEUE"
    echo "[working-knowledge] Pruned $PRUNED stale entries (uses:1, >30 days). See .dev-wiki/.stale-queue."
  fi
  rm -f "$TMPFILE"
fi

# --- Enforcement status ---
if [ -f "$HOME/.claude/enforce" ]; then
  echo "[enforcement] active"
else
  echo "[enforcement] inactive (touch ~/.claude/enforce to enable)"
fi

exit 0
