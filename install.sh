#!/usr/bin/env bash
# Install Nana Dev Kit — copies global pieces to ~/.claude/
# Run once per machine. Then use /py-init in any project to scaffold the harness.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SKILL_SRC="$SCRIPT_DIR/templates/.claude/skills/py-init/SKILL.md"
SOUL_SRC="$SCRIPT_DIR/templates/.claude/rules/nana-soul.md"

MEMORY_SRC="$SCRIPT_DIR/memory_server"

# Validate source files before copying
missing=0
for src in "$SKILL_SRC" "$SOUL_SRC"; do
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

# --- Global skill: /py-init ---
mkdir -p ~/.claude/skills/py-init
cp "$SKILL_SRC" ~/.claude/skills/py-init/SKILL.md

# --- Identity rules (Claude Code global) ---
mkdir -p ~/.claude/rules
cp "$SOUL_SRC" ~/.claude/rules/nana-soul.md

# --- Store kit path for /py-init to find templates ---
echo "$SCRIPT_DIR" > ~/.claude/.nana-dev-kit-path

# --- Memory MCP server ---
mkdir -p ~/.claude/memory_server
cp "$MEMORY_SRC"/*.py ~/.claude/memory_server/
cp "$MEMORY_SRC"/requirements.txt ~/.claude/memory_server/

# Register MCP server in settings.json (idempotent JSON merge)
SETTINGS=~/.claude/settings.json
python3 -c "
import json, os
path = os.path.expanduser('$SETTINGS')
data = {}
if os.path.isfile(path):
    with open(path) as f:
        data = json.load(f)
if 'mcpServers' not in data:
    data['mcpServers'] = {}
data['mcpServers']['memory'] = {
    'command': 'python3',
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
echo "  ~/.claude/rules/nana-soul.md        — Nana identity (Claude Code)"
echo "  ~/.claude/.nana-dev-kit-path        — kit location for /py-init"
echo "  ~/.claude/memory_server/            — persistent memory MCP server"
echo "  ~/.claude/settings.json             — MCP server registered"
echo ""
echo "Next: open a Python project and run /py-init to scaffold the 5-layer harness."
