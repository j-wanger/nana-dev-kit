#!/usr/bin/env python3
"""Phase 86 demand-evidence classifier (pre-registration: Admissibility, FROZEN).

Reads ONE candidate-row JSON, prints the classification on the last stdout line.
Closed enum: outcome-grade-admitted | rejected-gate-covered | ambiguous-downgrade |
consumption-grade-capped | inert | load-bearing.

Rules (pre-registered):
- outcome-candidate: requires a RE-EXECUTED deterministic gate against a recoverable
  pre-fix state. Unrecoverable -> ambiguous-downgrade (pinned direction; never upgrade).
  Gate exits 0 on pre-fix (it would have MISSED the defect) -> outcome-grade-admitted.
  Gate exits nonzero (it would have caught it) -> rejected-gate-covered.
- consumption-candidate: uses+citations > 0 -> consumption-grade-capped (supports
  cut-candidate/trim only; never keep for re-presentation-class); else inert.
- artifact: gate_referenced or citations >= 2 -> load-bearing;
  uses+citations == 0 -> inert; else consumption-grade-capped.

This tool reads ONLY the candidate row (blind: no expectations file).
"""
import json
import os
import subprocess
import sys


def classify(row, base="."):
    kind = row.get("kind", "")
    if kind == "outcome-candidate":
        re_exec = row.get("reexec") or {}
        if not re_exec.get("recoverable") or not re_exec.get("cmd"):
            # missing command must never mint a gate verdict
            return "ambiguous-downgrade"
        # reexec.dir resolves relative to the candidate row's own location
        cwd = os.path.normpath(os.path.join(base, re_exec.get("dir") or "."))
        try:
            proc = subprocess.run(
                re_exec["cmd"], shell=True,
                cwd=cwd,
                capture_output=True, timeout=300)
        except subprocess.TimeoutExpired:
            return "ambiguous-downgrade"
        return "outcome-grade-admitted" if proc.returncode == 0 else "rejected-gate-covered"
    if kind == "consumption-candidate":
        c = row.get("consumption") or {}
        used = (c.get("uses") or 0) + (c.get("citations") or 0)
        return "consumption-grade-capped" if used > 0 else "inert"
    if kind == "artifact":
        c = row.get("consumption") or {}
        uses, cites = (c.get("uses") or 0), (c.get("citations") or 0)
        if row.get("gate_referenced") or cites >= 2:
            return "load-bearing"
        if uses + cites == 0:
            return "inert"
        return "consumption-grade-capped"
    return "ambiguous-downgrade"


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: classify-evidence.py <candidate-row.json>", file=sys.stderr)
        sys.exit(2)
    with open(sys.argv[1]) as fh:
        row = json.load(fh)
    print(classify(row, base=os.path.dirname(os.path.abspath(sys.argv[1]))))
