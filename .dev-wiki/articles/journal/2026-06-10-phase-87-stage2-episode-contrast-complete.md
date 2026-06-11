---
title: "Phase 87 complete — Ceremony Stage-2 Episode Contrast: spec-generation undecidable; arm A ships, arm B ship-blocked by a load-bearing golden-master modification"
aliases: []
category: journal
tags: [ceremony, measurement, episode-contrast, stage-2, edge-screener, validity-sweep, review-gate]
parents: [phase-87-stage2-episode-contrast]
created: 2026-06-10
updated: 2026-06-10
source: debrief
duration: unknown
---

# Phase 87 complete — Ceremony Stage-2 Episode Contrast

## What Happened
- All 8 tasks [x]; 8/8 exit criteria via `eval/ceremony-lift/stage2/run-exit-criteria.sh` (RUN-STATUS LIVE). New frozen apparatus `eval/ceremony-lift/stage2/**` incl. the `amendments/` mechanism; kit-commit embargo held vs 6728e2f — no kit component touched.
- T1 drivability spike PASS (3 runs; pty mechanics learned) → T2 execution-protocol addendum frozen + A1 baseline gate 390/94.44 → T3 checkers 18/18 seeded controls → T4 HARD checkpoint + substrate (setup 4ed8071, twin clones, probes 10/10).
- T5 arms executed: B (minimal) FINISHED 996s; A (full ceremony) DNF 2,106s on the done-sentinel; instrument full 29/29. T6 evidence tables + blinded tie-break (0-0 reviewer defects; changed-lines favored B). T7 disposition checkpoint: **undecidable**; separate ship gate: arm A ships. T8 close-out + ship a6effcb.
- Mid-phase deviations (3) all handled via the experiment's own PRE-unblinding amendment mechanism (001 kit-marker hold, 002 model+stop-rule pinning, 003 canary re-posing + /cost removal) — no escape hatch needed.

## Decisions Made
- [[stage2-episode-outcome|Stage-2 episode outcome: spec-generation=undecidable, ship arm A]] -- extracted this session ([[stage2-episode-execution-design]] was articled at plan time; not duplicated).

## Problems Solved
- Arm B's silent golden-master regeneration (binary, invisible to blinded text-diff review) -- caught by the orchestrator validity sweep; load-bearing proven by restore-baseline drift failure, reproduced both directions → SHIP-BLOCKED.
- /cost swallowed input focus and broke the in-session canary posing -- amendment 003 (pre-unblinding): headless same-environment probe + complete pty-capture grep; canary CLEAN on that basis.

## Open Questions
- Trim follow-on round (Phase 88 candidate): dev-plan ride-alongs + debrief knowledge-capture half + Ph85 prune leftovers + NEW stage-2 checker tightening (run-exit-criteria c2 single-touch-through-HEAD for frozen files; check-instrument cmp-not-grep byte-identity; check-ship-table DNF-grep hole) — apparatus edits were barred post-unblinding by the amendment rule.
- _CURRENT_STATE.md at 230 lines vs ≤100 budget (pre-existing; owned sections compressed this debrief, preserved sections dominate the overage).
- Positive-control design: convention-mimicry made exactly-once non-discriminating — future seeded controls need mimicry-resistant targets.

## Artifacts Changed
- `eval/ceremony-lift/stage2/` (NEW frozen apparatus: spike/, execution-protocol.md, amendments/001-003, checkers + 18 seeded controls, instrument-record.md, arm-records/, ship-table.md, cost-table.md, results.md, run-exit-criteria.sh 8/8)
- `.dev-wiki/articles/phases/phase-87-stage2-episode-contrast.md` (`## Stage-2 verdict block` — disposition + ship decision)
- Health: kit test surface unchanged; edge-screener (substrate) 390→394 tests, 94.44%→94.58% coverage, shipped a6effcb via the experiment ship checkpoint.

### Review Gate
8/10 revise → fixed inline (c4bd9ff): HIGH tie-break-2 unpinned filter → corrected to pinned plain shortstat (121+/1- vs 219+/61-, same direction, immaterial); HIGH precision-2 coverage invocation unlogged → appended to cmdlogs (values reproduced exactly); 8 MEDIUMs: 4 record fixes applied, checker tightening routed to follow-on (post-unblinding apparatus edits barred). Reviewer's adversarial re-executions all reproduced TRUE — second consecutive phase with a live review-gate catch.

### Gate Compliance
gate-log:phase-87 direction=approved delivery=pending — flips at delivery (D3, gate-state follows git-state).

### Activation Quality
active-knowledge.md: 3 source sections (admissibility + evidence classes / freeze + verdicts-only invariants / cost measurement + verdict authority — carried from the Phase-86 header, same eval program). All 3 load-bearing this session: admissibility ruled the orchestrator-only evidence standard, the freeze invariants governed the addendum/amendment discipline, verdict authority shaped the closed-vocabulary T7 checkpoint and claim ceiling. Hit rate ~100% (3/3).

### Assumption-Ledger Revisit
A1 held (HEU-012 probe passed; enforcement fired in arms); **A2 bit** — the DNF artifact is exactly the decapitated-ceremony cost the assumption accepted, disclosed as a caveat on the disposition; A3 held (re-acked at checkpoint, no challenge); A4 held (spike passed; both arms driven to stop points); A5 held (seed acked, ceremony arm surfaced). Suggest reviewing [[stage2-episode-execution-design]] confidence in light of A2 (maintainer decides; the caveat column absorbed the bite as designed).

## Related
- [[phase-87-stage2-episode-contrast|Phase 87: Ceremony Stage-2 Episode Contrast]] -- parent phase

## Soft Observations / Phase N+1 Candidates
- pty-driven Claude Code sessions persist title-only transcripts while headless -p persists full token-bearing jsonl; AskUserQuestion errors in headless mode — interactive automation loses token accounting | platform-behavior wiki capture; cost instrumentation for driven sessions | eval/ceremony-lift/stage2/spike/spike-record.md
- /cost opens the account-level usage dashboard (not per-session cost) and swallows input focus — broke the in-session canary posing | automation hazard note | amendments/003-canary-posing-fix.md
- Live agent corner-cut class caught: minimal arm silently regenerated a committed golden-master fixture (binary, invisible to blinded text-diff review) | add binary-fixture diff to review/validity checklists | ship-table.md validity section
- Seeded positive controls keyed to "follow the documented convention" are satisfiable by mimicry of existing config state — non-discriminating | mimicry-resistant control design for future episodes | instrument-record.md full-mode caveat
- Ceremony arms end in debrief-shaped flows that don't naturally write app-root sentinel files → DNF artifact class under sentinel-based stop rules | stop-rule design note for any future episode | arm-records/interactions-arm-a.txt
