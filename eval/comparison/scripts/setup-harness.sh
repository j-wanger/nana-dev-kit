#!/usr/bin/env bash
set -euo pipefail

# setup-harness.sh — Create a fully harness-installed repo (Condition C)
# Runs install.sh, wires hook-wrapper.sh for invocation logging

TARGET_DIR="${1:?Usage: setup-harness.sh <target_dir> <starter_path>}"
STARTER_PATH="${2:?Usage: setup-harness.sh <target_dir> <starter_path>}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KIT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [ ! -d "$STARTER_PATH" ]; then
    echo "Error: starter path '$STARTER_PATH' does not exist" >&2
    exit 1
fi

if [ ! -f "$KIT_ROOT/install.sh" ]; then
    echo "Error: install.sh not found at $KIT_ROOT" >&2
    exit 1
fi

mkdir -p "$TARGET_DIR"
cp -r "$STARTER_PATH"/. "$TARGET_DIR"/

cd "$TARGET_DIR"
git init -q
git add -A
git commit -q -m "Initial scaffold"

# Run install.sh with HOME pointing to target dir's parent
# so harness artifacts install relative to the project
export HOME="$TARGET_DIR"
mkdir -p "$HOME/.claude"
bash "$KIT_ROOT/install.sh" --all 2>/dev/null || true

# Copy hook-wrapper.sh for instrumentation
if [ -f "$SCRIPT_DIR/hook-wrapper.sh" ]; then
    cp "$SCRIPT_DIR/hook-wrapper.sh" "$HOME/.claude/hooks/hook-wrapper.sh"
    chmod +x "$HOME/.claude/hooks/hook-wrapper.sh"
fi

# Create enforcement marker
touch .claude/enforce

git add -A
git commit -q -m "Install harness" --allow-empty

# Verify: rules and hooks present
if [ ! -d "$HOME/.claude/rules" ]; then
    echo "Error: rules not found after install" >&2
    exit 1
fi

echo "Full harness repo created at $TARGET_DIR"
