#!/usr/bin/env bash
# Tests for the Phase-65 enforcement firing-log substrate (the hardened `log_firing` pattern).
# T1: pilot hook (dev-wiki-scope-check) + the helper's safety contract (fail-open, injection, exfiltration).
# T2 extends this to all 6 instrumented hooks.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS="$REPO_ROOT/templates/.claude/hooks"
LOG=".dev-wiki/enforcement.log"
ORIG_HOME="$HOME"
ORIG_PATH="$PATH"

# A dev-wiki project with one open task scoped to src/**, active phase 65, enforce marker present.
setup_fixture() {
  local dir; dir=$(mktemp -d)
  mkdir -p "$dir/.dev-wiki" "$dir/.claude/rules"
  touch "$dir/.claude/enforce"
  printf 'Phase: 65 - firing log test\n' > "$dir/.claude/rules/active-phase.md"
  printf '# Tasks\n- [ ] [S] T1 do thing | scope: `src/**` | success: `true` | size: S\n' > "$dir/.dev-wiki/tasks.md"
  echo "$dir"
}
teardown() { export HOME="$ORIG_HOME"; export PATH="$ORIG_PATH"; chmod -R u+rwx "$1" 2>/dev/null || true; rm -rf "$1"; }

# Run a hook in a fixture; echo its exit code. stdout→$fx/.out, stderr→$fx/.err. Extra env via $RUN_ENV.
run_hook() {
  local hook="$1" fx="$2" json="$3"; local ec=0
  echo "$json" | HOME="$fx" bash -c "cd '$fx' && ${RUN_ENV:-} bash '$HOOKS/$hook'" >"$fx/.out" 2>"$fx/.err" || ec=$?
  echo "$ec"
}

OOS_JSON='{"tool_name":"Write","input":{"file_path":"docs/out-of-scope.py"}}'   # relative, not in src/** → advisory

echo "=== Phase 65 Firing-Log Tests ==="

# 1. Out-of-scope write → well-formed advisory record (all keys, jq-valid, correct values).
test_start "scope-check: out-of-scope emits well-formed advisory record"
T=$(setup_fixture)
EC=$(run_hook dev-wiki-scope-check.sh "$T" "$OOS_JSON")
LINE=$(tail -n1 "$T/$LOG" 2>/dev/null || echo "")
if [ "$EC" = "0" ] && printf '%s' "$LINE" | jq -e \
  '(.schema_version|type=="number") and (.ts|type=="string") and (.hook=="dev-wiki-scope-check") and (.action=="advisory") and (.reason=="out-of-scope") and (.phase=="65")' >/dev/null 2>&1; then
  test_pass; else test_fail "no well-formed advisory record (ec=$EC line=$LINE)"; fi
teardown "$T"

# 2. In-scope write → allow record. (Absolute path: the matcher prepends $ROOT to globs, so it
#    compares against an absolute file_path — which is what Claude passes in practice.)
test_start "scope-check: in-scope emits allow record"
T=$(setup_fixture)
EC=$(run_hook dev-wiki-scope-check.sh "$T" "{\"tool_name\":\"Write\",\"input\":{\"file_path\":\"$T/src/in-scope.py\"}}")
LINE=$(tail -n1 "$T/$LOG" 2>/dev/null || echo "")
if [ "$EC" = "0" ] && printf '%s' "$LINE" | jq -e '(.action=="allow") and (.reason=="in-scope")' >/dev/null 2>&1; then
  test_pass; else test_fail "no allow record (ec=$EC line=$LINE)"; fi
teardown "$T"

# 3. FAIL-OPEN (unwritable log): write fails, but the hook's decision + exit are preserved.
test_start "scope-check: fail-open under unwritable log (advisory + exit 0 preserved)"
T=$(setup_fixture)
: > "$T/$LOG"; chmod 000 "$T/$LOG"
EC=$(run_hook dev-wiki-scope-check.sh "$T" "$OOS_JSON")
chmod 644 "$T/$LOG" 2>/dev/null || true
if [ "$EC" = "0" ] && grep -q 'outside active task scope' "$T/.out"; then
  test_pass; else test_fail "hook broke under unwritable log (ec=$EC out=$(cat "$T/.out"))"; fi
teardown "$T"

# 4. FAIL-OPEN (stubbed failing `date`, used only by log_firing): exit preserved.
test_start "scope-check: fail-open under failing date (exit 0 preserved)"
T=$(setup_fixture)
mkdir -p "$T/stub"; printf '#!/bin/sh\nexit 1\n' > "$T/stub/date"; chmod +x "$T/stub/date"
RUN_ENV="PATH='$T/stub:$PATH'" EC=$(run_hook dev-wiki-scope-check.sh "$T" "$OOS_JSON")
unset RUN_ENV
if [ "$EC" = "0" ] && grep -q 'outside active task scope' "$T/.out"; then
  test_pass; else test_fail "hook broke under failing date (ec=$EC)"; fi
teardown "$T"

# 5. INJECTION-SAFE: malicious file_path can't corrupt the JSONL (every line stays jq-parseable).
test_start "scope-check: injection-safe (malicious path → log stays valid JSONL)"
T=$(setup_fixture)
EC=$(run_hook dev-wiki-scope-check.sh "$T" '{"tool_name":"Write","input":{"file_path":"docs/a\"b\\c\nd.py"}}')
if [ "$EC" = "0" ] && { [ ! -s "$T/$LOG" ] || jq -e . "$T/$LOG" >/dev/null 2>&1; }; then
  test_pass; else test_fail "log not valid JSONL after malicious path (ec=$EC)"; fi
teardown "$T"

# 6. EXFILTRATION-SAFE: a secret-bearing path is NOT recorded (controlled-vocab reason only).
test_start "scope-check: exfiltration-safe (secret in path not logged)"
T=$(setup_fixture)
EC=$(run_hook dev-wiki-scope-check.sh "$T" '{"tool_name":"Write","input":{"file_path":"docs/export-TOKEN-sekret.py"}}')
if [ "$EC" = "0" ] && ! grep -q 'sekret' "$T/$LOG" 2>/dev/null; then
  test_pass; else test_fail "secret leaked into firing log"; fi
teardown "$T"

# 7. HELPER BLOCK-SAFETY (the rm-rf scenario): the REAL log_firing function, extracted from the
#    shipped hook, must preserve `exit 2` even when the log write fails. No drift — uses the actual code.
test_start "log_firing: preserves a block (exit 2) under unwritable log"
T=$(setup_fixture)
sed -n '/^log_firing() {/,/^}/p' "$HOOKS/dev-wiki-scope-check.sh" > "$T/lib.sh"
cat > "$T/blockstub.sh" <<'EOF'
set -euo pipefail
. ./lib.sh
log_firing block test-block || true
exit 2
EOF
: > "$T/$LOG"; chmod 000 "$T/$LOG"
BEC=0; ( cd "$T" && bash blockstub.sh ) >/dev/null 2>&1 || BEC=$?
chmod 644 "$T/$LOG" 2>/dev/null || true
if [ -s "$T/lib.sh" ] && [ "$BEC" = "2" ]; then
  test_pass; else test_fail "block not preserved (lib empty? $([ -s "$T/lib.sh" ] && echo no || echo yes); exit=$BEC)"; fi
teardown "$T"

# === T2: all 6 hooks emit well-formed records; the blocking hooks preserve their block under log failure ===
# (The 3 existing loggers were retrofitted from raw-echo+tail-500 onto log_firing; enforce-memory has NO
#  coverage in test_enforce.sh, and neither stubs a failing date — so the dual-variant proof lives here.)

mk_devwiki() { local d; d=$(mktemp -d); mkdir -p "$d/.dev-wiki" "$d/.claude/rules" "$d/specs"; printf 'Phase: 65 - x\n' > "$d/.claude/rules/active-phase.md"; echo "$d"; }
mk_spec()    { local d; d=$(mk_devwiki); touch "$d/.claude/enforce"; echo "$d"; }
mk_memory()  { local d; d=$(mk_devwiki); touch "$d/.claude/enforce-memory"; echo "$d"; }
mk_loop()    { local d; d=$(mk_devwiki); touch "$d/.claude/enforce"; printf '%s\n' '- [ ] `test -f /nonexistent-deliverable-xyz`' > "$d/specs/phase-65-x.md"; echo "$d"; }
mk_checktests() { mk_devwiki; }

WRITE_OOS='{"tool_name":"Write","input":{"file_path":"src/app.py"}}'
CHECKTESTS_JSON='{"tool_uses":[{"input":{"file_path":"src/x.py"}}]}'

# Blocking hook: baseline block+record, then exit-2 preserved under (a) unwritable log and (b) failing date.
check_block() {  # label hook mkfx json renv
  local label="$1" hook="$2" mkfx="$3" json="$4" renv="${5:-}" T ec line hk="${2%.sh}"
  T=$($mkfx)
  test_start "$label: blocks (exit 2) + emits block record"
  RUN_ENV="$renv"; ec=$(run_hook "$hook" "$T" "$json"); unset RUN_ENV
  line=$(tail -n1 "$T/$LOG" 2>/dev/null || echo "")
  if [ "$ec" = "2" ] && printf '%s' "$line" | jq -e ".hook==\"$hk\" and .action==\"block\"" >/dev/null 2>&1; then test_pass; else test_fail "ec=$ec line=$line"; fi
  teardown "$T"
  T=$($mkfx); : > "$T/$LOG"; chmod 000 "$T/$LOG"
  test_start "$label: preserves block (exit 2) under unwritable log"
  RUN_ENV="$renv"; ec=$(run_hook "$hook" "$T" "$json"); unset RUN_ENV
  chmod 644 "$T/$LOG" 2>/dev/null || true
  assert_eq "2" "$ec" "block lost under unwritable log"
  teardown "$T"
  T=$($mkfx); mkdir -p "$T/stub"; printf '#!/bin/sh\nexit 1\n' > "$T/stub/date"; chmod +x "$T/stub/date"
  test_start "$label: preserves block (exit 2) under failing date"
  RUN_ENV="PATH='$T/stub:'\$PATH $renv"; ec=$(run_hook "$hook" "$T" "$json"); unset RUN_ENV
  assert_eq "2" "$ec" "block lost under failing date"
  teardown "$T"
}

check_block "enforce-spec"   enforce-spec.sh         mk_spec       "$WRITE_OOS"       ""
check_block "enforce-memory" enforce-memory.sh       mk_memory     "$WRITE_OOS"       "CI="
check_block "enforce-loop"   enforce-loop.sh         mk_loop       "{}"               ""
check_block "check-tests"    check-tests-were-run.sh mk_checktests "$CHECKTESTS_JSON" ""

# detect-loop: advisory (controlled-vocab, command NEVER logged) after 3 identical failures.
test_start "detect-loop: 3rd repeated failure emits advisory record"
T=$(mk_devwiki); touch "$T/.claude/enforce"
DLJSON='{"tool_input":{"command":"badcmd"},"exit_code":1}'
run_hook detect-loop.sh "$T" "$DLJSON" >/dev/null; run_hook detect-loop.sh "$T" "$DLJSON" >/dev/null
EC=$(run_hook detect-loop.sh "$T" "$DLJSON"); LINE=$(tail -n1 "$T/$LOG" 2>/dev/null || echo "")
if [ "$EC" = "0" ] && printf '%s' "$LINE" | jq -e '.hook=="detect-loop" and .action=="advisory" and .reason=="repeated-failure"' >/dev/null 2>&1; then test_pass; else test_fail "ec=$EC line=$LINE"; fi
teardown "$T"

# Static uniformity: the inline-duplicated log_firing body must be byte-identical across all 6 hooks
# (modulo the --arg hook "<name>" literal). Catches copy-drift even if behavioral coverage misses a hook.
test_start "log_firing: all 6 hook copies byte-identical (modulo hook name)"
NORM=""; MISMATCH=""
for h in enforce-spec enforce-loop enforce-memory dev-wiki-scope-check detect-loop check-tests-were-run; do
  BODY=$(sed -n '/^log_firing() {/,/^}/p' "$HOOKS/$h.sh" | sed 's/--arg hook "[^"]*"/--arg hook "HOOK"/')
  if [ -z "$NORM" ]; then NORM="$BODY"; elif [ "$BODY" != "$NORM" ]; then MISMATCH="$h"; fi
done
[ -z "$MISMATCH" ] && [ -n "$NORM" ] && test_pass || test_fail "log_firing body diverges in ${MISMATCH:-<none-extracted>}"

test_summary "firing-log"
