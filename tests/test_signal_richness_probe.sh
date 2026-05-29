#!/usr/bin/env bash
# Tests for scripts/signal-richness-probe.sh (Phase 66 T1).
# The probe is the committed, re-checkable gate for "is the enforcement-firing scorer buildable yet?".
# It is READ-ONLY over enforcement.log: classify records, compute the signal predicate over
# schema_version-bearing (new-format) records ONLY, and emit one of SCOREABLE / NOT-SCOREABLE /
# NO-DATA / CORRUPT. These tests use FIXTURES only — they never couple to the mutable live log
# (the "live log => NOT-SCOREABLE" check is a one-time phase-exit gate, not a permanent assertion).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROBE="$REPO_ROOT/scripts/signal-richness-probe.sh"

# All fixture logs live under one temp dir, removed wholesale on exit (mklog runs in $(...)
# subshells, so a parent-scoped file array would never populate — a dir sidesteps that and the
# trap returns 0 cleanly, which `make test` requires).
TEST_TMP=$(mktemp -d)
cleanup() { rm -rf "$TEST_TMP"; }
trap cleanup EXIT

# Write each argument as one line of a fresh temp logfile; echo its path.
mklog() {
  local f; f=$(mktemp "$TEST_TMP/log.XXXXXX")
  if [ "$#" -gt 0 ]; then printf '%s\n' "$@" > "$f"; else : > "$f"; fi
  echo "$f"
}
# Capture the full probe output (drains it completely — avoids a `| grep -q` closing the pipe early
# and SIGPIPE-ing the probe, which surfaces as exit 141 under this script's `set -o pipefail`).
run() { bash "$PROBE" "$1" 2>&1; }
has() { echo "$2" | grep -q "$1"; }      # has <pattern> <captured-output>

# Sample records (controlled-vocab, like the real substrate).
NEW_SPEC_BLOCK='{"schema_version":1,"ts":"2026-06-01T10:00:00Z","hook":"enforce-spec","action":"block","reason":"no-approved-spec","phase":"70"}'
NEW_LOOP_BLOCK='{"schema_version":1,"ts":"2026-06-01T10:01:00Z","hook":"detect-loop","action":"block","reason":"loop-detected","phase":"70"}'
NEW_SCOPE_ADV='{"schema_version":1,"ts":"2026-06-01T10:02:00Z","hook":"dev-wiki-scope-check","action":"advisory","reason":"out-of-scope","phase":"70"}'
NEW_SCOPE_SKIP='{"schema_version":1,"ts":"2026-06-01T10:03:00Z","hook":"dev-wiki-scope-check","action":"skipped","reason":"no-open-tasks","phase":"70"}'
LEGACY_BLOCK='{"ts":"2026-05-27T15:34:54Z","hook":"enforce-loop","action":"block","reason":"deliverable-missing"}'
LEGACY_ALLOW='{"ts":"2026-05-27T15:30:00Z","hook":"enforce-loop","action":"allow","reason":"all-checks-passed"}'
DEBRIEF='{"event":"debrief","phase":"43","status":"completed","tasks_done":5,"tasks_total":5}'

echo "=== Phase 66 Signal-Richness Probe Tests ==="

# 1. Absent log → NO-DATA (distinct from insufficient).
test_start "absent log → NO-DATA"
OUT=$(run /nonexistent/enforcement.log)
if has 'VERDICT: NO-DATA' "$OUT"; then test_pass; else test_fail "expected NO-DATA for missing file"; fi

# 2. Empty log → NO-DATA.
test_start "empty log → NO-DATA"
L=$(mklog); OUT=$(run "$L")
if has 'VERDICT: NO-DATA' "$OUT"; then test_pass; else test_fail "expected NO-DATA for empty file"; fi

# 3. All-legacy (incl legacy blocks) → NOT-SCOREABLE: legacy excluded from the numerator.
test_start "all-legacy (with legacy blocks) → NOT-SCOREABLE (legacy excluded)"
L=$(mklog "$LEGACY_ALLOW" "$LEGACY_BLOCK" "$LEGACY_BLOCK")
OUT=$(run "$L")
if echo "$OUT" | grep -q 'VERDICT: NOT-SCOREABLE' && echo "$OUT" | grep -q 'new=0'; then test_pass; else test_fail "legacy blocks must not count as signal; got: $OUT"; fi

# 4. ≥2 distinct new-format hooks AND ≥1 block → SCOREABLE.
test_start "2 distinct new-format hooks + block → SCOREABLE"
L=$(mklog "$NEW_SPEC_BLOCK" "$NEW_LOOP_BLOCK"); OUT=$(run "$L")
if has 'VERDICT: SCOREABLE' "$OUT"; then test_pass; else test_fail "expected SCOREABLE; got: $OUT"; fi

# 5. >50% unparseable → CORRUPT.
test_start ">50% unparseable lines → CORRUPT"
L=$(mklog "not json at all" "}{ broken" "garbage line" "$NEW_SPEC_BLOCK"); OUT=$(run "$L")
if has 'VERDICT: CORRUPT' "$OUT"; then test_pass; else test_fail "expected CORRUPT (3/4 malformed); got: $OUT"; fi

# 6. ≤50% unparseable → verdict from the valid records, NOT CORRUPT.
test_start "just-below-50% unparseable → verdict from valid records (not CORRUPT)"
L=$(mklog "garbage" "$NEW_SPEC_BLOCK" "$NEW_LOOP_BLOCK" "$NEW_SCOPE_ADV")
OUT=$(run "$L")
if echo "$OUT" | grep -q 'VERDICT: SCOREABLE' && ! echo "$OUT" | grep -q 'VERDICT: CORRUPT'; then test_pass; else test_fail "1/4 malformed must not flip to CORRUPT; got: $OUT"; fi

# 7. Duplicate (byte-identical) tuples → deduped, dup rate reported, verdict NOT inflated.
test_start "duplicate tuples → deduped + reported, not inflated"
L=$(mklog "$NEW_SCOPE_ADV" "$NEW_SCOPE_ADV")
OUT=$(run "$L")
if echo "$OUT" | grep -q 'new=2' && echo "$OUT" | grep -q 'new_deduped=1' && echo "$OUT" | grep -q 'duplicates=1' && echo "$OUT" | grep -q 'VERDICT: NOT-SCOREABLE'; then test_pass; else test_fail "dup tuples must dedup (one hook, no block); got: $OUT"; fi

# 8. Same ts + hook + action but DIFFERENT reason → NOT collapsed (dedup key includes reason).
test_start "same-ts/hook/action, distinct reason → NOT collapsed"
SAME_A='{"schema_version":1,"ts":"2026-06-01T11:00:00Z","hook":"dev-wiki-scope-check","action":"advisory","reason":"out-of-scope","phase":"70"}'
SAME_B='{"schema_version":1,"ts":"2026-06-01T11:00:00Z","hook":"dev-wiki-scope-check","action":"advisory","reason":"no-open-tasks","phase":"70"}'
L=$(mklog "$SAME_A" "$SAME_B")
OUT=$(run "$L")
if echo "$OUT" | grep -q 'new_deduped=2' && echo "$OUT" | grep -q 'duplicates=0'; then test_pass; else test_fail "distinct reasons must survive dedup; got: $OUT"; fi

# 9. Real-log-shape regression pin (replicates today: one hook, advisory/skipped only, + legacy) → NOT-SCOREABLE.
test_start "real-log-shape fixture (1 hook, 0 blocks, + legacy) → NOT-SCOREABLE"
L=$(mklog "$LEGACY_ALLOW" "$LEGACY_BLOCK" "$NEW_SCOPE_ADV" "$NEW_SCOPE_SKIP" "$DEBRIEF")
OUT=$(run "$L")
if echo "$OUT" | grep -q 'VERDICT: NOT-SCOREABLE' && echo "$OUT" | grep -q 'blocks=0'; then test_pass; else test_fail "today's shape must be NOT-SCOREABLE; got: $OUT"; fi

# 10. Predicate boundary: 2 hooks but ZERO blocks → NOT-SCOREABLE (block is required).
test_start "2 hooks, 0 blocks → NOT-SCOREABLE (block required)"
L=$(mklog "$NEW_SCOPE_ADV" '{"schema_version":1,"ts":"2026-06-01T10:09:00Z","hook":"check-tests-were-run","action":"advisory","reason":"tests-not-run","phase":"70"}'); OUT=$(run "$L")
if has 'VERDICT: NOT-SCOREABLE' "$OUT"; then test_pass; else test_fail "2 hooks but no block must be NOT-SCOREABLE; got: $OUT"; fi

# 11. Predicate boundary: 1 hook WITH a block → NOT-SCOREABLE (≥2 distinct hooks required).
test_start "1 hook with a block → NOT-SCOREABLE (>=2 hooks required)"
L=$(mklog "$NEW_SPEC_BLOCK"); OUT=$(run "$L")
if has 'VERDICT: NOT-SCOREABLE' "$OUT"; then test_pass; else test_fail "single hook must be NOT-SCOREABLE even with a block; got: $OUT"; fi

# 12. Debrief-completion records are classified, never counted as signal.
test_start "debrief-completion record classified, not counted as new-format"
L=$(mklog "$DEBRIEF" "$DEBRIEF")
OUT=$(run "$L")
if echo "$OUT" | grep -q 'new=0' && echo "$OUT" | grep -q 'debrief=2' && echo "$OUT" | grep -q 'VERDICT: NOT-SCOREABLE'; then test_pass; else test_fail "debrief records must classify as debrief, not new-format; got: $OUT"; fi

# 13. Probe is READ-ONLY: it must not modify the log it reads.
test_start "probe does not modify the log (read-only)"
L=$(mklog "$NEW_SPEC_BLOCK" "$LEGACY_ALLOW")
BEFORE=$(cksum < "$L")
run "$L" >/dev/null
AFTER=$(cksum < "$L")
assert_eq "$BEFORE" "$AFTER" "probe mutated the log"

# 14. Valid-JSON-but-non-object lines (bare scalar / array / null) → bucketed malformed, NEVER crash.
test_start "non-object JSON lines (scalar/array/null) → malformed, no crash"
L=$(mklog '42' '[1,2,3]' 'null' "$NEW_SPEC_BLOCK"); EC=0; OUT=$(run "$L") || EC=$?
if [ "$EC" = "0" ] && has 'VERDICT:' "$OUT" && has 'new=1' "$OUT" && has 'malformed=3' "$OUT"; then test_pass; else test_fail "non-object lines crashed or miscounted (ec=$EC): $OUT"; fi

test_summary "Signal-Richness Probe Tests"
