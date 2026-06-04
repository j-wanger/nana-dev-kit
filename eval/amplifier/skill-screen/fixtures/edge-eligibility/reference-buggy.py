"""PLANTED-BUGGY eligibility — the naive re-derivation that silently re-introduces survivorship bias.

eligible_on = members_on(as_of). Because members_on discards a name ON its removal date d, the name is
dropped at d — so the position is no longer held when the delisting crater books, and the loss is never
captured (the survivorship leak). Passes the basic assertions (quiet-date, not-yet-added, re-added) but
FAILS inclusive-through-d. Used only by check.sh's per-candidate selftest to prove the harness discriminates.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date

from edge_screener.universe.membership import MembershipTimeline


@dataclass(frozen=True)
class MembershipEligibility:
    timeline: MembershipTimeline

    def eligible_on(self, as_of: date) -> frozenset[str]:
        effective = max(as_of, self.timeline.start_date)
        return frozenset(self.timeline.members_on(effective))  # BUG: no removed-today add-back
