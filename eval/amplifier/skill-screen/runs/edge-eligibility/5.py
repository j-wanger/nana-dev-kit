from dataclasses import dataclass
from datetime import date

from edge_screener.universe.membership import MembershipAction, MembershipTimeline


@dataclass(frozen=True)
class MembershipEligibility:
    """Decide which names are scorable (eligible to be held) at a point in time.

    Survivorship-bias correction: when a name is REMOVED from the index, its
    delisting return (the terminal "crater") must still be booked. The crater is
    injected by the reader at the next trading day on or after the name's removal
    date. For it to be booked, the name must still be HELD — and therefore scored
    / eligible — at the rebalance where the crater lands.

    `timeline.members_on(d)` already EXCLUDES a name removed exactly on day d
    (a REMOVE with effective_date == d takes effect ON day d). If eligibility were
    just `members_on(as_of)`, a name removed on or before the rebalance date would
    be dropped *before* its crater could be booked — silently re-introducing the
    exact survivorship bias this is meant to correct.

    The fix is a one-step grace boundary: a freshly-removed name stays eligible
    through the first rebalance on or after its removal date (so the crater lands
    while it is still held), then drops once membership advances past it. Concretely:

        eligible_on(as_of) = members_on(as_of)
                             ∪ { names whose most-recent removal as known on as_of
                                 happened on the latest removal date that is
                                 <= as_of and is not earlier than the most recent
                                 ADD bringing membership current }

    Equivalently, and the form implemented below: current members, plus every name
    that was a member immediately *before* the latest membership-change date that
    is <= as_of and was removed on that date. That is exactly the just-departed
    cohort whose crater has not yet had a chance to be booked. It is no-lookahead
    (it only ever inspects changes with effective_date <= as_of) and books the
    crater exactly once: the cohort is eligible at the first rebalance on/after the
    removal date and gone at the next one.
    """

    timeline: MembershipTimeline

    def eligible_on(self, as_of: date) -> frozenset[str]:
        # Names that are still index members as of `as_of`.
        current = self.timeline.members_on(as_of)

        # Effective dates of all changes that have taken effect by `as_of`
        # (no-lookahead: anything after `as_of` is ignored).
        effective_dates = sorted(
            {
                ch.effective_date
                for ch in self.timeline.changes
                if ch.effective_date <= as_of
            }
        )
        if not effective_dates:
            # Nothing has happened yet past the baseline; only the current
            # membership is scorable.
            return current

        # The most recent membership-change date on or before `as_of`. Any name
        # removed on this date is the "just-departed" cohort: it left the index
        # but its delisting crater lands at the first rebalance on/after this
        # date — i.e. potentially THIS rebalance. It must stay held so the crater
        # can be booked. By the next change date, membership has advanced and the
        # cohort is no longer carried (the crater has been booked by then).
        last_change_date = effective_dates[-1]

        # Names removed exactly on the latest change date, as known on `as_of`.
        just_removed: set[str] = set()
        for ch in self.timeline.changes:
            if ch.effective_date != last_change_date:
                continue
            if ch.action is not MembershipAction.REMOVE:
                continue
            symbol = ch.symbol
            # Confirm, point-in-time, that this is genuinely the name's most
            # recent departure as of `as_of` (guards against a same-name
            # re-add/re-remove churn pattern recorded on the same date).
            removal = self.timeline.removal_as_of(symbol, as_of)
            if removal == last_change_date and symbol not in current:
                just_removed.add(symbol)

        if not just_removed:
            return current

        return current | frozenset(just_removed)
