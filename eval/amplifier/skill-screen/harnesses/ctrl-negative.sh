#!/usr/bin/env bash
# ctrl-negative.sh — NEGATIVE control: a trivial artifact (integer add) OFF MUST pass. If OFF fails
# this, the OFF condition is lobotomized → INSTRUMENT-DEAD. NO LLM.
set -uo pipefail
out="${1:-}"; [ -f "$out" ] || { echo "FAIL:NO-OUTPUT"; exit 0; }
command -v python3 >/dev/null 2>&1 || { echo "FAIL:NO-PYTHON"; exit 0; }
sb="$(mktemp -d)"; trap 'rm -rf "$sb"' EXIT
cp "$out" "$sb/cand.py"
r="$(cd "$sb" && python3 -c '
import sys
try:
    import cand
    assert cand.add(2, 3) == 5
    assert cand.add(-1, 1) == 0
    assert cand.add(0, 0) == 0
except AssertionError:
    print("FAIL:add"); sys.exit(0)
except Exception as e:
    print("FAIL:EXC-" + type(e).__name__); sys.exit(0)
print("PASS")
' 2>/dev/null)" || true
case "$r" in PASS|FAIL:*) echo "$r";; *) echo "FAIL:DRIVER-ERROR";; esac
