#!/usr/bin/env bash
# PreToolUse hook (Write|Edit) — blocks implementation writes without an approved spec.
# Exit 0 = allow, Exit 2 = block (stderr shown to agent).
# Claude Code pipes tool input JSON to stdin.

set -euo pipefail

# --- Opt-in check: enforcement disabled without marker ---
if [ ! -f "$HOME/.claude/enforce" ]; then
  exit 0
fi

# --- Lifecycle check: no dev-wiki means no enforcement ---
if [ ! -d ".dev-wiki" ]; then
  exit 0
fi

# --- Parse file path from stdin JSON ---
command -v jq >/dev/null 2>&1 || { echo "[warn] jq not found, hook skipped" >&2; exit 0; }

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.input.file_path // empty' 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# --- Path allowlist: meta/lifecycle/test/docs are always allowed ---
case "$FILE_PATH" in
  .dev-wiki/*|.claude/*|wiki/*|specs/*|tests/*|templates/*) exit 0 ;;
  *_test.*|test_*.*|*_spec.*) exit 0 ;;
  *.md) exit 0 ;;
esac

# --- Gate check: active-phase.md has spec gate marked ---
ACTIVE_PHASE=".claude/rules/active-phase.md"
if [ -f "$ACTIVE_PHASE" ]; then
  if grep -q '\[x\] spec' "$ACTIVE_PHASE" 2>/dev/null; then
    exit 0
  fi
fi

# --- Spec file check: find phase slug, verify spec exists with valid exit criteria ---
if [ -f "$ACTIVE_PHASE" ]; then
  PHASE_LINE=$(grep -m1 '^Phase:' "$ACTIVE_PHASE" 2>/dev/null || true)
  if [ -n "$PHASE_LINE" ]; then
    SLUG=$(echo "$PHASE_LINE" | sed 's/^Phase: *[0-9]* *- *//' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
    PHASE_NUM=$(echo "$PHASE_LINE" | grep -oE '[0-9]+' | head -1)
    SPEC_FILE="specs/phase-${PHASE_NUM}-${SLUG}.md"
    if [ -f "$SPEC_FILE" ]; then
      if grep -qE '^\- \[ \] `.+`' "$SPEC_FILE" 2>/dev/null; then
        exit 0
      fi
    fi
  fi
fi

echo "No approved spec for active phase. Run /spec first." >&2
exit 2
