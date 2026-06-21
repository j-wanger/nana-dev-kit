#!/usr/bin/env bash
# PreToolUse hook (Write|Edit) — blocks implementation writes without memory_search.
# Exit 0 = allow, Exit 2 = block (stderr shown to agent).
# Opt-in via ~/.claude/enforce-memory marker (separate from .claude/enforce).

set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true  # Phase 79: resolve project-relative refs regardless of CWD

# --- Phase 65 fail-open firing log: one JSONL record {schema_version,ts,hook,action,reason,phase} ---
# Exit-code-neutral (never aborts the hook under set -e); records controlled-vocab reasons only,
# never raw paths/commands. Gate = .dev-wiki present (the log lives there). Append-only + atomic
# (single >>; no read-modify-write truncation — that raced under concurrent fires). Call: log_firing <action> <reason>
log_firing() {
  [ -d ".dev-wiki" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0
  local action="${1:-}" reason="${2:-unspecified}" log=".dev-wiki/enforcement.log" phase ts
  phase=$(sed -n 's/^Phase: *\([0-9][0-9]*\).*/\1/p' ".claude/rules/active-phase.md" 2>/dev/null | head -n1) || true
  [ -n "$phase" ] || phase="unknown"
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || true
  { jq -nc --arg ts "$ts" --arg hook "enforce-memory" --arg action "$action" --arg reason "$reason" --arg phase "$phase" \
      '{schema_version:1,ts:$ts,hook:$hook,action:$action,reason:$reason,phase:$phase}' >> "$log"; } 2>/dev/null || return 0
  return 0
}

# --- Opt-in check: disabled unless a project-local OR global marker is present ---
if [ ! -f ".claude/enforce-memory" ] && [ ! -f "$HOME/.claude/enforce-memory" ]; then
  exit 0
fi

# --- CI bypass: MCP tools unavailable in CI ---
if [ "${CI:-}" = "true" ]; then
  exit 0
fi

# --- Lifecycle check: no dev-wiki means no enforcement ---
if [ ! -d ".dev-wiki" ]; then
  exit 0
fi

# --- Parse file path from stdin JSON ---
command -v jq >/dev/null 2>&1 || { echo "[nana:enforce-memory] jq not found, hook skipped" >&2; exit 0; }

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .input.file_path // empty' 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Normalize to project-relative (Phase 82): absolute event paths bypassed the relative patterns
# below; outside-project writes are not this project's gate to enforce.
FILE_PATH="${FILE_PATH#"$PWD"/}"
case "$FILE_PATH" in
  /*) exit 0 ;;
esac

# --- Path allowlist: meta/lifecycle/test/docs are always allowed ---
case "$FILE_PATH" in
  .dev-wiki/*|.claude/*|wiki/*|specs/*|tests/*|templates/*) log_firing "allow" "allowlisted-path"; exit 0 ;;
  *_test.*|test_*.*|*_spec.*) log_firing "allow" "test-file"; exit 0 ;;
  *.md) log_firing "allow" "markdown"; exit 0 ;;
esac

# --- Memory gate (Phase 95 redesign): assert a REAL in-session memory_search, not a marker the agent
#     touches itself. The old `.claude/.memory-consulted` check proved file-EXISTENCE, not consultation —
#     gameable (the audit found ~45% of bites were ritual marker-touches). Read the transcript PreToolUse
#     delivers and require a real assistant `tool_use` memory_search whose timestamp is at/after the
#     session-start anchor (~/.claude/.session-start-ts, written by session-start.sh) — a real-event
#     assertion (det-vs-LLM Principle 2) WITH per-session freshness. The deferred-tool catalog
#     (attachment/system entries naming mcp__memory__*) is structurally excluded by the type==assistant +
#     tool_use JSON gate, never a raw grep. FAIL-OPEN: a relevance gate never blocks on its own breakage. ---
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")
if [ -z "$TRANSCRIPT" ] || [ ! -r "$TRANSCRIPT" ]; then
  log_firing "allow" "no-transcript"
  exit 0
fi
# Freshness anchor: PER-SESSION keyed file ~/.claude/.session-start-ts-<session_id> (written by
# session-start.sh), NOT the bare global ts. The global is mutable shared state — a CONCURRENT session's
# session-start, or any global re-fire, advances it and falsely excludes a genuine in-session
# memory_search (observed: a 2h-advanced global blocked a real search). Keying by session_id isolates
# this session's bound; --resume re-fires SessionStart with the SAME session_id, so the keyed bound
# advances on resume (resumed-session freshness preserved). Fall back to the global ts when the keyed
# file is absent (old session / no session_id) — never stricter than before.
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")
ANCHOR=""
case "$SID" in
  ''|*[!a-zA-Z0-9_-]*) ANCHOR="" ;;                                   # path-safety: only a sane id keys a file
  *) [ -r "$HOME/.claude/.session-start-ts-$SID" ] && ANCHOR="$HOME/.claude/.session-start-ts-$SID" ;;
esac
[ -z "$ANCHOR" ] && [ -r "$HOME/.claude/.session-start-ts" ] && ANCHOR="$HOME/.claude/.session-start-ts"
SINCE=0
[ -n "$ANCHOR" ] && SINCE=$(cat "$ANCHOR" 2>/dev/null || echo 0)
case "$SINCE" in ''|*[!0-9]*) SINCE=0 ;; esac   # guard: only a bare epoch is a valid bound
# grep -F narrows to candidate lines cheaply; the JSON gate below is authoritative. fromjson? tolerates
# malformed lines so the scan never aborts. Output "1" per real, in-window match; head -1 short-circuits.
FOUND=$(grep -F '"tool_use"' "$TRANSCRIPT" 2>/dev/null \
  | jq -rR --argjson since "$SINCE" '
      fromjson?
      | select(.type=="assistant")
      | (.timestamp // "" | sub("\\.[0-9]+";"") | (try fromdateiso8601 catch 0)) as $ts
      | select($ts >= $since)
      | .message.content[]?
      | select(.type=="tool_use" and ((.name // "") | test("memory_search")))
      | "1"' 2>/dev/null | head -n1 || true)   # || true: empty grep (no tool_use lines) must not abort under set -e
if [ "$FOUND" = "1" ]; then
  log_firing "allow" "memory-searched"
  exit 0
fi

log_firing "block" "no-memory-search" || true
echo "[nana:enforce-memory] No memory_search this session. Call mcp__memory__memory_search before this write." >&2
exit 2
