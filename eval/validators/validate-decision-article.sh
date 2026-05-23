#!/usr/bin/env bash
# Validates a decision article against required frontmatter and structure.
# Usage: bash validate-decision-article.sh <article-file>
# Exit 0 = valid, Exit 1 = invalid

set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "Missing or nonexistent decision article" >&2
  exit 1
fi

ERRORS=0

check() {
  if ! eval "$1" 2>/dev/null; then
    echo "FAIL: $2" >&2
    ERRORS=$((ERRORS + 1))
  fi
}

check "head -1 \"$FILE\" | grep -q '^---'" "Missing frontmatter opening ---"
check "grep -q '^confidence:' \"$FILE\"" "Missing confidence: field"
check "grep -qE '^confidence: (low|medium|high)' \"$FILE\"" "Invalid confidence value"
check "grep -q '^source:' \"$FILE\"" "Missing source: field"
check "grep -q '^# ' \"$FILE\"" "Missing H1 title"

[ "$ERRORS" -eq 0 ]
