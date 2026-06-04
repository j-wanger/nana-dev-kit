#!/usr/bin/env bash
# selftest-chatty.sh — a deliberately NON-CONFORMING harness (violates the PASS|FAIL:<id> contract).
# Used by check.sh --selftest to prove run_check fails CLOSED on a harness that does not speak the
# contract (guards against an LLM-ish chatty harness silently passing).
echo "Looks correct to me, I'd say this passes."
