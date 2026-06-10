#!/usr/bin/env bash
# Phase 85 — assert each kit-owned hook (identity = script BASENAME) is registered EXACTLY ONCE
# across the UNION of <root>/.claude/settings.json + <root>/.claude/settings.local.json, and that
# every modules.json scope:project hook is present (none silently disarmed by the migration).
#
# POSITIVE CONTROL built in: the union extraction must yield >= 1 command, or the instrument is
# broken (exit 2) — never a silent pass (Phase-84 zsh false-zero class).
#
# Usage: assert-edge-screener-registration.sh [project-root]   # default /Users/jwang/edge-screener
# Exit: 0 = pass; 1 = duplicate or missing hook; 2 = instrument/input problem.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MODULES_JSON="$KIT_ROOT/modules.json"
ROOT="${1:-/Users/jwang/edge-screener}"

command -v jq >/dev/null 2>&1 || { echo "assert-edge: jq required" >&2; exit 2; }
[ -f "$MODULES_JSON" ] || { echo "assert-edge: modules.json missing" >&2; exit 2; }
[ -d "$ROOT/.claude" ] || { echo "assert-edge: $ROOT/.claude not found" >&2; exit 2; }

KIT_SCRIPTS=$(jq -r '.hooks[].script' "$MODULES_JSON" | sort -u)
EXPECTED_PROJECT=$(jq -r '.hooks[] | select(.scope == "project") | .script' "$MODULES_JSON" | sort -u)

UNION_CMDS=""
for f in "$ROOT/.claude/settings.json" "$ROOT/.claude/settings.local.json"; do
  [ -f "$f" ] || continue
  UNION_CMDS+=$(jq -r '.hooks // {} | .. | .command? // empty' "$f" 2>/dev/null)$'\n'
done

KIT_BASENAMES=$(printf '%s\n' "$UNION_CMDS" | tr ' \t' '\n\n' | grep '\.sh$' | sed 's#.*/##' \
                | grep -xF -f <(printf '%s\n' "$KIT_SCRIPTS") || true)

# Positive control
TOTAL=$(printf '%s\n' "$KIT_BASENAMES" | grep -c . || true)
if [ "$TOTAL" -lt 1 ]; then
  echo "assert-edge: POSITIVE CONTROL FAILED — union extraction found 0 kit-owned hook commands" >&2
  exit 2
fi

FAIL=0
# Exactly-once across the union
DUPES=$(printf '%s\n' "$KIT_BASENAMES" | sort | uniq -d)
if [ -n "$DUPES" ]; then
  echo "assert-edge: FAIL — kit hooks registered more than once across the union:" >&2
  printf '  %s\n' $DUPES >&2
  FAIL=1
fi
# Completeness: every scope:project hook present (migration must not silently disarm)
MISSING=$(comm -23 <(printf '%s\n' "$EXPECTED_PROJECT") <(printf '%s\n' "$KIT_BASENAMES" | sort -u))
if [ -n "$MISSING" ]; then
  echo "assert-edge: FAIL — scope:project hooks absent from the union (silently disarmed):" >&2
  printf '  %s\n' $MISSING >&2
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "assert-edge: PASS — $TOTAL kit-owned registrations, each basename exactly once; all $(printf '%s\n' "$EXPECTED_PROJECT" | grep -c .) scope:project hooks present"
fi
exit $FAIL
