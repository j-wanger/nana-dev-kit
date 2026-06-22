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

# --- ALLOW (Ph99 fix): Edit .py + `make test` → exit 0 (the kit's shell suite has no pytest) ---
MAKE_TEST='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"make test"}}]}}'
test_start "allow: Edit on .py with 'make test' run exits 0 (Ph99 shell-suite fix)"
T=$(mktemp -d); TR=$(mk_transcript "$T" "$EDIT_PY" "$MAKE_TEST")
EC=0; run_hook_stop "$T" "$TR" >/dev/null || EC=$?
if [ "$EC" = "0" ]; then test_pass; else test_fail "expected exit 0, got $EC ('make test' not accepted)"; fi
rm -rf "$T"

# --- ALLOW: `make eval` also satisfies the gate ---
MAKE_EVAL='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"make eval"}}]}}'
test_start "allow: Edit on .py with 'make eval' run exits 0"
T=$(mktemp -d); TR=$(mk_transcript "$T" "$EDIT_PY" "$MAKE_EVAL")
EC=0; run_hook_stop "$T" "$TR" >/dev/null || EC=$?
if [ "$EC" = "0" ]; then test_pass; else test_fail "expected exit 0, got $EC"; fi
rm -rf "$T"

# --- BLOCK (command-scoping guard, Ph99): a .py FILENAME containing "pytest" but NO test command
#     must still BLOCK — the gate scans COMMANDS, not file paths (no false-allow from a path) ---
EDIT_PYTEST_NAMED='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"src/pytest_helpers.py","old_string":"a","new_string":"b"}}]}}'
test_start "block: editing a 'pytest'-named .py file without running tests still exits 2"
T=$(mktemp -d); TR=$(mk_transcript "$T" "$EDIT_PYTEST_NAMED")
EC=0; run_hook_stop "$T" "$TR" >/dev/null || EC=$?
if [ "$EC" = "2" ]; then test_pass; else test_fail "expected exit 2, got $EC (filename false-allow)"; fi
rm -rf "$T"

# === Phase 99 adversarial-workflow hardening: make-flags, jq line-tolerance, .py$, legacy split ===

# --- ALLOW (A): `make` with flags/vars before the target IS a real test run (was false-blocked) ---
for cmd in "make -j4 test" "make -C subdir test" "make BAR=1 test" "make --jobs 4 eval"; do
  test_start "allow: '$cmd' (flags) counts as a test run, exits 0"
  C='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"'"$cmd"'"}}]}}'
  T=$(mktemp -d); TR=$(mk_transcript "$T" "$EDIT_PY" "$C")
  EC=0; run_hook_stop "$T" "$TR" >/dev/null || EC=$?
  if [ "$EC" = "0" ]; then test_pass; else test_fail "expected 0, got $EC"; fi
  rm -rf "$T"
done

# --- BLOCK (A guard): a quoted 'make test' in a NON-test command must NOT false-satisfy ---
test_start "block: git commit -m \"make test passes\" is not a test run, exits 2"
C='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"git commit -m \"make test passes\""}}]}}'
T=$(mktemp -d); TR=$(mk_transcript "$T" "$EDIT_PY" "$C")
EC=0; run_hook_stop "$T" "$TR" >/dev/null || EC=$?
if [ "$EC" = "2" ]; then test_pass; else test_fail "expected 2, got $EC (quoted 'make test' false-allow)"; fi
rm -rf "$T"

# --- ALLOW (B): a malformed/truncated transcript line between the write and the test command must
#     be SKIPPED (jq -R fromjson?), not abort the scan into a false block ---
test_start "allow: truncated transcript line between write and 'make test' still exits 0 (jq tolerance)"
BAD='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"make test"'
GOOD_MK='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"make test"}}]}}'
T=$(mktemp -d); TR=$(mk_transcript "$T" "$EDIT_PY" "$BAD" "$GOOD_MK")
EC=0; run_hook_stop "$T" "$TR" >/dev/null || EC=$?
if [ "$EC" = "0" ]; then test_pass; else test_fail "expected 0, got $EC (truncated line aborted the scan)"; fi
rm -rf "$T"

# --- ALLOW (C): editing a NON-Python file whose name merely contains '.py' must not block ---
for badpath in "docs/deploy.python-setup.md" "src/app.py.bak" "build/mod.pyc"; do
  test_start "allow: editing '$badpath' (not a .py source) without tests, exits 0"
  W='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"'"$badpath"'","old_string":"a","new_string":"b"}}]}}'
  T=$(mktemp -d); TR=$(mk_transcript "$T" "$W")
  EC=0; run_hook_stop "$T" "$TR" >/dev/null || EC=$?
  if [ "$EC" = "0" ]; then test_pass; else test_fail "expected 0, got $EC ('.py' substring false-block)"; fi
  rm -rf "$T"
done

# --- legacy shape (D): file_path and command are separated, not conflated ---
test_start "block: legacy shape, edit of pytest_helpers.py with NO command, exits 2"
EC=0; echo '{"tool_uses":[{"input":{"file_path":"src/pytest_helpers.py"}}]}' | CLAUDE_PROJECT_DIR="$(mktemp -d)" bash "$HOOK" >/dev/null 2>&1 || EC=$?
if [ "$EC" = "2" ]; then test_pass; else test_fail "expected 2, got $EC (legacy filename false-allow)"; fi
test_start "allow: legacy shape, .py edit + 'make test' command, exits 0"
EC=0; echo '{"tool_uses":[{"input":{"file_path":"src/app.py"}},{"input":{"command":"make test"}}]}' | CLAUDE_PROJECT_DIR="$(mktemp -d)" bash "$HOOK" >/dev/null 2>&1 || EC=$?
if [ "$EC" = "0" ]; then test_pass; else test_fail "expected 0, got $EC"; fi

test_summary "check-tests-were-run"
