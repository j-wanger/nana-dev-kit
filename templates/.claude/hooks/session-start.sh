#!/usr/bin/env bash
# SessionStart hook — loads project context into Claude's context.
# Reads: dev-wiki state, session state. Memory via MCP tools (not file read).
# All reads are optional — graceful silent skip when files are missing.

set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true  # Phase 79: resolve project-relative refs regardless of CWD

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$HOOK_DIR/session-start.d/wk-prune.sh"
source "$HOOK_DIR/session-start.d/memory-nudge.sh"
source "$HOOK_DIR/session-start.d/cognitive-readiness.sh"

# Session-start freshness anchor for enforce-memory. Global (back-compat: dev-debrief cooldown advisory
# + enforce-memory fallback) PLUS a per-session_id keyed file so a CONCURRENT session cannot advance
# another session's bound (which falsely excludes a genuine in-session memory_search). session_id is in
# the SessionStart event JSON on stdin — read ONLY when piped (never blocks a TTY/manual run). Every step
# is best-effort + `|| true`: a failure here must never break SessionStart (Phase-84 machine-wide class).
_NANA_SS_NOW=$(date +%s)
echo "$_NANA_SS_NOW" > "$HOME/.claude/.session-start-ts" 2>/dev/null || true
if [ ! -t 0 ]; then _NANA_SS_INPUT=$(cat 2>/dev/null || echo ""); else _NANA_SS_INPUT=""; fi
_NANA_SID=$(printf '%s' "$_NANA_SS_INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")
case "$_NANA_SID" in
  ''|*[!a-zA-Z0-9_-]*) : ;;   # no/invalid session_id -> global anchor only (enforce-memory falls back)
  *) echo "$_NANA_SS_NOW" > "$HOME/.claude/.session-start-ts-$_NANA_SID" 2>/dev/null || true
     # prune stale per-session anchors (>1 day) so they never accumulate
     find "$HOME/.claude" -maxdepth 1 -name '.session-start-ts-*' -type f -mtime +1 -delete 2>/dev/null || true ;;
esac

# --- Dev-wiki lifecycle state ---
DEVWIKI_STATE=".dev-wiki/_CURRENT_STATE.md"
if [ -f "$DEVWIKI_STATE" ]; then
  echo "=== Dev-Wiki State ==="
  grep -A2 '## Recommended Next Action' "$DEVWIKI_STATE" 2>/dev/null | head -3 || true
  grep -A3 '## Active Phase' "$DEVWIKI_STATE" 2>/dev/null | head -4 || true
  echo ""
fi

# --- Gate check (active phase with unchecked gates) ---
ACTIVE_PHASE=".claude/rules/active-phase.md"
if [ -f "$ACTIVE_PHASE" ] && grep -q 'Status:.*Active' "$ACTIVE_PHASE" 2>/dev/null; then
  UNCHECKED=$(grep -c '\- \[ \]' "$ACTIVE_PHASE" 2>/dev/null || true)
  if [ "$UNCHECKED" -gt 0 ] 2>/dev/null; then
    echo "[nana:gate] $UNCHECKED unchecked gate(s) in active phase. Complete gates before implementing."
  fi
fi

# --- Session state (compaction anchor) ---
SESSION_STATE=".claude/rules/py-session-state.md"
if [ -f "$SESSION_STATE" ]; then
  FOCUS=$(grep -A1 '## Current Focus' "$SESSION_STATE" 2>/dev/null | tail -1)
  if [ -n "$FOCUS" ] && [ "$FOCUS" != "(not set)" ]; then
    echo "=== Session State ==="
    cat "$SESSION_STATE"
    echo ""
  fi
fi

# --- Crash recovery: detect commits since last debrief ---
if [ -f "$DEVWIKI_STATE" ]; then
  STATE_MTIME=$(stat -f %m "$DEVWIKI_STATE" 2>/dev/null || stat -c %Y "$DEVWIKI_STATE" 2>/dev/null || echo 0)
  LATEST_COMMIT=$(git log -1 --format=%ct 2>/dev/null || echo 0)
  if [ "$LATEST_COMMIT" -gt "$STATE_MTIME" ] 2>/dev/null; then
    DEBRIEF_SINCE=$(git log --since="@$STATE_MTIME" --oneline -i --grep="Debrief" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    if [ "$DEBRIEF_SINCE" -eq 0 ] 2>/dev/null; then
      echo "[nana:recovery] Commits detected since last state update. Consider /dev-check or /dev-debrief."
    fi
  fi
fi

# --- Delivery-commit divergence: a phase marked delivery-accepted but never committed ---
# Catches the gate-state-vs-git-state split (a delivery gate ticked while D3's commit never landed —
# agent skipped it or a pre-commit hook aborted it). Deterministic + fail-open; the skill-text commit
# step it backstops can be skipped, this check cannot.
if [ -f "$ACTIVE_PHASE" ] && grep -qE '^- \[x\] Delivery accepted' "$ACTIVE_PHASE" 2>/dev/null; then
  # The phase number may sit right after the colon ("Phase: 2 —") or later ("Phase: NONE — Phase 75
  # COMPLETE", the kit's own completion format) — match a number that follows the word "Phase".
  PHASE_N=$(grep -m1 '^Phase:' "$ACTIVE_PHASE" 2>/dev/null | grep -oiE 'phase[ :_-]*[0-9]+' | grep -oE '[0-9]+' | head -1 || true)
  if [ -n "${PHASE_N:-}" ]; then
    PHASE_COMMITS=$(git log --oneline 2>/dev/null | grep -icE "phase[ _-]?${PHASE_N}\b" || true)
    if [ "${PHASE_COMMITS:-0}" -eq 0 ] 2>/dev/null; then
      echo "[nana:recovery] Phase $PHASE_N marked delivery-accepted but no commit references it — work may be uncommitted. Commit it or run /dev-check."
    fi
  fi
fi

# --- Installed-copy drift (kit repo only) ---
# The kit develops in templates/ but RUNS from ~/.claude; a stale installed copy silently undermines
# work (bit twice: Phase-73 curator gap, Phase-75 stale delivery-flow). Fire ONLY in the kit repo
# (git-root == the kit-path marker) so it is signal not noise. Fail-open, once per session.
KIT_PATH_MARKER="$HOME/.claude/.nana-dev-kit-path"
if [ -f "$KIT_PATH_MARKER" ]; then
  RAW_KIT=$(cat "$KIT_PATH_MARKER" 2>/dev/null || true)
  KIT_PATH=""
  # Resolve both sides to physical paths — git-root is already canonical, so the marker must be too
  # (guards against symlinked checkouts, e.g. macOS /var → /private/var).
  if [ -n "$RAW_KIT" ] && [ -d "$RAW_KIT" ]; then
    KIT_PATH=$(cd "$RAW_KIT" 2>/dev/null && pwd -P || true)
  fi
  GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
  if [ -n "$KIT_PATH" ] && [ "$GIT_ROOT" = "$KIT_PATH" ] && [ -x "$KIT_PATH/scripts/check-install-drift.sh" ]; then
    DRIFT_N=$("$KIT_PATH/scripts/check-install-drift.sh" --count 2>/dev/null || echo 0)
    if [ "${DRIFT_N:-0}" -gt 0 ] 2>/dev/null; then
      echo "[nana:drift] $DRIFT_N kit file(s) differ from your installed ~/.claude — run install.sh to sync."
    fi
  fi
fi

# --- Enforcement-marker advisory (Phase 82) ---
# The enforce-* hooks exit silently when no marker exists, so a deleted/never-created marker
# disables the whole enforcement layer with zero signal (4th cascade-class instance: the gap
# went dark 2026-05-25→06-09). Gated on .dev-wiki (a lifecycle project is expected enforced).
if [ -d ".dev-wiki" ] && [ ! -f ".claude/enforce" ] && [ ! -f "$HOME/.claude/enforce" ]; then
  echo "[nana:enforce] No enforcement marker (.claude/enforce or ~/.claude/enforce) — enforce-spec/enforce-loop are dormant. touch .claude/enforce to enable."
fi

# --- Stale post-commit sidecar ---
if [ -f ".dev-wiki/.pending-commit" ]; then
  echo "[nana:pending] Unprocessed commit detected. Run task matching."
  rm -f ".dev-wiki/.pending-commit"
fi

# --- Clear session state ---
rm -f .claude/.memory-consulted

# --- Module functions ---
check_memory_consolidation ".memory/memory.db" "$HOME/.claude/.memory-nudge-ts"
prune_working_knowledge ".claude/rules/working-knowledge.md" ".dev-wiki/.stale-queue"
check_cognitive_readiness

exit 0
