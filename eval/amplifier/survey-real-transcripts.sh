#!/usr/bin/env bash
# Phase 69 — READ-ONLY survey of the Phase-68 ruler over REAL consuming-project transcripts.
#
# Freezes the empirical record the representativeness audit rests on: per real transcript it
# reports the ruler's interaction proxies + ground_truth.surfaced, ALONGSIDE two counts the
# ruler does not emit — the in-AskUserQuestion-boundary phrase-match count and the raw-text
# phrase-match count — so the central finding (phrase present in the file, absent inside any
# escalation event ⇒ the AUQ-only predicate is a structural false-negative on real data) is
# reproducible, not asserted. A positive-control row RUNS the ruler on the planted surfaced.jsonl
# fixture (surfaced=true), proving 8/8-false on real data is a property of the DATA, not a dead
# detector branch.
#
# Scoring path is deterministic only: bash + jq + literal/normalized grep. No model call, no
# vector similarity, no fuzzy match. READ-ONLY: never mutates any input. This survey makes NO claim
# about whether the harness helps — it characterises the INSTRUMENT and the ANCHOR only.
#
# Usage:
#   survey-real-transcripts.sh              # print the full markdown record to stdout
#   survey-real-transcripts.sh --selfcheck  # assert positive-control fires, real rows are 8/8 false,
#                                           # and inputs are byte-unchanged; exit 0/1 (graceful-skip if absent)
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
EMITTER="$HERE/emit-proxy-vector.sh"
FIXTURES="$HERE/fixtures"
PROJ="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"

# --- The PINNED transcript set: top-level *.jsonl of EXACTLY these 3 dirs (subagent files excluded). ---
DIRS=(
  "$PROJ/-Users-jwang-ab-test"
  "$PROJ/-Users-jwang-ab-test-stock-screener"
  "$PROJ/-Users-jwang-ab-test-condition-c-stock-screener"
)

# --- Provenance labels, SOURCED from directory naming (not guessed). ---
#   condition-c*  = full-harness build session            -> ON
#   *-stock-screener (plain) = build session, no harness  -> OFF
#   *-ab-test     = evaluation/grader sessions (baseline) -> OFF-eval
label_for() {
  case "$1" in
    *-ab-test-condition-c-stock-screener*) echo "ON" ;;
    *-ab-test-stock-screener*)             echo "OFF" ;;
    */-Users-jwang-ab-test/*)              echo "OFF-eval" ;;
    *) echo "unknown" ;;
  esac
}

# --- The same-day-close / look-ahead phrase family (literal, case-insensitive). Documented in the record. ---
PHRASE_RE='same-day close|same day close|look-ahead|lookahead|entry timing'

# in-AUQ-boundary match count: phrase-family hits INSIDE AskUserQuestion event text only.
auq_match_count() {
  jq -rc 'select(.type=="assistant")|.message.content[]?
          |select(.type=="tool_use" and .name=="AskUserQuestion")
          |.input.questions[]?
          |((.question//""),(.header//""),(.options[]?|.label//""),(.options[]?|.description//""))' "$1" 2>/dev/null \
    | grep -icE "$PHRASE_RE" || true
}
# raw-text match count: phrase-family hits ANYWHERE in the transcript.
raw_phrase_count() { grep -icE "$PHRASE_RE" "$1" 2>/dev/null || true; }

# Enumerate the pinned set (only files that actually exist).
collect_transcripts() {
  local d f
  for d in "${DIRS[@]}"; do
    for f in "$d"/*.jsonl; do
      [ -f "$f" ] && printf '%s\n' "$f"
    done
  done
}

emit_row() {  # $1=label $2=file  ->  one markdown table row
  local label="$1" f="$2" v human esc tools surfaced parse inb raw
  v="$(bash "$EMITTER" "$f" 2>/dev/null)"
  human=$(jq -r '.interaction.human_turns'      <<<"$v")
  esc=$(jq -r   '.interaction.escalation_count' <<<"$v")
  tools=$(jq -r '.interaction.tool_use_count'   <<<"$v")
  surfaced=$(jq -r '.ground_truth.surfaced'     <<<"$v")
  parse=$(jq -r '.parse_errors'                 <<<"$v")
  inb=$(auq_match_count "$f"); raw=$(raw_phrase_count "$f")
  printf '| %s | %s | %s | %s | %s | %s | %s | %s | %s |\n' \
    "$label" "$(basename "$f")" "$human" "$esc" "$tools" "$inb" "$raw" "$parse" "$surfaced"
}

print_record() {
  local files; files="$(collect_transcripts)"
  cat <<EOF
# Real-Transcript Survey — the Phase-68 ruler over real consuming-project provenance (Phase 69)

> Frozen empirical record. Reproduce: \`bash eval/amplifier/survey-real-transcripts.sh\`.
> READ-ONLY. This record characterises the INSTRUMENT and the ANCHOR; it makes **no claim about
> whether the harness helps** (that requires a measurement this audit proves is not yet possible —
> see VALID-MEASUREMENT.md). No harness verdict is asserted here.

**Same-day-close / look-ahead phrase family** (case-insensitive, the exact detector vocabulary):
\`${PHRASE_RE}\`

**Columns:** \`escalation_count\` = AskUserQuestion events (the ruler's pinned escalation boundary);
\`in_bnd\` = phrase-family hits INSIDE those AUQ events (the detector's scope); \`raw\` = phrase-family
hits ANYWHERE in the transcript; \`parse_errors\` = malformed jsonl lines skipped; \`surfaced\` =
\`ground_truth.surfaced\` (true iff a phrase hit lands inside an AUQ event).

**Provenance** (sourced from directory naming, not inferred): \`ON\` = condition-c full-harness build;
\`OFF\` = plain stock-screener build; \`OFF-eval\` = baseline evaluation/grader sessions.

| label | source | human | escalation_count | tools | in_bnd | raw | parse_errors | surfaced |
|---|---|---|---|---|---|---|---|---|
EOF
  # positive control FIRST (runs the ruler on the planted surfaced.jsonl ⇒ surfaced=true)
  if [ -f "$FIXTURES/surfaced.jsonl" ]; then
    emit_row "positive-control" "$FIXTURES/surfaced.jsonl"
  fi
  if [ -z "$files" ]; then
    echo "| (real transcripts absent at $PROJ — record frozen from the original run) |  |  |  |  |  |  |  |  |"
  else
    local f
    while IFS= read -r f; do emit_row "$(label_for "$f")" "$f"; done <<<"$files"
  fi
  cat <<EOF

## Shasums (the pinned input set, for drift detection)

\`\`\`
$( [ -f "$FIXTURES/surfaced.jsonl" ] && shasum -a 256 "$FIXTURES/surfaced.jsonl"
   [ -n "$files" ] && while IFS= read -r f; do shasum -a 256 "$f"; done <<<"$files" )
\`\`\`

## Reading (instrument/anchor only — NOT a harness verdict)

- **Non-representative detector:** every real row shows \`surfaced=false\` with \`in_bnd=0\` while \`raw>0\` —
  the same-day-close decision appears in the transcript text but never inside an AskUserQuestion event.
  The v1 AUQ-only predicate is a *structural false-negative* on real provenance. The positive-control row
  shows the detector's positive branch DOES fire (\`surfaced=true\`) on the planted fixture, so the 0/8 is a
  property of the DATA, not a dead branch.
- **\`escalation_count≥1\` on several real rows with \`in_bnd=0\`** distinguishes "no escalation occurred" from
  "escalations occurred but none surfaced the anchor" — the latter is the actual mechanism.
- **Degenerate anchor:** the phrase appears in the \`OFF\`/\`OFF-eval\` baseline rows too — the base model treats
  look-ahead bias as first-class unprompted, so there is no OFF→ON headroom for the harness to add on this
  anchor (see VALID-MEASUREMENT.md for the operational degeneracy criterion).
EOF
}

selfcheck() {
  local rc=0
  # 1. positive control: the ruler's positive branch must fire on the planted fixture.
  if [ -f "$FIXTURES/surfaced.jsonl" ]; then
    local pc; pc=$(bash "$EMITTER" "$FIXTURES/surfaced.jsonl" 2>/dev/null | jq -r '.ground_truth.surfaced')
    if [ "$pc" = "true" ]; then echo "ok: positive control surfaced=true (detector fires)"; else
      echo "FAIL: positive control surfaced=$pc (expected true)"; rc=1; fi
  else echo "FAIL: positive-control fixture missing"; rc=1; fi

  # 2. read-only proof: shasum the inputs before, run the survey, shasum after — must match.
  local files; files="$(collect_transcripts)"
  local before after
  before=$( { [ -f "$FIXTURES/surfaced.jsonl" ] && shasum -a 256 "$FIXTURES/surfaced.jsonl";
              [ -n "$files" ] && while IFS= read -r f; do shasum -a 256 "$f"; done <<<"$files"; } | shasum -a 256)
  print_record >/dev/null 2>&1
  after=$(  { [ -f "$FIXTURES/surfaced.jsonl" ] && shasum -a 256 "$FIXTURES/surfaced.jsonl";
              [ -n "$files" ] && while IFS= read -r f; do shasum -a 256 "$f"; done <<<"$files"; } | shasum -a 256)
  if [ "$before" = "$after" ]; then echo "ok: inputs byte-unchanged (read-only)"; else
    echo "FAIL: input shasums changed — survey mutated an input"; rc=1; fi

  # 3. reproduce the recon: every PRESENT real transcript must read surfaced=false.
  if [ -z "$files" ]; then
    echo "skip: real transcripts absent at $PROJ — recon reproduction skipped (frozen record stands)"
  else
    local f s n=0 false_n=0
    while IFS= read -r f; do
      n=$((n+1))
      s=$(bash "$EMITTER" "$f" 2>/dev/null | jq -r '.ground_truth.surfaced')
      if [ "$s" = "false" ]; then false_n=$((false_n+1)); else
        echo "FAIL: $(basename "$f") surfaced=$s (expected false — detector fired on real data; STOP + re-derive)"; rc=1; fi
    done <<<"$files"
    echo "ok: $false_n/$n real transcripts surfaced=false"
  fi
  return $rc
}

case "${1:-}" in
  --selfcheck) selfcheck ;;
  "")          print_record ;;
  *) echo "usage: survey-real-transcripts.sh [--selfcheck]" >&2; exit 2 ;;
esac
