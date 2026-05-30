#!/usr/bin/env bash
# Firing test for the kit-uninitialized /nana-init nudge in cognitive-readiness.sh.
# Discipline: verify FIRING, not presence. Source the hook and call
# check_cognitive_readiness in a temp CWD with and without .dev-wiki/, and assert
# the nudge fires ONLY when the project is uninitialized (both directions).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers.sh"

HOOK="$PROJECT_ROOT/templates/.claude/hooks/session-start.d/cognitive-readiness.sh"
# fires: cognitive-readiness.sh   # (coverage gate — see test_hook_firing_coverage.sh)

echo "=== test_cognitive_readiness.sh ==="

# Syntax
test_start "cognitive-readiness.sh passes syntax check"
assert_exit_code 0 bash -n "$HOOK"

# Load the function under test
# shellcheck source=/dev/null
source "$HOOK"

# --- Uninitialized: no .dev-wiki/ -> nudge fires ---
UNINIT="$(mktemp -d)"
OUT_UNINIT="$(cd "$UNINIT" && check_cognitive_readiness 2>&1 || true)"
rm -rf "$UNINIT"
UNINIT_F="$(mktemp)"
printf '%s\n' "$OUT_UNINIT" > "$UNINIT_F"
test_start "nudge fires when .dev-wiki/ is missing"
assert_contains "$UNINIT_F" 'nana-init'

# --- Initialized: .dev-wiki/ present -> nudge silent (no false positive) ---
INIT="$(mktemp -d)"
mkdir -p "$INIT/.dev-wiki"
OUT_INIT="$(cd "$INIT" && check_cognitive_readiness 2>&1 || true)"
rm -rf "$INIT"
INIT_F="$(mktemp)"
printf '%s\n' "$OUT_INIT" > "$INIT_F"
test_start "nudge is silent when .dev-wiki/ is present"
if grep -q 'nana-init' "$INIT_F"; then
  test_fail "nudge fired in an initialized project (false positive)"
else
  test_pass
fi

rm -f "$UNINIT_F" "$INIT_F"

test_summary "test_cognitive_readiness.sh"
