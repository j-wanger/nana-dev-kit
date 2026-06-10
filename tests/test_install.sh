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

test_start "MCP config cwd is parent of memory_server (not inside package)"
if python3 -c "
import json
d = json.load(open('$THOME/.claude/settings.json'))
cwd = d['mcpServers']['memory']['cwd']
assert not cwd.endswith('memory_server'), f'cwd inside package: {cwd}'
assert cwd.endswith('.claude'), f'cwd should end with .claude, got {cwd}'
" 2>/dev/null; then
  test_pass
else
  test_fail "MCP cwd points inside memory_server package (python -m will fail)"
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

test_start "full install creates nana-init skill"
assert_file_exists "$THOME_ALL/.claude/skills/nana-init/SKILL.md"

test_start "full install copies ts-init scanner companion"
assert_file_exists "$THOME_ALL/.claude/skills/ts-init/scanner.md"

test_start "full install copies ts-init transform companion"
assert_file_exists "$THOME_ALL/.claude/skills/ts-init/transform.md"

# Global install installs ONLY global-scoped hooks (context-size-check) + opt-in markers.
# Enforcement/lifecycle hooks are scope=project — verified in the --project-local block below.
test_start "full install creates global session hook (context-size-check)"
assert_file_exists "$THOME_ALL/.claude/hooks/context-size-check.sh"

test_start "full install registers context-size-check globally"
if grep -q 'context-size-check.sh' "$THOME_ALL/.claude/settings.json" 2>/dev/null && grep -q 'UserPromptSubmit' "$THOME_ALL/.claude/settings.json" 2>/dev/null; then
  test_pass
else
  test_fail "context-size-check not registered globally"
fi

test_start "full install creates enforce marker"
assert_file_exists "$THOME_ALL/.claude/enforce"

test_start "full install creates enforce-memory marker"
assert_file_exists "$THOME_ALL/.claude/enforce-memory"

test_start "full install does NOT install project-scoped enforcement hooks globally"
if [ ! -f "$THOME_ALL/.claude/hooks/enforce-spec.sh" ] && ! grep -q 'enforce-spec.sh' "$THOME_ALL/.claude/settings.json" 2>/dev/null; then
  test_pass
else
  test_fail "enforce-spec leaked into global install (should be project-scoped)"
fi

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
{"hooks":{"UserPromptSubmit":[{"command":"/legacy/context-size-check.sh"}]}}
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
# Enforcement/lifecycle hooks are project-scoped — they install here, not globally.
assert_file_exists "$TPROJ/.claude/hooks/enforce-spec.sh"
assert_file_exists "$TPROJ/.claude/hooks/enforce-loop.sh"
assert_file_exists "$TPROJ/.claude/hooks/enforce-memory.sh"
assert_file_exists "$TPROJ/.claude/hooks/pre-compact.sh"
assert_file_exists "$TPROJ/.claude/hooks/post-commit.sh"

test_start "--project-local registers enforcement hooks in settings.local.json"
if grep -q 'enforce-spec.sh' "$TPROJ/.claude/settings.local.json" 2>/dev/null && grep -q 'enforce-loop.sh' "$TPROJ/.claude/settings.local.json" 2>/dev/null; then
  test_pass
else
  test_fail "enforcement hooks not registered in settings.local.json"
fi

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

# --- Phase 67: the copied session-start.d curator chain must EXECUTE at the destination, not just land ---
# Closes the session-start.d author-global-drift roadmap item as a PERMANENT regression test (was a
# one-shot manual dogfood). A copy can succeed while dropping the +x bit or landing curators without the
# orchestrator that loops them — so assert the chain runs end-to-end, not just that bytes arrived.
test_start "--project-local copies the FULL session-start.d curator set (no partial copy)"
SRC_CUR=$(ls "$PROJECT_ROOT/templates/.claude/hooks/session-start.d"/*.sh 2>/dev/null | xargs -n1 basename | sort | tr '\n' ' ')
DST_CUR=$(ls "$TPROJ/.claude/hooks/session-start.d"/*.sh 2>/dev/null | xargs -n1 basename | sort | tr '\n' ' ')
assert_eq "$SRC_CUR" "$DST_CUR" "copied session-start.d set differs from source"

# --- Phase 85: hook_dirs shipping invariant (install-gap fix) ---
# Every install path that ships a hook script must also ship the companion dirs that script
# consumes (modules.json .hook_dirs) — and ONLY for scripts it actually ships. An empty source
# dir must NOT abort the installer under set -euo pipefail (incident-5 class: partial install).
# fires: session-start.sh   # via the shipped-curator existence assertions on real modules.json
HDKIT=$(mktemp -d)
cp "$PROJECT_ROOT/install.sh" "$HDKIT/"
cp -r "$PROJECT_ROOT/templates" "$HDKIT/templates"
cp -r "$PROJECT_ROOT/scripts" "$HDKIT/scripts"
cp -r "$PROJECT_ROOT/memory_server" "$HDKIT/memory_server"
printf '#!/bin/bash\nexit 0\n' > "$HDKIT/templates/.claude/hooks/fake-global.sh"
mkdir -p "$HDKIT/templates/.claude/hooks/fake-global.d"
printf 'echo curator\n' > "$HDKIT/templates/.claude/hooks/fake-global.d/curator.sh"
mkdir -p "$HDKIT/templates/.claude/hooks/empty.d"   # exists but EMPTY — the set -e glob trap
jq '.hooks += [{"event":"SessionStart","matcher":"","script":"fake-global.sh","scope":"global"}]
    | .hook_dirs."fake-global.sh" = ["fake-global.d","empty.d"]' \
  "$PROJECT_ROOT/modules.json" > "$HDKIT/modules.json"

THOME_HD=$(mktemp -d)
# Pre-seed a stub venv python so the core module skips the slow venv build (pip lines are ||-guarded).
mkdir -p "$THOME_HD/.claude/memory_server/.venv/bin"
printf '#!/bin/sh\nexit 0\n' > "$THOME_HD/.claude/memory_server/.venv/bin/python3"
chmod +x "$THOME_HD/.claude/memory_server/.venv/bin/python3"

test_start "global path ships hook_dirs for consumer scripts it ships (and tolerates an empty dir)"
if env HOME="$THOME_HD" bash "$HDKIT/install.sh" >/dev/null 2>&1 \
   && [ -f "$THOME_HD/.claude/hooks/fake-global.d/curator.sh" ]; then
  test_pass
else
  test_fail "fake-global.d/curator.sh not shipped by global path (or installer aborted on empty.d)"
fi

test_start "global path ships NO dirs for consumers it does not ship (session-start.sh is scope:project)"
if [ ! -d "$THOME_HD/.claude/hooks/session-start.d" ]; then
  test_pass
else
  test_fail "session-start.d shipped globally without its consumer script"
fi

test_start "--project-local tolerates an empty hook_dirs source dir (no set -e abort)"
TPROJ_HD=$(mktemp -d)
jq '.hook_dirs."session-start.sh" += ["empty.d"]' "$PROJECT_ROOT/modules.json" > "$HDKIT/modules.json"
if (cd "$TPROJ_HD" && bash "$HDKIT/install.sh" --project-local >/dev/null 2>&1) \
   && [ -f "$TPROJ_HD/.claude/hooks/session-start.d/wk-prune.sh" ]; then
  test_pass
else
  test_fail "--project-local aborted or skipped session-start.d when empty.d present in hook_dirs"
fi
rm -rf "$HDKIT" "$THOME_HD" "$TPROJ_HD"

test_start "--project-local: copied session-start.sh entry point is executable"
# session-start.sh is the EXECUTED hook entry point (install.sh chmod +x's it); the session-start.d
# curators are SOURCED by it (line 9-11), so they intentionally need no +x bit — don't assert it.
if [ -x "$TPROJ/.claude/hooks/session-start.sh" ]; then
  test_pass
else
  test_fail "copied session-start.sh entry point is not executable"
fi

test_start "--project-local: firing the copied session-start.sh runs the curator chain end-to-end"
# session-start.sh sources every session-start.d/*.sh under set -e (a missing/unsourceable curator ->
# non-zero exit), so exit 0 + a curator's marker proves the chain EXECUTES at the install destination.
# cognitive-readiness emits [nana:cognitive] (here, the uninitialized-project nudge).
SS_EC=0
SS_OUT=$(HOME="$TPROJ" bash -c "cd '$TPROJ' && bash .claude/hooks/session-start.sh" 2>/dev/null) || SS_EC=$?
if [ "$SS_EC" = "0" ] && printf '%s' "$SS_OUT" | grep -q 'nana:cognitive'; then
  test_pass
else
  test_fail "curator chain did not fire at destination (ec=$SS_EC out=$(printf '%s' "$SS_OUT" | tr '\n' '|'))"
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

test_start "--status shows install-drift line (Phase 76)"
if echo "$STATUS_OUT" | grep -qi 'drift'; then
  test_pass
else
  test_fail "--status missing drift line"
fi

test_start "--status exits 0"
assert_exit_code 0 env HOME="$THOME_STATUS" bash "$PROJECT_ROOT/install.sh" --status
rm -rf "$THOME_STATUS"

# --- Functional verification (Phase 38: post-install behavioral checks) ---
THOME_FN=$(mktemp -d)
env HOME="$THOME_FN" bash "$PROJECT_ROOT/install.sh" >/dev/null 2>&1

# Module isolation: --core-only installs nana but NOT py-lint
THOME_CORE=$(mktemp -d)
env HOME="$THOME_CORE" bash "$PROJECT_ROOT/install.sh" --core-only >/dev/null 2>&1

test_start "--core-only installs nana skill"
assert_file_exists "$THOME_CORE/.claude/skills/nana/SKILL.md"

test_start "--core-only installs memory-consolidate skill"
assert_file_exists "$THOME_CORE/.claude/skills/memory-consolidate/SKILL.md"

test_start "--core-only does NOT install py-lint"
if [ ! -d "$THOME_CORE/.claude/skills/py-lint" ]; then
  test_pass
else
  test_fail "py-lint present under --core-only"
fi

test_start "--core-only does NOT install py-review"
if [ ! -d "$THOME_CORE/.claude/skills/py-review" ]; then
  test_pass
else
  test_fail "py-review present under --core-only"
fi

test_start "--core-only does NOT install py-test"
if [ ! -d "$THOME_CORE/.claude/skills/py-test" ]; then
  test_pass
else
  test_fail "py-test present under --core-only"
fi
rm -rf "$THOME_CORE"

# Module isolation: --no-python excludes py-lint/py-review/py-test
THOME_NP2=$(mktemp -d)
env HOME="$THOME_NP2" bash "$PROJECT_ROOT/install.sh" --no-python >/dev/null 2>&1

test_start "--no-python does NOT install py-lint"
if [ ! -d "$THOME_NP2/.claude/skills/py-lint" ]; then
  test_pass
else
  test_fail "py-lint present under --no-python"
fi

test_start "--no-python does NOT install py-review"
if [ ! -d "$THOME_NP2/.claude/skills/py-review" ]; then
  test_pass
else
  test_fail "py-review present under --no-python"
fi

test_start "--no-python does NOT install py-test"
if [ ! -d "$THOME_NP2/.claude/skills/py-test" ]; then
  test_pass
else
  test_fail "py-test present under --no-python"
fi
rm -rf "$THOME_NP2"

# Full install has all 5 new skills
test_start "full install creates nana skill"
assert_file_exists "$THOME_FN/.claude/skills/nana/SKILL.md"

test_start "full install creates memory-consolidate skill"
assert_file_exists "$THOME_FN/.claude/skills/memory-consolidate/SKILL.md"

test_start "full install creates py-lint skill"
assert_file_exists "$THOME_FN/.claude/skills/py-lint/SKILL.md"

test_start "full install creates py-review skill"
assert_file_exists "$THOME_FN/.claude/skills/py-review/SKILL.md"

test_start "full install creates py-test skill"
assert_file_exists "$THOME_FN/.claude/skills/py-test/SKILL.md"

# Hook functional test: enforce-spec.sh parses .input.file_path correctly
test_start "enforce-spec.sh allows when enforce marker removed"
rm -f "$THOME_FN/.claude/enforce"
SPEC_EXIT=0
echo '{"tool_name":"Write","input":{"file_path":"src/main.py"}}' | (cd "$THOME_FN" && bash "$PROJECT_ROOT/templates/.claude/hooks/enforce-spec.sh") >/dev/null 2>&1 || SPEC_EXIT=$?
touch "$THOME_FN/.claude/enforce"
if [ "$SPEC_EXIT" -eq 0 ]; then
  test_pass
else
  test_fail "enforce-spec.sh exit $SPEC_EXIT (should allow without enforce marker)"
fi

# Hook functional test: dev-wiki-scope-check.sh parses .input.file_path (not .tool_input)
test_start "scope-check.sh parses .input.file_path from PreToolUse JSON"
SCOPE_OUT=$(echo '{"tool_name":"Write","input":{"file_path":"src/main.py"}}' | bash "$PROJECT_ROOT/templates/.claude/hooks/dev-wiki-scope-check.sh" 2>&1 || true)
if echo '{"tool_name":"Write","input":{"file_path":"src/test.py"}}' | bash "$PROJECT_ROOT/templates/.claude/hooks/dev-wiki-scope-check.sh" >/dev/null 2>&1; then
  test_pass
else
  test_fail "scope-check.sh failed to parse .input.file_path"
fi

# Hook functional test (Phase 82 INVERTED): the old assertion enshrined a bug — it required
# scope-check to IGNORE .tool_input, but current platform events carry .tool_input (the .input-only
# parse made the hook dormant in production). Both fields must now be parsed, defensively.
test_start "scope-check.sh parses .tool_input with .input fallback (current event shape)"
if grep -q 'tool_input.file_path // .input.file_path' "$PROJECT_ROOT/templates/.claude/hooks/dev-wiki-scope-check.sh"; then
  test_pass
else
  test_fail "scope-check.sh must parse .tool_input.file_path with .input.file_path fallback"
fi

# MultiEdit in matchers: generated template preserves the Write|Edit|MultiEdit matcher
test_start "generated template registers hooks with MultiEdit matcher"
if grep -q 'Write|Edit|MultiEdit' "$PROJECT_ROOT/templates/.claude/settings.json"; then
  test_pass
else
  test_fail "MultiEdit not in template matchers"
fi

# Companion file verification: key skills have required companions
test_start "spec skill has adversarial-constraints-prompt.md"
assert_file_exists "$THOME_FN/.claude/skills/spec/adversarial-constraints-prompt.md"

test_start "dev-plan skill has memory-bridge.md"
assert_file_exists "$THOME_FN/.claude/skills/dev-plan/memory-bridge.md"

test_start "dev-debrief skill has delivery-flow.md"
assert_file_exists "$THOME_FN/.claude/skills/dev-debrief/delivery-flow.md"

test_start "dev-debrief skill has memory-harvest.md"
assert_file_exists "$THOME_FN/.claude/skills/dev-debrief/memory-harvest.md"

test_start "dev-plan skill has plan-review-companion.md"
assert_file_exists "$THOME_FN/.claude/skills/dev-plan/plan-review-companion.md"

# MCP server functional: import works from configured CWD
test_start "MCP memory server imports from configured cwd"
if command -v python3 >/dev/null 2>&1 && [ -f "$THOME_FN/.claude/settings.json" ]; then
  MCP_CWD=$(python3 -c "import json; d=json.load(open('$THOME_FN/.claude/settings.json')); print(d['mcpServers']['memory']['cwd'])" 2>/dev/null || echo "")
  MCP_CMD=$(python3 -c "import json; d=json.load(open('$THOME_FN/.claude/settings.json')); print(d['mcpServers']['memory']['command'])" 2>/dev/null || echo "")
  if [ -n "$MCP_CWD" ] && [ -n "$MCP_CMD" ] && (cd "$MCP_CWD" && "$MCP_CMD" -c "import memory_server" 2>/dev/null); then
    test_pass
  else
    test_fail "MCP server cannot import from configured cwd: $MCP_CWD"
  fi
else
  test_pass  # python3 unavailable, skip gracefully
fi

rm -rf "$THOME_FN"

# --- register-settings.py tests ---
test_start "register-settings.py hooks --help works"
if python3 "$PROJECT_ROOT/scripts/register-settings.py" hooks --help >/dev/null 2>&1; then
  test_pass
else
  test_fail "register-settings.py hooks --help failed"
fi

test_start "register-settings.py mcp --help works"
if python3 "$PROJECT_ROOT/scripts/register-settings.py" mcp --help >/dev/null 2>&1; then
  test_pass
else
  test_fail "register-settings.py mcp --help failed"
fi

test_start "register-settings.py: hook upsert creates correct JSON"
T_REG=$(mktemp -d)
echo '{}' > "$T_REG/settings.json"
python3 "$PROJECT_ROOT/scripts/register-settings.py" hooks "$T_REG/settings.json" "$PROJECT_ROOT/modules.json" --scope project-local
if python3 -c "
import json
d = json.load(open('$T_REG/settings.json'))
hooks = d['hooks']
assert 'PreToolUse' in hooks, 'missing PreToolUse'
assert 'PostToolUse' in hooks, 'missing PostToolUse'
assert 'Stop' in hooks, 'missing Stop'
total = sum(len(v) for v in hooks.values())
assert total == 17, f'expected 17 hook entries, got {total}'
print('OK')
" 2>/dev/null | grep -q OK; then
  test_pass
else
  test_fail "hook upsert produced incorrect JSON"
fi

test_start "register-settings.py: upsert is idempotent"
python3 "$PROJECT_ROOT/scripts/register-settings.py" hooks "$T_REG/settings.json" "$PROJECT_ROOT/modules.json" --scope project-local
TOTAL_AFTER=$(python3 -c "import json; d=json.load(open('$T_REG/settings.json')); print(sum(len(v) for v in d['hooks'].values()))")
if [ "$TOTAL_AFTER" = "17" ]; then
  test_pass
else
  test_fail "upsert not idempotent: expected 17, got $TOTAL_AFTER"
fi

test_start "register-settings.py: ghost cleanup removes entries"
python3 -c "
import json
d = json.load(open('$T_REG/settings.json'))
d['hooks']['PostToolUse'].append({'hooks': [{'type': 'command', 'command': '/old/dev-wiki-post-commit.sh'}]})
with open('$T_REG/settings.json', 'w') as f: json.dump(d, f, indent=2); f.write('\n')
"
python3 "$PROJECT_ROOT/scripts/register-settings.py" hooks "$T_REG/settings.json" "$PROJECT_ROOT/modules.json" --scope global
if python3 -c "
import json
d = json.load(open('$T_REG/settings.json'))
for e in d['hooks'].get('PostToolUse', []):
  for h in e.get('hooks', []):
    assert 'dev-wiki-post-commit' not in h.get('command', ''), 'ghost not cleaned'
print('OK')
" 2>/dev/null | grep -q OK; then
  test_pass
else
  test_fail "ghost cleanup failed"
fi

test_start "register-settings.py: MCP registration sets correct cwd"
python3 "$PROJECT_ROOT/scripts/register-settings.py" mcp "$T_REG/settings.json" --python /usr/bin/python3 --cwd ~/.claude
if python3 -c "
import json, os
d = json.load(open('$T_REG/settings.json'))
cwd = d['mcpServers']['memory']['cwd']
assert cwd == os.path.expanduser('~/.claude'), f'bad cwd: {cwd}'
print('OK')
" 2>/dev/null | grep -q OK; then
  test_pass
else
  test_fail "MCP registration cwd incorrect"
fi
rm -rf "$T_REG"

# --- modules.json consistency tests ---
test_start "modules.json valid JSON (jq)"
if jq empty "$PROJECT_ROOT/modules.json" 2>/dev/null; then
  test_pass
else
  test_fail "modules.json invalid JSON"
fi

test_start "modules.json: all skill dirs exist on filesystem"
MISSING_SKILLS=""
for s in $(jq -r '.modules[].skills[]' "$PROJECT_ROOT/modules.json"); do
  if [ ! -d "$PROJECT_ROOT/templates/.claude/skills/$s" ]; then
    MISSING_SKILLS="$MISSING_SKILLS $s"
  fi
done
if [ -z "$MISSING_SKILLS" ]; then
  test_pass
else
  test_fail "missing skill dirs:$MISSING_SKILLS"
fi

test_start "modules.json: all hook scripts exist on filesystem"
MISSING_HOOKS=""
HOOK_LIST=$(jq -r '.hooks[].script' "$PROJECT_ROOT/modules.json")
[ -n "$HOOK_LIST" ] || MISSING_HOOKS=" (canonical .hooks[] empty — schema regression)"
for h in $HOOK_LIST; do
  if [ ! -f "$PROJECT_ROOT/templates/.claude/hooks/$h" ]; then
    MISSING_HOOKS="$MISSING_HOOKS $h"
  fi
done
if [ -z "$MISSING_HOOKS" ]; then
  test_pass
else
  test_fail "missing hook scripts:$MISSING_HOOKS"
fi

# --- Phase 76: installed-copy-drift comparator (check-install-drift.sh) ---
# Hermetic: uses the REAL kit (templates/.claude + modules.json) but an ISOLATED installed-root
# via the override arg — NEVER touches the real ~/.claude.
DRIFT_SCRIPT="$PROJECT_ROOT/scripts/check-install-drift.sh"

make_synced_root() {  # $1 = installed-root to populate with the kit-managed copy-verbatim set
  local root="$1" s h
  for s in $(jq -r '.modules[].skills[]' "$PROJECT_ROOT/modules.json"); do
    if [ -d "$PROJECT_ROOT/templates/.claude/skills/$s" ]; then
      mkdir -p "$root/skills/$s"
      cp -r "$PROJECT_ROOT/templates/.claude/skills/$s/." "$root/skills/$s/"
    fi
  done
  mkdir -p "$root/hooks"
  for h in $(jq -r '.hooks[]|select(.scope=="global")|.script' "$PROJECT_ROOT/modules.json"); do
    [ -f "$PROJECT_ROOT/templates/.claude/hooks/$h" ] && cp "$PROJECT_ROOT/templates/.claude/hooks/$h" "$root/hooks/$h"
  done
  mkdir -p "$root/rules"
  cp "$PROJECT_ROOT/templates/.claude/rules/"*.md "$root/rules/"
}

test_start "drift: silent (exit 0) when installed root is synced"
DROOT=$(mktemp -d)
make_synced_root "$DROOT"
assert_exit_code 0 bash "$DRIFT_SCRIPT" "$DROOT"
rm -rf "$DROOT"

test_start "drift: detects an injected drift in a skill companion"
DROOT=$(mktemp -d)
make_synced_root "$DROOT"
echo "DRIFTED" >> "$DROOT/skills/dev-debrief/delivery-flow.md"
DEC=0; DOUT=$(bash "$DRIFT_SCRIPT" "$DROOT" 2>&1) || DEC=$?
if [ "$DEC" -ne 0 ] && echo "$DOUT" | grep -q 'delivery-flow.md'; then
  test_pass
else
  test_fail "expected drift on delivery-flow.md (ec=$DEC out=$DOUT)"
fi
rm -rf "$DROOT"

test_start "drift: --count prints the drift count and exits 0 (fail-open contract)"
DROOT=$(mktemp -d)
make_synced_root "$DROOT"
echo "DRIFTED" >> "$DROOT/skills/dev-debrief/delivery-flow.md"
DCOUNT=$(bash "$DRIFT_SCRIPT" --count "$DROOT" 2>/dev/null)
assert_exit_code 0 bash "$DRIFT_SCRIPT" --count "$DROOT"
if [ "${DCOUNT:-0}" -ge 1 ]; then test_pass; else test_fail "--count returned '$DCOUNT', expected >=1"; fi
rm -rf "$DROOT"

test_start "drift: exclusion allow-list respected (nana-personal.md drift NOT reported)"
DROOT=$(mktemp -d)
make_synced_root "$DROOT"
echo "# user customized" >> "$DROOT/rules/nana-personal.md"
DEC=0; DOUT=$(bash "$DRIFT_SCRIPT" "$DROOT" 2>&1) || DEC=$?
if [ "$DEC" -eq 0 ] && ! echo "$DOUT" | grep -q 'nana-personal'; then
  test_pass
else
  test_fail "excluded nana-personal.md was reported as drift (ec=$DEC out=$DOUT)"
fi
rm -rf "$DROOT"

test_start "drift: exclusion allow-list is pinned + bounded (1..6 entries)"
NEXCL=$(bash "$DRIFT_SCRIPT" --excludes 2>/dev/null | grep -c .)
if [ "${NEXCL:-99}" -ge 1 ] && [ "${NEXCL:-99}" -le 6 ]; then
  test_pass
else
  test_fail "exclusion list count $NEXCL not in 1..6"
fi

test_start "drift: missing installed file is handled (no crash; reported as drift)"
DROOT=$(mktemp -d)
make_synced_root "$DROOT"
rm -f "$DROOT/skills/dev-debrief/delivery-flow.md"
assert_exit_code 0 bash "$DRIFT_SCRIPT" --count "$DROOT"
DEC=0; DOUT=$(bash "$DRIFT_SCRIPT" "$DROOT" 2>&1) || DEC=$?
if echo "$DOUT" | grep -qi 'delivery-flow.md'; then test_pass; else test_fail "missing file not handled (ec=$DEC out=$DOUT)"; fi
rm -rf "$DROOT"

test_start "drift: fail-open (exit 0) when installed root does not exist"
assert_exit_code 0 bash "$DRIFT_SCRIPT" --count "/nonexistent/installed/root/xyz-$$"

# --- Phase 82: installed-hooks comparison pass (2b) ---
# Pre-Phase-79 global installs left project-scoped hooks LIVE in the installed root while the
# scope:global filter made their drift invisible (4+ stale registered hooks ran for weeks).
# Any kit-shipped hook PRESENT in the installed root is now compared regardless of scope tag.

test_start "drift: stale project-scoped hook present in installed root IS reported (2b)"
DROOT=$(mktemp -d)
make_synced_root "$DROOT"
cp "$PROJECT_ROOT/templates/.claude/hooks/enforce-spec.sh" "$DROOT/hooks/enforce-spec.sh"
echo "# stale" >> "$DROOT/hooks/enforce-spec.sh"
DEC=0; DOUT=$(bash "$DRIFT_SCRIPT" "$DROOT" 2>&1) || DEC=$?
if [ "$DEC" -ne 0 ] && echo "$DOUT" | grep -q 'hooks/enforce-spec.sh'; then
  test_pass
else
  test_fail "stale installed project-scoped hook not reported (ec=$DEC out=$DOUT)"
fi
rm -rf "$DROOT"

test_start "drift: user-owned non-kit hook in installed root is ignored (ownership boundary)"
DROOT=$(mktemp -d)
make_synced_root "$DROOT"
printf '#!/usr/bin/env bash\nexit 0\n' > "$DROOT/hooks/my-custom-hook.sh"
assert_exit_code 0 bash "$DRIFT_SCRIPT" "$DROOT"
rm -rf "$DROOT"

test_summary "test_install"
