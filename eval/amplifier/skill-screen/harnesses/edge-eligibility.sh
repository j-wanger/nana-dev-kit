#!/usr/bin/env bash
# edge-eligibility.sh — score an OFF re-derivation A' of the edge-screener eligibility candidate.
# Assembles a throwaway package { frozen real membership.py + A' as eligibility.py } and runs the
# guarded driver (spec-implied assertions). Prints exactly PASS | FAIL:<assertion-id>. NO LLM.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIX="$DIR/../fixtures/edge-eligibility"
out="${1:-}"
[ -f "$out" ] || { echo "FAIL:NO-OUTPUT"; exit 0; }
command -v python3 >/dev/null 2>&1 || { echo "FAIL:NO-PYTHON"; exit 0; }
sb="$(mktemp -d)"; trap 'rm -rf "$sb"' EXIT
pkg="$sb/edge_screener"
mkdir -p "$pkg/universe" "$pkg/survivorship"
: > "$pkg/__init__.py"; : > "$pkg/universe/__init__.py"; : > "$pkg/survivorship/__init__.py"
cp "$FIX/membership.py" "$pkg/universe/membership.py"   # frozen dependency (given to OFF in R_A)
cp "$out"               "$pkg/survivorship/eligibility.py"   # A' = the OFF re-derivation
cp "$FIX/driver.py"     "$sb/driver.py"
r="$(cd "$sb" && PYTHONPATH="$sb" python3 driver.py 2>/dev/null)" || true
case "$r" in PASS|FAIL:*) echo "$r";; *) echo "FAIL:DRIVER-ERROR";; esac
