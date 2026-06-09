# Circularity-Failure Predicate (Phase 80, T1 RED)

The agent-internal approach review's CRITICAL finding: a ground-truth set of "which assumptions were
load-bearing" is worthless if it is **author-selected**, because the same judgment whose blind spot is
being measured then picks the labels — and a corpus can only contain assumptions *someone already
noticed*. This file fixes, BEFORE any labeling, the line between a circular (author-selected) label and a
non-circular (outcome-determined) one. T1 GOes only if labels on the non-circular side are constructible.

## Definitions

A **ground-truth label** asserts: *"in phase P, assumption X turned out load-bearing"* (i.e., being wrong
about X would have changed the phase's outcome, and the project's record shows it mattered).

A **blind-baseline label** asserts: *"a clean-context reader of phase P's plan AS-OF-PLANNING-TIME would
list X as an assumption the plan makes"* — produced with NO access to any later phase.

## NON-CIRCULAR (outcome-determined) — a ground-truth label QUALIFIES iff its load-bearingness is
established by a MECHANICAL signal in the record, extractable by pattern WITHOUT a post-hoc judgment that
"X was the one that mattered". At least one of:

- **R1 — Confidence revision / deprecation.** A decision article's `confidence:` was lowered, or its
  `status:` set to `deprecated`/`under-review`, in a later commit.
- **R2 — Supersession / reversal.** A later decision explicitly supersedes or reverses an earlier one
  (a `superseded_by` link, "reverses Phase N", "supersedes [[...]]", or a `~~struck~~` Blocker entry).
- **R3 — Blocked / abandoned.** A task was tagged `[blocked: ...]`, or a planned approach was abandoned
  mid-phase and the reason recorded.
- **R4 — Empirical contradiction.** A later phase states an earlier result/assumption did NOT hold
  ("did NOT replicate", "TERMINATE", "DEGENERATE", "was from injected conditions", a measured Δ that
  reversed the earlier sign). The earlier phase's load-bearing assumption is the one the contradiction
  names.

The assumption text X is then taken from the EARLIER plan (the decision article at its low-confidence /
proposal state, or the approach as written), and its load-bearingness is certified by the LATER mechanical
signal — never by the labeler deciding X mattered.

## CIRCULAR (author-selected) — a label FAILS (is disqualified) if ANY of:

- **C1** — establishing that X was load-bearing requires reading the later outcome and *judging* it
  important, with no R1–R4 signal naming it.
- **C2** — the blind baseline for P was produced with any visibility of phases after P (the labeler knew
  the outcome). Blind baselines MUST come from a clean-context pass over plan-as-of-then.
- **C3** — X appears in the ground-truth set only because the labeler (who has read the whole project)
  finds it salient — i.e., X has no independent textual anchor in P's own plan.

## R5 — SILENCE label (added at the silent-class pivot, 2026-06-09)

The traced labels R1–R4 certify *load-bearingness* but, by construction, only capture assumptions that
were eventually NOTICED. A2's real fear is the assumption that stays wrong, unnoticed, while everyone says
yes. To test that class WITHOUT author-invented synthetic plants (the Ph66/69 unrepresentativeness the
review flagged), use the project's REAL silent failures, labeled mechanically:

- **R5 — Silence gap.** An assumption qualifies as SILENT-load-bearing iff it satisfies R1–R4 (was
  load-bearing) AND the gap between the phase where it BECAME false (introduction commit/phase) and the
  phase where it was CAUGHT (fix/detection commit/phase) spans **≥2 phases**. The gap is read from git
  history / the phase record — outcome-determined, not author judgment.

Confirmed real R5 cases (large gaps): MCP-memory CWD mismatch (broken Ph4 → noticed ~Ph38–49), session-start
line-cap erosion (70@Ph22 → 137 by Ph54, no test caught it), the cascade-failure class (enforce silently
disabled; explicitly a THIRD instance — pre-compact Ph15–23, MCP-CWD Ph4–38, nana-init Ph43–55). Each is a
plan-as-of-then assumption ("the hook is wired / firing", "memory persists at this path", "session-start
is within budget") that was load-bearing and stayed false for 30+ phases.

These anchor the silent-class fixtures in REAL burial patterns. Synthetic plants are used ONLY if the real
R5 set proves too small to score, and if so are CALIBRATED to the real cases (not invented from scratch).

- **GO** iff, for ≥3 real past phases, (a) ≥1 non-circular (R1–R4) ground-truth label is extractable per
  phase, AND (b) a blind baseline is constructible for each via clean-context (C2 satisfiable in practice).
- **INSTRUMENT-DEAD** iff non-circular labels are absent/too sparse to score, OR blind baselines cannot be
  produced without leaking the outcome (C2 unsatisfiable).

## Pre-registered known limit (necessary-not-sufficient, carried to T2)

R1–R4 only label assumptions that left a **trace** — they were noticed enough to be revised, superseded,
blocked, or contradicted. Assumptions that were silently wrong and never bit leave NO mechanical signal,
so the corpus is structurally blind to them. This makes the screen a NECESSARY test (a surfacer that can't
beat the blind baseline on traced assumptions certainly won't catch silent ones) but NOT a sufficient
guarantee of completeness. The Phase-81 ledger's missing-assumption calibration events are the only
detect-after backstop for the silent class. T1 GO does not erase this limit; it scopes the screen honestly.
