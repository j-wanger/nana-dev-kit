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

test_start "--core-only does NOT install ts-init"
if [ ! -d "$THOME_FLAGS/.claude/skills/ts-init" ]; then
  test_pass
else
  test_fail "ts-init present under --core-only"
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

test_start "--no-python still installs ts-init"
assert_file_exists "$THOME_NP/.claude/skills/ts-init/SKILL.md"

rm -rf "$THOME_NP"

# --no-typescript flag
THOME_NT=$(mktemp -d)

test_start "--no-typescript installs py-init"
env HOME="$THOME_NT" bash "$PROJECT_ROOT/install.sh" --no-typescript >/dev/null 2>&1
assert_file_exists "$THOME_NT/.claude/skills/py-init/SKILL.md"

test_start "--no-typescript does NOT install ts-init"
if [ ! -d "$THOME_NT/.claude/skills/ts-init" ]; then
  test_pass
else
  test_fail "ts-init present under --no-typescript"
fi

rm -rf "$THOME_NT"

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

test_start "full install creates ts-init skill"
assert_file_exists "$THOME_ALL/.claude/skills/ts-init/SKILL.md"

test_start "full install copies ts-init scanner companion"
assert_file_exists "$THOME_ALL/.claude/skills/ts-init/scanner.md"

test_start "full install copies ts-init transform companion"
assert_file_exists "$THOME_ALL/.claude/skills/ts-init/transform.md"

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

test_start "full install creates post-commit hook"
assert_file_exists "$THOME_ALL/.claude/hooks/post-commit.sh"

test_start "full install registers post-commit in settings.json"
if grep -q 'post-commit.sh' "$THOME_ALL/.claude/settings.json" 2>/dev/null; then
  test_pass
else
  test_fail "post-commit not registered in settings.json"
fi

test_start "full install creates enforce-memory hook"
assert_file_exists "$THOME_ALL/.claude/hooks/enforce-memory.sh"

test_start "full install creates enforce-memory marker"
assert_file_exists "$THOME_ALL/.claude/enforce-memory"

test_start "full install registers enforce-memory in settings.json"
if grep -q 'enforce-memory.sh' "$THOME_ALL/.claude/settings.json" 2>/dev/null; then
  test_pass
else
  test_fail "enforce-memory not registered in settings.json"
fi

# --- Phase 36 backports: 5 new global hooks ---
for backport in context-size-check dev-wiki-scope-check post-compact session-stop stale-queue; do
  test_start "full install creates $backport hook"
  assert_file_exists "$THOME_ALL/.claude/hooks/${backport}.sh"

  test_start "full install registers $backport in settings.json"
  if grep -q "${backport}.sh" "$THOME_ALL/.claude/settings.json" 2>/dev/null; then
    test_pass
  else
    test_fail "$backport not registered in settings.json"
  fi
done

test_start "all settings.json hook entries use nested schema (matcher + hooks array)"
SCHEMA_OK=$(python3 -c "
import json
with open('$THOME_ALL/.claude/settings.json') as f: d=json.load(f)
bad=[(ev,i,e) for ev,es in d.get('hooks',{}).items() for i,e in enumerate(es) if 'hooks' not in e or not isinstance(e['hooks'],list)]
print('OK' if not bad else 'BAD: ' + repr(bad))
")
if [ "$SCHEMA_OK" = "OK" ]; then
  test_pass
else
  test_fail "$SCHEMA_OK"
fi

test_start "install removes superseded dev-wiki-post-commit.sh"
# Pre-populate the file to confirm install.sh removes it
touch "$THOME_ALL/.claude/hooks/dev-wiki-post-commit.sh"
HOME="$THOME_ALL" bash "$PROJECT_ROOT/install.sh" >/dev/null 2>&1
if [ ! -f "$THOME_ALL/.claude/hooks/dev-wiki-post-commit.sh" ]; then
  test_pass
else
  test_fail "dev-wiki-post-commit.sh still present after install"
fi

test_start "install migrates flat-shape settings.json entries to nested"
THOME_MIGRATE=$(mktemp -d)
mkdir -p "$THOME_MIGRATE/.claude/hooks"
cat > "$THOME_MIGRATE/.claude/settings.json" <<'EOF'
{"hooks":{"PreToolUse":[{"matcher":"Write|Edit","command":"/legacy/enforce-spec.sh"}],"Stop":[{"command":"/legacy/enforce-loop.sh"}]}}
EOF
HOME="$THOME_MIGRATE" bash "$PROJECT_ROOT/install.sh" >/dev/null 2>&1
MIGRATE_OK=$(python3 -c "
import json
with open('$THOME_MIGRATE/.claude/settings.json') as f: d=json.load(f)
bad=[(ev,i,e) for ev,es in d.get('hooks',{}).items() for i,e in enumerate(es) if 'hooks' not in e]
print('OK' if not bad else 'BAD: ' + repr(bad))
")
if [ "$MIGRATE_OK" = "OK" ]; then
  test_pass
else
  test_fail "flat-shape entries not migrated: $MIGRATE_OK"
fi
rm -rf "$THOME_MIGRATE"

rm -rf "$THOME_ALL"

# --- --project-local mode ---
test_start "--project-local installs to .claude/hooks/ in CWD"
TPROJ=$(mktemp -d)
(cd "$TPROJ" && bash "$PROJECT_ROOT/install.sh" --project-local >/dev/null 2>&1)
assert_file_exists "$TPROJ/.claude/hooks/audit-log.sh"
assert_file_exists "$TPROJ/.claude/hooks/auto-ruff-format.sh"
assert_file_exists "$TPROJ/.claude/hooks/block-dangerous-bash.sh"
assert_file_exists "$TPROJ/.claude/hooks/check-tests-were-run.sh"
assert_file_exists "$TPROJ/.claude/hooks/scan-secrets.sh"
assert_file_exists "$TPROJ/.claude/hooks/session-start.sh"

test_start "--project-local writes settings.local.json with nested schema"
if [ -f "$TPROJ/.claude/settings.local.json" ]; then
  PROJ_SCHEMA=$(python3 -c "
import json
with open('$TPROJ/.claude/settings.local.json') as f: d=json.load(f)
bad=[(ev,i,e) for ev,es in d.get('hooks',{}).items() for i,e in enumerate(es) if 'hooks' not in e or not isinstance(e['hooks'],list)]
print('OK' if not bad else 'BAD: ' + repr(bad))
")
  if [ "$PROJ_SCHEMA" = "OK" ]; then
    test_pass
  else
    test_fail "$PROJ_SCHEMA"
  fi
else
  test_fail "settings.local.json not created"
fi

test_start "--project-local does NOT touch global ~/.claude/"
GLOBAL_PRE=$(ls -la "$TPROJ/global-pre" 2>/dev/null || echo "empty")
TPROJ_GLOBAL=$(mktemp -d)
(cd "$TPROJ" && HOME="$TPROJ_GLOBAL" bash "$PROJECT_ROOT/install.sh" --project-local >/dev/null 2>&1)
if [ ! -d "$TPROJ_GLOBAL/.claude/hooks" ]; then
  test_pass
else
  test_fail "--project-local wrote to global HOME"
fi
rm -rf "$TPROJ" "$TPROJ_GLOBAL"

# --- --status flag ---
test_start "--status shows skills count"
THOME_STATUS=$(mktemp -d)
HOME="$THOME_STATUS" bash "$PROJECT_ROOT/install.sh" >/dev/null 2>&1
STATUS_OUT=$(HOME="$THOME_STATUS" bash "$PROJECT_ROOT/install.sh" --status 2>&1)
if echo "$STATUS_OUT" | grep -q 'skills'; then
  test_pass
else
  test_fail "--status missing skills line"
fi

test_start "--status shows hooks count"
if echo "$STATUS_OUT" | grep -q 'hooks'; then
  test_pass
else
  test_fail "--status missing hooks line"
fi

test_start "--status shows version"
if echo "$STATUS_OUT" | grep -q 'version'; then
  test_pass
else
  test_fail "--status missing version line"
fi

test_start "--status exits 0"
assert_exit_code 0 env HOME="$THOME_STATUS" bash "$PROJECT_ROOT/install.sh" --status
rm -rf "$THOME_STATUS"

test_summary "test_install"
