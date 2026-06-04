"""Guarded driver for the edge-screener eligibility candidate — NO pytest, NO LLM.

Imports MembershipEligibility from the swapped-in module (A' = the OFF re-derivation, placed at
edge_screener/survivorship/eligibility.py) and the FROZEN real membership dependency, then runs the
PRE-REGISTERED spec-implied assertions in order. Prints exactly PASS or FAIL:<assertion-id> (the first
failing assertion = the consensus key). Any exception → FAIL:EXC-<Type> (A' did not conform).

Spec-implied (count toward the verdict): quiet-date, not-yet-added, re-added (basic PIT correctness)
and inclusive-through-d + superset-same-day (the survivorship crux — HAS-HEADROOM signal).
NOT here (unstated-edge → tracked as SPEC-INCOMPLETE in T3, never headroom): before-baseline-returns-baseline.
"""

import sys
from datetime import date, timedelta

from edge_screener.universe.membership import MembershipAction, MembershipChange, MembershipTimeline
from edge_screener.survivorship.eligibility import MembershipEligibility

BASE = date(2010, 1, 1)


def _add(d: int, s: str) -> MembershipChange:
    return MembershipChange(BASE + timedelta(days=d), MembershipAction.ADD, s)


def _rem(d: int, s: str) -> MembershipChange:
    return MembershipChange(BASE + timedelta(days=d), MembershipAction.REMOVE, s)


def _fail(cid: str) -> None:
    print(f"FAIL:{cid}")
    sys.exit(0)


def _set(x: object) -> set:
    return set(x)  # tolerate frozenset/set/list returns


try:
    e = MembershipEligibility(
        MembershipTimeline((_add(0, "AAA"), _add(0, "BBB"), _add(100, "CCC"), _rem(200, "BBB"), _add(300, "BBB")))
    )
    # --- basics (any competent impl) ---
    if _set(e.eligible_on(BASE + timedelta(days=150))) != {"AAA", "BBB", "CCC"}:
        _fail("quiet-date")
    if "CCC" in _set(e.eligible_on(BASE + timedelta(days=99))):
        _fail("not-yet-added")
    if "CCC" not in _set(e.eligible_on(BASE + timedelta(days=100))):
        _fail("not-yet-added")
    if "BBB" in _set(e.eligible_on(BASE + timedelta(days=250))):
        _fail("re-added")
    if "BBB" not in _set(e.eligible_on(BASE + timedelta(days=300))):
        _fail("re-added")
    # --- inclusive-through-d (THE survivorship crux — held THROUGH removal date, dropped strictly after) ---
    if "BBB" not in _set(e.eligible_on(BASE + timedelta(days=199))):
        _fail("inclusive-through-d")
    if "BBB" not in _set(e.eligible_on(BASE + timedelta(days=200))):
        _fail("inclusive-through-d")
    if "BBB" in _set(e.eligible_on(BASE + timedelta(days=201))):
        _fail("inclusive-through-d")
    # --- superset-same-day (#6 corollary: eligible exceeds members ONLY by same-day removals) ---
    m = _set(e.timeline.members_on(BASE + timedelta(days=200)))
    el = _set(e.eligible_on(BASE + timedelta(days=200)))
    if (el - m) != {"BBB"} or (m - el) != set():
        _fail("superset-same-day")
except SystemExit:
    raise
except Exception as exc:  # noqa: BLE001 — any nonconformance is a fail, deterministically
    print(f"FAIL:EXC-{type(exc).__name__}")
    sys.exit(0)

print("PASS")
