#!/usr/bin/env bash
# detect-surfacing.sh — Phase 87 positive-control surfacing detector (addendum-pinned).
# Usage: detect-surfacing.sh <settings.json> <settings.local.json> <script-basename>
# SURFACED (exit 0) iff the script's basename appears EXACTLY ONCE across the union of
# hook command strings in both files and the registration uses the nested schema.
# NOT-SURFACED (exit 1) otherwise (absent, duplicated, or split across files).
# Deterministic: jq extraction only, no prose judgment.
set -uo pipefail
[ $# -eq 3 ] || { echo "usage: detect-surfacing.sh <settings.json> <settings.local.json> <basename>"; exit 2; }
S1="$1"; S2="$2"; BASE="$3"

count_in() { # <file>
  local f="$1"
  [ -f "$f" ] || { echo 0; return; }
  jq -r '[.hooks // {} | to_entries[] | .value[]? | .hooks[]? | .command] | .[]' "$f" 2>/dev/null \
    | awk -v b="$BASE" 'BEGIN{n=0} { cnt=split($0, parts, "/"); last=parts[cnt]; sub(/[" ].*$/, "", last); if (last==b) n++ } END{print n}'
}

n1=$(count_in "$S1"); n2=$(count_in "$S2"); total=$((n1 + n2))
echo "basename=$BASE settings.json=$n1 settings.local.json=$n2 total=$total"
if [ "$total" -eq 1 ]; then
  echo "DETECTOR: SURFACED (exactly-once registration)"
  exit 0
else
  echo "DETECTOR: NOT-SURFACED (count=$total; convention requires exactly once across the union)"
  exit 1
fi
