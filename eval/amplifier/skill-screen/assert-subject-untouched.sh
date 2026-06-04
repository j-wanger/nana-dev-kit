#!/usr/bin/env bash
# assert-subject-untouched.sh — read-only guard for the skill-crystallization screen (Phase 78).
#
# The candidate SUBJECTS are FIXED: the nana-dev-kit source artifact (scripts/check-install-drift.sh +
# its tests) and the edge-screener domain artifact (universe/membership.py + its tests). The screen
# only ever READS them — to copy frozen R_A/T_A fixtures once, and OFF re-derives from R_A text alone.
# This proves they were not mutated: hash every path listed in subjects.txt (one path per line; absolute,
# or relative to the kit root passed as $NANA_KIT_ROOT/default two levels up), snapshot before a run,
# re-verify after; any drift fails CLOSED (mutating a measurement subject contaminates the result).
#
#   assert-subject-untouched.sh --snapshot <snapfile>   # capture baseline from subjects.txt
#   assert-subject-untouched.sh --verify   <snapfile>   # exits 0 iff byte-identical, 1 on drift
#   assert-subject-untouched.sh --selftest              # proves it PASSES unchanged + DETECTS a mutation
#   assert-subject-untouched.sh                         # --verify subjects.snapshot if present, else --selftest
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Deterministic manifest: sorted "<sha256>  <path>" over every existing file in a subjects list.
# A listed-but-missing path is recorded explicitly (its disappearance is itself drift).
snapshot_from() {  # <subjects-list> <out>
  local list="$1" out="$2" path
  : > "$out"
  while IFS= read -r path; do
    case "${path:-}" in ''|\#*) continue;; esac
    if [ -f "$path" ]; then
      printf '%s  %s\n' "$(shasum -a 256 "$path" | awk '{print $1}')" "$path"
    else
      printf 'MISSING  %s\n' "$path"
    fi
  done < "$list" | LC_ALL=C sort >> "$out"
}

verify() {  # <snapfile> <subjects-list>
  local snap="$1" list="$2" tmp
  [ -f "$snap" ] || { echo "assert-untouched: baseline snapshot missing: $snap" >&2; return 2; }
  [ -f "$list" ] || { echo "assert-untouched: subjects list missing: $list" >&2; return 2; }
  tmp="$(mktemp)"; snapshot_from "$list" "$tmp"
  if diff -q "$snap" "$tmp" >/dev/null 2>&1; then
    rm -f "$tmp"; echo "untouched: OK"; return 0
  else
    echo "DRIFT — a measurement subject was mutated during the run:" >&2
    diff "$snap" "$tmp" >&2 || true
    rm -f "$tmp"; return 1
  fi
}

selftest() {
  local t fail=0 list snap
  t="$(mktemp -d)"; trap 'rm -rf "$t"' RETURN
  printf 'real subject body\n' > "$t/subjectA"
  printf 'another subject\n'    > "$t/subjectB"
  list="$t/subjects.txt"; snap="$t/snap"
  printf '%s\n%s\n' "$t/subjectA" "$t/subjectB" > "$list"

  snapshot_from "$list" "$snap"
  if verify "$snap" "$list" >/dev/null 2>&1; then echo "ok: unchanged → untouched"; else echo "FAIL: unchanged flagged drift"; fail=1; fi
  # mutate a subject → must be DETECTED
  printf 'TAMPERED\n' >> "$t/subjectA"
  if verify "$snap" "$list" >/dev/null 2>&1; then echo "FAIL: mutation NOT detected"; fail=1; else echo "ok: mutation → DRIFT detected"; fi
  # restore → untouched again
  printf 'real subject body\n' > "$t/subjectA"
  if verify "$snap" "$list" >/dev/null 2>&1; then echo "ok: restored → untouched"; else echo "FAIL: restore not clean"; fail=1; fi
  # delete a subject → must be DETECTED (disappearance is drift)
  rm -f "$t/subjectB"
  if verify "$snap" "$list" >/dev/null 2>&1; then echo "FAIL: deletion NOT detected"; fail=1; else echo "ok: deletion → DRIFT detected"; fi
  [ "$fail" -eq 0 ] && { echo "SELFTEST: PASS"; return 0; } || { echo "SELFTEST: FAIL"; return 1; }
}

LIST="$DIR/subjects.txt"
case "${1:-}" in
  --snapshot) shift; [ $# -eq 1 ] || { echo "usage: --snapshot <snapfile>" >&2; exit 2; }; snapshot_from "$LIST" "$1"; echo "snapshot: $1";;
  --verify)   shift; [ $# -eq 1 ] || { echo "usage: --verify <snapfile>" >&2; exit 2; }; verify "$1" "$LIST";;
  --selftest) selftest;;
  "")         if [ -f "$DIR/subjects.snapshot" ]; then verify "$DIR/subjects.snapshot" "$LIST"; else selftest; fi;;
  *) echo "usage: assert-subject-untouched.sh --snapshot|--verify|--selftest ..." >&2; exit 2;;
esac
