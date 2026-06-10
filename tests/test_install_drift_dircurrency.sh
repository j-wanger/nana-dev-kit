#!/usr/bin/env bash
# Phase 85 — seeded controls for hook-dir currency in check-install-drift.sh.
#
# Incident 5 (2026-06-09): session-start.sh was md5-current at ~/.claude/hooks while its
# session-start.d/ was EMPTY — the checker's maxdepth-1 hook pass was structurally blind to
# directory contents, so the drift-guided resync shipped the script without its dir and every
# SessionStart errored machine-wide. These controls make that exact state a loud red cell.
#
# Controls-first standard ([[qa-verification-sweep]]): the checker's clean verdict counts only
# because each seeded defect below is CAUGHT — clean-on-seed would mean instrument-dead.
# Hermetic: the checker is copied into a sandbox kit (mktemp -d); the real ~/.claude is never read.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== test_install_drift_dircurrency.sh ==="

# --- Sandbox kit: checker + synthetic templates + synthetic modules.json ---
# Two declared mappings: session-start.sh (the real shape) and synth.sh (a SECOND entry proving
# the coverage is driven by the declared .hook_dirs map, not a hardcoded session-start.d name).
KIT=$(mktemp -d)
mkdir -p "$KIT/scripts" "$KIT/templates/.claude/hooks/session-start.d" \
         "$KIT/templates/.claude/hooks/synth.d" "$KIT/templates/.claude/rules"
cp "$PROJECT_ROOT/scripts/check-install-drift.sh" "$KIT/scripts/"
printf '#!/bin/bash\nsource session-start.d/wk-prune.sh\n' > "$KIT/templates/.claude/hooks/session-start.sh"
printf 'echo wk\n'  > "$KIT/templates/.claude/hooks/session-start.d/wk-prune.sh"
printf 'echo mn\n'  > "$KIT/templates/.claude/hooks/session-start.d/memory-nudge.sh"
printf '#!/bin/bash\n' > "$KIT/templates/.claude/hooks/synth.sh"
printf 'echo s1\n'  > "$KIT/templates/.claude/hooks/synth.d/s1.sh"
printf 'rule\n'     > "$KIT/templates/.claude/rules/nana-soul.md"
cat > "$KIT/modules.json" << 'EOF'
{
  "modules": [],
  "hooks": [
    { "event": "SessionStart", "matcher": "", "script": "session-start.sh", "scope": "project" },
    { "event": "SessionStart", "matcher": "", "script": "synth.sh", "scope": "project" }
  ],
  "hook_dirs": {
    "session-start.sh": ["session-start.d"],
    "synth.sh": ["synth.d"]
  }
}
EOF
CHECKER="$KIT/scripts/check-install-drift.sh"

make_synced_root() {  # $1 = root; fully synced w.r.t. the sandbox kit
  local r="$1"
  rm -rf "$r"
  mkdir -p "$r/hooks/session-start.d" "$r/hooks/synth.d" "$r/rules"
  cp "$KIT/templates/.claude/hooks/session-start.sh"            "$r/hooks/"
  cp "$KIT/templates/.claude/hooks/session-start.d/"*.sh        "$r/hooks/session-start.d/"
  cp "$KIT/templates/.claude/hooks/synth.sh"                    "$r/hooks/"
  cp "$KIT/templates/.claude/hooks/synth.d/"*.sh                "$r/hooks/synth.d/"
  cp "$KIT/templates/.claude/rules/"*.md                        "$r/rules/"
}

ROOT=$(mktemp -d)/root

# --- Control 0: fully synced root reports 0 ---
test_start "synced root reports drift 0"
make_synced_root "$ROOT"
N=$("$CHECKER" --count "$ROOT")
assert_eq "0" "$N" "synced root drifted: $("$CHECKER" "$ROOT" 2>&1 || true)"

# --- Seeded control 1: DELETED companion dir (the incident-5 state) ---
test_start "seeded DELETED session-start.d/ reports drift (incident-5 state is a red cell)"
make_synced_root "$ROOT"
rm -rf "$ROOT/hooks/session-start.d"
OUT=$("$CHECKER" "$ROOT" 2>&1 || true)
if echo "$OUT" | grep -q '^missing: hooks/session-start.d/wk-prune.sh' \
   && echo "$OUT" | grep -q '^missing: hooks/session-start.d/memory-nudge.sh'; then
  test_pass
else
  test_fail "deleted dir not reported as missing rows — instrument-dead. Output: $OUT"
fi

# --- Seeded control 2: one STALE curator file ---
test_start "seeded STALE curator file reports differs:"
make_synced_root "$ROOT"
echo "drifted-line" >> "$ROOT/hooks/session-start.d/wk-prune.sh"
OUT=$("$CHECKER" "$ROOT" 2>&1 || true)
if echo "$OUT" | grep -q '^differs: hooks/session-start.d/wk-prune.sh'; then
  test_pass
else
  test_fail "stale curator not reported. Output: $OUT"
fi

# --- Seeded control 3: ORPHAN installed-only file (flag, never remove) ---
test_start "seeded ORPHAN file in covered dir reports orphan: and is NOT removed"
make_synced_root "$ROOT"
printf 'echo ghost\n' > "$ROOT/hooks/session-start.d/ghost.sh"
OUT=$("$CHECKER" "$ROOT" 2>&1 || true)
if echo "$OUT" | grep -q '^orphan: hooks/session-start.d/ghost.sh' \
   && [ -f "$ROOT/hooks/session-start.d/ghost.sh" ]; then
  test_pass
else
  test_fail "orphan not flagged (or was removed — charter violation). Output: $OUT"
fi

# --- Seeded control 4: the SECOND declared mapping is covered (map-driven, not hardcoded) ---
test_start "seeded stale file under synth.d (second hook_dirs entry) reports differs:"
make_synced_root "$ROOT"
echo "drifted-line" >> "$ROOT/hooks/synth.d/s1.sh"
OUT=$("$CHECKER" "$ROOT" 2>&1 || true)
if echo "$OUT" | grep -q '^differs: hooks/synth.d/s1.sh'; then
  test_pass
else
  test_fail "second declared mapping not covered — coverage is hardcoded, not map-driven. Output: $OUT"
fi

# --- Control 5: consumer-conditioning — dir cells fire only where the consumer exists ---
test_start "root WITHOUT the consumer script gets NO dir cells (consumer-conditioned)"
make_synced_root "$ROOT"
rm -f "$ROOT/hooks/session-start.sh"
rm -rf "$ROOT/hooks/session-start.d"
# session-start.sh is scope:project and now absent from the root → not in the comparison set →
# its dir absence is NOT drift here (this root simply doesn't run that hook).
OUT=$("$CHECKER" "$ROOT" 2>&1 || true)
if echo "$OUT" | grep -q 'session-start.d'; then
  test_fail "dir cells fired without their consumer present. Output: $OUT"
else
  test_pass
fi

# --- Control 6: --count mode counts dir rows (the install.sh --status consumer) ---
test_start "--count includes dir-currency rows"
make_synced_root "$ROOT"
rm -rf "$ROOT/hooks/session-start.d"
N=$("$CHECKER" --count "$ROOT")
if [ "$N" -ge 2 ] 2>/dev/null; then
  test_pass
else
  test_fail "--count returned '$N' for a deleted 2-file dir (expected >= 2)"
fi

rm -rf "$KIT" "$(dirname "$ROOT")"

test_summary "install-drift dir-currency"
