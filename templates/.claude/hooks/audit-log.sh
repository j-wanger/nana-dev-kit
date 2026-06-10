#!/usr/bin/env bash
# PostToolUse hook — appends a JSONL audit record for every file write.
# Captures: timestamp, tool, file path.
# Output: .nana/audit.jsonl (gitignored by default).

set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true  # Phase 79: resolve project-relative refs regardless of CWD

command -v jq >/dev/null 2>&1 || { echo "[nana:audit] jq not found, hook skipped" >&2; exit 0; }

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .input.file_path // empty' 2>/dev/null || echo "")
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")

[ -z "$FILE_PATH" ] && exit 0

mkdir -p .nana 2>/dev/null || true
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# jq --arg (never string-interpolation): the file path IS recorded (that's the forensic point),
# but escaped — a path containing " or a newline must not corrupt the JSONL. Write is fail-open
# so an unwritable .nana never makes this PostToolUse hook exit non-zero.
{ jq -nc --arg ts "$TIMESTAMP" --arg tool "$TOOL_NAME" --arg file "$FILE_PATH" \
    '{ts:$ts,tool:$tool,file:$file}' >> .nana/audit.jsonl; } 2>/dev/null || true

exit 0
