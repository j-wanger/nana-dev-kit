#!/usr/bin/env bash
# Phase 85 — checkpoint-1 rehearsal: prove the install + dir-currency fixes end-to-end in
# sandboxes BEFORE any live-root write (HEU-012: sandbox-first; live ~/.claude is READ-ONLY here).
#
# Part A — project-local rehearsal: full --project-local install into a mktemp project, then run
#          the installed SessionStart chain. FIXTURE PROVENANCE: session-start.sh consumes NO
#          stdin event fields (verified by code read: no `read`/`jq` of stdin in the script) —
#          the pinned "event" is therefore the EMPTY stdin, which exercises every code path a
#          captured real event would. A hand-written JSON here would be circularity theater.
# Part B — global rehearsal: full install into a mktemp HOME; assert the scope:global set,
#          NO session-start.d shipped (its consumer is scope:project), drift 0 on the fresh root.
# Part C — LIVE POSITIVE CONTROL: selective COPY of the real ~/.claude; seed one stale curator
#          file; the new dir-currency cells must flag it (clean-on-seed = instrument-dead).
#          Also records the real root's CURRENT drift state, read-only, for the checkpoint.
#
# Usage: rehearse.sh | tee rehearsal.log     Exit 0 = all parts green.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CHECKER="$KIT_ROOT/scripts/check-install-drift.sh"
FAIL=0
say() { printf '%s %s\n' "[$(date -u +%Y-%m-%dT%H:%M:%SZ)]" "$*"; }
verdict() { # $1 label, $2 0/1
  if [ "$2" -eq 0 ]; then say "PASS: $1"; else say "FAIL: $1"; FAIL=1; fi
}

say "rehearsal start — kit=$KIT_ROOT HEAD=$(git -C "$KIT_ROOT" rev-parse --short HEAD 2>/dev/null || echo n/a)"

# ---------- Part A: project-local install + SessionStart chain ----------
PROJ=$(mktemp -d)
SHOME_A=$(mktemp -d)
say "A: project sandbox=$PROJ HOME=$SHOME_A"
( cd "$PROJ" && HOME="$SHOME_A" bash "$KIT_ROOT/install.sh" --project-local ) >/dev/null 2>&1
verdict "A1 --project-local install exits 0" $?

CUR_OK=0
for c in wk-prune.sh memory-nudge.sh cognitive-readiness.sh; do
  [ -f "$PROJ/.claude/hooks/session-start.d/$c" ] || CUR_OK=1
done
verdict "A2 all 3 curators shipped to project sandbox" $CUR_OK

mkdir -p "$SHOME_A/.claude"
SS_OUT=$(cd "$PROJ" && HOME="$SHOME_A" CLAUDE_PROJECT_DIR="$PROJ" \
         bash "$PROJ/.claude/hooks/session-start.d/../session-start.sh" < /dev/null 2>&1)
SS_RC=$?
verdict "A3 installed SessionStart chain exits 0 on the pinned (empty-stdin) event" $SS_RC
say "A3 provenance: session-start.sh reads no stdin fields (code-read verified); empty stdin = full coverage"
say "A3 output head: $(printf '%s' "$SS_OUT" | head -2 | tr '\n' ' | ')"

# ---------- Part B: global install into sandbox HOME ----------
SHOME_B=$(mktemp -d)
# stub venv so the core module skips the slow venv build (pip lines are ||-guarded)
mkdir -p "$SHOME_B/.claude/memory_server/.venv/bin"
printf '#!/bin/sh\nexit 0\n' > "$SHOME_B/.claude/memory_server/.venv/bin/python3"
chmod +x "$SHOME_B/.claude/memory_server/.venv/bin/python3"
say "B: global sandbox HOME=$SHOME_B"
HOME="$SHOME_B" bash "$KIT_ROOT/install.sh" >/dev/null 2>&1
verdict "B1 full global install exits 0" $?
[ ! -d "$SHOME_B/.claude/hooks/session-start.d" ]
verdict "B2 session-start.d NOT shipped globally (consumer is scope:project)" $?
bash "$SCRIPT_DIR/assert-global-set.sh" "$SHOME_B/.claude/settings.json" >/dev/null 2>&1
verdict "B3 sandbox settings.json kit hooks == scope:global set" $?
N=$("$CHECKER" --count "$SHOME_B/.claude")
[ "$N" = "0" ]
verdict "B4 fresh sandbox root drift count 0 (got: $N)" $?

# ---------- Part C: live positive control (read-only on the real root) ----------
LIVE="$HOME/.claude"
COPY=$(mktemp -d)/claude-copy
mkdir -p "$COPY"
for d in hooks rules skills; do
  [ -d "$LIVE/$d" ] && cp -R "$LIVE/$d" "$COPY/$d"
done
[ -f "$LIVE/settings.json" ] && cp "$LIVE/settings.json" "$COPY/settings.json"
say "C: live-copy sandbox=$COPY (real ~/.claude untouched)"

PRE_N=$("$CHECKER" --count "$COPY")
say "C1 live root CURRENT drift state (via copy, read-only): count=$PRE_N"
[ "$PRE_N" != "0" ] && "$CHECKER" "$COPY" 2>&1 | sed 's/^/      /' || true

if [ -d "$COPY/hooks/session-start.d" ] && [ -f "$COPY/hooks/session-start.d/wk-prune.sh" ]; then
  echo "seeded-stale-line" >> "$COPY/hooks/session-start.d/wk-prune.sh"
  POST=$("$CHECKER" "$COPY" 2>&1 || true)
  echo "$POST" | grep -q '^differs: hooks/session-start.d/wk-prune.sh'
  verdict "C2 POSITIVE CONTROL: seeded stale curator on the live-copy is flagged" $?
else
  say "FAIL: C2 live copy lacks session-start.d/wk-prune.sh — cannot run positive control"
  FAIL=1
fi

say "rehearsal end — overall: $([ "$FAIL" -eq 0 ] && echo GREEN || echo RED)"
exit $FAIL
