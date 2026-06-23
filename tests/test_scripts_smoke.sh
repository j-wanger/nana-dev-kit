#!/usr/bin/env bash
# Functional smoke tests for scripts/ entries that previously had NO functional coverage
# (Phase 82 coverage area). One deferred with rationale in the verification matrix:
# generate-delivery-report.py (functional smoke needs a stubbed `make` — M/L design).
# harness-audit.sh wired in Phase 83 (checkpoint override: wire-in over cut) — smoke below.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Scripts Functional Smoke Tests ==="

# ---- eval-runner.sh NEGATIVE CONTROL: a runner that can never fail proves nothing ----
# Hermetic copy (REPO_ROOT derives from the script's own path): 1 passing + 1 seeded-failing
# scenario; the runner must score 1/2, demonstrating it actually detects failures.
test_start "eval-runner: negative control — seeded failing scenario IS scored as fail"
T=$(mktemp -d)
mkdir -p "$T/scripts" "$T/eval/corpus/seeded-pass" "$T/eval/corpus/seeded-fail" "$T/templates/.claude/hooks"
cp "$REPO_ROOT/scripts/eval-runner.sh" "$T/scripts/"
[ -d "$REPO_ROOT/eval/validators" ] && cp -r "$REPO_ROOT/eval/validators" "$T/eval/validators"
PASS_SRC=$(find "$REPO_ROOT/eval/corpus" -mindepth 1 -maxdepth 1 -type d | head -1)
cp -r "$PASS_SRC/." "$T/eval/corpus/seeded-pass/"
cat > "$T/eval/corpus/seeded-fail/scenario.json" << 'EOF'
{
  "name": "seeded negative control - must fail",
  "category": "context",
  "scoring": "binary",
  "checks": [
    {"type": "file_exists", "path": "this/file/does/not/exist-seeded-control"}
  ]
}
EOF
OUT=$(bash "$T/scripts/eval-runner.sh" 2>&1); EC=$?
if echo "$OUT" | grep -qE '1/2'; then
  test_pass
else
  test_fail "runner did not score the seeded failure (ec=$EC, out tail: $(echo "$OUT" | tail -3 | tr '\n' '|'))"
fi
rm -rf "$T"

# NOTE (reviewer finding, accepted trade-off): the two generator smokes below regenerate the
# TRACKED artifacts docs/report.html and docs/workflow.html in the live tree — same side effect
# as the sanctioned `make report`/`make workflow` targets they exercise. Hermetic copies would
# need a fixture repo (VERSION, file inventory) the generators walk; deferred as not worth it.
# ---- generate-report.py: produces its HTML artifact (Makefile-sanctioned generator) ----
test_start "generate-report.py: exits 0 and writes docs/report.html with HTML content"
EC=0; python3 "$REPO_ROOT/scripts/generate-report.py" >/dev/null 2>&1 || EC=$?
if [ "$EC" = "0" ] && [ -f "$REPO_ROOT/docs/report.html" ] && grep -qi '<html' "$REPO_ROOT/docs/report.html"; then
  test_pass
else
  test_fail "generate-report.py failed (ec=$EC) or no HTML output"
fi

# ---- generate-workflow.py: produces its HTML artifact ----
test_start "generate-workflow.py: exits 0 and writes docs/workflow.html with HTML content"
EC=0; python3 "$REPO_ROOT/scripts/generate-workflow.py" >/dev/null 2>&1 || EC=$?
if [ "$EC" = "0" ] && [ -f "$REPO_ROOT/docs/workflow.html" ] && grep -qi '<html' "$REPO_ROOT/docs/workflow.html"; then
  test_pass
else
  test_fail "generate-workflow.py failed (ec=$EC) or no HTML output"
fi

# ---- generate-dashboard.py: produces its HTML artifact (Phase 106, Makefile-sanctioned generator) ----
test_start "generate-dashboard.py: exits 0 and writes docs/dashboard.html with HTML content"
EC=0; python3 "$REPO_ROOT/scripts/generate-dashboard.py" >/dev/null 2>&1 || EC=$?
if [ "$EC" = "0" ] && [ -f "$REPO_ROOT/docs/dashboard.html" ] && grep -qi '<html' "$REPO_ROOT/docs/dashboard.html"; then
  test_pass
else
  test_fail "generate-dashboard.py failed (ec=$EC) or no HTML output"
fi

# ---- harness-audit.sh: wired via `make audit` (Phase 83) — emits a per-hook utilization report ----
test_start "harness-audit: runs and emits USED/LATENT/UNCERTAIN utilization lines"
T=$(mktemp -d)
EC=0
OUT=$( (cd "$T" && bash "$REPO_ROOT/scripts/harness-audit.sh") 2>&1 ) || EC=$?
rm -rf "$T"
if { [ "$EC" = "0" ] || [ "$EC" = "1" ]; } && echo "$OUT" | grep -qE '^(USED|LATENT|UNCERTAIN|DEAD) '; then
  test_pass
else
  test_fail "harness-audit did not emit a utilization report (ec=$EC, head: $(echo "$OUT" | head -1))"
fi

test_summary "scripts-smoke"
