#!/usr/bin/env bash
# Phase 89 — section-anchored evidence content checker (exit criteria c2 + c10).
# Asserts: evidence/header.md pins a "kit HEAD:" 7+hex SHA, a sync-timestamp line, and >=1
# per-surface hash-comparison line; evidence/liveness-probe.md carries a numeric exit-code
# line OR an explicit couldnt-fire record INSIDE its own probe H2 section (a misplaced
# exit-code line does not count), plus marker-states and before-round DB row-count lines;
# evidence/memory-demand.md carries non-stub per-class tallies (hook-prompted /
# rules-instructed / spontaneous), an instructed-with-readback tally, writer write/read-back
# counts, and an end-of-round DB row count; .dev-wiki/_CURRENT_STATE.md cites
# eval/dogfood-round/evidence/memory-demand.md INSIDE "## Blockers and Open Questions" (c10).
# Live mode: a missing evidence file prints "PENDING: <file>" and counts as FAIL (run at T6).
# --selftest: seeded fixtures under checker-fixtures/evidence-*/; clean-on-seed = instrument-dead.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIX="$SCRIPT_DIR/checker-fixtures"

section() { # $1=file $2=lowercase ERE matched against H2 headings — state-flag walk
            # (never awk range syntax); EOF-terminated sections handled (flag stays set).
  awk -v re="$2" 'BEGIN{f=0} /^## /{f=(tolower($0) ~ re)} f' "$1"
}

tally() { # $1=file $2=label — non-stub tally line: "label: N" or "| label | N"
  grep -qE "^(\| *)?$2 *[:|] *[0-9]+" "$1"
}

check_header() { # $1 = header.md
  local f="$1" v=0
  grep -qE 'kit HEAD: *[0-9a-f]{7,}' "$f" \
    || { echo "FAIL: header lacks 'kit HEAD: <7+hex SHA>' line" >&2; v=1; }
  grep -qiE 'sync[^0-9]*[0-9]{4}-[0-9]{2}-[0-9]{2}' "$f" \
    || { echo "FAIL: header lacks a sync-timestamp line" >&2; v=1; }
  grep -qE '[0-9a-f]{7,}[^0-9a-f].*[0-9a-f]{7,}' "$f" \
    || { echo "FAIL: header lacks a per-surface hash-comparison line (two hashes)" >&2; v=1; }
  return "$v"
}

check_liveness() { # $1 = liveness-probe.md
  local f="$1" v=0 probe
  probe=$(section "$f" 'probe')
  [ -n "$probe" ] || { echo "FAIL: $f has no probe H2 section" >&2; return 1; }
  grep -qE 'exit code: [0-9]+' <<<"$probe" || grep -qF 'couldnt-fire' <<<"$probe" \
    || { echo "FAIL: probe section has neither 'exit code: N' nor an explicit couldnt-fire record" >&2; v=1; }
  grep -qiE 'marker[ -]states?' "$f" \
    || { echo "FAIL: marker-states line missing" >&2; v=1; }
  grep -qiE 'before.*row[ -]?count[^0-9]*[0-9]+' "$f" \
    || { echo "FAIL: before-round DB row-count line missing" >&2; v=1; }
  return "$v"
}

check_demand() { # $1 = memory-demand.md
  local f="$1" v=0 c
  for c in hook-prompted rules-instructed spontaneous; do
    tally "$f" "$c" || { echo "FAIL: $c tally missing or stub (needs a number)" >&2; v=1; }
  done
  tally "$f" 'instructed-with-readback' \
    || { echo "FAIL: instructed-with-readback tally missing" >&2; v=1; }
  tally "$f" 'writer writes' || { echo "FAIL: writer writes count missing" >&2; v=1; }
  tally "$f" 'writer read-backs' || { echo "FAIL: writer read-backs count missing" >&2; v=1; }
  tally "$f" 'end-of-round DB row count' \
    || { echo "FAIL: end-of-round DB row count missing" >&2; v=1; }
  return "$v"
}

check_blockers() { # $1 = _CURRENT_STATE.md
  local f="$1" sec
  sec=$(section "$f" '^## blockers and open questions')
  [ -n "$sec" ] || { echo "FAIL: '## Blockers and Open Questions' section absent in $f" >&2; return 1; }
  grep -qF 'eval/dogfood-round/evidence/memory-demand.md' <<<"$sec" \
    || { echo "FAIL: Blockers section lacks the memory-demand.md evidence pointer (c10)" >&2; return 1; }
}

live_one() { # $1 = checker fn, $2 = file (graceful-pending rule: missing file = FAIL)
  if [ ! -f "$2" ]; then echo "PENDING: $2 (counts as FAIL — required at T6)" >&2; return 1; fi
  "$1" "$2"
}

selftest() {
  local pass=0 fail=0
  ok()  { if "$@" >/dev/null 2>&1; then pass=$((pass+1)); else echo "SELFTEST FAIL: expected PASS: $*" >&2; fail=1; fi; }
  bad() { if "$@" >/dev/null 2>&1; then echo "SELFTEST FAIL: expected FAIL (instrument-dead): $*" >&2; fail=1; else pass=$((pass+1)); fi; }
  ok  check_header   "$FIX/evidence-valid/header.md"
  bad check_header   "$FIX/evidence-malformed/header-missing-field.md"
  ok  check_liveness "$FIX/evidence-valid/liveness-probe.md"
  ok  check_liveness "$FIX/evidence-couldnt-fire/liveness-probe.md"
  bad check_liveness "$FIX/evidence-malformed/liveness-no-record.md"
  bad check_liveness "$FIX/evidence-malformed/liveness-misplaced-exit.md"
  ok  check_demand   "$FIX/evidence-valid/memory-demand.md"
  bad check_demand   "$FIX/evidence-malformed/memory-demand-stub.md"
  ok  check_blockers "$FIX/evidence-valid/current-state.md"
  bad check_blockers "$FIX/evidence-malformed/current-state-no-citation.md"
  [ "$fail" -eq 0 ] && echo "SELFTEST PASS ($pass/10 controls)" || { echo "SELFTEST FAIL" >&2; exit 1; }
}

if [ "${1:-}" = "--selftest" ]; then selftest; exit 0; fi
ROOT="$(git rev-parse --show-toplevel)"
EV="$SCRIPT_DIR/evidence"
rc=0
live_one check_header   "$EV/header.md"         || rc=1
live_one check_liveness "$EV/liveness-probe.md" || rc=1
live_one check_demand   "$EV/memory-demand.md"  || rc=1
live_one check_blockers "$ROOT/.dev-wiki/_CURRENT_STATE.md" || rc=1
[ "$rc" -eq 0 ] && echo "EVIDENCE-CONTENT: PASS" || { echo "EVIDENCE-CONTENT: FAIL" >&2; exit 1; }
