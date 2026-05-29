#!/usr/bin/env bash
# Functional-smoke tests for audit-log.sh (Phase 66 T3 — KEEP disposition).
# The hook appends {ts,tool,file,model} to .nana/audit.jsonl on each file edit — a human-facing
# forensic trail. The eval corpus only asserts exit_code:0; these assert the RECORD shape and
# injection-safety (the jq --arg hardening), which the corpus does not cover.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_ROOT/templates/.claude/hooks/audit-log.sh"

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

# Run the hook in a fresh cwd with $2 as stdin JSON; echo its exit code. Writes .nana/audit.jsonl in $1.
# printf (not echo) so embedded backslashes/quotes reach the hook intact.
run_audit() {
  local dir="$1" json="$2" ec=0
  printf '%s\n' "$json" | ( cd "$dir" && bash "$HOOK" ) >/dev/null 2>&1 || ec=$?
  echo "$ec"
}
freshdir() { mktemp -d "$TEST_TMP/d.XXXXXX"; }

echo "=== Phase 66 audit-log Functional-Smoke Tests ==="

# 1. Write event → a jq-valid record with the expected fields.
test_start "write event → well-formed audit record"
D=$(freshdir)
EC=$(run_audit "$D" '{"tool_name":"Write","tool_input":{"file_path":"src/app.py"}}')
LINE=$(tail -n1 "$D/.nana/audit.jsonl" 2>/dev/null || echo "")
if [ "$EC" = "0" ] && printf '%s' "$LINE" | jq -e '(.ts|type=="string") and (.tool=="Write") and (.file=="src/app.py") and has("model")' >/dev/null 2>&1; then
  test_pass; else test_fail "no well-formed record (ec=$EC line=$LINE)"; fi

# 2. Empty file_path → exit 0, no record written.
test_start "empty file_path → exit 0, no record"
D=$(freshdir)
EC=$(run_audit "$D" '{"tool_name":"Write","tool_input":{"file_path":""}}')
if [ "$EC" = "0" ] && [ ! -f "$D/.nana/audit.jsonl" ]; then test_pass; else test_fail "expected exit 0 + no audit file (ec=$EC)"; fi

# 3. Injection: a path containing a quote + backslash must NOT corrupt the JSONL (the jq --arg fix).
test_start "path with quote/backslash → JSONL stays valid (no injection)"
D=$(freshdir)
EC=$(run_audit "$D" '{"tool_name":"Edit","tool_input":{"file_path":"src/a\"b\\c.py"}}')
LINE=$(tail -n1 "$D/.nana/audit.jsonl" 2>/dev/null || echo "")
if [ "$EC" = "0" ] && printf '%s' "$LINE" | jq -e '.file=="src/a\"b\\c.py"' >/dev/null 2>&1; then
  test_pass; else test_fail "injection corrupted the JSONL (ec=$EC line=$LINE)"; fi

# 4. Append-only: a second edit accumulates a second line (the trail grows).
test_start "second write appends (forensic trail accumulates)"
D=$(freshdir)
run_audit "$D" '{"tool_name":"Write","tool_input":{"file_path":"a.py"}}' >/dev/null
run_audit "$D" '{"tool_name":"Edit","tool_input":{"file_path":"b.py"}}' >/dev/null
N=$(wc -l < "$D/.nana/audit.jsonl" 2>/dev/null | tr -d ' ')
assert_eq "2" "$N" "expected 2 accumulated audit lines"

# 5. Reads the .input.file_path fallback too (PreToolUse-shaped input).
test_start "reads .input.file_path fallback"
D=$(freshdir)
EC=$(run_audit "$D" '{"tool_name":"Write","input":{"file_path":"fallback.py"}}')
LINE=$(tail -n1 "$D/.nana/audit.jsonl" 2>/dev/null || echo "")
if [ "$EC" = "0" ] && printf '%s' "$LINE" | jq -e '.file=="fallback.py"' >/dev/null 2>&1; then
  test_pass; else test_fail "fallback path not captured (ec=$EC line=$LINE)"; fi

# 6. Fail-open: an unwritable cwd (.nana can't be created) must NOT make the hook exit non-zero.
test_start "unwritable cwd → exit 0 (fail-open, mkdir guarded)"
D=$(freshdir); chmod 555 "$D"
EC=$(run_audit "$D" '{"tool_name":"Write","tool_input":{"file_path":"x.py"}}')
chmod 755 "$D"
assert_eq "0" "$EC" "audit-log aborted on unwritable cwd (fail-open violated)"

test_summary "audit-log Functional-Smoke Tests"
