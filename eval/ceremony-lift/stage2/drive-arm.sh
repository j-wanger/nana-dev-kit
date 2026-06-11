#!/usr/bin/env bash
# drive-arm.sh <arm-b|arm-a> — Phase 87 T5: capture the context-surface manifest +
# kit-HEAD embargo reading, drive the arm session per addendum + amendments, write the
# arm record. Usage: bash drive-arm.sh arm-b
set -uo pipefail
ARM="${1:?usage: drive-arm.sh <arm-b|arm-a>}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT="$(git -C "$DIR" rev-parse --show-toplevel)"
ARM_DIR="/Users/jwang/p87-arms/$ARM/edge-screener"
REC="$DIR/arm-records"; mkdir -p "$REC"

SHARED='Phase 10: add a standalone unit test in tests/unit/ that closes the two uncovered survivorship branches — the recovered-name (M) genuine-continuation path and the recycled-ticker post-removal-only path (see .dev-wiki/phase-10-candidate-analysis.md). Engine code, standing reports, and existing tests stay untouched. Done means: the new test passes, the full gate `uv run pytest && uv run mypy && uv run ruff check .` is green, total coverage does not regress below 94.44%, and no existing test is modified or deleted. Also: register the project hook script context-size-check.sh for SessionStart in the project settings, following the project'"'"'s documented registration conventions. When the task is fully complete and the gate is green, use the Write tool to create a file named ARM_DONE in the repository root containing exactly: done'
WRAP_A='Work this as a standard project phase using the full dev-wiki workflow: run /dev-plan for this phase and follow it through implementation and /dev-debrief, including its gates and reviews.'
WRAP_B='Before writing any code, surface your load-bearing assumptions (cost-sorted, worst-if-wrong first) via the AskUserQuestion tool and take positions; then implement the task directly. Project enforcement hooks are active.'

case "$ARM" in
  arm-b) PROMPT="$WRAP_B

$SHARED"; CANARY="What was the DRQ-1 verdict and which file records it?" ;;
  arm-a) PROMPT="$WRAP_A

$SHARED"; CANARY="" ;;
esac

# Shared task statement parity artifact (byte-identity asserted by check-instrument)
printf '%s' "$SHARED" > "$REC/task-statement-$ARM.txt"

# --- Context-surface manifest (pre-session, orchestrator-executed) ---------------
MAN="$REC/surface-manifest-$ARM.txt"
{
  echo "captured: $(date +%Y-%m-%dT%H:%M:%S%z)"
  echo "[global-rules]"; ls ~/.claude/rules/*.md 2>/dev/null
  echo "[kit-path-marker]"; ls ~/.claude/.nana-dev-kit-path 2>/dev/null || echo "held (amendment 001)"
  echo "[clone-projects-dir]"; ls -d ~/.claude/projects/-Users-jwang-p87-arms-* 2>/dev/null || echo "none-for-$ARM-at-start"
  echo "[clone-memory-db]"; find "$ARM_DIR" -name '.memory' 2>/dev/null || echo "absent"
  echo "[clone-head]"; git -C "$ARM_DIR" rev-parse --short HEAD
} > "$MAN"
# Voiding-class checks: pre-existing transcript dir for THIS arm; .memory present
UNCLASS="ALL-CLASSIFIED"
SLUG="-Users-jwang-p87-arms-${ARM}-edge-screener"
[ -d "$HOME/.claude/projects/$SLUG" ] && UNCLASS="UNCLASSIFIED:pre-existing-transcript-dir"
[ -d "$ARM_DIR/.memory" ] && UNCLASS="UNCLASSIFIED:clone-memory-db"
[ -f "$HOME/.claude/.nana-dev-kit-path" ] && UNCLASS="UNCLASSIFIED:kit-path-marker-not-held"

KIT_HEAD_EMBARGO="DIRTY"
git -C "$KIT" diff --quiet 6728e2f..HEAD -- templates/ scripts/ install.sh modules.json Makefile && KIT_HEAD_EMBARGO="EMPTY"

export ARM_DIR ARM_LOG="$REC/interactions-$ARM.txt" ARM_PROMPT="$PROMPT" CANARY \
       COST_LOG="$REC/cost-$ARM.txt" CANARY_LOG="$REC/canary-reply-$ARM.txt" \
       ARM_MODEL="claude-opus-4-8[1m]" DEADLINE_S=14400 MAX_CONT=6
: > "$ARM_LOG"
START=$(date +%s)
expect "$DIR/arm-driver.exp"
WALL=$(( $(date +%s) - START ))

STATUS="DNF"
[ -f "$ARM_DIR/ARM_DONE" ] && [ "$(cat "$ARM_DIR/ARM_DONE")" = "done" ] && STATUS="FINISHED"
cat > "$REC/$ARM.md" <<EOF
STATUS: $STATUS
TRANSCRIPT-DIR: $HOME/.claude/projects/$SLUG
KIT-HEAD-AT-START: 6728e2f
KIT-EMBARGO-AT-START: $KIT_HEAD_EMBARGO
KIT-ACTUAL-HEAD-AT-START: $(git -C "$KIT" rev-parse --short HEAD)
CAP-DEADLINE-S: 14400
WALL-S: $WALL
SURFACE-MANIFEST: $UNCLASS
INTERACTION-LOG: arm-records/interactions-$ARM.txt
EOF
echo "drive-arm $ARM: STATUS=$STATUS WALL=${WALL}s (record: $REC/$ARM.md)"
