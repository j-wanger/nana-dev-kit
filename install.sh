#!/usr/bin/env bash
# Install Nana Dev Kit — copies global pieces to ~/.claude/
# Run once per machine. Then use /py-init in any project to scaffold the harness.
#
# Flags:
#   --all          Install everything (default)
#   --core-only    Identity rules + spec + memory server only
#   --no-python    Skip py-init skill
#   --dry-run      Print actions without copying

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/templates/.claude/skills"
RULES_SRC="$SCRIPT_DIR/templates/.claude/rules"
MEMORY_SRC="$SCRIPT_DIR/memory_server"

# --- Flag parsing ---
DRY_RUN=false
INSTALL_CORE=true
INSTALL_PYTHON=true
INSTALL_DEVWIKI=true
INSTALL_KNOWLEDGE=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true ;;
    --core-only)
      INSTALL_PYTHON=false
      INSTALL_DEVWIKI=false
      INSTALL_KNOWLEDGE=false ;;
    --no-python)
      INSTALL_PYTHON=false ;;
    --all)
      INSTALL_CORE=true
      INSTALL_PYTHON=true
      INSTALL_DEVWIKI=true
      INSTALL_KNOWLEDGE=true ;;
    *)
      echo "Error: unknown flag: $1" >&2
      echo "Usage: install.sh [--all|--core-only|--no-python] [--dry-run]" >&2
      exit 1 ;;
  esac
  shift
done

# --- Module dependency validation ---
if [ "$INSTALL_PYTHON" = true ] && [ "$INSTALL_CORE" = false ]; then
  echo "Error: module 'python' requires 'core' but it is not selected." >&2
  exit 1
fi
if [ "$INSTALL_DEVWIKI" = true ] && [ "$INSTALL_CORE" = false ]; then
  echo "Error: module 'dev-wiki' requires 'core' but it is not selected." >&2
  exit 1
fi
if [ "$INSTALL_KNOWLEDGE" = true ] && [ "$INSTALL_CORE" = false ]; then
  echo "Error: module 'knowledge-wiki' requires 'core' but it is not selected." >&2
  exit 1
fi

# --- Skill directory definitions ---
CORE_SKILLS="spec"
PYTHON_SKILLS="py-init"
DEVWIKI_SKILLS="dev-wiki dev-check dev-debrief dev-init dev-plan dev-scan"
KNOWLEDGE_SKILLS="knowledge-wiki wiki-absorb wiki-add wiki-bootstrap wiki-consolidate wiki-health wiki-index wiki-init wiki-query wiki-reorg wiki-registry"

# --- Helper functions ---
do_copy() {
  local src="$1" dest="$2"
  if $DRY_RUN; then
    echo "[dry-run] copy $src → $dest"
  else
    mkdir -p "$(dirname "$dest")"
    cp -r "$src" "$dest"
  fi
}

install_skill_dir() {
  local skill="$1"
  local src="$SKILLS_SRC/$skill"
  local dest="$HOME/.claude/skills/$skill"
  if [ ! -d "$src" ]; then
    echo "Warning: skill source not found: $src" >&2
    return 0
  fi
  if $DRY_RUN; then
    echo "[dry-run] install skill: $skill ($(find "$src" -type f | wc -l | tr -d ' ') files)"
  else
    mkdir -p "$dest"
    cp -r "$src"/* "$dest"/
  fi
}

# --- Source validation (based on selected modules) ---
missing=0
if [ "$INSTALL_CORE" = true ]; then
  for src in "$RULES_SRC/nana-soul.md" "$RULES_SRC/nana-personal.md" "$RULES_SRC/file-lifecycle.md" "$SKILLS_SRC/spec/SKILL.md"; do
    if [ ! -f "$src" ]; then
      echo "Error: source file not found: $src" >&2
      missing=1
    fi
  done
  if [ ! -d "$MEMORY_SRC" ]; then
    echo "Error: memory_server directory not found: $MEMORY_SRC" >&2
    missing=1
  fi
fi
if [ "$INSTALL_PYTHON" = true ] && [ ! -f "$SKILLS_SRC/py-init/SKILL.md" ]; then
  echo "Error: source file not found: $SKILLS_SRC/py-init/SKILL.md" >&2
  missing=1
fi
[ "$missing" -eq 0 ] || exit 1

# --- Execute ---
if ! $DRY_RUN; then echo "Installing Nana Dev Kit..."; fi

# === Core module: rules + spec + memory + kit path ===
if [ "$INSTALL_CORE" = true ]; then
  if $DRY_RUN; then
    echo "[dry-run] --- Module: core ---"
  fi

  # Identity rules
  if $DRY_RUN; then
    echo "[dry-run] copy rules: nana-soul.md, file-lifecycle.md"
    if [ ! -f "$HOME/.claude/rules/nana-personal.md" ]; then
      echo "[dry-run] copy rules: nana-personal.md (new install)"
    else
      echo "[dry-run] skip: nana-personal.md (already exists)"
    fi
  else
    mkdir -p ~/.claude/rules
    cp "$RULES_SRC/nana-soul.md" ~/.claude/rules/nana-soul.md
    if [ ! -f ~/.claude/rules/nana-personal.md ]; then
      cp "$RULES_SRC/nana-personal.md" ~/.claude/rules/nana-personal.md
    fi
    cp "$RULES_SRC/file-lifecycle.md" ~/.claude/rules/file-lifecycle.md
  fi

  # Spec skill
  install_skill_dir "spec"

  # Kit path marker
  if $DRY_RUN; then
    echo "[dry-run] write kit path marker: ~/.claude/.nana-dev-kit-path"
  else
    echo "$SCRIPT_DIR" > ~/.claude/.nana-dev-kit-path
  fi

  # Memory MCP server
  if $DRY_RUN; then
    echo "[dry-run] install memory_server + venv + MCP registration"
  else
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

    # Register MCP server in settings.json (idempotent JSON merge)
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
  fi
fi

# === Python module ===
if [ "$INSTALL_PYTHON" = true ]; then
  if $DRY_RUN; then
    echo "[dry-run] --- Module: python ---"
  fi
  for skill in $PYTHON_SKILLS; do
    install_skill_dir "$skill"
  done
fi

# === Dev-wiki module ===
if [ "$INSTALL_DEVWIKI" = true ]; then
  if $DRY_RUN; then
    echo "[dry-run] --- Module: dev-wiki ---"
  fi
  for skill in $DEVWIKI_SKILLS; do
    install_skill_dir "$skill"
  done

  # Enforcement hooks
  HOOKS_SRC="$SCRIPT_DIR/templates/.claude/hooks"
  if $DRY_RUN; then
    echo "[dry-run] install hooks: enforce-spec.sh, enforce-loop.sh, detect-loop.sh"
    echo "[dry-run] register hooks in settings.json"
    echo "[dry-run] create enforce marker: ~/.claude/enforce"
  else
    mkdir -p ~/.claude/hooks
    cp "$HOOKS_SRC/enforce-spec.sh" ~/.claude/hooks/enforce-spec.sh
    cp "$HOOKS_SRC/enforce-loop.sh" ~/.claude/hooks/enforce-loop.sh
    cp "$HOOKS_SRC/detect-loop.sh" ~/.claude/hooks/detect-loop.sh
    chmod +x ~/.claude/hooks/enforce-spec.sh ~/.claude/hooks/enforce-loop.sh ~/.claude/hooks/detect-loop.sh
    touch ~/.claude/enforce

    # Register hooks in settings.json (idempotent JSON merge)
    SETTINGS=~/.claude/settings.json
    python3 -c "
import json, os
path = os.path.expanduser('$SETTINGS')
data = {}
if os.path.isfile(path):
    with open(path) as f:
        data = json.load(f)
if 'hooks' not in data:
    data['hooks'] = {}
hooks = data['hooks']
spec_hook = {'matcher': 'Write|Edit', 'command': os.path.expanduser('~/.claude/hooks/enforce-spec.sh')}
loop_hook = {'command': os.path.expanduser('~/.claude/hooks/enforce-loop.sh')}
if 'PreToolUse' not in hooks:
    hooks['PreToolUse'] = []
detect_hook = {'matcher': 'Bash', 'command': os.path.expanduser('~/.claude/hooks/detect-loop.sh')}
if not any(h.get('command','').endswith('enforce-spec.sh') for h in hooks['PreToolUse']):
    hooks['PreToolUse'].append(spec_hook)
if 'PostToolUse' not in hooks:
    hooks['PostToolUse'] = []
if not any(h.get('command','').endswith('detect-loop.sh') for h in hooks['PostToolUse']):
    hooks['PostToolUse'].append(detect_hook)
if 'Stop' not in hooks:
    hooks['Stop'] = []
if not any(h.get('command','').endswith('enforce-loop.sh') for h in hooks['Stop']):
    hooks['Stop'].append(loop_hook)
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
  fi
fi

# === Knowledge-wiki module ===
if [ "$INSTALL_KNOWLEDGE" = true ]; then
  if $DRY_RUN; then
    echo "[dry-run] --- Module: knowledge-wiki ---"
  fi
  for skill in $KNOWLEDGE_SKILLS; do
    install_skill_dir "$skill"
  done
fi

# --- Summary ---
if ! $DRY_RUN; then
  echo ""
  echo "Installed:"
  [ "$INSTALL_CORE" = true ] && echo "  ~/.claude/rules/                    — identity (soul, personal, file-lifecycle)"
  [ "$INSTALL_CORE" = true ] && echo "  ~/.claude/skills/spec/              — /spec contract creation"
  [ "$INSTALL_CORE" = true ] && echo "  ~/.claude/memory_server/            — persistent memory MCP server"
  [ "$INSTALL_CORE" = true ] && echo "  ~/.claude/.nana-dev-kit-path        — kit location marker"
  [ "$INSTALL_PYTHON" = true ] && echo "  ~/.claude/skills/py-init/           — /py-init Python scaffolding"
  [ "$INSTALL_DEVWIKI" = true ] && echo "  ~/.claude/skills/dev-*/             — dev-wiki lifecycle (6 skills)"
  [ "$INSTALL_DEVWIKI" = true ] && echo "  ~/.claude/hooks/enforce-*.sh        — enforcement hooks (spec + loop)"
  [ "$INSTALL_KNOWLEDGE" = true ] && echo "  ~/.claude/skills/wiki-*/            — knowledge-wiki pipeline (11 skills)"
  echo ""
  echo "Next: open a project and run /dev-init to bootstrap the dev lifecycle."
fi
