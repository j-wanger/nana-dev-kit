from dataclasses import dataclass
from datetime import date

from edge_screener.universe.membership import MembershipAction, MembershipTimeline


@dataclass(frozen=True)
class MembershipEligibility:
    """Decides which S&P 500 names are scorable (eligible to be held) at a
    given point in time, for a survivorship-corrected backtest.

    The subtlety: when a name leaves the index, its delisting crater (the
    terminal loss a survivorship-biased backtest silently omits) is booked by
    a separate reader at the next trading day on or after the name's removal
    date. For that crater to be booked, the name must STILL be held — and
    therefore eligible — at the rebalance that covers that day.

    A REMOVE with effective_date == d takes effect ON day d, so
    `timeline.members_on(d)` already excludes a name removed at d. But the
    crater for that name lands on the next trading day on/after d, which is the
    rebalance happening on d itself. So on the rebalance date d we must KEEP a
    name removed exactly at d: dropping it here is precisely the survivorship
    bias we are correcting (the crater would never be booked).

    A name removed strictly before `as_of` already had its crater booked at a
    prior trading day; keeping it would leave a dead name in the universe. So
    the boundary is exactly: keep current members, plus names whose most-recent
    known removal (as of `as_of`) falls on `as_of` itself.
    """

    timeline: MembershipTimeline

    def eligible_on(self, as_of: date) -> frozenset[str]:
        # Current members as of `as_of` (a REMOVE at == as_of is already
        # excluded by members_on, per its no-lookahead, on-the-day semantics).
        members = self.timeline.members_on(as_of)

        # Names removed exactly on `as_of`: still held so the reader can book
        # their delisting crater at the next trading day on/after the removal
        # date (which is the rebalance landing on `as_of`). This grants exactly
        # one extra rebalance of life past plain membership — no more, no less.
        # Using removal_as_of keeps this point-in-time (no lookahead) and
        # picks the MOST RECENT removal known on as_of, so a name later re-added
        # then removed again is governed by its latest known exit.
        just_removed = {
            change.symbol
            for change in self.timeline.changes
            if change.action == MembershipAction.REMOVE
            and change.effective_date <= as_of
            and change.symbol not in members
            and self.timeline.removal_as_of(change.symbol, as_of) == as_of
        }

        return frozenset(members | just_removed)
