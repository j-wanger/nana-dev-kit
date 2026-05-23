#!/usr/bin/env bash
# Inputs: MEMORY_DB (path), NUDGE_TS (path). Nudges if >500 active entries, weekly cooldown.

check_memory_consolidation() {
  local MEMORY_DB="$1"
  local NUDGE_TS="$2"

  [ -f "$MEMORY_DB" ] && command -v sqlite3 >/dev/null 2>&1 || return 0

  local SUPPRESS=false
  if [ -f "$NUDGE_TS" ]; then
    local LAST NOW DIFF
    LAST=$(cat "$NUDGE_TS" 2>/dev/null || echo "0")
    NOW=$(date +%s)
    DIFF=$(( NOW - LAST ))
    if [ "$DIFF" -lt 604800 ]; then
      SUPPRESS=true
    fi
  fi

  if [ "$SUPPRESS" = false ]; then
    local MCOUNT
    MCOUNT=$(timeout 2 sqlite3 "$MEMORY_DB" "SELECT COUNT(*) FROM memories WHERE is_active=1;" 2>/dev/null || echo "0")
    if [ "$MCOUNT" -gt 500 ] 2>/dev/null; then
      echo "[memory] $MCOUNT active entries. Consider running memory_consolidate."
      date +%s > "$NUDGE_TS"
    fi
  fi
}
