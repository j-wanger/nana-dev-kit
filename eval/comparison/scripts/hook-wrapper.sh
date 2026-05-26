#!/usr/bin/env bash
# hook-wrapper.sh — Wraps a harness hook with JSONL timing/exit-code logging
# Usage: hook-wrapper.sh <hook_name> <original_command> [args...]
# Logs to .claude/hook-invocations.jsonl in the current working directory

HOOK_NAME="${1:?Usage: hook-wrapper.sh <hook_name> <command> [args...]}"
shift
ORIGINAL_CMD="$*"

LOG_FILE="${PWD}/.claude/hook-invocations.jsonl"
mkdir -p "$(dirname "$LOG_FILE")"

START_MS=$(python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || date +%s000)

set +e
eval "$ORIGINAL_CMD"
EXIT_CODE=$?
set -e

END_MS=$(python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || date +%s000)
DURATION_MS=$((END_MS - START_MS))
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

printf '{"hook_name":"%s","timestamp":"%s","exit_code":%d,"duration_ms":%d}\n' \
    "$HOOK_NAME" "$TIMESTAMP" "$EXIT_CODE" "$DURATION_MS" >> "$LOG_FILE"

exit $EXIT_CODE
