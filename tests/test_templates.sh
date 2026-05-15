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

test_summary "test_templates"
