#!/usr/bin/env bash
# Phase 86 — verdicts-only invariant (spec exit criterion 8).
# No kit component modified this phase: empty diff against the pinned base 5360486
# over the kit-component paths. eval/, .dev-wiki/, specs/, .claude/rules/ are not in
# the pathspec (measurement + lifecycle artifacts are allowed). Makefile deliberately
# untouched this phase — controls run via run-exit-criteria.sh, not make test.
set -uo pipefail
cd "$(dirname "$0")/../.."
BASE=5360486
if git diff --quiet "$BASE"..HEAD -- templates/ scripts/ install.sh modules.json Makefile; then
  echo "check-verdicts-only: PASS (no kit component modified since $BASE)"
  exit 0
else
  echo "check-verdicts-only: FAIL — kit components changed since $BASE:"
  git diff --stat "$BASE"..HEAD -- templates/ scripts/ install.sh modules.json Makefile
  exit 1
fi
