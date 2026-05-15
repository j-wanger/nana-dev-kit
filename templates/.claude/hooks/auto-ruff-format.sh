#!/usr/bin/env bash
# PostToolUse hook for Write/Edit/MultiEdit — auto-formats Python files with ruff.
# Runs silently on .py files; skips non-Python files.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('input',{}).get('file_path',''))" 2>/dev/null || echo "")

if [[ "$FILE_PATH" == *.py ]] && command -v uv &>/dev/null; then
  uv run ruff check --fix --quiet "$FILE_PATH" 2>/dev/null || true
  uv run ruff format --quiet "$FILE_PATH" 2>/dev/null || true
fi

exit 0
