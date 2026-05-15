#!/usr/bin/env bash
# Stop hook — blocks Claude from declaring "done" if pytest hasn't been run.
# Claude Code pipes session context JSON to stdin.
# Exit 0 = allow stop, Exit 2 = force Claude to keep working (stderr shown as reason).

set -euo pipefail

INPUT=$(cat)

# Check if any Python files were modified in this session
HAS_PY_CHANGES=$(echo "$INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tool_uses = data.get('tool_uses', [])
for t in tool_uses:
    inp = t.get('input', {})
    fp = inp.get('file_path', '') or inp.get('command', '')
    if '.py' in fp:
        print('yes')
        sys.exit(0)
print('no')
" 2>/dev/null || echo "no")

# If no Python files were touched, allow stop
if [ "$HAS_PY_CHANGES" = "no" ]; then
  exit 0
fi

# Check if pytest was run at any point
PYTEST_RAN=$(echo "$INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tool_uses = data.get('tool_uses', [])
for t in tool_uses:
    cmd = t.get('input', {}).get('command', '')
    if 'pytest' in cmd:
        print('yes')
        sys.exit(0)
print('no')
" 2>/dev/null || echo "no")

if [ "$PYTEST_RAN" = "no" ]; then
  echo "You modified Python files but haven't run the test suite yet. Run: uv run pytest -x --cov=src --cov-fail-under=85" >&2
  exit 2
fi

exit 0
