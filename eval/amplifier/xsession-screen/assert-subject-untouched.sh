#!/usr/bin/env bash
# assert-subject-untouched.sh — read-only guard for the cross-session screen (Phase 77).
#
# edge-screener is a FIXED historical SUBJECT: the residual audit (and any later condition build) must
# read it, never write it. This proves that — snapshot the subject's working-tree status + the byte
# hashes of its substrate (.dev-wiki/.claude/AGENTS.md) before a run, re-verify after; any drift fails
# CLOSED (adversarial constraint #6 — mutating the historical record contaminates the measurement).
#
#   assert-subject-untouched.sh --snapshot <subject> <snapfile>   # capture baseline
#   ... run the audit / condition build (read-only) ...
#   assert-subject-untouched.sh --verify   <subject> <snapfile>   # exits 0 iff byte-identical, 1 on drift
#   assert-subject-untouched.sh --selftest                        # proves it PASSES unchanged + DETECTS a mutation
set -euo pipefail

SUBSTRATE_PATHS=".dev-wiki .claude AGENTS.md"

snapshot() {  # <subject> <out>   — deterministic manifest: porcelain status + sorted substrate hashes
  local subject="$1" out="$2" p existing=""
  for p in $SUBSTRATE_PATHS; do [ -e "$subject/$p" ] && existing="$existing $p"; done
  {
    echo "## git-status"
    if git -C "$subject" rev-parse --git-dir >/dev/null 2>&1; then
      git -C "$subject" status --porcelain
    else
      echo "(not a git repo)"
    fi
    echo "## substrate-hashes"
    if [ -n "$existing" ]; then
      ( cd "$subject" && find $existing -type f 2>/dev/null | LC_ALL=C sort | tr '\n' '\0' \
          | xargs -0 shasum -a 256 2>/dev/null ) || true
    fi
  } > "$out"
}

verify() {  # <subject> <snapfile>  → exits 0 untouched / 1 drift
  local subject="$1" snap="$2" tmp
  [ -f "$snap" ] || { echo "assert-untouched: baseline snapshot missing: $snap" >&2; return 2; }
  tmp="$(mktemp)"; snapshot "$subject" "$tmp"
  if diff -q "$snap" "$tmp" >/dev/null 2>&1; then
    rm -f "$tmp"; echo "untouched: OK"; return 0
  else
    echo "DRIFT — subject was mutated during the run:" >&2
    diff "$snap" "$tmp" >&2 || true
    rm -f "$tmp"; return 1
  fi
}

selftest() {
  local fail=0 sx snap
  sx="$(mktemp -d)"; snap="$(mktemp)"
  mkdir -p "$sx/src" "$sx/.dev-wiki/articles/decisions"
  printf 'code\n' > "$sx/src/a.py"
  printf 'decision body\n' > "$sx/.dev-wiki/articles/decisions/d.md"
  printf 'agents\n' > "$sx/AGENTS.md"
  ( cd "$sx" && git init -q && git config user.email t@t && git config user.name t \
      && git add -A && git commit -q -m init ) >/dev/null 2>&1

  snapshot "$sx" "$snap"
  if verify "$sx" "$snap" >/dev/null 2>&1; then echo "ok: unchanged → untouched"; else echo "FAIL: unchanged flagged drift"; fail=1; fi

  # mutate a substrate file → must be DETECTED
  printf 'TAMPERED\n' >> "$sx/.dev-wiki/articles/decisions/d.md"
  if verify "$sx" "$snap" >/dev/null 2>&1; then echo "FAIL: substrate mutation NOT detected"; fail=1; else echo "ok: substrate mutation → DRIFT detected"; fi

  # restore, then a stray untracked file (e.g. an audit accidentally writing into the subject) → DETECTED
  ( cd "$sx" && git checkout -q -- .dev-wiki/articles/decisions/d.md ) >/dev/null 2>&1
  if verify "$sx" "$snap" >/dev/null 2>&1; then echo "ok: restored → untouched"; else echo "FAIL: restore not clean"; fail=1; fi
  printf 'stray\n' > "$sx/residual.md"
  if verify "$sx" "$snap" >/dev/null 2>&1; then echo "FAIL: stray untracked file NOT detected"; fail=1; else echo "ok: stray untracked file → DRIFT detected"; fi

  rm -rf "$sx"; rm -f "$snap"
  [ "$fail" -eq 0 ] && { echo "SELFTEST: PASS"; return 0; } || { echo "SELFTEST: FAIL"; return 1; }
}

case "${1:---selftest}" in
  --snapshot) shift; [ $# -eq 2 ] || { echo "usage: --snapshot <subject> <out>" >&2; exit 2; }; snapshot "$1" "$2"; echo "snapshot: $2";;
  --verify)   shift; [ $# -eq 2 ] || { echo "usage: --verify <subject> <snapfile>" >&2; exit 2; }; verify "$1" "$2";;
  --selftest) selftest;;
  *) echo "usage: assert-subject-untouched.sh --snapshot|--verify|--selftest ..." >&2; exit 2;;
esac
