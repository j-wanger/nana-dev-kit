#!/usr/bin/env bash
# Provenance filter for .dev-wiki/enforcement.log (Phase 88 T1).
# Usage: filter-enforcement-log.sh <log-file> <hook-name>
# Emits key=value cells for the named hook ONLY:
#   total, allow, block, unattributed (records lacking a phase field), phase_<N> per phase
# plus one `BLOCK <ts> <phase|NOPHASE> <reason>` line per block record, for downstream
# block→follow-through pairing against session transcripts / memory.db write times.
# The log schema records hook DECISIONS only — this filter attributes provenance; it cannot
# observe agent follow-through (that pairing is the snapshot artifact's job, with the
# pre-stated `undecidable-on-this-evidence` fallback).
set -euo pipefail

LOG="${1:?usage: filter-enforcement-log.sh <log-file> <hook-name>}"
HOOK="${2:?usage: filter-enforcement-log.sh <log-file> <hook-name>}"
[ -f "$LOG" ] || { echo "ERROR: log not found: $LOG" >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq required" >&2; exit 1; }

jq -r --arg h "$HOOK" '
  select(.hook == $h) |
  [(.ts // "NOTS"), (.phase // "NOPHASE"), .action, (.reason // "-")] | @tsv
' "$LOG" | awk -F'\t' '
  { total++; act[$3]++
    if ($2 == "NOPHASE") unattr++; else phase[$2]++
    if ($3 == "block") blocks[++nb] = "BLOCK " $1 " " $2 " " $4
  }
  END {
    printf "total=%d\n", total
    printf "allow=%d\n", act["allow"] + 0
    printf "block=%d\n", act["block"] + 0
    printf "unattributed=%d\n", unattr + 0
    for (p in phase) printf "phase_%s=%d\n", p, phase[p]
    for (i = 1; i <= nb; i++) print blocks[i]
  }
'
