#!/usr/bin/env bash
# check.sh — deterministic scorer for the skill-crystallization headroom screen (Phase 78).
#
# NO LLM, NO embedding, NO judge. An OFF re-derivation (a model-produced implementation A') is scored
# by RUNNING a candidate's PRE-REGISTERED spec-implied correctness tests against it. This is the
# verifier-independent core: OFF never sees the tests; the tests are the out-of-band oracle.
#
# It deliberately CLONES the frozen anchor-screen/check.sh consensus apparatus: `aggregate`,
# `stability`, `verify_pins`, `_shasum`, N_REQUIRED=5, CONSENSUS_THRESHOLD=4 are byte-for-byte the
# same logic (see ../anchor-screen/check.sh). The ONLY substantive change is `run_check`: where the
# anchor screen grep-classified a text output against named clauses, this DISPATCHES to a per-candidate
# harness that executes the spec-implied tests and reports PASS | FAIL:<assertion-id>. The "clause-id"
# the aggregator demands consensus on is the first-failing spec-implied ASSERTION — so HAS-HEADROOM
# means "the bare model misses the SAME correctness ≥4/5", not OR-of-any-failure.
#
# Per-candidate harness contract — harnesses/<candidate>.sh <off_output_path>  MUST print exactly:
#     PASS                  (all pinned spec-implied assertions hold for A')
#     FAIL:<assertion-id>   (first-failing spec-implied assertion; the consensus key)
#   and nothing else on stdout. NO LLM in the harness. Harnesses run A' in a throwaway sandbox.
#
# Modes:
#   check.sh --run <candidate> <off_output>            → "PASS" | "FAIL:<assertion-id>"
#   check.sh --aggregate <candidate> <out1>..<outN>    → "verdict: ..." (+ "consensus-clause:")
#   check.sh --stability <verdictA> <verdictB>         → "stability: STABLE|FALSE-POSITIVE"
#   check.sh --verify-pins                             → exits 0 iff every prereg corpus/harness shasum matches
#   check.sh --selftest                                → exits 0 iff the planted correct/buggy pair flips both ways
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
N_REQUIRED=5          # n is pinned at exactly 5 (pre-registered, frozen) — cloned from anchor-screen
CONSENSUS_THRESHOLD=4 # >=4/5 — both for DEGENERATE (pass) and HAS-HEADROOM (same-assertion fail)

_shasum() { shasum -a 256 "$1" | awk '{print $1}'; }

run_check() {  # <candidate> <off_output>  → echoes PASS or FAIL:<assertion-id>
  # The ONLY divergence from anchor-screen/check.sh: dispatch to a per-candidate test harness
  # instead of grep-classifying against a .check file. The harness runs the pinned spec-implied
  # tests against the model's re-derivation A' and emits PASS | FAIL:<assertion-id>. NO LLM.
  local candidate="$1" out="$2" r harness
  harness="$DIR/harnesses/$candidate.sh"
  [ -x "$harness" ] || { echo "FAIL:NO-HARNESS-$candidate"; return 0; }
  [ -f "$out" ]     || { echo "FAIL:NO-OUTPUT"; return 0; }
  r="$("$harness" "$out" 2>/dev/null)" || true
  case "$r" in
    PASS|FAIL:*) echo "$r";;
    *)           echo "FAIL:HARNESS-MALFORMED";;   # a harness that does not speak the contract fails closed
  esac
}

aggregate() {  # <candidate> <out1>..<outN>  → verdict over the n runs   [CLONED byte-verbatim]
  local cf="$1"; shift
  local pass=0 fail=0 fails="" n=$# r
  if [ "$n" -ne "$N_REQUIRED" ]; then
    echo "verdict: ERROR (n=$n, expected exactly $N_REQUIRED)" >&2; return 2
  fi
  for out in "$@"; do
    r="$(run_check "$cf" "$out")"
    if [ "$r" = PASS ]; then pass=$((pass+1)); else fail=$((fail+1)); fails="${fails}${r#FAIL:}
"; fi
  done
  # most-failed single assertion-id (consensus-by-clause, NOT OR-of-any-failure)
  local maxc=0 topclause="" c cnt
  if [ "$fail" -gt 0 ]; then
    while read -r c cnt; do
      [ -z "${c:-}" ] && continue
      if [ "$cnt" -gt "$maxc" ]; then maxc="$cnt"; topclause="$c"; fi
    done <<EOF
$(printf '%s' "$fails" | grep -v '^$' | sort | uniq -c | awk '{print $2" "$1}')
EOF
  fi
  if [ "$pass" -ge "$CONSENSUS_THRESHOLD" ]; then
    echo "verdict: DEGENERATE"
  elif [ "$fail" -ge "$CONSENSUS_THRESHOLD" ] && [ "$maxc" -ge "$CONSENSUS_THRESHOLD" ]; then
    echo "verdict: HAS-HEADROOM"
    echo "consensus-clause: $topclause"
  else
    echo "verdict: UNSTABLE"
  fi
}

stability() {  # <verdictA> <verdictB>  [CLONED byte-verbatim from anchor-screen — see its rationale]
  # A HAS-HEADROOM draw in EITHER independent batch on a known-borderline candidate is the costly
  # false-positive (false build-go); UNSTABLE/DEGENERATE jitter is the safe direction.
  local a="$1" b="$2"
  if [ "$a" = HAS-HEADROOM ] || [ "$b" = HAS-HEADROOM ]; then
    echo "stability: FALSE-POSITIVE"
  else
    echo "stability: STABLE"
  fi
}

verify_pins() {  # every  corpus|harness: <path> / shasum: <hex>  pair in pre-registration.md must match
  local prereg="$DIR/pre-registration.md"
  [ -f "$prereg" ] || { echo "verify-pins: pre-registration.md absent" >&2; return 1; }
  local cur="" recorded actual rc=0 seen=0
  while IFS= read -r line; do
    case "$line" in
      "corpus: "*)  cur="${line#corpus: }";;
      "harness: "*) cur="${line#harness: }";;
      "shasum: "*)
        recorded="${line#shasum: }"
        if [ -z "$cur" ] || [ ! -f "$DIR/$cur" ]; then
          echo "verify-pins: missing file for shasum $recorded" >&2; rc=1; continue
        fi
        actual="$(_shasum "$DIR/$cur")"; seen=$((seen+1))
        if [ "$actual" != "$recorded" ]; then
          echo "verify-pins: DRIFT $cur (recorded $recorded, actual $actual)" >&2; rc=1
        fi
        cur="";;
    esac
  done < "$prereg"
  [ "$seen" -ge 1 ] || { echo "verify-pins: no corpus/harness shasum pins found" >&2; return 1; }
  return "$rc"
}

selftest() {
  # Planted toy candidate proves check.sh flips BOTH ways independent of the real candidates.
  # Toy task: "define bash function f(a,b) returning a+b". correct.txt adds (f 2 3 → 5); buggy.txt
  # multiplies (f 2 3 → 6 ≠ 5). The toy harness runs that single spec-implied assertion.
  local f="$DIR/fixtures" fail=0
  _expect() { if [ "$2" = "$3" ]; then echo "ok: $1 → $3"; else echo "FAIL: $1 expected [$2] got [$3]"; fail=1; fi; }
  _expect "run-correct" "PASS"        "$(run_check selftest-toy "$f/selftest-toy-correct.txt")"
  _expect "run-buggy"   "FAIL:adds"   "$(run_check selftest-toy "$f/selftest-toy-buggy.txt")"
  # 5 correct → DEGENERATE (model re-derives it → no headroom)
  _expect "agg-degenerate" "verdict: DEGENERATE" \
    "$(aggregate selftest-toy "$f/selftest-toy-correct.txt" "$f/selftest-toy-correct.txt" "$f/selftest-toy-correct.txt" "$f/selftest-toy-correct.txt" "$f/selftest-toy-correct.txt" | head -1)"
  # 5 same-assertion fail → HAS-HEADROOM (non-recoverable correctness)
  _expect "agg-headroom" "verdict: HAS-HEADROOM" \
    "$(aggregate selftest-toy "$f/selftest-toy-buggy.txt" "$f/selftest-toy-buggy.txt" "$f/selftest-toy-buggy.txt" "$f/selftest-toy-buggy.txt" "$f/selftest-toy-buggy.txt" | head -1)"
  _expect "agg-headroom-clause" "consensus-clause: adds" \
    "$(aggregate selftest-toy "$f/selftest-toy-buggy.txt" "$f/selftest-toy-buggy.txt" "$f/selftest-toy-buggy.txt" "$f/selftest-toy-buggy.txt" "$f/selftest-toy-buggy.txt" | sed -n 2p)"
  # 3 correct / 2 buggy → UNSTABLE (neither side reaches 4/5)
  _expect "agg-unstable" "verdict: UNSTABLE" \
    "$(aggregate selftest-toy "$f/selftest-toy-correct.txt" "$f/selftest-toy-correct.txt" "$f/selftest-toy-correct.txt" "$f/selftest-toy-buggy.txt" "$f/selftest-toy-buggy.txt" | head -1)"
  # stability rule (cloned): a HAS-HEADROOM draw in either batch is the fatal false-positive
  _expect "stab-both-unstable"  "stability: STABLE"         "$(stability UNSTABLE UNSTABLE)"
  _expect "stab-deg-unstable"   "stability: STABLE"         "$(stability DEGENERATE UNSTABLE)"
  _expect "stab-headroom-left"  "stability: FALSE-POSITIVE" "$(stability HAS-HEADROOM UNSTABLE)"
  _expect "stab-headroom-right" "stability: FALSE-POSITIVE" "$(stability DEGENERATE HAS-HEADROOM)"
  # harness-contract guard: a malformed harness output must fail closed, not pass
  _expect "malformed-fails" "FAIL:HARNESS-MALFORMED" "$(run_check selftest-chatty "$f/selftest-toy-correct.txt")"
  [ "$fail" -eq 0 ] && { echo "SELFTEST: PASS"; return 0; } || { echo "SELFTEST: FAIL"; return 1; }
}

case "${1:---selftest}" in
  --run)         shift; run_check "$@";;
  --aggregate)   shift; aggregate "$@";;
  --stability)   shift; stability "$@";;
  --verify-pins) verify_pins && echo "verify-pins: OK";;
  --selftest)    selftest;;
  *) echo "usage: check.sh --run|--aggregate|--stability|--verify-pins|--selftest ..." >&2; exit 2;;
esac
