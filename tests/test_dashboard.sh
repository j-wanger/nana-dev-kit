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

# ---- G13: per-option reasoning + consequences render CO-LOCATED inside that option's card (Phase 107) ----
# The comparability floor: not mere presence somewhere in the HTML, but each option's reasoning AND
# consequences inside ITS OWN card, with no other option's reasoning leaking in (true option-scoping).
test_start "render: each option's reasoning+consequences are option-scoped (co-located in its card)"
COCKPIT="$FIX/dashboard-brief.cockpit.json"
python3 "$GEN" --state "$STATE" --brief "$COCKPIT" --output "$OUT" >/dev/null 2>&1
set +e
python3 - "$OUT" "$COCKPIT" <<'PY'
import sys, json, re
html = open(sys.argv[1]).read()
brief = json.load(open(sys.argv[2]))
# Each card is the slice from one '<div class="option' to the next — nested divs (opt-head/desc/
# reasoning/consequences) carry no 'class="option' so the split isolates whole cards.
cards = re.split(r'<div class="option', html)[1:]
ok = True
for o in brief["options"]:
    card = next((c for c in cards if o["label"] in c), None)
    if card is None:
        print(f"FAIL: no card for {o['label']}"); ok = False; continue
    if o.get("reasoning") and o["reasoning"] not in card:
        print(f"FAIL: reasoning not co-located in {o['label']} card"); ok = False
    if o.get("consequences") and o["consequences"] not in card:
        print(f"FAIL: consequences not co-located in {o['label']} card"); ok = False
    for other in brief["options"]:
        if other["label"] != o["label"] and other.get("reasoning") and other["reasoning"] in card:
            print(f"FAIL: {other['label']} reasoning leaked into {o['label']} card"); ok = False
sys.exit(0 if ok else 1)
PY
rc=$?; set -e
if [ "$rc" -eq 0 ]; then test_pass; else test_fail "reasoning/consequences not option-scoped"; fi

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

# ---- G14: cockpit has THREE tabs (Status | Decide | Workflow) ----
test_start "cockpit: Status/Decide/Workflow tabs present"
python3 "$GEN" --state "$STATE" --brief "$FIX/dashboard-brief.cockpit.json" --output "$OUT" >/dev/null 2>&1
if grep -q 'data-tab="status"' "$OUT" && grep -q 'data-tab="decide"' "$OUT" && grep -q 'data-tab="workflow"' "$OUT"; then test_pass; else test_fail "missing one of the three tabs"; fi

# ---- G15: interactive render — a FRESH brief shows a form; a STALE (phase-mismatch) brief shows a banner and NO form ----
test_start "served: fresh brief => form; stale brief => banner + NO form (don't silently decide stale)"
set +e
python3 - "$GEN" "$STATE" "$FIX/dashboard-brief.cockpit.json" "$FIX/dashboard-brief.stale.json" <<'PY'
import sys, importlib.util as u, json
gen, state, cockpit, stale = sys.argv[1:5]
s = u.spec_from_file_location("gd", gen); m = u.module_from_spec(s); s.loader.exec_module(m)
ap = json.load(open(cockpit))["phase"]   # the cockpit fixture DEFINES "current" — robust to live-phase drift
fresh = m.render_dashboard(m.build_panes(state, cockpit, active_phase=ap), interactive=True)
stl   = m.render_dashboard(m.build_panes(state, stale,   active_phase=ap), interactive=True)
ok = True
if "<form" not in fresh: print("FAIL: fresh interactive render must contain a form"); ok = False
if "<form" in stl:       print("FAIL: stale brief must NOT present a submittable form"); ok = False
if "stale" not in stl.lower(): print("FAIL: stale brief must surface a loud staleness banner"); ok = False
sys.exit(0 if ok else 1)
PY
rc=$?; set -e
if [ "$rc" -eq 0 ]; then test_pass; else test_fail "stale-brief guard / form gating wrong"; fi

# ---- G16: Workflow tab re-rendered NATIVELY (Phase 107 T3) — >=2 section markers + native container, NOT an iframe ----
test_start "workflow tab: native re-render (>=2 section markers, native container, no iframe)"
python3 "$GEN" --state "$STATE" --brief "$FIX/dashboard-brief.cockpit.json" --output "$OUT" >/dev/null 2>&1
nmark=$(grep -oE 'class="sec-head">(Harness|Hooks|Tests|CI &amp; pre-commit)<' "$OUT" | sort -u | wc -l | tr -d ' ')
if grep -q 'workflow-native' "$OUT" && [ "$nmark" -ge 2 ] && ! grep -qi '<iframe' "$OUT"; then
  test_pass
else
  test_fail "workflow tab not natively re-rendered (native container + >=2 distinct section markers, no iframe); got $nmark markers"
fi

test_summary "dashboard"
