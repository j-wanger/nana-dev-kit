#!/usr/bin/env bash
# scripts/signal-richness-probe.sh — Phase 66
#
# Read-only deterministic gate: "is the enforcement-firing scorer buildable yet?"
#
# It classifies every record in an enforcement.log and computes the signal predicate over
# schema_version-bearing ("new-format") records ONLY, after full-{hook,ts,action,reason}-tuple
# dedup. The four verdicts are distinct on purpose:
#   NO-DATA       — log absent or empty (not the same as "insufficient signal")
#   CORRUPT       — >50% of non-empty lines fail JSON parse
#   SCOREABLE     — >=2 distinct hooks fired AND >=1 action-changing `block` firing
#   NOT-SCOREABLE — parseable, but below the predicate
#
# This IS the committed re-checkable trigger for the parked scorer (see
# [[park-enforcement-scorer-signal-insufficient]]): green (SCOREABLE) ⇒ revisit the scorer, AND
# only after the two structural blockers are resolved (real consuming-project provenance + a record
# schema that captures the agent's subsequent action). The probe NEVER writes/truncates the log.
#
# Usage: signal-richness-probe.sh [logpath]   (default: .dev-wiki/enforcement.log)

set -euo pipefail

LOG="${1:-.dev-wiki/enforcement.log}"

command -v jq >/dev/null 2>&1 || { echo "[signal-richness-probe] jq is required (brew install jq / apt-get install jq)" >&2; exit 2; }

report() {  # report <total> <new> <newd> <dups> <legacy> <debrief> <malformed> <hooks> <blocks> <verdict> <reason>
  local total="$1" new="$2" newd="$3" dups="$4" legacy="$5" debrief="$6" malformed="$7" hooks="$8" blocks="$9" verdict="${10}" reason="${11}"
  local offroster=$(( total - new - legacy - debrief - malformed ))
  [ "$offroster" -lt 0 ] && offroster=0
  # Emit the whole report in ONE write so a `| grep -q ...` consumer that closes the pipe early
  # cannot SIGPIPE the probe mid-stream (which would surface as exit 141 under `set -o pipefail`).
  # Build the full string first, then a single printf — one write(2), no per-line race.
  local out
  out=$(printf '%s\n' \
    "signal-richness probe: $LOG" \
    "  total non-empty lines:            $total" \
    "  new-format (schema_version):      $new  (deduped: $newd, duplicate tuples: $dups)" \
    "  legacy-enforce (no schema):       $legacy" \
    "  debrief-completion (off-roster):  $debrief" \
    "  malformed/other off-roster:       $(( malformed + offroster ))  (unparseable: $malformed)" \
    "  --- signal (new-format, deduped) ---" \
    "  distinct hooks fired:             $hooks" \
    "  block (action-changing) firings:  $blocks" \
    "  predicate: SCOREABLE iff distinct hooks >= 2 AND block firings >= 1" \
    "METRICS total=$total new=$new new_deduped=$newd duplicates=$dups legacy=$legacy debrief=$debrief malformed=$malformed hooks=$hooks blocks=$blocks" \
    "VERDICT: $verdict" \
    "  reason: $reason")
  printf '%s\n' "$out"
}

# NO-DATA: absent log.
if [ ! -f "$LOG" ]; then
  report 0 0 0 0 0 0 0 0 0 "NO-DATA" "log not found at '$LOG'"
  exit 0
fi

NONEMPTY=$(grep -cve '^[[:space:]]*$' "$LOG" 2>/dev/null || true)
NONEMPTY=${NONEMPTY:-0}
if [ "$NONEMPTY" -eq 0 ]; then
  report 0 0 0 0 0 0 0 0 0 "NO-DATA" "log is empty"
  exit 0
fi

# Classify each non-empty line: parse as JSON (tag failures), then aggregate in a single jq slurp.
# new-format = schema_version present; debrief = {event:...}; legacy = .hook present, no schema_version;
# malformed = JSON parse failed. Dedup new-format on the full {hook,ts,action,reason} tuple.
METRICS_LINE=$(
  grep -ve '^[[:space:]]*$' "$LOG" \
    | jq -Rc 'try (fromjson | if type=="object" then . else {"__malformed__":true} end) catch {"__malformed__":true}' \
    | jq -s -r '
        (map(select(.__malformed__ == true)) | length) as $malformed
        | (map(select((.__malformed__ != true) and (.schema_version != null)))) as $new
        | ($new | map({hook,ts,action,reason}) | unique) as $newd
        | (map(select((.__malformed__ != true) and (.schema_version == null) and (.event != null))) | length) as $debrief
        | (map(select((.__malformed__ != true) and (.schema_version == null) and (.event == null) and (.hook != null))) | length) as $legacy
        | length as $total
        | ($newd | map(.hook) | map(select(. != null)) | unique | length) as $hooks
        | ($newd | map(select(.action == "block")) | length) as $blocks
        | "\($total) \($malformed) \($new|length) \($newd|length) \($debrief) \($legacy) \($hooks) \($blocks) \(($new|length)-($newd|length))"
      '
)
read -r TOTAL MALFORMED NEW NEWD DEBRIEF LEGACY HOOKS BLOCKS DUPS <<<"$METRICS_LINE"

# Verdict precedence: CORRUPT (majority unparseable) → predicate.
if [ $(( MALFORMED * 2 )) -gt "$TOTAL" ]; then
  report "$TOTAL" "$NEW" "$NEWD" "$DUPS" "$LEGACY" "$DEBRIEF" "$MALFORMED" "$HOOKS" "$BLOCKS" \
    "CORRUPT" "majority of non-empty lines failed JSON parse ($MALFORMED/$TOTAL)"
elif [ "$HOOKS" -ge 2 ] && [ "$BLOCKS" -ge 1 ]; then
  report "$TOTAL" "$NEW" "$NEWD" "$DUPS" "$LEGACY" "$DEBRIEF" "$MALFORMED" "$HOOKS" "$BLOCKS" \
    "SCOREABLE" "$HOOKS distinct hooks and $BLOCKS block firing(s) in new-format records — a with/without action-delta is computable IF provenance is real and the schema captures agent-response"
else
  report "$TOTAL" "$NEW" "$NEWD" "$DUPS" "$LEGACY" "$DEBRIEF" "$MALFORMED" "$HOOKS" "$BLOCKS" \
    "NOT-SCOREABLE" "need >=2 distinct hooks (have $HOOKS) AND >=1 block firing (have $BLOCKS) in new-format records"
fi
exit 0
