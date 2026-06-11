#!/usr/bin/env bash
# Phase 89 pre-registration checker (exit criterion c1).
# Live mode: asserts eval/dogfood-round/pre-registration.md (a) exists with every pinned
# section, (b) carries the header-deferral exclusion, (c) is COMMITTED, and (d) its first-add
# commit is an ancestor of every commit touching eval/dogfood-round/evidence/** (the
# pre-registration-before-observation invariant, Phase-87 ancestry method).
# --selftest: seeded controls — a missing-section copy and a wrong-order scratch repo must
# both FAIL; a right-order scratch repo must PASS. Clean-on-seed = instrument-dead, may not ship.
set -euo pipefail

REQUIRED_SECTIONS=(
  "## Baseline"
  "## Session universe"
  "## Session evidence schema"
  "## Classification rules"
  "## Window-events format"
  "## Pinned-decision inventory"
  "## Admissibility pins"
  "## Session bar"
  "## Measurement-blind prompt rule"
  "## Header deferral"
)

check_sections() { # $1 = file
  local f="$1" s missing=0
  [ -f "$f" ] || { echo "FAIL: $f missing" >&2; return 1; }
  for s in "${REQUIRED_SECTIONS[@]}"; do
    grep -qF "$s" "$f" || { echo "FAIL: section '$s' absent" >&2; missing=1; }
  done
  grep -qF "EXCLUDES evidence/header.md" "$f" \
    || { echo "FAIL: header-deferral exclusion line absent" >&2; missing=1; }
  return "$missing"
}

check_ancestry() { # $1 = repo root, $2 = prereg path rel, $3 = evidence dir rel
  local root="$1" prereg="$2" evdir="$3" p c bad=0
  p=$(git -C "$root" log --diff-filter=A --format=%H -- "$prereg" | tail -1)
  [ -n "$p" ] || { echo "FAIL: $prereg not committed (pre-registration must be committed before any evidence)" >&2; return 1; }
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    [ "$c" = "$p" ] && continue
    git -C "$root" merge-base --is-ancestor "$p" "$c" \
      || { echo "FAIL: evidence commit $c predates pre-registration first-add $p" >&2; bad=1; }
  done < <(git -C "$root" log --format=%H -- "$evdir" || true)
  return "$bad"
}

selftest() {
  local t pass=0 fail=0
  t=$(mktemp -d)
  # shellcheck disable=SC2064 — expand now: $t is function-local, gone by EXIT time
  trap "rm -rf '$t'" EXIT

  # Control 1: missing-section copy must FAIL the section check.
  mkdir -p "$t/c1"
  { for s in "${REQUIRED_SECTIONS[@]}"; do printf '%s\nstub\n' "$s"; done
    echo "EXCLUDES evidence/header.md"; } > "$t/c1/full.md"
  grep -vF "## Admissibility pins" "$t/c1/full.md" > "$t/c1/missing.md"
  if check_sections "$t/c1/missing.md" 2>/dev/null; then
    echo "SELFTEST FAIL: missing-section fixture passed (instrument-dead)" >&2; fail=1
  else pass=$((pass+1)); fi
  # ...and the full synthetic copy must PASS it (positive control).
  if check_sections "$t/c1/full.md" 2>/dev/null; then pass=$((pass+1)); else
    echo "SELFTEST FAIL: full fixture failed section check" >&2; fail=1; fi

  # Control 2: wrong-order scratch repo (evidence committed BEFORE pre-registration) must FAIL.
  mkdir -p "$t/c2/eval/dogfood-round/evidence"
  git -C "$t/c2" init -q && git -C "$t/c2" -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
  echo row > "$t/c2/eval/dogfood-round/evidence/sessions.md"
  git -C "$t/c2" add -A && git -C "$t/c2" -c user.email=t@t -c user.name=t commit -qm evidence
  cp "$t/c1/full.md" "$t/c2/eval/dogfood-round/pre-registration.md"
  git -C "$t/c2" add -A && git -C "$t/c2" -c user.email=t@t -c user.name=t commit -qm prereg
  if check_ancestry "$t/c2" eval/dogfood-round/pre-registration.md eval/dogfood-round/evidence 2>/dev/null; then
    echo "SELFTEST FAIL: wrong-order repo passed ancestry (instrument-dead)" >&2; fail=1
  else pass=$((pass+1)); fi

  # Control 3: right-order scratch repo must PASS.
  mkdir -p "$t/c3/eval/dogfood-round/evidence"
  git -C "$t/c3" init -q
  cp "$t/c1/full.md" "$t/c3/eval/dogfood-round/pre-registration.md"
  git -C "$t/c3" add -A && git -C "$t/c3" -c user.email=t@t -c user.name=t commit -qm prereg
  echo row > "$t/c3/eval/dogfood-round/evidence/sessions.md"
  git -C "$t/c3" add -A && git -C "$t/c3" -c user.email=t@t -c user.name=t commit -qm evidence
  if check_ancestry "$t/c3" eval/dogfood-round/pre-registration.md eval/dogfood-round/evidence 2>/dev/null; then
    pass=$((pass+1))
  else echo "SELFTEST FAIL: right-order repo failed ancestry" >&2; fail=1; fi

  [ "$fail" -eq 0 ] && echo "SELFTEST PASS ($pass/4 controls)" || { echo "SELFTEST FAIL" >&2; exit 1; }
}

if [ "${1:-}" = "--selftest" ]; then selftest; exit 0; fi

ROOT="$(git rev-parse --show-toplevel)"
rc=0
check_sections "$ROOT/eval/dogfood-round/pre-registration.md" || rc=1
check_ancestry "$ROOT" eval/dogfood-round/pre-registration.md eval/dogfood-round/evidence || rc=1
[ "$rc" -eq 0 ] && echo "PREREGISTRATION: PASS" || { echo "PREREGISTRATION: FAIL" >&2; exit 1; }
