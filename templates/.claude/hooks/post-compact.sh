#!/usr/bin/env bash
# PostCompact hook — triggers recall after compaction to restore high-value context.
# Works with or without dev-wiki.

set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

echo '[nana:compact] Context was compacted. Search memory for category=correction to reload behavioral corrections. Re-read .claude/rules/active-phase.md for phase context.'

if [ -f "$ROOT/.claude/.session-anchor" ]; then
  echo "[nana:anchor] Pre-compaction anchor exists. Read $ROOT/.claude/.session-anchor and follow its recovery instructions. Delete the file after loading."
fi

if [ -d "$ROOT/.dev-wiki" ]; then
  echo '[nana:devwiki] Re-read .dev-wiki/tasks.md for current task state.'
fi

# Clear the context-warned flag so the size monitor can re-trigger next session
rm -f "$ROOT/.claude/.context-warned" 2>/dev/null || true

exit 0
