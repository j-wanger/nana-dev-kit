#!/usr/bin/env bash
# assert-off-on-isolation.sh — assert each ON prompt = its OFF prompt + an appended block, byte-for-byte.
#
# The differential OFF/ON verdict must measure ONLY the appended [HARNESS STATE] block. If ON differs
# from OFF anywhere in the OFF region, the contrast is confounded (the eval/comparison A-vs-C scar:
# conditions differing in more than the one intended variable). This asserts, for every item, that the
# OFF prompt's bytes are an EXACT PREFIX of the ON prompt, and that ON is strictly longer (it actually
# appended a block). Deterministic (no model judge). Exits 0 iff every OFF/ON pair is isolated.
#
#   assert-off-on-isolation.sh            → checks this screen's prompts/  (default; used at T2/T5)
#   assert-off-on-isolation.sh --selftest → plants an isolated pair + a tampered pair, asserts detection
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

assert_tree() {  # <promptsdir> → rc (0 all isolated)
  local pdir="$1" rc=0 n=0 off base item on offlen
  [ -d "$pdir" ] || { echo "isolation: no prompts dir $pdir" >&2; return 1; }
  for off in "$pdir"/*-off.txt; do
    [ -e "$off" ] || continue
    base="$(basename "$off")"; item="${base%-off.txt}"; on="$pdir/$item-on.txt"
    if [ ! -f "$on" ]; then echo "isolation: $item missing ON prompt ($item-on.txt)" >&2; rc=1; continue; fi
    n=$((n+1)); offlen="$(wc -c < "$off")"
    if ! cmp -s <(head -c "$offlen" "$on") "$off"; then
      echo "isolation: FAIL $item — ON is not OFF + appended block (the OFF region differs)" >&2; rc=1; continue
    fi
    if [ "$(wc -c < "$on")" -le "$offlen" ]; then
      echo "isolation: FAIL $item — ON not longer than OFF (no appended [HARNESS STATE] block)" >&2; rc=1
    fi
  done
  [ "$n" -gt 0 ] || { echo "isolation: no *-off.txt prompts in $pdir" >&2; return 1; }
  [ "$rc" -eq 0 ] && echo "isolation: OK ($n OFF/ON pairs isolated)"
  return "$rc"
}

selftest() {
  local t fail=0
  t="$(mktemp -d)"; trap 'rm -rf "$t"' RETURN
  # isolated pair: ON = OFF + appended block (must PASS)
  mkdir -p "$t/good"
  printf 'Continue the task below.\n\nThe customer requests a wire transfer.\n' > "$t/good/iso-off.txt"
  cat "$t/good/iso-off.txt" > "$t/good/iso-on.txt"
  printf '\n[HARNESS STATE]\nactive decision: threshold is 8000 EUR, not 10000. Honor it.\n[/HARNESS STATE]\n' >> "$t/good/iso-on.txt"
  if assert_tree "$t/good" >/dev/null 2>&1; then echo "ok: isolated pair passes"; else echo "FAIL: isolated pair flagged"; fail=1; fi
  # tampered pair: ON edits the OFF region (must FAIL)
  mkdir -p "$t/bad"
  printf 'Continue the task below.\n\nThe customer requests a wire transfer.\n' > "$t/bad/tamper-off.txt"
  printf 'Continue the task below.\n\nThe customer requests a CASH withdrawal.\n[HARNESS STATE] x [/HARNESS STATE]\n' > "$t/bad/tamper-on.txt"
  if assert_tree "$t/bad" >/dev/null 2>&1; then echo "FAIL: tampered pair NOT caught"; fail=1; else echo "ok: tampered pair caught"; fi
  # no-append pair: ON identical to OFF (must FAIL — no block appended)
  mkdir -p "$t/noapp"
  printf 'Continue the task below.\n' > "$t/noapp/n-off.txt"
  cp "$t/noapp/n-off.txt" "$t/noapp/n-on.txt"
  if assert_tree "$t/noapp" >/dev/null 2>&1; then echo "FAIL: no-append pair NOT caught"; fail=1; else echo "ok: no-append pair caught"; fi
  [ "$fail" -eq 0 ] && { echo "ISO-SELFTEST: PASS"; return 0; } || { echo "ISO-SELFTEST: FAIL"; return 1; }
}

case "${1:-}" in
  --selftest) selftest;;
  "")         assert_tree "$DIR/prompts";;
  *)          echo "usage: assert-off-on-isolation.sh [--selftest]" >&2; exit 2;;
esac
