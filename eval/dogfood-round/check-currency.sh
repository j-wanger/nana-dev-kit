#!/usr/bin/env bash
# Phase 89 currency checker (exit criterion c3) — edge-screener post-resync surface assertions:
# (a) detect-loop.sh ABSENT from $ES_ROOT/.claude/hooks/ AND no registration whose command
#     references detect-loop by basename in settings.json or settings.local.json (CUT 75b48af);
# (b) $ES_ROOT/.claude/hooks/check-tests-were-run.sh byte-equals the kit template (HARDENED
#     b8bd416 must be current on the consuming project);
# (c) kit hooks union-unique by BASENAME across both settings files' hook command strings —
#     Claude Code dedupe is STRING-KEYED, so two different command strings invoking the same
#     script BOTH fire (eval/install-gap/drq1-verification.md); normalize by basename.
# ES_ROOT / KIT_ROOT parameterized so --selftest can point at fixtures.
# --selftest: seeded controls under checker-fixtures/guard-currency/ — stale-ctw,
# detect-loop-present, dup-basename must each FAIL their check; the staged pass fixture must
# PASS all three. Clean-on-seed = instrument-dead, may not ship.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ES_ROOT="${ES_ROOT:-/Users/jwang/edge-screener}"
KIT_ROOT="${KIT_ROOT:-$(git -C "$DIR" rev-parse --show-toplevel)}"

hook_cmds() { # $1 = project root → union (sort -u: identical strings dedupe, like the platform)
  local f
  for f in "$1/.claude/settings.json" "$1/.claude/settings.local.json"; do
    [ -f "$f" ] || continue
    # nested {hooks:[{command}]} AND legacy flat {matcher,command} forms — same parsing
    # model as rehearsals/deregister-detect-loop.jq, so checker and surgery tool agree
    jq -r '.hooks // {} | to_entries[] | .value[]? | (.hooks[]?.command // .command)? // empty' "$f"
  done | sort -u
}

basenames() { grep -oE '[^/" ]+\.sh' || true; } # all .sh basenames in command strings

check_detect_loop() { # $1 = project root
  local root="$1" bad=0
  [ ! -e "$root/.claude/hooks/detect-loop.sh" ] \
    || { echo "FAIL: detect-loop.sh present in $root/.claude/hooks/ (cut 75b48af not synced)" >&2; bad=1; }
  if hook_cmds "$root" | basenames | grep -qx 'detect-loop.sh'; then
    echo "FAIL: a settings registration still references detect-loop.sh by basename" >&2; bad=1
  fi
  return "$bad"
}

check_ctw_hash() { # $1 = project root
  local es="$1/.claude/hooks/check-tests-were-run.sh"
  local kit="$KIT_ROOT/templates/.claude/hooks/check-tests-were-run.sh"
  [ -f "$kit" ] || { echo "FAIL: kit template $kit missing" >&2; return 1; }
  [ -f "$es" ] || { echo "FAIL: $es missing" >&2; return 1; }
  cmp -s "$es" "$kit" \
    || { echo "FAIL: check-tests-were-run.sh differs from kit template (stale hash)" >&2; return 1; }
}

check_basename_unique() { # $1 = project root
  local dups
  dups=$(hook_cmds "$1" | basenames | sort | uniq -d)
  [ -z "$dups" ] \
    || { echo "FAIL: duplicate hook basenames across settings union (both fire): $dups" >&2; return 1; }
}

selftest() {
  local fix t pass=0 fail=0
  fix="$DIR/checker-fixtures/guard-currency"
  t=$(mktemp -d)
  # shellcheck disable=SC2064 — expand now: $t is function-local, gone by EXIT time
  trap "rm -rf '$t'" EXIT

  # Positive controls: pass fixture staged to mktemp; its ctw refreshed from the LIVE kit
  # template so the control stays current as the template evolves (committed copy is a
  # byte-copy today; the refresh makes the selftest drift-proof).
  cp -R "$fix/pass" "$t/pass"
  cp "$KIT_ROOT/templates/.claude/hooks/check-tests-were-run.sh" \
     "$t/pass/.claude/hooks/check-tests-were-run.sh"
  if check_detect_loop "$t/pass" 2>/dev/null; then pass=$((pass+1)); else
    echo "SELFTEST FAIL: pass fixture failed detect-loop check" >&2; fail=1; fi
  if check_ctw_hash "$t/pass" 2>/dev/null; then pass=$((pass+1)); else
    echo "SELFTEST FAIL: pass fixture failed ctw-hash check" >&2; fail=1; fi
  if check_basename_unique "$t/pass" 2>/dev/null; then pass=$((pass+1)); else
    echo "SELFTEST FAIL: pass fixture failed basename-unique check" >&2; fail=1; fi

  # Seeded controls: each defect fixture must turn its check RED.
  if check_detect_loop "$fix/detect-loop-present" 2>/dev/null; then
    echo "SELFTEST FAIL: detect-loop-present fixture passed (instrument-dead)" >&2; fail=1
  else pass=$((pass+1)); fi
  if check_ctw_hash "$fix/stale-ctw" 2>/dev/null; then
    echo "SELFTEST FAIL: stale-ctw fixture passed (instrument-dead)" >&2; fail=1
  else pass=$((pass+1)); fi
  if check_basename_unique "$fix/dup-basename" 2>/dev/null; then
    echo "SELFTEST FAIL: dup-basename fixture passed (instrument-dead)" >&2; fail=1
  else pass=$((pass+1)); fi

  [ "$fail" -eq 0 ] && echo "SELFTEST PASS ($pass/6 controls)" || { echo "SELFTEST FAIL" >&2; exit 1; }
}

if [ "${1:-}" = "--selftest" ]; then selftest; exit 0; fi

rc=0
check_detect_loop "$ES_ROOT" || rc=1
check_ctw_hash "$ES_ROOT" || rc=1
check_basename_unique "$ES_ROOT" || rc=1
[ "$rc" -eq 0 ] && echo "CURRENCY: PASS" || { echo "CURRENCY: FAIL" >&2; exit 1; }
