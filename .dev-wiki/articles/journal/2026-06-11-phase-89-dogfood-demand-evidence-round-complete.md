---
title: "Phase 89 complete — Post-Trim Dogfood & Demand-Evidence Round"
aliases: []
category: journal
tags: [dogfood, trim-trial, memory-layer, demand-evidence, edge-screener, pre-registration]
parents: [phase-89-dogfood-evidence-round]
created: 2026-06-11
updated: 2026-06-11
source: debrief
duration: unknown
---

# Phase 89 complete — Post-Trim Dogfood & Demand-Evidence Round

## What Happened
- 6/6 tasks executed in pre-registered order: T1 pre-registration commit FIRST (45460bc — anti-retrofit ancestry guard), T2 evidence checkers (cfbfa66), T3 guard checkers + runner (59afc2b), T4 read-only probes + HARD checkpoint + gated edge-screener re-sync (45e591d), T5 three real headless evidence sessions + orchestrator extraction (98dffb8), T6 close-out with runner ALL-PASS 10/10 (ca81ff9), review-gate fixes (a2b65ce).
- Evidence-only phase honored: templates/, modules.json, MANIFEST byte-untouched (check-no-disposition + reviewer-verified); NEW eval/dogfood-round/ apparatus (7 selftested checkers, pre-registration, evidence corpus).
- A4/A6 demand evidence landed clean: edge-screener tallies ALL-ZERO on a liveness-probed live layer (three-way-clean: no hook coercion, rules-instructed search skipped, no spontaneous use); kit-side writer LIVE (2 bridge stores, 1 read-back). The multi-session continuity case (the layer's design purpose) arose naturally and was served entirely by the .dev-wiki file substrate.
- DISCOVERY (minor, escape hatch): mid-T5 the orchestrator committed its own T4 re-sync changes into edge-screener's repo (ed7503d there) — the pinned clean-tree session precondition required it; noted in T5 evidence provenance.
- Execution-time rulings (instructed-with-readback boundary, removed/suppressed/prospective inventory classes, unreached-not-declined writer classification) live in the committed pre-registration.md by design — no new decision articles this debrief.

## Decisions Made
- [[dogfood-demand-evidence-round]] — articled at plan (high); gate closed all_accept:true with A2 accept-defended. No new articles.

## Review Gate
Score 9/10 accept. MEDIUM: pre-registration removed-class inventory pinned from uncommitted working tree — corrected via append-only Addendum 1 + committing the curator prune; no row re-graded. LOWs fixed inline: check-currency legacy flat-form parsing; decision-article stage labels vs task ids; spec c10 overstatement. Reviewer independently re-verified: all 7 selftests, frozen-path diff empty, header hashes, transcript mtimes, log-delta chain, ledger consistency.

## Assumption-Ledger Revisit
- A1 held (3 probative ak sessions), A2 held (classification computed from transcripts; couldnt-find caveat recorded), A3 held (post-resync CURRENCY PASS + survivor smoke), A5 held (headless driver recorded per block).
- **A4 BIT**: the "planning input ready" sub-premise was false — already consumed by the Phase-87 arm-A ship (a6effcb) — and altered session 1's course mid-session; the ≥3-real-sessions substance held via reframing. Suggest the maintainer review [[dogfood-demand-evidence-round]] confidence (no auto-mutation); stale-premise class noted below.

## Problems Solved
- py-review Stop-blocked on docs-only diffs in 2/3 evidence sessions — correct outcome, one wasted Stop cycle each; filed as harden candidate (Blockers).
- Headless agent declared the memory tool unavailable rather than ToolSearch-ing — tallied as couldnt-find ≠ no-demand per the pre-registration pin.

## Open Questions
- edge-screener Phase-10 direction gate pending (3 assumptions awaiting Jake — filed in Blockers).
- _CURRENT_STATE.md chronically over the 100-line budget (176 lines, pre-existing) — structural housekeeping candidate.

## Artifacts Changed
- `eval/dogfood-round/**` (NEW: pre-registration + addendum, 7 checkers w/ selftests, evidence/ [header, liveness-probe, sessions, window-events, memory-demand, prompts/], rehearsals/, run-exit-criteria.sh ALL-PASS 10/10)
- `.claude/rules/active-phase.md` (Phases 90-93 window-events append obligation — mandatory activation point)
- out-of-repo: edge-screener re-synced post-trim (detect-loop deregistered; b8bd416 harden live there; ed7503d in its repo)
- Health: make test green (27 scripts), make eval 50/50 (denominator unchanged)

### Retro Check (Phases 85-89)

| Dimension | Findings | Signal |
|-----------|----------|--------|
| 1. Recurring Blockers | Stop-hook noise on non-code work, 2 instances (Ph85 check-tests-were-run Read false-positive; Ph89 py-review docs-only block ×2 sessions) — both filed as harden candidates | high |
| 2. Decision Reversals | 1 — Ph88 wk-seeding planning-time claim execution-corrected (loader misattribution; trials revert-coupled); no confidence downgrades | low |
| 3. User Corrections | Corrections concentrate at gates (continues 81-85 pattern): Ph86 A1 round-2 reject, Ph88 A4+A6 rejects, Ph87/89 don't-know→defend rounds; 4 ledger bits in 5 phases (85/86/87 A2, 89 A4) — ALL absorbed by pre-declared branches | high (structurally absorbed) |

Recommendations: bundle the two Stop-hook noise harden candidates into the next hook-hardening round; adopt a consumed-marker convention for planning inputs that feed experiments (the A4 stale-premise class); the assumption gate keeps doing the correcting — no dedicated improvement phase needed beyond the filed candidates.

## Soft Observations / Phase N+1 Candidates
- py-review docs-only Stop-block | next hook-hardening round (pairs with Ph85 ctw finding) | Blockers noise-candidate filing
- Deferred-tool discoverability suppresses voluntary MCP use (couldnt-find ≠ no-demand) | memory-layer disposition round input | pre-registration pin + memory mem_D3JFhJCVd1Vm
- Continuity case served entirely by .dev-wiki file substrate | framing input for the future A4/A6 prune round | evidence/memory-demand.md
- Stale-premise class: consumed-marker convention for planning inputs | small process fix or filing next phase | ledger A4 bit
- _CURRENT_STATE.md 176/100 lines chronic | housekeeping candidate | size-budgets.md

## Related
- [[phase-89-dogfood-evidence-round|Phase 89: Post-Trim Dogfood & Demand-Evidence Round]] — parent phase
