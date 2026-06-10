#!/usr/bin/env bash
# Phase 84 — real-event fixture provenance + diagnosis evidence pairing (anti-fixture-circularity).
# The Phase-82 defect class survived BECAUSE hand-written fixtures encoded the author's belief about
# the event shape: hook and fixture agreed while both were wrong against the runtime (the existing
# post-commit/detect-loop tests pass today while the hooks are dormant against real events).
# Contract enforced here:
#   (a) tests/fixtures/real-events/ holds >=1 capture per defect hook (post-commit, detect-loop),
#       each with a sidecar <fixture>.provenance naming the live source + date (or the documented
#       platform-docs fallback per the spec's assumption 4 — the sidecar must say which).
#   (b) eval/hook-hygiene/capture-diagnosis.md pairs every `branch:` verdict with a `fixture:` path
#       and an `evidence:` jq expression that RESOLVES (jq -e) against that fixture — a branch
#       verdict nobody can mechanically re-check is prose, not evidence.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES="$REPO_ROOT/tests/fixtures/real-events"
DIAG="$REPO_ROOT/eval/hook-hygiene/capture-diagnosis.md"

echo "=== Phase 84 Fixture Provenance Tests ==="

# ---- 1. >=1 capture per defect hook, valid JSON ----
for hook in post-commit detect-loop; do
  test_start "real-event capture exists for $hook (valid JSON)"
  F=$(ls "$FIXTURES"/${hook}*.json 2>/dev/null | head -1 || true)
  if [ -n "$F" ] && jq -e . "$F" >/dev/null 2>&1; then
    test_pass
  else
    test_fail "no valid JSON capture matching $FIXTURES/${hook}*.json"
  fi
done

# ---- 2. Every fixture carries a provenance sidecar (live source OR documented fallback) ----
test_start "every fixture has a provenance sidecar (source + date)"
MISSING=""
for F in "$FIXTURES"/*.json; do
  [ -e "$F" ] || { MISSING="no fixtures at all"; break; }
  P="$F.provenance"
  if [ ! -f "$P" ] || ! grep -qiE 'source:' "$P" || ! grep -qE '20[0-9]{2}-[0-9]{2}-[0-9]{2}' "$P"; then
    MISSING="$MISSING $(basename "$F")"
  fi
done
if [ -z "$MISSING" ]; then test_pass; else test_fail "missing/incomplete provenance:$MISSING"; fi

# ---- 3. Diagnosis: branch verdict per defect hook, closed enum ----
test_start "capture-diagnosis.md has a branch verdict per hook"
if [ -f "$DIAG" ] && [ "$(grep -cE '^branch: (remap|redesign|upstream)$' "$DIAG")" -ge 2 ]; then
  test_pass
else
  test_fail "need >=2 'branch: remap|redesign|upstream' lines in $DIAG"
fi

# ---- 4. Every branch line pairs with fixture: + evidence: whose jq expr RESOLVES in the fixture ----
test_start "every branch verdict is backed by a jq-resolvable evidence expr"
if [ ! -f "$DIAG" ]; then
  test_fail "capture-diagnosis.md absent"
else
  BAD=""
  N=$(grep -cE '^branch: ' "$DIAG" || true)
  for ((i=1; i<=N; i++)); do
    # block = the fixture:/evidence: lines nearest above/below the i-th branch line
    FIX=$(awk -v n="$i" '/^fixture: /{f=$2} /^branch: /{c++; if(c==n){print f; exit}}' "$DIAG")
    EXPR=$(awk -v n="$i" '/^branch: /{c++} c==n && /^evidence: /{sub(/^evidence: /,""); print; exit}' "$DIAG")
    if [ -z "$FIX" ] || [ -z "$EXPR" ] || ! jq -e "$EXPR" "$REPO_ROOT/$FIX" >/dev/null 2>&1; then
      BAD="$BAD #$i"
    fi
  done
  if [ -z "$BAD" ]; then test_pass; else test_fail "branch verdicts with unresolvable evidence:$BAD"; fi
fi

test_summary "fixture-provenance"
