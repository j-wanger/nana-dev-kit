#!/usr/bin/env bash
# check-cost-table.sh — Phase 87. Asserts the per-arm cost table has both arm rows with
# all 5 cells non-empty (NOT-EXTRACTABLE is a legal token-cell value per the A3 fallback)
# and an interaction-log pointer per row. Exit 0 iff well-formed.
set -uo pipefail
F="${1:-$(dirname "${BASH_SOURCE[0]}")/cost-table.md}"
fail=0
[ -f "$F" ] || { echo "FAIL: $F missing"; exit 1; }
for arm in arm-b arm-a; do
  row="$(grep -E "^\| *$arm *\|" "$F" | head -1)"
  if [ -z "$row" ]; then echo "FAIL: row for $arm missing"; fail=1; continue; fi
  ncells=$(printf '%s' "$row" | awk -F'|' '{print NF-2}')
  [ "$ncells" -ne 6 ] && { echo "FAIL: $arm row has $ncells cells (want 6)"; fail=1; }
  if printf '%s' "$row" | grep -qE '\|\s*\|'; then echo "FAIL: $arm row has an empty cell"; fail=1; else echo "PASS: $arm row complete"; fi
  printf '%s' "$row" | grep -q 'interactions' || { echo "FAIL: $arm row lacks an interaction-log pointer"; fail=1; }
done
[ "$fail" -eq 0 ] && echo "COST-TABLE: PASS" || echo "COST-TABLE: FAIL"
exit "$fail"
