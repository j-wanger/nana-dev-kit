#!/usr/bin/env bash
# Tests for scripts/check-assumption-ledger.sh — the deterministic NO-LLM assumption-ledger validator
# (Phase 81). FIRING assertions, not presence: each fixture is piped through a check MODE and the exit
# code is asserted (a malformed ledger must FLAG, a conformant one must PASS). Distinct from the script's
# own --selftest (which self-verifies on internal fixtures); both are required by the spec.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHECK="$PROJECT_ROOT/scripts/check-assumption-ledger.sh"

source "$SCRIPT_DIR/helpers.sh"

echo "=== test_assumption_ledger.sh ==="

TDIR=$(mktemp -d)
trap 'rm -rf "$TDIR"' EXIT

# --- Fixtures ---------------------------------------------------------------

# Conformant: 2 phases, all fields, revisit-status filled. Last block is at EOF (EOF-boundary fixture).
cat > "$TDIR/good.md" <<'EOF'
# Assumption Ledger

## Phase 80 — Screen
- date: 2026-06-09
- all_accept: false
- A1 | cost: high | position: accept | revisit-status: held | "Forced verdicts engage cognition"
- A2 | cost: high | position: reject | revisit-status: held | "The agent-chosen set can be trusted"

## Phase 82 — Next
- date: 2026-06-10
- all_accept: true
- A1 | cost: medium | position: accept | revisit-status: held | "The store persists at the assumed path"
EOF

# Blank revisit-status on one assumption (mid-phase / unrevisited).
cat > "$TDIR/blank-revisit.md" <<'EOF'
# Assumption Ledger

## Phase 82 — Next
- date: 2026-06-10
- all_accept: false
- A1 | cost: high | position: accept | revisit-status: held | "The store persists at the assumed path"
- A2 | cost: high | position: reject | revisit-status: | "The hook is firing"
EOF

# No positions taken: a phase block with zero assumption lines (gate did not fire).
cat > "$TDIR/no-positions.md" <<'EOF'
# Assumption Ledger

## Phase 82 — Next
- date: 2026-06-10
- all_accept: false
EOF

# Schema violation: an assumption line missing the position field.
cat > "$TDIR/missing-field.md" <<'EOF'
# Assumption Ledger

## Phase 82 — Next
- date: 2026-06-10
- all_accept: false
- A1 | cost: high | revisit-status: held | "The store persists at the assumed path"
EOF

# Append-only baseline (2 phases) + a truncated current (Phase 80 block removed).
cat > "$TDIR/base.md" <<'EOF'
# Assumption Ledger

## Phase 80 — Screen
- date: 2026-06-09
- all_accept: false
- A1 | cost: high | position: accept | revisit-status: held | "Forced verdicts engage cognition"

## Phase 82 — Next
- date: 2026-06-10
- all_accept: true
- A1 | cost: medium | position: accept | revisit-status: held | "The store persists"
EOF
cat > "$TDIR/truncated.md" <<'EOF'
# Assumption Ledger

## Phase 82 — Next
- date: 2026-06-10
- all_accept: true
- A1 | cost: medium | position: accept | revisit-status: held | "The store persists"
EOF

# --- Behavioral assertions (the firing test) -------------------------------

test_start "check script exists + executable"
assert_exit_code 0 test -x "$CHECK"

test_start "conformant ledger passes --schema"
assert_exit_code 0 bash "$CHECK" --schema "$TDIR/good.md"

test_start "conformant ledger passes --revisit (no blanks)"
assert_exit_code 0 bash "$CHECK" --revisit "$TDIR/good.md"

test_start "conformant ledger: --gate finds positions for Phase 82"
assert_exit_code 0 bash "$CHECK" --gate "$TDIR/good.md" 82

test_start "EOF-boundary: last block at end of file validates (Phase 82 present)"
assert_exit_code 0 bash "$CHECK" --gate "$TDIR/good.md" 82

test_start "blank revisit-status is FLAGGED by --revisit"
assert_exit_code 1 bash "$CHECK" --revisit "$TDIR/blank-revisit.md"

test_start "blank revisit-status for the closing phase is FLAGGED (debrief enforcement)"
assert_exit_code 1 bash "$CHECK" --revisit "$TDIR/blank-revisit.md" 82

test_start "filled revisit-status for the closing phase is SILENT (debrief differential)"
assert_exit_code 0 bash "$CHECK" --revisit "$TDIR/good.md" 82

test_start "no-positions phase is FLAGGED by --gate"
assert_exit_code 1 bash "$CHECK" --gate "$TDIR/no-positions.md" 82

test_start "no-positions phase is FLAGGED by --schema (no assumption lines)"
assert_exit_code 1 bash "$CHECK" --schema "$TDIR/no-positions.md"

test_start "schema-missing-field (no position:) is FLAGGED by --schema"
assert_exit_code 1 bash "$CHECK" --schema "$TDIR/missing-field.md"

test_start "append-only: removing a prior block is FLAGGED"
assert_exit_code 1 bash "$CHECK" --append-only "$TDIR/truncated.md" "$TDIR/base.md"

test_start "append-only: intact ledger passes"
assert_exit_code 0 bash "$CHECK" --append-only "$TDIR/good.md" "$TDIR/base.md"

test_start "append-only: dropping a row WITHIN a retained block is FLAGGED"
# base.md Phase 80 has A1 only; good.md (as baseline) has A1+A2 → base lost a row vs the baseline.
assert_exit_code 1 bash "$CHECK" --append-only "$TDIR/base.md" "$TDIR/good.md"

test_start "phase-number boundary: --gate 8 does not match Phase 80/82"
assert_exit_code 1 bash "$CHECK" --gate "$TDIR/good.md" 8

# Regression: the committed seed ledger is itself schema-valid.
test_start "committed .dev-wiki/assumption-ledger.md is schema-valid"
assert_exit_code 0 bash "$CHECK" --schema "$PROJECT_ROOT/.dev-wiki/assumption-ledger.md"

# The script's own internal self-check.
test_start "check --selftest passes"
assert_exit_code 0 bash "$CHECK" --selftest

# NO LLM in the scoring path (comment lines + the NO-LLM self-reference excluded).
test_start "no LLM invocation in the check (deterministic)"
if [ -z "$(grep -niE 'LLM|claude|model|judge' "$CHECK" 2>/dev/null | grep -vE '^[0-9]+:[[:space:]]*#' | grep -viE 'no[ -]?llm')" ]; then
  test_pass
else
  test_fail "LLM reference outside comments"
fi

# --- Single-schema-source consistency (no split-brain) -----------------------
# The canonical ledger schema lives in ONE place: the `## Ledger schema` block in this check script.
# The dev-plan gate companion and the dev-debrief revisit step reference it BY PATH; neither inlines a
# divergent copy. (Coverage note: scripts/check-assumption-ledger.sh and .dev-wiki/assumption-ledger.md are
# OUTSIDE check-install-drift's set — it compares skills/, global hooks, rules/ only — so their
# firing-coverage rides on THIS test + the Makefile wiring, not the drift comparator.)
SKILLS="$PROJECT_ROOT/templates/.claude/skills"

test_start "schema source: the check script owns the canonical '## Ledger schema' block"
assert_contains "$CHECK" "## Ledger schema"

test_start "schema source: dev-plan gate companion references the check script by path"
assert_contains "$SKILLS/dev-plan/assumption-gate.md" "check-assumption-ledger"

test_start "schema source: dev-debrief revisit step references the check script by path"
if grep -rq "check-assumption-ledger" "$SKILLS/dev-debrief/"; then test_pass; else test_fail "dev-debrief does not reference the check script"; fi

test_start "schema source: no divergent '## Ledger schema' HEADING in any skill companion"
# Line-start heading = a divergent schema DEFINITION; a mid-line backtick reference to the canonical
# block (as the gate companion legitimately makes) is fine and must NOT trip this.
SCHEMA_HITS=$( { grep -rlE '^#{2,4} Ledger schema' "$SKILLS" 2>/dev/null || true; } | wc -l | tr -d ' ')
assert_eq 0 "$SCHEMA_HITS" "a divergent '## Ledger schema' heading exists in a skill companion"

test_summary "test_assumption_ledger"
