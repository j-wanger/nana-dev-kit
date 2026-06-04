"""The inclusive-through-d eligibility policy — the survivorship ordering contract.

The bare engine, via its F2 decision lag, sells a name flat the moment its target weight goes to zero.
For a delisted name that is the survivorship leak: it is liquidated at the last pre-crater price before
the :mod:`~edge_screener.survivorship.reader` terminal crater can book. The fix lives here, not in the
engine: a removed name stays eligible (scorable, and therefore held) INCLUSIVE THROUGH its removal date
d, and is dropped only at the first rebalance STRICTLY AFTER d. The crater (injected at the next trading
day on-or-after d) then books while the position is still held; the next rebalance sells the already
cratered position.

This is the sole scoring gate. The engine's holdable universe is ``ever_members()`` (a superset), but no
signal or weight-normalization path may consume it — only :meth:`eligible_on` decides what is scored.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date

from edge_screener.universe.membership import MembershipAction, MembershipTimeline


@dataclass(frozen=True)
class MembershipEligibility:
    """Point-in-time scoring eligibility derived from a membership timeline (inclusive-through-d)."""

    timeline: MembershipTimeline

    def eligible_on(self, as_of: date) -> frozenset[str]:
        """Names scorable at ``as_of``: members at ``as_of`` plus any removed effective exactly at ``as_of``.

        A name removed at d is excluded by ``members_on(d)`` (removal is inclusive there), so it is added
        back on that single day — it must stay held through d for its crater to book. A name removed at
        d < as_of stays dropped; a name not yet added is absent; a re-added name reappears.
        """
        # Before the timeline baseline, membership is unknown (the changes log does not reach back). Use
        # the EARLIEST known membership (the baseline) as the best available estimate rather than crash or
        # hold cash — those names were in the index then; only changes within the brief pre-baseline gap
        # are unobservable (covered by the survivorship caveat). On/after the baseline this is a no-op.
        effective = max(as_of, self.timeline.start_date)
        members: set[str] = set(self.timeline.members_on(effective))
        removed_today = {
            change.symbol
            for change in self.timeline.changes
            if change.effective_date == as_of and change.action is MembershipAction.REMOVE
        }
        return frozenset(members | removed_today)
