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

# --- Phase 82: current platform event shape (.tool_input) + absolute paths — the dormancy regressions ---
# enforce-spec parsed only legacy .input.file_path (a .tool_input-only event sailed through), its
# relative allowlist never matched absolute event paths, and its spec lookup reconstructed the slug
# with an ASCII-dash sed that an em-dash phase line broke. All three must hold both ways.

test_start "spec: current shape (.tool_input) blocks without approved spec"
T=$(setup_fixture)
printf 'Phase: 99 - test\n' > "$T/.claude/rules/active-phase.md"
EXIT=$(run_spec_hook "$T" '{"tool_name":"Write","tool_input":{"file_path":"src/main.py"}}')
assert_eq "2" "$EXIT" "tool_input shape must hit the same gate as legacy .input"
teardown_fixture "$T"

test_start "spec: ABSOLUTE in-project path hits the allowlist (tests/)"
T=$(setup_fixture)
printf 'Phase: 99 - test\n' > "$T/.claude/rules/active-phase.md"
EXIT=$(run_spec_hook "$T" "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$T/tests/test_foo.py\"}}")
assert_eq "0" "$EXIT" "absolute path must be relativized before the allowlist"
teardown_fixture "$T"

test_start "spec: em-dash phase line + status suffix still finds the approved spec (glob lookup)"
T=$(setup_fixture)
printf 'Phase: 99 — Some Name (ultracode) | ACTIVE\n' > "$T/.claude/rules/active-phase.md"
printf '<!-- nana:approved 2026-06-09 -->\n# Spec: x\n' > "$T/specs/phase-99-some-name.md"
EXIT=$(run_spec_hook "$T" "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$T/src/main.py\"}}")
assert_eq "0" "$EXIT" "spec lookup must match by phase number glob, not slug reconstruction"
teardown_fixture "$T"

test_start "spec: outside-project absolute path is allowed (not this project's gate)"
T=$(setup_fixture)
printf 'Phase: 99 - test\n' > "$T/.claude/rules/active-phase.md"
EXIT=$(run_spec_hook "$T" '{"tool_name":"Write","tool_input":{"file_path":"/somewhere/else/src/main.py"}}')
assert_eq "0" "$EXIT" "outside-project writes must not be blocked"
teardown_fixture "$T"

test_summary "enforce"
