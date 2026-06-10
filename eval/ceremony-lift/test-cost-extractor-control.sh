#!/usr/bin/env bash
# Phase 86 — cost-extractor positive control (pre-registration: Token attribution).
# Hand-labeled anchor session 74a6533b: values below computed independently via direct
# jq one-liners on 2026-06-10 (manual instrument), pinned as literals. The pipeline
# (extract-costs.py) must reproduce them before any bulk cost row counts.
set -uo pipefail
cd "$(dirname "$0")"

SESSION="$HOME/.claude/projects/-Users-jwang-nana-dev-kit/74a6533b-66aa-426d-9da0-b2a6d22a0197.jsonl"
EXTRACTOR="./extract-costs.py"
FAIL=0
note() { echo "  $1"; }
check() { # check <name> <expected> <actual>
  if [ "$2" = "$3" ]; then note "PASS: $1 ($3)"; else note "FAIL: $1 expected=$2 actual=$3"; FAIL=1; fi
}

[ -f "$SESSION" ] || { echo "control: anchor session missing: $SESSION"; exit 1; }
[ -f "$EXTRACTOR" ] || { echo "control: extractor missing: $EXTRACTOR (RED)"; exit 1; }

# --- Hand-labeled pins (direct jq sums, manual run 2026-06-10) ---------------
PIN_IN=69481; PIN_CW=2197021; PIN_CR=118375940; PIN_OUT=547844
PIN_USAGE_MSGS=474
PIN_INTERRUPTIONS=7
PIN_CEREMONY_DISPATCHES=8     # 9 Agent dispatches minus wiki-add (non-ceremony)
PIN_MAX_WALLCLOCK=11293       # last-first = 11292.88s; spans must not exceed
PIN_STEP_CLASSES="approach-reviewer debrief-capture dev-plan-orchestration plan-reviewer review-gate-reviewer spec-generation"

OUT=$(python3 "$EXTRACTOR" "$SESSION") || { echo "control: extractor crashed"; exit 1; }
# Output format: TSV with header: step,msgs,in,cw,cr,out,cache_adj,wall_s,interrupts,dispatches,subagent_out

sum_col() { echo "$OUT" | awk -F'\t' -v c="$1" 'NR>1 {s+=$c} END {printf "%d", s}'; }

# 1. Conservation: per-type partition sums == direct totals (every message exactly once)
check "conservation input_tokens"        "$PIN_IN"  "$(sum_col 3)"
check "conservation cache_write"         "$PIN_CW"  "$(sum_col 4)"
check "conservation cache_read"          "$PIN_CR"  "$(sum_col 5)"
check "conservation output_tokens"       "$PIN_OUT" "$(sum_col 6)"
check "conservation usage_messages"      "$PIN_USAGE_MSGS" "$(sum_col 2)"

# 2. Ceremony dispatch detection (8, wiki-add excluded to implementation-other)
check "ceremony dispatch count"          "$PIN_CEREMONY_DISPATCHES" "$(sum_col 10)"

# 3. All six step classes present as rows
ACTUAL_CLASSES=$(echo "$OUT" | awk -F'\t' 'NR>1 && $1 != "implementation-other" {print $1}' | sort | tr '\n' ' ' | sed 's/ $//')
check "step classes" "$PIN_STEP_CLASSES" "$ACTUAL_CLASSES"

# 4. Interruptions
check "interruptions (AskUserQuestion)"  "$PIN_INTERRUPTIONS" "$(sum_col 9)"

# 4b. Subagent cost recovery (hand-paired 2026-06-10: sync colon-form via tool_use_id,
# background XML-form via notification desc; wiki-add's 42363 -> implementation-other)
PIN_SUBAGENT_TOTAL=906965   # 51447+63511+63697+50470+42363 sync + 129932+153848+143040+208657 background
PIN_SUBAGENT_OTHER=42363    # wiki-add (non-ceremony)
check "subagent tokens total"            "$PIN_SUBAGENT_TOTAL" "$(sum_col 11)"
SUB_OTHER=$(echo "$OUT" | awk -F'\t' '$1 == "implementation-other" {print $11}')
check "subagent tokens excluded (wiki-add)" "$PIN_SUBAGENT_OTHER" "$SUB_OTHER"

# 5. Wall-clock sanity: total > 0 and <= session span
WALL=$(sum_col 8)
if [ "$WALL" -gt 0 ] && [ "$WALL" -le "$PIN_MAX_WALLCLOCK" ]; then note "PASS: wall-clock ($WALL s within (0, $PIN_MAX_WALLCLOCK])"; else note "FAIL: wall-clock $WALL outside (0, $PIN_MAX_WALLCLOCK]"; FAIL=1; fi

# 6. Truncated-final-line fixture (mid-append .jsonl): parser tolerant, counts only complete lines
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
head -50 "$SESSION" > "$TMP/trunc.jsonl"
head -51 "$SESSION" | tail -1 | cut -c1-40 >> "$TMP/trunc.jsonl"   # half a line of JSON
EXPECT_TRUNC=$(head -50 "$SESSION" | jq -s '[.[] | select(.message.usage.output_tokens != null)] | length')
TRUNC_OUT=$(python3 "$EXTRACTOR" "$TMP/trunc.jsonl") || { note "FAIL: truncated fixture crashed"; FAIL=1; TRUNC_OUT=""; }
TRUNC_MSGS=$(echo "$TRUNC_OUT" | awk -F'\t' 'NR>1 {s+=$2} END {printf "%d", s}')
check "truncated-final-line fixture"     "$EXPECT_TRUNC" "$TRUNC_MSGS"

# 7. Empty-file fixture
: > "$TMP/empty.jsonl"
EMPTY_OUT=$(python3 "$EXTRACTOR" "$TMP/empty.jsonl") || { note "FAIL: empty fixture crashed"; FAIL=1; EMPTY_OUT=""; }
EMPTY_MSGS=$(echo "$EMPTY_OUT" | awk -F'\t' 'NR>1 {s+=$2} END {printf "%d", s}')
check "empty-file fixture"               "0" "$EMPTY_MSGS"

if [ "$FAIL" -eq 0 ]; then echo "cost-extractor control: ALL PASS"; exit 0; else echo "cost-extractor control: FAILURES"; exit 1; fi
