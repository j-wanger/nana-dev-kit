#!/usr/bin/env bash
# Controls-first tests for the project-state dashboard generator (scripts/generate-dashboard.py).
# Phase 106. HEU-012: assert the rendered HTML CONTAINS live FIXTURE content (not file-existence),
# malformed/missing-field briefs FAIL LOUD, a missing source FILE degrades to a marker (exit 0),
# a present-but-restructured source shows a DISTINCT marker (the #1 dead-instrument guard), the
# generator never mutates the source (render-only), and the static output has NO form.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GEN="$REPO_ROOT/scripts/generate-dashboard.py"
FIX="$SCRIPT_DIR/fixtures"
STATE="$FIX/dashboard-current-state.md"
BRIEF="$FIX/dashboard-brief.valid.json"
OUT="$(mktemp -d)/dashboard.html"

echo "=== Project-State Dashboard Generator Tests ==="

# ---- G1: valid state + brief renders, exit 0 ----
test_start "generator: valid state+brief exits 0"
set +e; python3 "$GEN" --state "$STATE" --brief "$BRIEF" --output "$OUT" >/dev/null 2>&1; rc=$?; set -e
assert_eq 0 "$rc" "valid inputs should exit 0"

# ---- G3: status pane CONTAINS a live fixture section ----
test_start "render: status pane contains live fixture content"
assert_contains "$OUT" "UNIQUE-STATUS-G3"

# ---- G6: direction pane CONTAINS recommendation + every option + every assumption ----
test_start "render: direction pane contains recommendation + options + assumptions"
if grep -q "Pick Option B for the test" "$OUT" \
   && grep -q "Option A bare" "$OUT" && grep -q "Option B recommended" "$OUT" && grep -q "Option C alternative" "$OUT" \
   && grep -q "first load-bearing fixture assumption" "$OUT" \
   && grep -q "second fixture assumption" "$OUT" \
   && grep -q "third fixture assumption" "$OUT"; then test_pass; else test_fail "direction pane missing content"; fi

# ---- G7: malformed-JSON brief FAILS LOUD ----
test_start "control: malformed-JSON brief fails loud"
BAD="$(mktemp)"; printf '{ not json' > "$BAD"
set +e; err=$(python3 "$GEN" --state "$STATE" --brief "$BAD" --output "$OUT" 2>&1 >/dev/null); rc=$?; set -e
rm -f "$BAD"
if [ "$rc" -ne 0 ] && [ -n "$err" ]; then test_pass; else test_fail "malformed brief should fail loud (rc=$rc)"; fi

# ---- G8: missing-required-field brief (no phase) FAILS LOUD ----
test_start "control: missing-phase brief fails loud"
NOPHASE="$(mktemp)"
python3 -c "import json; b=json.load(open('$BRIEF')); b.pop('phase'); json.dump(b,open('$NOPHASE','w'))"
set +e; err=$(python3 "$GEN" --state "$STATE" --brief "$NOPHASE" --output "$OUT" 2>&1 >/dev/null); rc=$?; set -e
rm -f "$NOPHASE"
if [ "$rc" -ne 0 ] && [ -n "$err" ]; then test_pass; else test_fail "missing-phase brief should fail loud (rc=$rc)"; fi

# ---- G8b: nonce-less brief still renders, exit 0 (backward-compat) ----
test_start "render: nonce-less brief renders (exit 0)"
set +e; python3 "$GEN" --state "$STATE" --brief "$FIX/dashboard-brief.nononce.json" --output "$OUT" >/dev/null 2>&1; rc=$?; set -e
assert_eq 0 "$rc" "nonce-less brief should render exit 0"

# ---- G9: missing source FILE degrades to (section absent), exit 0 ----
test_start "render: missing state file degrades to '(section absent)', exit 0"
set +e; python3 "$GEN" --state "$FIX/does-not-exist.md" --brief "$BRIEF" --output "$OUT" >/dev/null 2>&1; rc=$?; set -e
assert_eq 0 "$rc" "missing state should not crash"
assert_contains "$OUT" "section absent"

# ---- G11: present-but-restructured source → DISTINCT marker (not silent absent) ----
test_start "render: restructured state shows a distinct 'unrecognized' marker (not silent absent)"
python3 "$GEN" --state "$FIX/dashboard-current-state-restructured.md" --brief "$BRIEF" --output "$OUT" >/dev/null 2>&1
if grep -qi "unrecognized" "$OUT"; then test_pass; else test_fail "restructured non-empty state must show a distinct marker, not a silent placeholder"; fi

# ---- G10: generating does NOT mutate the source (render-only) ----
test_start "render-only: source file unchanged after render (sha)"
before=$(shasum "$STATE" | awk '{print $1}')
python3 "$GEN" --state "$STATE" --brief "$BRIEF" --output "$OUT" >/dev/null 2>&1
after=$(shasum "$STATE" | awk '{print $1}')
assert_eq "$before" "$after" "the dashboard must not write the living docs"

# ---- G12: static output (interactive=False) has NO form ----
test_start "static: make-dashboard output has NO <form> (render-only static page)"
python3 "$GEN" --state "$STATE" --brief "$BRIEF" --output "$OUT" >/dev/null 2>&1
if grep -qi "<form" "$OUT"; then test_fail "static page must not contain a form"; else test_pass; fi

test_summary "dashboard"
