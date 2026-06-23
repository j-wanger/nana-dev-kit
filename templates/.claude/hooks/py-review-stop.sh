#!/usr/bin/env bash
# Stop hook — prompts a self-review of the session diff ONLY when Python code changed.
# Replaces the old unconditional `prompt`-type hook (py-review-stop-prompt.md), which
# re-fired on every stop and looped during planning phases (no code to review).
# Claude Code pipes session context JSON to stdin.
# Exit 0 = allow stop, Exit 2 = force Claude to keep working (stderr shown as the reason).

set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true  # Phase 79: resolve project-relative refs regardless of CWD

# --- fail-open firing log (parity with check-tests-were-run.sh): one JSONL record ---
log_firing() {
  [ -d ".dev-wiki" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0
  local action="${1:-}" reason="${2:-unspecified}" log=".dev-wiki/enforcement.log" phase ts
  phase=$(sed -n 's/^Phase: *\([0-9][0-9]*\).*/\1/p' ".claude/rules/active-phase.md" 2>/dev/null | head -n1) || true
  [ -n "$phase" ] || phase="unknown"
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || true
  { jq -nc --arg ts "$ts" --arg hook "py-review" --arg action "$action" --arg reason "$reason" --arg phase "$phase" \
      '{schema_version:1,ts:$ts,hook:$hook,action:$action,reason:$reason,phase:$phase}' >> "$log"; } 2>/dev/null || return 0
  return 0
}

command -v jq >/dev/null 2>&1 || { echo "[nana:review] jq not found, hook skipped" >&2; exit 0; }

INPUT=$(cat)

# Loop guard: if we are already inside a stop-hook continuation, do not re-trigger.
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
if [ "$STOP_ACTIVE" = "true" ]; then
  log_firing skipped already-active || true
  exit 0
fi

# Code guard: only review when there is UNCOMMITTED Python in the working tree RIGHT NOW.
# The old gate scanned the whole session transcript for any .py tool_use, so once a single .py was
# touched it re-fired on EVERY subsequent Stop for the rest of the session — including AFTER the work
# was committed (clean tree) and on purely conversational turns that touched no code. Gating on the
# live working tree (git status) makes it silent the moment the diff is committed, and on turns with
# no uncommitted Python. `--untracked-files=all` lists individual new files (the default collapses a
# new directory to its name, hiding a new .py inside it). Non-git dir -> git errors -> skip (fail-open).
PY_CHANGED=$(git status --porcelain --untracked-files=all 2>/dev/null | grep -E '\.py"?$' || true)
if [ -z "$PY_CHANGED" ]; then
  log_firing skipped no-uncommitted-py || true
  exit 0
fi

log_firing block review-requested || true
cat >&2 <<'REVIEW'
[nana:review] Self-review this session's git diff before stopping. Check for these issues
ONLY — ruff handles style/formatting, skip it:

1. Does any new code duplicate existing functions or utilities in the codebase?
2. Do any new imports reference packages that are not in uv.lock?
3. Are there bare `except Exception` blocks or handlers that swallow errors?
4. Do new functions have at least one failure-path test, or only happy-path coverage?
5. Is the API usage correct for the version of each library in use?
6. Are there hardcoded secrets, API keys, ~ file paths, or credentials in the diff?

Format each finding as: [FAIL] N. Category — file:line — issue.
If all pass, say so briefly and stop.
REVIEW
exit 2
