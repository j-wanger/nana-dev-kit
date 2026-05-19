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

test_start "nana-soul.md has no personal data (jake)"
assert_exit_code 1 grep -qi 'jake' "$SOUL"

# --- AGENTS.md section rename ---
test_start "AGENTS.md has 'Pre-commit sequence' section"
assert_contains "$PROJECT_ROOT/templates/AGENTS.md" 'Pre-commit sequence'

# --- Personal profile file exists ---
test_start "nana-personal.md exists"
assert_file_exists "$PROJECT_ROOT/templates/.claude/rules/nana-personal.md"

# --- Instruction budget regression test ---
# Sum always-loaded files: soul + personal + nana.instructions.md + AGENTS.md
# Ceiling: 300 lines total before instruction-following degrades
test_start "instruction budget under 300 lines"
BUDGET_TOTAL=0
for f in \
  "$PROJECT_ROOT/templates/.claude/rules/nana-soul.md" \
  "$PROJECT_ROOT/templates/.claude/rules/nana-personal.md" \
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

test_summary "test_templates"
