#!/usr/bin/env bash
# Phase 84 — eval-harness hermeticity (defect 4, eval/qa-sweep/repro-runs.log line 59).
# The kit hooks open with `cd "${CLAUDE_PROJECT_DIR:-.}"` (Phase 79); if the eval runner does not
# neutralize that variable, a hook invoked inside a mktemp sandbox escapes into whatever project
# the caller's environment points at and mutates it — the instrument mutates the subject.
# The dormant real hooks write nothing today, so they cannot probe this; a synthetic PROBE hook
# (same cd-preamble, then touches .leak-marker in its CWD) is the instrument. Controls-first
# (qa-verification-sweep): the probe must catch a SEEDED leaky runner or the suite is dead.
# Everything runs in scratch rigs under mktemp -d — real live state is never touched.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUNNER="$REPO_ROOT/scripts/eval-runner.sh"
REAL_HOME="$HOME"

RIGS=()
cleanup() { for d in "${RIGS[@]}"; do rm -rf "$d" 2>/dev/null || true; done; }
trap cleanup EXIT

# build_rig <runner-file> -> echoes rig root. Mimics the repo layout the runner derives its
# paths from (scripts/, eval/corpus/, templates/.claude/hooks/) plus a fake "live" project
# carrying the three tripwire files the real leak would hit.
build_rig() {
  local runner_src="$1" rig
  rig=$(mktemp -d)
  mkdir -p "$rig/scripts" "$rig/eval/corpus/leak-probe" "$rig/templates/.claude/hooks" \
           "$rig/live/.dev-wiki" "$rig/live/.claude"
  cp "$runner_src" "$rig/scripts/eval-runner.sh"
  # Probe hook: the kit hooks' Phase-79 preamble, then a write where it lands + a HOME assert.
  cat > "$rig/templates/.claude/hooks/leak-probe.sh" <<EOF
#!/usr/bin/env bash
cd "\${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
touch .leak-marker
[ "\$HOME" = "$REAL_HOME" ] && exit 2  # HOME override must reach the hook env
exit 0
EOF
  cat > "$rig/eval/corpus/leak-probe/scenario.json" <<'EOF'
{"category": "hook", "hook": "leak-probe.sh", "input": "{}", "expected": {"exit_code": 0}}
EOF
  # Tripwire files with known content (what a real escape would corrupt).
  printf 'tripwire-pending\n'  > "$rig/live/.dev-wiki/.pending-commit"
  printf 'tripwire-enforce\n'  > "$rig/live/.dev-wiki/enforcement.log"
  printf 'tripwire-loop\n'     > "$rig/live/.claude/.loop-state"
  echo "$rig"
}

# tripwire_sum <rig> -> checksum of the fake live tree (names + content)
tripwire_sum() {
  (cd "$1/live" && find . -type f -print0 | sort -z | xargs -0 cksum) 2>/dev/null
}

echo "=== Phase 84 Eval-Harness Hermeticity Tests ==="

# ---- 1. Leak test: runner must neutralize CLAUDE_PROJECT_DIR (currently the defect) ----
test_start "runner neutralizes CLAUDE_PROJECT_DIR (no live-tree write)"
RIG=$(build_rig "$RUNNER"); RIGS+=("$RIG")
SUM_BEFORE=$(tripwire_sum "$RIG")
OUT1=$( (cd "$RIG" && CLAUDE_PROJECT_DIR="$RIG/live" bash scripts/eval-runner.sh) 2>&1 || true )
SUM_AFTER=$(tripwire_sum "$RIG")
if [ ! -f "$RIG/live/.leak-marker" ] && [ "$SUM_BEFORE" = "$SUM_AFTER" ]; then
  test_pass
else
  test_fail "hook escaped sandbox into the live tree (marker=$(test -f "$RIG/live/.leak-marker" && echo yes || echo no))"
fi

# ---- 2. HOME override reaches the hook env (probe exits 2 on real HOME -> scenario fails) ----
test_start "HOME override reaches hook env (probe scenario passes)"
if echo "$OUT1" | grep -q 'Score: 1/1'; then
  test_pass
else
  test_fail "probe scenario did not pass under the runner (got: $(echo "$OUT1" | tail -1))"
fi

# ---- 3. Seeded-leak self-check: a runner WITHOUT the fix must leak, else instrument-dead ----
test_start "seeded leaky runner caught by probe (controls-first)"
SEEDED=$(mktemp); RIGS+=("$SEEDED")
# Revert ONLY the fix (the env assignment) — deleting whole lines mentioning the var would
# remove the hook-invocation line itself and yield a runner that runs nothing (false negative).
sed 's/CLAUDE_PROJECT_DIR="\$work_dir" //' "$RUNNER" > "$SEEDED"
if cmp -s "$RUNNER" "$SEEDED"; then
  test_fail "seed is a no-op: the fix assignment was not found to revert"
else
RIG2=$(build_rig "$SEEDED"); RIGS+=("$RIG2")
( cd "$RIG2" && CLAUDE_PROJECT_DIR="$RIG2/live" bash scripts/eval-runner.sh >/dev/null 2>&1 ) || true
if [ -f "$RIG2/live/.leak-marker" ]; then
  test_pass
else
  test_fail "INSTRUMENT-DEAD: seeded leaky runner produced no leak — probe cannot catch the defect"
fi
fi

# ---- 4. Unset variant: hooks' :-. fallback keeps the probe inside the sandbox ----
test_start "CLAUDE_PROJECT_DIR unset: :-. fallback stays sandboxed"
RIG3=$(build_rig "$RUNNER"); RIGS+=("$RIG3")
OUT4=$( (cd "$RIG3" && env -u CLAUDE_PROJECT_DIR bash scripts/eval-runner.sh) 2>&1 || true )
if [ ! -f "$RIG3/live/.leak-marker" ] && echo "$OUT4" | grep -q 'Score: 1/1'; then
  test_pass
else
  test_fail "unset-variant leaked or probe scenario failed (got: $(echo "$OUT4" | tail -1))"
fi

test_summary "eval-hermeticity"
