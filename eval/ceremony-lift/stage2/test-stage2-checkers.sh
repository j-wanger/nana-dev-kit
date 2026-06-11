#!/usr/bin/env bash
# test-stage2-checkers.sh — Phase 87 T3 controls-first gate (Ph82 standard: a checker
# vouching for any clean verdict must FIRST catch a seeded defect in its area).
# Asserts every checker PASSES its good fixture and FAILS its seeded negative.
# Exit 0 iff all assertions hold.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
C="$DIR/controls"
fail=0

expect_rc() { # <desc> <want_rc> <cmd...>
  local desc="$1" want="$2"; shift 2
  "$@" >/dev/null 2>&1
  local got=$?
  if [ "$got" -eq "$want" ]; then
    echo "PASS: $desc (rc=$got)"
  else
    echo "FAIL: $desc (want rc=$want got rc=$got)"
    fail=1
  fi
}

# claim-ceiling: minting language caught; clean passes
expect_rc "ceiling: good fixture passes"            0 bash "$DIR/check-claim-ceiling.sh" "$C/ceiling-good.md"
expect_rc "ceiling: SEEDED minting language caught" 1 bash "$DIR/check-claim-ceiling.sh" "$C/ceiling-bad.md"
# --verdict-block: out-of-vocabulary disposition caught
expect_rc "verdict-block: good (undecidable) passes"   0 bash "$DIR/check-claim-ceiling.sh" --verdict-block "$C/verdict-block-good.md"
expect_rc "verdict-block: SEEDED out-of-vocab caught"  1 bash "$DIR/check-claim-ceiling.sh" --verdict-block "$C/verdict-block-bad.md"
# ship table: empty cell caught
expect_rc "ship-table: good passes"           0 bash "$DIR/check-ship-table.sh" "$C/ship-good.md"
expect_rc "ship-table: SEEDED empty cell caught" 1 bash "$DIR/check-ship-table.sh" "$C/ship-bad.md"
# cost table: missing arm row caught
expect_rc "cost-table: good passes"              0 bash "$DIR/check-cost-table.sh" "$C/cost-good.md"
expect_rc "cost-table: SEEDED missing arm caught" 1 bash "$DIR/check-cost-table.sh" "$C/cost-bad.md"
# substrate: SHA/refs mismatch caught (record-only mode for fixtures)
expect_rc "substrate: good passes"              0 bash "$DIR/check-substrate-intact.sh" --record-only "$C/substrate-good.md"
expect_rc "substrate: SEEDED refs mismatch caught" 1 bash "$DIR/check-substrate-intact.sh" --record-only "$C/substrate-bad.md"
# instrument pre-arm: isolation-probe failure caught
expect_rc "instrument --pre-arm: good passes"             0 bash "$DIR/check-instrument.sh" --pre-arm --record "$C/instrument-good-prearm.md"
expect_rc "instrument --pre-arm: SEEDED isolation FAIL caught" 1 bash "$DIR/check-instrument.sh" --pre-arm --record "$C/instrument-bad-isolation.md"
# instrument full: missing canary verdict caught; contaminated-but-LIVE caught; unclassified surface forces VOID
expect_rc "instrument full: good passes"                  0 bash "$DIR/check-instrument.sh" --record "$C/instrument-good-full.md" --arms "$C/arm-good"
expect_rc "instrument full: SEEDED missing canary caught" 1 bash "$DIR/check-instrument.sh" --record "$C/instrument-bad-missing-canary.md" --arms "$C/arm-good"
expect_rc "instrument full: SEEDED CONTAMINATED+LIVE inconsistency caught" 1 bash "$DIR/check-instrument.sh" --record "$C/instrument-bad-contaminated-live.md" --arms "$C/arm-good"
expect_rc "instrument full: SEEDED unclassified surface w/o VOID caught"   1 bash "$DIR/check-instrument.sh" --record "$C/instrument-good-full.md" --arms "$C/arm-bad"
# surfacing detector rehearsal pair (the design's most load-bearing matcher)
expect_rc "detector: exactly-once fixture → SURFACED"     0 bash "$DIR/detect-surfacing.sh" "$C/ctrl-good/settings.json" "$C/ctrl-good/settings.local.json" scan-secrets.sh
expect_rc "detector: SEEDED duplicate fixture → NOT-SURFACED" 1 bash "$DIR/detect-surfacing.sh" "$C/ctrl-bad/settings.json" "$C/ctrl-bad/settings.local.json" scan-secrets.sh

if [ "$fail" -eq 0 ]; then echo "STAGE2-CHECKERS: ALL CONTROLS PASS"; else echo "STAGE2-CHECKERS: CONTROL FAILURES"; fi
exit "$fail"
