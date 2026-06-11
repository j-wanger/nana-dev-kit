#!/usr/bin/env bash
# Phase 88 T3 seeded controls for the three routed stage-2 checker tightenings.
# Each tightened checker must FAIL on the seed the OLD version passed (the routed hole),
# PASS on clean, and handle the pinned boundary cases. Any wrong direction =
# instrument-dead for that strand (abort rule: ship nothing for it).
# NOTE: these controls run the checkers against FIXTURES in mktemp; the live Phase-87
# record is never re-graded (its grandfathered paths are asserted as grandfathered).
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$DIR" rev-parse --show-toplevel)"
S2="$ROOT/eval/ceremony-lift/stage2"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
declare -i pass=0 failn=0

expect() { # <desc> <expected-rc> <cmd...>
  local desc="$1" want="$2"; shift 2
  "$@" >/dev/null 2>&1; local got=$?
  [ "$got" -ge 1 ] && [ "$want" -ge 1 ] && got="$want"   # any non-zero counts as FAIL-direction
  if [ "$got" = "$want" ]; then echo "PASS: $desc"; pass+=1
  else echo "CONTROL-FAIL: $desc (want rc=$want got rc=$got)"; failn+=1; fi
}

mkrepo() { # <dir> — init a quiet fixture repo
  git -C "$1" init -q 2>/dev/null || git init -q "$1"
  git -C "$1" -c user.email=f@x -c user.name=f commit -q --allow-empty -m base
}
gcommit() { git -C "$1" add -A && git -C "$1" -c user.email=f@x -c user.name=f commit -qm "$2"; }

# ---------- c2 (through-HEAD) via run-exit-criteria.sh --c2-only ----------
C2="$S2/run-exit-criteria.sh"

r="$TMP/c2-clean"; mkdir -p "$r/d"; mkrepo "$r"
echo addendum > "$r/d/add.md"; gcommit "$r" P
echo results  > "$r/d/res.md"; gcommit "$r" R
expect "c2 clean (P→R, untouched through HEAD)" 0 \
  bash -c "cd '$r' && bash '$C2' --c2-only d/add.md d/res.md"

r="$TMP/c2-seed"; mkdir -p "$r/d"; mkrepo "$r"
echo addendum > "$r/d/add.md"; gcommit "$r" P
echo results  > "$r/d/res.md"; gcommit "$r" R
echo retrofit >> "$r/d/add.md"; gcommit "$r" "post-results touch"   # the OLD c2 PASSED this
expect "c2 SEED: post-results addendum touch caught" 1 \
  bash -c "cd '$r' && bash '$C2' --c2-only d/add.md d/res.md"

r="$TMP/c2-merge"; mkdir -p "$r/d"; mkrepo "$r"
echo addendum > "$r/d/add.md"; gcommit "$r" P
echo results  > "$r/d/res.md"; gcommit "$r" R
git -C "$r" checkout -qb side; echo side-touch >> "$r/d/add.md"; gcommit "$r" side
git -C "$r" checkout -q -; git -C "$r" -c user.email=f@x -c user.name=f merge -q --no-ff -m merge side
expect "c2 boundary: touch-via-merge caught" 1 \
  bash -c "cd '$r' && bash '$C2' --c2-only d/add.md d/res.md"

r="$TMP/c2-zero"; mkdir -p "$r/d"; mkrepo "$r"
echo results > "$r/d/res.md"; gcommit "$r" R
expect "c2 boundary: addendum never added (zero-touch) fails" 1 \
  bash -c "cd '$r' && bash '$C2' --c2-only d/add.md d/res.md"

r="$TMP/c2-order"; mkdir -p "$r/d"; mkrepo "$r"
echo results  > "$r/d/res.md"; gcommit "$r" R
echo addendum > "$r/d/add.md"; gcommit "$r" P
expect "c2 boundary: results precede addendum (ancestry) fails" 1 \
  bash -c "cd '$r' && bash '$C2' --c2-only d/add.md d/res.md"

# ---------- check-instrument.sh (cmp-not-grep) ----------
CI="$S2/check-instrument.sh"
mkfull() { # <file> <setup-sha> [artifacts-line]
  cat > "$1" << EOF
SETUP-SHA: $2
CHECKPOINT-ACK-SEED: y
CHECKPOINT-ACK-CLONES: y
CANARY-PRECHECK: PASS
RESTORATION-TEST: PASS
ISOLATION-PROBE: PASS
HOOK-FIRE-PROBE: PASS
DETECTOR-REHEARSAL: PASS
EXTRACTOR-SMOKE: PASS
CONTROL-HOOK: fixture
CONTROL-TASK-BYTE-IDENTITY: PASS
CANARY-VERDICT: CLEAN
CONTROL-VERDICT-ARM-A: SURFACED
CONTROL-VERDICT-ARM-B: NOT-SURFACED
RUN-STATUS: LIVE
${3:-}
EOF
}
ARMS="$S2/controls/arm-good"

mkfull "$TMP/i-seed.md" cafe001   # non-grandfathered, NO artifacts: old version PASSED this
expect "instrument SEED: grep-PASS without re-derivable artifacts caught" 1 \
  bash "$CI" --record "$TMP/i-seed.md" --arms "$ARMS"

mkdir -p "$TMP/pair-ok"; printf 'control task\n' > "$TMP/pair-ok/arm-a.md"; printf 'control task\n' > "$TMP/pair-ok/arm-b.md"
mkfull "$TMP/i-clean.md" cafe002 "CONTROL-TASK-ARTIFACTS: $TMP/pair-ok"
expect "instrument clean: identical pair re-derived via cmp" 0 \
  bash "$CI" --record "$TMP/i-clean.md" --arms "$ARMS"

mkdir -p "$TMP/pair-nl"; printf 'control task' > "$TMP/pair-nl/arm-a.md"; printf 'control task\n' > "$TMP/pair-nl/arm-b.md"
mkfull "$TMP/i-nl.md" cafe003 "CONTROL-TASK-ARTIFACTS: $TMP/pair-nl"
expect "instrument boundary: trailing-newline-only diff caught (cmp is byte-exact)" 1 \
  bash "$CI" --record "$TMP/i-nl.md" --arms "$ARMS"

mkdir -p "$TMP/pair-empty"; : > "$TMP/pair-empty/arm-a.md"; : > "$TMP/pair-empty/arm-b.md"
mkfull "$TMP/i-empty.md" cafe004 "CONTROL-TASK-ARTIFACTS: $TMP/pair-empty"
expect "instrument boundary: empty-empty pair is vacuous, fails" 1 \
  bash "$CI" --record "$TMP/i-empty.md" --arms "$ARMS"

mkfull "$TMP/i-grand.md" 4ed8071
expect "instrument grandfather: pinned Phase-87 record keeps legacy semantics" 0 \
  bash "$CI" --record "$TMP/i-grand.md" --arms "$ARMS"

# ---------- check-ship-table.sh (unconditional cmdlog + empty-table) ----------
CS="$S2/check-ship-table.sh"

cat > "$TMP/s-seed.md" << 'EOF'
| arm | collected | subset | coverage | gate | branch_detector | cmdlog |
|---|---|---|---|---|---|---|
| arm-b | 391 | PASS | 94.51 | PASS | IMPROVED | arm-records/cmdlog-b.txt |
| arm-a | DNF | DNF | DNF | FAIL | DNF | DNF |
EOF
expect "ship-table SEED: DNF row without cmdlog pointer caught" 1 bash "$CS" "$TMP/s-seed.md"

cat > "$TMP/s-clean.md" << 'EOF'
| arm | collected | subset | coverage | gate | branch_detector | cmdlog |
|---|---|---|---|---|---|---|
| arm-b | 391 | PASS | 94.51 | PASS | IMPROVED | arm-records/cmdlog-b.txt |
| arm-a | DNF | DNF | DNF | FAIL | DNF | arm-records/cmdlog-a.txt |
EOF
expect "ship-table clean: DNF row WITH cmdlog passes" 0 bash "$CS" "$TMP/s-clean.md"

: > "$TMP/s-empty.md"
expect "ship-table boundary: empty table fails (no vacuous-pass)" 1 bash "$CS" "$TMP/s-empty.md"
expect "ship-table boundary: absent table fails" 1 bash "$CS" "$TMP/does-not-exist.md"

echo "----"
echo "SEEDED-CONTROLS: $pass pass / $failn fail"
[ "$failn" -eq 0 ] && exit 0 || exit 1
