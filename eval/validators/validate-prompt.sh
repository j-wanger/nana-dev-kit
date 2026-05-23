#!/usr/bin/env bash
# Validates prompt artifact files (e.g., py-review-stop-prompt.md).
# Checks: numbered checklist items present, format directive present.
# Usage: bash validate-prompt.sh <file>
# Exit 0 = valid, Exit 1 = invalid

set -euo pipefail

FILE="${1:-}"
[ -z "$FILE" ] && { echo "Usage: validate-prompt.sh <file>" >&2; exit 1; }
[ ! -f "$FILE" ] && { echo "File not found: $FILE" >&2; exit 1; }

ERRORS=0

if ! grep -qE '^[0-9]+\.' "$FILE"; then
  echo "FAIL: no numbered checklist items found" >&2
  ERRORS=$((ERRORS + 1))
fi

if ! grep -qiE 'format|finding' "$FILE"; then
  echo "FAIL: no format directive found" >&2
  ERRORS=$((ERRORS + 1))
fi

if [ "$(grep -cE '^[0-9]+\.' "$FILE")" -lt 3 ]; then
  echo "FAIL: fewer than 3 numbered items" >&2
  ERRORS=$((ERRORS + 1))
fi

[ "$ERRORS" -eq 0 ] && exit 0 || exit 1
