#!/usr/bin/env bash
# check-instrument.sh — Phase 87. Validates the instrument record (and, in full mode,
# the arm records + run-status consistency rules).
#   --pre-arm            : pre-arm keys only (T4 gate, before any arm token)
#   --record <file>      : instrument record path (default: instrument-record.md)
#   --arms <dir>         : arm-records dir (full mode; default: arm-records/)
# Consistency (full): CANARY-VERDICT=CONTAMINATED -> RUN-STATUS=VOID;
# both CONTROL-VERDICTs NOT-SURFACED -> RUN-STATUS=INSTRUMENT-DEAD;
# any arm SURFACE-MANIFEST UNCLASSIFIED -> RUN-STATUS=VOID. Exit 0 iff valid.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mode=full; REC="$DIR/instrument-record.md"; ARMS="$DIR/arm-records"
while [ $# -gt 0 ]; do
  case "$1" in
    --pre-arm) mode=prearm; shift ;;
    --record)  REC="$2"; shift 2 ;;
    --arms)    ARMS="$2"; shift 2 ;;
    *) echo "unknown arg: $1"; exit 2 ;;
  esac
done
fail=0
[ -f "$REC" ] || { echo "FAIL: instrument record $REC missing"; exit 1; }

req() { # <key> <value-regex>
  if grep -qE "^$1: $2" "$REC"; then echo "PASS: $1"; else echo "FAIL: $1 missing or invalid (want $2)"; fail=1; fi
}

# Pre-arm keys (both modes)
req "SETUP-SHA" "[0-9a-f]+"
req "CHECKPOINT-ACK-SEED" ".+"
req "CHECKPOINT-ACK-CLONES" ".+"
req "CANARY-PRECHECK" "PASS"
req "RESTORATION-TEST" "PASS"
req "ISOLATION-PROBE" "PASS"
req "HOOK-FIRE-PROBE" "PASS"
req "DETECTOR-REHEARSAL" "PASS"
req "EXTRACTOR-SMOKE" "(PASS|NOT-EXTRACTABLE)"
req "CONTROL-HOOK" ".+"

if [ "$mode" = "full" ]; then
  req "CONTROL-TASK-BYTE-IDENTITY" "PASS"
  req "CANARY-VERDICT" "(CLEAN|CONTAMINATED)"
  req "CONTROL-VERDICT-ARM-A" "(SURFACED|NOT-SURFACED)"
  req "CONTROL-VERDICT-ARM-B" "(SURFACED|NOT-SURFACED)"
  req "RUN-STATUS" "(LIVE|VOID|INSTRUMENT-DEAD)"

  status=$(grep -E '^RUN-STATUS:' "$REC" | awk '{print $2}')
  canary=$(grep -E '^CANARY-VERDICT:' "$REC" | awk '{print $2}')
  ca=$(grep -E '^CONTROL-VERDICT-ARM-A:' "$REC" | awk '{print $2}')
  cb=$(grep -E '^CONTROL-VERDICT-ARM-B:' "$REC" | awk '{print $2}')
  if [ "$canary" = "CONTAMINATED" ] && [ "$status" != "VOID" ]; then
    echo "FAIL: canary CONTAMINATED but RUN-STATUS=$status (must be VOID)"; fail=1; fi
  if [ "$ca" = "NOT-SURFACED" ] && [ "$cb" = "NOT-SURFACED" ] && [ "$status" != "INSTRUMENT-DEAD" ]; then
    echo "FAIL: neither arm surfaced the control but RUN-STATUS=$status (must be INSTRUMENT-DEAD)"; fail=1; fi

  for arm in arm-b arm-a; do
    A="$ARMS/$arm.md"
    [ -f "$A" ] || { echo "FAIL: arm record $A missing"; fail=1; continue; }
    for kv in "STATUS: (FINISHED|DNF)" "TRANSCRIPT-DIR: .+" "KIT-HEAD-AT-START: 6728e2f" \
              "CAP-DEADLINE-S: [0-9]+" "WALL-S: [0-9]+" "INTERACTION-LOG: .+" \
              "SURFACE-MANIFEST: (ALL-CLASSIFIED|UNCLASSIFIED:.+)"; do
      k="${kv%%:*}"
      if grep -qE "^$kv" "$A"; then echo "PASS: $arm $k"; else echo "FAIL: $arm $k missing/invalid"; fail=1; fi
    done
    if grep -qE '^SURFACE-MANIFEST: UNCLASSIFIED:' "$A" && [ "${status:-}" != "VOID" ]; then
      echo "FAIL: $arm has an unclassified context surface but RUN-STATUS=${status:-unset} (must be VOID)"; fail=1
    fi
  done
fi
[ "$fail" -eq 0 ] && echo "INSTRUMENT: PASS ($mode)" || echo "INSTRUMENT: FAIL ($mode)"
exit "$fail"
