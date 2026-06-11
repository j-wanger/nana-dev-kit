#!/usr/bin/env bash
# check-ship-table.sh — Phase 87. Asserts the ship table has both arm rows with all 7
# cells non-empty (DNF is a legal cell value), every row carries a cmdlog pointer, and
# the blinded tie-break section is present IFF both arms' gate cells read PASS.
# Exit 0 iff well-formed.
set -uo pipefail
F="${1:-$(dirname "${BASH_SOURCE[0]}")/ship-table.md}"
fail=0
[ -f "$F" ] || { echo "FAIL: $F missing"; exit 1; }
[ -s "$F" ] || { echo "FAIL: $F empty (must not vacuous-pass)"; exit 1; }

gates=""
for arm in arm-b arm-a; do
  row="$(grep -E "^\| *$arm *\|" "$F" | head -1)"
  if [ -z "$row" ]; then echo "FAIL: row for $arm missing"; fail=1; continue; fi
  # 7 columns => 8 '|' separators; empty cell = '||' or '| |'
  ncells=$(printf '%s' "$row" | awk -F'|' '{print NF-2}')
  if [ "$ncells" -ne 7 ]; then echo "FAIL: $arm row has $ncells cells (want 7)"; fail=1; fi
  if printf '%s' "$row" | grep -qE '\|\s*\|'; then
    echo "FAIL: $arm row has an empty cell"; fail=1
  else
    echo "PASS: $arm row complete"
  fi
  # Phase-88 tightening (routed): cmdlog pointer is UNCONDITIONAL — a DNF row needs its
  # cmdlog too (was `cmdlog|DNF`: any DNF row passed pointer-less). Phase-87's table
  # already satisfies this (both rows carry cmdlogs post-c4bd9ff).
  printf '%s' "$row" | grep -qE 'cmdlog' || { echo "FAIL: $arm row lacks a cmdlog pointer"; fail=1; }
  gate=$(printf '%s' "$row" | awk -F'|' '{gsub(/ /,"",$6); print $6}')
  gates="$gates $gate"
done

if [ "$gates" = " PASS PASS" ]; then
  if grep -q '^## Tie-break' "$F"; then echo "PASS: tie-break section present (both arms pass)";
  else echo "FAIL: both arms pass but tie-break section missing"; fail=1; fi
else
  if grep -q '^## Tie-break' "$F"; then echo "FAIL: tie-break section present but arms did not both pass"; fail=1;
  else echo "PASS: no tie-break section (arms did not both pass)"; fi
fi
[ "$fail" -eq 0 ] && echo "SHIP-TABLE: PASS" || echo "SHIP-TABLE: FAIL"
exit "$fail"
