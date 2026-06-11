#!/usr/bin/env bash
# Phase 89 no-disposition guard (exit criterion c8) — over the pinned phase range
# (<first-add commit of eval/dogfood-round/pre-registration.md>..HEAD, per pre-registration.md
# "## Baseline" last bullet):
# (a) the diff touches ONLY the allowlist (eval/dogfood-round/**, .dev-wiki/**, specs/**,
#     .claude/rules/active-phase.md, .claude/rules/working-knowledge.md);
# (b) templates/**, modules.json, MANIFEST byte-untouched;
# (c) no "Revert ..." commit in the range references any trim-trial/cut/harden SHA — the
#     disposition vocabulary belongs to Phase 93, never this round.
# REPO parameterized so --selftest runs against scratch repos (each carries its own
# pre-registration.md commit to anchor the range).
# --selftest: seeded controls — templates-touch, revert-reference, out-of-allowlist, and
# missing-prereg must FAIL; the clean repo must PASS. Clean-on-seed = instrument-dead.
set -euo pipefail

PREREG="eval/dogfood-round/pre-registration.md"
REVERT_SHAS=(d43950f df3e623 75b48af b8bd416)

resolve_prereg() { # $1 = repo → first-add commit, empty if never committed
  git -C "$1" log --diff-filter=A --format=%H -- "$PREREG" | tail -1
}

check_allowlist() { # $1 = repo, $2 = range
  local f bad=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in
      eval/dogfood-round/*|.dev-wiki/*|specs/*) ;;
      .claude/rules/active-phase.md|.claude/rules/working-knowledge.md) ;;
      *) echo "FAIL: out-of-allowlist file touched in range: $f" >&2; bad=1 ;;
    esac
  done < <(git -C "$1" diff --name-only "$2")
  return "$bad"
}

check_untouched() { # $1 = repo, $2 = range
  local out
  out=$(git -C "$1" diff --name-only "$2" -- templates modules.json MANIFEST)
  [ -z "$out" ] || { echo "FAIL: frozen surface touched in range: $out" >&2; return 1; }
}

check_no_revert() { # $1 = repo, $2 = range
  local c subj body s bad=0
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    subj=$(git -C "$1" log -1 --format=%s "$c")
    case "$subj" in
      Revert*)
        body=$(git -C "$1" log -1 --format=%B "$c")
        for s in "${REVERT_SHAS[@]}"; do
          if grep -qF "$s" <<<"$body"; then
            echo "FAIL: revert of $s inside the round ($c) — disposition is Phase 93's" >&2; bad=1
          fi
        done ;;
    esac
  done < <(git -C "$1" log --format=%H "$2")
  return "$bad"
}

ci() { # $1 = repo, rest = commit args (-m ... [--allow-empty])
  local d="$1"; shift
  git -C "$d" add -A
  git -C "$d" -c user.email=t@t -c user.name=t commit -q "$@"
}

newrepo() { # $1 = dir → scratch repo with a committed pre-registration anchor
  mkdir -p "$1/eval/dogfood-round"
  git -C "$1" init -q
  echo "prereg anchor" > "$1/$PREREG"
  ci "$1" -m "prereg"
}

expect() { # $1 = pass|fail, $2 = label, rest = command
  local want="$1" label="$2"; shift 2
  if "$@" 2>/dev/null; then
    [ "$want" = pass ] && { pass=$((pass+1)); return; }
    echo "SELFTEST FAIL: $label passed (instrument-dead)" >&2; fail=1
  else
    [ "$want" = fail ] && { pass=$((pass+1)); return; }
    echo "SELFTEST FAIL: $label failed" >&2; fail=1
  fi
}

selftest() {
  local t p pass=0 fail=0
  t=$(mktemp -d)
  # shellcheck disable=SC2064 — expand now: $t is function-local, gone by EXIT time
  trap "rm -rf '$t'" EXIT

  # Control 1: clean repo (prereg + allowlisted .dev-wiki commit) passes all three checks.
  newrepo "$t/clean"; mkdir -p "$t/clean/.dev-wiki"
  echo notes > "$t/clean/.dev-wiki/notes.md"; ci "$t/clean" -m "phase work"
  p=$(resolve_prereg "$t/clean")
  expect pass "clean/allowlist" check_allowlist "$t/clean" "$p..HEAD"
  expect pass "clean/untouched" check_untouched "$t/clean" "$p..HEAD"
  expect pass "clean/no-revert" check_no_revert "$t/clean" "$p..HEAD"

  # Control 2: templates/ touched after prereg must FAIL (allowlist AND frozen-surface).
  newrepo "$t/tmpl"; mkdir -p "$t/tmpl/templates"
  echo hook > "$t/tmpl/templates/h.sh"; ci "$t/tmpl" -m "touch template"
  p=$(resolve_prereg "$t/tmpl")
  expect fail "templates/allowlist" check_allowlist "$t/tmpl" "$p..HEAD"
  expect fail "templates/untouched" check_untouched "$t/tmpl" "$p..HEAD"

  # Control 3: a Revert commit whose body references d43950f must FAIL.
  newrepo "$t/rev"
  ci "$t/rev" --allow-empty -m 'Revert "ak-ride-along trim"' -m "This reverts commit d43950f."
  p=$(resolve_prereg "$t/rev")
  expect fail "revert-reference" check_no_revert "$t/rev" "$p..HEAD"

  # Control 4: out-of-allowlist file (install.sh) must FAIL.
  newrepo "$t/oos"
  echo x > "$t/oos/install.sh"; ci "$t/oos" -m "out of scope"
  p=$(resolve_prereg "$t/oos")
  expect fail "out-of-allowlist" check_allowlist "$t/oos" "$p..HEAD"

  # Control 5: repo without a committed prereg cannot anchor the range — resolve is empty.
  mkdir -p "$t/nop"; git -C "$t/nop" init -q; ci "$t/nop" --allow-empty -m base
  if [ -z "$(resolve_prereg "$t/nop")" ]; then pass=$((pass+1)); else
    echo "SELFTEST FAIL: missing-prereg repo resolved an anchor" >&2; fail=1; fi

  [ "$fail" -eq 0 ] && echo "SELFTEST PASS ($pass/8 controls)" || { echo "SELFTEST FAIL" >&2; exit 1; }
}

if [ "${1:-}" = "--selftest" ]; then selftest; exit 0; fi

REPO="${REPO:-$(git rev-parse --show-toplevel)}"
P=$(resolve_prereg "$REPO")
[ -n "$P" ] || { echo "NO-DISPOSITION: FAIL — $PREREG not committed (no range anchor)" >&2; exit 1; }
rc=0
check_allowlist "$REPO" "$P..HEAD" || rc=1
check_untouched "$REPO" "$P..HEAD" || rc=1
check_no_revert "$REPO" "$P..HEAD" || rc=1
[ "$rc" -eq 0 ] && echo "NO-DISPOSITION: PASS (range $P..HEAD)" || { echo "NO-DISPOSITION: FAIL" >&2; exit 1; }
