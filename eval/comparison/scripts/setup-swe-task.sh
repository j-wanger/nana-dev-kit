#!/usr/bin/env bash
set -euo pipefail

# setup-swe-task.sh — Set up the SWE-bench task (django__django-16263) for a trial
# Usage: setup-swe-task.sh <target_dir>
# Requires: /tmp/swe-comparison/django-base exists (Django at commit 321ecb40f)

TARGET_DIR="${1:?Usage: setup-swe-task.sh <target_dir>}"
BASE="/tmp/swe-comparison/django-base"

if [ ! -d "$BASE/.git" ]; then
    echo "Error: Django base clone not found at $BASE" >&2
    echo "Clone it first: git clone django/django, checkout 321ecb40f" >&2
    exit 1
fi

cp -r "$BASE" "$TARGET_DIR"
echo "Django repo created at $TARGET_DIR (commit 321ecb40f)"
echo ""
echo "Task: Strip unused annotations from count() queries"
echo "See eval/comparison/tasks/swe-bench-django-16263.md for details"
