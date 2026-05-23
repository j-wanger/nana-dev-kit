#!/usr/bin/env bash
# Validates a spec file against the 9-section contract.
# Usage: bash validate-spec.sh <spec-file>
# Exit 0 = valid, Exit 1 = invalid

set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "Missing or nonexistent spec file" >&2
  exit 1
fi

ERRORS=0

check() {
  if ! eval "$1" 2>/dev/null; then
    echo "FAIL: $2" >&2
    ERRORS=$((ERRORS + 1))
  fi
}

check "grep -q '^## Objective' \"$FILE\"" "Missing ## Objective"
check "grep -q '^## Context' \"$FILE\"" "Missing ## Context"
check "grep -q '^## Scope' \"$FILE\"" "Missing ## Scope"
check "grep -q '^### In scope' \"$FILE\"" "Missing ### In scope"
check "grep -q '^### Out of scope' \"$FILE\"" "Missing ### Out of scope"
check "grep -q '^## Approach' \"$FILE\"" "Missing ## Approach"
check "grep -q '^## Constraints' \"$FILE\"" "Missing ## Constraints"
check "grep -q '^## Deliverables' \"$FILE\"" "Missing ## Deliverables"
check "grep -q '^## Exit Criteria' \"$FILE\"" "Missing ## Exit Criteria"
check "grep -q '^## Checkpoints' \"$FILE\"" "Missing ## Checkpoints"
check "grep -q '^## Assumptions' \"$FILE\"" "Missing ## Assumptions"

check "grep -cE '^\- \[ \] \x60' \"$FILE\" | grep -qv '^0$'" "No exit criteria with backtick commands"
check "grep -A50 '^## Constraints' \"$FILE\" | grep -q '^- '" "No constraint bullets"
check "grep -A50 '^## Checkpoints' \"$FILE\" | grep -q '^- '" "No checkpoint bullets"
check "grep -A50 '^## Assumptions' \"$FILE\" | grep -qiE 'if (false|missing|absent|unavailable)'" "No assumption fallbacks"

[ "$ERRORS" -eq 0 ]
