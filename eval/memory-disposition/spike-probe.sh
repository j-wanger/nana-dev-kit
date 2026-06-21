#!/usr/bin/env bash
# Phase 95 T2 — redesign feasibility SPIKE probe.
#
# This is the CANDIDATE core of a redesigned enforce-memory: instead of checking marker-file EXISTENCE
# (.claude/.memory-consulted, agent-touched = gameable), it asserts a REAL prior in-session memory_search by
# reading the session transcript JSONL that PreToolUse delivers on stdin as `.transcript_path`.
#
# Detection is JSON-disciplined (never grep): a real call is type==assistant -> message.content[] ->
# tool_use with name~memory_search — the deferred-tool catalog (attachment/system entries) is excluded by
# the type gate, so it cannot satisfy the gate spuriously.
#
# Polarity: exit 0 = allow (a real search this session), exit 2 = block. FAIL-OPEN (exit 0) on any infra
# failure (no transcript_path, unreadable, no jq/python) — a relevance gate must never block on its own
# breakage. Reads stdin JSON like a real PreToolUse hook.
set -uo pipefail

INPUT=$(cat 2>/dev/null || echo "")
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")

# fail-open: no transcript path delivered, or not readable
[ -n "$TRANSCRIPT" ] || { echo "[spike] no transcript_path — fail-open allow" >&2; exit 0; }
[ -r "$TRANSCRIPT" ] || { echo "[spike] transcript unreadable — fail-open allow" >&2; exit 0; }
command -v python3 >/dev/null 2>&1 || { echo "[spike] no python3 — fail-open allow" >&2; exit 0; }

# Deterministic JSON scan; short-circuits on the first real assistant tool_use memory_search.
FOUND=$(python3 - "$TRANSCRIPT" <<'PY'
import json, sys
path = sys.argv[1]
try:
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if not line or '"tool_use"' not in line:   # cheap pre-filter; the JSON check below is authoritative
                continue
            try:
                ev = json.loads(line)
            except Exception:
                continue
            if ev.get("type") != "assistant":
                continue
            content = (ev.get("message") or {}).get("content")
            if not isinstance(content, list):
                continue
            for b in content:
                if isinstance(b, dict) and b.get("type") == "tool_use" and "memory_search" in (b.get("name") or ""):
                    print("FOUND")
                    sys.exit(0)
except Exception:
    print("ERR")     # signal infra failure -> caller fails open
    sys.exit(0)
print("NONE")
PY
)

case "$FOUND" in
  FOUND) exit 0 ;;                 # real search -> allow
  ERR)   exit 0 ;;                 # infra failure -> fail-open allow
  *)     echo "[spike] no real memory_search this session" >&2; exit 2 ;;  # block
esac
