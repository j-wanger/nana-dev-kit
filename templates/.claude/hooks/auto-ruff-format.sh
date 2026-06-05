#!/usr/bin/env bash
# PostToolUse hook for Write/Edit/MultiEdit — auto-formats Python files with ruff.
# Runs silently on .py files; skips non-Python files.

set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true  # Phase 79: resolve project-relative refs regardless of CWD

command -v jq >/dev/null 2>&1 || { echo "[nana:ruff] jq not found, hook skipped" >&2; exit 0; }

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .input.file_path // empty' 2>/dev/null || echo "")

if [[ "$FILE_PATH" == *.py ]] && command -v uv &>/dev/null; then
  uv run ruff check --fix --quiet "$FILE_PATH" 2>/dev/null || true
  uv run ruff format --quiet "$FILE_PATH" 2>/dev/null || true
fi

exit 0
