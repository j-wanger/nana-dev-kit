#!/usr/bin/env bash
# Phase 86 — blind tabulator controls (spec exit criterion 4).
# Five seeds classified by classify-evidence.py WITHOUT access to the answer key;
# this script does the join. Blindness is auditable: the tabulator source must
# contain zero references to the answer-key path.
set -uo pipefail
cd "$(dirname "$0")"
TAB=./classify-evidence.py
KEY=controls/answer-key.json
FAIL=0

[ -f "$TAB" ] || { echo "tabulator controls: $TAB missing (RED)"; exit 1; }
[ -f "$KEY" ] || { echo "tabulator controls: answer key missing"; exit 1; }

# Blindness audit: tabulator never reads the key
if grep -q 'answer-key' "$TAB"; then
  echo "  FAIL: tabulator references answer-key (blindness violated)"; FAIL=1
else
  echo "  PASS: blindness (no answer-key reference in tabulator source)"
fi

for seed in controls/seed-*.json; do
  [ -f "$seed" ] || continue
  id=$(jq -r '.id' "$seed")
  expected=$(jq -r --arg id "$id" '.[$id]' "$KEY")
  actual=$(python3 "$TAB" "$seed" 2>/dev/null | tail -1)
  if [ "$actual" = "$expected" ]; then
    echo "  PASS: $id -> $actual"
  else
    echo "  FAIL: $id expected=$expected actual=$actual"; FAIL=1
  fi
done

if [ "$FAIL" -eq 0 ]; then echo "tabulator controls: ALL PASS"; exit 0; else echo "tabulator controls: FAILURES"; exit 1; fi
