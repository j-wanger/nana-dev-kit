#!/usr/bin/env bash
# check-install-drift.sh — detect when the installed ~/.claude has drifted from the kit
# source (templates/.claude). The kit DEVELOPS in templates/ but RUNS from ~/.claude, so a
# stale installed copy silently undermines work (bit twice: Phase-73 curator gap, Phase-75
# stale delivery-flow). Deterministic comparator over the kit-managed copy-verbatim set.
#
# Usage:
#   check-install-drift.sh [installed-root]   # human report; exit 0 = synced, 1 = drift
#   check-install-drift.sh --count [root]      # print drift count only; ALWAYS exit 0 (fail-open)
#   check-install-drift.sh --excludes          # print the pinned exclusion allow-list, one per line
#
# installed-root defaults to $HOME/.claude (overridable via the arg or $NANA_INSTALLED_ROOT for
# hermetic tests — NEVER touch the real ~/.claude in tests).
#
# Comparison set (from modules.json, the single source of truth): every file under each installed
# skill dir + global-scope hook scripts + the managed rules directory. Assumes a full (--all)
# install (the maintainer's case): a skill dir absent from the installed root is treated as a
# not-installed module and skipped, not as drift. NOTE: only scope:global hooks are compared
# (just context-size-check.sh); project-scoped hooks like session-start.sh install per-project
# (via /py-init or --project-local), NOT to ~/.claude, so their drift is out of this set by design.
#
# FAIL-OPEN: missing prerequisites or files never crash — the worst case is "say nothing".

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES="$KIT_ROOT/templates/.claude"
MODULES_JSON="$KIT_ROOT/modules.json"

# Pinned, bounded exclusion allow-list (paths relative to .claude/). Files legitimately divergent
# between templates/ and the installed copy: merged, user-customized, or runtime. Bounded — guards
# against silent scope-shrink (hiding real drift by quietly excluding files). The firing-coverage-
# exemption analog.
EXCLUDE=(
  "rules/nana-personal.md"     # user-customized; copied only on a fresh install, never overwritten
  "rules/py-session-state.md"  # runtime session-state template, not installed globally
  "settings.json"              # merged by register-settings.py, never copied verbatim
)

# --- Arg parsing ---
MODE="report"
ROOT_ARG=""
for a in "$@"; do
  case "$a" in
    --count) MODE="count" ;;
    --excludes) MODE="excludes" ;;
    *) ROOT_ARG="$a" ;;
  esac
done

if [ "$MODE" = "excludes" ]; then
  printf '%s\n' "${EXCLUDE[@]}"
  exit 0
fi

INSTALLED_ROOT="${ROOT_ARG:-${NANA_INSTALLED_ROOT:-$HOME/.claude}}"

# --- Fail-open guards: if we can't run a meaningful comparison, say nothing ---
emit_count_and_exit() { [ "$MODE" = "count" ] && echo "${1:-0}"; }
if ! command -v jq >/dev/null 2>&1 || [ ! -d "$TEMPLATES" ] || [ ! -f "$MODULES_JSON" ] || [ ! -d "$INSTALLED_ROOT" ]; then
  emit_count_and_exit 0
  exit 0
fi

is_excluded() {
  local rel="$1" e
  for e in "${EXCLUDE[@]}"; do
    [ "$rel" = "$e" ] && return 0
  done
  return 1
}

# --- Build the comparison set: relative paths (under .claude/) of kit-managed copy-verbatim files ---
REL_FILES=()

# 1. Skills — every file under each skill dir that is actually installed (skip not-installed modules).
while IFS= read -r skill; do
  [ -n "$skill" ] || continue
  sdir="$TEMPLATES/skills/$skill"
  [ -d "$sdir" ] || continue
  [ -d "$INSTALLED_ROOT/skills/$skill" ] || continue
  while IFS= read -r f; do
    REL_FILES+=("skills/$skill/${f#"$sdir/"}")
  done < <(find "$sdir" -type f 2>/dev/null)
done < <(jq -r '.modules[].skills[]' "$MODULES_JSON" 2>/dev/null)

# 2. Global-scope hooks.
while IFS= read -r h; do
  [ -n "$h" ] || continue
  [ -f "$TEMPLATES/hooks/$h" ] || continue
  REL_FILES+=("hooks/$h")
done < <(jq -r '.hooks[] | select(.scope == "global") | .script' "$MODULES_JSON" 2>/dev/null)

# 3. Managed rules directory. The glob picks up template-only files (nana-personal, py-session-state);
#    the exclusion allow-list removes them — that is why the list earns its complexity.
if [ -d "$TEMPLATES/rules" ]; then
  while IFS= read -r f; do
    REL_FILES+=("rules/$(basename "$f")")
  done < <(find "$TEMPLATES/rules" -maxdepth 1 -type f -name '*.md' 2>/dev/null)
fi

# --- Diff each file; collect drift ---
DRIFT=()
if [ "${#REL_FILES[@]}" -gt 0 ]; then
  for rel in "${REL_FILES[@]}"; do
    is_excluded "$rel" && continue
    kit="$TEMPLATES/$rel"
    inst="$INSTALLED_ROOT/$rel"
    [ -f "$kit" ] || continue                       # kit file vanished mid-glob → fail-open skip
    if [ ! -f "$inst" ]; then
      DRIFT+=("missing: $rel")
    elif ! cmp -s "$kit" "$inst"; then
      DRIFT+=("differs: $rel")
    fi
  done
fi

COUNT=${#DRIFT[@]}

if [ "$MODE" = "count" ]; then
  echo "$COUNT"
  exit 0
fi

if [ "$COUNT" -gt 0 ]; then
  printf '%s\n' "${DRIFT[@]}"
  echo "drift: $COUNT kit file(s) differ from $INSTALLED_ROOT — run install.sh to sync."
  exit 1
fi
exit 0
