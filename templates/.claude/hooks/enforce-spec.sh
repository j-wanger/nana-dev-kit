#!/usr/bin/env bash
# PreToolUse hook (Write|Edit) — blocks implementation writes without an approved spec.
# Exit 0 = allow, Exit 2 = block (stderr shown to agent).
# Claude Code pipes tool input JSON to stdin.

set -euo pipefail

LOG=".dev-wiki/enforcement.log"

log_event() {
  [ -d ".dev-wiki" ] || return 0
  local action="$1" reason="$2"
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"hook\":\"enforce-spec\",\"action\":\"$action\",\"reason\":\"$reason\"}" >> "$LOG"
  tail -n 500 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
}

# --- Opt-in check: disabled unless a project-local OR global marker is present ---
if [ ! -f ".claude/enforce" ] && [ ! -f "$HOME/.claude/enforce" ]; then
  exit 0
fi

# --- Lifecycle check: no dev-wiki means no enforcement ---
if [ ! -d ".dev-wiki" ]; then
  exit 0
fi

# --- Parse file path from stdin JSON ---
command -v jq >/dev/null 2>&1 || { echo "[nana:enforce-spec] jq not found, hook skipped" >&2; exit 0; }

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

# --- Gate check: active-phase.md has spec gate marked ---
ACTIVE_PHASE=".claude/rules/active-phase.md"
if [ -f "$ACTIVE_PHASE" ]; then
  if grep -q '\[x\] spec' "$ACTIVE_PHASE" 2>/dev/null; then
    log_event "allow" "gate-marked"
    exit 0
  fi
fi

# --- Spec file check: find phase slug, verify spec exists with provenance OR exit criteria ---
if [ -f "$ACTIVE_PHASE" ]; then
  PHASE_LINE=$(grep -m1 '^Phase:' "$ACTIVE_PHASE" 2>/dev/null || true)
  if [ -n "$PHASE_LINE" ]; then
    SLUG=$(echo "$PHASE_LINE" | sed 's/^Phase: *[0-9]* *- *//' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
    PHASE_NUM=$(echo "$PHASE_LINE" | grep -oE '[0-9]+' | head -1)
    SPEC_FILE="specs/phase-${PHASE_NUM}-${SLUG}.md"
    if [ -f "$SPEC_FILE" ]; then
      if grep -q 'nana:approved' "$SPEC_FILE" 2>/dev/null || grep -qE '^\- \[ \] `.+`' "$SPEC_FILE" 2>/dev/null; then
        log_event "allow" "spec-valid"
        exit 0
      fi
    fi
  fi
fi

log_event "block" "no-approved-spec"
echo "[nana:enforce-spec] No approved spec for active phase. Run /spec first." >&2
exit 2
