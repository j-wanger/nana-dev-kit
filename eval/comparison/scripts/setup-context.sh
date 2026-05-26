#!/usr/bin/env bash
set -euo pipefail

# setup-context.sh — Create a repo with harness context files only (Condition B)
# Includes: .claude/rules/ (nana-soul.md, file-lifecycle.md, nana-personal.md), AGENTS.md
# Excludes: hooks, skills, memory, enforcement

TARGET_DIR="${1:?Usage: setup-context.sh <target_dir> <starter_path>}"
STARTER_PATH="${2:?Usage: setup-context.sh <target_dir> <starter_path>}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KIT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [ ! -d "$STARTER_PATH" ]; then
    echo "Error: starter path '$STARTER_PATH' does not exist" >&2
    exit 1
fi

mkdir -p "$TARGET_DIR"
cp -r "$STARTER_PATH"/. "$TARGET_DIR"/

cd "$TARGET_DIR"

mkdir -p .claude/rules

cp "$KIT_ROOT/templates/.claude/rules/nana-soul.md" .claude/rules/
cp "$KIT_ROOT/templates/.claude/rules/file-lifecycle.md" .claude/rules/
cp "$KIT_ROOT/templates/.claude/rules/nana-personal.md" .claude/rules/

if [ -f "$KIT_ROOT/templates/AGENTS.md" ]; then
    cp "$KIT_ROOT/templates/AGENTS.md" AGENTS.md
fi

git init -q
git add -A
git commit -q -m "Initial scaffold with harness context"

# Verify: rules present, no hooks/skills
if [ ! -f ".claude/rules/nana-soul.md" ]; then
    echo "Error: nana-soul.md not found in context repo" >&2
    exit 1
fi
if [ -d ".claude/hooks" ] || [ -d ".claude/skills" ]; then
    echo "Error: hooks or skills found in context-only repo" >&2
    exit 1
fi

echo "Context-injection repo created at $TARGET_DIR"
