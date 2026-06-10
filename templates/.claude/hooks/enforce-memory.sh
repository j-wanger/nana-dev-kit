#!/usr/bin/env bash
# PreToolUse hook (Write|Edit) — blocks implementation writes without memory_search.
# Exit 0 = allow, Exit 2 = block (stderr shown to agent).
# Opt-in via ~/.claude/enforce-memory marker (separate from .claude/enforce).

set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true  # Phase 79: resolve project-relative refs regardless of CWD

# --- Phase 65 fail-open firing log: one JSONL record {schema_version,ts,hook,action,reason,phase} ---
# Exit-code-neutral (never aborts the hook under set -e); records controlled-vocab reasons only,
# never raw paths/commands. Gate = .dev-wiki present (the log lives there). Append-only + atomic
# (single >>; no read-modify-write truncation — that raced under concurrent fires). Call: log_firing <action> <reason>
log_firing() {
  [ -d ".dev-wiki" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0
  local action="${1:-}" reason="${2:-unspecified}" log=".dev-wiki/enforcement.log" phase ts
  phase=$(sed -n 's/^Phase: *\([0-9][0-9]*\).*/\1/p' ".claude/rules/active-phase.md" 2>/dev/null | head -n1) || true
  [ -n "$phase" ] || phase="unknown"
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || true
  { jq -nc --arg ts "$ts" --arg hook "enforce-memory" --arg action "$action" --arg reason "$reason" --arg phase "$phase" \
      '{schema_version:1,ts:$ts,hook:$hook,action:$action,reason:$reason,phase:$phase}' >> "$log"; } 2>/dev/null || return 0
  return 0
}

# --- Opt-in check: disabled unless a project-local OR global marker is present ---
if [ ! -f ".claude/enforce-memory" ] && [ ! -f "$HOME/.claude/enforce-memory" ]; then
  exit 0
fi

# --- CI bypass: MCP tools unavailable in CI ---
if [ "${CI:-}" = "true" ]; then
  exit 0
fi

# --- Lifecycle check: no dev-wiki means no enforcement ---
if [ ! -d ".dev-wiki" ]; then
  exit 0
fi

# --- Parse file path from stdin JSON ---
command -v jq >/dev/null 2>&1 || { echo "[nana:enforce-memory] jq not found, hook skipped" >&2; exit 0; }

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .input.file_path // empty' 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Normalize to project-relative (Phase 82): absolute event paths bypassed the relative patterns
# below; outside-project writes are not this project's gate to enforce.
FILE_PATH="${FILE_PATH#"$PWD"/}"
case "$FILE_PATH" in
  /*) exit 0 ;;
esac

# --- Path allowlist: meta/lifecycle/test/docs are always allowed ---
case "$FILE_PATH" in
  .dev-wiki/*|.claude/*|wiki/*|specs/*|tests/*|templates/*) log_firing "allow" "allowlisted-path"; exit 0 ;;
  *_test.*|test_*.*|*_spec.*) log_firing "allow" "test-file"; exit 0 ;;
  *.md) log_firing "allow" "markdown"; exit 0 ;;
esac

# --- Memory gate check ---
if [ -f ".claude/.memory-consulted" ]; then
  log_firing "allow" "memory-consulted"
  exit 0
fi

log_firing "block" "no-memory-search" || true
echo "[nana:enforce-memory] No memory_search detected this session. Call memory_search, then touch .claude/.memory-consulted" >&2
exit 2
