#!/usr/bin/env bash
# PreToolUse hook (Write|Edit) — warns when editing files outside the active task's scope.
# Emits [dev-wiki:scope-check] for Claude to act on via dev-wiki-hooks rules.

set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
[ -d "$ROOT/.dev-wiki" ] && [ -f "$ROOT/.dev-wiki/tasks.md" ] || exit 0

# --- jq fail-open guard ---
command -v jq >/dev/null 2>&1 || { echo "[nana:scope-check] jq not found, hook skipped" >&2; exit 0; }

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")
[ -z "$FILE_PATH" ] && exit 0

# Always allow dev-wiki state, project rules, and knowledge wiki paths
case "$FILE_PATH" in
  "$ROOT/.dev-wiki/"* | "$ROOT/.claude/rules/"* | "$ROOT/wiki/"* ) exit 0 ;;
esac

# Find first open task in tasks.md
TASK_LINE=$(grep -m1 '^- \[ \]' "$ROOT/.dev-wiki/tasks.md" 2>/dev/null || echo "")
if [ -z "$TASK_LINE" ]; then
  echo '[dev-wiki:scope-check] No open tasks in tasks.md.'
  exit 0
fi

# Extract scope field: between "| scope:" and "| success:" (or end of line)
SCOPE_RAW=$(echo "$TASK_LINE" | sed -n 's/.*| scope: *\(.*\)| success:.*/\1/p')
[ -z "$SCOPE_RAW" ] && exit 0

# Strip backticks, split by comma, check each glob
SCOPE_CLEAN=$(echo "$SCOPE_RAW" | sed 's/`//g')
MATCHED=false
IFS=',' read -ra GLOBS <<< "$SCOPE_CLEAN"
for GLOB in "${GLOBS[@]}"; do
  GLOB=$(echo "$GLOB" | sed 's/^ *//;s/ *$//')
  [ -z "$GLOB" ] && continue
  GLOB="${GLOB/#\~/$HOME}"
  [[ "$GLOB" != /* ]] && GLOB="$ROOT/$GLOB"
  if [[ "$FILE_PATH" == $GLOB ]]; then
    MATCHED=true
    break
  fi
done

if [ "$MATCHED" = false ]; then
  echo "[dev-wiki:scope-check] $FILE_PATH is outside active task scope."
fi

exit 0
