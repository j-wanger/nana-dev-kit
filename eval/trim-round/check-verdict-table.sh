#!/usr/bin/env bash
# Phase 88 verdict-table checker. Usage: check-verdict-table.sh [table.md]
# Defaults to the live table. Asserts:
#   - header carries `phase-base: <sha>` and the Phase-87 verdicts-stand pin
#   - every data row uses the closed enum for its class:
#       trim     -> trim-trial | no-trim
#       leftover -> keep | cut | harden | disable-at-boundary
#       checker  -> tightened | instrument-dead
#   - status -> proposed | approved | executed | dropped
#   - zero-class -> couldnt-fire | didnt-fire | n/a
#   - trim rows: revert-trigger, window, blockers-ref all non-empty and not n/a/-
#   - rows with status=executed have eval/trim-round/rehearsals/<id>.log
#   - at least one data row exists (empty table must not vacuous-pass)
# Controls-first: validated against checker-fixtures/{clean-table,bad-row-*}.md.
set -uo pipefail
cd "$(dirname "$0")"

TABLE="${1:-verdict-table.md}"
[ -f "$TABLE" ] || { echo "FAIL: table not found: $TABLE"; exit 1; }

grep -qE '^phase-base: [0-9a-f]{7,40}$' "$TABLE" || { echo "FAIL: missing phase-base SHA header"; exit 1; }
grep -q 'Phase-87 verdicts stand' "$TABLE" || { echo "FAIL: missing Phase-87 verdicts-stand pin"; exit 1; }

# State-flag awk (not range syntax): rows start after the |---| separator line.
awk -F'|' -v rehearsals_dir="rehearsals" '
  function trimcell(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  /^\|[ \t]*---/ { in_rows = 1; next }
  in_rows && /^\|/ {
    id = trimcell($2); class = trimcell($3); verdict = trimcell($4); status = trimcell($5)
    zc = trimcell($6); rt = trimcell($7); win = trimcell($8); bref = trimcell($9)
    nrows++
    ok = 0
    if (class == "trim"     && (verdict == "trim-trial" || verdict == "no-trim")) ok = 1
    if (class == "leftover" && (verdict == "keep" || verdict == "cut" || verdict == "harden" || verdict == "disable-at-boundary")) ok = 1
    if (class == "checker"  && (verdict == "tightened" || verdict == "instrument-dead")) ok = 1
    if (!ok) { printf "FAIL: row %s: verdict %s invalid for class %s\n", id, verdict, class; v = 1 }
    if (status != "proposed" && status != "approved" && status != "executed" && status != "dropped") {
      printf "FAIL: row %s: status %s invalid\n", id, status; v = 1 }
    if (zc != "couldnt-fire" && zc != "didnt-fire" && zc != "n/a") {
      printf "FAIL: row %s: zero-class %s invalid\n", id, zc; v = 1 }
    if (class == "trim" && verdict == "trim-trial") {
      if (rt == "" || rt == "n/a" || rt == "-")  { printf "FAIL: trim row %s: empty revert-trigger\n", id; v = 1 }
      if (win == "" || win == "n/a" || win == "-") { printf "FAIL: trim row %s: empty observation window\n", id; v = 1 }
      if (bref == "" || bref == "n/a" || bref == "-") { printf "FAIL: trim row %s: empty blockers-ref\n", id; v = 1 }
    }
    if (status == "executed") {
      logf = rehearsals_dir "/" id ".log"
      if (system("test -f " logf) != 0) { printf "FAIL: executed row %s: missing %s\n", id, logf; v = 1 }
    }
  }
  END {
    if (nrows < 1) { print "FAIL: no data rows (empty table must not pass)"; v = 1 }
    exit v
  }
' "$TABLE" || exit 1

echo "PASS: verdict table well-formed ($TABLE)"
