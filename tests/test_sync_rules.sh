#!/usr/bin/env bash
# Tests for sync-rules.sh — output files, headers, content propagation, error cases.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/helpers.sh"

echo "=== test_sync_rules.sh ==="

TDIR=$(mktemp -d)
trap 'rm -rf "$TDIR"' EXIT

SAMPLE_CONTENT="# Sample Project

This is a test AGENTS.md file."

echo "$SAMPLE_CONTENT" > "$TDIR/AGENTS.md"
bash "$PROJECT_ROOT/scripts/sync-rules.sh" "$TDIR" "$TDIR"

# Output files exist
test_start "creates CLAUDE.md"
assert_file_exists "$TDIR/CLAUDE.md"

test_start "creates copilot-instructions.md"
assert_file_exists "$TDIR/.github/copilot-instructions.md"

test_start "creates .cursor/rules/main.mdc"
assert_file_exists "$TDIR/.cursor/rules/main.mdc"

test_start "creates GEMINI.md"
assert_file_exists "$TDIR/GEMINI.md"

# AUTO-GENERATED headers
test_start "CLAUDE.md has AUTO-GENERATED header"
assert_contains "$TDIR/CLAUDE.md" "AUTO-GENERATED"

test_start "GEMINI.md has AUTO-GENERATED header"
assert_contains "$TDIR/GEMINI.md" "AUTO-GENERATED"

test_start "copilot-instructions.md has AUTO-GENERATED header"
assert_contains "$TDIR/.github/copilot-instructions.md" "AUTO-GENERATED"

test_start "Cursor main.mdc has AUTO-GENERATED header"
assert_contains "$TDIR/.cursor/rules/main.mdc" "AUTO-GENERATED"

# Content propagation
test_start "CLAUDE.md contains source content"
assert_contains "$TDIR/CLAUDE.md" "Sample Project"

test_start "GEMINI.md contains source content"
assert_contains "$TDIR/GEMINI.md" "Sample Project"

test_start "copilot-instructions.md contains source content"
assert_contains "$TDIR/.github/copilot-instructions.md" "Sample Project"

test_start "Cursor main.mdc contains source content"
assert_contains "$TDIR/.cursor/rules/main.mdc" "Sample Project"

# Cursor frontmatter
test_start "Cursor main.mdc has YAML frontmatter"
assert_contains "$TDIR/.cursor/rules/main.mdc" "alwaysApply: true"

# Error case: missing AGENTS.md
test_start "exits non-zero when AGENTS.md missing"
EDIR=$(mktemp -d)
assert_exit_code 1 bash "$PROJECT_ROOT/scripts/sync-rules.sh" "$EDIR" "$EDIR"
rm -rf "$EDIR"

# Edge case: unwritable target directory
test_start "exits non-zero on unwritable target"
WDIR=$(mktemp -d)
echo "# Test" > "$WDIR/AGENTS.md"
WDIR2=$(mktemp -d)
chmod a-w "$WDIR2"
assert_exit_code 1 bash "$PROJECT_ROOT/scripts/sync-rules.sh" "$WDIR" "$WDIR2"
chmod u+w "$WDIR2"
rm -rf "$WDIR" "$WDIR2"

test_start "reports error on unwritable target"
WDIR=$(mktemp -d)
echo "# Test" > "$WDIR/AGENTS.md"
WDIR2=$(mktemp -d)
chmod a-w "$WDIR2"
ERR_OUTPUT=$(bash "$PROJECT_ROOT/scripts/sync-rules.sh" "$WDIR" "$WDIR2" 2>&1 || true)
chmod u+w "$WDIR2"
rm -rf "$WDIR" "$WDIR2"
if echo "$ERR_OUTPUT" | grep -qi 'error.*writ\|not writable'; then
  test_pass
else
  test_fail "no writability error in output"
fi

test_summary "test_sync_rules"
