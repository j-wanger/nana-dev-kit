#!/usr/bin/env bash
# Install Nana Dev Kit — copies global pieces to ~/.claude/
# Run once per machine. Then use /py-init in any project to scaffold the harness.
#
# Flags:
#   --all            Install everything (default)
#   --core-only      Identity rules + spec + memory server only
#   --no-python      Skip py-init skill
#   --no-typescript  Skip ts-init skill
#   --project-local  Install per-project hooks (audit-log, auto-ruff-format,
#                    block-dangerous-bash, check-tests-were-run, scan-secrets,
#                    session-start) into $PWD/.claude/hooks/. No global writes.
#   --dry-run        Print actions without copying

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/templates/.claude/skills"
RULES_SRC="$SCRIPT_DIR/templates/.claude/rules"
MEMORY_SRC="$SCRIPT_DIR/memory_server"

# --- Flag parsing ---
DRY_RUN=false
SHOW_STATUS=false
PROJECT_LOCAL=false
INSTALL_CORE=true
INSTALL_PYTHON=true
INSTALL_TYPESCRIPT=true
INSTALL_DEVWIKI=true
INSTALL_KNOWLEDGE=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true ;;
    --status)
      SHOW_STATUS=true ;;
    --project-local)
      PROJECT_LOCAL=true ;;
    --core-only)
      INSTALL_PYTHON=false
      INSTALL_TYPESCRIPT=false
      INSTALL_DEVWIKI=false
      INSTALL_KNOWLEDGE=false ;;
    --no-python)
      INSTALL_PYTHON=false ;;
    --no-typescript)
      INSTALL_TYPESCRIPT=false ;;
    --all)
      INSTALL_CORE=true
      INSTALL_PYTHON=true
      INSTALL_TYPESCRIPT=true
      INSTALL_DEVWIKI=true
      INSTALL_KNOWLEDGE=true ;;
    *)
      echo "Error: unknown flag: $1" >&2
      echo "Usage: install.sh [--all|--core-only|--no-python|--no-typescript] [--project-local] [--dry-run] [--status]" >&2
      exit 1 ;;
  esac
  shift
done

# --- Project-local install (short-circuit, no global writes) ---
if $PROJECT_LOCAL; then
  HOOKS_SRC="$SCRIPT_DIR/templates/.claude/hooks"
  PROJ_HOOKS_DIR=".claude/hooks"
  PROJ_SETTINGS=".claude/settings.local.json"
  PROJECT_HOOKS=(
    "audit-log.sh"
    "auto-ruff-format.sh"
    "block-dangerous-bash.sh"
    "check-tests-were-run.sh"
    "scan-secrets.sh"
    "session-start.sh"
  )
  for h in "${PROJECT_HOOKS[@]}"; do
    [ -f "$HOOKS_SRC/$h" ] || { echo "Error: source missing: $HOOKS_SRC/$h" >&2; exit 1; }
  done
  if $DRY_RUN; then
    echo "[dry-run] --- Mode: project-local ---"
    echo "[dry-run] install hooks to $PROJ_HOOKS_DIR/: ${PROJECT_HOOKS[*]}"
    echo "[dry-run] install session-start.d/ modules (wk-prune.sh, memory-nudge.sh)"
    echo "[dry-run] register hooks in $PROJ_SETTINGS (nested schema)"
  else
    mkdir -p "$PROJ_HOOKS_DIR"
    for h in "${PROJECT_HOOKS[@]}"; do
      cp "$HOOKS_SRC/$h" "$PROJ_HOOKS_DIR/$h"
      chmod +x "$PROJ_HOOKS_DIR/$h"
    done
    # Copy session-start.d/ modules (sourced by session-start.sh)
    if [ -d "$HOOKS_SRC/session-start.d" ]; then
      mkdir -p "$PROJ_HOOKS_DIR/session-start.d"
      cp "$HOOKS_SRC/session-start.d"/*.sh "$PROJ_HOOKS_DIR/session-start.d/"
    fi
    python3 -c "
import json, os
path = '$PROJ_SETTINGS'
data = {}
if os.path.isfile(path):
    with open(path) as f:
        data = json.load(f)
if 'hooks' not in data:
    data['hooks'] = {}
hooks = data['hooks']

def upsert(event, matcher, hook_file):
    cmd = '.claude/hooks/' + hook_file
    if event not in hooks:
        hooks[event] = []
    for e in hooks[event]:
        for h in e.get('hooks', []):
            if h.get('command', '').endswith(hook_file):
                return
        if e.get('command', '').endswith(hook_file) and 'hooks' not in e:
            new = {'type': 'command', 'command': cmd}
            keep_matcher = e.get('matcher')
            e.clear()
            if keep_matcher: e['matcher'] = keep_matcher
            e['hooks'] = [new]
            return
    entry = {}
    if matcher: entry['matcher'] = matcher
    entry['hooks'] = [{'type': 'command', 'command': cmd}]
    hooks[event].append(entry)

upsert('SessionStart', '', 'session-start.sh')
upsert('PostToolUse', 'Edit|Write', 'audit-log.sh')
upsert('PostToolUse', 'Edit|Write', 'auto-ruff-format.sh')
upsert('PreToolUse', 'Bash', 'block-dangerous-bash.sh')
upsert('Stop', '', 'check-tests-were-run.sh')
upsert('PostToolUse', 'Edit|Write', 'scan-secrets.sh')

with open(path, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
    echo ""
    echo "Project-local hooks installed in $PROJ_HOOKS_DIR/"
    echo "  - audit-log.sh           — PostToolUse:Edit|Write — JSONL audit"
    echo "  - auto-ruff-format.sh    — PostToolUse:Edit|Write — Python ruff format"
    echo "  - block-dangerous-bash.sh — PreToolUse:Bash       — block rm -rf etc"
    echo "  - check-tests-were-run.sh — Stop                  — test reminder"
    echo "  - scan-secrets.sh        — PostToolUse:Edit|Write — gitleaks/secrets"
    echo "  - session-start.sh       — SessionStart           — dev-wiki + memory nudge"
  fi
  exit 0
fi

# --- Status check (early return, no writes) ---
if $SHOW_STATUS; then
  echo "=== Nana Dev Kit Status ==="
  KIT_PATH=""
  if [ -f "$HOME/.claude/.nana-dev-kit-path" ]; then
    KIT_PATH=$(cat "$HOME/.claude/.nana-dev-kit-path" 2>/dev/null || true)
  fi
  if [ -n "$KIT_PATH" ] && [ -f "$KIT_PATH/VERSION" ]; then
    echo "  version: $(cat "$KIT_PATH/VERSION")"
  else
    echo "  version: unknown (kit path marker missing)"
  fi
  echo ""
  echo "Core:"
  RULES_COUNT=$(ls "$HOME/.claude/rules/"*.md 2>/dev/null | wc -l | tr -d ' ')
  echo "  rules:   $RULES_COUNT files in ~/.claude/rules/"
  if [ -d "$HOME/.claude/memory_server/.venv" ]; then
    echo "  memory:  active (venv at ~/.claude/memory_server/.venv/)"
  else
    echo "  memory:  absent (no venv found)"
  fi
  echo ""
  echo "Skills:"
  SKILL_COUNT=$(ls -d "$HOME/.claude/skills"/*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')
  echo "  skills:  $SKILL_COUNT installed"
  PY_SKILLS=$(ls -d "$HOME/.claude/skills"/py-*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')
  DEV_SKILLS=$(ls -d "$HOME/.claude/skills"/dev-*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')
  WIKI_SKILLS=$(ls -d "$HOME/.claude/skills"/wiki-*/SKILL.md "$HOME/.claude/skills"/knowledge-wiki/SKILL.md 2>/dev/null | wc -l | tr -d ' ')
  TS_SKILLS=$(ls -d "$HOME/.claude/skills"/ts-*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')
  echo "    python:    $PY_SKILLS"
  echo "    typescript: $TS_SKILLS"
  echo "    lifecycle: $DEV_SKILLS"
  echo "    wiki:      $WIKI_SKILLS"
  echo ""
  echo "Hooks:"
  HOOK_COUNT=$(ls "$HOME/.claude/hooks/"*.sh 2>/dev/null | wc -l | tr -d ' ')
  echo "  hooks:   $HOOK_COUNT installed in ~/.claude/hooks/"
  if [ -f "$HOME/.claude/enforce" ]; then
    echo "  enforce: active"
  else
    echo "  enforce: inactive"
  fi
  exit 0
fi

# --- Module dependency validation ---
if [ "$INSTALL_PYTHON" = true ] && [ "$INSTALL_CORE" = false ]; then
  echo "Error: module 'python' requires 'core' but it is not selected." >&2
  exit 1
fi
if [ "$INSTALL_TYPESCRIPT" = true ] && [ "$INSTALL_CORE" = false ]; then
  echo "Error: module 'typescript' requires 'core' but it is not selected." >&2
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
TYPESCRIPT_SKILLS="ts-init"
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
if [ "$INSTALL_TYPESCRIPT" = true ] && [ ! -f "$SKILLS_SRC/ts-init/SKILL.md" ]; then
  echo "Error: source file not found: $SKILLS_SRC/ts-init/SKILL.md" >&2
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
    'cwd': os.path.expanduser('~/.claude')
}
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"

    # Verify MCP server can start
    if (cd ~/.claude && "$VENV_DIR/bin/python3" -c "import memory_server" 2>/dev/null); then
      echo "  MCP memory server: verified"
    else
      echo ""
      echo "WARNING: MCP memory server installed but cannot start."
      echo "  python: $VENV_DIR/bin/python3"
      echo "  cwd: ~/.claude"
      echo "  Try: cd ~/.claude && $VENV_DIR/bin/python3 -m memory_server"
      echo ""
    fi
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

# === TypeScript module ===
if [ "$INSTALL_TYPESCRIPT" = true ]; then
  if $DRY_RUN; then
    echo "[dry-run] --- Module: typescript ---"
  fi
  for skill in $TYPESCRIPT_SKILLS; do
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

  # Global hooks: enforcement + lifecycle (11 total)
  HOOKS_SRC="$SCRIPT_DIR/templates/.claude/hooks"
  GLOBAL_HOOKS=(
    "enforce-spec.sh"
    "enforce-loop.sh"
    "enforce-memory.sh"
    "detect-loop.sh"
    "pre-compact.sh"
    "post-commit.sh"
    "context-size-check.sh"
    "dev-wiki-scope-check.sh"
    "post-compact.sh"
    "session-stop.sh"
    "stale-queue.sh"
  )
  if $DRY_RUN; then
    echo "[dry-run] install hooks (11): ${GLOBAL_HOOKS[*]}"
    echo "[dry-run] remove superseded: dev-wiki-post-commit.sh (replaced by post-commit.sh)"
    echo "[dry-run] register hooks in settings.json (nested {matcher, hooks:[{type, command}]} schema)"
    echo "[dry-run] create enforce marker: ~/.claude/enforce"
  else
    mkdir -p ~/.claude/hooks
    for h in "${GLOBAL_HOOKS[@]}"; do
      [ -f "$HOOKS_SRC/$h" ] || { echo "Error: source missing: $HOOKS_SRC/$h" >&2; exit 1; }
      cp "$HOOKS_SRC/$h" ~/.claude/hooks/"$h"
      chmod +x ~/.claude/hooks/"$h"
    done
    # Remove superseded duplicate (kit's post-commit.sh replaces this — same trigger, more robust)
    rm -f ~/.claude/hooks/dev-wiki-post-commit.sh
    touch ~/.claude/enforce
    touch ~/.claude/enforce-memory

    # Register hooks in settings.json using Claude Code's nested schema:
    # {matcher, hooks:[{type:"command", command}]} — NOT the legacy flat {matcher, command}.
    # Migrates any pre-existing flat-shape entries to the nested shape.
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

def cmd_path(name):
    return os.path.expanduser('~/.claude/hooks/' + name)

def upsert(event, matcher, hook_file):
    cmd = cmd_path(hook_file)
    if event not in hooks:
        hooks[event] = []
    # Already present in nested shape?
    for e in hooks[event]:
        for inner in e.get('hooks', []):
            if inner.get('command', '').endswith(hook_file):
                return
    # Pre-existing flat-shape entry? Migrate it.
    for e in hooks[event]:
        if e.get('command', '').endswith(hook_file) and 'hooks' not in e:
            keep_matcher = e.get('matcher')
            e.clear()
            if keep_matcher: e['matcher'] = keep_matcher
            e['hooks'] = [{'type': 'command', 'command': cmd}]
            return
    # New entry.
    entry = {}
    if matcher: entry['matcher'] = matcher
    entry['hooks'] = [{'type': 'command', 'command': cmd}]
    hooks[event].append(entry)

# PreToolUse
upsert('PreToolUse', 'Write|Edit', 'enforce-spec.sh')
upsert('PreToolUse', 'Write|Edit', 'enforce-memory.sh')
upsert('PreToolUse', 'Write|Edit', 'dev-wiki-scope-check.sh')

# PostToolUse
upsert('PostToolUse', 'Bash', 'detect-loop.sh')
upsert('PostToolUse', 'Bash', 'post-commit.sh')
upsert('PostToolUse', 'Edit|Write', 'stale-queue.sh')

# Stop
upsert('Stop', '', 'enforce-loop.sh')
upsert('Stop', '', 'session-stop.sh')

# PreCompact + PostCompact
upsert('PreCompact', '', 'pre-compact.sh')
upsert('PostCompact', '', 'post-compact.sh')

# UserPromptSubmit
upsert('UserPromptSubmit', '', 'context-size-check.sh')

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
  [ "$INSTALL_TYPESCRIPT" = true ] && echo "  ~/.claude/skills/ts-init/           — /ts-init TypeScript scaffolding"
  [ "$INSTALL_DEVWIKI" = true ] && echo "  ~/.claude/skills/dev-*/             — dev-wiki lifecycle (6 skills)"
  [ "$INSTALL_DEVWIKI" = true ] && echo "  ~/.claude/hooks/                    — lifecycle hooks (enforce, detect-loop, post-commit, pre-compact)"
  [ "$INSTALL_KNOWLEDGE" = true ] && echo "  ~/.claude/skills/wiki-*/            — knowledge-wiki pipeline (11 skills)"
  echo ""
  echo "Getting started (open a project, then run one of these):"
  echo "  /dev-init     — bootstrap dev-wiki lifecycle tracking"
  echo "  /py-init      — scaffold Python project with full toolchain"
  echo "  /ts-init      — scaffold TypeScript project with full toolchain"
  echo "  /wiki-init    — start a knowledge wiki for your domain"
else
  echo ""
  echo "[dry-run] Getting started: /dev-init (lifecycle), /py-init (Python), /ts-init (TypeScript), /wiki-init (knowledge)"
fi
