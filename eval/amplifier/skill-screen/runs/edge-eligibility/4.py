"""Point-in-time scorable-universe selection for a survivorship-corrected backtest.

A name that LEAVES the index must still be held on the rebalance that coincides
with (or first follows) its removal, so that the delisting "crater" — booked by
the reader at the next trading day on/after the removal date — lands while the
name is still scored. Dropping it before then silently omits the terminal loss
and re-introduces survivorship bias; keeping it longer leaves dead names in the
universe. The boundary below holds a just-removed name for exactly the rebalance
on its removal date, then lets it fall off.
"""

from dataclasses import dataclass
from datetime import date

from edge_screener.universe.membership import MembershipAction, MembershipTimeline


@dataclass(frozen=True)
class MembershipEligibility:
    timeline: MembershipTimeline

    def eligible_on(self, as_of: date) -> frozenset[str]:
        # Current point-in-time members. `members_on` already applies every
        # change with effective_date <= as_of (no lookahead), and a REMOVE at
        # effective_date == as_of has ALREADY excluded the name here.
        members = self.timeline.members_on(as_of)

        # Names whose removal takes effect ON this exact day. They are gone from
        # `members_on(as_of)`, but their crater has not yet been booked, so they
        # must remain scorable for this one rebalance. We only consider REMOVEs
        # with effective_date == as_of (so no lookahead is introduced), and we
        # confirm via `removal_as_of` that this departure is the name's most
        # recent one as known on `as_of` (i.e. it was not re-added afterwards
        # and is not currently a member).
        just_removed = set()
        for change in self.timeline.changes:
            if change.effective_date != as_of:
                continue
            if change.action is not MembershipAction.REMOVE:
                continue
            symbol = change.symbol
            if symbol in members:
                # Re-added on the same day (ADD after REMOVE) — already counted.
                continue
            most_recent_removal = self.timeline.removal_as_of(symbol, as_of)
            if most_recent_removal == as_of:
                just_removed.add(symbol)

        return frozenset(members | just_removed)
