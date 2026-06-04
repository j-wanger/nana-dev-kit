#!/usr/bin/env bash
# selftest-toy.sh — planted harness used ONLY by check.sh --selftest to prove the scorer flips both ways.
# Toy spec-implied assertion `adds`: A' must define a bash function f(a,b) returning a+b; f 2 3 → 5.
# NO LLM. A' is run in an isolated subshell; any error / wrong result → FAIL:adds (fail closed).
set -euo pipefail
out="$1"
result="$(bash -c 'source "$1" >/dev/null 2>&1; f 2 3' _ "$out" 2>/dev/null)" || { echo "FAIL:adds"; exit 0; }
if [ "$result" = "5" ]; then echo "PASS"; else echo "FAIL:adds"; fi
