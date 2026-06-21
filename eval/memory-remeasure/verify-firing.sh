#!/usr/bin/env bash
# Phase 94 T1 — verify-by-firing: HARD admissibility gate.
#
# Drives the memory MCP server EXACTLY as Claude Code launches it (the global
# ~/.claude/settings.json `mcpServers.memory` entry: its configured python,
# `-m memory_server`, its `env.PYTHONPATH`) over real MCP stdio, with cwd set to a
# fresh mktemp CONSUMER directory, and asserts a store->search round-trip:
#   1. memory_store(scope=project) a unique marker,
#   2. memory_search(scope=project) returns that marker,
#   3. a row physically landed in <consumer-cwd>/.memory/memory.db (the CWD-relative
#      path that was the Ph91 couldn't-fire failure — NOT ~/.claude/.memory/).
# FIRES  => the retrospective demand zeros are admissible (genuine no-use, not couldn't-fire).
# COULDNT-FIRE (or --broken-control) => STOP: file the firing defect, Phase 95 stays blocked.
#
# Non-destructive: the round-trip runs in a mktemp sandbox consumer, never a real consumer DB.
# Controls-first: `--broken-control` drops PYTHONPATH so `-m memory_server` cannot be found from a
# consumer cwd (the exact Ph91 failure) and MUST classify COULDNT-FIRE — a clean-on-seed run there
# proves the firing detector is real, not a rubber stamp.
set -uo pipefail

SETTINGS="${HOME}/.claude/settings.json"
BROKEN=0
[ "${1:-}" = "--broken-control" ] && BROKEN=1

command -v jq >/dev/null 2>&1 || { echo "VERDICT: COULDNT-FIRE (jq missing)"; exit 1; }
[ -f "$SETTINGS" ] || { echo "VERDICT: COULDNT-FIRE (no ~/.claude/settings.json)"; exit 1; }

CMD=$(jq -r '.mcpServers.memory.command // empty' "$SETTINGS")
ARGS_JSON=$(jq -c '.mcpServers.memory.args // []' "$SETTINGS")
PP=$(jq -r '.mcpServers.memory.env.PYTHONPATH // empty' "$SETTINGS")
[ -n "$CMD" ] || { echo "VERDICT: COULDNT-FIRE (memory MCP not registered)"; exit 1; }

if [ "$BROKEN" -eq 1 ]; then
  PP="/tmp/nana-ph94-no-such-pythonpath"   # reproduce the Ph91 module-resolution break
fi

CONSUMER=$(mktemp -d)
MARKER="PH94-FIRING-PROBE-$$-$(date +%s)-$RANDOM"
DRIVER_PY=~/.claude/memory_server/.venv/bin/python3
[ -x "$DRIVER_PY" ] && CLIENT_PY="$DRIVER_PY" || CLIENT_PY="$(command -v python3)"

cleanup() { rm -rf "$CONSUMER"; }
trap cleanup EXIT

# --- drive the configured server over MCP stdio in the consumer cwd ---
HIT=$(FIRE_CMD="$CMD" FIRE_ARGS="$ARGS_JSON" FIRE_PP="$PP" FIRE_CWD="$CONSUMER" FIRE_MARKER="$MARKER" \
  "$CLIENT_PY" - <<'PYEOF' 2>/dev/null
import os, json, asyncio
try:
    from mcp import ClientSession, StdioServerParameters
    from mcp.client.stdio import stdio_client
except Exception:
    print("NO_HIT"); raise SystemExit(0)

cmd = os.environ["FIRE_CMD"]
args = json.loads(os.environ["FIRE_ARGS"])
marker = os.environ["FIRE_MARKER"]
env = dict(os.environ); env["PYTHONPATH"] = os.environ["FIRE_PP"]
params = StdioServerParameters(command=cmd, args=args, env=env, cwd=os.environ["FIRE_CWD"])

async def run():
    async with stdio_client(params) as (r, w):
        async with ClientSession(r, w) as s:
            await s.initialize()
            await s.call_tool("memory_store",
                              {"content": marker, "scope": "project", "category": "fact"})
            res = await s.call_tool("memory_search", {"query": marker, "scope": "project"})
            blob = json.dumps(getattr(res, "model_dump", lambda: res)(), default=str)
            return marker in blob

try:
    print("HIT" if asyncio.run(asyncio.wait_for(run(), timeout=60)) else "NO_HIT")
except Exception:
    print("NO_HIT")
PYEOF
)

# --- assert a row physically persisted to the CONSUMER's DB (CWD-relative) ---
DB="$CONSUMER/.memory/memory.db"
ROWS=0
if [ -f "$DB" ]; then
  ROWS=$(sqlite3 "$DB" "select count(*) from memories where content like '%${MARKER}%'" 2>/dev/null || echo 0)
fi

echo "consumer-cwd: $CONSUMER"
echo "search-roundtrip: ${HIT:-NO_HIT}   db-rows-for-marker: $ROWS   db-path: $DB"

if [ "${HIT:-NO_HIT}" = "HIT" ] && [ "${ROWS:-0}" -ge 1 ]; then
  echo "VERDICT: FIRES"
  [ "$BROKEN" -eq 1 ] && { echo "CONTROL-FAIL: broken-config FIRED — firing detector is not trustworthy"; exit 1; }
  exit 0
else
  echo "VERDICT: COULDNT-FIRE"
  # broken-control SHOULD land here — that is the control passing.
  [ "$BROKEN" -eq 1 ] && exit 0
  exit 1
fi
