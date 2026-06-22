#!/usr/bin/env python3
"""Deterministic contract fidelity-check — did a worker's output honor its contract?

Reads a CONTRACT (outcome objectives + deterministic guardrails, each a shell command +
expected exit/stdout — reusing the kit's success:-criterion shape) and a worker-output
WORKDIR, runs every guardrail against the workdir, and emits a mechanical PASS/FAIL
fidelity verdict (per-guardrail detail + overall). Exit 0 iff every guardrail passed.

This is pillar-1 of the rung-C contract-driven-delegation program and the SCORING
INSTRUMENT for the Phase-100 contract-vs-spec screen — so it is purely deterministic
(no LLM, no network, no timestamps/ordering nondeterminism in its own output) and fails
LOUD on a malformed contract rather than scoring garbage (controls-first, HEU-012).

Usage:
    python3 scripts/check-fidelity.py --contract PATH --workdir PATH [--json]

Exit codes: 0 = all guardrails passed; 1 = one or more failed; 2 = usage / malformed
contract (fail loud, message on stderr).
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

GUARDRAIL_TIMEOUT = 30  # seconds; a guardrail command that hangs is a contract bug


def load_contract(path):
    """Read, parse, and validate a contract. Raise ValueError (caught in main → stderr +
    exit 2) on malformed JSON or a missing required field — never score garbage."""
    try:
        data = json.loads(Path(path).read_text())
    except FileNotFoundError:
        raise ValueError(f"contract not found: {path}")
    except json.JSONDecodeError as e:
        raise ValueError(f"malformed JSON in contract {path}: {e}")
    if not isinstance(data, dict):
        raise ValueError("contract must be a JSON object")
    guardrails = data.get("guardrails")
    if not isinstance(guardrails, list) or not guardrails:
        raise ValueError("contract missing/empty required field: guardrails (non-empty list)")
    for i, g in enumerate(guardrails):
        if not isinstance(g, dict) or not g.get("id") or not g.get("command"):
            raise ValueError(f"guardrail[{i}] missing required field: id and/or command")
    return data


def run_guardrail(g, workdir):
    """Run one guardrail command in the workdir. Returns (passed, reason). Deterministic
    given a deterministic command — no timestamps or wall-clock in the output."""
    try:
        proc = subprocess.run(
            g["command"], shell=True, cwd=workdir,
            capture_output=True, text=True, timeout=GUARDRAIL_TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        return False, f"timed out after {GUARDRAIL_TIMEOUT}s"
    expect_exit = g.get("expect_exit", 0)
    if proc.returncode != expect_exit:
        return False, f"exit {proc.returncode}, expected {expect_exit}"
    needle = g.get("expect_stdout_contains")
    if needle is not None and needle not in proc.stdout:
        return False, f"stdout missing expected substring {needle!r}"
    return True, "ok"


def main():
    ap = argparse.ArgumentParser(description="Deterministic contract fidelity-check.")
    ap.add_argument("--contract", required=True, help="path to the contract JSON")
    ap.add_argument("--workdir", required=True, help="path to the worker-output workdir")
    ap.add_argument("--json", action="store_true", help="emit a machine-readable JSON verdict")
    args = ap.parse_args()

    try:
        contract = load_contract(args.contract)
        workdir = Path(args.workdir)
        if not workdir.is_dir():
            raise ValueError(f"workdir not found or not a directory: {args.workdir}")
    except ValueError as e:
        print(f"check-fidelity: {e}", file=sys.stderr)
        return 2

    # Sorted by id → deterministic ordering regardless of contract authoring order.
    guardrails = sorted(contract["guardrails"], key=lambda g: g["id"])
    results = []
    for g in guardrails:
        passed, reason = run_guardrail(g, workdir)
        results.append({"id": g["id"], "passed": passed, "reason": reason,
                        "description": g.get("description", "")})

    n_pass = sum(1 for r in results if r["passed"])
    all_pass = n_pass == len(results)

    if args.json:
        print(json.dumps({"fidelity": "PASS" if all_pass else "FAIL",
                          "passed": n_pass, "total": len(results),
                          "guardrails": results}, indent=2, sort_keys=True))
    else:
        for r in results:
            tag = "PASS" if r["passed"] else "FAIL"
            desc = f" — {r['description']}" if r["description"] else ""
            detail = "" if r["passed"] else f" ({r['reason']})"
            print(f"[{tag}] {r['id']}{desc}{detail}")
        print(f"FIDELITY: {'PASS' if all_pass else 'FAIL'} ({n_pass}/{len(results)} guardrails passed)")

    return 0 if all_pass else 1


if __name__ == "__main__":
    sys.exit(main())
