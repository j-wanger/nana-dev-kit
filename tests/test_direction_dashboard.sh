#!/usr/bin/env bash
# Functional tests for the direction dashboard generator (scripts/generate-direction.py).
# Phase 99 — Direction Dashboard. Controls-first per HEU-012: assert the rendered HTML
# CONTAINS the brief content (NOT mere file-existence), and (T2) a seeded malformed brief
# MUST make the generator fail loud — clean-on-seed = dead instrument.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GEN="$REPO_ROOT/scripts/generate-direction.py"
VALID="$SCRIPT_DIR/fixtures/direction-brief.valid.json"

echo "=== Direction Dashboard Generator Tests ==="

OUT="$(mktemp -d)/direction.html"

# ---- T1: valid brief renders, and the HTML CONTAINS the brief content ----
test_start "generator: valid brief exits 0"
set +e
python3 "$GEN" --brief "$VALID" --output "$OUT" >/dev/null 2>&1
rc=$?
set -e
assert_eq 0 "$rc" "generator should exit 0 on a valid brief"

test_start "render: output file written"
assert_file_exists "$OUT"

test_start "render: contains recommendation text"
assert_contains "$OUT" "Render-only dashboard is the recommended first slice."

test_start "render: contains every option label"
if grep -q "Dashboard-first" "$OUT" && grep -q "Thin end-to-end slice" "$OUT" && grep -q "Fidelity-spine-first" "$OUT"; then
  test_pass
else
  test_fail "an option label is missing from the rendered HTML"
fi

test_start "render: contains every assumption text"
if grep -q "Render-only relieves the throughput pain." "$OUT" \
   && grep -q "A one-shot generator suffices over a live server." "$OUT" \
   && grep -q "The direction gate is the right first surface to render." "$OUT"; then
  test_pass
else
  test_fail "an assumption text is missing from the rendered HTML"
fi

test_start "render: contains assumption positions"
if grep -q "accept" "$OUT" && grep -qE "don.{0,6}t-know" "$OUT"; then
  test_pass
else
  test_fail "an assumption position is missing from the rendered HTML"
fi

# ---- T2: controls-first — a malformed / missing-field brief MUST fail loud ----
# clean-on-seed (renders a page on garbage input) = dead instrument.
MALFORMED="$SCRIPT_DIR/fixtures/direction-brief.malformed.json"
MISSING="$SCRIPT_DIR/fixtures/direction-brief.missingfield.json"

test_start "control: malformed JSON brief fails loud (non-zero + stderr)"
set +e
err=$(python3 "$GEN" --brief "$MALFORMED" --output "$OUT" 2>&1 >/dev/null)
rc=$?
set -e
if [ "$rc" -ne 0 ] && [ -n "$err" ]; then test_pass; else test_fail "expected non-zero exit + stderr (got rc=$rc)"; fi

test_start "control: missing-required-field brief fails loud (non-zero + stderr)"
set +e
err=$(python3 "$GEN" --brief "$MISSING" --output "$OUT" 2>&1 >/dev/null)
rc=$?
set -e
if [ "$rc" -ne 0 ] && [ -n "$err" ]; then test_pass; else test_fail "expected non-zero exit + stderr (got rc=$rc)"; fi

# ---- T2: the recommended option is visibly marked ----
test_start "render: recommended option is visibly marked"
python3 "$GEN" --brief "$VALID" --output "$OUT" >/dev/null 2>&1
assert_contains "$OUT" "Recommended"

test_summary "direction-dashboard"
