#!/usr/bin/env bash
# check-substrate-intact.sh — Phase 87. Asserts the substrate record shows edge-screener
# refs byte-identical post-experiment (or ship-checkpoint-authorized) and the kit-commit
# embargo (component-path diff vs pinned base 6728e2f) held at both arm starts and close.
# --record-only <file>: validate a record file alone (fixture mode, no live git checks).
# Default mode additionally executes the LIVE kit embargo diff. Exit 0 iff intact.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mode=live
if [ "${1:-}" = "--record-only" ]; then mode=record; shift; fi
F="${1:-$DIR/substrate-record.md}"
fail=0
[ -f "$F" ] || { echo "FAIL: $F missing"; exit 1; }

grep -qE '^PRE-EXPERIMENT-SHA: [0-9a-f]+' "$F" && echo "PASS: pre-experiment SHA recorded" || { echo "FAIL: PRE-EXPERIMENT-SHA missing"; fail=1; }
if grep -qE '^POST-REFS: (IDENTICAL|SHIP-AUTHORIZED)$' "$F"; then
  echo "PASS: post-experiment refs IDENTICAL or SHIP-AUTHORIZED"
else
  echo "FAIL: POST-REFS not IDENTICAL/SHIP-AUTHORIZED"; fail=1
fi
for k in EMBARGO-AT-B-START EMBARGO-AT-A-START EMBARGO-AT-CLOSE; do
  grep -qE "^$k: EMPTY$" "$F" && echo "PASS: $k EMPTY" || { echo "FAIL: $k not EMPTY"; fail=1; }
done

if [ "$mode" = "live" ]; then
  ROOT="$(git -C "$DIR" rev-parse --show-toplevel)"
  if git -C "$ROOT" diff --quiet 6728e2f..HEAD -- templates/ scripts/ install.sh modules.json Makefile; then
    echo "PASS: live kit-component embargo diff empty vs 6728e2f"
  else
    echo "FAIL: kit component modified since pinned base 6728e2f"; fail=1
  fi
fi
[ "$fail" -eq 0 ] && echo "SUBSTRATE-INTACT: PASS" || echo "SUBSTRATE-INTACT: FAIL"
exit "$fail"
