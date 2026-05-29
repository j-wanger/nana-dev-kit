#!/usr/bin/env bash
# Install Nana Dev Kit — copies global pieces to ~/.claude/
# Run once per machine. Then use /nana-init in any project to scaffold the harness.
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
MODULES_JSON="$SCRIPT_DIR/modules.json"
REGISTER_SCRIPT="$SCRIPT_DIR/scripts/register-settings.py"

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

command -v jq >/dev/null 2>&1 || { echo "Error: jq is required. Install with: brew install jq (macOS) or apt install jq (Linux)." >&2; exit 1; }

# --- Project-local install (short-circuit, no global writes) ---
if $PROJECT_LOCAL; then
  HOOKS_SRC="$SCRIPT_DIR/templates/.claude/hooks"
  PROJ_HOOKS_DIR=".claude/hooks"
  PROJ_SETTINGS=".claude/settings.local.json"
  PROJECT_HOOKS=$(jq -r '.hooks[] | select(.scope == "project") | .script' "$MODULES_JSON")
  EXTRA_DIRS=$(jq -r '.project_local.extra_dirs[]' "$MODULES_JSON" 2>/dev/null || true)
  for h in $PROJECT_HOOKS; do
    [ -f "$HOOKS_SRC/$h" ] || { echo "Error: source missing: $HOOKS_SRC/$h" >&2; exit 1; }
  done
  if $DRY_RUN; then
    echo "[dry-run] --- Mode: project-local ---"
    echo "[dry-run] install hooks to $PROJ_HOOKS_DIR/: $PROJECT_HOOKS"
    [ -n "$EXTRA_DIRS" ] && echo "[dry-run] install extra dirs: $EXTRA_DIRS"
    echo "[dry-run] register hooks in $PROJ_SETTINGS (nested schema)"
    echo "[dry-run] create project enforce marker: .claude/enforce"
  else
    mkdir -p "$PROJ_HOOKS_DIR"
    for h in $PROJECT_HOOKS; do
      cp "$HOOKS_SRC/$h" "$PROJ_HOOKS_DIR/$h"
      chmod +x "$PROJ_HOOKS_DIR/$h"
    done
    for d in $EXTRA_DIRS; do
      if [ -d "$HOOKS_SRC/$d" ]; then
        mkdir -p "$PROJ_HOOKS_DIR/$d"
        cp "$HOOKS_SRC/$d"/*.sh "$PROJ_HOOKS_DIR/$d/"
      fi
    done
    python3 "$REGISTER_SCRIPT" hooks "$PROJ_SETTINGS" "$MODULES_JSON" \
      --scope project-local --hooks-dir "$PROJ_HOOKS_DIR"
    touch .claude/enforce
    echo ""
    echo "Project-local hooks installed in $PROJ_HOOKS_DIR/"
    echo "Enforcement marker created: .claude/enforce"
    jq -r '.hooks[] | select(.scope == "project") | "  - \(.script) — \(.event):\(.matcher) "' "$MODULES_JSON" | sed 's/:  *$//'
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

# --- Helper: read skill list from modules.json ---
module_skills() {
  jq -r --arg m "$1" '.modules[] | select(.name == $m) | .skills[]' "$MODULES_JSON"
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

# --- Source validation ---
missing=0
[ "$INSTALL_CORE" = true ] && for src in "$RULES_SRC/nana-soul.md" "$RULES_SRC/nana-personal.md" "$RULES_SRC/file-lifecycle.md"; do
  [ -f "$src" ] || { echo "Error: source file not found: $src" >&2; missing=1; }
done
[ "$INSTALL_CORE" = true ] && [ ! -d "$MEMORY_SRC" ] && { echo "Error: memory_server directory not found: $MEMORY_SRC" >&2; missing=1; }
[ "$INSTALL_PYTHON" = true ] && [ ! -f "$SKILLS_SRC/py-init/SKILL.md" ] && { echo "Error: source file not found: $SKILLS_SRC/py-init/SKILL.md" >&2; missing=1; }
[ "$INSTALL_TYPESCRIPT" = true ] && [ ! -f "$SKILLS_SRC/ts-init/SKILL.md" ] && { echo "Error: source file not found: $SKILLS_SRC/ts-init/SKILL.md" >&2; missing=1; }
[ "$missing" -eq 0 ] || exit 1

# --- Execute ---
if ! $DRY_RUN; then echo "Installing Nana Dev Kit..."; fi

# === Core module: rules + skills + memory + kit path ===
if [ "$INSTALL_CORE" = true ]; then
  $DRY_RUN && echo "[dry-run] --- Module: core ---"

  if $DRY_RUN; then
    echo "[dry-run] copy rules: nana-soul.md, file-lifecycle.md"
    [ ! -f "$HOME/.claude/rules/nana-personal.md" ] && echo "[dry-run] copy rules: nana-personal.md (new install)" || echo "[dry-run] skip: nana-personal.md (already exists)"
    for skill in $(module_skills core); do install_skill_dir "$skill"; done
    echo "[dry-run] write kit path marker + install memory_server + venv + MCP registration"
  else
    mkdir -p ~/.claude/rules
    cp "$RULES_SRC/nana-soul.md" ~/.claude/rules/nana-soul.md
    [ ! -f ~/.claude/rules/nana-personal.md ] && cp "$RULES_SRC/nana-personal.md" ~/.claude/rules/nana-personal.md
    cp "$RULES_SRC/file-lifecycle.md" ~/.claude/rules/file-lifecycle.md
    for skill in $(module_skills core); do install_skill_dir "$skill"; done
    echo "$SCRIPT_DIR" > ~/.claude/.nana-dev-kit-path
    mkdir -p ~/.claude/memory_server
    cp "$MEMORY_SRC"/*.py ~/.claude/memory_server/
    cp "$MEMORY_SRC"/requirements.txt ~/.claude/memory_server/

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

    python3 "$REGISTER_SCRIPT" mcp ~/.claude/settings.json \
      --python "$VENV_DIR/bin/python3" --cwd ~/.claude

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
  $DRY_RUN && echo "[dry-run] --- Module: python ---"
  for skill in $(module_skills python); do install_skill_dir "$skill"; done
fi

# === TypeScript module ===
if [ "$INSTALL_TYPESCRIPT" = true ]; then
  $DRY_RUN && echo "[dry-run] --- Module: typescript ---"
  for skill in $(module_skills typescript); do install_skill_dir "$skill"; done
fi

# === Dev-wiki module: skills + hooks + markers ===
if [ "$INSTALL_DEVWIKI" = true ]; then
  $DRY_RUN && echo "[dry-run] --- Module: dev-wiki ---"
  for skill in $(module_skills dev-wiki); do install_skill_dir "$skill"; done

  HOOKS_SRC="$SCRIPT_DIR/templates/.claude/hooks"
  HOOK_SCRIPTS=$(jq -r '.hooks[] | select(.scope == "global") | .script' "$MODULES_JSON" | sort -u)
  MARKERS=$(jq -r '.modules[] | select(.name == "dev-wiki") | .markers[]' "$MODULES_JSON")

  if $DRY_RUN; then
    HOOK_COUNT=$(echo "$HOOK_SCRIPTS" | wc -l | tr -d ' ')
    echo "[dry-run] install hooks ($HOOK_COUNT): $HOOK_SCRIPTS"
    echo "[dry-run] register hooks in settings.json (nested schema)"
    echo "[dry-run] create markers: $MARKERS"
  else
    mkdir -p ~/.claude/hooks
    for h in $HOOK_SCRIPTS; do
      [ -f "$HOOKS_SRC/$h" ] || { echo "Error: source missing: $HOOKS_SRC/$h" >&2; exit 1; }
      cp "$HOOKS_SRC/$h" ~/.claude/hooks/"$h"
      chmod +x ~/.claude/hooks/"$h"
    done

    GHOSTS=$(jq -r '.ghost_cleanup[]' "$MODULES_JSON" 2>/dev/null || true)
    for g in $GHOSTS; do rm -f ~/.claude/hooks/"$g".sh; done
    for m in $MARKERS; do touch "$(eval echo "$m")"; done

    python3 "$REGISTER_SCRIPT" hooks ~/.claude/settings.json "$MODULES_JSON" --scope global
  fi
fi

# === Knowledge-wiki module ===
if [ "$INSTALL_KNOWLEDGE" = true ]; then
  $DRY_RUN && echo "[dry-run] --- Module: knowledge-wiki ---"
  for skill in $(module_skills knowledge-wiki); do install_skill_dir "$skill"; done
fi

# --- Summary ---
if ! $DRY_RUN; then
  echo ""
  echo "Installed:"
  [ "$INSTALL_CORE" = true ] && echo "  ~/.claude/rules/                    — identity (soul, personal, file-lifecycle)"
  [ "$INSTALL_CORE" = true ] && echo "  ~/.claude/skills/{spec,nana,memory-consolidate,nana-init}/ — core skills"
  [ "$INSTALL_CORE" = true ] && echo "  ~/.claude/memory_server/            — persistent memory MCP server"
  [ "$INSTALL_CORE" = true ] && echo "  ~/.claude/.nana-dev-kit-path        — kit location marker"
  [ "$INSTALL_PYTHON" = true ] && echo "  ~/.claude/skills/py-init/           — /py-init Python scaffolding"
  [ "$INSTALL_TYPESCRIPT" = true ] && echo "  ~/.claude/skills/ts-init/           — /ts-init TypeScript scaffolding"
  [ "$INSTALL_DEVWIKI" = true ] && echo "  ~/.claude/skills/dev-*/             — dev-wiki lifecycle (6 skills)"
  [ "$INSTALL_DEVWIKI" = true ] && echo "  ~/.claude/hooks/                    — global session hooks (lifecycle + enforcement hooks install per-project via /py-init or --project-local)"
  [ "$INSTALL_KNOWLEDGE" = true ] && echo "  ~/.claude/skills/wiki-*/            — knowledge-wiki pipeline (11 skills)"
  echo ""
  echo "Getting started (open a project, then run one of these):"
  echo "  /nana-init    — bootstrap full Nana experience (recommended)"
  echo "  /dev-init     — bootstrap dev-wiki lifecycle tracking"
  echo "  /py-init      — scaffold Python project with full toolchain"
  echo "  /ts-init      — scaffold TypeScript project with full toolchain"
  echo "  /wiki-init    — start a knowledge wiki for your domain"
else
  echo ""
  echo "[dry-run] Getting started: /nana-init (full bootstrap), /dev-init (lifecycle), /py-init (Python), /ts-init (TypeScript), /wiki-init (knowledge)"
fi
