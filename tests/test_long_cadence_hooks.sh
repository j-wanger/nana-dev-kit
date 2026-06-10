#!/usr/bin/env bash
# Phase 67 — firing tests for the advisory long-cadence hooks (pre-compact, post-compact, session-stop)
# plus the check-tests-were-run allow/skip branch. These fire only at compaction / session-end and write
# nothing to enforcement.log by construction, so log-silence is NOT evidence they work — only a
# synthesized-trigger firing test is ([[HEU-012]]). Every assertion checks a LOAD-BEARING SIDE-EFFECT
# (stdout content, or a file write/removal), never exit code alone — an advisory hook gutted to a no-op
# still exits 0, so exit-code-only "coverage" is satisfied by a broken hook.
# fires: pre-compact.sh post-compact.sh session-stop.sh check-tests-were-run.sh py-review-stop.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS="$REPO_ROOT/templates/.claude/hooks"
ORIG_HOME="$HOME"

teardown() { export HOME="$ORIG_HOME"; chmod -R u+rwx "$1" 2>/dev/null || true; rm -rf "$1"; }

# Run a hook in an ISOLATED fixture (own HOME + cwd, never a git repo) so a hook that writes relative to
# $CWD/$ROOT cannot touch the kit's own .dev-wiki/.nana. echo exit code; stdout->$fx/.out stderr->$fx/.err.
run_hook() {
  local hook="$1" fx="$2" json="${3:-}"; local ec=0
  printf '%s' "$json" | HOME="$fx" bash -c "cd '$fx' && bash '$HOOKS/$hook'" >"$fx/.out" 2>"$fx/.err" || ec=$?
  echo "$ec"
}

echo "=== Phase 67 Long-Cadence Hook Firing Tests ==="

# ---- pre-compact.sh: surfaces active-phase + next task from project state (advisory, exit 0) ----
test_start "pre-compact: surfaces active-phase + next task from fixtures"
T=$(mktemp -d); mkdir -p "$T/.claude/rules" "$T/.dev-wiki"
printf 'Phase: 99 - sentinel phase\nObjective: do the sentinel thing\n' > "$T/.claude/rules/active-phase.md"
printf '# Tasks\n- [ ] [S] sentinel-task do it | scope: `x` | success: `true` | size: S\n' > "$T/.dev-wiki/tasks.md"
EC=$(run_hook pre-compact.sh "$T")
if [ "$EC" = "0" ] && grep -q 'Phase: 99 - sentinel phase' "$T/.out" && grep -q 'sentinel-task' "$T/.out"; then
  test_pass; else test_fail "did not surface phase/task (ec=$EC out=$(tr '\n' '|' < "$T/.out"))"; fi
teardown "$T"

# ---- pre-compact.sh: graceful when project state absent (no crash, exit 0 + banner) ----
test_start "pre-compact: graceful with no project state (still exits 0 + banner)"
T=$(mktemp -d)
EC=$(run_hook pre-compact.sh "$T")
if [ "$EC" = "0" ] && grep -q 'Pre-Compaction State Snapshot' "$T/.out"; then
  test_pass; else test_fail "crashed or no banner without state (ec=$EC)"; fi
teardown "$T"

# ---- post-compact.sh: REMOVES the .context-warned flag (load-bearing side-effect) ----
test_start "post-compact: removes .claude/.context-warned flag"
T=$(mktemp -d); mkdir -p "$T/.claude"; touch "$T/.claude/.context-warned"
EC=$(run_hook post-compact.sh "$T")
if [ "$EC" = "0" ] && [ ! -f "$T/.claude/.context-warned" ]; then
  test_pass; else test_fail "did not remove .context-warned (ec=$EC still_present=$([ -f "$T/.claude/.context-warned" ] && echo yes || echo no))"; fi
teardown "$T"

# ---- post-compact.sh: graceful with no .claude (emits recovery banner, exit 0) ----
test_start "post-compact: graceful with no .claude (recovery banner present)"
T=$(mktemp -d)
EC=$(run_hook post-compact.sh "$T")
if [ "$EC" = "0" ] && grep -q 'Context was compacted' "$T/.out"; then
  test_pass; else test_fail "no recovery banner / crashed (ec=$EC)"; fi
teardown "$T"

# ---- session-stop.sh: WRITES .dev-wiki/.session-end with 'ended:' (load-bearing side-effect) ----
test_start "session-stop: writes .dev-wiki/.session-end containing 'ended:'"
T=$(mktemp -d); mkdir -p "$T/.dev-wiki"
EC=$(run_hook session-stop.sh "$T")
if [ "$EC" = "0" ] && [ -f "$T/.dev-wiki/.session-end" ] && grep -q '^ended:' "$T/.dev-wiki/.session-end"; then
  test_pass; else test_fail "no .session-end with ended: (ec=$EC)"; fi
teardown "$T"

# ---- session-stop.sh: graceful with no .dev-wiki (no breadcrumb written, exit 0) ----
test_start "session-stop: graceful with no .dev-wiki (no breadcrumb)"
T=$(mktemp -d)
EC=$(run_hook session-stop.sh "$T")
if [ "$EC" = "0" ] && [ ! -f "$T/.dev-wiki/.session-end" ]; then
  test_pass; else test_fail "wrote breadcrumb without .dev-wiki or crashed (ec=$EC)"; fi
teardown "$T"

# ---- check-tests-were-run.sh: ALLOW branch (py touched + pytest ran) -> exit 0 + allow record ----
# (the BLOCK branch is already covered in test_firing_log.sh; this completes the exit-0 paths.)
test_start "check-tests: allow path emits an allow record (py changed + pytest ran)"
T=$(mktemp -d); mkdir -p "$T/.dev-wiki" "$T/.claude/rules"; printf 'Phase: 99 - x\n' > "$T/.claude/rules/active-phase.md"
EC=$(run_hook check-tests-were-run.sh "$T" '{"tool_uses":[{"input":{"file_path":"src/x.py"}},{"input":{"command":"uv run pytest -x"}}]}')
LINE=$(tail -n1 "$T/.dev-wiki/enforcement.log" 2>/dev/null || echo "")
if [ "$EC" = "0" ] && printf '%s' "$LINE" | jq -e '(.hook=="check-tests-were-run") and (.action=="allow")' >/dev/null 2>&1; then
  test_pass; else test_fail "no allow record (ec=$EC line=$LINE)"; fi
teardown "$T"

# ---- check-tests-were-run.sh: SKIP branch (no .py touched) -> exit 0 + skipped record ----
test_start "check-tests: skip path emits a skipped record (no .py touched)"
T=$(mktemp -d); mkdir -p "$T/.dev-wiki" "$T/.claude/rules"; printf 'Phase: 99 - x\n' > "$T/.claude/rules/active-phase.md"
EC=$(run_hook check-tests-were-run.sh "$T" '{"tool_uses":[{"input":{"file_path":"README.md"}}]}')
LINE=$(tail -n1 "$T/.dev-wiki/enforcement.log" 2>/dev/null || echo "")
if [ "$EC" = "0" ] && printf '%s' "$LINE" | jq -e '(.action=="skipped")' >/dev/null 2>&1; then
  test_pass; else test_fail "no skipped record (ec=$EC line=$LINE)"; fi
teardown "$T"

# ---- py-review-stop.sh: PLANNING path (no .py touched) -> exit 0, no review prompt, skipped record ----
# (Phase 74: replaces the old unconditional py-review-stop-prompt.md prompt hook that looped during planning.)
test_start "py-review: planning path (no .py touched) exits 0 with no review prompt"
T=$(mktemp -d); mkdir -p "$T/.dev-wiki" "$T/.claude/rules"; printf 'Phase: 99 - x\n' > "$T/.claude/rules/active-phase.md"
EC=$(run_hook py-review-stop.sh "$T" '{"stop_hook_active":false,"tool_uses":[{"input":{"file_path":".dev-wiki/tasks.md"}},{"input":{"command":"uv run ruff check ."}}]}')
LINE=$(tail -n1 "$T/.dev-wiki/enforcement.log" 2>/dev/null || echo "")
if [ "$EC" = "0" ] && ! grep -q 'nana:review' "$T/.err" && printf '%s' "$LINE" | jq -e '(.hook=="py-review") and (.action=="skipped")' >/dev/null 2>&1; then
  test_pass; else test_fail "planning path should exit 0 silent + skipped record (ec=$EC err=$(tr '\n' '|' < "$T/.err") line=$LINE)"; fi
teardown "$T"

# ---- py-review-stop.sh: CODE-CHANGED path (.py touched, first stop) -> exit 2 + review prompt + block record ----
test_start "py-review: code-changed path (.py touched, first stop) exits 2 with review prompt"
T=$(mktemp -d); mkdir -p "$T/.dev-wiki" "$T/.claude/rules"; printf 'Phase: 99 - x\n' > "$T/.claude/rules/active-phase.md"
EC=$(run_hook py-review-stop.sh "$T" '{"stop_hook_active":false,"tool_uses":[{"input":{"file_path":"src/pkg/loader.py"}}]}')
LINE=$(tail -n1 "$T/.dev-wiki/enforcement.log" 2>/dev/null || echo "")
if [ "$EC" = "2" ] && grep -q 'nana:review' "$T/.err" && printf '%s' "$LINE" | jq -e '(.hook=="py-review") and (.action=="block")' >/dev/null 2>&1; then
  test_pass; else test_fail "code-changed path should exit 2 + review prompt + block record (ec=$EC err=$(tr '\n' '|' < "$T/.err") line=$LINE)"; fi
teardown "$T"

# ---- py-review-stop.sh: LOOP GUARD (stop_hook_active=true) -> exit 0 even with .py changed (no infinite stop loop) ----
test_start "py-review: loop guard (stop_hook_active=true) exits 0 even with .py changed"
T=$(mktemp -d); mkdir -p "$T/.dev-wiki" "$T/.claude/rules"; printf 'Phase: 99 - x\n' > "$T/.claude/rules/active-phase.md"
EC=$(run_hook py-review-stop.sh "$T" '{"stop_hook_active":true,"tool_uses":[{"input":{"file_path":"src/pkg/loader.py"}}]}')
if [ "$EC" = "0" ] && ! grep -q 'nana:review' "$T/.err"; then
  test_pass; else test_fail "loop guard should exit 0 silent (ec=$EC err=$(tr '\n' '|' < "$T/.err"))"; fi
teardown "$T"

# ---- Phase 82: REAL Stop-event shape (transcript_path, no tool_uses) ----
# Stop events never carried .tool_uses — the hooks only ever acted on fabricated fixtures.
# These pipe the real shape: a transcript JSONL the hook must scan for tool_use inputs.

make_transcript() {  # $1 = dir; writes transcript.jsonl WITHOUT pytest
  printf '%s\n' \
    '{"type":"user","message":{"content":"go"}}' \
    '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"src/mod.py"}}]}}' \
    > "$1/transcript.jsonl"
}

test_start "check-tests: REAL shape — py edit in transcript, no pytest -> block (exit 2)"
T=$(mktemp -d); mkdir -p "$T/.dev-wiki" "$T/.claude/rules"; printf 'Phase: 99 - x\n' > "$T/.claude/rules/active-phase.md"
make_transcript "$T"
EC=$(run_hook check-tests-were-run.sh "$T" "{\"stop_hook_active\":false,\"transcript_path\":\"$T/transcript.jsonl\"}")
if [ "$EC" = "2" ]; then test_pass; else test_fail "real Stop shape should block (ec=$EC)"; fi
teardown "$T"

test_start "check-tests: REAL shape — pytest in transcript -> allow (exit 0)"
T=$(mktemp -d); mkdir -p "$T/.dev-wiki" "$T/.claude/rules"; printf 'Phase: 99 - x\n' > "$T/.claude/rules/active-phase.md"
make_transcript "$T"
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"uv run pytest -q"}}]}}' >> "$T/transcript.jsonl"
EC=$(run_hook check-tests-were-run.sh "$T" "{\"stop_hook_active\":false,\"transcript_path\":\"$T/transcript.jsonl\"}")
if [ "$EC" = "0" ]; then test_pass; else test_fail "pytest in transcript should allow (ec=$EC)"; fi
teardown "$T"

test_start "py-review: REAL shape — py edit in transcript -> review requested (exit 2)"
T=$(mktemp -d); mkdir -p "$T/.dev-wiki" "$T/.claude/rules"; printf 'Phase: 99 - x\n' > "$T/.claude/rules/active-phase.md"
make_transcript "$T"
EC=$(run_hook py-review-stop.sh "$T" "{\"stop_hook_active\":false,\"transcript_path\":\"$T/transcript.jsonl\"}")
if [ "$EC" = "2" ] && grep -q 'nana:review' "$T/.err"; then
  test_pass; else test_fail "real Stop shape should request review (ec=$EC)"; fi
teardown "$T"

test_summary "long-cadence-hooks"
