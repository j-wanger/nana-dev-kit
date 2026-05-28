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
assert_contains "$PROJECT_ROOT/templates/.claude/hooks/session-start.sh" 'nana:gate'

test_start "session-start.sh has kit summary line"
assert_contains "$PROJECT_ROOT/templates/.claude/hooks/session-start.sh" 'nana:kit'

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

# --- Enforce-memory hook ---
test_start "enforce-memory.sh exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/hooks/enforce-memory.sh"

test_start "enforce-memory.sh passes syntax check"
assert_exit_code 0 bash -n "$PROJECT_ROOT/templates/.claude/hooks/enforce-memory.sh"

test_start "enforce-memory.sh has jq fail-open guard"
assert_contains "$PROJECT_ROOT/templates/.claude/hooks/enforce-memory.sh" 'command -v jq'

test_start "enforce-memory.sh has nana prefix"
assert_contains "$PROJECT_ROOT/templates/.claude/hooks/enforce-memory.sh" 'nana:enforce-memory'

test_start "enforce-memory.sh checks memory-consulted gate"
assert_contains "$PROJECT_ROOT/templates/.claude/hooks/enforce-memory.sh" 'memory-consulted'

test_start "session-start.sh clears memory-consulted"
assert_contains "$PROJECT_ROOT/templates/.claude/hooks/session-start.sh" 'memory-consulted'

# --- MANIFEST ---
test_start "MANIFEST exists with >100 entries"
MANIFEST="$PROJECT_ROOT/templates/.claude/skills/MANIFEST"
if [ -f "$MANIFEST" ] && [ "$(wc -l < "$MANIFEST")" -gt 100 ]; then
  test_pass
else
  test_fail "MANIFEST missing or too small"
fi

test_start "MANIFEST has skill descriptions (10+)"
DESC_COUNT=$(grep -c '^# [a-z]' "$MANIFEST" || true)
if [ "$DESC_COUNT" -ge 10 ]; then
  test_pass
else
  test_fail "MANIFEST has $DESC_COUNT descriptions, expected 10+"
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

# --- Phase 37: Ceremony streamlining ---
test_start "plan-review-companion.md exists in dev-plan skill"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/dev-plan/plan-review-companion.md"

test_start "plan-review-companion.md referenced from dev-plan SKILL.md"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/dev-plan/SKILL.md" 'plan-review-companion'

test_start "dev-plan SKILL.md has agent-internal flow"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/dev-plan/SKILL.md" 'agent-internal'

test_start "dev-plan SKILL.md has direction gate"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/dev-plan/SKILL.md" 'direction'

test_start "dev-plan SKILL.md has delivery gate reference"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/dev-plan/SKILL.md" 'delivery'

test_start "dev-plan SKILL.md has no old 5-gate template"
if grep -q 'Spec reviewed.*Tier' "$PROJECT_ROOT/templates/.claude/skills/dev-plan/SKILL.md"; then
  test_fail "old 5-gate template still present"
else
  test_pass
fi

test_start "spec SKILL.md has --internal mode"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/spec/SKILL.md" '\-\-internal'

test_start "delivery-flow.md exists in dev-debrief skill"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/dev-debrief/delivery-flow.md"

test_start "dev-debrief SKILL.md references delivery report"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/dev-debrief/SKILL.md" 'delivery'

test_start "delivery-flow.md has auto-commit protocol"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/dev-debrief/delivery-flow.md" 'auto-commit\|Auto-Commit'

test_start "delivery report script exists"
assert_file_exists "$PROJECT_ROOT/scripts/generate-delivery-report.py"

test_start "implementation-guide.md has 2-gate model"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/dev-plan/implementation-guide.md" 'direction gate'

test_start "implementation-guide.md no old 5-gate references"
if grep -q 'Spec reviewed.*Tier\|Tasks approved by user' "$PROJECT_ROOT/templates/.claude/skills/dev-plan/implementation-guide.md"; then
  test_fail "old 5-gate reference still present"
else
  test_pass
fi

test_start "task-schema.md has 2-gate log format"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/dev-plan/task-schema.md" 'direction='

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

# --- README accuracy (drift detection) ---
README="$PROJECT_ROOT/README.md"

test_start "README eval scenario count matches reality"
ACTUAL_EVAL=$(find "$PROJECT_ROOT/eval/corpus" -name 'scenario.json' | wc -l | tr -d ' ')
README_EVAL=$(grep -oE '[0-9]+-scenario' "$README" | head -1 | grep -oE '[0-9]+')
if [ -z "$README_EVAL" ]; then
  test_fail "could not extract eval count from README (pattern: N-scenario)"
elif [ "$ACTUAL_EVAL" = "$README_EVAL" ]; then
  test_pass
else
  test_fail "README says $README_EVAL scenarios, actually $ACTUAL_EVAL"
fi

test_start "README hook fidelity count matches reality"
ACTUAL_HOOK_EVAL=$(find "$PROJECT_ROOT/eval/corpus" -type d -name 'hook-*' | wc -l | tr -d ' ')
README_HOOK_EVAL=$(grep -oE 'hook fidelity \([0-9]+\)' "$README" | grep -oE '[0-9]+')
if [ -z "$README_HOOK_EVAL" ]; then
  test_fail "could not extract hook fidelity count from README (pattern: hook fidelity (N))"
elif [ "$ACTUAL_HOOK_EVAL" = "$README_HOOK_EVAL" ]; then
  test_pass
else
  test_fail "README says $README_HOOK_EVAL hook scenarios, actually $ACTUAL_HOOK_EVAL"
fi

test_start "README test script count matches reality"
ACTUAL_SCRIPTS=$(grep -c 'bash.*tests/test_' "$PROJECT_ROOT/Makefile" | tr -d ' ')
README_SCRIPTS=$(grep -oE '[0-9]+ scripts' "$README" | head -1 | grep -oE '[0-9]+')
if [ -z "$README_SCRIPTS" ]; then
  test_fail "could not extract script count from README (pattern: N scripts)"
elif [ "$ACTUAL_SCRIPTS" = "$README_SCRIPTS" ]; then
  test_pass
else
  test_fail "README says $README_SCRIPTS scripts, actually $ACTUAL_SCRIPTS"
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

# --- MANIFEST freshness (every skill dir has a description) ---
test_start "manifest_freshness: all skill dirs have MANIFEST descriptions"
MANIFEST="$PROJECT_ROOT/templates/.claude/skills/MANIFEST"
MISSING_DESCS=0
MISSING_LIST=""
while IFS= read -r skill_dir; do
  DIR_NAME=$(basename "$skill_dir")
  if ! grep -q "^# ${DIR_NAME}:" "$MANIFEST" 2>/dev/null; then
    MISSING_LIST="${MISSING_LIST}  MISSING: ${DIR_NAME}"$'\n'
    MISSING_DESCS=$((MISSING_DESCS + 1))
  fi
done < <(find "$PROJECT_ROOT/templates/.claude/skills" -name 'SKILL.md' -exec dirname {} \; | sort)
if [ "$MISSING_DESCS" -eq 0 ]; then
  test_pass
else
  echo ""
  printf '%s' "$MISSING_LIST"
  test_fail "$MISSING_DESCS skill(s) missing MANIFEST descriptions"
fi

# --- Phase 29 new skills ---
test_start "nana/SKILL.md exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/nana/SKILL.md"

test_start "memory-consolidate/SKILL.md exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/memory-consolidate/SKILL.md"

test_start "scope-exploration-spec.md exists in dev-plan"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/dev-plan/scope-exploration-spec.md"

test_start "dev-plan SKILL.md references scope-exploration-spec"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/dev-plan/SKILL.md" 'scope-exploration-spec'

test_start "spec SKILL.md has provenance marker instruction"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/spec/SKILL.md" 'nana:approved'

# --- Report staleness regression ---
test_start "report_staleness: no stale 5-Layer in reports"
if grep -q '5-Layer' "$PROJECT_ROOT/docs/report.html" 2>/dev/null || grep -q '5-Layer' "$PROJECT_ROOT/docs/workflow.html" 2>/dev/null; then
  test_fail "reports still reference 5-Layer (should be 7-Layer)"
else
  test_pass
fi

test_start "report_staleness: reports have 7-Layer"
if grep -q '7-Layer\|7 Layer' "$PROJECT_ROOT/docs/report.html" 2>/dev/null && grep -q '7-Layer\|7 Layer' "$PROJECT_ROOT/docs/workflow.html" 2>/dev/null; then
  test_pass
else
  test_fail "reports missing 7-Layer reference"
fi

test_start "report_staleness: no MEMORY.md in reports"
if grep -q 'MEMORY\.md' "$PROJECT_ROOT/docs/report.html" 2>/dev/null || grep -q 'MEMORY\.md' "$PROJECT_ROOT/docs/workflow.html" 2>/dev/null; then
  test_fail "reports reference deleted .memory/MEMORY.md"
else
  test_pass
fi

test_start "report_staleness: no python3 (json) in reports"
if grep -q 'python3 (json)' "$PROJECT_ROOT/docs/workflow.html" 2>/dev/null; then
  test_fail "workflow.html references python3 (json) — hooks use jq since Phase 24"
else
  test_pass
fi

test_start "report_staleness: enforcement section in workflow"
if grep -q '<h[23].*[Ee]nforcement' "$PROJECT_ROOT/docs/workflow.html" 2>/dev/null; then
  test_pass
else
  test_fail "workflow.html missing Enforcement section header"
fi

test_start "report_staleness: memory bridge section in workflow"
if grep -q '<h[23].*[Mm]emory.*[Bb]ridge' "$PROJECT_ROOT/docs/workflow.html" 2>/dev/null; then
  test_pass
else
  test_fail "workflow.html missing Memory Bridge section header"
fi

# --- ts-init skill ---
test_start "ts-init SKILL.md exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/ts-init/SKILL.md"

test_start "ts-init scanner.md exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/ts-init/scanner.md"

test_start "ts-init transform.md exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/skills/ts-init/transform.md"

test_start "ts-init SKILL.md references scanner.md"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/ts-init/SKILL.md" "scanner.md"

test_start "ts-init SKILL.md references transform.md"
assert_contains "$PROJECT_ROOT/templates/.claude/skills/ts-init/SKILL.md" "transform.md"

test_start "ts-init SKILL.md mentions ES2023"
if grep -qi 'es2023' "$PROJECT_ROOT/templates/.claude/skills/ts-init/SKILL.md"; then
  test_pass
else
  test_fail "ts-init SKILL.md missing ES2023 target"
fi

test_start "ts-init scanner has 10 dimensions + monorepo pre-check"
if grep -qi 'monorepo' "$PROJECT_ROOT/templates/.claude/skills/ts-init/scanner.md" && grep -qi 'compatible' "$PROJECT_ROOT/templates/.claude/skills/ts-init/scanner.md"; then
  test_pass
else
  test_fail "scanner missing monorepo or compatible"
fi

test_start "ts-init scanner warns about React + Biome"
if grep -qi 'react.*biome\|biome.*react\|React/Next' "$PROJECT_ROOT/templates/.claude/skills/ts-init/scanner.md"; then
  test_pass
else
  test_fail "scanner missing React/Biome warning"
fi

test_start "ts-init transform mentions biome, vitest, husky"
if grep -qi 'biome' "$PROJECT_ROOT/templates/.claude/skills/ts-init/transform.md" && \
   grep -qi 'vitest' "$PROJECT_ROOT/templates/.claude/skills/ts-init/transform.md" && \
   grep -qi 'husky' "$PROJECT_ROOT/templates/.claude/skills/ts-init/transform.md"; then
  test_pass
else
  test_fail "transform missing biome/vitest/husky"
fi

test_start "AGENTS-ts.md exists"
assert_file_exists "$PROJECT_ROOT/templates/AGENTS-ts.md"

test_start "AGENTS-ts.md references pnpm, biome, vitest, tsc"
if grep -q 'pnpm' "$PROJECT_ROOT/templates/AGENTS-ts.md" && \
   grep -q 'biome' "$PROJECT_ROOT/templates/AGENTS-ts.md" && \
   grep -q 'vitest' "$PROJECT_ROOT/templates/AGENTS-ts.md" && \
   grep -q 'tsc' "$PROJECT_ROOT/templates/AGENTS-ts.md"; then
  test_pass
else
  test_fail "AGENTS-ts.md missing toolchain references"
fi

test_start "AGENTS-ts.md within budget (<=95 lines)"
TS_AGENTS_LINES=$(wc -l < "$PROJECT_ROOT/templates/AGENTS-ts.md")
if [ "$TS_AGENTS_LINES" -le 95 ]; then
  test_pass
else
  test_fail "AGENTS-ts.md is $TS_AGENTS_LINES lines (max 95)"
fi

test_start "ci-ts.yml exists"
assert_file_exists "$PROJECT_ROOT/templates/.github/workflows/ci-ts.yml"

test_start "ci-ts.yml uses pnpm + biome + tsc + vitest"
if grep -q 'pnpm' "$PROJECT_ROOT/templates/.github/workflows/ci-ts.yml" && \
   grep -q 'biome' "$PROJECT_ROOT/templates/.github/workflows/ci-ts.yml" && \
   grep -q 'tsc' "$PROJECT_ROOT/templates/.github/workflows/ci-ts.yml" && \
   grep -q 'vitest' "$PROJECT_ROOT/templates/.github/workflows/ci-ts.yml"; then
  test_pass
else
  test_fail "ci-ts.yml missing toolchain commands"
fi

test_start "ci-ts.yml has setup-node action"
if grep -qi 'setup-node' "$PROJECT_ROOT/templates/.github/workflows/ci-ts.yml"; then
  test_pass
else
  test_fail "ci-ts.yml missing setup-node action"
fi

test_start "MANIFEST has ts-init description"
if grep -q '# ts-init:' "$PROJECT_ROOT/templates/.claude/skills/MANIFEST"; then
  test_pass
else
  test_fail "MANIFEST missing ts-init description"
fi

# --- Phase 39: Resilience & Health Probes ---

test_start "context-size-check.sh uses jq (not python3)"
if grep -q 'jq' "$PROJECT_ROOT/templates/.claude/hooks/context-size-check.sh" && \
   ! grep -q 'python3' "$PROJECT_ROOT/templates/.claude/hooks/context-size-check.sh"; then
  test_pass
else
  test_fail "context-size-check.sh still uses python3"
fi

test_start "context-size-check.sh has jq fail-open guard"
if grep -q 'command -v jq' "$PROJECT_ROOT/templates/.claude/hooks/context-size-check.sh"; then
  test_pass
else
  test_fail "context-size-check.sh missing jq fail-open guard"
fi

test_start "session-start.sh no python3 for JSON parsing"
if ! grep 'python3 -c' "$PROJECT_ROOT/templates/.claude/hooks/session-start.sh" >/dev/null 2>&1; then
  test_pass
else
  test_fail "session-start.sh still uses python3 -c for JSON parsing"
fi

test_start "session-start.sh has 3-state memory health probe"
if grep -q 'memory.*healthy' "$PROJECT_ROOT/templates/.claude/hooks/session-start.sh" && \
   grep -q 'memory.*broken' "$PROJECT_ROOT/templates/.claude/hooks/session-start.sh" && \
   grep -q 'memory.*configured' "$PROJECT_ROOT/templates/.claude/hooks/session-start.sh"; then
  test_pass
else
  test_fail "session-start.sh missing 3-state health probe"
fi

test_start "PostToolUse hooks use .tool_input canonical path"
POSTTOOLUSE_HOOKS="audit-log auto-ruff-format scan-secrets stale-queue"
ALL_CANONICAL=true
for hook in $POSTTOOLUSE_HOOKS; do
  if ! grep -q 'tool_input.file_path' "$PROJECT_ROOT/templates/.claude/hooks/${hook}.sh" 2>/dev/null; then
    ALL_CANONICAL=false
    break
  fi
done
if $ALL_CANONICAL; then
  test_pass
else
  test_fail "Not all PostToolUse hooks use .tool_input canonical path"
fi

test_start "nana-init/SKILL.md exists with language markers"
if test -f "$PROJECT_ROOT/templates/.claude/skills/nana-init/SKILL.md" && \
   grep -qi 'py-init' "$PROJECT_ROOT/templates/.claude/skills/nana-init/SKILL.md" && \
   grep -qi 'ts-init' "$PROJECT_ROOT/templates/.claude/skills/nana-init/SKILL.md" && \
   grep -qi 'pyproject' "$PROJECT_ROOT/templates/.claude/skills/nana-init/SKILL.md"; then
  test_pass
else
  test_fail "nana-init/SKILL.md missing or incomplete"
fi

test_start "MANIFEST has nana-init description"
if grep -q '# nana-init:' "$PROJECT_ROOT/templates/.claude/skills/MANIFEST"; then
  test_pass
else
  test_fail "MANIFEST missing nana-init description"
fi

test_start "nana-init/SKILL.md dispatches to dev-init"
if grep -q 'dev-init' "$PROJECT_ROOT/templates/.claude/skills/nana-init/SKILL.md" && \
   grep -q 'Skill.*dev-init' "$PROJECT_ROOT/templates/.claude/skills/nana-init/SKILL.md"; then
  test_pass
else
  test_fail "nana-init/SKILL.md missing dev-init dispatch"
fi

test_start "nana-init/SKILL.md dispatches to wiki-init"
if grep -q 'wiki-init' "$PROJECT_ROOT/templates/.claude/skills/nana-init/SKILL.md" && \
   grep -q 'Skill.*wiki-init' "$PROJECT_ROOT/templates/.claude/skills/nana-init/SKILL.md"; then
  test_pass
else
  test_fail "nana-init/SKILL.md missing wiki-init dispatch"
fi

test_start "nana-init/SKILL.md within 120 line cap"
NANA_INIT_LINES=$(wc -l < "$PROJECT_ROOT/templates/.claude/skills/nana-init/SKILL.md")
if [ "$NANA_INIT_LINES" -le 120 ]; then
  test_pass
else
  test_fail "nana-init/SKILL.md is $NANA_INIT_LINES lines (cap: 120)"
fi

# --- Heuristic Learning System (Phase 44) ---

test_start "session-start.sh has heuristic count block"
if grep -q 'nana:heuristic' "$PROJECT_ROOT/templates/.claude/hooks/session-start.sh"; then
  test_pass
else
  test_fail "session-start.sh missing [nana:heuristics] block"
fi

test_start "eval/reasoning/run-eval.py exists"
if [ -f "$PROJECT_ROOT/eval/reasoning/run-eval.py" ]; then
  test_pass
else
  test_fail "eval/reasoning/run-eval.py missing"
fi

test_start "eval/reasoning/judges/reasoning-judge.md exists"
if [ -f "$PROJECT_ROOT/eval/reasoning/judges/reasoning-judge.md" ]; then
  test_pass
else
  test_fail "eval/reasoning/judges/reasoning-judge.md missing"
fi

test_start "eval/reasoning has >= 20 scenario files"
SCENARIO_COUNT=$(find "$PROJECT_ROOT/eval/reasoning/corpus" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SCENARIO_COUNT" -ge 20 ]; then
  test_pass
else
  test_fail "eval/reasoning has $SCENARIO_COUNT scenarios (need >= 20)"
fi

test_start "eval/reasoning/judges/reasoning-judge-v2.md exists"
if [ -f "$PROJECT_ROOT/eval/reasoning/judges/reasoning-judge-v2.md" ]; then
  test_pass
else
  test_fail "reasoning-judge-v2.md missing"
fi

test_start "eval/reasoning/baseline/results-v2.json exists"
if [ -f "$PROJECT_ROOT/eval/reasoning/baseline/results-v2.json" ]; then
  test_pass
else
  test_fail "results-v2.json missing"
fi

test_start "wiki/heuristics has >= 5 IRON RULES"
IRON_COUNT=$(find "$PROJECT_ROOT/wiki/heuristics" -name "IRON-*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$IRON_COUNT" -ge 5 ]; then
  test_pass
else
  test_fail "wiki/heuristics has $IRON_COUNT IRON RULES (need >= 5)"
fi

test_start "SCHEMA.md includes iron status"
if grep -q 'iron' "$PROJECT_ROOT/wiki/heuristics/SCHEMA.md"; then
  test_pass
else
  test_fail "SCHEMA.md missing iron status"
fi

# Phase 46: Anti-pattern tables + heuristic capture
test_start "SCHEMA.md has anti-pattern table format"
if grep -q 'Failure Mode.*Detection Signal' "$PROJECT_ROOT/wiki/heuristics/SCHEMA.md"; then
  test_pass
else
  test_fail "SCHEMA.md missing anti-pattern table format definition"
fi

test_start "All IRON RULES have anti-pattern tables"
IRON_TABLE_MISSING=0
for f in "$PROJECT_ROOT"/wiki/heuristics/IRON-*.md; do
  if ! grep -q '| Failure Mode' "$f"; then
    IRON_TABLE_MISSING=$((IRON_TABLE_MISSING + 1))
  fi
done
if [ "$IRON_TABLE_MISSING" -eq 0 ]; then
  test_pass
else
  test_fail "$IRON_TABLE_MISSING IRON RULES missing anti-pattern tables"
fi

test_start "heuristic-capture.md exists"
if test -f "$PROJECT_ROOT/templates/.claude/skills/dev-debrief/heuristic-capture.md"; then
  test_pass
else
  test_fail "templates/.claude/skills/dev-debrief/heuristic-capture.md missing"
fi

test_start "dev-debrief SKILL.md references heuristic capture"
if grep -q 'heuristic.capture' "$PROJECT_ROOT/templates/.claude/skills/dev-debrief/SKILL.md"; then
  test_pass
else
  test_fail "dev-debrief SKILL.md missing heuristic-capture reference"
fi

test_start "dev-debrief SKILL.md under 350 lines"
DEBRIEF_LINES=$(wc -l < "$PROJECT_ROOT/templates/.claude/skills/dev-debrief/SKILL.md" | tr -d ' ')
if [ "$DEBRIEF_LINES" -le 350 ]; then
  test_pass
else
  test_fail "dev-debrief SKILL.md is $DEBRIEF_LINES lines (max 350)"
fi

# === Phase 47: Self-Dialogue ===

test_start "self-dialogue-prompt.md exists"
if test -f "$PROJECT_ROOT/templates/.claude/skills/dev-plan/self-dialogue-prompt.md"; then
  test_pass
else
  test_fail "templates/.claude/skills/dev-plan/self-dialogue-prompt.md missing"
fi

test_start "dev-plan SKILL.md references self-dialogue"
if grep -q 'self-dialogue' "$PROJECT_ROOT/templates/.claude/skills/dev-plan/SKILL.md"; then
  test_pass
else
  test_fail "dev-plan SKILL.md missing self-dialogue reference"
fi

test_start "dev-plan SKILL.md under 350 lines"
DEVPLAN_LINES=$(wc -l < "$PROJECT_ROOT/templates/.claude/skills/dev-plan/SKILL.md" | tr -d ' ')
if [ "$DEVPLAN_LINES" -le 350 ]; then
  test_pass
else
  test_fail "dev-plan SKILL.md is $DEVPLAN_LINES lines (max 350)"
fi

test_start "self-dialogue-injection.md exists"
if test -f "$PROJECT_ROOT/eval/reasoning/self-dialogue-injection.md"; then
  test_pass
else
  test_fail "eval/reasoning/self-dialogue-injection.md missing"
fi

# Phase 48: Trace collection + ablation analysis
test_start "trace-schema.json exists and is valid JSON"
if test -f "$PROJECT_ROOT/eval/reasoning/trace-schema.json" && python3 -c "import json; json.load(open('$PROJECT_ROOT/eval/reasoning/trace-schema.json'))"; then
  test_pass
else
  test_fail "eval/reasoning/trace-schema.json missing or invalid"
fi

test_start "traces directory exists"
if test -d "$PROJECT_ROOT/eval/reasoning/traces"; then
  test_pass
else
  test_fail "eval/reasoning/traces/ directory missing"
fi

test_start "run-eval.py has --ablation mode"
if python3 "$PROJECT_ROOT/eval/reasoning/run-eval.py" --help 2>&1 | grep -q 'ablation'; then
  test_pass
else
  test_fail "run-eval.py missing --ablation mode"
fi

test_start "run-eval.py has --analyze mode"
if python3 "$PROJECT_ROOT/eval/reasoning/run-eval.py" --help 2>&1 | grep -q 'analyze'; then
  test_pass
else
  test_fail "run-eval.py missing --analyze mode"
fi

test_start "README documents ablation methodology"
if grep -q 'ablation' "$PROJECT_ROOT/eval/reasoning/README.md"; then
  test_pass
else
  test_fail "eval/reasoning/README.md missing ablation section"
fi

# Phase 51: Heuristic-informed runtime judging
test_start "heuristic-matcher.md exists"
if test -f "$PROJECT_ROOT/templates/.claude/skills/dev-plan/heuristic-matcher.md"; then
  test_pass
else
  test_fail "templates/.claude/skills/dev-plan/heuristic-matcher.md missing"
fi

test_start "heuristic-judge-prompt.md exists"
if test -f "$PROJECT_ROOT/templates/.claude/skills/dev-plan/heuristic-judge-prompt.md"; then
  test_pass
else
  test_fail "templates/.claude/skills/dev-plan/heuristic-judge-prompt.md missing"
fi

test_start "SKILL.md references heuristic-matcher"
if grep -q 'heuristic-matcher' "$PROJECT_ROOT/templates/.claude/skills/dev-plan/SKILL.md"; then
  test_pass
else
  test_fail "dev-plan SKILL.md missing heuristic-matcher reference"
fi

test_start "dev-plan SKILL.md ≤350 lines"
SKILL_LINES=$(wc -l < "$PROJECT_ROOT/templates/.claude/skills/dev-plan/SKILL.md")
if [ "$SKILL_LINES" -le 350 ]; then
  test_pass
else
  test_fail "dev-plan SKILL.md is $SKILL_LINES lines (max 350)"
fi

test_start "ground-truth.json has 25+ scenarios"
if python3 -c "import json; g=json.load(open('$PROJECT_ROOT/eval/reasoning/selective/ground-truth.json')); assert len(g) >= 25" 2>/dev/null; then
  test_pass
else
  test_fail "ground-truth.json missing or has <25 scenarios"
fi

test_start "run-eval.py has --selective mode"
if python3 "$PROJECT_ROOT/eval/reasoning/run-eval.py" --help 2>&1 | grep -q 'selective'; then
  test_pass
else
  test_fail "run-eval.py missing --selective mode"
fi

test_summary "test_templates"
