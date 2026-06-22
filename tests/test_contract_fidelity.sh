#!/usr/bin/env bash
# Functional tests for the deterministic fidelity-check (scripts/check-fidelity.py).
# Phase 100 — Contract-vs-Spec Fidelity Screen, pillar-1. Controls-first per HEU-012:
# the check is the SCORING INSTRUMENT for the screen, so a bug in it corrupts the whole
# measurement. Therefore it must:
#   - PASS a worker output that honors every guardrail,
#   - FAIL LOUD (non-zero) on a worker output that violates a guardrail, naming it
#     (a guardrail with no failing fixture = dead instrument),
#   - FAIL LOUD on a malformed/missing-field contract (clean-on-seed = dead),
#   - be DETERMINISTIC (two runs on the same input are byte-identical),
#   - carry NO LLM/network dependency (AST import scan) and run OFFLINE.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHECK="$REPO_ROOT/scripts/check-fidelity.py"

echo "=== Contract Fidelity-Check Tests ==="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ---- a valid contract: 3 deterministic guardrails (file / content / stdout) ----
CONTRACT="$WORK/contract.json"
cat > "$CONTRACT" <<'JSON'
{
  "objectives": ["Produce result.txt marked DONE", "Report status ok"],
  "guardrails": [
    {"id": "g1-file", "description": "result.txt exists", "command": "test -f result.txt"},
    {"id": "g2-content", "description": "result marked DONE", "command": "grep -q DONE result.txt"},
    {"id": "g3-status", "description": "status is ok", "command": "cat status.txt", "expect_stdout_contains": "ok"}
  ]
}
JSON

# build a worker-output workdir honoring all guardrails
mk_honored() {
  local d; d="$(mktemp -d)"
  printf 'DONE\n' > "$d/result.txt"
  printf 'ok\n'   > "$d/status.txt"
  echo "$d"
}

run_check() {  # run_check <contract> <workdir> ; sets RC and OUT
  set +e
  OUT="$(python3 "$CHECK" --contract "$1" --workdir "$2" 2>&1)"
  RC=$?
  set -e
}

# ---- honored output -> PASS (exit 0) ----
HON="$(mk_honored)"
test_start "honored worker output -> check exits 0 (PASS)"
run_check "$CONTRACT" "$HON"
assert_eq 0 "$RC" "honored output should PASS"

# ---- per-guardrail VIOLATED output -> FAIL loud naming the guardrail ----
# g1: result.txt absent
V1="$(mktemp -d)"; printf 'ok\n' > "$V1/status.txt"
test_start "violated g1-file -> non-zero + names guardrail"
run_check "$CONTRACT" "$V1"
if [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "g1-file"; then test_pass; else test_fail "expected non-zero naming g1-file (rc=$RC)"; fi

# g2: result.txt present but not DONE
V2="$(mktemp -d)"; printf 'incomplete\n' > "$V2/result.txt"; printf 'ok\n' > "$V2/status.txt"
test_start "violated g2-content -> non-zero + names guardrail"
run_check "$CONTRACT" "$V2"
if [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "g2-content"; then test_pass; else test_fail "expected non-zero naming g2-content (rc=$RC)"; fi

# g3: status.txt present but stdout lacks "ok"
V3="$(mktemp -d)"; printf 'DONE\n' > "$V3/result.txt"; printf 'bad\n' > "$V3/status.txt"
test_start "violated g3-status (stdout) -> non-zero + names guardrail"
run_check "$CONTRACT" "$V3"
if [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "g3-status"; then test_pass; else test_fail "expected non-zero naming g3-status (rc=$RC)"; fi

# ---- controls-first: malformed / missing-field contract -> fail loud ----
BADJSON="$WORK/bad.json"; printf '{ "guardrails": [ {,, ] ' > "$BADJSON"
test_start "control: malformed JSON contract fails loud (non-zero + stderr)"
set +e
err=$(python3 "$CHECK" --contract "$BADJSON" --workdir "$HON" 2>&1 >/dev/null); rc=$?
set -e
if [ "$rc" -ne 0 ] && [ -n "$err" ]; then test_pass; else test_fail "expected non-zero + stderr (rc=$rc)"; fi

MISSING="$WORK/missing.json"; printf '{"objectives":["x"],"guardrails":[{"id":"g1"}]}' > "$MISSING"
test_start "control: guardrail missing 'command' fails loud (non-zero + stderr)"
set +e
err=$(python3 "$CHECK" --contract "$MISSING" --workdir "$HON" 2>&1 >/dev/null); rc=$?
set -e
if [ "$rc" -ne 0 ] && [ -n "$err" ]; then test_pass; else test_fail "expected non-zero + stderr (rc=$rc)"; fi

EMPTY="$WORK/empty.json"; printf '{"objectives":["x"],"guardrails":[]}' > "$EMPTY"
test_start "control: empty guardrails list fails loud (non-zero + stderr)"
set +e
err=$(python3 "$CHECK" --contract "$EMPTY" --workdir "$HON" 2>&1 >/dev/null); rc=$?
set -e
if [ "$rc" -ne 0 ] && [ -n "$err" ]; then test_pass; else test_fail "expected non-zero + stderr (rc=$rc)"; fi

# ---- determinism: two runs on the same input are byte-identical ----
test_start "determinism: two runs byte-identical"
o1="$(python3 "$CHECK" --contract "$CONTRACT" --workdir "$HON" 2>&1 || true)"
o2="$(python3 "$CHECK" --contract "$CONTRACT" --workdir "$HON" 2>&1 || true)"
if [ "$o1" = "$o2" ]; then test_pass; else test_fail "output differs across runs"; fi

# ---- no LLM/network dependency (AST import scan, robust to aliasing/from-imports) ----
test_start "no network/LLM import (AST scan exits 0)"
set +e
python3 -c "import ast,sys; t=ast.parse(open('$CHECK').read()); m={a.name.split('.')[0] for n in ast.walk(t) if isinstance(n,ast.Import) for a in n.names}|{n.module.split('.')[0] for n in ast.walk(t) if isinstance(n,ast.ImportFrom) and n.module}; sys.exit(1 if m & {'requests','anthropic','openai','httpx','urllib','urllib3','socket','http'} else 0)"
rc=$?
set -e
assert_eq 0 "$rc" "check-fidelity.py must carry no network/LLM import"

# ---- runtime offline control: completes with API keys unset / network env stripped ----
test_start "runtime offline: completes with no API key set"
set +e
env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u OPENCODE_API_KEY \
  python3 "$CHECK" --contract "$CONTRACT" --workdir "$HON" >/dev/null 2>&1
rc=$?
set -e
assert_eq 0 "$rc" "check should run offline on honored input"

test_summary "contract-fidelity"
