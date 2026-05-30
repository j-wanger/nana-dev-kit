#!/usr/bin/env bash
# Phase 68 / T1 — BEHAVIORAL transcript-schema feasibility probe.
#
# Proves a REAL Claude Code session transcript (jsonl) carries a non-empty extraction
# for every proxy group the amplifier emitter needs — the "verify firing, not presence"
# bar (HEU-012). Deterministic, READ-ONLY (jq read-only; no writes anywhere).
#
# Usage: bash eval/amplifier/schema-probe.sh [transcript.jsonl]
#   No arg → picks the newest nana-dev-kit project transcript containing AskUserQuestion.
# Exit: 0 iff every proxy group returns >=1 record; 1 if any group is empty; 2 if no transcript.
set -uo pipefail

PROJ_DIR="${HOME}/.claude/projects/-Users-jwang-nana-dev-kit"
TRANSCRIPT="${1:-}"
if [ -z "$TRANSCRIPT" ]; then
  TRANSCRIPT=$(grep -l '"AskUserQuestion"' "$PROJ_DIR"/*.jsonl 2>/dev/null | head -1)
fi
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  echo "PROBE: no real transcript found (looked in $PROJ_DIR for one containing AskUserQuestion)"
  exit 2
fi
echo "PROBE transcript: $(basename "$TRANSCRIPT")"

fail=0
probe() {  # $1 name  $2 jq-filter
  local name="$1" filter="$2" n
  n=$(jq -rc "$filter" "$TRANSCRIPT" 2>/dev/null | grep -c .)
  if [ "${n:-0}" -ge 1 ]; then
    printf '  OK   %-14s %s\n' "$name" "$n"
  else
    printf '  MISS %-14s 0\n' "$name"; fail=1
  fi
}

probe "human-turn"    'select(.type=="user" and (.isMeta|not) and ((.message.content|type)=="string" or ((.message.content|type)=="array" and ([.message.content[].type]|any(.=="text")) and ([.message.content[].type]|any(.=="tool_result")|not))))'
probe "ask-user-q"    'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and .name=="AskUserQuestion")'
probe "tool-use"      'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")'
probe "assistant-act" 'select(.type=="assistant")'

if [ "$fail" -eq 0 ]; then
  echo "PROBE: PASS — all proxy groups non-empty (transcript-parsing is viable)"
  exit 0
else
  echo "PROBE: FAIL — a proxy group is unreadable; pivot to a logging-hook capture before building the emitter"
  exit 1
fi
