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

# Session activity. Real Stop events carry transcript_path (JSONL, one event per line); the legacy
# .tool_uses array is used only by eval scenarios + tests. In BOTH shapes we separate WRITE-class
# FILE activity (Condition 1) from Bash COMMAND activity (Condition 2): a filename must not satisfy
# the command check, and a command string must not satisfy the .py check.
# Phase 88 (HEU-007): the transcript .py condition keys on WRITE-CLASS tools only (a Read of a .py
# during analysis is not "modified"). Phase 99: jq -R 'fromjson?' parses each line independently and
# SKIPS a malformed/truncated line (a partial-flush line must not abort the scan and false-block).
TOOL_ACTIVITY=$(echo "$INPUT" | jq -r '[.tool_uses[]?.input | (.file_path // .command // "")] | join("\n")' 2>/dev/null || echo "")
WRITE_ACTIVITY=$(echo "$INPUT" | jq -r '[.tool_uses[]?.input.file_path // empty] | join("\n")' 2>/dev/null || echo "")
CMD_ACTIVITY=$(echo "$INPUT" | jq -r '[.tool_uses[]?.input.command // empty] | join("\n")' 2>/dev/null || echo "")
if [ -z "$TOOL_ACTIVITY" ]; then
  TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")
  if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    WRITE_ACTIVITY=$(jq -rR 'fromjson? | select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")
      | select(.name == "Write" or .name == "Edit" or .name == "MultiEdit" or .name == "NotebookEdit")
      | .input.file_path // ""' "$TRANSCRIPT" 2>/dev/null || echo "")
    CMD_ACTIVITY=$(jq -rR 'fromjson? | select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | select(.name == "Bash") | .input.command // ""' "$TRANSCRIPT" 2>/dev/null || echo "")
  fi
fi

# Condition 1: a Python SOURCE file was MODIFIED this session — write-class only, extension-anchored
# (\.py$) so .pyc / app.py.bak / notes.python.md do NOT count (Ph99 false-block fix).
HAS_PY_CHANGES=$(printf '%s' "$WRITE_ACTIVITY" | grep -qE '\.py$' && echo true || echo false)

# If no Python files were touched, allow stop
if [ "$HAS_PY_CHANGES" != "true" ]; then
  log_firing skipped no-py-changes || true
  exit 0
fi

# Condition 2: a test command was actually RUN this session. Satisfied by pytest (consuming Python
# projects, any form — uv run / python -m / poetry run) OR `make test`/`make eval` (shell-tested
# projects like nana-dev-kit, which has NO pytest — Ph85/Ph99 dogfood). `make` is anchored to a
# command position and tolerates flags/vars before the target (make -j4 test, make -C dir test) so a
# real invocation matches while a quoted mention (git commit -m "make test") does not. COMMANDS only.
TEST_RAN=$(printf '%s' "$CMD_ACTIVITY" | grep -Eq 'pytest|(^|[[:space:];&|])make([[:space:]]+[^[:space:]]+)*[[:space:]]+(test|eval)([[:space:]]|$)' && echo true || echo false)

if [ "$TEST_RAN" != "true" ]; then
  log_firing block tests-not-run || true
  echo "[nana:tests] You modified Python files but haven't run the test suite yet. Run your tests (e.g. \`uv run pytest -x --cov=src --cov-fail-under=85\`, or \`make test\` for shell-tested projects)." >&2
  exit 2
fi

log_firing allow tests-ran || true
exit 0
