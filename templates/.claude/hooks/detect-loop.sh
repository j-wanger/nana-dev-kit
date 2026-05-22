#!/usr/bin/env bash
# PostToolUse hook (Bash) — detects repeated identical failing commands.
# Advisory only (stdout warning, never blocks). Pure bash for <50ms.
# Tracks command+exitcode in .claude/.loop-state (cleared each SessionStart).

set -euo pipefail

LOOP_STATE=".claude/.loop-state"

# Bail if no enforce marker (opt-in)
if [ ! -f "$HOME/.claude/enforce" ]; then
  exit 0
fi

INPUT=$(cat)

# Extract command and exit code via grep/sed (pure bash, no Python)
COMMAND=$(echo "$INPUT" | grep -o '"command" *: *"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//')
EXIT_CODE=$(echo "$INPUT" | grep -o '"exit_code" *: *[0-9]*' | head -1 | sed 's/.*: *//')

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
  echo "[loop-detected] Same command failed $COUNT times consecutively. Consider a different approach."
fi

exit 0
