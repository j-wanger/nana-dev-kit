#!/usr/bin/env bash
# Phase 85 — assert the kit-owned hook commands in ~/.claude/settings.json equal EXACTLY the
# modules.json scope:global script set (the Phase-84 deregistration end-state must not regress).
#
# Identity = script BASENAME: live command forms are mixed (bash ~/.claude/hooks/X.sh, absolute
# paths, ${CLAUDE_PROJECT_DIR} forms) — naive string comparison sees one hook as many.
# Kit-owned = basename appears in modules.json .hooks[].script (user-owned hooks are ignored).
#
# POSITIVE CONTROL built in: the command extraction must yield at least one command overall —
# a zero-extraction instrument reads as BROKEN (exit 2), never as pass (the zsh word-split
# false-0/11-matrix class, Phase 84).
#
# Usage: assert-global-set.sh [settings.json]   # default ~/.claude/settings.json
# Exit: 0 = sets equal; 1 = mismatch (diff printed); 2 = instrument/input problem.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MODULES_JSON="$KIT_ROOT/modules.json"
SETTINGS="${1:-$HOME/.claude/settings.json}"

command -v jq >/dev/null 2>&1 || { echo "assert-global-set: jq required" >&2; exit 2; }
[ -f "$MODULES_JSON" ] || { echo "assert-global-set: modules.json not found: $MODULES_JSON" >&2; exit 2; }
[ -f "$SETTINGS" ] || { echo "assert-global-set: settings file not found: $SETTINGS" >&2; exit 2; }

EXPECTED=$(jq -r '.hooks[] | select(.scope == "global") | .script' "$MODULES_JSON" | sort -u)
KIT_SCRIPTS=$(jq -r '.hooks[].script' "$MODULES_JSON" | sort -u)

# All hook commands in the settings file (nested schema: hooks.<Event>[].hooks[].command).
ALL_CMDS=$(jq -r '.hooks // {} | .. | .command? // empty' "$SETTINGS" 2>/dev/null)

# Positive control: an empty extraction on a file that HAS a hooks key = broken instrument.
if [ -z "$ALL_CMDS" ]; then
  if jq -e '.hooks | length > 0' "$SETTINGS" >/dev/null 2>&1; then
    echo "assert-global-set: POSITIVE CONTROL FAILED — settings has hooks but extraction found 0 commands" >&2
    exit 2
  fi
  ACTUAL=""   # genuinely no hooks registered
else
  # Normalize: every whitespace token ending in .sh, basename'd, filtered to kit-owned.
  # MULTISET first (spec criterion 4): a hook registered twice must FAIL, not collapse via sort -u.
  ACTUAL_ALL=$(printf '%s\n' "$ALL_CMDS" | tr ' \t' '\n\n' | grep '\.sh$' | sed 's#.*/##' | sort \
           | grep -xF -f <(printf '%s\n' "$KIT_SCRIPTS") || true)
  DUPES=$(printf '%s\n' "$ACTUAL_ALL" | uniq -d)
  if [ -n "$DUPES" ]; then
    echo "assert-global-set: FAIL — kit hook(s) registered more than once (multiset violation):" >&2
    printf '  %s\n' $DUPES >&2
    exit 1
  fi
  ACTUAL=$(printf '%s\n' "$ACTUAL_ALL" | uniq)   # dupe-free here (checked above), sorted
fi

if [ "$EXPECTED" = "$ACTUAL" ]; then
  echo "assert-global-set: PASS — kit-owned hooks in $SETTINGS == modules.json scope:global set:"
  printf '  %s\n' $EXPECTED
  exit 0
else
  echo "assert-global-set: FAIL — set mismatch (expected vs actual):" >&2
  diff <(printf '%s\n' "$EXPECTED") <(printf '%s\n' "$ACTUAL") >&2 || true
  exit 1
fi
