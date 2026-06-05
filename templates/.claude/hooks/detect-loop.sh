#!/usr/bin/env bash
# PostToolUse hook (Bash) — detects repeated identical failing commands.
# Advisory only (stdout warning, never blocks). Pure bash for <50ms.
# Tracks command+exitcode in .claude/.loop-state (cleared each SessionStart).

set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true  # Phase 79: resolve project-relative refs regardless of CWD

# --- Phase 65 fail-open firing log: one JSONL record {schema_version,ts,hook,action,reason,phase} ---
# Exit-code-neutral (never aborts the hook under set -e); records controlled-vocab reasons only,
# never raw paths/commands (the bash command is NEVER logged). Gate = .dev-wiki present. Call: log_firing <action> <reason>
log_firing() {
  [ -d ".dev-wiki" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0
  local action="${1:-}" reason="${2:-unspecified}" log=".dev-wiki/enforcement.log" phase ts
  phase=$(sed -n 's/^Phase: *\([0-9][0-9]*\).*/\1/p' ".claude/rules/active-phase.md" 2>/dev/null | head -n1) || true
  [ -n "$phase" ] || phase="unknown"
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || true
  { jq -nc --arg ts "$ts" --arg hook "detect-loop" --arg action "$action" --arg reason "$reason" --arg phase "$phase" \
      '{schema_version:1,ts:$ts,hook:$hook,action:$action,reason:$reason,phase:$phase}' >> "$log"; } 2>/dev/null || return 0
  return 0
}

LOOP_STATE=".claude/.loop-state"

# Bail if no enforce marker (opt-in)
if [ ! -f "$HOME/.claude/enforce" ]; then
  exit 0
fi

INPUT=$(cat)

# Extract command and exit code via grep/sed (pure bash, no Python)
COMMAND=$(echo "$INPUT" | grep -o '"command" *: *"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//' || true)
EXIT_CODE=$(echo "$INPUT" | grep -o '"exit_code" *: *[0-9]*' | head -1 | sed 's/.*: *//' || true)

# Skip if we couldn't parse either field
if [ -z "$COMMAND" ] || [ -z "$EXIT_CODE" ]; then
  exit 0
fi

# Skip successful commands
if [ "$EXIT_CODE" = "0" ]; then
  # Reset state on success
  rm -f "$LOOP_STATE"
  exit 0
fi

# Build signature
SIG="${COMMAND}:${EXIT_CODE}"

# Ensure state dir exists
mkdir -p "$(dirname "$LOOP_STATE")" 2>/dev/null || true

# Check if last entry matches — if different command, reset
if [ -f "$LOOP_STATE" ]; then
  LAST=$(tail -1 "$LOOP_STATE" 2>/dev/null || true)
  if [ "$LAST" != "$SIG" ]; then
    printf '%s\n' "$SIG" > "$LOOP_STATE"
    exit 0
  fi
fi

# Append this signature
printf '%s\n' "$SIG" >> "$LOOP_STATE"

# Count consecutive identical entries
COUNT=$(wc -l < "$LOOP_STATE" 2>/dev/null | tr -d ' ')

if [ "$COUNT" -ge 3 ] 2>/dev/null; then
  echo "[nana:loop] Same command failed $COUNT times consecutively. Consider a different approach."
  log_firing advisory repeated-failure || true
fi

exit 0
