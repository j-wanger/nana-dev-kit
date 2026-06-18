#!/usr/bin/env bash
# Phase 93 T1 — consumer-state fixture harness + seeded controls (controls-first).
#
# install.sh --update reconciles a drifted consuming project to the current kit: ADD missing
# hooks, DEDUPE duplicate registrations (DRQ-1 — distinct command strings invoking one script
# both fire), and DEREG cut hooks (the Phase-88 detect-loop ghost that lingers across the
# 17/18/19-hook staged consumers). Before any of that reconcile/dereg logic is written or
# trusted (T2/T3), this harness proves the DETECTION INSTRUMENT can actually catch the defects
# it claims to fix — clean-on-seed = instrument-dead ([[qa-verification-sweep]], [[HEU-012]]).
#
# Three deterministic detectors over a consumer's settings.local.json + on-disk hooks:
#   detect_missing_hooks   -> kit project hooks absent from the consumer        (ADD)
#   detect_duplicate_registrations -> a basename registered >1x                 (DEDUPE, DRQ-1)
#   detect_cut_hooks       -> a registered/present basename the kit no longer ships (DEREG)
#
# Fixtures are built PROGRAMMATICALLY from the live modules.json (via the same
# register-settings.py --scope project-local that install.sh --project-local uses) so they stay
# faithful and never go stale; a manifest declares only the mutation + expected detections.
# A new drift class is one directory under eval/install-update/fixtures/ (one manifest.json).
#
# Hermetic: every consumer is built under mktemp -d; modules.json / register-settings.py are
# only READ; no live consumer repo, no ~/.claude, no kit file is ever written. BUILD + SANDBOX.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULES_JSON="$REPO_ROOT/modules.json"
REGISTER="$REPO_ROOT/scripts/register-settings.py"
FIXTURES_DIR="$REPO_ROOT/eval/install-update/fixtures"

echo "=== test_install_update.sh (Phase 93 T1: consumer fixtures + seeded controls) ==="

command -v jq >/dev/null 2>&1 || { echo "jq required" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }

SANDBOXES=()
cleanup() { for d in ${SANDBOXES[@]+"${SANDBOXES[@]}"}; do rm -rf "$d" 2>/dev/null || true; done; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# The instrument: three detectors (jq over settings.local.json + on-disk hooks).
# Each is a pure stdout producer that always returns 0 (safe under set -e + pipefail).
# ---------------------------------------------------------------------------

# kit_project_hooks -> the CURRENT kit project-scope hook basenames (the truth to reconcile to).
kit_project_hooks() {
  jq -r '.hooks[] | select(.scope == "project") | .script' "$MODULES_JSON" 2>/dev/null | sort -u
}

# registered_basenames <settings.local.json> -> one basename per registration command (dups kept).
registered_basenames() {
  local f="$1"
  [ -f "$f" ] || return 0
  jq -r '(.hooks // {}) | to_entries[] | .value[]? | (.hooks // [])[]? | (.command // .prompt // empty)' \
     "$f" 2>/dev/null | sed 's#.*/##' | sed '/^$/d'
}

# present_basenames <consumer-root> -> basenames known to the consumer: registered OR on-disk.
present_basenames() {
  local root="$1"
  {
    registered_basenames "$root/.claude/settings.local.json"
    if [ -d "$root/.claude/hooks" ]; then
      find "$root/.claude/hooks" -maxdepth 1 -type f -name '*.sh' -exec basename {} \;
    fi
  } | sort -u
}

# detect_cut_hooks <consumer-root> -> present basenames the current kit no longer ships (DEREG).
detect_cut_hooks() {
  local root="$1" kit; kit=$(kit_project_hooks)
  present_basenames "$root" | while IFS= read -r b; do
    [ -n "$b" ] || continue
    grep -qxF "$b" <<<"$kit" || echo "$b"
  done
}

# detect_duplicate_registrations <consumer-root> -> basenames registered more than once (DEDUPE).
detect_duplicate_registrations() {
  local root="$1"
  registered_basenames "$root/.claude/settings.local.json" | sort | uniq -d
}

# detect_missing_hooks <consumer-root> -> kit project hooks neither registered nor present (ADD).
detect_missing_hooks() {
  local root="$1" present; present=$(present_basenames "$root")
  kit_project_hooks | while IFS= read -r b; do
    [ -n "$b" ] || continue
    grep -qxF "$b" <<<"$present" || echo "$b"
  done
}

# ---------------------------------------------------------------------------
# Fixture builder: a synced baseline consumer + manifest-declared mutations.
# ---------------------------------------------------------------------------

# build_synced_consumer <root> -> a consumer at the CURRENT kit project-hook set, registered the
# way install.sh --project-local registers it (faithful baseline). enforce marker is set so the
# don't-arm invariant (T2) has something to preserve.
build_synced_consumer() {
  local root="$1" h
  rm -rf "$root/.claude"
  mkdir -p "$root/.claude/hooks"
  while IFS= read -r h; do
    [ -n "$h" ] || continue
    printf '#!/usr/bin/env bash\nexit 0\n' > "$root/.claude/hooks/$h"
    chmod +x "$root/.claude/hooks/$h"
  done < <(kit_project_hooks)
  python3 "$REGISTER" hooks "$root/.claude/settings.local.json" "$MODULES_JSON" --scope project-local >/dev/null 2>&1
  touch "$root/.claude/enforce"
}

# append_registration <settings> <event> <matcher> <command> — add ONE nested registration entry.
append_registration() {
  local f="$1" event="$2" matcher="$3" cmd="$4" tmp
  tmp=$(mktemp)
  if [ -n "$matcher" ]; then
    jq --arg ev "$event" --arg m "$matcher" --arg c "$cmd" \
       '.hooks[$ev] = ((.hooks[$ev] // []) + [{"matcher":$m,"hooks":[{"type":"command","command":$c}]}])' \
       "$f" > "$tmp" && mv "$tmp" "$f"
  else
    jq --arg ev "$event" --arg c "$cmd" \
       '.hooks[$ev] = ((.hooks[$ev] // []) + [{"hooks":[{"type":"command","command":$c}]}])' \
       "$f" > "$tmp" && mv "$tmp" "$f"
  fi
}

# apply_mutations <root> <manifest> — strip_all | add_ghost | duplicate.
apply_mutations() {
  local root="$1" manifest="$2" n i op script event matcher
  n=$(jq '.mutations | length' "$manifest")
  for ((i=0; i<n; i++)); do
    op=$(jq -r ".mutations[$i].op" "$manifest")
    script=$(jq -r ".mutations[$i].script // \"\"" "$manifest")
    event=$(jq -r ".mutations[$i].event // \"\"" "$manifest")
    matcher=$(jq -r ".mutations[$i].matcher // \"\"" "$manifest")
    case "$op" in
      strip_all)
        rm -rf "$root/.claude/hooks"
        mkdir -p "$root/.claude"
        echo '{}' > "$root/.claude/settings.local.json"
        ;;
      add_ghost)
        # A cut hook the kit no longer ships: file present + a registration pointing at it.
        mkdir -p "$root/.claude/hooks"
        printf '#!/usr/bin/env bash\nexit 0\n' > "$root/.claude/hooks/$script"
        chmod +x "$root/.claude/hooks/$script"
        append_registration "$root/.claude/settings.local.json" "$event" "$matcher" \
          "\${CLAUDE_PROJECT_DIR}/.claude/hooks/$script"
        ;;
      duplicate)
        # A SECOND registration of a kept script with a DIFFERENT command string (bare relative,
        # the pre-Phase-79 style). DRQ-1: both fire; basename-keyed detection sees the dup.
        append_registration "$root/.claude/settings.local.json" "$event" "$matcher" \
          ".claude/hooks/$script"
        ;;
      *) echo "unknown mutation op: $op" >&2 ;;
    esac
  done
}

# norm <newline-list> -> sorted, unique, blank-free; sets_equal compares two as sets.
norm() { printf '%s\n' "$1" | sed '/^$/d' | sort -u; }
sets_equal() { [ "$(norm "$1")" = "$(norm "$2")" ]; }
one_line() { norm "$1" | tr '\n' ' '; }

# ---------------------------------------------------------------------------
# Seeded controls (controls-first). Only a discriminating instrument passes all three:
# a dead detector (always empty) fails the seeded-defect controls; a crying-wolf detector
# (always flags) fails the clean control.
# ---------------------------------------------------------------------------
echo "--- Seeded controls (clean-on-seed = instrument-dead) ---"
CTRL=$(mktemp -d); SANDBOXES+=("$CTRL")

test_start "clean synced consumer flags nothing (no false positives)"
build_synced_consumer "$CTRL"
c=$(detect_cut_hooks "$CTRL"); d=$(detect_duplicate_registrations "$CTRL"); m=$(detect_missing_hooks "$CTRL")
if [ -z "$c" ] && [ -z "$d" ] && [ -z "$m" ]; then
  test_pass
else
  test_fail "instrument cries wolf on a synced consumer: cut=[$(one_line "$c")] dup=[$(one_line "$d")] missing=[$(one_line "$m")]"
fi

test_start "SEEDED cut-hook is flagged (else INSTRUMENT-DEAD — dereg untrustworthy)"
build_synced_consumer "$CTRL"
SEED_CUT="synth-cut-control.sh"   # a basename the kit does not ship; answer not inferable from a clean state
printf '#!/usr/bin/env bash\nexit 0\n' > "$CTRL/.claude/hooks/$SEED_CUT"
append_registration "$CTRL/.claude/settings.local.json" "Stop" "" "\${CLAUDE_PROJECT_DIR}/.claude/hooks/$SEED_CUT"
if detect_cut_hooks "$CTRL" | grep -qxF "$SEED_CUT"; then
  test_pass
else
  test_fail "INSTRUMENT-DEAD: seeded cut-hook $SEED_CUT not flagged. Got: [$(one_line "$(detect_cut_hooks "$CTRL")")]"
fi

test_start "SEEDED duplicate registration is flagged (else INSTRUMENT-DEAD — dedupe untrustworthy)"
build_synced_consumer "$CTRL"
SEED_DUP="enforce-loop.sh"   # a kept hook; second registration with a distinct command string
append_registration "$CTRL/.claude/settings.local.json" "Stop" "" ".claude/hooks/$SEED_DUP"
if detect_duplicate_registrations "$CTRL" | grep -qxF "$SEED_DUP"; then
  test_pass
else
  test_fail "INSTRUMENT-DEAD: seeded duplicate $SEED_DUP not flagged. Got: [$(one_line "$(detect_duplicate_registrations "$CTRL")")]"
fi

# ---------------------------------------------------------------------------
# Drift-class fixtures (one manifest.json per class — the "table").
# ---------------------------------------------------------------------------
echo "--- Drift-class fixtures ---"
[ -d "$FIXTURES_DIR" ] || { echo "FAIL: fixtures dir missing: $FIXTURES_DIR" >&2; test_fail "no fixtures dir"; }

FIXTURE_COUNT=0
while IFS= read -r manifest; do
  [ -n "$manifest" ] || continue
  FIXTURE_COUNT=$((FIXTURE_COUNT + 1))
  class=$(jq -r '.class' "$manifest")
  C=$(mktemp -d); SANDBOXES+=("$C")
  build_synced_consumer "$C"
  apply_mutations "$C" "$manifest"

  exp_cut=$(jq -r '.expect.cut_hooks[]?' "$manifest")
  exp_dup=$(jq -r '.expect.duplicate_registrations[]?' "$manifest")
  missing_mode=$(jq -r '.expect.missing_mode' "$manifest")
  case "$missing_mode" in
    all)  exp_missing=$(kit_project_hooks) ;;
    none) exp_missing="" ;;
    *)    exp_missing="" ;;
  esac

  got_cut=$(detect_cut_hooks "$C")
  got_dup=$(detect_duplicate_registrations "$C")
  got_missing=$(detect_missing_hooks "$C")

  test_start "[$class] cut-hooks (DEREG candidates)"
  if sets_equal "$exp_cut" "$got_cut"; then test_pass
  else test_fail "expected [$(one_line "$exp_cut")] got [$(one_line "$got_cut")]"; fi

  test_start "[$class] duplicate registrations (DEDUPE candidates)"
  if sets_equal "$exp_dup" "$got_dup"; then test_pass
  else test_fail "expected [$(one_line "$exp_dup")] got [$(one_line "$got_dup")]"; fi

  test_start "[$class] missing hooks ($missing_mode) (ADD candidates)"
  if sets_equal "$exp_missing" "$got_missing"; then test_pass
  else test_fail "expected [$(one_line "$exp_missing")] got [$(one_line "$got_missing")]"; fi
done < <(find "$FIXTURES_DIR" -name manifest.json 2>/dev/null | sort)

test_start "all 3 drift classes exercised"
if [ "$FIXTURE_COUNT" -ge 3 ]; then test_pass
else test_fail "only $FIXTURE_COUNT fixture manifests found under $FIXTURES_DIR (expected >= 3)"; fi

# ---------------------------------------------------------------------------
# T2 — install.sh --update reconciliation (the subject; T1 detectors are the instrument).
# ---------------------------------------------------------------------------
echo "--- T2: install.sh --update reconciliation ---"
INSTALL="$REPO_ROOT/install.sh"
STAGED="$FIXTURES_DIR/staged-detect-loop-ghost/manifest.json"
DUPM="$FIXTURES_DIR/phase79-duplicate-registration/manifest.json"
NOHOOKS="$FIXTURES_DIR/no-hooks/manifest.json"

run_update() { local dir="$1"; shift; ( cd "$dir" && bash "$INSTALL" --update "$@" ); }
# snapshot <root> -> checksum of the .claude tree (names + content); detects any write.
snapshot() { ( cd "$1" && find .claude -type f -print0 2>/dev/null | sort -z | xargs -0 cksum 2>/dev/null ); }

test_start "[--update] exits 0 on a staged consumer"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"; apply_mutations "$C" "$STAGED"
if run_update "$C" >/dev/null 2>&1; then test_pass; else test_fail "install.sh --update exited non-zero"; fi

test_start "[--update] un-armed consumer is NOT armed without --arm (don't auto-arm staged consumers)"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"; apply_mutations "$C" "$STAGED"
rm -f "$C/.claude/enforce"
run_update "$C" >/dev/null 2>&1 || true
if [ ! -e "$C/.claude/enforce" ]; then test_pass; else test_fail "--update armed an un-armed consumer (enforce created)"; fi

test_start "[--update --arm] creates the enforce marker (arming is opt-in)"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"; rm -f "$C/.claude/enforce"
run_update "$C" --arm >/dev/null 2>&1 || true
if [ -e "$C/.claude/enforce" ]; then test_pass; else test_fail "--arm did not create enforce marker"; fi

test_start "[--update] already-armed consumer stays armed (no disarm)"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"   # has enforce
run_update "$C" >/dev/null 2>&1 || true
if [ -e "$C/.claude/enforce" ]; then test_pass; else test_fail "--update disarmed an armed consumer"; fi

test_start "[--update] no-hooks consumer: all kit hooks added (ADD via --project-local path)"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"; apply_mutations "$C" "$NOHOOKS"
run_update "$C" >/dev/null 2>&1 || true
miss=$(detect_missing_hooks "$C")
if [ -z "$miss" ]; then test_pass; else test_fail "after --update, still missing: [$(one_line "$miss")]"; fi

test_start "[--update] duplicate registrations are deduped (DRQ-1: nonempty -> empty)"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"; apply_mutations "$C" "$DUPM"
pre=$(detect_duplicate_registrations "$C")
run_update "$C" >/dev/null 2>&1 || true
post=$(detect_duplicate_registrations "$C")
if [ -n "$pre" ] && [ -z "$post" ]; then test_pass
else test_fail "dedupe failed: pre=[$(one_line "$pre")] post=[$(one_line "$post")]"; fi

test_start "[--update] kept hooks survive dedupe (current-kit set still complete)"
# (same consumer C, after the dedupe run above) — dedupe must not drop a legitimate kept hook.
miss=$(detect_missing_hooks "$C")
if [ -z "$miss" ]; then test_pass; else test_fail "dedupe dropped kept hooks; missing: [$(one_line "$miss")]"; fi

test_start "[--update] second run is a no-op (idempotent)"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"; apply_mutations "$C" "$DUPM"
run_update "$C" >/dev/null 2>&1 || true          # run 1 (dedupes — a real change)
s1=$(snapshot "$C")
run_update "$C" >/dev/null 2>&1 || true          # run 2 (must change nothing)
s2=$(snapshot "$C")
if [ "$s1" = "$s2" ]; then test_pass; else test_fail "second --update mutated the consumer tree"; fi

test_start "[--update --dry-run] writes nothing"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"; apply_mutations "$C" "$STAGED"
before=$(snapshot "$C")
DRYOUT=$(run_update "$C" --dry-run 2>&1) || true
after=$(snapshot "$C")
if [ "$before" = "$after" ]; then test_pass; else test_fail "--dry-run mutated the consumer tree"; fi

test_start "[--update --dry-run] diff flags the detect-loop cut hook"
if echo "$DRYOUT" | grep -qi 'detect-loop'; then test_pass
else test_fail "dry-run diff did not flag detect-loop. Output: $DRYOUT"; fi

test_start "[--update --dry-run] diff reports the dedupe action on the dup fixture"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"; apply_mutations "$C" "$DUPM"
DRYOUT2=$(run_update "$C" --dry-run 2>&1) || true
if echo "$DRYOUT2" | grep -qi 'dedup' && echo "$DRYOUT2" | grep -qi 'enforce-spec'; then test_pass
else test_fail "dry-run diff did not report dedupe of enforce-spec. Output: $DRYOUT2"; fi

# ---------------------------------------------------------------------------
# T3 — automated basename-normalized deregistration behind safety rails.
# ---------------------------------------------------------------------------
echo "--- T3: automated cut-hook dereg (backup + restore + survivor smoke) ---"

# Positive control: a seeded cut-list hook (detect-loop) is removed AND deregistered.
test_start "[dereg] cut-list hook detect-loop removed (file gone + registration gone)"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"; apply_mutations "$C" "$STAGED"
run_update "$C" >/dev/null 2>&1 || true
file_gone=true; [ -f "$C/.claude/hooks/detect-loop.sh" ] && file_gone=false
reg_gone=true; registered_basenames "$C/.claude/settings.local.json" | grep -qxF detect-loop.sh && reg_gone=false
if $file_gone && $reg_gone; then test_pass
else test_fail "detect-loop not fully deregistered (file_gone=$file_gone reg_gone=$reg_gone)"; fi

# Negative control: a kept (non-cut) hook MUST survive the dereg (same consumer C).
test_start "[dereg] negative control: kept hook enforce-loop survives (file + registration)"
keep_file=false; [ -f "$C/.claude/hooks/enforce-loop.sh" ] && keep_file=true
keep_reg=false; registered_basenames "$C/.claude/settings.local.json" | grep -qxF enforce-loop.sh && keep_reg=true
if $keep_file && $keep_reg; then test_pass
else test_fail "dereg removed a kept hook (file=$keep_file reg=$keep_reg)"; fi

# Backup BEFORE removal + tested restore round-trip.
test_start "[dereg] timestamped backup created and restore round-trips to pre-dereg settings"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"; apply_mutations "$C" "$STAGED"
# normalize the post-add/dedupe pre-dereg settings: run a DRY-run to confirm nothing written, then
# capture the settings install.sh will back up — i.e. the state after ADD/UPDATE+dedupe, which for
# this fixture equals the current file (no dups, all present). Compare the backup against it.
PRE=$(mktemp); jq -S . "$C/.claude/settings.local.json" > "$PRE"
run_update "$C" >/dev/null 2>&1 || true
BK=$(ls -d "$C"/.claude/.dereg-backup.*/settings.local.json 2>/dev/null | head -1)
if [ -n "$BK" ] && [ -f "$BK" ] && [ "$(jq -S . "$BK")" = "$(cat "$PRE")" ]; then test_pass
else test_fail "no faithful timestamped backup (BK='$BK') — restore would not round-trip"; fi
rm -f "$PRE"

# Survivor functional smoke: a kept enforce hook fires exit-2 (block) and exit-0 (allow) post-dereg.
test_start "[dereg] survivor smoke: block-dangerous-bash fires exit-2 block / exit-0 allow"
PROBE="$C/.claude/hooks/block-dangerous-bash.sh"
sb=0; sa=0
if [ -x "$PROBE" ]; then
  echo '{"tool_input":{"command":"rm -rf /"}}' | bash "$PROBE" >/dev/null 2>&1 || sb=$?
  echo '{"tool_input":{"command":"ls -la"}}'   | bash "$PROBE" >/dev/null 2>&1 || sa=$?
else
  sb=-1
fi
if [ "$sb" -eq 2 ] && [ "$sa" -eq 0 ]; then test_pass
else test_fail "survivor smoke failed: block rc=$sb (want 2), allow rc=$sa (want 0)"; fi

# A no-cuts consumer is a no-op for dereg (no backup directory created).
test_start "[dereg] no-cuts consumer: dereg is a no-op (no backup directory)"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"   # synced, no cut hooks present
run_update "$C" >/dev/null 2>&1 || true
if ! ls -d "$C"/.claude/.dereg-backup.* >/dev/null 2>&1; then test_pass
else test_fail "a backup was created when there were no cut hooks to remove"; fi

# Idempotency across the destructive op: a second --update on the staged fixture changes nothing.
test_start "[dereg] staged fixture: second --update is a no-op (idempotent post-dereg)"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"; apply_mutations "$C" "$STAGED"
run_update "$C" >/dev/null 2>&1 || true; s1=$(snapshot "$C")
run_update "$C" >/dev/null 2>&1 || true; s2=$(snapshot "$C")
if [ "$s1" = "$s2" ]; then test_pass; else test_fail "second --update changed the consumer tree after dereg"; fi

# ---------------------------------------------------------------------------
# T4 — don't-clobber invariants + consumer-aware drift detection (detect-and-warn).
# ---------------------------------------------------------------------------
echo "--- T4: don't-clobber + check-install-drift --consumer ---"
DRIFT_SH="$REPO_ROOT/scripts/check-install-drift.sh"

test_start "[don't-clobber] custom settings key, custom hook, .dev-wiki, .gitignore preserved across --update"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"
# a non-kit top-level settings key
tmp=$(mktemp); jq '. + {"permissions":{"allow":["Bash(ls)"]}}' "$C/.claude/settings.local.json" > "$tmp" && mv "$tmp" "$C/.claude/settings.local.json"
# a non-kit custom hook (unique basename) + its registration — flagged as cut, but NOT removed
printf '#!/usr/bin/env bash\nexit 0\n' > "$C/.claude/hooks/my-custom-hook.sh"; chmod +x "$C/.claude/hooks/my-custom-hook.sh"
append_registration "$C/.claude/settings.local.json" "PreToolUse" "Read" "\${CLAUDE_PROJECT_DIR}/.claude/hooks/my-custom-hook.sh"
# project state outside .claude/
mkdir -p "$C/.dev-wiki"; printf 'state\n' > "$C/.dev-wiki/_CURRENT_STATE.md"
printf 'node_modules/\n' > "$C/.gitignore"
run_update "$C" >/dev/null 2>&1 || true
clobber=""
[ -f "$C/.claude/hooks/my-custom-hook.sh" ] || clobber="$clobber custom-hook-file"
registered_basenames "$C/.claude/settings.local.json" | grep -qxF my-custom-hook.sh || clobber="$clobber custom-hook-reg"
[ "$(jq -r '.permissions.allow[0]' "$C/.claude/settings.local.json" 2>/dev/null)" = "Bash(ls)" ] || clobber="$clobber settings-key"
[ -f "$C/.dev-wiki/_CURRENT_STATE.md" ] || clobber="$clobber dev-wiki"
[ "$(cat "$C/.gitignore" 2>/dev/null)" = "node_modules/" ] || clobber="$clobber gitignore"
if [ -z "$clobber" ]; then test_pass; else test_fail "--update clobbered:$clobber"; fi

# Controls-first for the consumer comparator: it must CATCH seeded drift before a clean verdict counts.
test_start "[check-drift --consumer] clean synced consumer reports NO drift (exit 0)"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"
rc=0; out=$(bash "$DRIFT_SH" --consumer "$C" 2>&1) || rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then test_pass; else test_fail "clean consumer flagged drift (rc=$rc out=[$out])"; fi

test_start "[check-drift --consumer] SEEDED cut hook detect-loop flagged (exit 1)"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"; apply_mutations "$C" "$STAGED"
rc=0; out=$(bash "$DRIFT_SH" --consumer "$C" 2>&1) || rc=$?
if [ "$rc" -eq 1 ] && echo "$out" | grep -q '^cut: detect-loop.sh'; then test_pass
else test_fail "consumer cut hook not flagged (rc=$rc out=[$out])"; fi

test_start "[check-drift --consumer] SEEDED duplicate registration flagged (exit 1)"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"; apply_mutations "$C" "$DUPM"
rc=0; out=$(bash "$DRIFT_SH" --consumer "$C" 2>&1) || rc=$?
if [ "$rc" -eq 1 ] && echo "$out" | grep -q '^duplicate: enforce-spec.sh'; then test_pass
else test_fail "consumer duplicate not flagged (rc=$rc out=[$out])"; fi

test_start "[check-drift --consumer] no-hooks consumer flags missing hooks (exit 1)"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"; apply_mutations "$C" "$NOHOOKS"
rc=0; out=$(bash "$DRIFT_SH" --consumer "$C" 2>&1) || rc=$?
if [ "$rc" -eq 1 ] && echo "$out" | grep -q '^missing: '; then test_pass
else test_fail "no-hooks consumer missing-set not flagged (rc=$rc out=[$out])"; fi

test_start "[--update] malformed settings.local.json: fail-STOP before any mutation (no half-sync, exit !=0)"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"; apply_mutations "$C" "$STAGED"
printf 'NOT JSON {{{\n' > "$C/.claude/settings.local.json"
before=$(snapshot "$C")
rc=0; out=$(run_update "$C" 2>&1) || rc=$?
after=$(snapshot "$C")
if [ "$rc" -ne 0 ] && [ "$before" = "$after" ] && echo "$out" | grep -qi 'not valid JSON'; then test_pass
else test_fail "malformed settings did not fail-stop cleanly (rc=$rc, tree changed=$([ "$before" = "$after" ] && echo no || echo YES), out=[$out])"; fi

test_start "[check-drift --consumer] clean again after --update reconciles the staged fixture (detect-and-warn closes)"
C=$(mktemp -d); SANDBOXES+=("$C"); build_synced_consumer "$C"; apply_mutations "$C" "$STAGED"
run_update "$C" >/dev/null 2>&1 || true
rc=0; out=$(bash "$DRIFT_SH" --consumer "$C" 2>&1) || rc=$?
if [ "$rc" -eq 0 ]; then test_pass; else test_fail "consumer still drifts after --update (rc=$rc out=[$out])"; fi

test_summary "install-update-harness"
