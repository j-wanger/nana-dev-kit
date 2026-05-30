# Cross-Boundary Retention Headroom Screen — Result (Phase 71)

> **No-harness-value claim.** This screen characterises a BOUNDARY and an INSTRUMENT, not the harness.
> `HAS-HEADROOM` means *lift is possible* (the residual lacks the decision, so a harness rule *could*
> supply it) — never that lift exists. `DEGENERATE` / `DEGENERATE-by-summary-robustness` means the
> residual already carries the decision and the bare model acts on it, so there is no lift to measure.
> This record makes **no claim about whether the Nana harness helps in real work.**

base-model: claude-opus-4-8 (bare subagent via the Agent tool — no rules/hooks/skills/memory/tools)
method: n=5 per condition; differential OFF×ON verdict via the deterministic named-clause checker
(`check.sh`), NO LLM in the scoring path. Pre-registered + committed before runs (`pre-registration.md`,
commit 896e096); OFF/ON prompts shasum-pinned (`check.sh --verify-pins`) + leak-checked + OFF-is-prefix-of-ON
isolation-checked. A model authored the compaction-summary substrate (the real mechanism), then it was frozen.

## Substrate (short→long escalation, recorded — NOT a retrofit)

The candidates' OFF residual is a MODEL-authored compaction summary of a frozen synthetic transcript. Each
transcript was pinned, THEN summarised, and the summary ACCEPTED as produced (no transcript was iterated to
force a drop). Two probe rounds:
- **Round 1 (short, ~40-line sessions):** two summaries — both RETAINED their decision.
- **Round 2 (long, 1,213-word / ~12-decision session):** one 356-word summary — RETAINED all three candidate
  decisions (EUR 8,000, ROLLING 7-day, hit_flag sentinel 9; every token verified present by grep).

The escalation short→long was a substrate-validity fix (short transcripts do not stress compaction); the
retention result held at both scales.

## Controls-first checkpoint — PASS (instrument validated)

| control | expected | result |
|---|---|---|
| control-negative (decision present in residual) | DEGENERATE | **DEGENERATE** (OFF 5/5 PASS — model honored the in-residual 14-day value over the 30-day default) ✓ |
| control-positive (arbitrary rule ONLY in [HARNESS STATE]) | HAS-HEADROOM | **HAS-HEADROOM** (OFF 5/5 FAIL — model REFUSED to invent the sentinel; ON 5/5 PASS — honored the state block) ✓ |
| control-middle (HTTP 204 vs 200) | STABLE (no false-positive in 2 batches) | **STABLE** (DEGENERATE/DEGENERATE) ✓ |

The positive control is load-bearing: it proves the ON pathway is LIVE (a state-block decision absent from
the residual IS read and honored) and that the instrument CAN read HAS-HEADROOM — so the candidate nulls are
NOT an artifact of a dead instrument. The negative confirms DEGENERATE-when-residual-carries-it; the middle
confirms no false-positive on a borderline.

## Candidate verdicts

| candidate | class | retained in summary? | verdict |
|---|---|---|---|
| cand-threshold (EUR 8,000 monitoring alert) | motivated | YES | **DEGENERATE-by-summary-robustness** (OFF 5/5 honored 8,000 over the 10k default) |
| cand-window (ROLLING 7-day window) | motivated | YES | **DEGENERATE-by-summary-robustness** (OFF 5/5 honored rolling 7-day) |
| cand-sentinel (legacy hit_flag = 9) | arbitrary (engineered-favorable backstop) | YES | **DEGENERATE-by-summary-robustness** (OFF 5/5 honored 9; see brittle-forbid note) |

Candidates screened: 3 (2 motivated + 1 engineered-favorable arbitrary). NATURAL/motivated candidates that
reached a lossy boundary: 0. Engineered-favorable that reached a lossy boundary: 0. No candidate produced an
OFF-fail driven by a dropped decision.

## The finding

Across three project decisions spanning motivated reasoning (an EUR 8,000 monitoring threshold deliberately
set below the EUR 10,000 statutory line; a ROLLING 7-day structuring window chosen over calendar windows) and
an arbitrary non-derivable convention (a legacy `hit_flag = 9` sentinel), a model-authored compaction summary
of a realistic ~12-decision session **RETAINED every decision** — even compressing 1,213 words to 356. And in
the OFF condition the bare base model **honored every retained decision** 5/5, including choosing the
counter-default EUR 8,000 over the EUR 10,000 regulatory default it would otherwise reach for.

The discriminating variable is therefore the same one Phase 70 found for single decisions, now in the
multi-turn dimension: harness retention headroom requires the native compaction summary to DROP a decision —
and it does not. Claude Code's own compaction summary is decision-comprehensive; it does the decision
retention unprompted, exactly as the bare model did the AML reasoning unprompted in Phase 70. There is nothing
for the harness cross-compaction state machinery to RECOVER that the native summary has not already carried,
in the single-session / single-compaction regime this screen can reach.

PROGRAM-VERDICT: TERMINATE-by-summary-robustness

Per the pre-registered ladder: no candidate (motivated or engineered-favorable) reached a lossy boundary —
every decision was retained by the native summary — so the single-session cross-boundary-retention measurement
line is closed. The positive control proves this is a property of the BOUNDARY (decisions are not dropped),
not a dead instrument (the ON pathway works when a decision IS absent).

## What TERMINATE-by-summary-robustness does and does NOT close (scope + honesty rails)

It is scoped to *single-session, single-compaction retention of an explicitly-stated decision*. It does NOT
close, and this screen did not and could not test:

1. **Cross-SESSION persistence.** Claude Code's compaction summary lives only within a session; it does not
   survive a new session. The harness state files (`active-phase.md`, `_CURRENT_STATE.md`) DO persist across
   sessions. This screen, built on one within-session summary, says nothing about that regime — where the
   native mechanism genuinely does not reach but the harness files do.
2. **Cumulative MULTI-compaction degradation.** A long-running task compacts repeatedly; information can decay
   across successive summaries in a way one compaction does not exercise. Untested here.
3. **Diffuse process discipline** (staying on-plan, not re-litigating settled calls) — not a single-output
   checkable decision; out of scope by construction (named in the spec).

These are the genuine surviving headroom regimes. Each needs a real long-horizon / multi-session substrate —
the Phase-70 `decidable-when` ("a multi-turn substrate exists"), which still does not exist. NO Phase-72 rig is
authorized by this screen.

## Limitations (recorded, not buried)

- **DISCOVERED brittle-forbid (cand-sentinel).** The pre-registered forbid clause `not-boolean` (`\btrue\b|\bboolean\b`)
  fired on the model's CORRECT explanation ("9, not 1 or boolean true"), not on a wrong answer — a substring
  forbid cannot tell "answer = 9, explained as not-true" from "answer = true". The as-pinned check read a FALSE
  HAS-HEADROOM; the clause is withdrawn as INVALID and the substantive verdict (DEGENERATE — the model wrote 9
  on every run) was taken from the valid `require honored-9` clause + the deterministic retention grep. The
  committed check was left UNCHANGED (editing after the runs would be retrofitting). The realized brittleness is
  exactly the Phase-70-anticipated risk; it is disambiguated decisively by the positive control, which shows
  what a REAL OFF-failure looks like (the model states NO value), categorically unlike the sentinel runs.
- **Single compaction, n=5, synthetic boundary.** One model-authored summary of one synthetic session; n=5;
  deterministic regex checks. A genuinely lossy boundary at real scale (hundreds of turns, dozens of decisions,
  or repeated compactions) was not reached and is the surviving regime above.
- **The summary over-retained relative to its length budget.** Asked for ~150–220 words, the model produced 356,
  keeping every decision. A real compaction under harder token pressure might be more lossy — but it would then
  drop the LEAST-salient detail first, which is the arbitrary-trivia (PARKED/unknowables) band, not the motivated
  decisions whose recovery would be the actual process-retention win.

## Discovered latent finding (recorded, out of scope to fix here)

`templates/.claude/hooks/post-compact.sh` READS `.claude/.session-anchor`, but NOTHING in the repo ever WRITES
that file (only `.gitignore` lists it) — that post-compaction recovery branch is DEAD and never fires. Noted as
a follow-up; NOT fixed here, because editing the cross-compaction machinery (the SUBJECT of this measurement)
mid-screen would violate freeze-the-subject.

See [[cross-boundary-retention-headroom-screen]] for the decision and the disposition handoff, and
[[amplifier-anchor-headroom-screen]] for the Phase-70 single-decision parent this extends.
