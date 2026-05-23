#!/usr/bin/env bash
# PostToolUse hook (Bash) — detects successful git commit, writes .pending-commit sidecar.
# Advisory only (stdout trigger, never blocks). All paths exit 0.
# Emits [dev-wiki:post-commit] for Claude to act on via dev-wiki-hooks rules.

set -euo pipefail

# --- Opt-in check ---
if [ ! -f "$HOME/.claude/enforce" ]; then
  exit 0
fi

# --- jq fail-open guard ---
command -v jq >/dev/null 2>&1 || { echo "[warn] jq not found, post-commit hook skipped" >&2; exit 0; }

INPUT=$(cat)

# --- Parse command and exit code ---
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")
EXIT_CODE=$(echo "$INPUT" | jq -r '.exit_code // empty' 2>/dev/null || echo "")

# --- Fast-path: not a git commit or failed ---
if [ -z "$COMMAND" ] || [ -z "$EXIT_CODE" ]; then
  exit 0
fi

case "$COMMAND" in
  *"git commit"*) ;;
  *"git "commit*) ;;
  *) exit 0 ;;
esac

if [ "$EXIT_CODE" != "0" ]; then
  exit 0
fi

# --- Skip amend/fixup/squash (not new work) ---
case "$COMMAND" in
  *--amend*|*--fixup*|*--squash*) exit 0 ;;
esac

# --- Lifecycle check: no dev-wiki means no tracking ---
if [ ! -d ".dev-wiki" ]; then
  exit 0
fi

# --- Capture commit metadata ---
HASH=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
MESSAGE=$(git log -1 --format='%s' HEAD 2>/dev/null || echo "")
FILES=$(git diff-tree --root --no-commit-id --name-only -r HEAD 2>/dev/null || echo "")

# --- Write .pending-commit as one-line JSON (overwrite) ---
FILES_JSON=$(echo "$FILES" | jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
MESSAGE_ESCAPED=$(echo "$MESSAGE" | jq -R -s '.[:-1]' 2>/dev/null || echo "")
printf '{"hash":"%s","message":%s,"files":%s}\n' "$HASH" "$MESSAGE_ESCAPED" "$FILES_JSON" > .dev-wiki/.pending-commit

# --- Emit trigger tag ---
echo "[dev-wiki:post-commit] Commit $HASH detected. Check .dev-wiki/.pending-commit for task matching."

exit 0
