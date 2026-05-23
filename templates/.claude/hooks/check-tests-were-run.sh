#!/usr/bin/env bash
# Stop hook — blocks Claude from declaring "done" if pytest hasn't been run.
# Claude Code pipes session context JSON to stdin.
# Exit 0 = allow stop, Exit 2 = force Claude to keep working (stderr shown as reason).

set -euo pipefail

command -v jq >/dev/null 2>&1 || { echo "[warn] jq not found, hook skipped" >&2; exit 0; }

INPUT=$(cat)

# Check if any Python files were modified in this session
HAS_PY_CHANGES=$(echo "$INPUT" | jq -r '[.tool_uses[].input | (.file_path // .command // "")] | any(contains(".py"))' 2>/dev/null || echo "false")

# If no Python files were touched, allow stop
if [ "$HAS_PY_CHANGES" != "true" ]; then
  exit 0
fi

# Check if pytest was run at any point
PYTEST_RAN=$(echo "$INPUT" | jq -r '[.tool_uses[].input.command // ""] | any(contains("pytest"))' 2>/dev/null || echo "false")

if [ "$PYTEST_RAN" != "true" ]; then
  echo "You modified Python files but haven't run the test suite yet. Run: uv run pytest -x --cov=src --cov-fail-under=85" >&2
  exit 2
fi

exit 0
