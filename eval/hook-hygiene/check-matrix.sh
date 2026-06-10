#!/usr/bin/env bash
# Phase 84 T4a/T4b — deterministic validator for the ghost-registration coverage matrix.
# Asserts the matrix is complete (a row per discovered root x 11 ghost hooks, registration +
# copy-currency cells filled from a closed vocabulary) and carries its own positive control
# (at least one registered=yes cell — a matrix claiming 0 registrations anywhere is exactly the
# zsh word-splitting instrument-death this phase's gate self-caught).
# T4b extension (end-state): basename-normalized live extraction == modules.json scope:global
# set, OR registration-exceptions.md records a maintainer decision.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MATRIX="$SCRIPT_DIR/coverage-matrix.md"

FAIL=0
say() { echo "check-matrix: $*"; }

GHOSTS="session-start.sh session-stop.sh enforce-loop.sh pre-compact.sh post-compact.sh stale-queue.sh detect-loop.sh post-commit.sh enforce-spec.sh enforce-memory.sh dev-wiki-scope-check.sh"

[ -f "$MATRIX" ] || { say "FAIL coverage-matrix.md missing"; exit 1; }

ROOTS=$(sed -n 's/^roots: //p' "$MATRIX" | head -1)
[ -n "$ROOTS" ] || { say "FAIL no 'roots:' line"; exit 1; }

NROOTS=0
for ROOT in $(echo "$ROOTS"); do
  NROOTS=$((NROOTS + 1))
  for H in $(echo "$GHOSTS"); do
    ROW=$(grep -E "^\| $(basename "$ROOT") \| $H \|" "$MATRIX" | head -1)
    if [ -z "$ROW" ]; then
      say "FAIL missing row: $(basename "$ROOT") x $H"; FAIL=1; continue
    fi
    echo "$ROW" | grep -qE '\| (yes|no) \| (current|stale|absent) \|$' || { say "FAIL malformed cells: $ROW"; FAIL=1; }
  done
done
[ "$NROOTS" -ge 1 ] || { say "FAIL zero roots"; FAIL=1; }

# Positive control: a matrix with no registered=yes cell anywhere is instrument-dead, not clean.
grep -qE '^\| [^|]+ \| [^|]+ \| yes \|' "$MATRIX" || { say "FAIL positive control: no registered=yes cell in the whole matrix"; FAIL=1; }

# Row-count exactness: rows == roots x 11 (no stray/duplicate rows)
EXPECT=$((NROOTS * 11))
GOT=$(grep -cE '^\| [^|]+ \| [^|]+\.sh \| (yes|no) \| (current|stale|absent) \|$' "$MATRIX")
[ "$GOT" -eq "$EXPECT" ] || { say "FAIL row count: got $GOT want $EXPECT"; FAIL=1; }

# ---- T4b end-state assertion (active once a checkpoint-decision line exists in rehearsal.log) ----
REHEARSAL="$SCRIPT_DIR/rehearsal.log"
DECISION=$(grep -oE '^checkpoint-decision: (approve|partial|defer)' "$REHEARSAL" 2>/dev/null | head -1 | awk '{print $2}')
if [ -n "${DECISION:-}" ]; then
  LIVE_KIT_HOOKS=$(jq -r '.hooks | to_entries[] | .value[].hooks[]?.command // empty' "$HOME/.claude/settings.json" 2>/dev/null \
    | grep -oE '[a-z0-9-]+\.sh' | sort -u)
  GLOBAL_SET=$(jq -r '.hooks[] | select(.scope == "global") | .script' "$REPO_ROOT/modules.json" | sort -u)
  KIT_OWNED=$(jq -r '.hooks[].script' "$REPO_ROOT/modules.json" | sort -u)
  LIVE_KIT_OWNED=$(comm -12 <(echo "$LIVE_KIT_HOOKS") <(echo "$KIT_OWNED"))
  if [ "$LIVE_KIT_OWNED" = "$GLOBAL_SET" ]; then
    say "end-state: live kit-owned global registrations == modules.json scope:global set"
  elif grep -qE '^maintainer-decision: (approve|partial|defer)' "$SCRIPT_DIR/registration-exceptions.md" 2>/dev/null; then
    say "end-state: exceptions documented in registration-exceptions.md ($(sed -n 's/^maintainer-decision: //p' "$SCRIPT_DIR/registration-exceptions.md" | head -1))"
  else
    say "FAIL end-state: live extraction != scope:global set AND no registration-exceptions.md decision"; FAIL=1
  fi
fi

if [ "$FAIL" -eq 0 ]; then say "PASS"; exit 0; else exit 1; fi
