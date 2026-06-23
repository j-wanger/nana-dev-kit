#!/usr/bin/env bash
# Roundtrip + boundary-validator + watcher controls for the act-from-page channel (Phase 106).
#
# Controls-first per HEU-012:
#   R0/R3  the shared deterministic validator ACCEPTS a faithful response and REJECTS every seeded
#          defect (stale-nonce / partial-coverage / phantom-option / bad-position) — clean-on-seed
#          = dead instrument.
#   R1/R2  END-TO-END: boot the real server, POST a valid decision, and confirm the SERVER-WRITTEN
#          file passes the SAME validator and its fields match the POST (one artifact, real diff).
#   R4     the session WATCHER predicate IGNORES a pre-seeded stale-nonce file (+ a positive control
#          that it DOES fire on a fresh-nonce decision).
#   R5     the abandoned-tab wait RELEASES on its injected deadline (positive-control the arithmetic,
#          per the Ph84 "verify the loop actually fires, not silently degenerates" lesson).
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
set +e  # checks exit codes MANUALLY; helpers.sh does `set -euo pipefail`, so disable errexit AFTER.
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-decision-response.py"
SERVER="$REPO_ROOT/scripts/decision-server.py"
FIX="$SCRIPT_DIR/fixtures"
BRIEF="$FIX/dashboard-brief.valid.json"
STATE="$FIX/dashboard-current-state.md"
VALIDRESP="$FIX/decision-response.valid.json"
NONCE="$(jq -r '.nonce' "$BRIEF")"

# Portable self-watchdog (macOS has no GNU `timeout`; R5 has a timed loop).
MAIN_PID=$$
( sleep 120; kill -9 "$MAIN_PID" 2>/dev/null ) >/dev/null 2>&1 &
WD=$!; trap 'kill "$WD" 2>/dev/null' EXIT

echo "=== Dashboard Roundtrip + Decision-Validator + Watcher Controls ==="
validate_rc() { python3 "$VALIDATE" "$1" "$2" >/dev/null 2>&1; echo $?; }

# ---- R0 + R3a-d: validator accepts the faithful response, rejects every seeded defect ----
test_start "R0 validator: valid response accepted (exit 0)"
assert_eq 0 "$(validate_rc "$BRIEF" "$VALIDRESP")" "valid response should validate"
for ctl in stalenonce partialcoverage phantomoption badposition; do
  test_start "R3 control: $ctl response rejected (non-zero)"
  rc="$(validate_rc "$BRIEF" "$FIX/decision-response.$ctl.json")"
  if [ "$rc" -ne 0 ]; then test_pass; else test_fail "$ctl should have been rejected (dead instrument)"; fi
done
test_start "control: malformed-JSON response fails loud"
BAD="$(mktemp)"; printf '{ not json' > "$BAD"
rc="$(validate_rc "$BRIEF" "$BAD")"; rm -f "$BAD"
if [ "$rc" -ne 0 ]; then test_pass; else test_fail "malformed JSON should fail loud"; fi
test_start "control: nonce-less brief accepts a nonce-less response (fail-open)"
LEGACY="$(mktemp)"
python3 -c "import json; r=json.load(open('$VALIDRESP')); r.pop('brief_nonce',None); r['assumptions']=r['assumptions'][:2]; json.dump(r,open('$LEGACY','w'))"
assert_eq 0 "$(validate_rc "$FIX/dashboard-brief.nononce.json" "$LEGACY")" "legacy nonce-less brief should fail-open"
rm -f "$LEGACY"

# ---- HTTP client for the end-to-end roundtrip ----
CLIENT="$(mktemp)"
cat > "$CLIENT" <<'PY'
import sys, http.client
from urllib.parse import urlparse
method, url = sys.argv[1], sys.argv[2]
body = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] != "" else None
origin = sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] != "" else None
u = urlparse(url)
headers = {}
if origin:
    headers["Origin"] = origin
    headers["Host"] = u.netloc
if body is not None:
    headers["Content-Type"] = "application/json"
try:
    c = http.client.HTTPConnection(u.hostname, u.port, timeout=5)
    c.request(method, u.path or "/", body=(body.encode() if body else None), headers=headers)
    sys.stdout.write(str(c.getresponse().status))
except Exception as e:
    sys.stdout.write("ERR:%s" % e)
PY

# ---- R1 + R2: end-to-end — boot the server, POST a valid decision, server-written file validates + matches ----
SCRATCH="$(mktemp -d)"; mkdir -p "$SCRATCH/.dev-wiki"
RESP="$SCRATCH/.dev-wiki/decision-response.json"
URLFILE="$SCRATCH/.dev-wiki/.decision-server.url"
python3 "$SERVER" --brief "$BRIEF" --state "$STATE" --response "$RESP" --timeout 30 >/dev/null 2>"$SCRATCH/err" &
SPID=$!; disown "$SPID" 2>/dev/null
i=0; while [ ! -s "$URLFILE" ] && kill -0 "$SPID" 2>/dev/null && [ $i -lt 50 ]; do sleep 0.1; i=$((i+1)); done
URL="$(cat "$URLFILE" 2>/dev/null)"

test_start "R1 roundtrip: valid POST → server writes a file the shared validator ACCEPTS"
code="$(python3 "$CLIENT" POST "$URL/decision" "$(cat "$VALIDRESP")" "$URL")"
ok=1
[ "$code" = "200" ] || ok=0
[ -f "$RESP" ] || ok=0
python3 "$VALIDATE" "$BRIEF" "$RESP" >/dev/null 2>&1 || ok=0
if [ "$ok" = "1" ]; then test_pass; else test_fail "roundtrip failed (code=$code)"; fi

test_start "R2 one-artifact: server-written fields match the POSTED decision (real diff)"
if [ -f "$RESP" ] \
   && [ "$(jq -r '.option_label' "$RESP")" = "$(jq -r '.option_label' "$VALIDRESP")" ] \
   && [ "$(jq -r '.brief_nonce' "$RESP")" = "$NONCE" ] \
   && [ "$(jq -r '.assumptions|length' "$RESP")" = "$(jq -r '.assumptions|length' "$VALIDRESP")" ]; then
  test_pass
else
  test_fail "server-written file does not match the posted decision"
fi
kill "$SPID" 2>/dev/null; rm -rf "$SCRATCH"; rm -f "$CLIENT"

# ---- session-side constructs (the SAME logic the dev-plan T6 companion documents) ----
# watcher_ready RESP EXPECTED_NONCE → 0 iff a FRESH decision (nonce match) or a timeout sentinel is present.
watcher_ready() {
  local f="$1" nonce="$2" status got
  [ -f "$f" ] || return 1
  status="$(jq -r '.status // empty' "$f" 2>/dev/null)"
  got="$(jq -r '.brief_nonce // empty' "$f" 2>/dev/null)"
  if [ "$status" = "timeout" ]; then
    # nonce-aware (the server stamps brief_nonce into the sentinel): a STALE prior-gate timeout
    # sentinel (different/absent nonce) must NOT release — only a fresh one does, or a legacy
    # nonce-less gate (fail-open).
    [ -z "$nonce" ] && return 0
    [ "$got" = "$nonce" ] && return 0
    return 1
  fi
  [ -n "$nonce" ] && [ "$got" = "$nonce" ] && return 0
  return 1
}
# wait_for_decision RESP NONCE DEADLINE_EPOCH → 0 if ready, 1 if the deadline passed (abandoned tab).
wait_for_decision() {
  local f="$1" nonce="$2" deadline="$3"
  while true; do
    watcher_ready "$f" "$nonce" && return 0
    [ "$(date +%s)" -ge "$deadline" ] && return 1
    sleep 0.2
  done
}

# ---- R4: watcher IGNORES a pre-seeded stale-nonce file; fires on a fresh one (positive control) ----
SCRATCH2="$(mktemp -d)"; mkdir -p "$SCRATCH2/.dev-wiki"
SRESP="$SCRATCH2/.dev-wiki/decision-response.json"
cp "$FIX/decision-response.stalenonce.json" "$SRESP"
test_start "R4 staleness: watcher does NOT fire on a pre-seeded stale-nonce file"
if watcher_ready "$SRESP" "$NONCE"; then test_fail "watcher fired on a stale-nonce file"; else test_pass; fi
cp "$VALIDRESP" "$SRESP"
test_start "R4 positive-control: watcher DOES fire on a fresh-nonce decision"
if watcher_ready "$SRESP" "$NONCE"; then test_pass; else test_fail "watcher failed to fire on a fresh decision"; fi
# timeout-sentinel branch is nonce-aware too: a STALE prior-gate sentinel must NOT release
printf '{"status":"timeout","brief_nonce":"deadbeefdeadbeefdeadbeefdeadbeef"}' > "$SRESP"
test_start "R4 staleness: watcher does NOT fire on a stale-nonce TIMEOUT sentinel"
if watcher_ready "$SRESP" "$NONCE"; then test_fail "fired on a stale-nonce timeout sentinel (nonce-blind)"; else test_pass; fi
printf '{"status":"timeout","brief_nonce":"%s"}' "$NONCE" > "$SRESP"
test_start "R4 positive-control: watcher fires on a FRESH-nonce timeout sentinel"
if watcher_ready "$SRESP" "$NONCE"; then test_pass; else test_fail "did not fire on a fresh timeout sentinel"; fi
rm -rf "$SCRATCH2"

# ---- R5: the abandoned-tab wait RELEASES on its deadline (no hang) ----
EMPTY="$(mktemp -d)/decision-response.json"   # never created — simulates an abandoned tab
test_start "R5 abandoned-tab: wait_for_decision RELEASES on its deadline (no hang)"
start="$(date +%s)"; deadline=$((start + 3))
wait_for_decision "$EMPTY" "$NONCE" "$deadline"; released=$?
elapsed=$(( $(date +%s) - start ))
if [ "$released" = "1" ] && [ "$elapsed" -ge 2 ] && [ "$elapsed" -le 15 ]; then test_pass; else test_fail "deadline release misbehaved (released=$released elapsed=${elapsed}s)"; fi
test_start "R5 arithmetic positive-control: an already-passed deadline releases immediately"
wait_for_decision "$EMPTY" "$NONCE" "$(( $(date +%s) - 1 ))"; r=$?
if [ "$r" = "1" ]; then test_pass; else test_fail "already-passed deadline did not release"; fi

test_summary "dashboard-roundtrip"
