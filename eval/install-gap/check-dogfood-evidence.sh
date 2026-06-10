#!/usr/bin/env bash
# Phase 85 — format validator for the dogfood evidence artifact.
# A zero in the A5 memory-layer answer counts ONLY with a liveness probe carrying a NUMERIC
# exit code and a DB row count (the Phase-83 couldnt-fire trap); the observation table must
# carry >=1 row each for SessionStart, a PreToolUse decision, and Stop, across >=2 sessions.
#
# Usage:
#   check-dogfood-evidence.sh [dogfood-evidence.md]   # exit 0 = complete, 1 = incomplete
#   check-dogfood-evidence.sh --selftest               # seeded fixtures, both directions

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

validate() {
  local file="$1" v=0
  [ -f "$file" ] || { echo "dogfood: file not found: $file" >&2; return 1; }

  grep -qE 'exit code: [0-9]+' "$file" \
    || { echo "dogfood: probe exit code missing (need numeric 'exit code: N')" >&2; v=1; }
  grep -qE 'row count: [0-9]+' "$file" \
    || { echo "dogfood: DB row count missing (need numeric 'row count: N')" >&2; v=1; }

  for ev in SessionStart PreToolUse Stop; do
    grep -qE "^\| [^|]+ \| $ev \|" "$file" \
      || { echo "dogfood: no observation row for $ev" >&2; v=1; }
  done

  local n
  n=$(grep -cE '^## Session [0-9]+' "$file" || true)
  [ "$n" -ge 2 ] || { echo "dogfood: only $n session section(s) (need >= 2 real-work sessions)" >&2; v=1; }

  return $v
}

selftest() {
  local d pass=0 fail=0
  d="$(mktemp -d)"
  trap 'rm -rf "$d"' RETURN
  cat > "$d/good.md" << 'EOF'
# Evidence
exit code: 0
row count: 0
## Session 1 — 2026-06-10
| session-start.sh | SessionStart | 2026-06-10T10:00Z | helped |
| enforce-spec.sh | PreToolUse | 2026-06-10T10:05Z | neutral |
## Session 2 — 2026-06-11
| enforce-loop.sh | Stop | 2026-06-11T11:00Z | neutral |
EOF
  sed 's/exit code: 0/exit code: pending/' "$d/good.md" > "$d/bad-exit.md"
  grep -v 'PreToolUse' "$d/good.md" > "$d/bad-event.md"
  sed 's/^## Session 2.*$//' "$d/good.md" > "$d/bad-sessions.md"

  validate "$d/good.md" >/dev/null 2>&1          && pass=$((pass+1)) || { echo "selftest FAIL: good rejected" >&2; fail=1; }
  validate "$d/bad-exit.md" >/dev/null 2>&1      && { echo "selftest FAIL: non-numeric exit code accepted" >&2; fail=1; } || pass=$((pass+1))
  validate "$d/bad-event.md" >/dev/null 2>&1     && { echo "selftest FAIL: missing PreToolUse row accepted" >&2; fail=1; } || pass=$((pass+1))
  validate "$d/bad-sessions.md" >/dev/null 2>&1  && { echo "selftest FAIL: single session accepted" >&2; fail=1; } || pass=$((pass+1))
  echo "selftest: $pass/4 fixtures behaved"
  return $fail
}

case "${1:-}" in
  --selftest) selftest ;;
  *) validate "${1:-$SCRIPT_DIR/dogfood-evidence.md}" && echo "dogfood evidence: complete" ;;
esac
