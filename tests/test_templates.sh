#!/usr/bin/env bash
# Tests for template placeholder presence — structural verification.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/helpers.sh"

echo "=== test_templates.sh ==="

# pyproject.toml placeholders
test_start "pyproject.toml has {{PACKAGE_NAME}}"
assert_contains "$PROJECT_ROOT/templates/pyproject.toml" '{{PACKAGE_NAME}}'

test_start "pyproject.toml has {{PROJECT_DESCRIPTION}}"
assert_contains "$PROJECT_ROOT/templates/pyproject.toml" '{{PROJECT_DESCRIPTION}}'

# AGENTS.md placeholders
test_start "AGENTS.md has {{PROJECT_NAME}}"
assert_contains "$PROJECT_ROOT/templates/AGENTS.md" '{{PROJECT_NAME}}'

test_start "AGENTS.md has {{PROJECT_DESCRIPTION}}"
assert_contains "$PROJECT_ROOT/templates/AGENTS.md" '{{PROJECT_DESCRIPTION}}'

test_start "AGENTS.md has {{PACKAGE_NAME}}"
assert_contains "$PROJECT_ROOT/templates/AGENTS.md" '{{PACKAGE_NAME}}'

# Verify placeholders are raw (not accidentally substituted)
test_start "pyproject.toml placeholder is not empty string"
assert_exit_code 1 grep -q 'name = ""' "$PROJECT_ROOT/templates/pyproject.toml"

# --- Protocol presence in nana-soul.md ---
SOUL="$PROJECT_ROOT/templates/.claude/rules/nana-soul.md"

test_start "nana-soul.md has 'Thinking protocol' section"
assert_contains "$SOUL" 'Thinking protocol'

test_start "nana-soul.md has 'Memory discipline' section"
assert_contains "$SOUL" 'Memory discipline'

test_start "nana-soul.md has 'Code quality lens' section"
assert_contains "$SOUL" 'Code quality lens'

test_start "nana-soul.md has surgical discipline bullet"
assert_contains "$SOUL" 'every changed line'

test_start "nana-soul.md has 'Voice & presence' section"
assert_contains "$SOUL" 'Voice'

test_start "nana-soul.md stays under 60 lines"
SOUL_LINES=$(wc -l < "$SOUL")
if [ "$SOUL_LINES" -le 60 ]; then
  echo -n "($SOUL_LINES/60) "
  test_pass
else
  test_fail "soul: $SOUL_LINES / 60 lines OVER"
fi

test_start "nana-soul.md has no personal data (jake)"
assert_exit_code 1 grep -qi 'jake' "$SOUL"

# --- AGENTS.md section rename ---
test_start "AGENTS.md has 'Pre-commit sequence' section"
assert_contains "$PROJECT_ROOT/templates/AGENTS.md" 'Pre-commit sequence'

# --- Personal profile template (no user-specific data) ---
test_start "nana-personal.md exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/rules/nana-personal.md"

test_start "nana-personal.md template has no jake-specific content"
assert_exit_code 1 grep -qi 'jake' "$PROJECT_ROOT/templates/.claude/rules/nana-personal.md"

# --- Spec skill ---
SPEC="$PROJECT_ROOT/templates/.claude/skills/spec/SKILL.md"

test_start "spec SKILL.md exists"
assert_file_exists "$SPEC"

test_start "spec has Constraints section"
assert_contains "$SPEC" 'Constraints'

test_start "spec has Checkpoints section"
assert_contains "$SPEC" 'Checkpoints'

test_start "spec has two-tier review gate"
assert_contains "$SPEC" 'Tier 0'

test_start "spec-reviewer-prompt.md exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/spec/spec-reviewer-prompt.md"

test_start "adversarial-constraints-prompt.md exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/spec/adversarial-constraints-prompt.md"

# --- File lifecycle reference ---
LIFECYCLE="$PROJECT_ROOT/templates/.claude/rules/file-lifecycle.md"

test_start "file-lifecycle.md exists"
assert_file_exists "$LIFECYCLE"

test_start "file-lifecycle.md has decision routing"
assert_contains "$LIFECYCLE" 'Decision routing'

test_start "file-lifecycle.md has memory_store routing"
assert_contains "$LIFECYCLE" 'memory_store'

# --- Session-start gate-check ---
test_start "session-start.sh has gate-check logic"
assert_contains "$PROJECT_ROOT/templates/.claude/hooks/session-start.sh" 'gate-check'

test_start "session-start.sh passes syntax check"
assert_exit_code 0 bash -n "$PROJECT_ROOT/templates/.claude/hooks/session-start.sh"

# --- Hook jq migration ---
for hook in audit-log auto-ruff-format block-dangerous-bash scan-secrets enforce-spec check-tests-were-run; do
  test_start "$hook.sh uses jq (not python3 -c)"
  HOOKFILE="$PROJECT_ROOT/templates/.claude/hooks/$hook.sh"
  if grep -q 'jq' "$HOOKFILE" && ! grep -q 'python3 -c' "$HOOKFILE"; then
    test_pass
  else
    test_fail "$hook.sh still uses python3 -c or missing jq"
  fi
done

test_start "audit-log.sh has jq fail-open guard"
assert_contains "$PROJECT_ROOT/templates/.claude/hooks/audit-log.sh" 'command -v jq'

test_start "block-dangerous-bash.sh has jq fail-open guard"
assert_contains "$PROJECT_ROOT/templates/.claude/hooks/block-dangerous-bash.sh" 'command -v jq'

# --- Imported skills presence ---
test_start "dev-plan SKILL.md exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/dev-plan/SKILL.md"

test_start "dev-wiki SKILL.md exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/dev-wiki/SKILL.md"

test_start "dev-debrief SKILL.md exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/dev-debrief/SKILL.md"

test_start "wiki-query SKILL.md exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/wiki-query/SKILL.md"

test_start "knowledge-wiki SKILL.md exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/knowledge-wiki/SKILL.md"

test_start "wiki-init SKILL.md exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/wiki-init/SKILL.md"

# --- PreCompact hook ---
test_start "pre-compact.sh exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/hooks/pre-compact.sh"

test_start "pre-compact.sh passes syntax check"
assert_exit_code 0 bash -n "$PROJECT_ROOT/templates/.claude/hooks/pre-compact.sh"

# --- PostCommit hook ---
test_start "post-commit.sh exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/hooks/post-commit.sh"

test_start "post-commit.sh passes syntax check"
assert_exit_code 0 bash -n "$PROJECT_ROOT/templates/.claude/hooks/post-commit.sh"

test_start "post-commit.sh has jq fail-open guard"
assert_contains "$PROJECT_ROOT/templates/.claude/hooks/post-commit.sh" 'command -v jq'

test_start "post-commit.sh emits dev-wiki trigger tag"
assert_contains "$PROJECT_ROOT/templates/.claude/hooks/post-commit.sh" 'dev-wiki:post-commit'

test_start "post-commit.sh writes pending-commit sidecar"
assert_contains "$PROJECT_ROOT/templates/.claude/hooks/post-commit.sh" 'pending-commit'

test_start "settings.json has PostToolUse Bash matcher for post-commit"
if jq -e '.hooks.PostToolUse[] | select(.hooks[].command | test("post-commit"))' "$PROJECT_ROOT/templates/.claude/settings.json" >/dev/null 2>&1; then
  test_pass
else
  test_fail "post-commit.sh not registered in PostToolUse"
fi

# --- Session-start memory guidance ---
test_start "session-start.sh has memory_search guidance"
assert_contains "$PROJECT_ROOT/templates/.claude/hooks/session-start.sh" 'memory_search'

test_start "session-start.sh has pending-commit stale check"
assert_contains "$PROJECT_ROOT/templates/.claude/hooks/session-start.sh" 'pending-commit'

# --- Session-start.d/ modules ---
test_start "session-start.d/wk-prune.sh exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/hooks/session-start.d/wk-prune.sh"

test_start "session-start.d/wk-prune.sh passes syntax check"
assert_exit_code 0 bash -n "$PROJECT_ROOT/templates/.claude/hooks/session-start.d/wk-prune.sh"

test_start "session-start.d/memory-nudge.sh exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/hooks/session-start.d/memory-nudge.sh"

test_start "session-start.d/memory-nudge.sh passes syntax check"
assert_exit_code 0 bash -n "$PROJECT_ROOT/templates/.claude/hooks/session-start.d/memory-nudge.sh"

test_start "session-start.sh sources 2 modules from session-start.d/"
SOURCES=$(grep -c 'source.*session-start\.d/' "$PROJECT_ROOT/templates/.claude/hooks/session-start.sh")
if [ "$SOURCES" -eq 2 ]; then
  test_pass
else
  test_fail "expected 2 source lines, got $SOURCES"
fi

# --- MANIFEST ---
test_start "MANIFEST exists with >100 entries"
MANIFEST="$PROJECT_ROOT/templates/.claude/skills/MANIFEST"
if [ -f "$MANIFEST" ] && [ "$(wc -l < "$MANIFEST")" -gt 100 ]; then
  test_pass
else
  test_fail "MANIFEST missing or too small"
fi

# --- Spec auto-invoke companion ---
test_start "spec-auto-invoke.md exists in dev-plan skill"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/dev-plan/spec-auto-invoke.md"

test_start "spec-auto-invoke.md referenced from SKILL.md"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/dev-plan/SKILL.md" 'spec-auto-invoke'

test_start "SKILL.md STOP behavior removed from Step 0.6"
if grep -q 'Run.*\/spec.*first.*STOP' "$PROJECT_ROOT/templates/.claude/skills/dev-plan/SKILL.md"; then
  test_fail "STOP still present in Step 0.6"
else
  test_pass
fi

test_start "dev-plan SKILL.md ≤350 lines"
DEVPLAN_LINES=$(wc -l < "$PROJECT_ROOT/templates/.claude/skills/dev-plan/SKILL.md")
if [ "$DEVPLAN_LINES" -le 350 ]; then
  echo -n "($DEVPLAN_LINES/350) "
  test_pass
else
  test_fail "SKILL.md: $DEVPLAN_LINES / 350 lines OVER"
fi

# --- Memory-wiki bridge ---
test_start "memory-bridge.md exists in dev-plan skill"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/dev-plan/memory-bridge.md"

test_start "memory-bridge.md referenced from dev-plan SKILL.md"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/dev-plan/SKILL.md" 'memory-bridge.md'

test_start "memory-bridge.md has bridge-decision tag"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/dev-plan/memory-bridge.md" 'bridge-decision'

test_start "spec SKILL.md has memory_store bridge"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/spec/SKILL.md" 'memory_store'

test_start "wiki-query SKILL.md has memory_search bridge"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/wiki-query/SKILL.md" 'memory_search'

test_start "wiki-query SKILL.md has Memory Results section"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/wiki-query/SKILL.md" 'Memory Results'

test_start "spec SKILL.md ≤350 lines"
SPEC_LINES=$(wc -l < "$PROJECT_ROOT/templates/.claude/skills/spec/SKILL.md")
if [ "$SPEC_LINES" -le 350 ]; then
  echo -n "($SPEC_LINES/350) "
  test_pass
else
  test_fail "spec SKILL.md: $SPEC_LINES / 350 lines OVER"
fi

test_start "wiki-query SKILL.md ≤350 lines"
WQ_LINES=$(wc -l < "$PROJECT_ROOT/templates/.claude/skills/wiki-query/SKILL.md")
if [ "$WQ_LINES" -le 350 ]; then
  echo -n "($WQ_LINES/350) "
  test_pass
else
  test_fail "wiki-query SKILL.md: $WQ_LINES / 350 lines OVER"
fi

# --- Instruction budget regression test ---
# Sum always-loaded files: soul + personal + nana.instructions.md + AGENTS.md
# Ceiling: 300 lines total before instruction-following degrades
test_start "instruction budget under 300 lines"
BUDGET_TOTAL=0
for f in \
  "$PROJECT_ROOT/templates/.claude/rules/nana-soul.md" \
  "$PROJECT_ROOT/templates/.claude/rules/nana-personal.md" \
  "$PROJECT_ROOT/templates/.claude/rules/file-lifecycle.md" \
  "$PROJECT_ROOT/templates/.github/instructions/nana.instructions.md" \
  "$PROJECT_ROOT/templates/AGENTS.md"; do
  BUDGET_TOTAL=$((BUDGET_TOTAL + $(wc -l < "$f")))
done
if [ "$BUDGET_TOTAL" -le 300 ]; then
  echo -n "($BUDGET_TOTAL/300) "
  test_pass
else
  test_fail "budget: $BUDGET_TOTAL / 300 lines OVER"
fi

# --- Memory-harvest API correctness ---
test_start "memory-harvest.md uses category=custom (not lesson/constraint)"
HARVEST="$PROJECT_ROOT/templates/.claude/skills/dev-debrief/memory-harvest.md"
if ! grep -q 'category.*lesson\|category.*constraint' "$HARVEST" && grep -q 'category.*custom' "$HARVEST"; then
  test_pass
else
  test_fail "memory-harvest.md has invalid MCP categories"
fi

test_start "memory-harvest.md uses trust (not confidence)"
if grep -q 'trust' "$HARVEST" && ! grep -q 'confidence' "$HARVEST"; then
  test_pass
else
  test_fail "memory-harvest.md uses confidence instead of trust"
fi

# --- README v0.4.0 coverage ---
test_start "README mentions enforcement"
assert_contains "$PROJECT_ROOT/README.md" 'nforcement'

test_start "README mentions eval"
assert_contains "$PROJECT_ROOT/README.md" 'eval'

test_start "README mentions dev-plan"
assert_contains "$PROJECT_ROOT/README.md" 'dev-plan'

test_start "README within 70-120 line budget"
README_LINES=$(wc -l < "$PROJECT_ROOT/README.md")
if [ "$README_LINES" -ge 70 ] && [ "$README_LINES" -le 120 ]; then
  echo -n "($README_LINES/120) "
  test_pass
else
  test_fail "README: $README_LINES lines (expected 70-120)"
fi

# --- PreCompact hook registration ---
test_start "settings.json has PreCompact hook"
if jq -e '.hooks.PreCompact' "$PROJECT_ROOT/templates/.claude/settings.json" >/dev/null 2>&1; then
  test_pass
else
  test_fail "PreCompact missing from settings.json"
fi

# --- Cross-skill reference validation ---
test_start "cross-skill references resolve to existing files"
SKILL_DIR="$PROJECT_ROOT/templates/.claude/skills"
BROKEN_REFS=0
BROKEN_LIST=""
while IFS= read -r ref; do
  LOCAL=$(echo "$ref" | sed 's|~/.claude/skills/|'"$SKILL_DIR"'/|')
  if [ ! -f "$LOCAL" ]; then
    SRC=$(grep -rn "$ref" "$SKILL_DIR" | head -1 | cut -d: -f1-2)
    BROKEN_LIST="${BROKEN_LIST}  BROKEN: ${SRC} -> ${ref}"$'\n'
    BROKEN_REFS=$((BROKEN_REFS + 1))
  fi
done < <(grep -roh '~/.claude/skills/[^"'\'' ]*\.md' "$SKILL_DIR" | grep -v '[*<]' | sort -u)
if [ "$BROKEN_REFS" -eq 0 ]; then
  test_pass
else
  echo ""
  printf '%s' "$BROKEN_LIST"
  test_fail "$BROKEN_REFS broken cross-skill reference(s)"
fi

test_summary "test_templates"
