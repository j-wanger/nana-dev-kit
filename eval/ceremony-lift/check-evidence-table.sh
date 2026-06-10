#!/usr/bin/env bash
# Phase 86 — evidence-table structural check (spec exit criterion 6).
# Row count == manifest ceremony total; anchor clause rides via check-corpus-manifest;
# every outcome-grade row has a re-execution log pointer; every row has a closed-enum
# evidence-class label and a non-empty caveat cell.
set -uo pipefail
cd "$(dirname "$0")"
T=evidence-table.md
FAIL=0
[ -f "$T" ] || { echo "check-evidence-table: $T missing"; exit 1; }

# Anchor + manifest validity ride every evidence check
bash ./check-corpus-manifest.sh >/dev/null || { echo "  FAIL: corpus manifest check failed"; FAIL=1; }
[ "$FAIL" -eq 0 ] && echo "  PASS: corpus manifest valid (anchor count rides)"

EXPECTED=$(grep -E '^CEREMONY-DISPATCHES-TOTAL: ' corpus-manifest.md | grep -oE '[0-9]+')
ACTUAL=$(grep -cE '^\| d[0-9]+ \|' "$T")
if [ "$ACTUAL" = "$EXPECTED" ]; then
  echo "  PASS: row count == manifest ceremony total ($ACTUAL)"
else
  echo "  FAIL: row count expected=$EXPECTED actual=$ACTUAL"; FAIL=1
fi

ENUM='outcome-grade-admitted|rejected-gate-covered|ambiguous-downgrade|consumption-grade-capped|inert|load-bearing|zero-catch'
badclass=$(grep -E '^\| d[0-9]+ \|' "$T" | grep -vcE "\| ($ENUM) \|" || true)
if [ "$badclass" = "0" ]; then
  echo "  PASS: every row carries a closed-enum evidence class"
else
  echo "  FAIL: $badclass rows with class outside the closed enum"; FAIL=1
fi

# outcome-grade rows must carry a re-execution log pointer (cell like reexec-log.md#rX)
badptr=$(grep -E '^\| d[0-9]+ \|' "$T" | grep -E '\| outcome-grade-admitted \|' | grep -vcE '\| re-execution-log\.md#[a-z0-9-]+ \|' || true)
if [ "$badptr" = "0" ]; then
  echo "  PASS: every outcome-grade row has a re-execution log pointer"
else
  echo "  FAIL: $badptr outcome-grade rows without re-execution pointer"; FAIL=1
fi

# every pointed-to anchor exists in the log
if [ -f re-execution-log.md ]; then
  missing=0
  for a in $(grep -E '^\| d[0-9]+ \|' "$T" | grep -oE 're-execution-log\.md#[a-z0-9-]+' | sed 's/.*#//' | sort -u); do
    grep -q "^### $a" re-execution-log.md || { echo "  FAIL: log anchor missing: $a"; missing=1; }
  done
  [ "$missing" = "0" ] && echo "  PASS: all re-execution pointers resolve"
  [ "$missing" = "1" ] && FAIL=1
fi

# caveat cell (last column) non-empty on every row
badcaveat=$(grep -E '^\| d[0-9]+ \|' "$T" | awk -F'|' '{c=$(NF-1); gsub(/ /,"",c); if (c=="") n++} END {print n+0}')
if [ "$badcaveat" = "0" ]; then
  echo "  PASS: every row has a non-empty caveat cell"
else
  echo "  FAIL: $badcaveat rows with empty caveat"; FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then echo "check-evidence-table: ALL PASS"; exit 0; else echo "check-evidence-table: FAILURES"; exit 1; fi
