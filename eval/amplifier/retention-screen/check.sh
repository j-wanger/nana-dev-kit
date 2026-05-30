#!/usr/bin/env bash
# check.sh — deterministic named-clause checker for the CROSS-BOUNDARY RETENTION screen (Phase 71).
#
# Cloned from ../anchor-screen/check.sh: run_check, aggregate, stability, verify_pins are PORTED
# VERBATIM. The ONLY additions are diff_verdict() + the --diff mode — the differential two-condition
# (OFF n=5 × ON n=5) verdict the retention screen needs (the anchor screen had one OFF condition).
#
# Deterministic only — no model judge, no vectors, no fuzzy scoring. A model OUTPUT file is classified against an item's PRE-REGISTERED
# clauses (a .check file: "did the model HONOR the dropped decision?"). consensus-by-clause (not
# OR-of-failures, not a fuzzy score) is the guard against the asymmetric false-HAS-HEADROOM risk.
#
# Differential verdict (over an OFF aggregate and an ON aggregate of the SAME .check):
#   DEGENERATE    — OFF PASSES ≥4/5: residual context already honors the decision; harness adds nothing.
#   HAS-HEADROOM  — OFF FAILS ≥4/5 (same consensus-clause) AND ON PASSES ≥4/5: harness recovered it.
#   INERT         — OFF FAILS ≥4/5 AND ON FAILS ≥4/5 on the SAME clause: harness present but not honored.
#   UNSTABLE      — anything else, incl. ON failing on a DIFFERENT clause than OFF (honored the decision
#                   but broke another element → quarantine, never INERT) and the n=5 dead zone.
#
# A .check file is TAB-separated lines:   <clause-id>\t<require|forbid>\t<ERE>
#   require  → the correct behavior is PRESENT iff this ERE matches the output (case-insensitive)
#   forbid   → the output must NOT match this ERE (e.g. a hedge marker, or a wrong conclusion)
# Lines beginning with '#' and blank lines are ignored.
#
# A single run PASSES iff every 'require' clause matches AND no 'forbid' clause matches.
# On FAIL the PRIMARY failing clause-id is reported (first require-miss, else first forbid-hit),
# so the aggregator can demand CONSENSUS on the same missing behavior.
#
# Modes:
#   check.sh --run <checkfile> <outputfile>        → prints "PASS" | "FAIL:<clause-id>"
#   check.sh --aggregate <checkfile> <out1>..<outN> → prints "verdict: ..." (+ "consensus-clause:")
#   check.sh --diff <checkfile> <off1..off5> <on1..on5> → prints "screen-verdict: ..." (10 run files)
#   check.sh --stability <verdict-b1> <verdict-b2> → prints "stability: STABLE|FALSE-POSITIVE"
#   check.sh --selftest                            → exits 0 iff planted classify + differential + pins verify
#   check.sh --verify-pins                         → exits 0 iff every pre-registration prompt-shasum matches
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
N_REQUIRED=5          # n is pinned at exactly 5 (pre-registered, frozen)
CONSENSUS_THRESHOLD=4 # >=4/5 — both for DEGENERATE (pass) and HAS-HEADROOM (same-clause fail)

_shasum() { shasum -a 256 "$1" | awk '{print $1}'; }

run_check() {  # <checkfile> <outputfile>  → echoes PASS or FAIL:<clause-id>
  local cf="$1" out="$2" cid type re
  # require-misses first (a missing correct behavior is the headroom signal)
  while IFS=$'\t' read -r cid type re; do
    case "${cid:-}" in ''|\#*) continue;; esac
    if [ "$type" = require ] && ! grep -Eiq -- "$re" "$out"; then
      echo "FAIL:$cid"; return 0
    fi
  done < "$cf"
  # forbid-hits second (a hedge marker or a wrong conclusion present)
  while IFS=$'\t' read -r cid type re; do
    case "${cid:-}" in ''|\#*) continue;; esac
    if [ "$type" = forbid ] && grep -Eiq -- "$re" "$out"; then
      echo "FAIL:$cid"; return 0
    fi
  done < "$cf"
  echo PASS
}

aggregate() {  # <checkfile> <out1>..<outN>  → verdict over the n runs
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
  # most-failed single clause-id (consensus-by-clause, NOT OR-of-any-failure)
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

stability() {  # <verdict-batch1> <verdict-batch2>  → STABLE unless a batch false-positived
  # Middle-control criterion (pre-registered, pre-run). A known-PARTIAL anchor (~half correct) must
  # NOT read HAS-HEADROOM in either independent n=5 batch — that draw is the costliest error (false
  # continue) the screen exists to prevent. UNSTABLE/DEGENERATE jitter between batches is acceptable
  # (the safe direction; the screen quarantines or under-calls, never over-calls). Rationale: at n=5
  # a true p≈0.5 anchor is maximally UNSTABLE (~62% per batch), so demanding "reproduces UNSTABLE"
  # would self-halt ~55% of the time on a working instrument; demanding "never false-positives" is
  # the property that actually matters and is statistically robust (P(a HAS-HEADROOM draw)≈0.19/batch
  # only if the anchor sits AT 0.5; a correct-leaning partial control makes it rarer still).
  local a="$1" b="$2"
  if [ "$a" = HAS-HEADROOM ] || [ "$b" = HAS-HEADROOM ]; then
    echo "stability: FALSE-POSITIVE"   # screen over-called the known-partial control → instrument-broken → STOP
  else
    echo "stability: STABLE"
  fi
}

diff_verdict() {  # <off_verdict> <off_clause> <on_verdict> <on_clause> → screen-verdict
  # Composes two aggregate() outputs. aggregate's "DEGENERATE" = honored ≥4/5; "HAS-HEADROOM" =
  # dropped ≥4/5 on a consensus clause. The retention screen reads OFF and ON together.
  local ov="$1" oc="$2" nv="$3" nc="$4"
  if [ "$ov" = DEGENERATE ]; then
    echo DEGENERATE                       # OFF honored ≥4/5 → residual context suffices; harness adds nothing
  elif [ "$ov" = HAS-HEADROOM ]; then     # OFF DROPPED ≥4/5 on consensus clause $oc (headroom precondition)
    if [ "$nv" = DEGENERATE ]; then
      echo HAS-HEADROOM                    # ON honored ≥4/5 → the harness state recovered the dropped decision
    elif [ "$nv" = HAS-HEADROOM ] && [ "$nc" = "$oc" ]; then
      echo INERT                           # ON dropped the SAME decision → state present in-context but not honored
    else
      echo UNSTABLE                        # ON jittery, OR dropped a DIFFERENT clause (honored decision, broke
    fi                                     #   another element) → quarantine, NEVER INERT
  else
    echo UNSTABLE                          # OFF jittery / n=5 dead zone → never round toward HAS-HEADROOM
  fi
}

diff_screen() {  # <checkfile> <off1>..<off5> <on1>..<on5> → screen-verdict over the two n=5 batches
  local cf="$1"; shift
  if [ "$#" -ne "$((2*N_REQUIRED))" ]; then
    echo "screen-verdict: ERROR (got $# run files, expected $((2*N_REQUIRED)): 5 OFF then 5 ON)" >&2; return 2
  fi
  # N_REQUIRED is pinned at 5; first 5 args are OFF runs, next 5 are ON runs.
  local off_out on_out ov oc nv nc
  off_out="$(aggregate "$cf" "${@:1:5}")"
  on_out="$(aggregate "$cf" "${@:6:5}")"
  ov="$(printf '%s\n' "$off_out" | sed -n 's/^verdict: //p')"
  oc="$(printf '%s\n' "$off_out" | sed -n 's/^consensus-clause: //p')"
  nv="$(printf '%s\n' "$on_out"  | sed -n 's/^verdict: //p')"
  nc="$(printf '%s\n' "$on_out"  | sed -n 's/^consensus-clause: //p')"
  echo "screen-verdict: $(diff_verdict "$ov" "${oc:-}" "$nv" "${nc:-}")"
  echo "off: $ov${oc:+ ($oc)}"
  echo "on: $nv${nc:+ ($nc)}"
}

verify_pins() {  # every  prompt: <path> / prompt-shasum: <hex>  pair in pre-registration.md must match
  local prereg="$DIR/pre-registration.md"
  [ -f "$prereg" ] || { echo "verify-pins: pre-registration.md absent" >&2; return 1; }
  local cur_prompt="" recorded actual rc=0 seen=0
  while IFS= read -r line; do
    case "$line" in
      "prompt: "*)        cur_prompt="${line#prompt: }";;
      "prompt-shasum: "*)
        recorded="${line#prompt-shasum: }"
        if [ -z "$cur_prompt" ] || [ ! -f "$DIR/$cur_prompt" ]; then
          echo "verify-pins: missing prompt file for shasum $recorded" >&2; rc=1; continue
        fi
        actual="$(_shasum "$DIR/$cur_prompt")"; seen=$((seen+1))
        if [ "$actual" != "$recorded" ]; then
          echo "verify-pins: DRIFT $cur_prompt (recorded $recorded, actual $actual)" >&2; rc=1
        fi
        cur_prompt="";;
    esac
  done < "$prereg"
  [ "$seen" -ge 1 ] || { echo "verify-pins: no prompt-shasum pins found" >&2; return 1; }
  return "$rc"
}

selftest() {
  local f="$DIR/fixtures" cf="$DIR/fixtures/selftest.check" fail=0
  _expect() {  # <label> <expected> <actual>
    if [ "$2" = "$3" ]; then echo "ok: $1 → $3"; else echo "FAIL: $1 expected [$2] got [$3]"; fail=1; fi
  }
  # per-run classification, both directions + the hedged (present-but-not-committed) boundary
  _expect "pass"   "PASS"      "$(run_check "$cf" "$f/selftest-pass.txt")"
  _expect "fail"   "FAIL:kw"   "$(run_check "$cf" "$f/selftest-fail.txt")"
  _expect "hedged" "FAIL:hedge" "$(run_check "$cf" "$f/selftest-hedged.txt")"
  # aggregation: 5 pass → DEGENERATE
  _expect "agg-degenerate" "verdict: DEGENERATE" \
    "$(aggregate "$cf" "$f/selftest-pass.txt" "$f/selftest-pass.txt" "$f/selftest-pass.txt" "$f/selftest-pass.txt" "$f/selftest-pass.txt" | head -1)"
  # 5 same-clause fail → HAS-HEADROOM
  _expect "agg-headroom" "verdict: HAS-HEADROOM" \
    "$(aggregate "$cf" "$f/selftest-fail.txt" "$f/selftest-fail.txt" "$f/selftest-fail.txt" "$f/selftest-fail.txt" "$f/selftest-fail.txt" | head -1)"
  _expect "agg-headroom-clause" "consensus-clause: kw" \
    "$(aggregate "$cf" "$f/selftest-fail.txt" "$f/selftest-fail.txt" "$f/selftest-fail.txt" "$f/selftest-fail.txt" "$f/selftest-fail.txt" | sed -n 2p)"
  # 3 pass / 2 fail → UNSTABLE (neither side reaches 4/5)
  _expect "agg-unstable" "verdict: UNSTABLE" \
    "$(aggregate "$cf" "$f/selftest-pass.txt" "$f/selftest-pass.txt" "$f/selftest-pass.txt" "$f/selftest-fail.txt" "$f/selftest-fail.txt" | head -1)"
  # 5 fail but SPLIT across two clauses (3 kw + 2 hedge) → UNSTABLE, NOT HAS-HEADROOM
  #   this is the consensus-by-clause guard: OR-of-failures would wrongly call this HAS-HEADROOM
  _expect "agg-split-unstable" "verdict: UNSTABLE" \
    "$(aggregate "$cf" "$f/selftest-fail.txt" "$f/selftest-fail.txt" "$f/selftest-fail.txt" "$f/selftest-hedged.txt" "$f/selftest-hedged.txt" | head -1)"
  # stability rule (middle control): a HAS-HEADROOM draw in either batch is the fatal false-positive
  _expect "stab-both-unstable"   "stability: STABLE"         "$(stability UNSTABLE UNSTABLE)"
  _expect "stab-deg-unstable"    "stability: STABLE"         "$(stability DEGENERATE UNSTABLE)"
  _expect "stab-headroom-left"   "stability: FALSE-POSITIVE" "$(stability HAS-HEADROOM UNSTABLE)"
  _expect "stab-headroom-right"  "stability: FALSE-POSITIVE" "$(stability DEGENERATE HAS-HEADROOM)"
  # --- differential verdict (the retention-screen addition): OFF batch × ON batch ---
  local P="$f/selftest-pass.txt" Fl="$f/selftest-fail.txt" H="$f/selftest-hedged.txt"
  # OFF honored 5/5 → DEGENERATE regardless of ON (here ON drops, to prove ON is ignored)
  _expect "diff-degenerate" "screen-verdict: DEGENERATE" \
    "$(diff_screen "$cf" "$P" "$P" "$P" "$P" "$P"  "$Fl" "$Fl" "$Fl" "$Fl" "$Fl" | head -1)"
  # OFF dropped 5/5 (kw), ON honored 5/5 → HAS-HEADROOM (harness recovered it)
  _expect "diff-headroom" "screen-verdict: HAS-HEADROOM" \
    "$(diff_screen "$cf" "$Fl" "$Fl" "$Fl" "$Fl" "$Fl"  "$P" "$P" "$P" "$P" "$P" | head -1)"
  # OFF dropped 5/5 (kw), ON dropped 5/5 on the SAME clause (kw) → INERT
  _expect "diff-inert" "screen-verdict: INERT" \
    "$(diff_screen "$cf" "$Fl" "$Fl" "$Fl" "$Fl" "$Fl"  "$Fl" "$Fl" "$Fl" "$Fl" "$Fl" | head -1)"
  # OFF dropped 5/5 (kw), ON dropped 5/5 on a DIFFERENT clause (hedge) → UNSTABLE, NEVER INERT
  _expect "diff-cross-unstable" "screen-verdict: UNSTABLE" \
    "$(diff_screen "$cf" "$Fl" "$Fl" "$Fl" "$Fl" "$Fl"  "$H" "$H" "$H" "$H" "$H" | head -1)"
  # OFF jittery (3 honored / 2 dropped = dead zone) → UNSTABLE regardless of ON
  _expect "diff-off-deadzone" "screen-verdict: UNSTABLE" \
    "$(diff_screen "$cf" "$P" "$P" "$P" "$Fl" "$Fl"  "$P" "$P" "$P" "$P" "$P" | head -1)"
  # pin integrity — only once a pre-registration exists (T2); the apparatus self-test does not need it
  if [ -f "$DIR/pre-registration.md" ]; then
    if verify_pins; then echo "ok: verify-pins"; else echo "FAIL: verify-pins"; fail=1; fi
  else
    echo "skip: verify-pins (no pre-registration.md yet — exercised by --verify-pins at T2)"
  fi
  [ "$fail" -eq 0 ] && { echo "SELFTEST: PASS"; return 0; } || { echo "SELFTEST: FAIL"; return 1; }
}

case "${1:---selftest}" in
  --run)         shift; run_check "$@";;
  --aggregate)   shift; aggregate "$@";;
  --diff)        shift; diff_screen "$@";;
  --stability)   shift; stability "$@";;
  --verify-pins) verify_pins && echo "verify-pins: OK";;
  --selftest)    selftest;;
  *) echo "usage: check.sh --run|--aggregate|--diff|--stability|--verify-pins|--selftest ..." >&2; exit 2;;
esac
