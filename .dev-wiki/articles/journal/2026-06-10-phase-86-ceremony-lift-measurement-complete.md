---
title: "Phase 86 complete — Ceremony Lift Measurement: stage-1 screen + checkpoint verdicts (4 decided, 2 to stage-2/follow-on)"
aliases: []
category: journal
tags: [ceremony, measurement, eval, verdicts, review-gate, pre-registration, transcripts]
parents: [phase-86-ceremony-lift-measurement]
created: 2026-06-10
updated: 2026-06-10
source: debrief
duration: unknown
---

# Phase 86 complete — Ceremony Lift Measurement

## What Happened
- All 8 tasks [x]; 8/8 exit criteria (post-correction re-run) via `eval/ceremony-lift/run-exit-criteria.sh`; check-verdicts-only.sh green vs pinned base 5360486. New frozen apparatus `eval/ceremony-lift/` (19 files), no kit component touched.
- T1 pre-registration committed then byte-FROZEN (9ad62f0) — survived 11 commits unchanged. T2 cost extractor + 13-check hand-labeled control; T3 cost table over 12 sessions (ceremony ~66% adj tokens / ~64% wall; EARLY-EXIT no). DISCOVERY mid-T3: subagent cost recovery silently zero (both transcript marker forms missed) — extractor fixed, control strengthened with hand-paired pins.
- T4 five blind tabulator controls vs never-read answer key; T5 corpus manifest, 44 ceremony dispatches, anchor count == 8 hand-counted pin; T6 evidence table + re-execution log — flagship: the Ph85 review-gate catch fully admitted via transcript-extracted pre-fix state (4/4 Edit calls reverse-applied; defect reproduces while make test passes on the same state).
- T7 HARD checkpoint: maintainer verdicts taken (see [[ceremony-step-verdicts]]); STAGE-2 go, routed follow-on.

## Decisions Made
- [[ceremony-step-verdicts|Ceremony-step checkpoint verdicts (Phase 86)]] -- extracted this session ([[ceremony-lift-tiered-screen]] was articled at plan time; not duplicated).

## Problems Solved
- Git-unrecoverable pre-fix states (inline-fix workflow) -- transcript Edit-call reverse-application in a worktree; reusable forensic method (re-execution-log.md#r-ph85-review-gate).
- Silently-dead extractor column behind a passing control -- caught by reading the output table; control now pins every column (b7e7e0e).

## Open Questions
- Stage-2 follow-on design execution (Phase 87 candidate): episode contrast per frozen pre-registration `## Stage-2 parameters`; spec-generation is its primary customer; dev-plan trim verdict also queues follow-on work.
- Follow-on trim round needs per-cut removal checklists: dev-plan ride-alongs (active-knowledge re-presentation, state-loader/artifact-writer heft) + debrief knowledge-capture half (working-knowledge seeding ~10k tokens/session, journal prose, memory bridge).
- 3 cross-phase WK facts still HELD (Ph85 Blockers note) — disposition now shaped by the debrief-capture=trim verdict; re-presented at this debrief's capture check.
- Measurement-method debts disclosed not fixed: pooled-share materiality (no per-phase median), interruption count misses permission prompts, session PLAN-split unimplemented (review-gate denominator undercounts by ≤3).

## Artifacts Changed
- `eval/ceremony-lift/` (NEW, 19 files: pre-registration.md FROZEN, extract-costs.py + 13-check control, cost-table.md, classify-evidence.py + 5 blind controls + answer-key.json, corpus-manifest.md, evidence-table.md + re-execution log, check-verdict-block.sh, check-verdicts-only.sh, run-exit-criteria.sh)
- `.dev-wiki/articles/phases/phase-86-ceremony-lift-measurement.md` (`## Maintainer Verdicts` block + review-gate correction)
- Health: make-test count unchanged at 26; 9 new runner-based control/check scripts deliberately outside make test (verdicts-only Makefile invariant).

### Review Gate
6/10 revise. CRITICAL: taxonomy-widening — 4 assumption-ledger bit rows admitted outcome-grade in violation of the FROZEN pre-registration (no gate counterfactual); the retrofit class the freeze exists to prevent, missed by self-check, convicted by the reviewer against the frozen text. Fixed inline (bits → ambiguous-downgrade; blind classifier agrees); CRITICAL+HIGH fixed, the pre-registered A2 >50%-downgrade STOP fired, was re-presented, maintainer accepted-and-proceeded; verdicts re-confirmed (no line moved). Meta-irony on the record: the reviewer caught a defect in the measurement of the reviewer — the review-gate step's second fully-witnessed marginal catch, live evidence for the verdict that kept it by expected-cost arithmetic.

### Gate Compliance
gate-log:phase-86 direction=approved delivery=pending — flips at delivery (D3, gate-state follows git-state).

### Activation Quality
active-knowledge.md: 3 source sections (admissibility + evidence classes / freeze + verdicts-only invariants / cost measurement + verdict authority), all heavily referenced this session — every section load-bearing (admissibility ruled the table, the freeze convicted the CRITICAL, verdict authority shaped the checkpoint). Hit rate ~100% (3/3).

### Assumption-Ledger Revisit
A1 held, A3 held, A4 held (label-window under-enumeration noted as caveat, not leak), A5 held (2 steps to stage-2/follow-on, 4 decided). **A2 BIT** — the >50% ambiguous-downgrade STOP fired (pre-fix states largely unrecoverable: constraints fold pre-commit). Suggest reviewing [[ceremony-lift-tiered-screen]] confidence in light of A2 (maintainer decides; the pinned downgrade direction absorbed the bite as designed).

## Related
- [[phase-86-ceremony-lift-measurement|Phase 86: Ceremony Lift Measurement]] -- parent phase

## Soft Observations / Phase N+1 Candidates
- Span-attribution wall-clock inflates steps that precede user gates (approach-reviewer 17.8% wall includes gate idle) | future per-step wall claims need idle-time separation | cost-table.md
- Anchor controls must cover every step CLASS, not one anchor phase: Ph81/82/83 review-gate dispatches fell outside the session window silently (denominator -3) | evidence-table.md table-level caveats
- Registered-but-not-working, extractor edition: unpinned subagent_out column silently dead while the control passed | controls must pin every column | b7e7e0e
- The freeze earned its keep twice: byte-frozen pre-registration survived 11 commits AND armed the reviewer's taxonomy-widening conviction | a25ad50
- Inline-fix workflow makes pre-fix states git-unrecoverable by construction; transcript Edit-call reverse-application recovers them (4/4) | re-execution-log.md#r-ph85-review-gate
