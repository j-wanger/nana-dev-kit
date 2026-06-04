"""Point-in-time S&P 500 membership: a committed change log reconstructed as-of any date.

Index membership is *metadata*, not market data, so the change log is committed (deterministic, no
network at read time) — like the constituent snapshot. Free sources cannot supply a complete change
history before the recent past, so the reconstructable window starts at the log's **baseline** (its
earliest change date); a query before it raises rather than silently returning an empty — and therefore
wrong — membership. That raised boundary is the honest residual of the survivorship correction.

No-lookahead by construction: :meth:`MembershipTimeline.members_on` applies only changes with effective
date <= as_of, so perturbing a *future* change cannot alter a *past* membership — the strategy-layer
analog of the engine's F1 invariant.
"""

from __future__ import annotations

import csv
import re
from dataclasses import dataclass
from datetime import date
from enum import Enum
from pathlib import Path


class MembershipAction(Enum):
    """A change to index membership: a name joins (``ADD``) or leaves (``REMOVE``)."""

    ADD = "add"
    REMOVE = "remove"


class MembershipUnknownError(LookupError):
    """Raised when membership is queried before the reconstructable window (the log baseline)."""


@dataclass(frozen=True)
class MembershipChange:
    """One dated membership event. The earliest events (the baseline date) seed the starting set."""

    effective_date: date
    action: MembershipAction
    symbol: str


_FILENAME_RE = re.compile(r"sp500_membership_changes_(\d{4}-\d{2}-\d{2})\.csv$")
_REQUIRED_COLUMNS = {"effective_date", "action", "symbol"}
DEFAULT_DATA_DIR = Path(__file__).parent / "data"


@dataclass(frozen=True)
class MembershipTimeline:
    """Point-in-time index membership from a forward change log.

    The earliest change date is the *baseline* — the start of the reconstructable window; its rows are
    the baseline adds, and every later row adds or removes one name. Membership at ``as_of`` is the
    forward accumulation of every change with effective date <= as_of. The log is validated at
    construction: it must be non-empty, sorted by effective date, and coherent (never remove a
    non-member, never add an existing member) — a corrupt committed file fails fast rather than
    producing a silently wrong membership.
    """

    changes: tuple[MembershipChange, ...]

    def __post_init__(self) -> None:
        if not self.changes:
            raise ValueError("membership timeline has no changes")
        effective_dates = [c.effective_date for c in self.changes]
        if effective_dates != sorted(effective_dates):
            raise ValueError("membership changes must be sorted by effective_date (non-decreasing)")
        members: set[str] = set()
        for change in self.changes:
            if change.action is MembershipAction.ADD:
                if change.symbol in members:
                    raise ValueError(
                        f"incoherent log: {change.symbol!r} added at {change.effective_date} but already a member"
                    )
                members.add(change.symbol)
            else:
                if change.symbol not in members:
                    raise ValueError(
                        f"incoherent log: {change.symbol!r} removed at {change.effective_date} but not a member"
                    )
                members.discard(change.symbol)

    @property
    def start_date(self) -> date:
        """The baseline date — the earliest reconstructable as-of (queries before this raise)."""
        return self.changes[0].effective_date

    def members_on(self, as_of: date) -> frozenset[str]:
        """The index membership as of ``as_of`` — only changes with effective date <= as_of applied."""
        if as_of < self.start_date:
            raise MembershipUnknownError(f"membership before the baseline {self.start_date} is unknown (as_of={as_of})")
        members: set[str] = set()
        for change in self.changes:
            if change.effective_date > as_of:
                break  # sorted → every remaining change is in the future of as_of (no-lookahead)
            if change.action is MembershipAction.ADD:
                members.add(change.symbol)
            else:
                members.discard(change.symbol)
        return frozenset(members)

    def ever_members(self) -> frozenset[str]:
        """Every symbol that was ever a member — the holdable superset for a survivorship backtest."""
        return frozenset(c.symbol for c in self.changes if c.action is MembershipAction.ADD)

    def removal(self, symbol: str) -> date | None:
        """The date ``symbol`` last left the index, or ``None`` if it is a current member (or unknown).

        'Current' is as of the latest change in the log. A name removed then re-added returns ``None``
        (it is back in); the episodic per-removal refinement is deferred to when a screen needs it.
        """
        last: MembershipChange | None = None
        for change in self.changes:
            if change.symbol == symbol:
                last = change
        if last is None or last.action is MembershipAction.ADD:
            return None
        return last.effective_date

    def removal_as_of(self, symbol: str, as_of: date) -> date | None:
        """The date ``symbol`` had most-recently left the index *as known on* ``as_of``, else ``None``.

        Point-in-time: considers only changes with effective date <= as_of, so a *future* re-add cannot
        hide a removal that has already happened by ``as_of``. The delisting-aware reader needs this
        (not :meth:`removal`, which is full-log) because the engine reads the whole series once at the
        window end — a name removed mid-window then re-added later must still book its crater.
        """
        last: MembershipChange | None = None
        for change in self.changes:
            if change.effective_date > as_of:
                break  # sorted → no-lookahead
            if change.symbol == symbol:
                last = change
        if last is None or last.action is MembershipAction.ADD:
            return None
        return last.effective_date


def _row_to_change(row: dict[str, str], filename: str) -> MembershipChange:
    try:
        action = MembershipAction(str(row["action"]).strip().lower())
    except ValueError as exc:
        raise ValueError(f"membership CSV {filename}: unknown action {row['action']!r}") from exc
    effective = date.fromisoformat(str(row["effective_date"]).strip())
    return MembershipChange(effective, action, str(row["symbol"]).strip())


def load_membership_timeline(path: Path) -> MembershipTimeline:
    """Load a dated membership-changes CSV (``effective_date,action,symbol``). No network at read time."""
    if not _FILENAME_RE.search(path.name):
        raise ValueError(f"membership filename must be sp500_membership_changes_YYYY-MM-DD.csv, got {path.name!r}")
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        missing = _REQUIRED_COLUMNS - set(reader.fieldnames or [])
        if missing:
            raise ValueError(f"membership CSV {path.name} missing columns {sorted(missing)}")
        changes = tuple(_row_to_change(row, path.name) for row in reader)
    return MembershipTimeline(changes)
