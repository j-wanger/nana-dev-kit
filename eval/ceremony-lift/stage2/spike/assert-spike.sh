#!/usr/bin/env bash
# assert-spike.sh — Phase 87 T1 (ledger A4, spike-defended drivability assumption).
# Asserts a driven, gate-bearing scratch session reached its stop point under the
# closed response policy, with the responses logged verbatim. Exit 0 iff ALL hold:
#   1. run/STOP_MARKER exists and contains exactly "done" (the session reached its
#      scripted stop point — i.e. the gate did not stall the run)
#   2. run/response-log.txt exists and contains >=1 "GATE-RESPONSE" line (the
#      closed-policy responder answered >=1 AskUserQuestion gate, recorded verbatim)
#   3. run/mechanism.txt names the driving mechanism (pinned later in the addendum)
# A stalled, absent, or unanswered-gate run fails. No LLM judgment anywhere.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN="$DIR/run"
fail=0

check() { # <desc> <cmd...>
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $desc"
  else
    echo "FAIL: $desc"
    fail=1
  fi
}

check "stop marker exists with exact content 'done'" \
  bash -c '[ -f "'"$RUN"'/STOP_MARKER" ] && [ "$(cat "'"$RUN"'/STOP_MARKER")" = "done" ]'
check "response log exists with >=1 verbatim GATE-RESPONSE line" \
  bash -c '[ -f "'"$RUN"'/response-log.txt" ] && grep -q "^GATE-RESPONSE" "'"$RUN"'/response-log.txt"'
check "mechanism record names the driving mechanism" \
  bash -c '[ -s "'"$RUN"'/mechanism.txt" ]'

if [ "$fail" -eq 0 ]; then
  echo "SPIKE: PASS (drivability demonstrated)"
else
  echo "SPIKE: FAIL"
fi
exit "$fail"
