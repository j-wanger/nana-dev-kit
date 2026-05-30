#!/usr/bin/env bash
# Phase 68 / T3+T4 — the amplifier proxy-vector emitter, control-validated.
# Asserts VALUES (not just shape): the detector + an interaction proxy FLIP between the
# surfaced/buried control pair; missing sources yield sentinels (not 0); malformed jsonl is
# skip-and-counted; the emitter is read-only; a real transcript reads cleanly.
# Deterministic only — no neural judge anywhere in the scoring path.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EMIT="$REPO_ROOT/eval/amplifier/emit-proxy-vector.sh"
FX="$REPO_ROOT/eval/amplifier/fixtures"

echo "=== test_amplifier_emitter.sh ==="

test_start "emitter exists and is executable"
[ -x "$EMIT" ] && test_pass || test_fail "missing or non-exec: $EMIT"

# --- ground-truth detector flips on the control pair ---
SURF=$("$EMIT" "$FX/surfaced.jsonl")
BUR=$("$EMIT" "$FX/buried.jsonl")
OUT=$("$EMIT" "$FX/buried_phrase_outside_escalation.jsonl")

test_start "surfaced control -> ground_truth.surfaced == true"
assert_eq "true" "$(printf '%s' "$SURF" | jq -r '.ground_truth.surfaced')"

test_start "buried control -> ground_truth.surfaced == false (detector FLIPS)"
assert_eq "false" "$(printf '%s' "$BUR" | jq -r '.ground_truth.surfaced')"

test_start "interaction proxy FLIPS: escalation_count surfaced==1"
assert_eq "1" "$(printf '%s' "$SURF" | jq -r '.interaction.escalation_count')"
test_start "interaction proxy FLIPS: escalation_count buried==0"
assert_eq "0" "$(printf '%s' "$BUR" | jq -r '.interaction.escalation_count')"

test_start "phrase OUTSIDE an escalation event -> surfaced == false (not raw-text match)"
assert_eq "false" "$(printf '%s' "$OUT" | jq -r '.ground_truth.surfaced')"

# --- missing source => sentinel, never silent 0 ---
test_start "absent enforcement.log -> enforcement == null (sentinel, not 0)"
assert_eq "null" "$(printf '%s' "$SURF" | jq -r '.enforcement')"

test_start "present enforcement.log -> enforcement.block_count == 2"
WB=$("$EMIT" "$FX/surfaced.jsonl" --enforcement-log "$FX/enforcement-with-blocks.log")
assert_eq "2" "$(printf '%s' "$WB" | jq -r '.enforcement.block_count')"

# --- malformed jsonl is skip-and-count, vector still valid ---
test_start "corrupt line -> parse_errors == 1"
COR=$("$EMIT" "$FX/corrupt_line.jsonl")
assert_eq "1" "$(printf '%s' "$COR" | jq -r '.parse_errors')"
test_start "corrupt-line vector still valid: human_turns==1"
assert_eq "1" "$(printf '%s' "$COR" | jq -r '.interaction.human_turns')"
test_start "corrupt-line vector still valid: tool_use_count==1"
assert_eq "1" "$(printf '%s' "$COR" | jq -r '.interaction.tool_use_count')"

# --- no verdict/grade field (observations only) ---
test_start "no verdict/grade/score field in output"
assert_eq "false" "$(printf '%s' "$SURF" | jq -r 'has("verdict") or has("grade") or has("score")')"

# --- read-only: hermetic proof. Copy inputs (incl. a real transcript) into a mktemp dir,
# snapshot the WHOLE dir before/after, run the emitter with cwd inside it. Ambient processes
# (the live session transcript, hooks writing .dev-wiki) cannot touch the temp copy, so any
# hash change is the emitter's doing; a stray relative write would also alter the dir hash.
REAL=$(grep -l '"AskUserQuestion"' "$HOME"/.claude/projects/-Users-jwang-nana-dev-kit/*.jsonl 2>/dev/null | head -1)
test_start "emitter is read-only (hermetic temp-dir snapshot, no mutation, no stray writes)"
SANDBOX=$(mktemp -d)
cp "$FX"/*.jsonl "$FX"/*.log "$SANDBOX"/ 2>/dev/null
[ -n "$REAL" ] && cp "$REAL" "$SANDBOX/real.jsonl"
snap() { find "$SANDBOX" -type f -exec shasum {} \; | sed "s#$SANDBOX##" | sort; }
RO_BEFORE=$(snap)
( cd "$SANDBOX" && for f in *.jsonl; do "$EMIT" "$f" >/dev/null 2>&1; done
  "$EMIT" surfaced.jsonl --enforcement-log enforcement-with-blocks.log >/dev/null 2>&1 )
RO_AFTER=$(snap)
[ "$RO_BEFORE" = "$RO_AFTER" ] && test_pass || test_fail "emitter mutated an input or wrote a stray file"
rm -rf "$SANDBOX"

# --- real transcript reads as valid 4-group JSON ---
test_start "real transcript -> valid 4-group proxy vector"
if [ -n "$REAL" ]; then
  if "$EMIT" "$REAL" | jq -e 'has("mechanical") and has("interaction") and (.ground_truth|has("surfaced")) and has("enforcement")' >/dev/null 2>&1; then
    test_pass
  else
    test_fail "real transcript did not emit valid 4-group JSON"
  fi
else
  test_fail "no real transcript found to validate against (expected one with AskUserQuestion)"
fi

test_summary "amplifier-emitter"
