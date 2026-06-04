from dataclasses import dataclass
from datetime import date

from edge_screener.universe.membership import MembershipAction, MembershipTimeline


@dataclass(frozen=True)
class MembershipEligibility:
    """Decide which names are scorable (eligible to be held) at a point in time.

    A survivorship-corrected backtest must keep a name HELD through the moment
    its delisting return (the terminal "crater") is booked. The crater is
    injected by a separate reader at the next trading day on/after the name's
    removal date. ``MembershipTimeline.members_on(d)`` applies a REMOVE with
    effective_date ``d`` ON day ``d`` -- so the name has already dropped out of
    raw membership on the very day it left, which is exactly the day the crater
    is about to land. If we scored only raw members we would drop the name one
    step too early and silently omit the crater, re-introducing survivorship
    bias.

    Eligibility therefore equals current membership PLUS any name whose most
    recent removal (as known on ``as_of``, never looking ahead) takes effect ON
    ``as_of`` itself. That single extra step keeps the name held precisely for
    the rebalance at which its crater is booked, and no longer -- a name removed
    on an earlier date has already had its crater booked and is correctly gone.
    """

    timeline: MembershipTimeline

    def eligible_on(self, as_of: date) -> frozenset[str]:
        # Raw point-in-time membership (REMOVE at d takes effect on day d).
        members = self.timeline.members_on(as_of)

        # Names that left ON as_of: still held today so the reader can book the
        # delisting crater at the next trading day on/after the removal date.
        just_removed = set()
        for change in self.timeline.changes:
            if change.action is not MembershipAction.REMOVE:
                continue
            if change.effective_date != as_of:
                continue
            symbol = change.symbol
            # No-lookahead + most-recent-status guards: only retain the symbol
            # if, as known on as_of, its latest removal is this very day. This
            # excludes names that were removed today but subsequently (per the
            # most-recent status) re-added, and any whose recorded removal as of
            # today is actually an earlier date.
            if symbol in members:
                continue
            if self.timeline.removal_as_of(symbol, as_of) == as_of:
                just_removed.add(symbol)

        return members | frozenset(just_removed)
