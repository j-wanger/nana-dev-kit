#!/usr/bin/env bash
# harness-audit.sh — deterministic evidence→verdict classifier for the nana-dev-kit harness.
#
# Pins an INDEPENDENT inventory (the denominator) to its SOURCES, computes transitive
# reachability, then maps each component to exactly one verdict from observable evidence.
# CLASSIFIES ONLY — it never modifies any file.
#
# bash 3.2 compatible: no associative arrays, no mapfile/readarray, no ${var,,}.
# jq is a hard dependency (used for all JSON). Everything else is plain loops + temp files.
#
# Verdicts:
#   USED        reachable AND affirmative firing-evidence observed
#   LATENT      reachable, no firing-evidence, real path had >=N opportunities w/ zero effect
#   UNCERTAIN   reachable, no firing-evidence, long-cadence trigger (needs synthesized firing test)
#   DEADWEIGHT  NOT reachable
#
# Output contract:
#   - per-component classification lines tagged USED/LATENT/UNCERTAIN/DEADWEIGHT
#   - SUMMARY counts
#   - DRIFT: lines (if any)
#   - reconciliation line:  INVENTORY=<N> CLASSIFIED=<M> MATCH=ok|MISMATCH
# Exit non-zero on MISMATCH or any DRIFT (the MATCH= line is always printed first).

set -u
LC_ALL=C
export LC_ALL

# --- locate repo root (script lives in <root>/scripts) -----------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT" || { echo "cannot cd to repo root: $ROOT" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || { echo "Error: jq is required (hard dependency)." >&2; exit 1; }

MODULES_JSON="modules.json"
SETTINGS_JSON="templates/.claude/settings.json"
HOOKS_DIR="templates/.claude/hooks"
SKILLS_DIR="templates/.claude/skills"
RULES_DIR="templates/.claude/rules"
HEUR_DIR="wiki/heuristics"
TESTS_DIR="tests"
EVAL_DIR="eval"
ENFORCE_LOG=".dev-wiki/enforcement.log"
STALE_QUEUE=".dev-wiki/.stale-queue"
AUDIT_LOG=".nana/audit.jsonl"
SESS_TS="$HOME/.claude/.session-start-ts"

# --- temp scratch (sorted, deterministic) ------------------------------------
WORK="$(mktemp -d "${TMPDIR:-/tmp}/harness-audit.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
INV="$WORK/inventory"       # every inventoried path, one per line
CLS="$WORK/classified"      # "<path>\t<verdict>" one per line
DRIFT="$WORK/drift"         # DRIFT: lines
: >"$INV"; : >"$CLS"; : >"$DRIFT"

# helper: record one classification (path TAB verdict)
emit() { printf '%s\t%s\n' "$1" "$2" >>"$CLS"; }
# helper: add to inventory
inv()  { printf '%s\n' "$1" >>"$INV"; }

# =============================================================================
# STEP 1 — BUILD INDEPENDENT INVENTORY (denominator pinned to sources)
# =============================================================================

# (a) skills: from modules.json (dedup) — these are the source of truth
SKILLS_SRC="$WORK/skills.src"
jq -r '.modules[].skills[]' "$MODULES_JSON" | sort -u >"$SKILLS_SRC"
while IFS= read -r s; do
  [ -n "$s" ] || continue
  inv "skill:$s"
done <"$SKILLS_SRC"

# (b) hooks: top-level *.sh + *.md + session-start.d/*.sh
HOOKS_LIST="$WORK/hooks.list"
: >"$HOOKS_LIST"
for f in "$HOOKS_DIR"/*.sh; do [ -e "$f" ] && basename "$f" >>"$HOOKS_LIST"; done
for f in "$HOOKS_DIR"/*.md; do [ -e "$f" ] && basename "$f" >>"$HOOKS_LIST"; done
for f in "$HOOKS_DIR"/session-start.d/*.sh; do
  [ -e "$f" ] && echo "session-start.d/$(basename "$f")" >>"$HOOKS_LIST"
done
sort -u "$HOOKS_LIST" -o "$HOOKS_LIST"
while IFS= read -r h; do
  [ -n "$h" ] || continue
  inv "hook:$h"
done <"$HOOKS_LIST"

# (c) rules
for f in "$RULES_DIR"/*.md; do [ -e "$f" ] && inv "rule:$(basename "$f")"; done

# (d) heuristics: HEU-* and IRON-*
for f in "$HEUR_DIR"/HEU-*.md "$HEUR_DIR"/IRON-*.md; do
  [ -e "$f" ] && inv "heuristic:$(basename "$f")"
done

# (e) tests
for f in "$TESTS_DIR"/test_*.sh; do [ -e "$f" ] && inv "test:$(basename "$f")"; done

# (f) eval subsystems (directories)
for d in "$EVAL_DIR"/*/; do
  [ -d "$d" ] || continue
  b="$(basename "$d")"
  inv "eval:$b"
done

sort -u "$INV" -o "$INV"
N=$(grep -c . "$INV")

# =============================================================================
# STEP 2/3 helpers — reachability + firing evidence
# =============================================================================

# settings.json command strings (basenames of registered hook commands)
SETTINGS_HOOKS="$WORK/settings.hooks"
jq -r '.. | objects | (.command? // .prompt? // empty)' "$SETTINGS_JSON" 2>/dev/null \
  | sed 's#.*/##' | sort -u >"$SETTINGS_HOOKS"

# modules.json registered hook scripts
MODHOOKS="$WORK/modules.hooks"
jq -r '.hooks[].script' "$MODULES_JSON" 2>/dev/null | sort -u >"$MODHOOKS"

# skills named in modules.json (reachability set for skills)
# (== SKILLS_SRC; every skill in inventory is registered there by construction)

# Skill(skill="x") references made BY skills (for the "named in another skill" criterion)
SKILL_REFS="$WORK/skill.refs"
grep -rhoE 'Skill\(skill="[a-z0-9-]+"' "$SKILLS_DIR" 2>/dev/null \
  | sed -E 's/.*"([a-z0-9-]+)"/\1/' | sort -u >"$SKILL_REFS"

# enforcement.log action counts per hook (firing evidence for enforce-* family)
log_count() { # $1 = hook name
  [ -f "$ENFORCE_LOG" ] || { echo 0; return; }
  jq -r --arg h "$1" 'select(.hook==$h) | .hook' "$ENFORCE_LOG" 2>/dev/null | grep -c .
}

# is a hook registered (settings.json OR modules.json)? $1 = hook name (e.g. enforce-spec.sh)
hook_registered() {
  grep -qx "$1" "$SETTINGS_HOOKS" && return 0
  grep -qx "$1" "$MODHOOKS" && return 0
  return 1
}

# is a hook transitively sourced by a reachable hook? $1 = bare script name (e.g. wk-prune.sh)
# session-start.d/* are sourced by session-start.sh (itself registered).
hook_sourced() {
  local name="$1"
  # match `source .../<name>` in any hook file
  if grep -rlE "source[[:space:]].*/$name" "$HOOKS_DIR" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# long-cadence hooks: reachable but fire on rare lifecycle events
is_long_cadence() {
  case "$1" in
    pre-compact.sh|post-compact.sh|session-stop.sh|check-tests-were-run.sh) return 0 ;;
    *) return 1 ;;
  esac
}

# heuristic counter movement across history (spec: git log -S 'helpful: 1' empty => >=13 phases, 0 movement)
HEUR_MOVED=$(git log -S 'helpful: 1' -- "$HEUR_DIR"/*.md --oneline 2>/dev/null | grep -c . )
[ -n "$HEUR_MOVED" ] || HEUR_MOVED=0

# eval dirs reachable by the runner (CORPUS_DIR + validators only) OR a Makefile target
eval_reachable() { # $1 = eval subdir basename
  case "$1" in
    corpus|validators) return 0 ;;   # iterated by scripts/eval-runner.sh
  esac
  # any Makefile target that names eval/<name>
  grep -qE "eval/$1([/[:space:]\"']|\$)" Makefile 2>/dev/null && return 0
  return 1
}

# test-fixture coupling guard: does a make-test / make-eval path assert this basename's existence?
# $1 = basename (e.g. HEU-001-....md or reasoning). Returns 0 if coupled.
fixture_coupled() {
  local base="$1"
  grep -rl "$base" "$TESTS_DIR" Makefile >/dev/null 2>&1 && return 0
  return 1
}

# =============================================================================
# CLASSIFY: HOOKS
# =============================================================================
while IFS= read -r h; do
  name="${h#session-start.d/}"   # bare script name for sourced/cadence checks
  reachable=1
  via=""
  if hook_registered "$h"; then
    via="settings/modules"
  elif hook_registered "$name"; then
    via="settings/modules"
  elif hook_sourced "$name"; then
    via="sourced-by-reachable"
  else
    reachable=0
  fi

  if [ "$reachable" -eq 0 ]; then
    echo "DEADWEIGHT  hook:$h            (not registered, not sourced)"
    emit "hook:$h" DEADWEIGHT
    continue
  fi

  # --- firing evidence ---
  fired=0; ev=""
  case "$name" in
    enforce-loop.sh|enforce-spec.sh|enforce-memory.sh)
      c=$(log_count "${name%.sh}")
      [ "$c" -gt 0 ] && { fired=1; ev="enforcement.log:${name%.sh}=$c"; }
      ;;
    stale-queue.sh)
      [ -f "$STALE_QUEUE" ] && { fired=1; ev="output:$STALE_QUEUE"; }
      ;;
    audit-log.sh)
      [ -f "$AUDIT_LOG" ] && { fired=1; ev="output:$AUDIT_LOG"; }
      ;;
    session-start.sh)
      [ -f "$SESS_TS" ] && { fired=1; ev="output:.session-start-ts"; }
      ;;
  esac

  if [ "$fired" -eq 1 ]; then
    echo "USED        hook:$h            ($via; firing-evidence: $ev)"
    emit "hook:$h" USED
  elif is_long_cadence "$name"; then
    echo "UNCERTAIN   hook:$h            ($via; no firing-evidence — long-cadence; needs synthesized-trigger firing test)"
    emit "hook:$h" UNCERTAIN
  else
    # reachable, no firing evidence, not long-cadence: latent until a real trigger is exercised
    echo "LATENT      hook:$h            ($via; reachable but no observed firing-evidence)"
    emit "hook:$h" LATENT
  fi
done <"$HOOKS_LIST"

# =============================================================================
# CLASSIFY: SKILLS
# =============================================================================
# Every inventoried skill is registered in modules.json (reachable by construction).
# Note whether it is also invoked by another skill (Skill(skill=)) as supporting evidence.
while IFS= read -r s; do
  [ -n "$s" ] || continue
  ref=""
  if grep -qx "$s" "$SKILL_REFS"; then
    ref="; invoked-by-skill"
  fi
  # test-fixture coupling annotation (skill dir asserted by a make-test path)
  fix=""
  if fixture_coupled "$s"; then
    fix="; test-fixture coupling: DEFER"
  fi
  echo "USED        skill:$s            (registered in modules.json$ref$fix)"
  emit "skill:$s" USED
done <"$SKILLS_SRC"

# =============================================================================
# CLASSIFY: RULES (always-loaded — USED-or-LATENT, never DEADWEIGHT on loadedness)
# =============================================================================
for f in "$RULES_DIR"/*.md; do
  [ -e "$f" ] || continue
  b="$(basename "$f")"
  # always loaded into context => USED (loadedness is the firing evidence for a rule)
  echo "USED        rule:$b            (always-loaded into context)"
  emit "rule:$b" USED
done

# =============================================================================
# CLASSIFY: HEURISTICS
# =============================================================================
# Reachable (matcher-selectable + indexed). Firing-evidence = counter>0.
# All sit at helpful:0/harmful:0 and git -S shows ZERO counter movement across
# >=13 phases of real opportunities => LATENT (not deadweight, not used).
# CRITICAL GUARD: heuristics are make-eval / make-test fixtures => annotate DEFER, never cut.
for f in "$HEUR_DIR"/HEU-*.md "$HEUR_DIR"/IRON-*.md; do
  [ -e "$f" ] || continue
  b="$(basename "$f")"
  helpful=$(grep -E '^helpful:' "$f" | head -1 | sed -E 's/[^0-9]//g')
  harmful=$(grep -E '^harmful:' "$f" | head -1 | sed -E 's/[^0-9]//g')
  [ -n "$helpful" ] || helpful=0
  [ -n "$harmful" ] || harmful=0
  fix=""
  fixture_coupled "$b" && fix="; test-fixture coupling: DEFER"
  if [ "$helpful" -gt 0 ] || [ "$harmful" -gt 0 ]; then
    echo "USED        heuristic:$b            (counter helpful=$helpful harmful=$harmful$fix)"
    emit "heuristic:$b" USED
  else
    # zero counters AND zero movement across >=13 phases => LATENT
    echo "LATENT      heuristic:$b            (helpful=0 harmful=0; >=13 phases zero counter-movement (git -S '\''helpful: 1'\''=$HEUR_MOVED)$fix)"
    emit "heuristic:$b" LATENT
  fi
done

# =============================================================================
# CLASSIFY: TESTS
# =============================================================================
# Reachable iff invoked in the Makefile test: body. Firing evidence = being in the run set.
MAKE_TEST_BODY="$WORK/maketest.body"
awk '/^test:/{f=1} f{print} f&&/^$/{exit}' Makefile >"$MAKE_TEST_BODY"
for f in "$TESTS_DIR"/test_*.sh; do
  [ -e "$f" ] || continue
  b="$(basename "$f")"
  if grep -q "$b" "$MAKE_TEST_BODY"; then
    echo "USED        test:$b            (in Makefile test: body)"
    emit "test:$b" USED
  else
    echo "DEADWEIGHT  test:$b            (not wired into make test)"
    emit "test:$b" DEADWEIGHT
  fi
done

# =============================================================================
# CLASSIFY: EVAL SUBSYSTEMS
# =============================================================================
for d in "$EVAL_DIR"/*/; do
  [ -d "$d" ] || continue
  b="$(basename "$d")"
  fix=""
  fixture_coupled "$b" && fix="; test-fixture coupling: DEFER"
  if eval_reachable "$b"; then
    echo "USED        eval:$b            (iterated by eval-runner / Makefile target$fix)"
    emit "eval:$b" USED
  else
    # not iterated by the automated runner/Makefile => manual-only => not automatically reached
    if [ -n "$fix" ]; then
      # coupled to a test/Makefile assertion: reachable as fixture, but not auto-run => UNCERTAIN+DEFER
      echo "UNCERTAIN   eval:$b            (manual-only; asserted by a make-test path$fix)"
      emit "eval:$b" UNCERTAIN
    else
      echo "DEADWEIGHT  eval:$b            (manual-only; not iterated by eval-runner or any Makefile target)"
      emit "eval:$b" DEADWEIGHT
    fi
  fi
done

# =============================================================================
# STEP 4 — REACHABILITY-DRIFT CHECK
# =============================================================================
# 4a: every hook command in settings.json must have a backing file under HOOKS_DIR.
while IFS= read -r cmd; do
  [ -n "$cmd" ] || continue
  if [ ! -f "$HOOKS_DIR/$cmd" ] && [ ! -f "$HOOKS_DIR/session-start.d/$cmd" ]; then
    echo "DRIFT: settings.json registers '$cmd' but no backing file under $HOOKS_DIR" >>"$DRIFT"
  fi
done <"$SETTINGS_HOOKS"

# 4b: every modules.json project-scoped hook + each hook_dirs dir must be copied
#     by BOTH install.sh --project-local AND the py-init/ts-init SKILL.md cp instructions.
#     For hook dirs (e.g. session-start.d) assert the cp glob is recursive (cp -r) or names
#     the .d subdir explicitly.
PYINIT="$SKILLS_DIR/py-init/SKILL.md"
TSINIT="$SKILLS_DIR/ts-init/SKILL.md"

# project-scoped hook scripts
jq -r '.hooks[] | select(.scope=="project") | .script' "$MODULES_JSON" 2>/dev/null \
  >"$WORK/proj.hooks"
# install.sh copies project hooks via: cp "$HOOKS_SRC/$h" ... in a `for h in $PROJECT_HOOKS` loop
# (PROJECT_HOOKS itself is jq '.hooks[] | select(.scope=="project")' — so install covers all by construction).
# We still assert the loop exists, then assert py-init/ts-init copy the *.sh / *.md globs.
grep -q 'PROJECT_HOOKS=.*select(.scope == "project")' install.sh \
  || echo "DRIFT: install.sh --project-local does not select project-scoped hooks from modules.json" >>"$DRIFT"

for skillmd in "$PYINIT" "$TSINIT"; do
  who="$(basename "$(dirname "$skillmd")")"
  # must copy the hooks tree: recursive dot-copy (Phase 74: `cp -R .../hooks/. `) or legacy *.sh glob
  grep -qE 'cp (-R|-r) .*templates/\.claude/hooks/\.|cp .*templates/\.claude/hooks/"\*\.sh' "$skillmd" \
    || echo "DRIFT: $who SKILL.md missing recursive/glob cp of hooks/" >>"$DRIFT"
done

# hook_dirs: must be shipped by install.sh (ship_hook_dirs, Phase 85) AND by py-init/ts-init via
# recursive dot-copy (which carries every hook subdir) or an explicit cp -r of the dir.
while IFS= read -r ed; do
  [ -n "$ed" ] || continue
  # install.sh: consumer-conditioned dir shipping helper
  grep -q 'ship_hook_dirs' install.sh \
    || echo "DRIFT: install.sh missing ship_hook_dirs handling for '$ed'" >>"$DRIFT"
  # py-init / ts-init: recursive dot-copy OR explicit cp -r naming the dir
  for skillmd in "$PYINIT" "$TSINIT"; do
    who="$(basename "$(dirname "$skillmd")")"
    if grep -qE "cp (-R|-r) .*templates/\.claude/hooks/\.|cp -r .*hooks/$ed([\"[:space:]/]|\$)" "$skillmd"; then
      : # recursive dot-copy carries the subdir, or it is named explicitly — OK
    else
      echo "DRIFT: $who SKILL.md does not copy the hook dir '$ed' (session-start.d cp-gap)" >>"$DRIFT"
    fi
  done
done < <(jq -r '.hook_dirs[][]' "$MODULES_JSON" 2>/dev/null)

# =============================================================================
# STEP 5 — RECONCILE
# =============================================================================
# Build sorted classified-path set; assert: every inventoried path got exactly one
# verdict AND no verdict references a non-inventoried path (symmetric difference empty).
CLS_PATHS="$WORK/cls.paths"
cut -f1 "$CLS" | sort >"$CLS_PATHS.raw"
sort -u "$CLS_PATHS.raw" >"$CLS_PATHS"

# duplicate-verdict detection (a path classified more than once)
DUPS="$(uniq -d "$CLS_PATHS.raw")"

# symmetric difference between inventory and classified-paths
ONLY_INV="$(comm -23 "$INV" "$CLS_PATHS")"   # inventoried but unclassified
ONLY_CLS="$(comm -13 "$INV" "$CLS_PATHS")"   # classified but not inventoried

M=$(grep -c . "$CLS_PATHS")

# --- SUMMARY (counts per verdict) --------------------------------------------
c_used=$(cut -f2 "$CLS" | grep -c '^USED$')
c_latent=$(cut -f2 "$CLS" | grep -c '^LATENT$')
c_uncertain=$(cut -f2 "$CLS" | grep -c '^UNCERTAIN$')
c_dead=$(cut -f2 "$CLS" | grep -c '^DEADWEIGHT$')

echo ""
echo "=== SUMMARY ==="
echo "USED=$c_used  LATENT=$c_latent  UNCERTAIN=$c_uncertain  DEADWEIGHT=$c_dead"

# --- DRIFT report ------------------------------------------------------------
drift_found=0
if [ -s "$DRIFT" ]; then
  drift_found=1
  echo ""
  sort -u "$DRIFT"
else
  echo "DRIFT: none"
fi

# --- MATCH line (ALWAYS printed before exit) ---------------------------------
echo ""
match="ok"
if [ "$N" -ne "$M" ] || [ -n "$ONLY_INV" ] || [ -n "$ONLY_CLS" ] || [ -n "$DUPS" ]; then
  match="MISMATCH"
fi
echo "INVENTORY=$N CLASSIFIED=$M MATCH=$match"

if [ "$match" = "MISMATCH" ]; then
  [ -n "$DUPS" ]     && { echo "  duplicate verdicts:"; echo "$DUPS" | sed 's/^/    /'; }
  [ -n "$ONLY_INV" ] && { echo "  inventoried but unclassified:"; echo "$ONLY_INV" | sed 's/^/    /'; }
  [ -n "$ONLY_CLS" ] && { echo "  classified but not inventoried:"; echo "$ONLY_CLS" | sed 's/^/    /'; }
fi

# --- exit status -------------------------------------------------------------
if [ "$match" = "MISMATCH" ] || [ "$drift_found" -eq 1 ]; then
  exit 1
fi
exit 0
