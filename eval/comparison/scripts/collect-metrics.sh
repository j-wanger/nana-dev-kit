#!/usr/bin/env bash
set -euo pipefail

# collect-metrics.sh — Collect metrics from a trial repo and output JSON
# Usage: collect-metrics.sh <repo_dir> [<task_file_for_checksum>]

REPO_DIR="${1:?Usage: collect-metrics.sh <repo_dir> [<task_file>]}"
TASK_FILE="${2:-}"

command -v jq >/dev/null 2>&1 || { echo '{"error":"jq required"}'; exit 1; }

if [ ! -d "$REPO_DIR/.git" ]; then
    echo '{"error":"not a git repo"}' >&2
    exit 1
fi

cd "$REPO_DIR"

# Git metrics
COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo 0)
# Subtract initial scaffold commit(s)
WORK_COMMITS=$((COMMITS > 1 ? COMMITS - 1 : 0))

# File metrics (exclude .git, .claude, .venv, __pycache__, .pytest_cache, .egg-info)
EXCLUDE="! -path './.git/*' ! -path './.claude/*' ! -path './.venv/*' ! -path './*__pycache__*' ! -path './.pytest_cache/*' ! -path './*.egg-info/*'"
TOTAL_FILES=$(eval "find . -type f $EXCLUDE" | wc -l | tr -d ' ')
PY_FILES=$(eval "find . -name '*.py' $EXCLUDE" | wc -l | tr -d ' ')
PY_LINES=$(eval "find . -name '*.py' $EXCLUDE -exec cat {} +" 2>/dev/null | wc -l | tr -d ' ')
TEST_FILES=$(eval "find . -name 'test_*.py' $EXCLUDE -o -name '*_test.py' $EXCLUDE" | wc -l | tr -d ' ')

# Test results — prefer venv python if available
TEST_PASS=0
TEST_FAIL=0
TEST_TOTAL=0
PYTHON="python3"
if [ -f ".venv/bin/python" ]; then
    PYTHON=".venv/bin/python"
elif [ -f ".venv/bin/python3" ]; then
    PYTHON=".venv/bin/python3"
fi
if [ "$PY_FILES" -gt 0 ]; then
    TEST_OUTPUT=$(PYTHONPATH=src $PYTHON -m pytest tests/ --tb=no -q 2>&1 || true)
    if echo "$TEST_OUTPUT" | grep -qE '[0-9]+ passed'; then
        TEST_PASS=$(echo "$TEST_OUTPUT" | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+')
    fi
    if echo "$TEST_OUTPUT" | grep -qE '[0-9]+ failed'; then
        TEST_FAIL=$(echo "$TEST_OUTPUT" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+')
    fi
    TEST_TOTAL=$((TEST_PASS + TEST_FAIL))
fi

# Linter metrics (optional)
RUFF_FINDINGS="-1"
MYPY_ERRORS="-1"
if command -v ruff >/dev/null 2>&1; then
    RUFF_FINDINGS=$(ruff check . --quiet 2>/dev/null | wc -l | tr -d ' ')
fi
if command -v mypy >/dev/null 2>&1; then
    MYPY_ERRORS=$(mypy src/ --no-error-summary 2>/dev/null | grep -c 'error:' || echo 0)
fi

# Task file checksum verification
CHECKSUM_VALID="null"
if [ -n "$TASK_FILE" ] && [ -f "$TASK_FILE" ]; then
    CURRENT_SHA=$(shasum -a 256 "$TASK_FILE" | cut -d' ' -f1)
    CHECKSUM_VALID="\"$CURRENT_SHA\""
fi

# Hook invocations (condition C only)
HOOK_EVENTS=0
HOOK_BLOCKS=0
if [ -f ".claude/hook-invocations.jsonl" ]; then
    HOOK_EVENTS=$(wc -l < ".claude/hook-invocations.jsonl" | tr -d ' ')
    HOOK_BLOCKS=$(grep -c '"exit_code":2' ".claude/hook-invocations.jsonl" 2>/dev/null || echo 0)
fi

# Output JSON
jq -n \
    --argjson commits "$WORK_COMMITS" \
    --argjson total_files "$TOTAL_FILES" \
    --argjson py_files "$PY_FILES" \
    --argjson py_lines "$PY_LINES" \
    --argjson test_files "$TEST_FILES" \
    --argjson test_pass "$TEST_PASS" \
    --argjson test_fail "$TEST_FAIL" \
    --argjson test_total "$TEST_TOTAL" \
    --argjson ruff_findings "$RUFF_FINDINGS" \
    --argjson mypy_errors "$MYPY_ERRORS" \
    --argjson checksum "$CHECKSUM_VALID" \
    --argjson hook_events "$HOOK_EVENTS" \
    --argjson hook_blocks "$HOOK_BLOCKS" \
    '{
        commits: $commits,
        total_files: $total_files,
        py_files: $py_files,
        py_lines: $py_lines,
        test_files: $test_files,
        test_pass: $test_pass,
        test_fail: $test_fail,
        test_total: $test_total,
        ruff_findings: $ruff_findings,
        mypy_errors: $mypy_errors,
        task_checksum: $checksum,
        hook_events: $hook_events,
        hook_blocks: $hook_blocks
    }'
