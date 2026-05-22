#!/usr/bin/env bash
# Install Nana Dev Kit — copies global pieces to ~/.claude/
# Run once per machine. Then use /py-init in any project to scaffold the harness.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SKILL_SRC="$SCRIPT_DIR/templates/.claude/skills/py-init/SKILL.md"
SOUL_SRC="$SCRIPT_DIR/templates/.claude/rules/nana-soul.md"
PERSONAL_SRC="$SCRIPT_DIR/templates/.claude/rules/nana-personal.md"
LIFECYCLE_SRC="$SCRIPT_DIR/templates/.claude/rules/file-lifecycle.md"
SPEC_SRC="$SCRIPT_DIR/templates/.claude/skills/spec"

MEMORY_SRC="$SCRIPT_DIR/memory_server"

# Validate source files before copying
missing=0
for src in "$SKILL_SRC" "$SOUL_SRC" "$PERSONAL_SRC" "$LIFECYCLE_SRC" "$SPEC_SRC/SKILL.md"; do
  if [ ! -f "$src" ]; then
    echo "Error: source file not found: $src" >&2
    missing=1
  fi
done
if [ ! -d "$MEMORY_SRC" ]; then
  echo "Error: memory_server directory not found: $MEMORY_SRC" >&2
  missing=1
fi
[ "$missing" -eq 0 ] || exit 1

echo "Installing Nana Dev Kit..."

# --- Global skills: /py-init + /spec ---
mkdir -p ~/.claude/skills/py-init ~/.claude/skills/spec
cp "$SKILL_SRC" ~/.claude/skills/py-init/SKILL.md
cp "$SPEC_SRC"/SKILL.md ~/.claude/skills/spec/SKILL.md
cp "$SPEC_SRC"/spec-reviewer-prompt.md ~/.claude/skills/spec/spec-reviewer-prompt.md
cp "$SPEC_SRC"/adversarial-constraints-prompt.md ~/.claude/skills/spec/adversarial-constraints-prompt.md

# --- Identity rules (Claude Code global) ---
mkdir -p ~/.claude/rules
cp "$SOUL_SRC" ~/.claude/rules/nana-soul.md
if [ ! -f ~/.claude/rules/nana-personal.md ]; then
  cp "$PERSONAL_SRC" ~/.claude/rules/nana-personal.md
fi
cp "$LIFECYCLE_SRC" ~/.claude/rules/file-lifecycle.md

# --- Store kit path for /py-init to find templates ---
echo "$SCRIPT_DIR" > ~/.claude/.nana-dev-kit-path

# --- Memory MCP server ---
mkdir -p ~/.claude/memory_server
cp "$MEMORY_SRC"/*.py ~/.claude/memory_server/
cp "$MEMORY_SRC"/requirements.txt ~/.claude/memory_server/

# Create venv and install deps (graceful fallback)
VENV_DIR=~/.claude/memory_server/.venv
VENV_PYTHON="$VENV_DIR/bin/python3"
if [ ! -f "$VENV_PYTHON" ]; then
  if python3 -m venv "$VENV_DIR" 2>/dev/null; then
    "$VENV_PYTHON" -m pip install --quiet -r ~/.claude/memory_server/requirements.txt 2>/dev/null || \
      echo "Warning: pip install failed for memory_server deps. Memory MCP may not work." >&2
  else
    echo "Warning: python3 venv unavailable. Memory MCP server deps not installed." >&2
  fi
else
  "$VENV_PYTHON" -m pip install --quiet -r ~/.claude/memory_server/requirements.txt 2>/dev/null || true
fi

# Register MCP server in settings.json (idempotent JSON merge, uses venv Python)
SETTINGS=~/.claude/settings.json
python3 -c "
import json, os
path = os.path.expanduser('$SETTINGS')
venv_python = os.path.expanduser('$VENV_DIR/bin/python3')
data = {}
if os.path.isfile(path):
    with open(path) as f:
        data = json.load(f)
if 'mcpServers' not in data:
    data['mcpServers'] = {}
data['mcpServers']['memory'] = {
    'command': venv_python,
    'args': ['-m', 'memory_server'],
    'cwd': os.path.expanduser('~/.claude/memory_server')
}
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"

echo ""
echo "Installed:"
echo "  ~/.claude/skills/py-init/SKILL.md   — run /py-init in any Python project"
echo "  ~/.claude/skills/spec/              — run /spec to write contracts before execution"
echo "  ~/.claude/rules/nana-soul.md        — Nana identity (Claude Code)"
echo "  ~/.claude/rules/nana-personal.md    — personal profile (customize per user)"
echo "  ~/.claude/rules/file-lifecycle.md   — file update routing reference"
echo "  ~/.claude/.nana-dev-kit-path        — kit location for /py-init"
echo "  ~/.claude/memory_server/            — persistent memory MCP server"
echo "  ~/.claude/settings.json             — MCP server registered"
echo ""
echo "Next: open a Python project and run /py-init to scaffold the 5-layer harness."
