#!/usr/bin/env bash
# PreToolUse hook (Write|Edit) — blocks implementation writes without memory_search.
# Exit 0 = allow, Exit 2 = block (stderr shown to agent).
# Opt-in via ~/.claude/enforce-memory marker (separate from .claude/enforce).

set -euo pipefail

LOG=".dev-wiki/enforcement.log"

log_event() {
  [ -d ".dev-wiki" ] || return 0
  local action="$1" reason="$2"
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"hook\":\"enforce-memory\",\"action\":\"$action\",\"reason\":\"$reason\"}" >> "$LOG"
  tail -n 500 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
}

# --- Opt-in check: disabled without marker ---
if [ ! -f "$HOME/.claude/enforce-memory" ]; then
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
FILE_PATH=$(echo "$INPUT" | jq -r '.input.file_path // empty' 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# --- Path allowlist: meta/lifecycle/test/docs are always allowed ---
case "$FILE_PATH" in
  .dev-wiki/*|.claude/*|wiki/*|specs/*|tests/*|templates/*) log_event "allow" "allowlisted-path"; exit 0 ;;
  *_test.*|test_*.*|*_spec.*) log_event "allow" "test-file"; exit 0 ;;
  *.md) log_event "allow" "markdown"; exit 0 ;;
esac

# --- Memory gate check ---
if [ -f ".claude/.memory-consulted" ]; then
  log_event "allow" "memory-consulted"
  exit 0
fi

log_event "block" "no-memory-search"
echo "[nana:enforce-memory] No memory_search detected this session. Call memory_search, then touch .claude/.memory-consulted" >&2
exit 2
