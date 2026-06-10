#!/usr/bin/env bash
# PreToolUse hook (Write|Edit) — blocks implementation writes without an approved spec.
# Exit 0 = allow, Exit 2 = block (stderr shown to agent).
# Claude Code pipes tool input JSON to stdin.

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
  { jq -nc --arg ts "$ts" --arg hook "enforce-spec" --arg action "$action" --arg reason "$reason" --arg phase "$phase" \
      '{schema_version:1,ts:$ts,hook:$hook,action:$action,reason:$reason,phase:$phase}' >> "$log"; } 2>/dev/null || return 0
  return 0
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
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .input.file_path // empty' 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# --- Normalize to a project-relative path (Phase 82): current events carry ABSOLUTE file_path,
# which silently bypassed every relative allowlist pattern below. Outside-project writes are not
# this project's gate to enforce - allow and exit.
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

# --- Gate check: active-phase.md has spec gate marked ---
ACTIVE_PHASE=".claude/rules/active-phase.md"
if [ -f "$ACTIVE_PHASE" ]; then
  if grep -q '\[x\] spec' "$ACTIVE_PHASE" 2>/dev/null; then
    log_firing "allow" "gate-marked"
    exit 0
  fi
fi

# --- Spec file check: find phase slug, verify spec exists with provenance OR exit criteria ---
if [ -f "$ACTIVE_PHASE" ]; then
  PHASE_LINE=$(grep -m1 '^Phase:' "$ACTIVE_PHASE" 2>/dev/null || true)
  if [ -n "$PHASE_LINE" ]; then
    # Phase 82: match the spec by phase NUMBER glob, not by reconstructing the slug - the old
    # sed assumed an ASCII "- " separator and a bare phase name, so an em-dash or any status
    # suffix in active-phase.md broke the lookup and blocked despite a valid approved spec.
    PHASE_NUM=$(echo "$PHASE_LINE" | grep -oE '[0-9]+' | head -1)
    for SPEC_FILE in "specs/phase-${PHASE_NUM}-"*.md; do
      if [ -f "$SPEC_FILE" ]; then
        if grep -q 'nana:approved' "$SPEC_FILE" 2>/dev/null || grep -qE '^\- \[ \] `.+`' "$SPEC_FILE" 2>/dev/null; then
          log_firing "allow" "spec-valid"
          exit 0
        fi
      fi
    done
  fi
fi

log_firing "block" "no-approved-spec" || true
echo "[nana:enforce-spec] No approved spec for active phase. Run /spec first." >&2
exit 2
