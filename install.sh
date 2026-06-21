#!/usr/bin/env bash
# Install Nana Dev Kit — copies global pieces to ~/.claude/
# Run once per machine. Then use /nana-init in any project to scaffold the harness.
#
# Flags:
#   --all            Install everything (default)
#   --core-only      Identity rules + spec + memory server only
#   --no-python      Skip py-init skill
#   --no-typescript  Skip ts-init skill
#   --project-local  Install ALL project-scoped hooks from modules.json (17)
#                    into $PWD/.claude/hooks/. No global writes.
#   --update         Idempotently re-sync an already-installed consuming project ($PWD/.claude)
#                    to the current kit: ADD/UPDATE project hooks, dedupe registrations by script
#                    basename (DRQ-1), and FLAG cut hooks for the gated dereg. Arming is DECOUPLED
#                    — .claude/enforce is left untouched unless --arm is also passed. A consumer
#                    with no kit hooks (e.g. signal-watch) is fully installed via this same path.
#   --migrate-to-local  Consolidate a consumer that registered its kit hooks in the PROJECT-scope
#                    .claude/settings.json (the committed file --update never reads) onto the kit's single
#                    canonical .claude/settings.local.json topology: relocate the kit set to local +
#                    deregister kit-managed + cut hooks from settings.json + remove cut files. Each hook
#                    then lives in ONE file (DRQ-1 cross-file double-fire structurally impossible). Behind
#                    a timestamped backup of BOTH settings files → survivor smoke → revert. Run before --update.
#   --arm            With --update / --migrate-to-local: also create/keep the .claude/enforce marker (opt-in arming).
#   --dry-run        Print actions without copying (with --update: print the reconciliation diff)

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
UPDATE=false
MIGRATE=false
ARM=false
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
    --update)
      UPDATE=true ;;
    --migrate-to-local)
      MIGRATE=true ;;
    --arm)
      ARM=true ;;
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
      echo "Usage: install.sh [--all|--core-only|--no-python|--no-typescript] [--project-local] [--update [--arm]] [--migrate-to-local [--arm]] [--dry-run] [--status]" >&2
      exit 1 ;;
  esac
  shift
done

command -v jq >/dev/null 2>&1 || { echo "Error: jq is required. Install with: brew install jq (macOS) or apt install jq (Linux)." >&2; exit 1; }

# --- Helper: ship hook companion dirs (modules.json .hook_dirs) alongside their consumer ---
# A dir ships ONLY when its consumer script is among the scripts this path ships (never ship a
# dir whose consumer this path does not install). find-based copy: an empty/no-match source dir
# must NOT abort the installer under set -euo pipefail — a mid-sequence abort leaves a partial
# install, the incident-5 class (session-start.sh present, session-start.d/ missing).
ship_hook_dirs() {  # $1 = destination hooks dir; $2.. = shipped script basenames
  local dest="$1" s d
  shift
  for s in "$@"; do
    for d in $(jq -r --arg s "$s" '.hook_dirs[$s][]?' "$MODULES_JSON" 2>/dev/null); do
      [ -d "$HOOKS_SRC/$d" ] || continue
      mkdir -p "$dest/$d"
      find "$HOOKS_SRC/$d" -maxdepth 1 -name '*.sh' -exec cp {} "$dest/$d/" \;
      find "$dest/$d" -maxdepth 1 -name '*.sh' -exec chmod +x {} \;
    done
  done
}

# --- Helper: basenames registered in a settings file (one line per registration; dups kept) ---
# Used by --update to compute the reconciliation diff (dedupe + cut-flag detection). Genuinely
# fail-open under set -euo pipefail: a missing OR malformed-JSON file yields empty + exit 0 (the
# `jq -e .` validity gate returns BEFORE the producing pipeline, so a parse error cannot propagate
# its non-zero exit through a `$(...)` substitution and abort the script — the prior `2>/dev/null`
# only hid jq's message, not its exit code). --update also fail-STOPS on malformed settings upfront.
registered_basenames() {  # $1 = settings file
  [ -f "$1" ] || return 0
  jq -e . "$1" >/dev/null 2>&1 || return 0
  jq -r '(.hooks // {}) | to_entries[] | .value[]? | (.hooks // [])[]? | (.command // .prompt // empty)' \
     "$1" 2>/dev/null | sed 's#.*/##' | sed '/^$/d'
}

# --- Helper: post-dereg survivor smoke — a kept, state-independent enforce hook still fires ---
# block-dangerous-bash.sh is payload-driven (not marker-gated): exit 2 on a dangerous command,
# exit 0 on a safe one. A dereg that corrupts settings.local.json or drops a survivor registration
# fails this; install.sh then reverts from the timestamped backup (HEU-012: assert allow AND block).
survivor_smoke_ok() {  # $1 = hooks dir, $2 = settings file
  jq -e . "$2" >/dev/null 2>&1 || return 1
  local probe="$1/block-dangerous-bash.sh" rc_block=0 rc_allow=0
  [ -x "$probe" ] || return 0   # survivor absent in this consumer — JSON-validity check stands alone
  set +e
  echo '{"tool_input":{"command":"rm -rf /"}}' | bash "$probe" >/dev/null 2>&1; rc_block=$?
  echo '{"tool_input":{"command":"ls -la"}}'   | bash "$probe" >/dev/null 2>&1; rc_allow=$?
  set -e
  [ "$rc_block" -eq 2 ] && [ "$rc_allow" -eq 0 ]
}

# --- Update / re-sync mode (short-circuit, operates on $PWD/.claude; arming decoupled) ---
if $UPDATE; then
  HOOKS_SRC="$SCRIPT_DIR/templates/.claude/hooks"
  PROJ_HOOKS_DIR=".claude/hooks"
  PROJ_SETTINGS=".claude/settings.local.json"
  PROJECT_HOOKS=$(jq -r '.hooks[] | select(.scope == "project") | .script' "$MODULES_JSON")
  for h in $PROJECT_HOOKS; do
    [ -f "$HOOKS_SRC/$h" ] || { echo "Error: source missing: $HOOKS_SRC/$h" >&2; exit 1; }
  done
  # Malformed consumer settings is a prerequisite violation — fail STOP here, BEFORE any cp/mutation,
  # so a hand-corrupted settings.local.json can never leave a half-synced consumer (files refreshed,
  # registrations un-reconciled). register-settings.py's json.load would also crash on it downstream.
  if [ -f "$PROJ_SETTINGS" ] && ! jq -e . "$PROJ_SETTINGS" >/dev/null 2>&1; then
    echo "Error: $PWD/$PROJ_SETTINGS is not valid JSON — fix or remove it before --update (no files changed)." >&2
    exit 1
  fi
  KIT_SET=$(echo "$PROJECT_HOOKS" | tr ' ' '\n' | sort -u | sed '/^$/d')

  # ADD: kit project hooks whose file is absent in the consumer (present ones are refreshed).
  ADDS=""
  for h in $PROJECT_HOOKS; do
    [ -f "$PROJ_HOOKS_DIR/$h" ] || ADDS="$ADDS $h"
  done
  # DEDUPE: script basenames registered more than once (DRQ-1).
  DUPS=$(registered_basenames "$PROJ_SETTINGS" | sort | uniq -d | tr '\n' ' ')
  # CUT (FLAG ONLY this phase — destructive dereg is the gated follow-on): registered-or-present
  # basenames the current kit no longer ships. Liberal flagging; conservative removal lives behind
  # the cut-list + rails so a consumer's legitimate custom hook is never silently nuked.
  PRESENT=$( { registered_basenames "$PROJ_SETTINGS"
               if [ -d "$PROJ_HOOKS_DIR" ]; then
                 find "$PROJ_HOOKS_DIR" -maxdepth 1 -type f -name '*.sh' -exec basename {} \;
               fi; } | sort -u )
  CUTS=""
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    grep -qxF "$b" <<<"$KIT_SET" || CUTS="$CUTS $b"
  done <<< "$PRESENT"

  # Cut-list (modules.json .cut_hooks): the CONSERVATIVE auto-remove set. A flagged cut hook NOT
  # on this list is reported but never removed — a consumer's legitimate custom hook must survive.
  CUT_LIST=$(jq -r '.cut_hooks[]?' "$MODULES_JSON")
  TO_DEREG=""
  for c in $CUT_LIST; do
    cs="$c"; case "$cs" in *.sh) ;; *) cs="$cs.sh" ;; esac
    if [ -f "$PROJ_HOOKS_DIR/$cs" ] || registered_basenames "$PROJ_SETTINGS" | grep -qxF "$cs"; then
      TO_DEREG="$TO_DEREG $cs"
    fi
  done
  FLAG_ONLY=""
  for b in $CUTS; do
    echo " $TO_DEREG " | grep -qF " $b " || FLAG_ONLY="$FLAG_ONLY $b"
  done

  if $DRY_RUN; then
    echo "[dry-run] --- Mode: update (re-sync $PWD/.claude to current kit) ---"
    echo "[dry-run] add hooks:${ADDS:- (none — all present, will be refreshed)}"
    echo "[dry-run] refresh present hooks: $(echo "$PROJECT_HOOKS" | wc -w | tr -d ' ') project hook(s) overwritten from templates"
    [ -n "${DUPS// /}" ] && echo "[dry-run] dedupe registrations (by basename): $DUPS" || echo "[dry-run] dedupe registrations: (none)"
    [ -n "${TO_DEREG// /}" ] && echo "[dry-run] deregister cut hooks (remove file + registration; settings backed up first):$TO_DEREG" || echo "[dry-run] deregister cut hooks: (none)"
    [ -n "${FLAG_ONLY// /}" ] && echo "[dry-run] FLAG cut hooks (NOT on cut-list — reported, not removed):$FLAG_ONLY"
    $ARM && echo "[dry-run] arm: touch .claude/enforce" || echo "[dry-run] arming DECOUPLED — .claude/enforce untouched (pass --arm to arm)"
    echo "[dry-run] (no files written)"
    exit 0
  fi

  mkdir -p "$PROJ_HOOKS_DIR"
  for h in $PROJECT_HOOKS; do
    cp "$HOOKS_SRC/$h" "$PROJ_HOOKS_DIR/$h"
    chmod +x "$PROJ_HOOKS_DIR/$h"
  done
  # shellcheck disable=SC2086 — word-split intended: newline/space-separated script basenames
  ship_hook_dirs "$PROJ_HOOKS_DIR" $PROJECT_HOOKS
  # ADD/UPDATE registrations + dedupe-by-basename in one upsert pass (register-settings owns the
  # settings JSON; --dedupe collapses the DRQ-1 duplicate command strings upsert cannot remove).
  python3 "$REGISTER_SCRIPT" hooks "$PROJ_SETTINGS" "$MODULES_JSON" --scope project-local --dedupe

  # --- Destructive deregistration of cut-list hooks (rails: backup -> remove -> smoke -> revert) ---
  DEREGGED=""
  BK_DIR=""
  if [ -n "${TO_DEREG// /}" ]; then
    TS=$(date +%Y%m%d%H%M%S)
    BK_DIR=".claude/.dereg-backup.$TS"
    mkdir -p "$BK_DIR/hooks"
    # RAIL: timestamped backup BEFORE any removal — settings + the files being removed, so the whole
    # op is reversible (a registered-but-missing half-state is exactly the class we are avoiding).
    cp "$PROJ_SETTINGS" "$BK_DIR/settings.local.json"
    dereg_args=()
    for cs in $TO_DEREG; do
      [ -f "$PROJ_HOOKS_DIR/$cs" ] && cp "$PROJ_HOOKS_DIR/$cs" "$BK_DIR/hooks/$cs"
      rm -f "$PROJ_HOOKS_DIR/$cs"
      dereg_args+=(--basename "$cs")
    done
    python3 "$REGISTER_SCRIPT" deregister "$PROJ_SETTINGS" "${dereg_args[@]}"
    # RAIL: survivor functional smoke + JSON validity; revert from backup on ANY failure.
    if survivor_smoke_ok "$PROJ_HOOKS_DIR" "$PROJ_SETTINGS"; then
      DEREGGED="$TO_DEREG"
    else
      cp "$BK_DIR/settings.local.json" "$PROJ_SETTINGS"
      for cs in $TO_DEREG; do [ -f "$BK_DIR/hooks/$cs" ] && cp "$BK_DIR/hooks/$cs" "$PROJ_HOOKS_DIR/$cs"; done
      echo "Error: dereg survivor smoke failed — reverted settings + cut files from $BK_DIR" >&2
      exit 1
    fi
  fi

  # Arming is DECOUPLED from the hook refresh — the staged consumers must NOT auto-arm (Phase 91).
  $ARM && touch .claude/enforce
  echo ""
  echo "Re-synced $PWD/.claude to current kit:"
  echo "  hooks refreshed: $(echo "$PROJECT_HOOKS" | wc -w | tr -d ' ') project hook(s)"
  [ -n "${ADDS// /}" ] && echo "  added:$ADDS"
  [ -n "${DUPS// /}" ] && echo "  duplicate registrations deduped: $DUPS"
  [ -n "${DEREGGED// /}" ] && echo "  deregistered cut hooks:$DEREGGED (settings backed up in $BK_DIR)"
  [ -n "${FLAG_ONLY// /}" ] && echo "  cut hooks flagged (not on cut-list — left in place):$FLAG_ONLY"
  $ARM && echo "  armed: .claude/enforce" || echo "  arming decoupled: .claude/enforce unchanged"
  exit 0
fi

# --- Migrate-to-local mode (Phase 96): consolidate a consumer that registered its kit hooks in the
# project-scope .claude/settings.json (the committed file --update never looks at) onto the kit's single
# canonical topology, gitignored .claude/settings.local.json — register the current kit set into
# settings.local.json, deregister the kit-managed + cut (detect-loop) basenames from settings.json, and
# remove the cut hook FILES. The existing --update is UNCHANGED. Because each kit hook then lives in
# exactly ONE file, the DRQ-1 cross-file double-fire is structurally impossible (basename-normalized).
# Rails: --dry-run; timestamped backup of BOTH settings files BEFORE any write; survivor smoke; revert.
if $MIGRATE; then
  HOOKS_SRC="$SCRIPT_DIR/templates/.claude/hooks"
  PROJ_HOOKS_DIR=".claude/hooks"
  S_LOCAL=".claude/settings.local.json"
  S_JSON=".claude/settings.json"
  PROJECT_HOOKS=$(jq -r '.hooks[] | select(.scope == "project") | .script' "$MODULES_JSON")
  for h in $PROJECT_HOOKS; do
    [ -f "$HOOKS_SRC/$h" ] || { echo "Error: source missing: $HOOKS_SRC/$h" >&2; exit 1; }
  done
  # Malformed settings (either file) is a prerequisite violation — fail STOP before any mutation.
  for sf in "$S_JSON" "$S_LOCAL"; do
    if [ -f "$sf" ] && ! jq -e . "$sf" >/dev/null 2>&1; then
      echo "Error: $PWD/$sf is not valid JSON — fix or remove it before --migrate-to-local (no files changed)." >&2
      exit 1
    fi
  done
  KIT_SET=$(echo "$PROJECT_HOOKS" | tr ' ' '\n' | sort -u | sed '/^$/d')
  CUT_SET=$(jq -r '.cut_hooks[]?' "$MODULES_JSON" | sed '/^$/d; s/\.sh$//; s/$/.sh/')
  # kit-managed = current kit set + cut-list (the basenames this op may relocate / deregister).
  MANAGED=$(printf '%s\n%s\n' "$KIT_SET" "$CUT_SET" | sort -u | sed '/^$/d')

  # kit-managed basenames currently registered in settings.json (the topology to consolidate away).
  IN_JSON=""
  if [ -f "$S_JSON" ]; then
    while IFS= read -r b; do
      [ -n "$b" ] || continue
      if grep -qxF "$b" <<<"$MANAGED"; then IN_JSON="$IN_JSON $b"; fi
    done < <(registered_basenames "$S_JSON" | sort -u)
  fi
  # cut-hook FILES present on disk (removed during consolidation, like --update's dereg).
  CUT_FILES=""
  for cs in $CUT_SET; do [ -f "$PROJ_HOOKS_DIR/$cs" ] && CUT_FILES="$CUT_FILES $cs"; done
  # cut-hook registrations lingering in settings.local.json (deregister from there too).
  CUT_IN_LOCAL=""
  if [ -f "$S_LOCAL" ]; then
    for cs in $CUT_SET; do
      if registered_basenames "$S_LOCAL" | grep -qxF "$cs"; then CUT_IN_LOCAL="$CUT_IN_LOCAL $cs"; fi
    done
  fi

  # Idempotent no-op: nothing kit-managed in settings.json, no cut FILE, no cut reg in settings.local.
  if [ -z "${IN_JSON// /}" ] && [ -z "${CUT_FILES// /}" ] && [ -z "${CUT_IN_LOCAL// /}" ]; then
    if $DRY_RUN; then
      echo "[dry-run] --- Mode: migrate-to-local ($PWD/.claude) ---"
      echo "[dry-run] already consolidated — no kit registrations in settings.json, no cut residue (no-op)"
      exit 0
    fi
    echo ""
    echo "Already consolidated: $PWD/.claude has no kit registrations in settings.json and no cut residue (no change)."
    $ARM && { mkdir -p .claude; touch .claude/enforce; echo "  armed: .claude/enforce"; }
    exit 0
  fi

  if $DRY_RUN; then
    echo "[dry-run] --- Mode: migrate-to-local (consolidate settings.json kit regs -> settings.local.json) ---"
    echo "[dry-run] relocate to settings.local.json (register current kit set): $(echo "$KIT_SET" | wc -w | tr -d ' ') hook(s)"
    echo "[dry-run] deregister kit-managed from settings.json:${IN_JSON:- (none)}"
    [ -n "${CUT_IN_LOCAL// /}" ] && echo "[dry-run] deregister cut hooks from settings.local.json:$CUT_IN_LOCAL"
    [ -n "${CUT_FILES// /}" ] && echo "[dry-run] remove cut hook files:$CUT_FILES"
    echo "[dry-run] refresh $(echo "$PROJECT_HOOKS" | wc -w | tr -d ' ') kit hook file(s) from templates"
    echo "[dry-run] back up settings.json (and settings.local.json if present) first (timestamped); survivor smoke gates the result"
    $ARM && echo "[dry-run] arm: touch .claude/enforce" || echo "[dry-run] arming DECOUPLED — .claude/enforce untouched (pass --arm to arm)"
    echo "[dry-run] (no files written)"
    exit 0
  fi

  # RAIL: timestamped backup of BOTH settings files BEFORE any write (the cut now touches a COMMITTED file).
  TS=$(date +%Y%m%d%H%M%S)
  BK_DIR=".claude/.migrate-backup.$TS"
  mkdir -p "$BK_DIR/hooks"
  HAD_LOCAL=false
  [ -f "$S_JSON" ]  && cp "$S_JSON"  "$BK_DIR/settings.json"
  if [ -f "$S_LOCAL" ]; then cp "$S_LOCAL" "$BK_DIR/settings.local.json"; HAD_LOCAL=true; fi
  for cs in $CUT_FILES; do cp "$PROJ_HOOKS_DIR/$cs" "$BK_DIR/hooks/$cs"; done

  # 0. ship the current kit hook FILES (mirrors --update) BEFORE registering them — so the relocated
  # registrations point at present, current files and the survivor-smoke probe is never absent (else
  # migrate-alone leaves the registered-but-missing half-state the kit has been bitten by 5x; HEU-012).
  mkdir -p "$PROJ_HOOKS_DIR"
  for h in $PROJECT_HOOKS; do
    cp "$HOOKS_SRC/$h" "$PROJ_HOOKS_DIR/$h"
    chmod +x "$PROJ_HOOKS_DIR/$h"
  done
  # shellcheck disable=SC2086 — word-split intended: newline/space-separated script basenames
  ship_hook_dirs "$PROJ_HOOKS_DIR" $PROJECT_HOOKS

  # 1. land the current kit set in settings.local.json (the canonical topology).
  python3 "$REGISTER_SCRIPT" hooks "$S_LOCAL" "$MODULES_JSON" --scope project-local --dedupe
  # 2. deregister the kit-managed (kit + cut) basenames from settings.json.
  if [ -f "$S_JSON" ] && [ -n "${IN_JSON// /}" ]; then
    dj=(); for b in $IN_JSON; do dj+=(--basename "$b"); done
    python3 "$REGISTER_SCRIPT" deregister "$S_JSON" "${dj[@]}"
  fi
  # 3. deregister any lingering cut hooks from settings.local.json.
  if [ -n "${CUT_IN_LOCAL// /}" ]; then
    dl=(); for b in $CUT_IN_LOCAL; do dl+=(--basename "$b"); done
    python3 "$REGISTER_SCRIPT" deregister "$S_LOCAL" "${dl[@]}"
  fi
  # 4. remove the cut hook FILES.
  for cs in $CUT_FILES; do rm -f "$PROJ_HOOKS_DIR/$cs"; done

  # RAIL: survivor functional smoke + JSON validity; revert BOTH files + cut files on ANY failure.
  if survivor_smoke_ok "$PROJ_HOOKS_DIR" "$S_LOCAL"; then
    :
  else
    [ -f "$BK_DIR/settings.json" ] && cp "$BK_DIR/settings.json" "$S_JSON"
    if $HAD_LOCAL; then cp "$BK_DIR/settings.local.json" "$S_LOCAL"; else rm -f "$S_LOCAL"; fi
    for cs in $CUT_FILES; do [ -f "$BK_DIR/hooks/$cs" ] && cp "$BK_DIR/hooks/$cs" "$PROJ_HOOKS_DIR/$cs"; done
    echo "Error: migrate survivor smoke failed — reverted settings + cut files from $BK_DIR" >&2
    exit 1
  fi

  # Arming is DECOUPLED — touched only with --arm (Phase 91 / Phase 96 A5).
  $ARM && touch .claude/enforce
  echo ""
  echo "Consolidated $PWD/.claude to the settings.local.json topology:"
  echo "  kit hooks registered in settings.local.json: $(echo "$KIT_SET" | wc -w | tr -d ' ')"
  echo "  kit hook files refreshed from templates: $(echo "$PROJECT_HOOKS" | wc -w | tr -d ' ')"
  [ -n "${IN_JSON// /}" ] && echo "  deregistered from settings.json:$IN_JSON"
  [ -n "${CUT_IN_LOCAL// /}" ] && echo "  deregistered cut hooks from settings.local.json:$CUT_IN_LOCAL"
  [ -n "${CUT_FILES// /}" ] && echo "  removed cut hook files:$CUT_FILES"
  echo "  settings backed up in $BK_DIR"
  $ARM && echo "  armed: .claude/enforce" || echo "  arming decoupled: .claude/enforce unchanged"
  exit 0
fi

# --- Project-local install (short-circuit, no global writes) ---
if $PROJECT_LOCAL; then
  HOOKS_SRC="$SCRIPT_DIR/templates/.claude/hooks"
  PROJ_HOOKS_DIR=".claude/hooks"
  PROJ_SETTINGS=".claude/settings.local.json"
  PROJECT_HOOKS=$(jq -r '.hooks[] | select(.scope == "project") | .script' "$MODULES_JSON")
  EXTRA_DIRS=$(jq -r '.hook_dirs[][]' "$MODULES_JSON" 2>/dev/null || true)
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
    # shellcheck disable=SC2086 — word-split intended: newline-separated script basenames
    ship_hook_dirs "$PROJ_HOOKS_DIR" $PROJECT_HOOKS
    # NB: no --hooks-dir override — register-settings defaults project-local commands to
    # ${CLAUDE_PROJECT_DIR}/.claude/hooks so they resolve regardless of CWD (Phase 79). The hook
    # FILES were copied to $PROJ_HOOKS_DIR (.claude/hooks) above; only the registered command path differs.
    python3 "$REGISTER_SCRIPT" hooks "$PROJ_SETTINGS" "$MODULES_JSON" \
      --scope project-local
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
  echo ""
  echo "Install drift (templates/ vs installed ~/.claude):"
  DRIFT_SCRIPT="$SCRIPT_DIR/scripts/check-install-drift.sh"
  if [ -x "$DRIFT_SCRIPT" ]; then
    DRIFT_N=$("$DRIFT_SCRIPT" --count 2>/dev/null || echo 0)
    if [ "${DRIFT_N:-0}" -gt 0 ] 2>/dev/null; then
      echo "  drift:   $DRIFT_N kit file(s) differ — run install.sh to sync"
    else
      echo "  drift:   none (installed copy matches templates/)"
    fi
  else
    echo "  drift:   unknown (comparator missing)"
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

    # MCP cwd comes from modules.json (the declared single source of truth) — it was
    # previously hardcoded here, making the manifest's mcp block dead config (Phase 82).
    MCP_CWD=$(jq -r 'first(.modules[] | select(.mcp != null) | .mcp.cwd)' "$SCRIPT_DIR/modules.json" 2>/dev/null)
    python3 "$REGISTER_SCRIPT" mcp ~/.claude/settings.json \
      --python "$VENV_DIR/bin/python3" --cwd "${MCP_CWD:-~/.claude}" \
      --modules-json "$SCRIPT_DIR/modules.json"

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
    HOOK_DIRS_DRY=$(for h in $HOOK_SCRIPTS; do jq -r --arg s "$h" '.hook_dirs[$s][]?' "$MODULES_JSON" 2>/dev/null; done | sort -u | tr '\n' ' ')
    [ -n "${HOOK_DIRS_DRY// /}" ] && echo "[dry-run] install hook dirs: $HOOK_DIRS_DRY"
    echo "[dry-run] register hooks in settings.json (nested schema)"
    echo "[dry-run] create markers: $MARKERS"
  else
    mkdir -p ~/.claude/hooks
    for h in $HOOK_SCRIPTS; do
      [ -f "$HOOKS_SRC/$h" ] || { echo "Error: source missing: $HOOKS_SRC/$h" >&2; exit 1; }
      cp "$HOOKS_SRC/$h" ~/.claude/hooks/"$h"
      chmod +x ~/.claude/hooks/"$h"
    done
    # shellcheck disable=SC2086 — word-split intended: newline-separated script basenames
    ship_hook_dirs ~/.claude/hooks $HOOK_SCRIPTS

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
  [ "$INSTALL_KNOWLEDGE" = true ] && echo "  ~/.claude/skills/wiki-*/            — knowledge-wiki pipeline (10 skills)"
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
