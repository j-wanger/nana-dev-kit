#!/usr/bin/env bash
# Phase 69 — measurability gate: "is a VALID harness off/on measurement possible on this anchor/data YET?"
#
# A deterministic, READ-ONLY predicate (the Phase-66 signal-richness-probe idiom — a runnable trigger, not a
# calendar note). It is the load-bearing Phase-70 gate: only a flip to MEASURABLE unblocks the expensive live
# off/on run. Criteria + the pinned threshold live in VALID-MEASUREMENT.md (read, not hard-coded).
#
# Classification over the transcript set (planted control fixtures excluded by shasum):
#   NO-DATA          no transcripts present.
#   MEASURABLE       >= MIN_ON distinct ON  AND  >= MIN_OFF distinct OFF  AND  >=1 in-boundary ground-truth
#                    event (detector sees the anchor)  AND  an OFF-vs-ON surfaced-rate differential (lift to detect).
#   NOT-MEASURABLE   otherwise, with the specific failing reason(s).
#
# Deterministic only: bash + jq. No model call, no vector similarity, no fuzzy match. Makes NO harness-value claim.
#
# Usage:
#   measurability-gate.sh             # classify the real transcript set; print VERDICT + reasons
#   measurability-gate.sh --selftest  # assert a constructed MEASURABLE and a NOT-MEASURABLE scenario; exit 0/1
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
EMITTER="$HERE/emit-proxy-vector.sh"
FIXTURES="$HERE/fixtures"
DOC="$HERE/VALID-MEASUREMENT.md"

# --- pinned threshold, READ from VALID-MEASUREMENT.md (not a buried magic literal) ---
read_threshold() {
  local line; line="$(grep -oE 'gate-threshold:[^>]*' "$DOC" 2>/dev/null | head -1)"
  MIN_ON=$(printf '%s' "$line"  | grep -oE 'MIN_ON=[0-9]+'  | grep -oE '[0-9]+' || true)
  MIN_OFF=$(printf '%s' "$line" | grep -oE 'MIN_OFF=[0-9]+' | grep -oE '[0-9]+' || true)
  : "${MIN_ON:=2}" "${MIN_OFF:=2}"
}

label_for() {
  case "$1" in
    *-ab-test-condition-c-stock-screener*) echo "ON" ;;
    *-ab-test-stock-screener*)             echo "OFF" ;;
    */-Users-jwang-ab-test/*)              echo "OFF" ;;   # eval/baseline sessions are harness-OFF
    *) echo "unknown" ;;
  esac
}

# planted control-fixture shasums — EXCLUDED so a planted transcript can never satisfy the gate.
planted_shasums() {
  local f
  for f in "$FIXTURES"/*.jsonl; do
    [ -f "$f" ] && shasum -a 256 "$f" | awk '{print $1}'
  done
}

# classify a projects dir → prints "VERDICT" on the last line; reasons to stderr.
classify() {
  local proj="$1"
  read_threshold
  local dirs=(
    "$proj/-Users-jwang-ab-test"
    "$proj/-Users-jwang-ab-test-stock-screener"
    "$proj/-Users-jwang-ab-test-condition-c-stock-screener"
  )
  local excl; excl="$(planted_shasums)"
  local on=0 off=0 surf_on=0 surf_off=0 total=0 inb=0
  local d f sha lbl surfaced
  for d in "${dirs[@]}"; do
    for f in "$d"/*.jsonl; do
      [ -f "$f" ] || continue
      sha="$(shasum -a 256 "$f" | awk '{print $1}')"
      if printf '%s\n' "$excl" | grep -qx "$sha"; then continue; fi   # skip planted fixtures
      total=$((total+1))
      lbl="$(label_for "$f")"
      surfaced="$(bash "$EMITTER" "$f" 2>/dev/null | jq -r '.ground_truth.surfaced')"
      case "$lbl" in
        ON)  on=$((on+1));  [ "$surfaced" = "true" ] && { surf_on=$((surf_on+1)); inb=$((inb+1)); } ;;
        OFF) off=$((off+1)); [ "$surfaced" = "true" ] && { surf_off=$((surf_off+1)); inb=$((inb+1)); } ;;
      esac
    done
  done

  local unk=$((total - on - off))   # files not ON/OFF-labelled: counted in total, never in an arm (cannot satisfy the gate)
  echo "set: total=$total (planted excluded) | ON=$on OFF=$off unknown=$unk | surfaced_on=$surf_on surfaced_off=$surf_off | in_boundary_events=$inb | threshold MIN_ON=$MIN_ON MIN_OFF=$MIN_OFF" >&2

  if [ "$total" -eq 0 ]; then echo "NO-DATA"; return; fi

  local reasons=()
  [ "$on"  -ge "$MIN_ON" ]  || reasons+=("ON arm under threshold ($on < $MIN_ON)")
  [ "$off" -ge "$MIN_OFF" ] || reasons+=("OFF arm under threshold ($off < $MIN_OFF)")
  [ "$inb" -ge 1 ]          || reasons+=("0 in-boundary ground-truth events — detector blind to the anchor on this data")
  [ "$surf_on" -ne "$surf_off" ] || reasons+=("no OFF-vs-ON differential (surfaced_on=$surf_on == surfaced_off=$surf_off) — degenerate anchor / no headroom")

  if [ "${#reasons[@]}" -eq 0 ]; then
    echo "MEASURABLE"
  else
    local r; for r in "${reasons[@]}"; do echo "reason: $r" >&2; done
    echo "NOT-MEASURABLE"
  fi
}

selftest() {
  command -v mktemp >/dev/null || { echo "FAIL: mktemp unavailable"; return 1; }
  local rc=0 tmp; tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  # synthetic-but-structurally-valid transcripts (distinct content ⇒ shasums differ from planted fixtures).
  mk_surfaced() {  # an AskUserQuestion event whose question carries the anchor phrase ⇒ surfaced=true
    printf '%s\n' "{\"type\":\"assistant\",\"message\":{\"content\":[{\"type\":\"tool_use\",\"name\":\"AskUserQuestion\",\"input\":{\"questions\":[{\"header\":\"Timing\",\"question\":\"Use same-day close for entry, or next-day open? ($1)\",\"options\":[{\"label\":\"same-day close\",\"description\":\"look-ahead risk\"}]}]}}]}}" > "$2"
  }
  mk_buried() {    # plain assistant text mentioning the phrase but NOT in an AUQ ⇒ surfaced=false
    printf '%s\n' "{\"type\":\"assistant\",\"message\":{\"content\":[{\"type\":\"text\",\"text\":\"Handled look-ahead bias in the backtester ($1).\"}]}}" > "$2"
  }

  # Scenario A — MEASURABLE: 2 distinct ON surfaced + 2 distinct OFF buried (real OFF≠ON differential).
  local A="$tmp/A"
  mkdir -p "$A/-Users-jwang-ab-test-condition-c-stock-screener" "$A/-Users-jwang-ab-test-stock-screener"
  mk_surfaced a1 "$A/-Users-jwang-ab-test-condition-c-stock-screener/a1.jsonl"
  mk_surfaced a2 "$A/-Users-jwang-ab-test-condition-c-stock-screener/a2.jsonl"
  mk_buried   b1 "$A/-Users-jwang-ab-test-stock-screener/b1.jsonl"
  mk_buried   b2 "$A/-Users-jwang-ab-test-stock-screener/b2.jsonl"
  local va; va="$(classify "$A" 2>/dev/null)"
  if [ "$va" = "MEASURABLE" ]; then echo "ok: scenario A ⇒ MEASURABLE (green path reachable)"; else
    echo "FAIL: scenario A ⇒ $va (expected MEASURABLE — gate may be permanently-RED)"; rc=1; fi

  # Scenario B — NOT-MEASURABLE: 2 ON + 2 OFF all buried (zero in-boundary events).
  local B="$tmp/B"
  mkdir -p "$B/-Users-jwang-ab-test-condition-c-stock-screener" "$B/-Users-jwang-ab-test-stock-screener"
  mk_buried c1 "$B/-Users-jwang-ab-test-condition-c-stock-screener/c1.jsonl"
  mk_buried c2 "$B/-Users-jwang-ab-test-condition-c-stock-screener/c2.jsonl"
  mk_buried d1 "$B/-Users-jwang-ab-test-stock-screener/d1.jsonl"
  mk_buried d2 "$B/-Users-jwang-ab-test-stock-screener/d2.jsonl"
  local vb; vb="$(classify "$B" 2>/dev/null)"
  if [ "$vb" = "NOT-MEASURABLE" ]; then echo "ok: scenario B ⇒ NOT-MEASURABLE (red path correct)"; else
    echo "FAIL: scenario B ⇒ $vb (expected NOT-MEASURABLE)"; rc=1; fi

  return $rc
}

case "${1:-}" in
  --selftest) selftest ;;
  "")
    PROJ="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"
    verdict="$(classify "$PROJ")"
    echo "VERDICT: $verdict"
    ;;
  *) echo "usage: measurability-gate.sh [--selftest]" >&2; exit 2 ;;
esac
