#!/usr/bin/env bash
# Controls-first tests for the ephemeral decision-server (scripts/decision-server.py). Phase 106.
# Every case boots the server in a mktemp -d scratch .dev-wiki (NEVER the live one) and drives it
# over loopback. The whole script is meant to run under `timeout` (see the Makefile / task) so an
# off-thread-shutdown deadlock manifests as a FAILURE, never a hang.
#
# S1  GET / serves 200 + live brief + a <form>
# S2  valid POST → 200 + schema-valid file in .dev-wiki + no leftover mkstemp tmp
# S3  after the accepted decision the server EXITS (process gone) — binds exit-to-write
# S3b watchdog with NO POST → {status:timeout} sentinel + exit
# S4  malformed / bad-position / wrong-Origin / wrong-Host POST → non-2xx + NO write + server up
# S4lat two back-to-back valid POSTs → exactly one write + 409 (single-accept latch)
# S5  binds 127.0.0.1 (source) and never 0.0.0.0
# S6  wrong path / traversal → non-2xx
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
set +e  # MUST follow the source: helpers.sh does `set -euo pipefail`, so errexit is on after it.
        # This test drives a server and checks exit codes MANUALLY everywhere — an expected
        # non-zero (kill of an exited server, a 4xx probe) must never abort the run. The portable
        # self-watchdog below bounds total runtime in place of the (macOS-absent) `timeout`.
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SERVER="$REPO_ROOT/scripts/decision-server.py"
VALIDATOR="$REPO_ROOT/scripts/validate-decision-response.py"
FIX="$SCRIPT_DIR/fixtures"
BRIEF="$FIX/dashboard-brief.valid.json"
STATE="$FIX/dashboard-current-state.md"
VALIDRESP="$FIX/decision-response.valid.json"
# The served brief's phase — injected as --active-phase so the stale-gate guard (Phase 107) sees a
# FRESH gate by construction (decoupled from the live active-phase.md, which advances each phase).
BRIEFPHASE="$(python3 -c "import json; print(json.load(open('$BRIEF'))['phase'])")"

# Portable self-watchdog (macOS has no GNU `timeout`): hard-kill this script if it overruns, so a
# server-shutdown DEADLOCK surfaces as a failed run rather than a hang.
MAIN_PID=$$
# Redirect the watchdog's fds so its (orphaned) sleep never holds an inherited stdout open —
# otherwise a piped reader of this script would block on a never-closing pipe.
( sleep 200; kill -9 "$MAIN_PID" 2>/dev/null ) >/dev/null 2>&1 &
WATCHDOG_PID=$!
trap 'kill "$WATCHDOG_PID" 2>/dev/null' EXIT

echo "=== Ephemeral Decision-Server Tests ==="

# HTTP client via http.client (full control over the Host header). Args: METHOD URL [BODY] [ORIGIN] [HOST]
# Prints: first line = status code (or ERR), remaining lines = body.
CLIENT="$(mktemp)"
cat > "$CLIENT" <<'PY'
import sys, http.client
from urllib.parse import urlparse
method, url = sys.argv[1], sys.argv[2]
body = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] != "" else None
origin = sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] != "" else None
host = sys.argv[5] if len(sys.argv) > 5 and sys.argv[5] != "" else None
u = urlparse(url)
headers = {}
if origin: headers["Origin"] = origin
if host: headers["Host"] = host
if body is not None: headers["Content-Type"] = "application/json"
try:
    conn = http.client.HTTPConnection(u.hostname, u.port, timeout=5)
    conn.request(method, u.path or "/", body=(body.encode() if body else None), headers=headers)
    r = conn.getresponse()
    sys.stdout.write(str(r.status) + "\n" + r.read().decode("utf-8", "replace"))
except Exception as e:
    sys.stdout.write("ERR\n%s" % e)
PY
req()  { python3 "$CLIENT" "$@"; }
code() { python3 "$CLIENT" "$@" | head -1; }

boot() {  # boot <timeout-seconds> [active-phase] ; sets SCRATCH RESP URLFILE URL PID
  SCRATCH="$(mktemp -d)"; mkdir -p "$SCRATCH/.dev-wiki"
  RESP="$SCRATCH/.dev-wiki/decision-response.json"
  URLFILE="$SCRATCH/.dev-wiki/.decision-server.url"
  python3 "$SERVER" --brief "$BRIEF" --state "$STATE" --response "$RESP" --timeout "$1" \
      --active-phase "${2:-$BRIEFPHASE}" >/dev/null 2>"$SCRATCH/err.txt" &
  PID=$!
  disown "$PID" 2>/dev/null  # suppress async "Terminated" job-control noise when we kill it
  local i=0
  while [ ! -s "$URLFILE" ] && kill -0 "$PID" 2>/dev/null && [ $i -lt 50 ]; do sleep 0.1; i=$((i+1)); done
  URL="$(cat "$URLFILE" 2>/dev/null)"
  HOSTHDR="${URL#http://}"
}
wait_exit() { local i=0; while kill -0 "$PID" 2>/dev/null && [ $i -lt 60 ]; do sleep 0.1; i=$((i+1)); done; }
teardown() { [ -n "${PID:-}" ] && kill "$PID" 2>/dev/null; PID=""; [ -n "${SCRATCH:-}" ] && rm -rf "$SCRATCH"; }

# ---- S5: source binds 127.0.0.1, never 0.0.0.0 ----
test_start "S5: binds 127.0.0.1 (source) and never 0.0.0.0"
if grep -q '"127.0.0.1"' "$SERVER" && ! grep -q '0\.0\.0\.0' "$SERVER"; then test_pass; else test_fail "must bind 127.0.0.1, never 0.0.0.0"; fi

# ---- S1: GET / serves the interactive dashboard ----
boot 30
test_start "S1: GET / → 200 + live brief content + a <form>"
out="$(req GET "$URL/")"
if [ "$(echo "$out" | head -1)" = "200" ] && echo "$out" | grep -q "Pick Option B for the test" && echo "$out" | grep -qi '<form'; then
  test_pass
else
  test_fail "GET / did not serve the interactive dashboard"
fi
teardown

# ---- S6: wrong path / traversal → non-2xx ----
boot 30
test_start "S6: wrong path (GET /secret) → non-2xx"
if [ "$(code GET "$URL/secret")" != "200" ]; then test_pass; else test_fail "wrong path served 200"; fi
test_start "S6: traversal (GET /../etc/passwd) → non-2xx"
if [ "$(code GET "$URL/../etc/passwd")" != "200" ]; then test_pass; else test_fail "traversal served 200"; fi
teardown

# ---- S4: bad POSTs → non-2xx + NO write + server stays up ----
boot 30
test_start "S4a: malformed-JSON POST → non-2xx, no write"
c="$(code POST "$URL/decision" '{ not json' "$URL" "$HOSTHDR")"
if [ "$c" != "200" ] && [ ! -f "$RESP" ]; then test_pass; else test_fail "malformed POST mishandled (code=$c, wrote=$( [ -f "$RESP" ] && echo yes || echo no))"; fi
test_start "S4b: bad-position POST → non-2xx, no write"
c="$(code POST "$URL/decision" "$(cat "$FIX/decision-response.badposition.json")" "$URL" "$HOSTHDR")"
if [ "$c" != "200" ] && [ ! -f "$RESP" ]; then test_pass; else test_fail "bad-position accepted (code=$c)"; fi
test_start "S4c: wrong-Origin POST → 403, no write"
c="$(code POST "$URL/decision" "$(cat "$VALIDRESP")" "http://evil.example" "$HOSTHDR")"
if [ "$c" = "403" ] && [ ! -f "$RESP" ]; then test_pass; else test_fail "wrong Origin not rejected (code=$c)"; fi
test_start "S4d: wrong-Host POST → 403, no write"
c="$(code POST "$URL/decision" "$(cat "$VALIDRESP")" "$URL" "evil.example:1234")"
if [ "$c" = "403" ] && [ ! -f "$RESP" ]; then test_pass; else test_fail "wrong Host not rejected (code=$c)"; fi
test_start "S4e: server still up after the bad POSTs"
if kill -0 "$PID" 2>/dev/null; then test_pass; else test_fail "server died on a bad POST"; fi
teardown

# ---- S2 + S4lat + S3: valid POST writes a schema-valid file, latch, then the server exits ----
boot 30
test_start "S2: valid POST → 200 + schema-valid file in .dev-wiki + no leftover tmp"
c="$(code POST "$URL/decision" "$(cat "$VALIDRESP")" "$URL" "$HOSTHDR")"
ok=1
[ "$c" = "200" ] || ok=0
[ -f "$RESP" ] || ok=0
[ "$(basename "$(dirname "$RESP")")" = ".dev-wiki" ] || ok=0
python3 "$VALIDATOR" "$BRIEF" "$RESP" >/dev/null 2>&1 || ok=0
ls "$SCRATCH/.dev-wiki/".decision-*.tmp >/dev/null 2>&1 && ok=0
if [ "$ok" = "1" ]; then test_pass; else test_fail "valid POST did not produce a schema-valid file (code=$c)"; fi

# S4lat: single-accept latch — IN-PROCESS with post-accept shutdown SUPPRESSED. A network 2nd-POST
# always races the off-thread shutdown and gets connection-refused (ERR), never 409 — so the old
# `409 || ERR` network check was a DEAD INSTRUMENT (removing the latch left it green; the ERR is
# already what S3 asserts). Keeping the listener up exposes the latch: correct code → 409, no latch
# → 200 (mutation-checked). This requires its own in-process server, independent of the network one.
test_start "S4lat: 2nd POST after an accepted decision → exactly 409 (single-accept latch)"
c2lat="$(python3 - "$SERVER" "$BRIEF" "$STATE" "$VALIDRESP" "$BRIEFPHASE" <<'PY'
import importlib.util, tempfile, os, sys, threading, http.client
from urllib.parse import urlparse
server, brief, state, validresp, ap = sys.argv[1:6]
spec = importlib.util.spec_from_file_location("ds", server)
ds = importlib.util.module_from_spec(spec); spec.loader.exec_module(ds)
ds.DecisionServer.shutdown_async = lambda self: None  # keep the listener up so the latch is reachable
scratch = tempfile.mkdtemp(); os.makedirs(os.path.join(scratch, ".dev-wiki"), exist_ok=True)
resp = os.path.join(scratch, ".dev-wiki", "decision-response.json")
# Inject active-phase == the served brief phase so the stale-gate guard sees a fresh gate; without it
# the latch test would pass for the wrong reason -- a stale 409 fired before the latch is reached.
srv = ds.DecisionServer(brief, state, resp, 30, ap)
threading.Thread(target=srv.serve_forever, kwargs={"poll_interval": 0.05}, daemon=True).start()
u = urlparse(srv.url); host = "%s:%d" % (u.hostname, u.port)
body = open(validresp, "rb").read()
def post():
    c = http.client.HTTPConnection(u.hostname, u.port, timeout=5)
    c.request("POST", "/decision", body=body,
              headers={"Origin": srv.url, "Host": host, "Content-Type": "application/json"})
    return c.getresponse().status
post()           # first accept → sets the latch (shutdown suppressed)
print(post())    # second POST → must be 409
srv.shutdown(); srv.server_close()
PY
)"
if [ "$c2lat" = "409" ]; then test_pass; else test_fail "latch did not return 409 on the 2nd accept (got '$c2lat')"; fi

test_start "S3: server exits after the accepted decision (no off-thread-shutdown deadlock)"
wait_exit
if ! kill -0 "$PID" 2>/dev/null; then test_pass; else test_fail "server did not exit after accept (deadlock?)"; fi
teardown

# ---- S3b: watchdog with NO POST → timeout sentinel + exit ----
boot 1
test_start "S3b: watchdog (no POST) writes a {status:timeout} sentinel and exits"
wait_exit
ok=1
kill -0 "$PID" 2>/dev/null && ok=0
{ [ -f "$RESP" ] && grep -q '"status"' "$RESP" && grep -q 'timeout' "$RESP"; } || ok=0
if [ "$ok" = "1" ]; then test_pass; else test_fail "watchdog did not write a timeout sentinel + exit"; fi
teardown

# ---- S7: a STALE gate (served brief phase != active phase) → banner + NO form on GET, POST refused (Phase 107) ----
boot 30 999   # active-phase 999 != the brief's phase => the served gate is stale
test_start "S7a: GET / on a stale gate → served page shows the stale banner and NO <form>"
out="$(req GET "$URL/")"
if echo "$out" | grep -qi 'stale' && ! echo "$out" | grep -qi '<form'; then test_pass; else test_fail "stale gate must show a banner and no form"; fi
test_start "S7b: POST a valid decision to a stale gate → non-2xx + NO write (don't drive the wrong phase)"
c="$(code POST "$URL/decision" "$(cat "$VALIDRESP")" "$URL" "$HOSTHDR")"
if [ "$c" != "200" ] && [ ! -f "$RESP" ]; then test_pass; else test_fail "stale gate accepted a decision (code=$c, wrote=$( [ -f "$RESP" ] && echo yes || echo no))"; fi
teardown

rm -f "$CLIENT"
test_summary "decision-server"
