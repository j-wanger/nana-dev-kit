#!/usr/bin/env bash
# check-claim-ceiling.sh — Phase 87. Default mode: every given summary artifact must
# embed the verbatim claim-ceiling sentence and contain NO verdict-minting language
# (addendum-pinned patterns, applied after removing exact ceiling-sentence lines).
# --verdict-block <file>: additionally require a closed-vocabulary disposition line.
# Exit 0 iff all files clean.
set -uo pipefail

CEIL='may never mint keep or cut'
VOCAB='confirm-trim-trial|not-confirmed|undecidable|instrument-dead|void'
fail=0
mode=default
if [ "${1:-}" = "--verdict-block" ]; then mode=verdict-block; shift; fi
[ $# -ge 1 ] || { echo "usage: check-claim-ceiling.sh [--verdict-block] <file...>"; exit 2; }

for f in "$@"; do
  [ -f "$f" ] || { echo "FAIL: $f missing"; fail=1; continue; }
  if grep -qF "$CEIL" "$f"; then
    echo "PASS: $f embeds the ceiling sentence"
  else
    echo "FAIL: $f missing the verbatim ceiling sentence"; fail=1
  fi
  # Remove exact ceiling-sentence lines, then apply violation patterns (addendum-pinned).
  stripped="$(grep -vF "$CEIL" "$f" || true)"
  for pat in 'verdict[: ]+ *(keep|cut)\b' 'mint(s|ed)? +(a +)?(keep|cut)\b' '(ceremony|minimal|spec[- ]generation) *(arm)? *(wins|won|beats?|beat|loses?|lost)\b'; do
    if printf '%s\n' "$stripped" | grep -qiE "$pat"; then
      echo "FAIL: $f matches violation pattern: $pat"; fail=1
    fi
  done
  if [ "$mode" = "verdict-block" ]; then
    if grep -qE "^disposition: ($VOCAB)$" "$f"; then
      echo "PASS: $f disposition line is closed-vocabulary"
    else
      echo "FAIL: $f disposition line missing or out of closed vocabulary ($VOCAB)"; fail=1
    fi
  fi
done
[ "$fail" -eq 0 ] && echo "CLAIM-CEILING: PASS" || echo "CLAIM-CEILING: FAIL"
exit "$fail"
