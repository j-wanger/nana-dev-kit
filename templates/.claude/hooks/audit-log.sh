#!/usr/bin/env bash
# PostToolUse hook — appends a JSONL audit record for every file write.
# Captures: timestamp, tool, file path, model (from env if available).
# Output: .nana/audit.jsonl (gitignored by default).

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('input',{}).get('file_path',''))" 2>/dev/null || echo "")
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name','unknown'))" 2>/dev/null || echo "unknown")

[ -z "$FILE_PATH" ] && exit 0

mkdir -p .nana
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
MODEL="${CLAUDE_MODEL:-unknown}"

printf '{"ts":"%s","tool":"%s","file":"%s","model":"%s"}\n' \
  "$TIMESTAMP" "$TOOL_NAME" "$FILE_PATH" "$MODEL" >> .nana/audit.jsonl

exit 0
