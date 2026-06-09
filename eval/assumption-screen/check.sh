#!/usr/bin/env bash
# check.sh — deterministic recovery scorer for the assumption-surfacer silent-class screen (Phase 80).
# Cloned from ../amplifier/anchor-screen/check.sh (run_check verbatim; aggregate adapted to
# RECOVERED/MISSED/UNSTABLE cells + a per-case SURFACER-vs-NAIVE compare). NO LLM, NO embedding, NO judge.
#
# A .check file is TAB-separated:  <clause-id>\t<require|forbid>\t<ERE>
#   require → the buried assumption is RECOVERED iff this ERE matches the run output (case-insensitive).
#   forbid  → the output must NOT match (a phantom/fabrication marker, or a leaked entity).
# A single run PASSES iff every require matches AND no forbid matches.
# A CELL (one condition × one fixture, n=5 runs) is:
#   RECOVERED iff pass >= CONSENSUS (the condition reliably surfaces the buried assumption)
#   MISSED    iff pass <= n-CONSENSUS (reliably misses it)
#   UNSTABLE  otherwise
#
# Modes:
#   check.sh --run   <checkfile> <outfile>            → "PASS" | "FAIL:<clause-id>"
#   check.sh --cell  <checkfile> <out1>..<outN>       → "cell: RECOVERED|MISSED|UNSTABLE (pass=P/N)"
#   check.sh --leak  <checkfile> <planfile>           → "leak: CLEAN" | "leak: LEAK:<clause-id>"  (control 3)
#   check.sh --selftest                               → exit 0 iff planted PASS/FAIL/leak classify correctly
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
N_REQUIRED=5
CONSENSUS_THRESHOLD=4

run_check() {  # <checkfile> <outputfile> → PASS | FAIL:<clause-id>
  local cf="$1" out="$2" cid type re
  while IFS=$'\t' read -r cid type re; do
    case "${cid:-}" in ''|\#*) continue;; esac
    if [ "$type" = require ] && ! grep -Eiq -- "$re" "$out"; then echo "FAIL:$cid"; return 0; fi
  done < "$cf"
  while IFS=$'\t' read -r cid type re; do
    case "${cid:-}" in ''|\#*) continue;; esac
    if [ "$type" = forbid ] && grep -Eiq -- "$re" "$out"; then echo "FAIL:$cid"; return 0; fi
  done < "$cf"
  echo PASS
}

cell() {  # <checkfile> <out1>..<outN> → cell: RECOVERED|MISSED|UNSTABLE (pass=P/N)
  local cf="$1"; shift
  local n=$# pass=0 r
  [ "$n" -eq "$N_REQUIRED" ] || { echo "cell: ERROR (n=$n, expected $N_REQUIRED)" >&2; return 2; }
  for out in "$@"; do r="$(run_check "$cf" "$out")"; [ "$r" = PASS ] && pass=$((pass+1)); done
  if [ "$pass" -ge "$CONSENSUS_THRESHOLD" ]; then echo "cell: RECOVERED (pass=$pass/$n)"
  elif [ "$pass" -le $((n-CONSENSUS_THRESHOLD)) ]; then echo "cell: MISSED (pass=$pass/$n)"
  else echo "cell: UNSTABLE (pass=$pass/$n)"; fi
}

# leak control (control 3): the buried assumption's own require-entities must NOT appear in the PLAN text,
# else the plan telegraphs the answer. CLEAN iff no require clause matches the plan.
leak() {  # <checkfile> <planfile> → leak: CLEAN | leak: LEAK:<clause-id>
  local cf="$1" plan="$2" cid type re
  while IFS=$'\t' read -r cid type re; do
    case "${cid:-}" in ''|\#*) continue;; esac
    if [ "$type" = require ] && grep -Eiq -- "$re" "$plan"; then echo "leak: LEAK:$cid"; return 0; fi
  done < "$cf"
  echo "leak: CLEAN"
}

selftest() {
  local d; d="$(mktemp -d)"; trap 'rm -rf "$d"' RETURN
  printf 'buried\trequire\t(actually fir(e|es|ing)|merely registered)\n' > "$d/c.check"
  printf 'the hook may be merely registered, not actually firing\n' > "$d/hit"     # PASS (recovered)
  printf 'this plan looks clean and complete\n'                        > "$d/miss"  # FAIL (missed)
  local rh rm; rh="$(run_check "$d/c.check" "$d/hit")"; rm="$(run_check "$d/c.check" "$d/miss")"
  # cell: 4 hits + 1 miss → RECOVERED
  local cv; cv="$(cell "$d/c.check" "$d/hit" "$d/hit" "$d/hit" "$d/hit" "$d/miss")"
  # leak: a plan that contains the require entities is a LEAK
  local lk lc; lk="$(leak "$d/c.check" "$d/hit")"; lc="$(leak "$d/c.check" "$d/miss")"
  if [ "$rh" = PASS ] && [ "$rm" = "FAIL:buried" ] && [ "$cv" = "cell: RECOVERED (pass=4/5)" ] \
     && [ "$lk" = "leak: LEAK:buried" ] && [ "$lc" = "leak: CLEAN" ]; then
    echo "selftest OK (run hit=$rh miss=$rm; $cv; $lk / $lc)"; return 0
  fi
  echo "selftest FAIL (hit=$rh miss=$rm cell=$cv leakhit=$lk leakclean=$lc)" >&2; return 1
}

case "${1:-}" in
  --run)      shift; run_check "$@";;
  --cell)     shift; cell "$@";;
  --leak)     shift; leak "$@";;
  --selftest) selftest;;
  *) echo "usage: $0 --run|--cell|--leak <checkfile> <files...> | --selftest" >&2; exit 2;;
esac
