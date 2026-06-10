#!/usr/bin/env bash
# Phase 83 artifact checker — structural assertions over verdict-table.md + liveness-grep.log.
# T1 asserts table shape + discovered roots; the arming block arms when arming-runs.log exists (T2).
set -uo pipefail
cd "$(dirname "$0")"
fail=0
say() { printf '%s\n' "$*"; }

TABLE=verdict-table.md
LOG=liveness-grep.log
CANDS='enforce-memory|memory-reinforcement|memory-mcp-scaffold|audit-log-model-field|orphan-companions|harness-audit'

[ -f "$TABLE" ] || { say "FAIL: $TABLE missing"; exit 1; }
[ -f "$LOG" ]   || { say "FAIL: $LOG missing"; exit 1; }

# Exactly 6 candidate rows, bare names at line start, no duplicates.
n_uniq=$(grep -oE "^\| ($CANDS) " "$TABLE" | sort -u | wc -l | tr -d ' ')
n_total=$(grep -cE "^\| ($CANDS) " "$TABLE")
[ "$n_uniq" = 6 ]  || { say "FAIL: expected 6 distinct candidate rows, got $n_uniq"; fail=1; }
[ "$n_total" = 6 ] || { say "FAIL: expected exactly 6 candidate rows total, got $n_total"; fail=1; }

# Header row (located by pattern, not position) carries the required columns.
hdr=$(grep -m1 '^| candidate |' "$TABLE")
[ -n "$hdr" ] || { say "FAIL: no '| candidate |' header row"; fail=1; }
for col in matrix-row arming-procedure zero-class proposed-verdict removal-set; do
  printf '%s' "$hdr" | grep -q "$col" || { say "FAIL: table header missing column: $col"; fail=1; }
done

# Liveness log opens with the DISCOVERED roots (machine-readable ROOTS: lines).
head -8 "$LOG" | grep -q '^ROOTS:' || { say "FAIL: $LOG must open with ROOTS: lines (discovered installed surface)"; fail=1; }

# T2 arming block: one ARMED line per candidate; cut/disable rows must carry a zero-class token.
[ -f arming-runs.log ] || { say "FAIL: arming-runs.log missing (T2 arming not run)"; exit 1; }
for c in enforce-memory memory-reinforcement memory-mcp-scaffold audit-log-model-field orphan-companions harness-audit; do
  grep -q "^ARMED $c " arming-runs.log || { say "FAIL: no ARMED line for $c"; fail=1; }
done
bad=$(grep -E "^\| ($CANDS) " "$TABLE" | grep -E '\| (cut|disable-at-boundary) \|' | grep -cvE 'couldnt-fire|didnt-fire')
[ "$bad" = 0 ] || { say "FAIL: $bad cut/disable rows lack a zero-class token (couldnt-fire|didnt-fire)"; fail=1; }

[ "$fail" = 0 ] && say "PASS: prune-on-value artifacts OK"
exit "$fail"
