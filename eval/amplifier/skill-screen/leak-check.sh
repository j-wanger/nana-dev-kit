#!/usr/bin/env bash
# leak-check.sh — assert every OFF recoverable-corpus R_A is leak-clean (skill-crystallization screen, Phase 78).
#
# Ported from retention-screen/leak-check.sh. Two deterministic guards (NO model judge):
#   (a) GLOBAL vocab (leak-vocab.txt) — cross-candidate smells meaning HIDDEN-TEST content leaked into a
#       corpus (e.g. "def test_", "assert ", "pytest", "@pytest"). R_A must read like interface + call
#       sites + task, NEVER like the test file that is supposed to be the out-of-band oracle.
#   (b) PER-CANDIDATE offleak (corpus/<candidate>.offleak) — the ANSWER tokens the spec-implied tests
#       assert ∪ the tests' fixture literals. If R_A states these, OFF can copy-pass and BOTH a false
#       TERMINATE (answer handed over) and a false HAS-HEADROOM are possible. One token per line;
#       blanks / #-comments ignored.
#
# Only *-corpus.txt files (the R_A given to OFF) are scanned. Exits 0 iff every corpus is clean.
#   leak-check.sh            → scans this screen's corpus/  (default; used at T2/T4)
#   leak-check.sh --selftest → plants clean + global-leak + answer-leak corpora, asserts detection both ways
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_VOCAB="$DIR/leak-vocab.txt"
[ -f "$GLOBAL_VOCAB" ] || { echo "leak-check: leak-vocab.txt absent" >&2; exit 1; }

# Scan one corpus against the global vocab + its per-candidate offleak (in <corpusdir>). <corpusdir>
# lets --selftest point at a planted tmp tree.
scan_corpus() {  # <corpus-file> <corpusdir>
  local p="$1" corpusdir="$2" rc=0 term base item itemleak
  base="$(basename "$p")"; item="${base%-corpus.txt}"
  while IFS= read -r term; do
    case "${term:-}" in ''|\#*) continue;; esac
    if grep -iqF -- "$term" "$p"; then
      echo "LEAK(global): $base contains test-content smell '$term'" >&2; rc=1
    fi
  done < "$GLOBAL_VOCAB"
  itemleak="$corpusdir/$item.offleak"
  if [ -f "$itemleak" ]; then
    while IFS= read -r term; do
      case "${term:-}" in ''|\#*) continue;; esac
      if grep -iqF -- "$term" "$p"; then
        echo "LEAK(answer): $base states the answer token '$term' the spec-implied tests check" >&2; rc=1
      fi
    done < "$itemleak"
  fi
  return "$rc"
}

scan_tree() {  # <corpusdir>
  local cdir="$1" rc=0 n=0 p
  [ -d "$cdir" ] || { echo "leak-check: no corpus dir $cdir" >&2; return 1; }
  for p in "$cdir"/*-corpus.txt; do
    [ -e "$p" ] || continue
    n=$((n+1))
    scan_corpus "$p" "$cdir" || rc=1
  done
  [ "$n" -gt 0 ] || { echo "leak-check: no *-corpus.txt in $cdir" >&2; return 1; }
  [ "$rc" -eq 0 ] && echo "leak-check: OK ($n corpora clean)"
  return "$rc"
}

selftest() {
  local t fail=0
  t="$(mktemp -d)"; trap 'rm -rf "$t"' RETURN
  mkdir -p "$t/c.clean" "$t/c.g" "$t/c.a"
  # clean corpus: interface + call site + task, states no answer, carries no test content
  printf 'def is_member(ticker, as_of_date): ...  # call: universe = [t for t in tickers if is_member(t, d)]\nTask: implement the membership predicate.\n' > "$t/c.clean/cand-corpus.txt"
  # global-leak corpus: smuggles hidden TEST content
  printf 'def test_membership_excludes_future():\n    assert not is_member("FOO", date(2010,1,1))\n' > "$t/c.g/cand-corpus.txt"
  # answer-leak corpus: states the per-candidate answer token
  printf 'Implement it by filtering strictly-before the added_date boundary.\n' > "$t/c.a/cand-corpus.txt"
  printf 'strictly-before the added_date\n' > "$t/c.a/cand.offleak"

  if scan_tree "$t/c.clean" >/dev/null 2>&1; then echo "ok: clean corpus passes"; else echo "FAIL: clean corpus flagged"; fail=1; fi
  if scan_tree "$t/c.g" >/dev/null 2>&1; then echo "FAIL: global (test-content) leak NOT caught"; fail=1; else echo "ok: global leak caught"; fi
  if scan_tree "$t/c.a" >/dev/null 2>&1; then echo "FAIL: answer leak NOT caught"; fail=1; else echo "ok: answer leak caught"; fi
  [ "$fail" -eq 0 ] && { echo "LEAK-SELFTEST: PASS"; return 0; } || { echo "LEAK-SELFTEST: FAIL"; return 1; }
}

case "${1:-}" in
  --selftest) selftest;;
  "")         scan_tree "$DIR/corpus";;
  *)          echo "usage: leak-check.sh [--selftest]" >&2; exit 2;;
esac
