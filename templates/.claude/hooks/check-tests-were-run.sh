#!/usr/bin/env bash
# Stop hook — blocks Claude from declaring "done" if pytest hasn't been run.
# Claude Code pipes session context JSON to stdin.
# Exit 0 = allow stop, Exit 2 = force Claude to keep working (stderr shown as reason).

set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true  # Phase 79: resolve project-relative refs regardless of CWD

# --- Phase 65 fail-open firing log: one JSONL record {schema_version,ts,hook,action,reason,phase} ---
# Exit-code-neutral (never aborts the hook under set -e); records controlled-vocab reasons only,
# never raw paths/commands. Gate = .dev-wiki present (the log lives there). Call: log_firing <action> <reason>
log_firing() {
  [ -d ".dev-wiki" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0
  local action="${1:-}" reason="${2:-unspecified}" log=".dev-wiki/enforcement.log" phase ts
  phase=$(sed -n 's/^Phase: *\([0-9][0-9]*\).*/\1/p' ".claude/rules/active-phase.md" 2>/dev/null | head -n1) || true
  [ -n "$phase" ] || phase="unknown"
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || true
  { jq -nc --arg ts "$ts" --arg hook "check-tests-were-run" --arg action "$action" --arg reason "$reason" --arg phase "$phase" \
      '{schema_version:1,ts:$ts,hook:$hook,action:$action,reason:$reason,phase:$phase}' >> "$log"; } 2>/dev/null || return 0
  return 0
}

command -v jq >/dev/null 2>&1 || { echo "[nana:tests] jq not found, hook skipped" >&2; exit 0; }

INPUT=$(cat)

# Check if any Python files were modified in this session
HAS_PY_CHANGES=$(echo "$INPUT" | jq -r '[.tool_uses[].input | (.file_path // .command // "")] | any(contains(".py"))' 2>/dev/null || echo "false")

# If no Python files were touched, allow stop
if [ "$HAS_PY_CHANGES" != "true" ]; then
  log_firing skipped no-py-changes || true
  exit 0
fi

# Check if pytest was run at any point
PYTEST_RAN=$(echo "$INPUT" | jq -r '[.tool_uses[].input.command // ""] | any(contains("pytest"))' 2>/dev/null || echo "false")

if [ "$PYTEST_RAN" != "true" ]; then
  log_firing block tests-not-run || true
  echo "[nana:tests] You modified Python files but haven't run the test suite yet. Run: uv run pytest -x --cov=src --cov-fail-under=85" >&2
  exit 2
fi

log_firing allow tests-ran || true
exit 0
