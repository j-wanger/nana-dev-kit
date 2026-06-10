#!/usr/bin/env bash
# PreToolUse hook (Write|Edit) — warns when editing files outside the active task's scope.
# Emits [dev-wiki:scope-check] for Claude to act on via dev-wiki-hooks rules.

set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true  # Phase 79: resolve project-relative refs regardless of CWD

# --- Phase 65 fail-open firing log: one JSONL record {schema_version,ts,hook,action,reason,phase} ---
# Exit-code-neutral (never aborts the hook under set -e); records controlled-vocab reasons only,
# never raw paths/commands. Gate = .dev-wiki present (the log lives there; same gate as the enforce-*
# loggers). Append-only + atomic (single >>; no read-modify-write truncation). Call: log_firing <action> <reason>
log_firing() {
  [ -d ".dev-wiki" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0
  local action="${1:-}" reason="${2:-unspecified}" log=".dev-wiki/enforcement.log" phase ts
  phase=$(sed -n 's/^Phase: *\([0-9][0-9]*\).*/\1/p' ".claude/rules/active-phase.md" 2>/dev/null | head -n1) || true
  [ -n "$phase" ] || phase="unknown"
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || true
  { jq -nc --arg ts "$ts" --arg hook "dev-wiki-scope-check" --arg action "$action" --arg reason "$reason" --arg phase "$phase" \
      '{schema_version:1,ts:$ts,hook:$hook,action:$action,reason:$reason,phase:$phase}' >> "$log"; } 2>/dev/null || return 0
  return 0
}

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
[ -d "$ROOT/.dev-wiki" ] && [ -f "$ROOT/.dev-wiki/tasks.md" ] || exit 0

# --- jq fail-open guard ---
command -v jq >/dev/null 2>&1 || { echo "[nana:scope-check] jq not found, hook skipped" >&2; exit 0; }

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .input.file_path // empty' 2>/dev/null || echo "")
[ -z "$FILE_PATH" ] && exit 0

# Normalize to ABSOLUTE (Phase 82): the allowlist and the glob matcher below are written against
# $ROOT-prefixed absolute paths, but events may carry project-relative paths — absolutize those.
[[ "$FILE_PATH" != /* ]] && FILE_PATH="$ROOT/$FILE_PATH"

# Always allow dev-wiki state, project rules, and knowledge wiki paths
case "$FILE_PATH" in
  "$ROOT/.dev-wiki/"* | "$ROOT/.claude/rules/"* | "$ROOT/wiki/"* ) log_firing allow allowlisted-path || true; exit 0 ;;
esac

# Find first open task in tasks.md
TASK_LINE=$(grep -m1 '^- \[ \]' "$ROOT/.dev-wiki/tasks.md" 2>/dev/null || echo "")
if [ -z "$TASK_LINE" ]; then
  echo '[dev-wiki:scope-check] No open tasks in tasks.md.'
  log_firing skipped no-open-tasks || true
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
  log_firing advisory out-of-scope || true
else
  log_firing allow in-scope || true
fi

exit 0
