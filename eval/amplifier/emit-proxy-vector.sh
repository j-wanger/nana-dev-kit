#!/usr/bin/env bash
# Phase 68 — amplifier proxy-vector emitter (Frontier 0 measurement instrument).
#
# Reads a REAL Claude Code session transcript (jsonl) + optional final git state and
# enforcement.log, and emits ONE deterministic proxy-vector JSON to stdout.
# Scoring path is deterministic only: bash + jq, literal/normalized string matching.
# No neural judge, no model call, no vector-similarity, no fuzzy matching anywhere here.
# READ-ONLY: never mutates any input or any project state.
#
# Usage:
#   emit-proxy-vector.sh <transcript.jsonl> [--enforcement-log PATH] [--repo PATH]
#
# Schema: see eval/amplifier/SCHEMA-NOTES.md (4 groups, frozen). No verdict/grade field.
set -uo pipefail

TRANSCRIPT="${1:-}"
ENF_LOG=""
REPO=""
shift || true
while [ $# -gt 0 ]; do
  case "$1" in
    --enforcement-log) ENF_LOG="${2:-}"; shift 2 ;;
    --repo)            REPO="${2:-}"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  echo "usage: emit-proxy-vector.sh <transcript.jsonl> [--enforcement-log P] [--repo P]" >&2
  exit 2
fi

# --- 1. Split transcript into valid jsonl lines vs parse errors (skip-and-count) ---
parse_errors=0
valid_lines=()
while IFS= read -r line || [ -n "$line" ]; do
  [ -z "$line" ] && continue                       # blank line: ignore, not an error
  if printf '%s' "$line" | jq empty >/dev/null 2>&1; then
    valid_lines+=("$line")
  else
    parse_errors=$((parse_errors + 1))
  fi
done < "$TRANSCRIPT"

if [ "${#valid_lines[@]}" -gt 0 ]; then
  STREAM=$(printf '%s\n' "${valid_lines[@]}")
else
  STREAM=""                                         # → jq -s sees [] (empty session)
fi

# --- 2. Interaction proxies + ground-truth detector (one jq pass over the slurped array) ---
# is_human: a user-role turn that is real human text, NOT a replayed tool_result.
# surfaced: same-day-close phrase family appears INSIDE an AskUserQuestion event's text.
# unsolicited: human turns whose most-recent preceding assistant turn carried NO AskUserQuestion.
INTER=$(printf '%s' "$STREAM" | jq -s '
  def is_human:
    .type=="user"
    and (.isMeta != true)
    and ((.message.content|type=="string")
         or ((.message.content|type=="array")
             and (([.message.content[].type]|index("text")) != null)
             and (([.message.content[].type]|index("tool_result")) == null)));
  def auq_blocks: [.[]|select(.type=="assistant")|.message.content[]?|select(.type=="tool_use" and .name=="AskUserQuestion")];
  def tool_blocks: [.[]|select(.type=="assistant")|.message.content[]?|select(.type=="tool_use")];
  def auq_texts:
    [ .[]|select(.type=="assistant")|.message.content[]?
      |select(.type=="tool_use" and .name=="AskUserQuestion")
      |.input.questions[]?
      |((.question // ""), (.header // ""), (.options[]?|.label // ""), (.options[]?|.description // "")) ];
  def surfaced:
    (auq_texts | map(ascii_downcase)) as $t
    | any($t[];
        contains("same-day close") or contains("same day close")
        or contains("look-ahead") or contains("lookahead")
        or contains("entry timing"));
  def unsolicited:
    reduce .[] as $e ({p:false, c:0};
      if ($e.type=="assistant")
        then .p = (([$e.message.content[]?|select(.type=="tool_use" and .name=="AskUserQuestion")]|length) > 0)
      elif ($e|is_human)
        then (if .p then . else .c += 1 end)
      else . end) | .c;
  {
    human_turns: ([.[]|select(is_human)]|length),
    escalation_count: (auq_blocks|length),
    tool_use_count: (tool_blocks|length),
    redirect_proxy: {status:"experimental", unsolicited_human_turns: unsolicited},
    surfaced: surfaced
  }')

# --- 3. Enforcement (external log only; absent ⇒ null sentinel, never 0) ---
ENF_JSON="null"
if [ -n "$ENF_LOG" ] && [ -f "$ENF_LOG" ]; then
  bc=0
  while IFS= read -r l || [ -n "$l" ]; do
    [ -z "$l" ] && continue
    if printf '%s' "$l" | jq -e 'select(.action=="block")' >/dev/null 2>&1; then
      bc=$((bc + 1))
    fi
  done < "$ENF_LOG"
  ENF_JSON="{\"block_count\":$bc}"
fi

# --- 4. Mechanical (git STRUCTURE only; execution-dependent fields are sentinels) ---
REVERTS_JSON="null"
if [ -n "$REPO" ] && git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
  rc=$(git -C "$REPO" log --pretty=%s 2>/dev/null | grep -cE '^(fixup!|squash!|Revert )' || true)
  REVERTS_JSON="$rc"
fi

# --- 5. Assemble (observations only — no verdict/grade/score) ---
jq -n \
  --argjson inter "$INTER" \
  --argjson reverts "$REVERTS_JSON" \
  --argjson enforcement "$ENF_JSON" \
  --argjson parse_errors "$parse_errors" \
  --arg source "$(basename "$TRANSCRIPT")" \
  '{
    mechanical: {
      tests_pass: null,
      lint_findings: null,
      commits_to_first_green: null,
      reverts_fixups: $reverts
    },
    interaction: {
      human_turns: $inter.human_turns,
      escalation_count: $inter.escalation_count,
      tool_use_count: $inter.tool_use_count,
      redirect_proxy: $inter.redirect_proxy
    },
    enforcement: $enforcement,
    ground_truth: { surfaced: $inter.surfaced },
    parse_errors: $parse_errors,
    source: $source
  }'
