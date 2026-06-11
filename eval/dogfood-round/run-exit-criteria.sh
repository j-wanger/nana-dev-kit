#!/usr/bin/env bash
# Phase 89 exit-criteria runner — the 10 machine-checkable criteria from
# specs/phase-89-dogfood-demand-evidence.md. Exit 0 + ALL-PASS iff every criterion RAN and
# passed. DOGFOOD_SKIP_SLOW=1 skips c9 (make test/eval) and the run prints
# "PARTIAL (skipped: c9)" — partial runs are visibly partial and CANNOT print ALL-PASS.
# Testability: DOGFOOD_CRITERIA_STUB points every criterion at <stubdir>/cN.sh instead of the
# real command (the --selftest seeded-failure and skip-slow controls run on stubs only — the
# real slow criteria are never executed by selftest). A missing checker script is a FAIL for
# its criterion, not a crash. Clean-on-seed = instrument-dead, may not ship.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$DIR" rev-parse --show-toplevel)"
cd "$ROOT"
STUB="${DOGFOOD_CRITERIA_STUB:-}"
pass=0; failn=0; skipped=0; total=10

run_c() { # <cN> <desc> <cmd...>
  local n="$1" desc="$2"; shift 2
  [ -n "$STUB" ] && set -- bash "$STUB/$n.sh"
  if "$@" >/dev/null 2>&1; then
    echo "$n: PASS — $desc"; pass=$((pass+1))
  else
    echo "$n: FAIL — $desc"; failn=$((failn+1))
  fi
}

c9_real() { # make test green AND make eval all-pass at denominator 50
  make test >/dev/null 2>&1 || return 1
  local out count
  out=$(make eval 2>&1) || return 1
  count=$(grep -oE 'Score: [0-9]+/[0-9]+' <<<"$out" | grep -oE '/[0-9]+' | tr -d /)
  [ "$count" = "50" ] || return 1   # post-trim denominator pin (detect-loop cut 75b48af)
  grep -qE "Score: $count/$count" <<<"$out"
}

main() {
  run_c c1 "pre-registration committed-before-evidence + pinned sections" \
    bash eval/dogfood-round/check-preregistration.sh
  run_c c2 "evidence content (header pins, liveness exit-code placement, demand tallies)" \
    bash eval/dogfood-round/check-evidence-content.sh
  run_c c3 "edge-screener currency (detect-loop gone, ctw hash current, basename-unique)" \
    bash eval/dogfood-round/check-currency.sh
  run_c c4 "liveness-probe record exists" \
    test -f eval/dogfood-round/evidence/liveness-probe.md
  run_c c5 "session evidence format (>=3 blocks in pinned schema)" \
    bash eval/dogfood-round/check-evidence-format.sh
  run_c c6 "memory-demand close-out exists" \
    test -f eval/dogfood-round/evidence/memory-demand.md
  run_c c7 "window-events attestations + verbatim triggers, zero unfiled events" \
    bash eval/dogfood-round/check-window-events.sh
  run_c c8 "no-disposition guard over the pinned phase range" \
    bash eval/dogfood-round/check-no-disposition.sh
  if [ "${DOGFOOD_SKIP_SLOW:-0}" = "1" ]; then
    echo "c9: SKIPPED — make test + make eval denominator-50 (DOGFOOD_SKIP_SLOW)"; skipped=$((skipped+1))
  else
    run_c c9 "make test green + make eval all-pass at denominator 50" c9_real
  fi
  run_c c10 "_CURRENT_STATE.md Blockers cite memory-demand evidence" \
    grep -q 'eval/dogfood-round/evidence/memory-demand.md' .dev-wiki/_CURRENT_STATE.md
  echo "----"
  echo "RESULT: $pass PASS / $failn FAIL / $skipped SKIPPED (of $total)"
  if [ "$skipped" -gt 0 ]; then echo "PARTIAL (skipped: c9)"; exit 1; fi
  if [ "$failn" -eq 0 ]; then echo "ALL-PASS"; exit 0; fi
  exit 1
}

selftest() {
  local t n out sfail=0
  t=$(mktemp -d)
  # shellcheck disable=SC2064 — expand now: $t is function-local, gone by EXIT time
  trap "rm -rf '$t'" EXIT
  mkdir -p "$t/ok" "$t/seeded"
  for n in c1 c2 c3 c4 c5 c6 c7 c8 c9 c10; do
    printf '#!/usr/bin/env bash\nexit 0\n' > "$t/ok/$n.sh"
    cp "$t/ok/$n.sh" "$t/seeded/$n.sh"
  done
  printf '#!/usr/bin/env bash\nexit 1\n' > "$t/seeded/c3.sh"

  # Control 1 (positive): all-pass stub run prints ALL-PASS and exits 0.
  if out=$(DOGFOOD_CRITERIA_STUB="$t/ok" DOGFOOD_SKIP_SLOW=0 bash "$0") \
     && grep -qx 'ALL-PASS' <<<"$out"; then :; else
    echo "SELFTEST FAIL: all-pass stub run did not print ALL-PASS" >&2; sfail=1; fi

  # Control 2: a seeded failing criterion (c3) prevents ALL-PASS and is reported FAIL.
  out=$(DOGFOOD_CRITERIA_STUB="$t/seeded" DOGFOOD_SKIP_SLOW=0 bash "$0") && {
    echo "SELFTEST FAIL: seeded-failure run exited 0 (instrument-dead)" >&2; sfail=1; }
  grep -q '^c3: FAIL' <<<"$out" || { echo "SELFTEST FAIL: seeded c3 not reported FAIL" >&2; sfail=1; }
  grep -qx 'ALL-PASS' <<<"$out" && { echo "SELFTEST FAIL: seeded run printed ALL-PASS" >&2; sfail=1; }

  # Control 3: skip-slow run is visibly PARTIAL and cannot print ALL-PASS even all-green.
  out=$(DOGFOOD_CRITERIA_STUB="$t/ok" DOGFOOD_SKIP_SLOW=1 bash "$0") && {
    echo "SELFTEST FAIL: skip-slow run exited 0" >&2; sfail=1; }
  grep -qx 'PARTIAL (skipped: c9)' <<<"$out" || { echo "SELFTEST FAIL: PARTIAL marker absent" >&2; sfail=1; }
  grep -qx 'ALL-PASS' <<<"$out" && { echo "SELFTEST FAIL: skip-slow run printed ALL-PASS" >&2; sfail=1; }

  [ "$sfail" -eq 0 ] && echo "SELFTEST PASS (3/3 controls)" || { echo "SELFTEST FAIL" >&2; exit 1; }
}

if [ "${1:-}" = "--selftest" ]; then selftest; exit 0; fi
main
