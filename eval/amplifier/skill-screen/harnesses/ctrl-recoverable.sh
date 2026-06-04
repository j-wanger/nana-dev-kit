#!/usr/bin/env bash
# ctrl-recoverable.sh — RECOVERABLE-FULLY-SPECIFIED control: an artifact whose correctness is FULLY
# stated in its R_A (clamp(x,lo,hi) with the exact branch behavior). OFF MUST pass. If OFF fails a
# fully-specified, recoverable artifact, the corpora are systematically too thin and every HAS-HEADROOM
# is suspect → INSTRUMENT-DEAD (the symmetric partner to the positive control). NO LLM.
set -uo pipefail
out="${1:-}"; [ -f "$out" ] || { echo "FAIL:NO-OUTPUT"; exit 0; }
command -v python3 >/dev/null 2>&1 || { echo "FAIL:NO-PYTHON"; exit 0; }
sb="$(mktemp -d)"; trap 'rm -rf "$sb"' EXIT
cp "$out" "$sb/cand.py"
r="$(cd "$sb" && python3 -c '
import sys
try:
    import cand
    assert cand.clamp(5, 0, 10) == 5     # in range
    assert cand.clamp(-3, 0, 10) == 0    # below → lo
    assert cand.clamp(99, 0, 10) == 10   # above → hi
    assert cand.clamp(0, 0, 10) == 0     # boundary lo
    assert cand.clamp(10, 0, 10) == 10   # boundary hi
except AssertionError:
    print("FAIL:clamp"); sys.exit(0)
except Exception as e:
    print("FAIL:EXC-" + type(e).__name__); sys.exit(0)
print("PASS")
' 2>/dev/null)" || true
case "$r" in PASS|FAIL:*) echo "$r";; *) echo "FAIL:DRIVER-ERROR";; esac
