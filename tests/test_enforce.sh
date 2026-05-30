#!/usr/bin/env bash
# Tests for enforcement hooks (enforce-spec.sh and enforce-loop.sh).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SPEC_HOOK="$REPO_ROOT/templates/.claude/hooks/enforce-spec.sh"
LOOP_HOOK="$REPO_ROOT/templates/.claude/hooks/enforce-loop.sh"
# fires: enforce-spec.sh enforce-loop.sh   # (coverage gate — see test_hook_firing_coverage.sh)

ORIG_HOME="$HOME"

setup_fixture() {
  local dir
  dir=$(mktemp -d)
  mkdir -p "$dir/.claude/rules" "$dir/.dev-wiki/articles/journal" "$dir/specs"
  touch "$dir/.claude/enforce"
  echo "$dir"
}

teardown_fixture() {
  export HOME="$ORIG_HOME"
  rm -rf "$1"
}

run_spec_hook() {
  local fixture="$1" json="$2"
  local exit_code=0
  echo "$json" | HOME="$fixture" bash -c "cd '$fixture' && bash '$SPEC_HOOK'" 2>/dev/null || exit_code=$?
  echo "$exit_code"
}

run_loop_hook() {
  local fixture="$1" json="$2"
  local exit_code=0
  echo "$json" | HOME="$fixture" bash -c "cd '$fixture' && bash '$LOOP_HOOK'" 2>/dev/null || exit_code=$?
  echo "$exit_code"
}

run_loop_hook_stdout() {
  local fixture="$1" json="$2"
  echo "$json" | HOME="$fixture" bash -c "cd '$fixture' && bash '$LOOP_HOOK'" 2>/dev/null || true
}

WRITE_JSON='{"tool_name":"Write","input":{"file_path":"src/main.py"}}'
STOP_JSON='{}'

echo "=== Enforcement Hook Tests ==="

# --- enforce-spec.sh tests ---

test_start "spec: allow when no .dev-wiki"
T=$(mktemp -d)
mkdir -p "$T/.claude"
touch "$T/.claude/enforce"
EXIT=$(run_spec_hook "$T" "$WRITE_JSON")
assert_eq "0" "$EXIT" "should allow when no .dev-wiki"
rm -rf "$T"

test_start "spec: allow when allowlisted path"
T=$(setup_fixture)
printf 'Phase: 99 - test\n' > "$T/.claude/rules/active-phase.md"
EXIT=$(run_spec_hook "$T" '{"tool_name":"Write","input":{"file_path":"tests/test_foo.py"}}')
assert_eq "0" "$EXIT" "tests/ should be allowlisted"
teardown_fixture "$T"

test_start "spec: block when no spec exists"
T=$(setup_fixture)
printf 'Phase: 99 - test\n' > "$T/.claude/rules/active-phase.md"
EXIT=$(run_spec_hook "$T" "$WRITE_JSON")
assert_eq "2" "$EXIT" "should block without spec"
teardown_fixture "$T"

test_start "spec: block when stub spec (no exit criteria)"
T=$(setup_fixture)
printf 'Phase: 99 - test\n' > "$T/.claude/rules/active-phase.md"
printf '# Spec: Test\n\n## Exit Criteria\n\nTODO\n' > "$T/specs/phase-99-test.md"
EXIT=$(run_spec_hook "$T" "$WRITE_JSON")
assert_eq "2" "$EXIT" "stub spec should not satisfy gate"
teardown_fixture "$T"

test_start "spec: allow when valid spec exists"
T=$(setup_fixture)
printf 'Phase: 99 - test\n' > "$T/.claude/rules/active-phase.md"
printf '## Exit Criteria\n\n- [ ] `test -f src/main.py`\n' > "$T/specs/phase-99-test.md"
EXIT=$(run_spec_hook "$T" "$WRITE_JSON")
assert_eq "0" "$EXIT" "valid spec should allow"
teardown_fixture "$T"

test_start "spec: allow when gate marked [x]"
T=$(setup_fixture)
printf 'Phase: 99 - test\nGates: [x] spec reviewed\n' > "$T/.claude/rules/active-phase.md"
EXIT=$(run_spec_hook "$T" "$WRITE_JSON")
assert_eq "0" "$EXIT" "gate [x] spec should allow"
teardown_fixture "$T"

# --- enforce-loop.sh tests ---

test_start "loop: deliverable-check pass"
T=$(setup_fixture)
printf 'Phase: 99 - test\n' > "$T/.claude/rules/active-phase.md"
printf -- '- [ ] `test -f %s/specs/phase-99-test.md`\n' "$T" > "$T/specs/phase-99-test.md"
EXIT=$(run_loop_hook "$T" "$STOP_JSON")
assert_eq "0" "$EXIT" "existing deliverable should pass"
teardown_fixture "$T"

test_start "loop: deliverable-check fail"
T=$(setup_fixture)
printf 'Phase: 99 - test\n' > "$T/.claude/rules/active-phase.md"
printf -- '- [ ] `test -f %s/nonexistent-file`\n' "$T" > "$T/specs/phase-99-test.md"
EXIT=$(run_loop_hook "$T" "$STOP_JSON")
assert_eq "2" "$EXIT" "missing deliverable should block"
teardown_fixture "$T"

test_start "loop: debrief advisory output"
T=$(setup_fixture)
printf 'Phase: 99 - test\n' > "$T/.claude/rules/active-phase.md"
(cd "$T" && git init -q && git config user.email "test@test.com" && git commit --allow-empty -m "test" -q)
OUTPUT=$(run_loop_hook_stdout "$T" "$STOP_JSON")
if echo "$OUTPUT" | grep -q "debrief\|dev-debrief"; then
  test_pass
else
  test_fail "expected debrief advisory in stdout"
fi
teardown_fixture "$T"

test_start "loop: marker absent = allow all"
T=$(mktemp -d)
mkdir -p "$T/.claude/rules" "$T/.dev-wiki" "$T/specs"
printf 'Phase: 99 - test\n' > "$T/.claude/rules/active-phase.md"
printf -- '- [ ] `test -f %s/nonexistent-file`\n' "$T" > "$T/specs/phase-99-test.md"
EXIT=$(run_loop_hook "$T" "$STOP_JSON")
assert_eq "0" "$EXIT" "should allow without enforce marker"
rm -rf "$T"

test_summary "enforce"
