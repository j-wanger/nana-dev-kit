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
# skill dir + global-scope hook scripts + ANY kit-shipped hook script already present in the
# installed root (Phase 82: pre-Phase-79 global installs left project-scoped hooks live in
# ~/.claude — a present copy is running code, so its drift is compared regardless of scope tag;
# the checker never ADDS files, refresh stays install.sh's job) + for each hook script in the set,
# the companion dirs it consumes per modules.json .hook_dirs (Phase 85: consumer present ⇒ dir
# must exist and match; installed-only files there are flagged `orphan:`) + the managed rules dir.
# Assumes a full (--all) install (the maintainer's case): a skill dir absent from the installed
# root is treated as a not-installed module and skipped, not as drift.
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
    --consumer) MODE="consumer" ;;
    *) ROOT_ARG="$a" ;;
  esac
done

if [ "$MODE" = "excludes" ]; then
  printf '%s\n' "${EXCLUDE[@]}"
  exit 0
fi

# --- Consumer-aware drift (Phase 93): detect-and-warn complement to install.sh --update ---
# This is a DIFFERENT comparison from the kit-vs-installed drift below: a consuming project's
# project-local hook set (files + settings.local.json registrations) reconciled, BY BASENAME,
# against the kit's CURRENT scope:project hook set. Surfaces the three classes --update fixes —
#   missing:   a current kit project hook absent from the consumer            (ADD)
#   duplicate: one script basename registered more than once (DRQ-1)          (DEDUPE)
#   cut:       a registered/present basename the kit no longer ships          (DEREG — flagged)
# Liberal flagging (every cut hook, on the cut-list or not); --update removes only the cut-list.
# Read-only and FAIL-OPEN (the comparator never mutates a consumer). Exit 1 on drift, 0 clean.
if [ "$MODE" = "consumer" ]; then
  CROOT="$ROOT_ARG"
  if [ -z "$CROOT" ] || ! command -v jq >/dev/null 2>&1 || [ ! -f "$MODULES_JSON" ]; then
    exit 0
  fi
  C_SETTINGS="$CROOT/.claude/settings.local.json"
  C_HOOKS="$CROOT/.claude/hooks"
  KIT_SET=$(jq -r '.hooks[] | select(.scope == "project") | .script' "$MODULES_JSON" 2>/dev/null | sort -u)
  # Global-scope kit hooks (install to ~/.claude, not per-project). A stray copy in a project hooks
  # dir is NOT a "cut" — the kit still ships it — so it must not be flagged as drift (Phase 96).
  KIT_GLOBAL=$(jq -r '.hooks[] | select(.scope == "global") | .script' "$MODULES_JSON" 2>/dev/null | sort -u)

  c_registered() {  # one basename per registration command (dups kept)
    [ -f "$C_SETTINGS" ] || return 0
    jq -r '(.hooks // {}) | to_entries[] | .value[]? | (.hooks // [])[]? | (.command // .prompt // empty)' \
       "$C_SETTINGS" 2>/dev/null | sed 's#.*/##' | sed '/^$/d'
  }
  c_present() {  # registered OR on-disk basenames
    { c_registered
      if [ -d "$C_HOOKS" ]; then find "$C_HOOKS" -maxdepth 1 -type f -name '*.sh' -exec basename {} \; ; fi
    } | sort -u
  }

  C_DRIFT=()
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    c_present | grep -qxF "$b" || C_DRIFT+=("missing: $b")
  done <<< "$KIT_SET"
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    C_DRIFT+=("duplicate: $b")
  done < <(c_registered | sort | uniq -d)
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    grep -qxF "$b" <<<"$KIT_SET" && continue
    grep -qxF "$b" <<<"$KIT_GLOBAL" && continue   # legit global kit hook strayed into the project dir — not drift
    C_DRIFT+=("cut: $b")
  done < <(c_present)
  # Phase 96: kit-managed regs in the PROJECT-scope .claude/settings.json (the committed file --update
  # never looks at). Flag them as the settings.json-topology drift class that --migrate-to-local fixes;
  # left in place they orphan a detect-loop reg on file-removal (ghost) and cross-file double-fire (DRQ-1).
  C_SETTINGS_JSON="$CROOT/.claude/settings.json"
  C_CUT_SET=$(jq -r '.cut_hooks[]?' "$MODULES_JSON" 2>/dev/null | sed '/^$/d; s/\.sh$//; s/$/.sh/')
  C_MANAGED=$(printf '%s\n%s\n' "$KIT_SET" "$C_CUT_SET" | sort -u | sed '/^$/d')
  if [ -f "$C_SETTINGS_JSON" ]; then
    while IFS= read -r b; do
      [ -n "$b" ] || continue
      if grep -qxF "$b" <<<"$C_MANAGED"; then C_DRIFT+=("settings-json-topology: $b"); fi
    done < <(jq -r '(.hooks // {}) | to_entries[] | .value[]? | (.hooks // [])[]? | (.command // .prompt // empty)' \
               "$C_SETTINGS_JSON" 2>/dev/null | sed 's#.*/##' | sed '/^$/d' | sort -u)
  fi

  if [ "${#C_DRIFT[@]}" -gt 0 ]; then
    printf '%s\n' "${C_DRIFT[@]}"
    echo "consumer drift: ${#C_DRIFT[@]} item(s) in $CROOT — run install.sh --update (or --migrate-to-local for settings-json-topology) to reconcile."
    exit 1
  fi
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

# 2b. Installed hook scripts (Phase 82): any hook PRESENT in the installed root that the kit also
# ships is LIVE CODE there regardless of its current scope tag — pre-Phase-79 global installs left
# project-scoped hooks registered in ~/.claude/settings.json, and those copies kept RUNNING while
# the scope:global filter above made their drift invisible (4 stale registered hooks found live).
# Compare every such file; never ADD files to the installed root — refresh is install.sh's job.
# ${arr[@]+...} idiom: bash 3.2 + set -u errors on "${arr[@]}" for an EMPTY array (fires when a
# sandbox kit has no skills/global hooks — the real modules.json never tripped it).
in_rel_files() { local r="$1" x; for x in ${REL_FILES[@]+"${REL_FILES[@]}"}; do [ "$x" = "$r" ] && return 0; done; return 1; }
if [ -d "$INSTALLED_ROOT/hooks" ]; then
  while IFS= read -r f; do
    h=$(basename "$f")
    [ -f "$TEMPLATES/hooks/$h" ] || continue   # user-owned / non-kit hook → not ours to compare
    in_rel_files "hooks/$h" || REL_FILES+=("hooks/$h")
  done < <(find "$INSTALLED_ROOT/hooks" -maxdepth 1 -type f -name '*.sh' 2>/dev/null)
fi

# 2c. Hook companion dirs (Phase 85): consumer present ⇒ its declared dirs must exist and match.
# For every hook script ALREADY in the comparison set that declares dirs in modules.json
# .hook_dirs, each templates file in those dirs joins the set — so a consumer whose companion
# dir is missing or stale drifts LOUDLY. Incident 5 (2026-06-09): session-start.sh was
# md5-current while session-start.d/ was EMPTY (this checker was the resync shopping list and
# was blind to the dir) → every SessionStart on the machine errored. Installed-only files in a
# covered dir are flagged as `orphan:` rows — detect-and-warn: flagged, never removed.
# Content-only compare (cmp -s) is a pinned exemption for these dirs: the files are SOURCED,
# not exec'd, so the exec bit is not load-bearing (eval/install-gap/inventory.md).
HOOKDIR_ORPHANS=()
HOOK_CONSUMERS=()
for r in ${REL_FILES[@]+"${REL_FILES[@]}"}; do
  case "$r" in hooks/*.sh) [[ "$r" == hooks/*/* ]] || HOOK_CONSUMERS+=("$(basename "$r")") ;; esac
done
if [ "${#HOOK_CONSUMERS[@]}" -gt 0 ]; then
  for c in "${HOOK_CONSUMERS[@]}"; do
    while IFS= read -r d; do
      [ -n "$d" ] || continue
      if [ -d "$TEMPLATES/hooks/$d" ]; then
        while IFS= read -r f; do
          rel="hooks/$d/$(basename "$f")"
          in_rel_files "$rel" || REL_FILES+=("$rel")
        done < <(find "$TEMPLATES/hooks/$d" -maxdepth 1 -type f 2>/dev/null)
      fi
      if [ -d "$INSTALLED_ROOT/hooks/$d" ]; then
        while IFS= read -r f; do
          b=$(basename "$f")
          [ -f "$TEMPLATES/hooks/$d/$b" ] || HOOKDIR_ORPHANS+=("orphan: hooks/$d/$b")
        done < <(find "$INSTALLED_ROOT/hooks/$d" -maxdepth 1 -type f 2>/dev/null)
      fi
    done < <(jq -r --arg s "$c" '.hook_dirs[$s][]?' "$MODULES_JSON" 2>/dev/null)
  done
fi

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

# Orphans in covered hook dirs count as drift rows (flagged, never removed).
if [ "${#HOOKDIR_ORPHANS[@]}" -gt 0 ]; then
  DRIFT+=("${HOOKDIR_ORPHANS[@]}")
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
