#!/usr/bin/env bash
# PreToolUse hook (Write|Edit|MultiEdit) — blocks implementation writes when the active phase's
# assumption-ledger block is absent or malformed, i.e. the dev-plan Step-13 assumption gate has not
# fired. Exit 0 = allow, Exit 2 = block (stderr shown to agent). Claude Code pipes tool input JSON to stdin.
#
# Phase 91: the checkable forcing-function BEHIND the assumption-gate prose. The Phase-90 fix was
# prose-only and did not bind (the gate was skipped a third time). This hook makes the durable ledger
# block a precondition for implementation, so the gate cannot be silently skipped. It enforces that the
# gate FIRED (a schema-valid block with positions exists) — not that the reasoning was good; all-accept
# remains allowed-but-warned by the gate itself.

set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true  # resolve project-relative refs regardless of CWD

# --- fail-open firing log (mirrors enforce-spec): one JSONL record, exit-code-neutral ---
log_firing() {
  [ -d ".dev-wiki" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0
  local action="${1:-}" reason="${2:-unspecified}" log=".dev-wiki/enforcement.log" phase ts
  phase=$(sed -n 's/^Phase: *\([0-9][0-9]*\).*/\1/p' ".claude/rules/active-phase.md" 2>/dev/null | head -n1) || true
  [ -n "$phase" ] || phase="unknown"
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || true
  { jq -nc --arg ts "$ts" --arg hook "enforce-assumption-gate" --arg action "$action" --arg reason "$reason" --arg phase "$phase" \
      '{schema_version:1,ts:$ts,hook:$hook,action:$action,reason:$reason,phase:$phase}' >> "$log"; } 2>/dev/null || return 0
  return 0
}

# --- Opt-in: disabled unless a project-local OR global enforce marker is present ---
if [ ! -f ".claude/enforce" ] && [ ! -f "$HOME/.claude/enforce" ]; then
  exit 0
fi

# --- Lifecycle: no dev-wiki means no enforcement ---
if [ ! -d ".dev-wiki" ]; then
  exit 0
fi

# --- jq required to parse the event; absent ⇒ fail-open ---
command -v jq >/dev/null 2>&1 || { echo "[nana:enforce-assumption-gate] jq not found, hook skipped" >&2; exit 0; }

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .input.file_path // empty' 2>/dev/null || echo "")
[ -z "$FILE_PATH" ] && exit 0

# --- Normalize to project-relative; outside-project (absolute) writes are not ours to gate ---
FILE_PATH="${FILE_PATH#"$PWD"/}"
case "$FILE_PATH" in
  /*) exit 0 ;;
esac

# --- Allowlist: meta/lifecycle/test/docs are always allowed (planning + the ledger itself live here) ---
case "$FILE_PATH" in
  .dev-wiki/*|.claude/*|wiki/*|specs/*|tests/*|templates/*) log_firing "allow" "allowlisted-path"; exit 0 ;;
  *_test.*|test_*.*|*_spec.*) log_firing "allow" "test-file"; exit 0 ;;
  *.md) log_firing "allow" "markdown"; exit 0 ;;
esac

# --- Locate the checker + ledger; fail-open (kit convention) if the apparatus is absent ---
CHECKER="scripts/check-assumption-ledger.sh"
LEDGER=".dev-wiki/assumption-ledger.md"
ACTIVE_PHASE=".claude/rules/active-phase.md"
[ -f "$CHECKER" ] || { log_firing "allow" "checker-absent"; exit 0; }
[ -f "$ACTIVE_PHASE" ] || { log_firing "allow" "no-active-phase"; exit 0; }

PHASE_LINE=$(grep -m1 '^Phase:' "$ACTIVE_PHASE" 2>/dev/null || true)
PHASE_NUM=$(echo "$PHASE_LINE" | grep -oE '[0-9]+' | head -1 || true)
[ -n "$PHASE_NUM" ] || { log_firing "allow" "no-phase-number"; exit 0; }

# --- Gate: the active phase must have positions recorded (--gate: a phase block with >=1 position
#     line). Whole-file --schema is deliberately NOT required — a malformed PRIOR-phase block (format
#     drift in older/consumer ledgers) must NOT false-block a properly-gated current phase (verified:
#     aml-substrate passes --gate for its active phase but fails whole-file --schema on an old block).
#     The gate enforces that positions were TAKEN for this phase, not whole-ledger well-formedness. ---
if [ -f "$LEDGER" ] \
   && bash "$CHECKER" --gate "$LEDGER" "$PHASE_NUM" >/dev/null 2>&1; then
  log_firing "allow" "gate-fired"
  exit 0
fi

log_firing "block" "gate-not-fired" || true
echo "[nana:enforce-assumption-gate] Phase $PHASE_NUM has no recorded assumption-gate positions. Run the dev-plan Step-13 gate (append a positions block for Phase $PHASE_NUM to $LEDGER) before writing implementation code." >&2
exit 2
