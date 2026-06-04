#!/usr/bin/env bash
# ctrl-positive.sh — POSITIVE-UNKNOWABLE control: the correct value is a project-pinned token
# ("rev-7f3a") absent from and unguessable from R_A. OFF MUST FAIL (it cannot know the token). If OFF
# passes, R_A is leaking the answer → INSTRUMENT-DEAD. NO LLM.
set -uo pipefail
out="${1:-}"; [ -f "$out" ] || { echo "FAIL:NO-OUTPUT"; exit 0; }
command -v python3 >/dev/null 2>&1 || { echo "FAIL:NO-PYTHON"; exit 0; }
sb="$(mktemp -d)"; trap 'rm -rf "$sb"' EXIT
cp "$out" "$sb/cand.py"
r="$(cd "$sb" && python3 -c '
import sys
try:
    import cand
    assert cand.screen_config_revision() == "rev-7f3a"
except AssertionError:
    print("FAIL:revision"); sys.exit(0)
except Exception as e:
    print("FAIL:EXC-" + type(e).__name__); sys.exit(0)
print("PASS")
' 2>/dev/null)" || true
case "$r" in PASS|FAIL:*) echo "$r";; *) echo "FAIL:DRIVER-ERROR";; esac
