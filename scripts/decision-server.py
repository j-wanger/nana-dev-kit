#!/usr/bin/env python3
"""Ephemeral act-from-page decision server (Phase 106).

Spun up by the /dev-plan direction gate ONLY at the decision moment (opt-in via a
.dev-wiki/act-from-page marker — see the dev-plan companion). It serves the LIVE dashboard
(interactive form) on 127.0.0.1, accepts exactly ONE validated decision POST, atomically writes
.dev-wiki/decision-response.json, then EXITS. It is NOT a daemon: it lives for the seconds/minutes
of one decision. The session-side orchestrator waits on the response file (a run_in_background
watcher — never a foreground sleep) and ingests it through the SAME deterministic validator.

Why a server at all: a file:// page is sandboxed and cannot write a repo file. Serving the page
from this loopback origin makes the form's same-origin POST trustworthy (Origin/Host checks) and
lets the page hand the decision back through a real channel — no clipboard, no browser FS API.

Correctness load-bearing points (each has a control in tests/test_decision_server.sh):
  * 127.0.0.1 + port-0 bind ONLY (never the all-interfaces wildcard) — the readback port goes to
    .decision-server.url.
  * POST guards: Origin == own loopback origin, Host allowlist, Content-Length cap, reject chunked,
    and a SINGLE-ACCEPT LATCH checked before the write (a 2nd POST gets 409, never a double write).
  * The decision is validated by validate-decision-response.py BEFORE it is committed; an invalid
    POST writes NOTHING and the server STAYS UP (the maintainer can fix + resubmit).
  * Atomic write: mkstemp(dir=.dev-wiki) -> fsync -> os.replace (same fs) — no torn reads.
  * THE SERVER OWNS THE SINGLE TIMEOUT: on watchdog expiry it writes a {"status":"timeout"}
    sentinel (same atomic path) and exits, so the session waits on ONE file condition and branches
    on contents (valid decision vs timeout) — no dual-deadline coupling.
  * Off-thread shutdown: HTTPServer is single-threaded, so the handler runs IN serve_forever's
    thread; calling shutdown() inline would DEADLOCK. Shutdown is always spawned on its own thread.
"""

import argparse
import importlib.util
import json
import os
import sys
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WIKI = ROOT / ".dev-wiki"
MAX_BODY = 256 * 1024  # a decision is a few KB; cap to refuse oversized POSTs
DEFAULT_TIMEOUT = 900  # 15 minutes — the server is the single source of the gate timeout


def _load_module(filename, modname):
    """Load a hyphen-named sibling script by path (a plain import is impossible)."""
    path = Path(__file__).with_name(filename)
    spec = importlib.util.spec_from_file_location(modname, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _read_nonce(brief_path):
    """Best-effort read of the brief's nonce (None for a legacy nonce-less or unreadable brief).
    Stamped into the timeout sentinel so the session watcher can reject a STALE prior-gate sentinel
    instead of releasing on it (the timeout branch was otherwise nonce-blind)."""
    try:
        return json.loads(Path(brief_path).read_text()).get("nonce")
    except (OSError, json.JSONDecodeError):
        return None


_dash = _load_module("generate-dashboard.py", "generate_dashboard")
_val = _load_module("validate-decision-response.py", "validate_decision_response")
render_dashboard = _dash.render_dashboard
build_panes = _dash.build_panes
validate = _val.validate


class DecisionServer(HTTPServer):
    def __init__(self, brief_path, state_path, response_path, timeout_s):
        # Bind loopback only (127.0.0.1), ephemeral port — never the all-interfaces wildcard;
        # this endpoint writes a repo file, so it must never be reachable off-host.
        super().__init__(("127.0.0.1", 0), DecisionHandler)
        self.brief_path = str(brief_path)
        self.brief_nonce = _read_nonce(self.brief_path)
        self.state_path = str(state_path)
        self.response_path = Path(response_path)
        self.url_path = self.response_path.parent / ".decision-server.url"
        self.lock = threading.Lock()
        self.accepted = False
        port = self.server_address[1]
        self.url = f"http://127.0.0.1:{port}"
        self.allowed_origins = {f"http://127.0.0.1:{port}", f"http://localhost:{port}"}
        self.allowed_hosts = {f"127.0.0.1:{port}", f"localhost:{port}"}
        self.watchdog = threading.Timer(timeout_s, self._on_timeout)
        self.watchdog.daemon = True

    # ---- helpers ----
    def origin_ok(self, origin):
        return origin in self.allowed_origins

    def host_ok(self, host):
        return host in self.allowed_hosts

    def render_page(self):
        panes = build_panes(self.state_path, self.brief_path)
        return render_dashboard(panes, interactive=True)

    def _atomic_write(self, text):
        """Write text to the response file atomically: temp in the SAME dir -> fsync -> os.replace."""
        d = str(self.response_path.parent)
        fd, tmp = tempfile.mkstemp(dir=d, prefix=".decision-", suffix=".tmp")
        try:
            with os.fdopen(fd, "w") as f:
                f.write(text)
                f.flush()
                os.fsync(f.fileno())
            os.replace(tmp, self.response_path)
        except BaseException:
            try:
                os.unlink(tmp)
            except OSError:
                pass
            raise

    def handle_decision(self, body):
        """Parse -> validate against the brief -> commit atomically. Returns (ok, message).
        On any failure NOTHING is written (the temp is removed) so the maintainer can resubmit."""
        try:
            parsed = json.loads(body.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as e:
            return False, f"malformed JSON: {e}"
        d = str(self.response_path.parent)
        fd, tmp = tempfile.mkstemp(dir=d, prefix=".decision-", suffix=".tmp")
        try:
            with os.fdopen(fd, "w") as f:
                json.dump(parsed, f)
                f.flush()
                os.fsync(f.fileno())
            errors = validate(self.brief_path, tmp)
            if errors:
                os.unlink(tmp)
                return False, "; ".join(errors)
            os.replace(tmp, self.response_path)  # atomic commit
            return True, ""
        except BaseException:
            try:
                os.unlink(tmp)
            except OSError:
                pass
            raise

    def shutdown_async(self):
        """Shut down from a SEPARATE thread — calling shutdown() inside a handler (which runs in
        serve_forever's thread for a single-threaded HTTPServer) deadlocks."""
        threading.Thread(target=self.shutdown, daemon=True).start()

    def _on_timeout(self):
        """Watchdog: if no decision landed, write a timeout sentinel and exit. The session reads
        ONE file and branches on {status:timeout} vs a real decision — single timeout authority."""
        with self.lock:
            if self.accepted:
                return
            self._atomic_write(json.dumps({"status": "timeout", "brief_nonce": self.brief_nonce}))
            self.accepted = True
        self.shutdown_async()

    def start(self):
        self.url_path.write_text(self.url + "\n")
        print(self.url, flush=True)
        self.watchdog.start()
        try:
            self.serve_forever(poll_interval=0.2)
        finally:
            self.watchdog.cancel()
            try:
                self.url_path.unlink()
            except OSError:
                pass


class DecisionHandler(BaseHTTPRequestHandler):
    # Per-connection socket timeout. socketserver.StreamRequestHandler.setup() calls
    # connection.settimeout(self.timeout), so a stalled request line / header / body read raises
    # socket.timeout inside handle_one_request, drops the connection, and RELEASES self.server.lock
    # on the exception path. Without it a slow/dropped client (adversarial slow-loris OR just a
    # flaky browser) would block do_POST's rfile.read WHILE HOLDING the lock on this single-threaded
    # server — which also deadlocks the watchdog (_on_timeout contends on the same lock), defeating
    # the "server owns the single timeout" invariant and leaking the process. 30s >> a real loopback
    # POST (<<1s), << DEFAULT_TIMEOUT (900s).
    timeout = 30

    # Silence the default stderr access log (keeps test output clean).
    def log_message(self, *args):
        pass

    def _respond(self, code, text, ctype="text/plain; charset=utf-8"):
        body = text.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path not in ("/", "/index.html"):
            self._respond(404, "not found")
            return
        try:
            html = self.server.render_page()
        except Exception as e:  # a malformed live brief shouldn't crash the handler
            self._respond(500, f"render error: {e}")
            return
        self._respond(200, html, ctype="text/html; charset=utf-8")

    def do_POST(self):
        if self.path.split("?", 1)[0] != "/decision":
            self._respond(404, "not found")
            return
        # CSRF / loopback guards (cheap, entropy-independent — defense in depth with the nonce).
        if not self.server.origin_ok(self.headers.get("Origin")):
            self._respond(403, "bad Origin")
            return
        if not self.server.host_ok(self.headers.get("Host", "")):
            self._respond(403, "bad Host")
            return
        if "chunked" in self.headers.get("Transfer-Encoding", "").lower():
            self._respond(400, "chunked transfer not accepted")
            return
        try:
            length = int(self.headers.get("Content-Length", ""))
        except ValueError:
            self._respond(411, "Content-Length required")
            return
        if length <= 0 or length > MAX_BODY:
            self._respond(413, "empty or oversized body")
            return

        already = False
        ok = False
        msg = ""
        with self.server.lock:
            if self.server.accepted:
                already = True
            else:
                body = self.rfile.read(length)
                ok, msg = self.server.handle_decision(body)
                if ok:
                    self.server.accepted = True
                    self.server.watchdog.cancel()

        if already:
            self._respond(409, "a decision was already accepted")
        elif ok:
            self._respond(200, "Decision received.")
            self.server.shutdown_async()  # off-thread — deadlock-safe
        else:
            self._respond(400, msg)


def main():
    parser = argparse.ArgumentParser(description="Ephemeral act-from-page decision server (Phase 106).")
    parser.add_argument("--brief", default=str(WIKI / "direction-brief.json"))
    parser.add_argument("--state", default=str(WIKI / "_CURRENT_STATE.md"))
    parser.add_argument("--response", default=str(WIKI / "decision-response.json"))
    parser.add_argument("--timeout", type=float, default=DEFAULT_TIMEOUT,
                        help="seconds before the server writes a {status:timeout} sentinel and exits")
    args = parser.parse_args()

    if not Path(args.brief).exists():
        print(f"Error: direction brief not found: {args.brief}", file=sys.stderr)
        sys.exit(1)

    srv = DecisionServer(args.brief, args.state, args.response, args.timeout)
    srv.start()


if __name__ == "__main__":
    main()
