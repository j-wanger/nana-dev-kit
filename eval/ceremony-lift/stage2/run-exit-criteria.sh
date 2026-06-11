#!/usr/bin/env bash
# run-exit-criteria.sh — Phase 87 exit-criteria runner (mirrors stage-1 run_c pattern).
# 8 criteria from specs/phase-87-stage2-episode-contrast.md. If the recorded RUN-STATUS
# is VOID or INSTRUMENT-DEAD (pre-declared honest end states), criteria 4-5 report
# N/A-<STATUS> instead of running (the episode produced no live contest tables).
# Exit 0 iff every criterion PASSes or is N/A by run-status.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$DIR" rev-parse --show-toplevel)"
cd "$ROOT"
pass=0; failn=0; na=0; total=8

STATUS="LIVE"
if [ -f "$DIR/instrument-record.md" ]; then
  s=$(grep -E '^RUN-STATUS:' "$DIR/instrument-record.md" | awk '{print $2}' || true)
  [ -n "${s:-}" ] && STATUS="$s"
fi

run_c() { # <n> <desc> <na-when-not-live: yes|no> <cmd...>
  local n="$1" desc="$2" naflag="$3"; shift 3
  if [ "$naflag" = "yes" ] && [ "$STATUS" != "LIVE" ]; then
    echo "criterion $n: N/A-$STATUS — $desc"; na=$((na+1)); return
  fi
  if "$@" >/dev/null 2>&1; then
    echo "criterion $n: PASS — $desc"; pass=$((pass+1))
  else
    echo "criterion $n: FAIL — $desc"; failn=$((failn+1))
  fi
}

c2() { # addendum first-add-commit strictly precedes results' and is byte-unchanged between
  local P R
  P=$(git log --diff-filter=A --format=%H -- eval/ceremony-lift/stage2/execution-protocol.md | tail -1)
  R=$(git log --diff-filter=A --format=%H -- eval/ceremony-lift/stage2/results.md | tail -1)
  [ -n "$P" ] && [ -n "$R" ] || return 1
  git merge-base --is-ancestor "$P" "$R" || return 1
  git diff --quiet "$P" "$R" -- eval/ceremony-lift/stage2/execution-protocol.md
}

run_c 1 "stage-1 pre-registration byte-intact + stage-1 apparatus additive-only" no \
  bash -c "git diff --quiet 9ad62f0 HEAD -- eval/ceremony-lift/pre-registration.md && git diff --quiet 6728e2f HEAD -- eval/ceremony-lift/ ':(exclude)eval/ceremony-lift/stage2'"
run_c 2 "execution-protocol addendum precedes results and is byte-frozen between" no c2
run_c 3 "instrument record valid (full mode: canary/control/byte-identity/probes)" no \
  bash eval/ceremony-lift/stage2/check-instrument.sh
run_c 4 "ship table well-formed (both arms, no empty cells, tie-break iff both pass)" yes \
  bash eval/ceremony-lift/stage2/check-ship-table.sh
run_c 5 "cost table well-formed (per-arm wall/interrupts/tokens, interaction logs)" yes \
  bash eval/ceremony-lift/stage2/check-cost-table.sh
run_c 6 "claim ceiling embedded + no minting language + closed-vocabulary disposition" no \
  bash -c "bash eval/ceremony-lift/stage2/check-claim-ceiling.sh --verdict-block .dev-wiki/articles/phases/phase-87-stage2-episode-contrast.md && bash eval/ceremony-lift/stage2/check-claim-ceiling.sh eval/ceremony-lift/stage2/results.md"
run_c 7 "substrate intact (refs identical/ship-authorized; embargo held across window)" no \
  bash eval/ceremony-lift/stage2/check-substrate-intact.sh
run_c 8 "verdicts/evidence-only: no kit component modified vs pinned base 6728e2f" no \
  git diff --quiet 6728e2f..HEAD -- templates/ scripts/ install.sh modules.json Makefile

echo "----"
echo "RUN-STATUS: $STATUS"
echo "RESULT: $pass PASS / $failn FAIL / $na N/A (of $total)"
[ "$failn" -eq 0 ] && exit 0 || exit 1
