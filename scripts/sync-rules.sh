#!/usr/bin/env bash
# Sync AGENTS.md (single source of truth) to per-agent-surface copies.
# Usage: sync-rules.sh <template-dir> <target-dir>
#   template-dir: directory containing AGENTS.md
#   target-dir:   project root where per-surface copies are written
#
# Surfaces generated:
#   CLAUDE.md                          — Claude Code
#   .github/copilot-instructions.md   — GitHub Copilot
#   .cursor/rules/main.mdc            — Cursor
#   GEMINI.md                          — Gemini CLI
#
# Run as: make sync-rules, or as a pre-commit hook.

set -euo pipefail

TEMPLATE_DIR="${1:-.}"
TARGET_DIR="${2:-.}"

AGENTS_MD="$TEMPLATE_DIR/AGENTS.md"

if [ ! -f "$AGENTS_MD" ]; then
  echo "Error: $AGENTS_MD not found" >&2
  exit 1
fi

if [ ! -w "$TARGET_DIR" ]; then
  echo "Error: target directory not writable: $TARGET_DIR" >&2
  exit 1
fi

CONTENT=$(cat "$AGENTS_MD")
HEADER="<!-- AUTO-GENERATED from AGENTS.md — do not edit directly. Run: make sync-rules -->"

# --- CLAUDE.md ---
cat > "$TARGET_DIR/CLAUDE.md" <<EOF
$HEADER

$CONTENT
EOF

# --- .github/copilot-instructions.md ---
mkdir -p "$TARGET_DIR/.github"
cat > "$TARGET_DIR/.github/copilot-instructions.md" <<EOF
$HEADER

$CONTENT
EOF

# --- .cursor/rules/main.mdc ---
mkdir -p "$TARGET_DIR/.cursor/rules"
cat > "$TARGET_DIR/.cursor/rules/main.mdc" <<EOF
---
description: Project conventions and rules (synced from AGENTS.md)
globs:
alwaysApply: true
---

$HEADER

$CONTENT
EOF

# --- GEMINI.md ---
cat > "$TARGET_DIR/GEMINI.md" <<EOF
$HEADER

$CONTENT
EOF

echo "Synced AGENTS.md → CLAUDE.md, .github/copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md"
