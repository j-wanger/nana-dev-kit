# enforce-memory firing-distribution audit (Phase 95 T2)

POSITIVE-CONTROL: PASS

Feeds the T3 HARD checkpoint (keep | redesign | retire). Deterministic; reproduce with
`python3 eval/memory-disposition/tally-firing.py` (+ `--selftest`, `--verify-ingest`). Substrate = the kit's
own sessions, where `~/.claude/enforce-memory` is ARMED: 90 transcripts + `.dev-wiki/enforcement.log`
(3585 records, the hook's own JSONL firing log, `schema_version:1`).

## Method (and the corrections the Phase-95 adversarial review forced)

- Real `memory_search` calls counted as `type==assistant -> message.content[] -> tool_use, name~memory_search`
  ONLY — **never grep**. A deferred-tool catalog (attachment/system entries) names `mcp__memory__*` and
  over-counts a naive grep ~5x (32 real vs 157 raw line-hits; Phase-94 finding, re-confirmed). The
  type+tool_use gate structurally excludes it (independently re-derived: 12/17 reproduced exactly).
- **Same-session attribution** — a bite is correlated ONLY against searches in a transcript whose time-span
  contains the bite (the session active when the hook fired). The first-cut tool flattened all sessions into
  one global timeline; a different session's search could redeem a bite (a latent leak the review caught). The
  `--selftest` cross-transcript control now guards it.
- **Window band, not a point** — the first-cut headline (71% at a +20min window) was window-gamed: a single
  search ~18min after a 7-bite phase-82 burst flipped 6 bites value at exactly the 20min boundary. The honest
  read is a BAND; the `--selftest` window-cliff control guards it. No single window is privileged.
- **Episode view** — bursts of bites within 30min collapse to one blocked-episode (the phase-82 burst is ONE
  episode the agent eventually responded to, not 7 independent value events) — the honest denominator.

## Firing distribution (enforcement.log, hook=enforce-memory)

| action | reason | count | gating? |
|---|---|---|---|
| allow | allowlisted-path | 631 | no (meta/lifecycle/test/templates writes) |
| allow | memory-consulted | 160 | yes — marker was present (see caveat) |
| allow | markdown | 68 | no (`*.md` writes) |
| block | no-memory-search | **17** | yes — the BITE |

Total enforce-memory fires: 876. The hook DOES fire (no couldnt-fire question — [[HEU-012]] satisfied: 876
records, 17 real blocks across phases 82-95). Real `memory_search` calls in the corpus: **32**.

## Value vs ritual — the decision-relevant measure

**Per BITE** (real same-session `memory_search` within a post-bite window):

| window | VALUE | ritual |
|---|---|---|
| +5min | 6/17 (35%) | 11 |
| +10min | 6/17 (35%) | 11 |
| +15min | 6/17 (35%) | 11 |
| +20min | 12/17 (70%) | 5 |
| +30min | 12/17 (70%) | 5 |

→ **follow-through is a 35-70% band, window-dependent — not a single point.**

**Per EPISODE** (bursts collapsed; the honest denominator): **11 blocked-episodes, 6 led to a real
same-session search (~55%), 5 were ritual** (marker-touch with no real search in-session). The 5 ritual
episodes: phase 85, 87, 88, 91, 95.

## What this says (findings, not the disposition)

1. **enforce-memory creates real consultation roughly half the time it bites** (~55% of episodes; 35-70% per
   bite). It is neither pure ritual nor reliably value-bearing — it is a partial nudge.
2. **The mechanism is gameable by construction.** The hook checks `.claude/.memory-consulted` EXISTENCE; the
   agent touches that marker itself (observed live THIS session — the hook blocked a `.sh` write, then the
   marker was touched to proceed). The 160 `memory-consulted` allows attest a marker was present, NOT that a
   search ran — they are NOT counted as value evidence (the marker is agent-attested).
3. **NO subsystem-zero is cited.** Reinforcement-count / access_count zeros are couldnt-fire (fastembed-gated)
   and are not used here ([[HEU-012]]).
4. **Corroborating (Phase 94, [[consumer-memory-remeasure]]):** the rules+hooks consumer (aml-substrate) had
   the highest value-bearing demand (44 rows, 25 read-back) vs rules-only (aml-casework 20 rows, 10 read-back)
   — suggestive that the hook adds demand over rules alone, BUT confounded with domain/task-mix (both are
   AML). The hook's clean MARGINAL value over the always-loaded rules-nudge is NOT isolated.

## Scope / caveats

- Kit-side measurement (the maintainer's sessions). Consumer-side firing lives in each consumer's own
  `.dev-wiki/enforcement.log`; aml-substrate is the only armed consumer and corroborates direction (above).
- Same-session attribution uses transcript time-span containment; two time-overlapping sessions could in
  principle share credit, but the window-cliff and cross-transcript `--selftest` controls bound the error and
  the per-episode reading is robust to it.
- "Value" = a real search happened in-session near the bite; it does NOT grade whether the retrieved memory
  changed the downstream action (same limitation as Phase 94's read-back).
