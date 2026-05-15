#!/usr/bin/env bash
# Install Nana Dev Kit — copies global pieces to ~/.claude/
# Run once per machine. Then use /py-init in any project to scaffold the harness.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Nana Dev Kit..."

# --- Global skill: /py-init ---
mkdir -p ~/.claude/skills/py-init
cp "$SCRIPT_DIR/templates/.claude/skills/py-init/SKILL.md" ~/.claude/skills/py-init/SKILL.md 2>/dev/null || true

# --- Identity rules (Claude Code global) ---
mkdir -p ~/.claude/rules
cp "$SCRIPT_DIR/templates/.claude/rules/nana-soul.md" ~/.claude/rules/nana-soul.md

# --- Store kit path for /py-init to find templates ---
echo "$SCRIPT_DIR" > ~/.claude/.nana-dev-kit-path

echo ""
echo "Installed:"
echo "  ~/.claude/skills/py-init/SKILL.md  — run /py-init in any Python project"
echo "  ~/.claude/rules/nana-soul.md       — Nana identity (Claude Code)"
echo "  ~/.claude/.nana-dev-kit-path       — kit location for /py-init"
echo ""
echo "Next: open a Python project and run /py-init to scaffold the 5-layer harness."
