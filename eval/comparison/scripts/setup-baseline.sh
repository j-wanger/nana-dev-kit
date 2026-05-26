#!/usr/bin/env bash
set -euo pipefail

# setup-baseline.sh — Create a bare repo with no harness artifacts (Condition A)
# Usage: setup-baseline.sh <target_dir> <starter_path>

TARGET_DIR="${1:?Usage: setup-baseline.sh <target_dir> <starter_path>}"
STARTER_PATH="${2:?Usage: setup-baseline.sh <target_dir> <starter_path>}"

if [ ! -d "$STARTER_PATH" ]; then
    echo "Error: starter path '$STARTER_PATH' does not exist" >&2
    exit 1
fi

mkdir -p "$TARGET_DIR"
cp -r "$STARTER_PATH"/. "$TARGET_DIR"/

cd "$TARGET_DIR"
git init -q
git add -A
git commit -q -m "Initial scaffold"

# Verify: no harness artifacts
if [ -d ".claude/rules" ] || [ -d ".claude/hooks" ] || [ -d ".claude/skills" ]; then
    echo "Error: harness artifacts found in baseline repo" >&2
    exit 1
fi

echo "Baseline repo created at $TARGET_DIR"
