#!/usr/bin/env bash
# PostToolUse hook (Edit|Write) — appends changed source file paths to .dev-wiki/.stale-queue
# for incremental refresh at next session start. See dev-wiki-reference.md Section R.

set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true  # Phase 79: resolve project-relative refs regardless of CWD

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
[ -d "$ROOT/.dev-wiki" ] || exit 0

# --- jq fail-open guard ---
command -v jq >/dev/null 2>&1 || { echo "[nana:stale-queue] jq not found, hook skipped" >&2; exit 0; }

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .input.file_path // empty' 2>/dev/null || echo "")
[ -z "$FILE_PATH" ] && exit 0

# Convert to project-relative path
REL_PATH="${FILE_PATH#$ROOT/}"
[[ "$REL_PATH" == /* ]] && exit 0

# Skip dev-wiki, claude config, wiki, and markdown
case "$REL_PATH" in
  .dev-wiki/*|.claude/*|wiki/*) exit 0 ;;
  *.md) exit 0 ;;
esac

# Skip Section Q exclusion patterns
case "$REL_PATH" in
  node_modules/*|.git/*|dist/*|build/*|__pycache__/*) exit 0 ;;
  .venv/*|venv/*|.tox/*|*.egg-info/*|.mypy_cache/*|.pytest_cache/*) exit 0 ;;
esac

# Skip binary extensions
case "$REL_PATH" in
  *.png|*.jpg|*.gif|*.ico|*.woff|*.ttf|*.pdf) exit 0 ;;
  *.pyc|*.o|*.so|*.dylib|*.class|*.jar) exit 0 ;;
esac

QUEUE="$ROOT/.dev-wiki/.stale-queue"

# Hard cap: 200 entries
if [ -f "$QUEUE" ]; then
  COUNT=$(wc -l < "$QUEUE" | tr -d ' ')
  if [ "$COUNT" -ge 200 ]; then
    echo "[nana:stale-queue] Queue full (200 entries). Entry dropped: $REL_PATH" >&2
    exit 0
  fi
  # Best-effort dedup
  grep -qxF "$REL_PATH" "$QUEUE" 2>/dev/null && exit 0
fi

echo "$REL_PATH" >> "$QUEUE"
exit 0
