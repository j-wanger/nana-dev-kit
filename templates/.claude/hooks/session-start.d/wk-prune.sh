#!/usr/bin/env bash
# Inputs: WK_FILE (path), STALE_QUEUE (path). Prunes [uses:1] entries older than 30 days.

prune_working_knowledge() {
  local WK_FILE="$1"
  local STALE_QUEUE="$2"

  [ -f "$WK_FILE" ] || return 0

  local TODAY_EPOCH
  TODAY_EPOCH=$(date +%s)
  local PRUNED=0
  local TMPFILE
  TMPFILE=$(mktemp)
  local STALE_ENTRIES=""

  while IFS= read -r line; do
    if [ "$PRUNED" -ge 5 ]; then
      echo "$line" >> "$TMPFILE"
      continue
    fi
    if echo "$line" | grep -q '^\- \[uses: 1\]' && ! echo "$line" | grep -q '\[pinned\]'; then
      read -r source_line || source_line=""
      local ACTIVATED
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
}
