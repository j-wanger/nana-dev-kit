#!/usr/bin/env bash
# Firing test for enforce-assumption-gate.sh (Phase 91 — the assumption-gate forcing function).
# fires: enforce-assumption-gate.sh
# Pipes REAL PreToolUse events through the hook and asserts exit codes (block=2, allow=0).
# All fixtures live in mktemp -d scratch — never touches live state (HEU-012).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$ROOT/templates/.claude/hooks/enforce-assumption-gate.sh"
CHECKER="$ROOT/scripts/check-assumption-ledger.sh"
fail=0

VALID='# Assumption Ledger

## Phase 7 — Test
- date: 2026-06-14
- all_accept: true
- A1 | cost: high | position: accept | revisit-status:  | "a load-bearing assumption with rationale"
'
MIXED='# Assumption Ledger

## Phase 6 — Old (format drift; would fail strict whole-file schema)
- A1 an old-format position line without the strict cost/position fields

## Phase 7 — Test
- date: 2026-06-14
- all_accept: true
- A1 | cost: high | position: accept | revisit-status:  | "valid current-phase block"
'
NOBLOCK='# Assumption Ledger

## Phase 6 — Other
- date: 2026-06-14
- all_accept: true
- A1 | cost: high | position: accept | revisit-status:  | "different phase block, not phase 7"
'

mk() { # $1 = ledger content ("" = no ledger file); echoes the scratch project dir
  local d; d=$(mktemp -d)
  mkdir -p "$d/.dev-wiki" "$d/.claude/rules" "$d/scripts"
  cp "$CHECKER" "$d/scripts/check-assumption-ledger.sh"
  printf 'Phase: 7 — Test\n' > "$d/.claude/rules/active-phase.md"
  touch "$d/.claude/enforce"
  [ -n "$1" ] && printf '%s' "$1" > "$d/.dev-wiki/assumption-ledger.md"
  echo "$d"
}
run() { # $1=project dir, $2=file_path ; echoes the hook's exit code
  # HOME=$1 so BOTH marker paths (project .claude/enforce and $HOME/.claude/enforce) resolve to the
  # scratch project's own marker — the test fully controls arming, independent of the maintainer's
  # real ~/.claude/enforce.
  printf '{"tool_input":{"file_path":"%s"}}' "$2" | CLAUDE_PROJECT_DIR="$1" HOME="$1" bash "$HOOK" >/dev/null 2>&1
  echo $?
}
expect() { if [ "$2" = "$3" ]; then echo "ok: $1"; else echo "FAIL: $1 — expected $2 got $3"; fail=1; fi; }

d=$(mk "$VALID");     expect "valid block ⇒ allow impl write"        0 "$(run "$d" src/x.py)"; rm -rf "$d"
d=$(mk "");           expect "no ledger file ⇒ block"               2 "$(run "$d" src/x.py)"; rm -rf "$d"
d=$(mk "$NOBLOCK");   expect "no block for active phase ⇒ block"    2 "$(run "$d" src/x.py)"; rm -rf "$d"
d=$(mk "$MIXED");     expect "valid current block allows despite malformed PRIOR block (no false-lockout)" 0 "$(run "$d" src/x.py)"; rm -rf "$d"
d=$(mk "$VALID");     expect "allowlisted *.md ⇒ allow"             0 "$(run "$d" docs/readme.md)"; rm -rf "$d"
d=$(mk "$VALID");     expect "allowlisted .dev-wiki/* ⇒ allow"      0 "$(run "$d" .dev-wiki/tasks.md)"; rm -rf "$d"
d=$(mk "$NOBLOCK"); rm -f "$d/.claude/enforce"
                      expect "no enforce marker ⇒ allow (opt-in)"   0 "$(run "$d" src/x.py)"; rm -rf "$d"

if [ "$fail" = 0 ]; then echo "ALL PASS"; else echo "FAILURES"; fi
exit "$fail"
