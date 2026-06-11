---
title: "Dogfood & Demand-Evidence Round"
aliases: [phase-89-approach]
category: decisions
tags: [dogfood, trim-trial, memory-layer, demand-evidence, pre-registration, edge-screener]
parents: [trim-follow-on-round]
created: 2026-06-11
updated: 2026-06-11
source: plan
confidence: high
status: active
---

# Dogfood & Demand-Evidence Round (Phase 89)

## Decision

Run Phase 89 as a pre-registered, four-stage evidence round (spec
`specs/phase-89-dogfood-demand-evidence.md`, nana:approved 2026-06-11): **T1** pre-registration
commit FIRST (session-evidence schema with trigger-reachability fields and three-class memory-call
classification `hook-prompted | rules-instructed | spontaneous`; window-events designed as a
CROSS-PHASE accumulator that Phases 90-93 sessions keep appending to until the Phase-93
disposition; admissibility pins citing the A4 reject rationale + Phase-83 keep-with-revisit
filing; wk-seeding pinned-decision inventory; baseline header pinning kit HEAD SHA + sync
timestamp + resolved-surface hashes) + deterministic checkers with seeded-failure selftests
(tasks T1-T3) → read-only probes (memory-layer liveness, edge-screener surface currency,
enforce-memory marker states) → HARD maintainer checkpoint → checkpoint-gated edge-screener
re-sync (template-sourced `--project-local` + rehearsed basename-normalized jq deregistration
of the cut detect-loop from settings.local.json, backup + tested restore — install.sh cannot
remove registrations) (task T4) → ≥3 real-work sessions on edge-screener's own agenda with
measurement-blind archived prompts; session 1 shaped as a real `/dev-plan` Phase-10 planning
session (trigger-reachable BY ITS NATURE: planning decisions made, pinned decisions in scope —
counters the weakest assumption that headless sessions structurally cannot reach either trigger)
→ **T4** close-out (per-class tallies, writer write/read-back counts, A4/A6 evidence filing in
Blockers, exit-criteria runner ALL-PASS with seeded-failure control).

Evidence only, never disposition: trim restore-or-confirm belongs to the Phase-93 debrief;
memory-layer keep/cut to a future prune round. `templates/**`, `modules.json`, `MANIFEST`
byte-untouched over the pinned phase range (`<pre-registration first-add commit>..HEAD`); no
reverts of d43950f/df3e623/75b48af/b8bd416.

## Why

- The windows went live only today (install sync 2026-06-11, drift 0) with ZERO exposure;
  unobserved windows close vacuously at Phase 93.
- A4 reject ruled the Phase-85 dogfood zero inadmissible; A6 kept the writers alive precisely so
  this round could collect clean demand evidence — spontaneous-vs-coerced-vs-instructed
  classification is the load-bearing distinction (memory layer is the VOLUNTARY class;
  [[mandatory-automatic-voluntary]]).
- Edge-screener verified PRE-trim live (detect-loop.sh present + registered; check-tests-were-run
  hash ≠ template) — evidence on pre-trim surfaces is invalid as post-trim exposure, so the
  re-sync precedes sessions, behind the out-of-repo HARD checkpoint.
- Edge-screener is standard ceremony, so its dev-plan/debrief sessions exercise the A6-kept
  bridge/harvest writers — write-side liveness vs read-back demand is observable there.

## Alternatives considered

- One-phase observation burst (windows observed only in Phase 89) — rejected: the windows run
  through Phase 93; the durable deliverable is the cross-phase accumulator + protocol, with
  Phase 89 contributing the first probative entries.
- Sessions before re-sync (start collecting immediately) — rejected: pre-trim surfaces make the
  exposure invalid and the pre-harden check-tests-were-run noise class would contaminate tallies.
- Skipping the pinned-decision inventory — rejected: without it the wk-seeding trigger is
  unfalsifiable in edge-screener context and zeros there would masquerade as confirming.

## Review incorporation (Step 12, reviewer 9/10 accept)

- Accumulator activation: the Phases-90-93 append obligation is pinned in always-loaded
  `.claude/rules/active-phase.md` at close-out — mandatory, not voluntary ([[HEU-012]],
  [[mandatory-automatic-voluntary]]).
- Classification authority: reachability records + call classification are orchestrator-executed
  deterministic rules pinned at pre-registration — never session self-attestation (Ph82 standard).
- Kit-side reachability records carry a `WK-already-presents-it` non-probative subclass (the
  wk-seeding trigger is structurally suppressed in-kit while WK entries decay in place).
- The jq deregistration is rehearsed on a copy of the ACTUAL edge-screener settings.local.json
  before the checkpoint, not only the kit fixture.
- Pre-registration also pins, blind, the boundary ruling for a `rules-instructed` session-start
  search whose result is subsequently USED (instructed read, genuine read-back value) — the case
  the future prune round will argue about.

## Source

Phase 89 planning, 2026-06-11. Spec: `specs/phase-89-dogfood-demand-evidence.md`.
Gate: closed 2026-06-11 (all_accept:true; A2 accept-defended after don't-know — live
transcript-observability probe; ledger block appended).
