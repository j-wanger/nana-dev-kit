#!/usr/bin/env bash
# PostToolUse hook for Write/Edit/MultiEdit — scans written file for secrets.
# Uses gitleaks if available; falls back to pattern matching.

set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true  # Phase 79: resolve project-relative refs regardless of CWD

command -v jq >/dev/null 2>&1 || { echo "[nana:secrets] jq not found, hook skipped" >&2; exit 0; }

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .input.file_path // empty' 2>/dev/null || echo "")

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

if command -v gitleaks &>/dev/null; then
  if ! gitleaks detect --no-git --source "$FILE_PATH" --quiet 2>/dev/null; then
    echo "[nana:secrets] gitleaks detected potential secrets in $FILE_PATH. Review before committing." >&2
  fi
else
  # Fallback: basic pattern matching for common secret formats
  if grep -qEi '(api[_-]?key|secret[_-]?key|password|token|credential)\s*[=:]\s*["'"'"'][A-Za-z0-9+/=_-]{16,}' "$FILE_PATH" 2>/dev/null; then
    echo "[nana:secrets] potential hardcoded secret detected in $FILE_PATH. Review before committing." >&2
  fi
fi

exit 0
