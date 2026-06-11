#!/usr/bin/env bash
# drive-spike.sh — Phase 87 T1 GREEN: drive a minimal gate-bearing claude session
# non-interactively in a mktemp sandbox under the closed response policy, then
# collect artifacts into run/ for assert-spike.sh.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN="$DIR/run"
rm -rf "$RUN"
mkdir -p "$RUN"

SANDBOX="$(mktemp -d)"
# Pre-arm sandbox state: the globally-armed enforce-memory hook blocks the first
# Write unless .claude/.memory-consulted exists — pre-touch it (recorded as an
# arm-provisioning caveat in spike-record.md; the addendum must pin this for arms).
mkdir -p "$SANDBOX/.claude"
touch "$SANDBOX/.claude/.memory-consulted"

export SPIKE_SANDBOX="$SANDBOX"
export SPIKE_LOG="$RUN/response-log.txt"
export SPIKE_PROMPT='Call the AskUserQuestion tool exactly once: question "Spike gate: proceed?", header "Spike", with two options labeled "Proceed" and "Halt". After an answer is received, use the Write tool to create a file named STOP_MARKER in the current directory containing exactly: done
Then end your turn. Do nothing else: no other files, no other tools.'

: > "$SPIKE_LOG"
echo "sandbox: $SANDBOX" > "$RUN/sandbox-path.txt"

expect "$DIR/spike-driver.exp"
rc=$?

# Collect artifacts.
if [ -f "$SANDBOX/STOP_MARKER" ]; then
  # Normalize a single trailing newline away for the exact-content assertion.
  printf '%s' "$(cat "$SANDBOX/STOP_MARKER")" > "$RUN/STOP_MARKER"
fi
echo "expect-driven interactive CLI (pty): spike-driver.exp; claude --model haiku --permission-mode acceptEdits; closed policy = <Enter> on highlighted first option; expect rc=$rc" > "$RUN/mechanism.txt"

echo "drive-spike: done (expect rc=$rc; artifacts in $RUN)"
