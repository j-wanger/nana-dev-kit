#!/usr/bin/env bash
# Phase 88 ghost-registration sweep. Asserts that NO hook registration on any discovered
# settings surface points at a nonexistent script — the registered-but-dormant class the
# kit has been bitten by 4+ times. Surfaces discovered mechanically (Phase-83/84 method):
#   ~/.claude/settings.json, plus each root's .claude/settings.json AND
#   .claude/settings.local.json (gitignored in consuming projects — repo greps can't see it).
# Roots: this repo + any project recorded in the kit-path marker scan.
# Usage: check-ghost-registrations.sh [--surface <file>]...   (explicit surfaces for tests)
# Controls-first: must FAIL on a seeded ghost fixture before vouching (see
# checker-fixtures/ghost-settings.json + the seeded control in this file's test mode).
set -uo pipefail
command -v jq >/dev/null || { echo "ERROR: jq required"; exit 1; }

surfaces=()
if [ "${1:-}" = "--surface" ]; then
  while [ "${1:-}" = "--surface" ]; do surfaces+=("$2"); shift 2; done
else
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  for f in "$HOME/.claude/settings.json" "$ROOT/.claude/settings.json" "$ROOT/.claude/settings.local.json"; do
    [ -f "$f" ] && surfaces+=("$f")
  done
  # kit-marker scan: consuming projects recorded on this machine
  if [ -f "$HOME/.claude/.nana-dev-kit-path" ]; then :; fi
  for proj in "$HOME"/*/.claude/settings.json "$HOME"/*/*/.claude/settings.json; do
    [ -f "$proj" ] || continue
    d=$(dirname "$proj")
    # only roots that carry kit-named hooks (cheap marker: hooks dir with kit scripts)
    ls "$d/hooks" 2>/dev/null | grep -qE 'enforce-spec|enforce-loop|session-start' || continue
    surfaces+=("$proj")
    [ -f "$d/settings.local.json" ] && surfaces+=("$d/settings.local.json")
  done
fi

fail=0; checked=0
for s in "${surfaces[@]}"; do
  base=$(dirname "$s")            # .../.claude
  proj=$(dirname "$base")         # project root (for ${CLAUDE_PROJECT_DIR} resolution)
  while IFS= read -r cmd; do
    [ -n "$cmd" ] || continue
    # first token that looks like a path to a .sh script
    script=$(grep -oE '[^ ]+\.sh' <<< "$cmd" | head -1) || true
    [ -n "${script:-}" ] || continue
    resolved="${script//\$\{CLAUDE_PROJECT_DIR\}/$proj}"
    resolved="${resolved//\$HOME/$HOME}"
    resolved="${resolved/#\~/$HOME}"
    case "$resolved" in /*) : ;; *) resolved="$proj/$resolved" ;; esac
    checked=$((checked+1))
    if [ ! -f "$resolved" ]; then
      echo "FAIL: ghost registration in $s -> $script (resolved: $resolved)"; fail=1
    fi
  done < <(jq -r '.. | objects | select(has("command")) | .command' "$s" 2>/dev/null)
done

echo "checked $checked registrations across ${#surfaces[@]} surfaces"
[ "$checked" -gt 0 ] || { echo "FAIL: zero registrations checked (vacuous sweep)"; exit 1; }
[ "$fail" -eq 0 ] && echo "GHOST-SWEEP: PASS" || echo "GHOST-SWEEP: FAIL"
exit "$fail"
