#!/usr/bin/env bash
# Install Nana Dev Kit — copies global pieces to ~/.claude/
# Run once per machine. Then use /py-init in any project to scaffold the harness.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SKILL_SRC="$SCRIPT_DIR/templates/.claude/skills/py-init/SKILL.md"
SOUL_SRC="$SCRIPT_DIR/templates/.claude/rules/nana-soul.md"

# Validate source files before copying
missing=0
for src in "$SKILL_SRC" "$SOUL_SRC"; do
  if [ ! -f "$src" ]; then
    echo "Error: source file not found: $src" >&2
    missing=1
  fi
done
[ "$missing" -eq 0 ] || exit 1

echo "Installing Nana Dev Kit..."

# --- Global skill: /py-init ---
mkdir -p ~/.claude/skills/py-init
cp "$SKILL_SRC" ~/.claude/skills/py-init/SKILL.md

# --- Identity rules (Claude Code global) ---
mkdir -p ~/.claude/rules
cp "$SOUL_SRC" ~/.claude/rules/nana-soul.md

# --- Store kit path for /py-init to find templates ---
echo "$SCRIPT_DIR" > ~/.claude/.nana-dev-kit-path

echo ""
echo "Installed:"
echo "  ~/.claude/skills/py-init/SKILL.md  — run /py-init in any Python project"
echo "  ~/.claude/rules/nana-soul.md       — Nana identity (Claude Code)"
echo "  ~/.claude/.nana-dev-kit-path       — kit location for /py-init"
echo ""
echo "Next: open a Python project and run /py-init to scaffold the 5-layer harness."
