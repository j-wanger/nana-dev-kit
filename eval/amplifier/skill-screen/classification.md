# Classification — T3 OFF re-derivation results (Phase 78)

Scored by `check.sh` (NO-LLM) over the pre-registered spec-implied assertions, n=5 per
candidate/control, CONSENSUS_THRESHOLD=4. All OFF outputs are closed-book re-derivations from the
recoverable corpus `R_A` only (verified independent — see copy-leak checks below). Frozen under `runs/`.
Pre-registration: `3f6a0cba61f0ad259d88311289c8507d0035f82d` (ancestor of HEAD).

## Real candidates

### edge-eligibility (domain — PIT survivorship; prior HAS-HEADROOM) → **DEGENERATE (4/5 PASS)**
| sample | score |
|---|---|
| 1 | PASS |
| 2 | PASS |
| 3 | PASS |
| 4 | PASS |
| 5 | FAIL:re-added |
- 4/5 PASS ≥ threshold 4 ⇒ DEGENERATE. The single failure (#5) is on a BASIC assertion (`re-added`),
  NOT on the survivorship crux — i.e. 5/5 that were scored on `inclusive-through-d` got it right.
- **The headline surprise**: the bare model DERIVED the inclusive-through-`d` survivorship boundary
  (keep a removed name eligible through its removal date `d` so the delisting crater books on a held
  position) from the explicit-goal corpus, in 4/5 samples — using independent variable names and
  structures (#1 `just_removed`+`removal_as_of`; #2 a for-loop with `break`; #5 an effective-dates scan).
- SPEC-INCOMPLETE: none observed (no sample failed on the unstated-edge `before-baseline` behavior,
  which is not in the scored set anyway).
- Copy-leak check: 4/5 outputs contain ZERO of the real artifact's distinctive tokens; #2 reuses only
  the obvious variable name `removed_today` but has a wholly different docstring and loop structure
  (verified by diff) — coincidental naming, not copying. All 5 are genuine independent re-derivations.

### nana-drift (general — drift comparator core; prior DEGENERATE) → **DEGENERATE (5/5 PASS)**
| sample | score |
|---|---|
| 1–5 | PASS |
- 5/5 PASS ⇒ DEGENERATE. The general compare-and-report core (`detects-drift`, `silent-when-synced`)
  is trivially recoverable, as predicted.
- Copy-leak check: 0/5 outputs contain the real script's distinctive tokens (`modules.json`,
  `NANA_INSTALLED_ROOT`, `EXCLUDE=`, `nana-personal`) — independent re-derivations.

## Controls (gate the verdict — evaluated by PASS-COUNT per the pre-registration, not the 3-way verdict)
| control | criterion | PASS count | result |
|---|---|---|---|
| ctrl-negative (add) | ≥4/5 PASS | 5/5 | ✓ OFF is not lobotomized |
| ctrl-positive (unknowable `rev-7f3a`) | ≥4/5 FAIL (≤1/5 PASS) | 0/5 PASS | ✓ instrument SEES non-recoverable content |
| ctrl-recoverable (clamp) | ≥4/5 PASS | 5/5 | ✓ corpus channel is fair, not starved |

- **Check-design note** (recorded so the verdict is un-foolable): `check.sh --aggregate` reports the
  positive control as `UNSTABLE` — NOT because the instrument failed, but because its 5 FAILs split
  across exception-clauses (NotImplementedError / LookupError×2 / a custom `ScreenConfigRevisionUnavailable`×2),
  and the 3-way verdict demands a SAME-clause consensus that is meaningful only for real candidates. The
  control's pre-registered criterion is PASS-COUNT (≥4/5 FAIL); 0/5 PASS satisfies it cleanly. No output
  contained the pinned token `rev-7f3a` (no leak). The varied exceptions are themselves the positive
  signal: the bare model HONESTLY REFUSED to invent the project's unknowable token (it raised rather than
  hallucinated) — the Phase-71 "refused to invent an absent sentinel" echo, here proving the instrument
  registers non-recoverable content as FAIL.

## Cost-delta (recorded-only; NO verdict logic reads it — review M4)
Each OFF re-derivation cost ~33–37k subagent tokens / 1 tool-use / 5–45s wall. Invoking a crystallized
skill that bundled the tested artifact would cost ~0 re-derivation tokens. So crystallization DOES buy a
token/latency saving — but the screen measures CORRECTNESS headroom, and on correctness the candidates
are DEGENERATE: the model re-derives the right answer, so the skill saves cost, not correctness. (Cost
savings is the weak value claim; it does not justify a capture MODULE on its own — a saved artifact in
the repo, or a one-line note, captures the same saving without the machinery.)

## Verdict inputs
- Controls all satisfy their criteria ⇒ instrument LIVE (not INSTRUMENT-DEAD).
- Both measurable real candidates DEGENERATE ⇒ per the pre-registered ladder, `PROGRAM-VERDICT: TERMINATE`.
