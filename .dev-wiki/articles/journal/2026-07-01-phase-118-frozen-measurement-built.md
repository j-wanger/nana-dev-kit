---
title: "Phase 118 — YouTube grounded-acquisition frozen live measurement: BUILT + twice-adversarially-reviewed (8/9 tasks; live T9 RUN pending maintainer)"
aliases: [phase-118-built, youtube-frozen-measurement-built]
category: journal
tags: [youtube, research-pipeline, grounding, anti-retrofit, pre-registration, frozen-instrument, adversarial-review, phase-118]
parents: [phase-118-youtube-frozen-live-measurement]
created: 2026-07-01
updated: 2026-07-01
source: debrief
duration: ~4h (post-compaction estimate; may undercount)
---

# Phase 118 — YouTube grounded-acquisition frozen live measurement: BUILT + twice-reviewed

## What Happened

- Built the full anti-retrofit instrument around the byte-frozen Ph116/117 apparatus: `seal118` (rail + prereg SHA-256 self-seals), `select118` (deterministic templated-query corpus selection + corpus-freeze), `verify118` (two-stage tamper-evident anchor), `harness118` (rail-BLIND API-path Sonnet-4.6 batch runner, $10/batch cap, per-id accounting, non-optional-stopping resume), `score118` (A1 audio rubric + A2 directional scorers), `recovery118` (novelty bare-model recovery control, outside-kit), `verdict118` (4-way mechanical truth table + ToS containment gate), `run118` (T9 orchestration scaffold + results writer + runbook). 8 apparatus modules + 9 test modules.
- 8 of 9 tasks fully [x]. **T9 is the live manual-drive RUN** — its scaffold is built + green (7 tests), but the actual measurement (search → corpus-freeze → batch → A1 audio → novelty → verdict → results.md) awaits the maintainer at the PREREG-commit checkpoint: it needs a residential IP, `ANTHROPIC_API_KEY`, and manual audio/novelty judging. The phase is NOT complete and the delivery gate does NOT flip.
- Ran **two sequential ultracode adversarial-review Workflows** (18 then 20 agents, ~2.05M subagent tokens; 6 dimensions × find→adversarial-verify each). The SECOND pass (over the code plus the first pass's fixes) found a NEW HIGH the first missed — evidence for review-twice on a frozen-measurement instrument. 22 confirmed findings total (3 HIGH per pass), all fixed inline + regression-tested. Green TDD had missed every one (tests assert intended behavior; the reviews found what a caller/operator can OMIT or DRIFT).
- The maintainer chose "Frozen feasibility + novelty tag" sequencing (feasibility-first) over a cheap value-pre-screen-first; then at review upgraded the novelty signal from a bare tag to a CONTROLLED per-concept bare-model recovery screen (the Ph104/Ph58/59/78 controlled form), kept OUT of the mechanical verdict, admissible only scoped-to-post-cutoff.

## Decisions Made

- [[youtube-frozen-live-measurement|YouTube frozen live measurement — feasibility GO/NO-GO + controlled novelty recovery]] -- updated this session with the BUILT + twice-reviewed Outcome (authored at plan; not duplicated).

## Problems Solved

- **Review-1 HIGHs (anti-retrofit holes in the phase's own freeze code):** `corpus.sha256` written but never read back → bind the verdict to the git-tracked artifact via `git show`. The keystone `ground()` re-derivation was bypassable by omitting a sidecar → derive the required-sidecar set from telemetry, not caller args.
- **Review-2 HIGH:** `is_terminal` used an ENUMERATED terminal-outcome set that omitted 4 real outcomes → a legitimate resume re-fetches them → double-count row → the anchor VOIDs the whole measurement. Fix: derive terminal-ness from the emitted vocabulary (every outcome terminal except the provisional `not-run`) — is_terminal is now DRIFT-PROOF.
- **Vacuous-seal risk confirmed handled:** `git ls-files companion/` is empty (whole tree gitignored) so Ph117's `git diff --quiet` byte-freeze check could not fail; `rail.sha256` recompute-and-match (verified at debrief — all 4 hashes identical) genuinely replaces it.
- **ToS gate false-positive:** a bare-word `git grep source_quote` hits tracked dev-wiki prose that merely mentions the field → switched to a quote-agnostic `source_quote`-VALUE regex that catches a real committed provenance record but is clean on the repo.

## Open Questions

- The live T9 measurement outcome — grounding rate of a rail-BLIND extractor, real cost, the A2 dead-letter rate (directional, with binomial CI), the novelty distribution — first measured when the maintainer runs it. This is the immediate next action.
- Phase 119 = the value/headroom screen (does grounded YouTube retrieval improve a real decision vs a bare model), fed by this phase's admissible-scoped novelty-recovery distribution — the one surviving untested amplifier-null avenue (post-cutoff/proprietary content; Ph104 showed retrieval pays there).

## Artifacts Changed

- `companion/research/youtube/{seal118,select118,verify118,harness118,score118,recovery118,verdict118,run118}.py` (NEW, gitignored apparatus) + 9 `tests/test_*118.py` (~169 tests, 78→169)
- `.dev-wiki/phase-118/{pre-registration.md, prereg.sha256, rail.sha256}` (NEW tracked — params/aggregates/hashes ONLY, no verbatim; `run118/` gitignored, added to the nested `.gitignore`)
- The grounding rail (`ground/normalize/consolidate/schema.py`) stayed BYTE-FROZEN (SHA-256 verified; never edited)

## Related

- [[phase-118-youtube-frozen-live-measurement|Phase 118: YouTube grounded-acquisition frozen live measurement]] -- parent phase (status: active — BUILT, live T9 RUN pending)

## Soft Observations / Phase N+1 Candidates

- Phase 119 candidate | the value/headroom screen (does grounded YouTube retrieval beat a bare frontier model on a real decision), fed by the novelty-recovery distribution | [[youtube-frozen-live-measurement]] Consequences + this journal Open Questions
- The reusable methodological lesson (bind every decision input to a verified source; review-twice on frozen instruments) is memory-stored (mem_vOqG0DRMKsCw, mem_U0enNeZnuCAt), cross-project reusable for any pre-registered/tamper-evidence instrument.
- Review gate SATISFIED by the two adversarial-review Workflows (far more rigorous than the standard unified reviewer) — no third reviewer dispatched.
