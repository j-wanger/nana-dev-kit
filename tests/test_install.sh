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

test_start "creates adversarial-constraints-prompt.md"
assert_file_exists "$THOME/.claude/skills/spec/adversarial-constraints-prompt.md"

test_start "creates file-lifecycle.md"
assert_file_exists "$THOME/.claude/rules/file-lifecycle.md"

# Second run — idempotency
cp "$THOME/.claude/rules/nana-soul.md" "$THOME/nana-first"
cp "$THOME/.claude/skills/py-init/SKILL.md" "$THOME/skill-first"

test_start "install.sh exits 0 on second run"
assert_exit_code 0 env HOME="$THOME" bash "$PROJECT_ROOT/install.sh"

test_start "nana-soul.md identical after second run"
assert_exit_code 0 diff "$THOME/nana-first" "$THOME/.claude/rules/nana-soul.md"

test_start "SKILL.md identical after second run"
assert_exit_code 0 diff "$THOME/skill-first" "$THOME/.claude/skills/py-init/SKILL.md"

test_start "personal profile not overwritten on re-install"
echo "# Custom user profile" > "$THOME/.claude/rules/nana-personal.md"
env HOME="$THOME" bash "$PROJECT_ROOT/install.sh" >/dev/null 2>&1
if grep -q 'Custom user profile' "$THOME/.claude/rules/nana-personal.md"; then
  test_pass
else
  test_fail "personal profile was overwritten"
fi

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

# --- Module flags ---
THOME_FLAGS=$(mktemp -d)

test_start "--dry-run does not create files"
env HOME="$THOME_FLAGS" bash "$PROJECT_ROOT/install.sh" --dry-run >/dev/null 2>&1
if [ ! -d "$THOME_FLAGS/.claude/skills" ]; then
  test_pass
else
  test_fail "dry-run created files"
fi

test_start "--dry-run mentions dev-plan"
DRY_OUTPUT=$(env HOME="$THOME_FLAGS" bash "$PROJECT_ROOT/install.sh" --dry-run 2>&1)
if echo "$DRY_OUTPUT" | grep -q 'dev-plan'; then
  test_pass
else
  test_fail "--dry-run output missing dev-plan"
fi

test_start "--core-only installs spec"
env HOME="$THOME_FLAGS" bash "$PROJECT_ROOT/install.sh" --core-only >/dev/null 2>&1
assert_file_exists "$THOME_FLAGS/.claude/skills/spec/SKILL.md"

test_start "--core-only does NOT install dev-plan"
if [ ! -d "$THOME_FLAGS/.claude/skills/dev-plan" ]; then
  test_pass
else
  test_fail "dev-plan present under --core-only"
fi

test_start "--core-only does NOT install wiki-query"
if [ ! -d "$THOME_FLAGS/.claude/skills/wiki-query" ]; then
  test_pass
else
  test_fail "wiki-query present under --core-only"
fi

test_start "--core-only does NOT install py-init"
if [ ! -d "$THOME_FLAGS/.claude/skills/py-init" ]; then
  test_pass
else
  test_fail "py-init present under --core-only"
fi

test_start "--core-only does NOT install enforce hooks"
if [ ! -f "$THOME_FLAGS/.claude/hooks/enforce-spec.sh" ] && [ ! -f "$THOME_FLAGS/.claude/enforce" ]; then
  test_pass
else
  test_fail "enforce hooks present under --core-only"
fi

rm -rf "$THOME_FLAGS"

THOME_NP=$(mktemp -d)

test_start "--no-python installs dev-plan"
env HOME="$THOME_NP" bash "$PROJECT_ROOT/install.sh" --no-python >/dev/null 2>&1
assert_file_exists "$THOME_NP/.claude/skills/dev-plan/SKILL.md"

test_start "--no-python installs wiki-query"
assert_file_exists "$THOME_NP/.claude/skills/wiki-query/SKILL.md"

test_start "--no-python does NOT install py-init"
if [ ! -d "$THOME_NP/.claude/skills/py-init" ]; then
  test_pass
else
  test_fail "py-init present under --no-python"
fi

rm -rf "$THOME_NP"

# Full install with all modules
THOME_ALL=$(mktemp -d)

test_start "full install creates dev-plan skill"
env HOME="$THOME_ALL" bash "$PROJECT_ROOT/install.sh" >/dev/null 2>&1
assert_file_exists "$THOME_ALL/.claude/skills/dev-plan/SKILL.md"

test_start "full install copies spec-auto-invoke.md companion"
assert_file_exists "$THOME_ALL/.claude/skills/dev-plan/spec-auto-invoke.md"

test_start "full install creates wiki-query skill"
assert_file_exists "$THOME_ALL/.claude/skills/wiki-query/SKILL.md"

test_start "full install creates dev-wiki skill"
assert_file_exists "$THOME_ALL/.claude/skills/dev-wiki/SKILL.md"

test_start "full install creates knowledge-wiki skill"
assert_file_exists "$THOME_ALL/.claude/skills/knowledge-wiki/SKILL.md"

test_start "full install creates dev-debrief skill"
assert_file_exists "$THOME_ALL/.claude/skills/dev-debrief/SKILL.md"

test_start "full install creates wiki-init skill"
assert_file_exists "$THOME_ALL/.claude/skills/wiki-init/SKILL.md"

test_start "full install creates enforce-spec hook"
assert_file_exists "$THOME_ALL/.claude/hooks/enforce-spec.sh"

test_start "full install creates enforce-loop hook"
assert_file_exists "$THOME_ALL/.claude/hooks/enforce-loop.sh"

test_start "full install creates enforce marker"
assert_file_exists "$THOME_ALL/.claude/enforce"

test_start "full install registers hooks in settings.json"
if grep -q 'enforce-spec.sh' "$THOME_ALL/.claude/settings.json" 2>/dev/null && grep -q 'enforce-loop.sh' "$THOME_ALL/.claude/settings.json" 2>/dev/null; then
  test_pass
else
  test_fail "hooks not registered in settings.json"
fi

test_start "full install creates pre-compact hook"
assert_file_exists "$THOME_ALL/.claude/hooks/pre-compact.sh"

test_start "full install registers PreCompact in settings.json"
if grep -q 'pre-compact.sh' "$THOME_ALL/.claude/settings.json" 2>/dev/null && grep -q 'PreCompact' "$THOME_ALL/.claude/settings.json" 2>/dev/null; then
  test_pass
else
  test_fail "PreCompact not registered in settings.json"
fi

rm -rf "$THOME_ALL"

test_summary "test_install"
