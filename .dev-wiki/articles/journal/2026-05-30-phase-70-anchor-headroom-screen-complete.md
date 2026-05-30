---
title: "Phase 70 complete — Single-Decision Anchor-Headroom Screen → PROGRAM-VERDICT: TERMINATE"
aliases: []
category: journal
tags: [eval-validity, amplifier-vision, measurement, anchor-selection, headroom, terminate, phase-70, journal]
parents: [phase-70-anchor-headroom-screen]
created: 2026-05-30
updated: 2026-05-30
source: debrief
duration: long
---

# Phase 70 complete — Single-Decision Anchor-Headroom Screen → PROGRAM-VERDICT: TERMINATE

## What Happened

Phase 70 built AND ran the cheapest decisive go/no-go for the whole amplifier-measurement program
(Phases 65–69 mostly negative), **inverting the Phase-69 handoff order**: anchor selection is upstream
of measurement, and predicate-repair-first was structurally blocked (the anchor surfaces in OFF ≥ ON ⇒
any boundary repair collapses to raw-text). So it screened anchor EXISTENCE first — does ANY
non-commodity single-decision PURE-REASONING anchor have real OFF-baseline headroom (the harness-OFF
bare subagent OMITS the correct behavior unprompted)? All five adversarial-review fixes adopted
(un-fixed design 4/10).

- **T1 (FIRST/checkpoint)** froze the deterministic apparatus — `check.sh` (named-clause
  consensus-by-clause ≥4/5 same-clause-id, `--selftest` 13/13 both directions, `--verify-pins`, NO LLM
  in the scoring path), `leak-check.sh` + `leak-vocab.txt`, 7 shasum-pinned no-tools OFF prompts + 7
  named-clause checks + selftest fixtures — and was **committed SEPARATELY at `be96783` BEFORE any run**
  so the anti-retrofit guard (`git merge-base --is-ancestor be96783 df45592`) passes.
- **T2 (load-bearing checkpoint)** validated the instrument: negative (look-ahead) = DEGENERATE 5/5,
  positive (fictional Zephyr Act fact) = HAS-HEADROOM 5/5, middle ($14k) batch1+batch2 = DEGENERATE ⇒
  `stability: STABLE` (no false-positive in the contested band).
- **T3** screened 4 candidates, all **DEGENERATE 5/5**: structuring, UBO indirect-aggregation (the
  best-shot multiply-and-sum), sanctions transliteration, and the engineered-favorable EU AMLR €10,000
  cap. `claude-opus-4-8` (bare) produced the correct AML behavior unprompted on every real anchor.
- **T4** → **PROGRAM-VERDICT: TERMINATE** (pre-registered ladder; even the engineered-favorable
  DEGENERATE) + `screen-record.md` + finalized the decision article. The only anchor with headroom was
  the positive control's fact-that-does-not-exist.
- **T5 (LAST)** regression: `make eval` 52/52, `make test` green at the UNCHANGED 19-script count,
  frozen artifacts git-diff-empty, 12/12 exit battery.

Two documented pre-run DISCOVERY refinements (validity fixes, not post-hoc loosening): the middle-control
stability rule changed from "reproduces UNSTABLE" to "must not read HAS-HEADROOM in either batch" (a true
~50%-pass anchor is UNSTABLE only ~62%/batch at n=5, so the original would spuriously halt a working
instrument ~55% of the time); and a uniform "no external tools/search" clause was added to all 7 OFF
prompts before freezing (shasums recomputed before commit).

## Decisions Made

- [[amplifier-anchor-headroom-screen|Phase 70 — Single-decision anchor-headroom screen → PROGRAM-VERDICT: TERMINATE]] (confidence high; authored at planning, finalized this session with the realized result + handoff)

## Problems Solved

- **The Phase-69 handoff order was structurally impossible.** Predicate-repair-first cannot be designed
  on a degenerate anchor (OFF ≥ ON ⇒ raw-text collapse). Resolved by inverting: screen anchor existence
  first, deterministically, before any detector engineering or live run.
- **The asymmetric false-continue risk** (the Phase-58 n=1 false-positive scar) was guarded by a
  consensus-by-clause criterion (≥4/5 SAME clause-id), not OR-of-failures + run-noise.

## Open Questions

- **Retrieval on genuinely-unknowable facts** (proprietary / post-training-cutoff). The positive control
  proved headroom is reachable ONLY for facts outside the model's knowledge — the long-standing Phase-59
  untested sweet spot. **decidable-when:** a non-commodity corpus + absorb pipeline exists to source real
  proprietary/post-cutoff anchors. (carried forward)
- **Long-horizon / multi-turn process-retention headroom.** Explicitly dropped from this screen (a
  one-shot subagent can't surface it). **decidable-when:** a multi-turn substrate exists to run
  constraint-set-then-test-after-interposed-work probes. (carried forward)

## Artifacts Changed

- `eval/amplifier/anchor-screen/` (NEW repo-only subsystem: `check.sh`, `leak-check.sh`,
  `leak-vocab.txt`, `pre-registration.md`, `screen-record.md`, `fixtures/`, `prompts/` ×7,
  `checks/` ×7, `verdicts/` ×7, `runs/` ×30; deterministic scoring path, NO LLM in classification;
  NOT wired into install.sh / Makefile / `make test` / `make eval`)
- `.dev-wiki/articles/decisions/amplifier-anchor-headroom-screen.md` (finalized: realized result +
  handoff)
- `specs/phase-70-anchor-headroom-screen.md` (NEW spec, nana:approved)

## Related

- [[phase-70-anchor-headroom-screen|Phase 70: Single-Decision Anchor-Headroom Screen]] — parent phase
- [[amplifier-representativeness-audit]] (Phase 69 — the audit this screen acts on)
- [[amplifier-measurement-instrument]] (Phase 68 — the ruler)

## Health Delta

- `make eval`: 52/52 (unchanged). `make test`: green at the UNCHANGED 19-script count (anchor-screen
  self-tests are NOT wired as make-test gates → README still "19 scripts"; no script-count bump).
- Frozen artifacts git-diff-empty: `emit-proxy-vector.sh`, `measurability-gate.sh`, and all CODE under
  `eval/comparison|corpus|reasoning`. No hooks / modules.json / settings.json touched.
- New repo-only tree under `eval/amplifier/anchor-screen/` (consistent with the Phase 68/69 amplifier tree).
- Committed `be96783` (plan + T1) + `df45592` (T2–T5), pushed to `main`. Delivery accepted by the user.

## Soft Observations / Phase N+1 Candidates

- The amplifier-measurement program, as a SINGLE-DECISION-ANCHOR line, is now empirically **terminated**:
  across 4 diverse AML anchors (incl. the engineered-favorable) the frontier base model produced the
  correct behavior unprompted 5/5 every time; headroom appeared ONLY on a fictional fact.
  | (next-phase framing) Phase 71 should NOT pursue single-decision anchor measurement; the two live
  avenues are (a) retrieval-on-genuinely-proprietary-facts and (b) long-horizon/process-retention on a
  multi-turn substrate — OR pivot to the engineering roadmap (gap 4.1 language-agnostic core,
  vector-search-default-on). | (evidence) `eval/amplifier/anchor-screen/screen-record.md`
- The deterministic-consensus-by-clause eval pattern (named-clause checks + ≥4/5 same-clause +
  controls-first + pre-registered graded ladder + commit-precedes-runs anti-retrofit guard) is a
  reusable instrument for any "is X measurable / does the baseline already do X" screen.
  | (next-phase framing) candidate for a `/wiki-capture` as a measurement-methodology heuristic.
  | (evidence) `eval/amplifier/anchor-screen/check.sh` + `pre-registration.md`
- Five+ amplifier phases (65–69 + 70) have now all converged on the same wall — the strong base model
  leaves little measurable headroom. The harness's value, if any, is process-discipline (lifecycle /
  gates / context-retention), which this single-decision measurement line structurally cannot capture.
  | (next-phase framing) reconsider whether to keep investing in harness-lift MEASUREMENT vs. accepting
  process-merit and shipping engineering-roadmap work. | (evidence) the Phase-59→61→69→70 negative chain

### Activation Quality

`.claude/rules/active-knowledge.md` carried 3 distilled blocks, all sourced to
`[[amplifier-anchor-headroom-screen]]` (the decision captured this session) — 1/1 distinct slug
activated = 100% hit rate. The phase's pre-registered design (controls-first, deterministic consensus,
graded ladder) tracked the active-knowledge framing exactly; no drift between planned and realized.

### Retro Check (Phases 61-70)

| Dimension | Findings | Signal |
|-----------|----------|--------|
| 1. Recurring Blockers | 0 process blockers (the recurring "no measurable headroom / strong base model" theme is a convergent *finding*, captured as such — Phases 59/61/69/70 — not an execution blocker; the memory-venv blocker resolved Phase 58, no recurrence) | low |
| 2. Decision Reversals | 0 post-hoc reversals of shipped work; 3 healthy *pre-commitment* reversals at the direction gate (P65 scored-fixture→substrate, P69 live-run→audit, P70 predicate-repair-first→anchor-screen) — adversarial review killing weak designs before spend | low |
| 3. User Corrections | 0 corrections of agent error; user direction *selections* via AskUserQuestion (P65/66/69/70 Approach A) are gate choices, not overrides | none |

Recommendations:
- No systemic issues. The amplifier line's repeated negatives are an honest convergent result, not a process failure — the burden-of-proof-on-the-feature discipline is working (it turned the would-be 6th negative meta-phase into a clean TERMINATE). The one durable signal: stop re-asking the single-decision-headroom question; the next investment should be a *different* class (retrieval-on-proprietary, long-horizon, or engineering roadmap), as the TERMINATE handoff records.
