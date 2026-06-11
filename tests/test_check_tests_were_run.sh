#!/usr/bin/env bash
# Paired functional smoke for the check-tests-were-run.sh HEU-007 dual-condition harden
# (Phase 88). The Ph85 dogfood false-positive class: Read of .py files during read-only
# analysis tripped the "tests not run" Stop block. Harden: the .py condition keys on
# WRITE-CLASS tools (Write/Edit/MultiEdit/NotebookEdit) in the transcript path AND retains
# the tests-not-run condition — block AND allow both asserted (HEU-012: a presence test
# would pass a dormant hook; an allow-only test would pass an overcorrected one).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_ROOT/templates/.claude/hooks/check-tests-were-run.sh"
# fires: check-tests-were-run.sh   # (coverage gate — see test_hook_firing_coverage.sh)

mk_transcript() { # <dir> <jsonl-lines...> — writes transcript.jsonl, echoes its path
  local d="$1"; shift
  printf '%s\n' "$@" > "$d/transcript.jsonl"
  echo "$d/transcript.jsonl"
}

run_hook_stop() { # <sandbox> <transcript-path> — pipes a real-shaped Stop event
  echo "{\"transcript_path\":\"$2\"}" | CLAUDE_PROJECT_DIR="$1" bash "$HOOK" 2>/dev/null
}

EDIT_PY='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"src/mod.py","old_string":"a","new_string":"b"}}]}}'
READ_PY='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Read","input":{"file_path":"src/mod.py"}}]}}'
PYTEST='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"uv run pytest -x"}}]}}'

# --- BLOCK path: Edit on .py, no pytest → exit 2 ---
test_start "block: Edit on .py without pytest exits 2"
T=$(mktemp -d); TR=$(mk_transcript "$T" "$EDIT_PY")
EC=0; run_hook_stop "$T" "$TR" >/dev/null || EC=$?
if [ "$EC" = "2" ]; then test_pass; else test_fail "expected exit 2, got $EC"; fi
rm -rf "$T"

# --- ALLOW path (the harden): Read-ONLY .py activity → exit 0 (was the false positive) ---
test_start "allow: Read-only .py activity exits 0 (Ph85 false-positive killed)"
T=$(mktemp -d); TR=$(mk_transcript "$T" "$READ_PY")
EC=0; run_hook_stop "$T" "$TR" >/dev/null || EC=$?
if [ "$EC" = "0" ]; then test_pass; else test_fail "expected exit 0, got $EC (Read still trips the block)"; fi
rm -rf "$T"

# --- ALLOW path: Edit on .py + pytest ran → exit 0 (second condition retained) ---
test_start "allow: Edit on .py with pytest run exits 0"
T=$(mktemp -d); TR=$(mk_transcript "$T" "$EDIT_PY" "$PYTEST")
EC=0; run_hook_stop "$T" "$TR" >/dev/null || EC=$?
if [ "$EC" = "0" ]; then test_pass; else test_fail "expected exit 0, got $EC"; fi
rm -rf "$T"

# --- BLOCK retained for Write tool too (no false negative from over-narrowing) ---
test_start "block: Write of a new .py without pytest exits 2"
WRITE_PY='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Write","input":{"file_path":"src/new.py","content":"x=1"}}]}}'
T=$(mktemp -d); TR=$(mk_transcript "$T" "$WRITE_PY")
EC=0; run_hook_stop "$T" "$TR" >/dev/null || EC=$?
if [ "$EC" = "2" ]; then test_pass; else test_fail "expected exit 2, got $EC"; fi
rm -rf "$T"

test_summary "check-tests-were-run"
