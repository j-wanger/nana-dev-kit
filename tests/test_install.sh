#!/usr/bin/env bash
# Tests for install.sh — idempotency, correct outputs, kit path content.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/helpers.sh"

echo "=== test_install.sh ==="

THOME=$(mktemp -d)
trap 'rm -rf "$THOME"' EXIT

# First run
test_start "install.sh exits 0 on first run"
assert_exit_code 0 env HOME="$THOME" bash "$PROJECT_ROOT/install.sh"

test_start "creates py-init SKILL.md"
assert_file_exists "$THOME/.claude/skills/py-init/SKILL.md"

test_start "creates nana-soul.md"
assert_file_exists "$THOME/.claude/rules/nana-soul.md"

test_start "creates .nana-dev-kit-path"
assert_file_exists "$THOME/.claude/.nana-dev-kit-path"

test_start "kit path points to project root"
assert_eq "$PROJECT_ROOT" "$(cat "$THOME/.claude/.nana-dev-kit-path")"

test_start "SKILL.md content matches source"
assert_exit_code 0 diff "$THOME/.claude/skills/py-init/SKILL.md" "$PROJECT_ROOT/templates/.claude/skills/py-init/SKILL.md"

test_start "nana-soul.md content matches source"
assert_exit_code 0 diff "$THOME/.claude/rules/nana-soul.md" "$PROJECT_ROOT/templates/.claude/rules/nana-soul.md"

# Second run — idempotency
cp "$THOME/.claude/rules/nana-soul.md" "$THOME/nana-first"
cp "$THOME/.claude/skills/py-init/SKILL.md" "$THOME/skill-first"

test_start "install.sh exits 0 on second run"
assert_exit_code 0 env HOME="$THOME" bash "$PROJECT_ROOT/install.sh"

test_start "nana-soul.md identical after second run"
assert_exit_code 0 diff "$THOME/nana-first" "$THOME/.claude/rules/nana-soul.md"

test_start "SKILL.md identical after second run"
assert_exit_code 0 diff "$THOME/skill-first" "$THOME/.claude/skills/py-init/SKILL.md"

test_summary "test_install"
