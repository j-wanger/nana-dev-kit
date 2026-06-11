#!/usr/bin/env bash
# check-protocol.sh — Phase 87 T2 RED gate. Asserts the execution-protocol addendum
# pins every execution-level item the frozen Stage-2 parameters left open.
# Structural: required H2 sections present. Referential: load-bearing tokens present
# inside the file (closed-policy clauses, VOID/DNF semantics, ruling keywords).
# Exit 0 iff all assertions hold.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
F="$DIR/execution-protocol.md"
fail=0

say() { echo "$1: $2"; [ "$1" = "FAIL" ] && fail=1; }

[ -f "$F" ] || { echo "FAIL: execution-protocol.md missing"; exit 1; }

# --- Tier 0: required sections -------------------------------------------------
SECTIONS=(
  "## Maintainer rulings"
  "## Arm ordering"
  "## Budget cap"
  "## Gate-response policy"
  "## Cross-arm isolation"
  "## Positive control"
  "## Leak canary"
  "## Context surfaces"
  "## Blinded defect review"
  "## Amendment rule"
  "## Tie handling"
  "## Claim-ceiling patterns"
  "## Target branch IDs"
  "## Provisioning manifest"
  "## Transcript mapping and cost capture"
)
for s in "${SECTIONS[@]}"; do
  if grep -qF "$s" "$F"; then say PASS "section present: $s"; else say FAIL "section MISSING: $s"; fi
done

# --- Tier 1: load-bearing content tokens ----------------------------------------
declare -a CHECKS=(
  "independent clones|Maintainer rulings pin the clones ruling"
  "phase-exit gate|Maintainer rulings pin the ship-runner referent"
  "canned|Maintainer rulings pin canned orchestrator-mediated inputs"
  "zero-gate|gate policy pre-declares zero-gate-firing as valid"
  "DID-NOT-FINISH|DNF mapping pinned"
  "stop rule|budget cap has a deterministic stop rule"
  "post-stop|canary placement pinned post-stop"
  "VOID|post-unblinding amendment / voiding semantics present"
  "undecidable|all-tie outcome pre-declared undecidable"
  "parity-shared|context-surface classification vocabulary present"
  "voiding|context-surface voiding class present"
  "force-add|provisioning manifest covers gitignored/untracked surfaces"
  "NOT-EXTRACTABLE|cost capture pins the A3 fallback semantics"
  "exactly once|positive-control detector asserts the single-registration invariant"
  "DRQ-1|leak canary question pinned"
)
for c in "${CHECKS[@]}"; do
  tok="${c%%|*}"; desc="${c#*|}"
  if grep -qi -- "$tok" "$F"; then say PASS "$desc"; else say FAIL "$desc (token '$tok' absent)"; fi
done

# Target branch IDs must look like file:line references.
if grep -qE '[a-z_/]+\.py:[0-9]+' "$F"; then
  say PASS "target branch IDs are concrete file:line references"
else
  say FAIL "target branch IDs missing concrete file:line references"
fi

if [ "$fail" -eq 0 ]; then echo "CHECK-PROTOCOL: PASS"; else echo "CHECK-PROTOCOL: FAIL"; fi
exit "$fail"
