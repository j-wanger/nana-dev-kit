#!/usr/bin/env bash
# Phase 67 — firing tests for the registered Pre/PostToolUse + UserPromptSubmit hooks that lacked one.
# Each asserts a LOAD-BEARING SIDE-EFFECT (exit-2 block, stderr warning, or a file write), never exit
# code alone, and pairs a positive firing with a negative branch so a no-op/always-fire hook fails.
# Isolated fixtures (own HOME + cwd, never a git repo) keep hooks off the kit's own .dev-wiki/.nana.
# fires: scan-secrets.sh block-dangerous-bash.sh auto-ruff-format.sh stale-queue.sh post-commit.sh context-size-check.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS="$REPO_ROOT/templates/.claude/hooks"
ORIG_HOME="$HOME"

teardown() { export HOME="$ORIG_HOME"; chmod -R u+rwx "$1" 2>/dev/null || true; rm -rf "$1"; }
run_hook() {  # hook fixture json -> echo exit code; stdout->$fx/.out stderr->$fx/.err
  local hook="$1" fx="$2" json="${3:-}"; local ec=0
  printf '%s' "$json" | HOME="$fx" bash -c "cd '$fx' && bash '$HOOKS/$hook'" >"$fx/.out" 2>"$fx/.err" || ec=$?
  echo "$ec"
}

echo "=== Phase 67 Pre/PostToolUse Hook Firing Tests ==="

# ---- scan-secrets.sh (PostToolUse): warns on a hardcoded secret, silent on a clean file ----
# Secret crafted to trip BOTH paths: the fallback grep (api_key=...) when gitleaks is absent, and the
# gitleaks AWS rule (AKIA...) when it is present — so the warning is deterministic either way.
test_start "scan-secrets: warns on a file containing a hardcoded secret"
T=$(mktemp -d)
printf 'api_key = "AbCdEf0123456789ghIjKl"\naws_key = "AKIA1234567890ABCDEF"\n' > "$T/leak.py"
EC=$(run_hook scan-secrets.sh "$T" "{\"tool_input\":{\"file_path\":\"$T/leak.py\"}}")
if [ "$EC" = "0" ] && grep -q 'nana:secrets' "$T/.err"; then test_pass; else test_fail "no secret warning (ec=$EC err=$(cat "$T/.err"))"; fi
teardown "$T"

test_start "scan-secrets: silent on a clean file (not an always-warn no-op)"
T=$(mktemp -d); printf 'x = 1\nprint("hello world")\n' > "$T/clean.py"
EC=$(run_hook scan-secrets.sh "$T" "{\"tool_input\":{\"file_path\":\"$T/clean.py\"}}")
if [ "$EC" = "0" ] && ! grep -q 'nana:secrets' "$T/.err"; then test_pass; else test_fail "warned on clean file (ec=$EC err=$(cat "$T/.err"))"; fi
teardown "$T"

# ---- block-dangerous-bash.sh (PreToolUse, BLOCKING): exit 2 on rm -rf /, exit 0 on a safe command ----
test_start "block-dangerous-bash: blocks 'rm -rf /' (exit 2 + reason)"
T=$(mktemp -d)
EC=$(run_hook block-dangerous-bash.sh "$T" '{"input":{"command":"rm -rf /"}}')
if [ "$EC" = "2" ] && grep -q 'nana:block' "$T/.err"; then test_pass; else test_fail "did not block (ec=$EC err=$(cat "$T/.err"))"; fi
teardown "$T"

test_start "block-dangerous-bash: allows a safe command (exit 0, not always-block)"
T=$(mktemp -d)
EC=$(run_hook block-dangerous-bash.sh "$T" '{"input":{"command":"ls -la"}}')
if [ "$EC" = "0" ] && [ ! -s "$T/.err" ]; then test_pass; else test_fail "blocked a safe command (ec=$EC err=$(cat "$T/.err"))"; fi
teardown "$T"

# ---- auto-ruff-format.sh (PostToolUse): skips non-.py; formats .py iff ruff is available ----
test_start "auto-ruff-format: leaves a non-.py file untouched (exit 0)"
T=$(mktemp -d); printf 'x=1\n' > "$T/note.txt"; BEFORE=$(cat "$T/note.txt")
EC=$(run_hook auto-ruff-format.sh "$T" "{\"tool_input\":{\"file_path\":\"$T/note.txt\"}}")
if [ "$EC" = "0" ] && [ "$(cat "$T/note.txt")" = "$BEFORE" ]; then test_pass; else test_fail "mutated a non-py file or crashed (ec=$EC)"; fi
teardown "$T"

if command -v uv >/dev/null 2>&1 && uv run ruff --version >/dev/null 2>&1; then
  test_start "auto-ruff-format: formats a badly-spaced .py file (ruff available)"
  T=$(mktemp -d); printf 'x=1\n' > "$T/f.py"
  EC=$(run_hook auto-ruff-format.sh "$T" "{\"tool_input\":{\"file_path\":\"$T/f.py\"}}")
  if [ "$EC" = "0" ] && grep -q 'x = 1' "$T/f.py"; then test_pass; else test_fail "did not format (ec=$EC content=$(cat "$T/f.py"))"; fi
  teardown "$T"
else
  test_start "auto-ruff-format: graceful no-op on .py when ruff unavailable (exit 0, file intact)"
  echo "  (note: ruff unavailable in this env — the format side-effect is unasserted here)"
  T=$(mktemp -d); printf 'x=1\n' > "$T/f.py"
  EC=$(run_hook auto-ruff-format.sh "$T" "{\"tool_input\":{\"file_path\":\"$T/f.py\"}}")
  if [ "$EC" = "0" ] && [ "$(cat "$T/f.py")" = "x=1" ]; then test_pass; else test_fail "crashed or mutated without ruff (ec=$EC)"; fi
  teardown "$T"
fi

# ---- stale-queue.sh (PostToolUse): queues a source edit, skips a markdown edit ----
test_start "stale-queue: appends a changed source file to .dev-wiki/.stale-queue"
T=$(mktemp -d); mkdir -p "$T/.dev-wiki"
EC=$(run_hook stale-queue.sh "$T" "{\"tool_input\":{\"file_path\":\"$T/src/foo.py\"}}")
if [ "$EC" = "0" ] && [ -f "$T/.dev-wiki/.stale-queue" ] && grep -qxF 'src/foo.py' "$T/.dev-wiki/.stale-queue"; then
  test_pass; else test_fail "did not queue src/foo.py (ec=$EC queue=$(cat "$T/.dev-wiki/.stale-queue" 2>/dev/null))"; fi
teardown "$T"

test_start "stale-queue: skips a markdown edit (not queued)"
T=$(mktemp -d); mkdir -p "$T/.dev-wiki"
EC=$(run_hook stale-queue.sh "$T" "{\"tool_input\":{\"file_path\":\"$T/docs/readme.md\"}}")
if [ "$EC" = "0" ] && ! { [ -f "$T/.dev-wiki/.stale-queue" ] && grep -q 'readme.md' "$T/.dev-wiki/.stale-queue"; }; then
  test_pass; else test_fail "queued a markdown file (ec=$EC)"; fi
teardown "$T"

# ---- post-commit.sh (PostToolUse Bash): writes .pending-commit on a successful commit (opt-in) ----
test_start "post-commit: writes .dev-wiki/.pending-commit + trigger on a successful git commit"
T=$(mktemp -d); mkdir -p "$T/.claude" "$T/.dev-wiki"; touch "$T/.claude/enforce"
EC=$(run_hook post-commit.sh "$T" '{"tool_input":{"command":"git commit -m test"},"exit_code":0}')
if [ "$EC" = "0" ] && [ -f "$T/.dev-wiki/.pending-commit" ] && grep -q 'dev-wiki:post-commit' "$T/.out"; then
  test_pass; else test_fail "no .pending-commit / trigger (ec=$EC out=$(cat "$T/.out"))"; fi
teardown "$T"

test_start "post-commit: no-op without the enforce opt-in marker (not always-fire)"
T=$(mktemp -d); mkdir -p "$T/.dev-wiki"   # no .claude/enforce in HOME
EC=$(run_hook post-commit.sh "$T" '{"tool_input":{"command":"git commit -m test"},"exit_code":0}')
if [ "$EC" = "0" ] && [ ! -f "$T/.dev-wiki/.pending-commit" ]; then test_pass; else test_fail "fired without opt-in (ec=$EC)"; fi
teardown "$T"

# ---- context-size-check.sh (UserPromptSubmit): warns + sets flag past 5MB, silent below ----
test_start "context-size-check: warns + sets .context-warned when transcript exceeds 5MB"
T=$(mktemp -d); dd if=/dev/zero of="$T/transcript.jsonl" bs=1024 count=5200 2>/dev/null
EC=$(run_hook context-size-check.sh "$T" "{\"transcript_path\":\"$T/transcript.jsonl\"}")
if [ "$EC" = "0" ] && grep -q 'nana:context' "$T/.err" && [ -f "$T/.claude/.context-warned" ]; then
  test_pass; else test_fail "no warning/flag past 5MB (ec=$EC err=$(cat "$T/.err"))"; fi
teardown "$T"

test_start "context-size-check: silent for a small transcript (not always-warn)"
T=$(mktemp -d); printf 'tiny\n' > "$T/transcript.jsonl"
EC=$(run_hook context-size-check.sh "$T" "{\"transcript_path\":\"$T/transcript.jsonl\"}")
if [ "$EC" = "0" ] && ! grep -q 'nana:context' "$T/.err" && [ ! -f "$T/.claude/.context-warned" ]; then
  test_pass; else test_fail "warned on a small transcript (ec=$EC)"; fi
teardown "$T"

test_summary "tooluse-hooks"
