#!/usr/bin/env bash
# Validates a phase article against required frontmatter and structure.
# Usage: bash validate-phase-article.sh <article-file>
# Exit 0 = valid, Exit 1 = invalid

set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "Missing or nonexistent phase article" >&2
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
check "grep -q '^status:' \"$FILE\"" "Missing status: field"
check "grep -q '^created:' \"$FILE\"" "Missing created: field"
check "grep -q '^updated:' \"$FILE\"" "Missing updated: field"
check "grep -qE '^status: (not-started|active|completed|blocked)' \"$FILE\"" "Invalid status value"
check "grep -q '^# ' \"$FILE\"" "Missing H1 title"

[ "$ERRORS" -eq 0 ]
