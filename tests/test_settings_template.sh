#!/usr/bin/env bash
# Settings-template integrity.
# The per-project template (templates/.claude/settings.json) is a GENERATED
# artifact: it must equal what register-settings.py produces from modules.json
# (no drift), and it must register the enforcement hooks. The firing test
# (added in Task 5) proves enforce-spec actually blocks in a fresh scaffold.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MODULES="$SCRIPT_DIR/modules.json"
TEMPLATE="$SCRIPT_DIR/templates/.claude/settings.json"
REG="$SCRIPT_DIR/scripts/register-settings.py"

fail=0

# --- Drift: committed template == generated from modules.json ---
echo "=== Drift: committed template == generated from modules.json ==="
TMP=$(mktemp)
echo '{}' > "$TMP"
# Mirror the Makefile `template` target exactly (no --hooks-dir override — project-local commands
# default to ${CLAUDE_PROJECT_DIR}/.claude/hooks so they resolve regardless of CWD, Phase 79).
python3 "$REG" hooks "$TMP" "$MODULES" --scope project-local --regenerate
if diff <(jq -S . "$TMP") <(jq -S . "$TEMPLATE") >/dev/null; then
  echo "  PASS: template in sync with modules.json"
else
  echo "  FAIL: template drifted from modules.json — run 'make template'"
  diff <(jq -S . "$TMP") <(jq -S . "$TEMPLATE") || true
  fail=1
fi
rm -f "$TMP"

# --- Hook commands resolve regardless of CWD: ${CLAUDE_PROJECT_DIR}-prefixed, NO bare relative ---
# Bare `.claude/hooks/X.sh` 404s when Claude Code runs the hook from a non-project-root CWD (Phase 79,
# the edge-screener Stop-hook dogfood). Every project hook command must be ${CLAUDE_PROJECT_DIR}-anchored.
echo ""
echo "=== Hook command paths are CWD-independent (\${CLAUDE_PROJECT_DIR}-prefixed) ==="
if jq -r '.hooks[][].hooks[].command' "$TEMPLATE" | grep -q '^\.claude/hooks/'; then
  echo "  FAIL: a bare-relative .claude/hooks command remains (404s under CWD-drift)"
  jq -r '.hooks[][].hooks[].command' "$TEMPLATE" | grep '^\.claude/hooks/' || true
  fail=1
elif [ "$(jq -r '.hooks[][].hooks[].command' "$TEMPLATE" | grep -c '^${CLAUDE_PROJECT_DIR}/.claude/hooks/')" -ge 1 ]; then
  echo "  PASS: all hook commands are \${CLAUDE_PROJECT_DIR}-anchored"
else
  echo "  FAIL: no \${CLAUDE_PROJECT_DIR}-anchored hook command found"
  fail=1
fi

# --- Enforcement hooks registered in the generated template ---
echo ""
echo "=== Enforcement hooks registered in template ==="
for h in enforce-spec.sh enforce-loop.sh enforce-memory.sh; do
  if grep -q "$h" "$TEMPLATE"; then
    echo "  PASS: $h registered"
  else
    echo "  FAIL: $h missing from template"
    fail=1
  fi
done

# --- Firing: a project scaffolded FROM the template self-enforces ---
# The bug this guards against survived two experiment runs because reviewers
# checked that enforce-spec.sh EXISTED, not that it FIRED. This asserts exit 2.
echo ""
echo "=== Firing: scaffold-from-template makes enforce-spec block (exit 2) ==="
SCAFFOLD=$(mktemp -d)
EMPTY_HOME=$(mktemp -d)
# Simulate py-init: the template ships the hooks AND the opt-in marker.
mkdir -p "$SCAFFOLD/.claude/rules" "$SCAFFOLD/.dev-wiki"
cp -r "$SCRIPT_DIR/templates/.claude/hooks" "$SCAFFOLD/.claude/hooks"
cp "$SCRIPT_DIR/templates/.claude/enforce" "$SCAFFOLD/.claude/enforce"
# Active phase with NO approved spec -> an implementation write must be blocked.
printf 'Phase: 99 - scaffold firing test\n' > "$SCAFFOLD/.claude/rules/active-phase.md"
SPEC_EXIT=0
echo '{"tool_name":"Write","input":{"file_path":"src/app.py"}}' \
  | (cd "$SCAFFOLD" && HOME="$EMPTY_HOME" bash .claude/hooks/enforce-spec.sh) >/dev/null 2>&1 || SPEC_EXIT=$?
if [ "$SPEC_EXIT" -eq 2 ]; then
  echo "  PASS: enforce-spec exits 2 in fresh scaffold (empty HOME, project marker only)"
else
  echo "  FAIL: enforce-spec exit $SPEC_EXIT (expected 2 — scaffold is not self-enforcing)"
  fail=1
fi
# No false positives: an allowlisted write (specs/) must still pass.
ALLOW_EXIT=0
echo '{"tool_name":"Write","input":{"file_path":"specs/phase-99-x.md"}}' \
  | (cd "$SCAFFOLD" && HOME="$EMPTY_HOME" bash .claude/hooks/enforce-spec.sh) >/dev/null 2>&1 || ALLOW_EXIT=$?
if [ "$ALLOW_EXIT" -eq 0 ]; then
  echo "  PASS: allowlisted write (specs/) passes in scaffold"
else
  echo "  FAIL: allowlisted write blocked (exit $ALLOW_EXIT)"
  fail=1
fi
rm -rf "$SCAFFOLD" "$EMPTY_HOME"

# --- Backward-compat: global-only marker still triggers enforcement ---
echo ""
echo "=== Backward-compat: global-only marker still blocks ==="
GPROJ=$(mktemp -d); GHOME=$(mktemp -d)
mkdir -p "$GPROJ/.dev-wiki" "$GHOME/.claude"
touch "$GHOME/.claude/enforce"   # global marker only, no project marker
GC_EXIT=0
echo '{"tool_name":"Write","input":{"file_path":"src/app.py"}}' \
  | (cd "$GPROJ" && HOME="$GHOME" bash "$SCRIPT_DIR/templates/.claude/hooks/enforce-spec.sh") >/dev/null 2>&1 || GC_EXIT=$?
if [ "$GC_EXIT" -eq 2 ]; then
  echo "  PASS: global-only marker still triggers enforcement"
else
  echo "  FAIL: global marker no longer works (exit $GC_EXIT) — backward compat broken"
  fail=1
fi
rm -rf "$GPROJ" "$GHOME"

# --- Scaffolders ship the marker (else a scaffold registers but never fires) ---
echo ""
echo "=== Scaffolders (py-init, ts-init) copy the enforce marker ==="
for skill in py-init ts-init; do
  if grep -q 'templates/.claude/enforce' "$SCRIPT_DIR/templates/.claude/skills/$skill/SKILL.md"; then
    echo "  PASS: $skill copies the enforce marker"
  else
    echo "  FAIL: $skill does not copy the enforce marker (scaffold won't self-enforce)"
    fail=1
  fi
done

[ "$fail" -eq 0 ] || exit 1
echo ""
echo "Settings template integrity: all checks passed"
