#!/usr/bin/env bash
# Stop hook — checks deliverable files from spec exit criteria and advises on debrief.
# Exit 0 = allow stop, Exit 2 = block (stderr shown as reason).
# Claude Code pipes session context JSON to stdin.

set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true  # Phase 79: resolve project-relative refs regardless of CWD

INPUT=$(cat)

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
  { jq -nc --arg ts "$ts" --arg hook "enforce-loop" --arg action "$action" --arg reason "$reason" --arg phase "$phase" \
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

# --- Determine active phase slug ---
ACTIVE_PHASE=".claude/rules/active-phase.md"
if [ ! -f "$ACTIVE_PHASE" ]; then
  exit 0
fi

PHASE_LINE=$(grep -m1 '^Phase:' "$ACTIVE_PHASE" 2>/dev/null || true)
if [ -z "$PHASE_LINE" ]; then
  exit 0
fi

SLUG=$(echo "$PHASE_LINE" | sed 's/^Phase: *[0-9]* *- *//' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
PHASE_NUM=$(echo "$PHASE_LINE" | grep -oE '[0-9]+' | head -1)
SPEC_FILE="specs/phase-${PHASE_NUM}-${SLUG}.md"

# --- Deliverable check: run file-existence exit criteria from spec ---
if [ -f "$SPEC_FILE" ]; then
  TIMEOUT_CMD=""
  if command -v gtimeout >/dev/null 2>&1; then
    TIMEOUT_CMD="gtimeout 30"
  elif command -v timeout >/dev/null 2>&1; then
    TIMEOUT_CMD="timeout 30"
  fi

  FAILED=""
  while IFS= read -r criterion; do
    CMD=$(echo "$criterion" | sed 's/^- \[ \] `//;s/`$//')
    # Only run file-existence checks (test -f, test -d)
    case "$CMD" in
      "test -f "*|"test -d "*)
        if [ -n "$TIMEOUT_CMD" ]; then
          if ! $TIMEOUT_CMD bash -c "$CMD" 2>/dev/null; then
            FAILED="$CMD"
            break
          fi
        else
          if ! bash -c "$CMD" 2>/dev/null; then
            FAILED="$CMD"
            break
          fi
        fi
        ;;
    esac
  done < <(grep -E '^\- \[ \] `' "$SPEC_FILE" 2>/dev/null || true)

  if [ -n "$FAILED" ]; then
    log_firing "block" "deliverable-missing" || true
    echo "[nana:enforce-loop] Deliverable missing. Exit criterion not met: $FAILED" >&2
    exit 2
  fi
fi

# --- Open tasks advisory ---
TASKS_FILE=".dev-wiki/tasks.md"
if [ -f "$TASKS_FILE" ]; then
  PHASE_MARKER="<!-- phase:phase-${PHASE_NUM}-${SLUG} -->"
  OPEN_COUNT=$(sed -n "/${PHASE_MARKER}/,/<!-- phase:/{ /^- \[ \]/p; }" "$TASKS_FILE" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$OPEN_COUNT" -gt 0 ] 2>/dev/null; then
    echo "[nana:enforce-loop] $OPEN_COUNT open task(s) remaining in Phase $PHASE_NUM."
  fi
fi

# --- Debrief advisory: check if meaningful work was done without debrief ---
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  AUTHOR=$(git config user.email 2>/dev/null || true)
  if [ -n "$AUTHOR" ]; then
    RECENT_COMMITS=$(git log --since="2 hours ago" --author="$AUTHOR" --oneline 2>/dev/null | wc -l | tr -d ' ')
    if [ "$RECENT_COMMITS" -gt 0 ] 2>/dev/null; then
      TODAY=$(date +%Y-%m-%d)
      JOURNAL_EXISTS=$(find .dev-wiki/articles/journal/ -name "${TODAY}-*" 2>/dev/null | head -1)
      if [ -z "$JOURNAL_EXISTS" ]; then
        echo "[nana:enforce-loop] Commits found but no debrief today. Consider running /dev-debrief."
      fi
    fi
  fi
fi

log_firing "allow" "all-checks-passed"
exit 0
