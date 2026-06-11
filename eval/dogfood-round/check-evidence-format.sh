#!/usr/bin/env bash
# Phase 89 — session-evidence format checker (exit criterion c5).
# Validates evidence/sessions.md against the pinned session-block schema
# (pre-registration.md "## Session evidence schema"): >=3 "### Session <n> —" blocks; each
# block carries a driver line (headless-maintainer-agent|jake-interactive), an agenda line,
# a prompt archived-at line, a snapshots line with before=/after= pairs, >=1 hook-event row
# each for SessionStart, PreToolUse (or a named PreToolUse decision hook), and Stop, and a
# reachability line with all three orchestrator-computed fields.
# --selftest: seeded fixtures under checker-fixtures/evidence-*/; a run that passes a seeded
# malformed fixture is instrument-dead and may not ship.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIX="$SCRIPT_DIR/checker-fixtures"

check_block() { # $1 = single-session block file, $2 = label for messages
  local b="$1" lbl="$2" v=0
  grep -qE '^driver: (headless-maintainer-agent|jake-interactive)$' "$b" \
    || { echo "FAIL: [$lbl] driver line missing/invalid" >&2; v=1; }
  grep -qE '^agenda: .+' "$b" \
    || { echo "FAIL: [$lbl] agenda line missing" >&2; v=1; }
  grep -qE '^prompt: archived at .+' "$b" \
    || { echo "FAIL: [$lbl] prompt archived-at line missing" >&2; v=1; }
  grep -qE '^snapshots: .*before=[0-9]+ after=[0-9]+' "$b" \
    || { echo "FAIL: [$lbl] snapshots before=/after= line missing" >&2; v=1; }
  grep -qE '^\|[^|]*\| *SessionStart *\|' "$b" \
    || { echo "FAIL: [$lbl] no SessionStart hook-event row" >&2; v=1; }
  grep -qE '^\|[^|]*\| *PreToolUse *\|' "$b" \
    || grep -qE '^\| *(enforce-spec|enforce-loop|enforce-memory|block-dangerous-bash|dev-wiki-scope-check|scan-secrets)[^|]*\|' "$b" \
    || { echo "FAIL: [$lbl] no PreToolUse (or PreToolUse decision-hook) row" >&2; v=1; }
  grep -qE '^\|[^|]*\| *Stop *\|' "$b" \
    || { echo "FAIL: [$lbl] no Stop hook-event row" >&2; v=1; }
  grep -qE '^reachability: .*compaction=[yn].*planning_or_recovery_decision=[yn].*pinned_decision_in_scope=[yn]' "$b" \
    || { echo "FAIL: [$lbl] reachability line missing/incomplete" >&2; v=1; }
  return "$v"
}

check_sessions() { # $1 = sessions.md path
  local f="$1" v=0 n d b
  [ -f "$f" ] || { echo "FAIL: $f missing" >&2; return 1; }
  n=$(grep -cE '^### Session [0-9]+ ' "$f" || true)
  [ "$n" -ge 3 ] || { echo "FAIL: $n session block(s); pinned bar is >=3" >&2; v=1; }
  d=$(mktemp -d)
  awk -v d="$d" '/^### Session [0-9]+ /{n++} n{print >> (d "/block-" n)}' "$f"
  for b in "$d"/block-*; do
    [ -e "$b" ] || continue
    check_block "$b" "$(head -1 "$b")" || v=1
  done
  rm -rf "$d"
  return "$v"
}

selftest() {
  local pass=0 fail=0 fx
  if check_sessions "$FIX/evidence-valid/sessions.md" >/dev/null 2>&1; then pass=$((pass+1))
  else echo "SELFTEST FAIL: valid 3-session fixture rejected" >&2; fail=1; fi
  for fx in sessions-missing-reachability sessions-two-blocks sessions-missing-stop; do
    if check_sessions "$FIX/evidence-malformed/$fx.md" >/dev/null 2>&1; then
      echo "SELFTEST FAIL: $fx accepted (instrument-dead)" >&2; fail=1
    else pass=$((pass+1)); fi
  done
  [ "$fail" -eq 0 ] && echo "SELFTEST PASS ($pass/4 controls)" || { echo "SELFTEST FAIL" >&2; exit 1; }
}

if [ "${1:-}" = "--selftest" ]; then selftest; exit 0; fi
if check_sessions "${1:-$SCRIPT_DIR/evidence/sessions.md}"; then
  echo "EVIDENCE-FORMAT: PASS"
else
  echo "EVIDENCE-FORMAT: FAIL" >&2; exit 1
fi
