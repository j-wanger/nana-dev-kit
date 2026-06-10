#!/usr/bin/env bash
# Phase 86 — build corpus-manifest.md: mechanical enumeration of ALL ceremony
# dispatches in the frozen corpus (pre-registration ## Corpus), incl. zero-catch
# ones. Same session selection as build-cost-table.sh; same dispatch classification
# as extract-costs.py (shared code path, --manifest mode).
set -euo pipefail
cd "$(dirname "$0")"
SDIR="$HOME/.claude/projects/-Users-jwang-nana-dev-kit"
WINDOW_LO="2026-05-31T17:00"
WINDOW_HI="2026-06-10T15:01:28"

SESSIONS=()
for f in "$SDIR"/*.jsonl; do
  first=$(head -5 "$f" | jq -r 'select(.timestamp != null) | .timestamp' 2>/dev/null | head -1)
  [ -n "$first" ] || continue
  [[ "$first" > "$WINDOW_LO" && "$first" < "$WINDOW_HI" ]] || continue
  grep -qm1 'ceremony-lift' "$f" && continue
  SESSIONS+=("$f")
done
[ "${#SESSIONS[@]}" -gt 0 ] || { echo "build-corpus-manifest: no corpus sessions"; exit 1; }

TSV=$(python3 ./extract-costs.py --manifest "${SESSIONS[@]}")

{
  echo "# Corpus Manifest — ceremony dispatches, Phases 76–85 (frozen)"
  echo
  echo "Window: first-timestamp in ($WINDOW_LO, $WINDOW_HI); end-commit 5360486;"
  echo "self-feedback exclusion: sessions containing 'ceremony-lift' skipped."
  echo "Sessions: ${#SESSIONS[@]}. Includes zero-catch dispatches (the denominator)."
  echo
  echo "| session | timestamp | label | class |"
  echo "|---|---|---|---|"
  echo "$TSV" | tail -n +2 | awk -F'\t' '{printf "| %s | %s | %s | %s |\n", $1, $2, $3, $4}'
  echo
  total=$(echo "$TSV" | tail -n +2 | awk -F'\t' '$4 != "non-ceremony"' | wc -l | tr -d ' ')
  echo "CEREMONY-DISPATCHES-TOTAL: $total"
} > corpus-manifest.md
echo "build-corpus-manifest: wrote corpus-manifest.md"
