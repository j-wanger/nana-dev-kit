#!/usr/bin/env bash
# PreToolUse hook for Bash tool — blocks dangerous commands.
# Exit 0 = allow, Exit 2 = block (stderr shown to Claude as reason).
# Claude Code pipes tool input JSON to stdin.

set -euo pipefail

command -v jq >/dev/null 2>&1 || { echo "[warn] jq not found, hook skipped" >&2; exit 0; }

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.input.command // empty' 2>/dev/null || echo "")

# Block rm -rf with dangerous targets
if echo "$COMMAND" | grep -qE 'rm\s+-[a-zA-Z]*r[a-zA-Z]*f.*(/|~|\$HOME|\.\.)'; then
  echo "Blocked: recursive force-delete targeting root, home, or parent directories. Use a more targeted rm command." >&2
  exit 2
fi

# Block force-push
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force|git\s+push\s+-f'; then
  echo "Blocked: force-push is not allowed. Open a PR instead, or use --force-with-lease if you must overwrite." >&2
  exit 2
fi

# Block --no-verify on commit/push
if echo "$COMMAND" | grep -qE 'git\s+(commit|push)\s+.*--no-verify'; then
  echo "Blocked: --no-verify bypasses pre-commit hooks. Fix the underlying hook failure instead." >&2
  exit 2
fi

# Block git reset --hard
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  echo "Blocked: git reset --hard discards uncommitted changes. Use git stash or git checkout for specific files." >&2
  exit 2
fi

exit 0
