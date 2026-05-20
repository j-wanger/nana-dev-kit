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

test_start "creates spec SKILL.md"
assert_file_exists "$THOME/.claude/skills/spec/SKILL.md"

test_start "creates spec-reviewer-prompt.md"
assert_file_exists "$THOME/.claude/skills/spec/spec-reviewer-prompt.md"

# Second run — idempotency
cp "$THOME/.claude/rules/nana-soul.md" "$THOME/nana-first"
cp "$THOME/.claude/skills/py-init/SKILL.md" "$THOME/skill-first"

test_start "install.sh exits 0 on second run"
assert_exit_code 0 env HOME="$THOME" bash "$PROJECT_ROOT/install.sh"

test_start "nana-soul.md identical after second run"
assert_exit_code 0 diff "$THOME/nana-first" "$THOME/.claude/rules/nana-soul.md"

test_start "SKILL.md identical after second run"
assert_exit_code 0 diff "$THOME/skill-first" "$THOME/.claude/skills/py-init/SKILL.md"

# MCP server registration
test_start "creates memory_server directory"
assert_file_exists "$THOME/.claude/memory_server/server.py"

test_start "registers mcpServers in settings.json"
if [ -f "$THOME/.claude/settings.json" ] && python3 -c "import json; d=json.load(open('$THOME/.claude/settings.json')); assert 'mcpServers' in d" 2>/dev/null; then
  test_pass
else
  test_fail "mcpServers not in settings.json"
fi

test_start "preserves existing settings.json on merge"
THOME2=$(mktemp -d)
mkdir -p "$THOME2/.claude"
echo '{"existingKey": "preserved"}' > "$THOME2/.claude/settings.json"
env HOME="$THOME2" bash "$PROJECT_ROOT/install.sh" >/dev/null 2>&1
if python3 -c "import json; d=json.load(open('$THOME2/.claude/settings.json')); assert d.get('existingKey') == 'preserved'" 2>/dev/null; then
  test_pass
else
  test_fail "existing content not preserved"
fi
rm -rf "$THOME2"

test_start "MCP registration idempotent"
env HOME="$THOME" bash "$PROJECT_ROOT/install.sh" >/dev/null 2>&1
if python3 -c "import json; d=json.load(open('$THOME/.claude/settings.json')); assert 'mcpServers' in d" 2>/dev/null; then
  test_pass
else
  test_fail "mcpServers missing after second run"
fi

# Memory server venv bootstrap
test_start "creates memory_server venv"
assert_file_exists "$THOME/.claude/memory_server/.venv/bin/python3"

test_start "MCP config uses venv Python"
if python3 -c "
import json
d = json.load(open('$THOME/.claude/settings.json'))
cmd = d['mcpServers']['memory']['command']
assert '.venv/bin/python3' in cmd, f'expected venv python, got {cmd}'
" 2>/dev/null; then
  test_pass
else
  test_fail "MCP config does not point to venv Python"
fi

# Edge case: missing SKILL.md source (currently swallowed by || true)
test_start "exits non-zero when SKILL.md source is missing"
ETEMP=$(mktemp -d)
cp "$PROJECT_ROOT/install.sh" "$ETEMP/"
mkdir -p "$ETEMP/templates/.claude/rules"
cp "$PROJECT_ROOT/templates/.claude/rules/nana-soul.md" "$ETEMP/templates/.claude/rules/"
assert_exit_code 1 env HOME="$THOME" bash "$ETEMP/install.sh"
rm -rf "$ETEMP"

# Edge case: clear error message when source files missing
test_start "reports error when source files missing"
ETEMP=$(mktemp -d)
cp "$PROJECT_ROOT/install.sh" "$ETEMP/"
ERR_OUTPUT=$(env HOME="$THOME" bash "$ETEMP/install.sh" 2>&1 || true)
rm -rf "$ETEMP"
if echo "$ERR_OUTPUT" | grep -qi 'error'; then
  test_pass
else
  test_fail "no error message in output"
fi

test_summary "test_install"
