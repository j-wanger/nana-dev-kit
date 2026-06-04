"""Membership eligibility for a survivorship-corrected S&P 500 backtest.

A name is *scorable* (eligible to be held) on a rebalance date if it is a
current index member, OR if it left the index on exactly that date. The second
case is the survivorship-bias correction: a name removed on day ``d`` is no
longer in ``members_on(d)`` (a REMOVE takes effect ON its effective date), but
the strategy must still HOLD it on ``d`` so that the delisting crater — booked
by the reader at the next trading day on/after the removal date — actually
lands on a held position. Drop it before its crater is booked and the terminal
loss silently vanishes, re-introducing exactly the survivorship bias this is
meant to correct. Keep it past its removal date and dead names linger in the
universe. The boundary is therefore: held through and including the removal
date, dropped strictly after it.
"""

from dataclasses import dataclass
from datetime import date

from edge_screener.universe.membership import MembershipAction, MembershipTimeline


@dataclass(frozen=True)
class MembershipEligibility:
    timeline: MembershipTimeline

    def eligible_on(self, as_of: date) -> frozenset[str]:
        # Current point-in-time members. A name removed strictly before as_of is
        # already absent here (its crater was booked on an earlier rebalance),
        # and a name removed exactly on as_of is also absent — we add it back
        # below so its crater can still be booked while it is held.
        members = self.timeline.members_on(as_of)

        # Names whose most-recent removal (as known on as_of, no lookahead) is
        # exactly as_of. These are no longer members but must remain held for
        # one more rebalance so the delisting return is booked on a held name.
        removed_today: set[str] = set()
        for change in self.timeline.changes:
            # No-lookahead: ignore any change effective after as_of.
            if change.effective_date > as_of:
                break
            if change.action is not MembershipAction.REMOVE:
                continue
            # Confirm this is the symbol's most recent membership event as of
            # as_of (it could have been re-added later, on/before as_of, in
            # which case it is already a current member and handled above).
            if self.timeline.removal_as_of(change.symbol, as_of) == as_of:
                removed_today.add(change.symbol)

        return frozenset(members | removed_today)
