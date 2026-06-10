#!/usr/bin/env bash
# PostToolUse hook (Bash) — detects a successful git commit, writes .pending-commit sidecar.
# Advisory only (stdout trigger, never blocks). All paths exit 0.
# Emits [dev-wiki:post-commit] for Claude to act on via dev-wiki-hooks rules.
# Phase 84 redesign: the platform delivers NO exit code in PostToolUse events and fires the
# event ONLY for successful tool calls (live-capture evidence: eval/hook-hygiene/
# capture-diagnosis.md), so event arrival is the success signal. A legacy top-level .exit_code,
# if present, is honored as a failure guard; a textual prefilter + git-state recency
# confirmation rejects mention-only commands and compound commands whose commit failed.

set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true  # Phase 79: resolve project-relative refs regardless of CWD

# --- Opt-in check: project-local OR global marker (Phase 84: project-local was ignored) ---
if [ ! -f ".claude/enforce" ] && [ ! -f "$HOME/.claude/enforce" ]; then
  exit 0
fi

# --- jq fail-open guard ---
command -v jq >/dev/null 2>&1 || { echo "[nana:post-commit] jq not found, post-commit hook skipped" >&2; exit 0; }

INPUT=$(cat)

# --- Parse command (canonical .tool_input, legacy .input fallback) ---
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // .input.command // empty' 2>/dev/null || echo "")

# --- Fail-loud on signal absence (HEU-002): a Bash event without a command is an anomaly ---
if [ -z "$COMMAND" ]; then
  echo "[nana:post-commit] event carried no command field (signal absence) — skipped" >&2
  exit 0
fi

# --- Legacy failure guard: old-shape events carried a top-level exit code; honor it ---
LEGACY_EXIT=$(echo "$INPUT" | jq -r '.exit_code // empty' 2>/dev/null || echo "")
if [ -n "$LEGACY_EXIT" ] && [ "$LEGACY_EXIT" != "0" ]; then
  exit 0
fi

# --- Textual prefilter: cheap reject of non-commit commands; loose on purpose (catches
# --- flag-interleaved `git -c … commit`) — the git-state confirmation below is the real gate.
case "$COMMAND" in
  *git*commit*) ;;
  *) exit 0 ;;
esac

# --- Skip amend/fixup/squash (not new work) ---
case "$COMMAND" in
  *--amend*|*--fixup*|*--squash*) exit 0 ;;
esac

# --- Lifecycle check: no dev-wiki means no tracking ---
if [ ! -d ".dev-wiki" ]; then
  exit 0
fi

# --- Git-state confirmation: a commit must exist and be recent (<=120s). Rejects mention-only
# --- commands (old HEAD) and compound commands whose commit failed but the pipeline succeeded.
HASH=$(git rev-parse HEAD 2>/dev/null || echo "")
if [ -z "$HASH" ]; then
  exit 0
fi
COMMIT_TS=$(git log -1 --format=%ct HEAD 2>/dev/null || echo 0)
NOW=$(date +%s)
if [ $((NOW - COMMIT_TS)) -gt 120 ]; then
  exit 0
fi

# --- Capture commit metadata ---
MESSAGE=$(git log -1 --format='%s' HEAD 2>/dev/null || echo "")
FILES=$(git diff-tree --root --no-commit-id --name-only -r HEAD 2>/dev/null || echo "")

# --- Write .pending-commit as one-line JSON (overwrite) ---
FILES_JSON=$(echo "$FILES" | jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
MESSAGE_ESCAPED=$(echo "$MESSAGE" | jq -R -s '.[:-1]' 2>/dev/null || echo "")
printf '{"hash":"%s","message":%s,"files":%s}\n' "$HASH" "$MESSAGE_ESCAPED" "$FILES_JSON" > .dev-wiki/.pending-commit

# --- Emit trigger tag ---
echo "[dev-wiki:post-commit] Commit $HASH detected. Check .dev-wiki/.pending-commit for task matching."

exit 0
