#!/usr/bin/env python3
"""Deterministic boundary validator for an act-from-page decision response (Phase 106).

ONE validator, RUN by BOTH the ephemeral decision-server's POST path AND the dev-plan
ingest step — so the server and the gate cannot drift, and the ingest stays a deterministic
check rather than an LLM eyeballing nonce / coverage / position (the kit's "deterministic
validators at boundaries over neural judges" posture).

A "decision response" is what the served dashboard writes to .dev-wiki/decision-response.json:
the maintainer's option pick + a position on every assumption + optional notes, echoing the
brief's phase and (when present) its nonce. This script answers ONE question deterministically:
does the response faithfully + completely answer THIS brief's gate?

    validate(brief_path, response_path) -> list[str]   # [] == valid; each str is a violation
    CLI: validate-decision-response.py <brief.json> <response.json>
         exit 0 = valid; exit 1 = invalid (reasons on stderr) or unreadable; exit 2 = usage.
"""

import json
import sys
from pathlib import Path

# The three positions the assumption gate accepts — EXACT membership. Rejects '', 'unknown',
# and apostrophe-corrupted variants ("dont-know" / "don’t-know"). Pinned as the single literal
# source so the server and the ingest validate against the same constant.
VALID_POSITIONS = ("accept", "reject", "don't-know")


def _load(path):
    """Read + parse JSON; raise ValueError (caught in main -> stderr + exit 1) on a missing
    file or malformed JSON. Fails loud — never returns a partial/garbage object."""
    p = Path(path)
    if not p.exists():
        raise ValueError(f"file not found: {path}")
    try:
        return json.loads(p.read_text())
    except json.JSONDecodeError as e:
        raise ValueError(f"malformed JSON in {path}: {e}")


def validate(brief_path, response_path):
    """Return a list of human-readable violation strings ([] = the response faithfully and
    completely answers the brief's gate). Checks, in order:
      - phase echo (the response answers the SAME phase the brief posed);
      - option_label is one of the brief's options (no phantom option);
      - 1:1 assumption coverage (every brief assumption gets exactly one position, no extras);
      - exact position membership against VALID_POSITIONS (no '', 'unknown', no silent skip);
      - brief_nonce echo, ONLY when the brief carries a nonce (legacy nonce-less briefs skip
        the staleness check — the guard fails OPEN rather than fail-closed on old briefs).
    """
    brief = _load(brief_path)
    resp = _load(response_path)
    errors = []

    # phase echo
    if resp.get("phase") != brief.get("phase"):
        errors.append(f"phase mismatch: brief={brief.get('phase')!r} response={resp.get('phase')!r}")

    # option_label is one of the brief's option labels
    labels = {o.get("label") for o in brief.get("options", []) if isinstance(o, dict)}
    chosen = resp.get("option_label")
    if chosen not in labels:
        known = sorted(label for label in labels if label)
        errors.append(f"option_label {chosen!r} is not one of the brief options {known}")

    # 1:1 assumption coverage + exact position membership
    brief_ids = [a.get("id") for a in brief.get("assumptions", []) if isinstance(a, dict) and a.get("id")]
    resp_items = resp.get("assumptions")
    if not isinstance(resp_items, list):
        errors.append("response 'assumptions' must be a list")
        resp_items = []
    resp_by_id = {}
    for i, a in enumerate(resp_items):
        if not isinstance(a, dict) or not a.get("id"):
            errors.append(f"response assumption[{i}] missing id")
            continue
        aid = a["id"]
        if aid in resp_by_id:
            errors.append(f"response assumption {aid} appears more than once")
        resp_by_id[aid] = a
    for bid in brief_ids:
        if bid not in resp_by_id:
            errors.append(f"assumption {bid} has no position (the gate requires a position on every assumption)")
            continue
        pos = resp_by_id[bid].get("position")
        if pos not in VALID_POSITIONS:
            errors.append(f"assumption {bid} has invalid position {pos!r} (must be one of {list(VALID_POSITIONS)})")
    for rid in resp_by_id:
        if rid not in brief_ids:
            errors.append(f"response covers unknown assumption {rid!r} (not in the brief)")

    # brief_nonce echo — only when the brief carries a nonce (legacy briefs skip; fail-open)
    brief_nonce = brief.get("nonce")
    if brief_nonce:
        if resp.get("brief_nonce") != brief_nonce:
            errors.append("brief_nonce mismatch (stale/foreign/replayed response — does not match the current brief)")

    return errors


def main(argv):
    if len(argv) != 3:
        print(f"usage: {Path(argv[0]).name} <brief.json> <response.json>", file=sys.stderr)
        return 2
    try:
        errors = validate(argv[1], argv[2])
    except ValueError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    if errors:
        print("decision-response REJECTED:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
