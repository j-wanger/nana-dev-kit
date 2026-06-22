---
title: "Phase 99: Direction Dashboard — render-only visual steering surface for the /dev-plan direction gate"
aliases: [direction-dashboard, direction-gate-dashboard, design-direction-dashboard]
category: decisions
tags: [direction-dashboard, dashboard, rung-c, contract-delegation, html-generator, heu-012, dev-plan]
parents: [phase-99-direction-dashboard]
created: 2026-06-22
updated: 2026-06-22
source: plan
confidence: high
---

## Context

Phase 98 ([[frontier-watch]]) closed the rung-B watch; the Ph97 verdict located the kit's moat in opinionated, value-capturing guardrails and named **rung-C — contract-driven delegation to downstream/local workers** as a future rung. At the Phase-99 direction gate the maintainer pulled rung-C forward, reframing it away from "plumbing" into the kit's own thesis applied one level up: a frozen **contract** (clear outcome objectives + deterministic guardrails — the hooks pattern) governs a downstream worker so it stays truthful, **plus an HTML dashboard** as the human steering surface — because in-session text streams faster than the maintainer can process and steer ("output speed is too fast to keep up in pure text; visuals would help greatly").

The program has three pillars: (1) contract + fidelity spine, (2) downstream-worker execution, (3) the dashboard. The maintainer chose to build **pillar 3 first**.

## Decision

Phase 99 ships a **render-only direction dashboard**: a static HTML page that renders the `/dev-plan` **direction gate** (recommendation, option set, cost-sorted assumptions + positions) plus orienting context, so the maintainer reviews design directions visually at human pace, then answers the gate in-session.

- **Render-only, not interactive** (A1 accept): the bottleneck is *processing dense text*, not the *latency of deciding*. A read-only page solves that; a browser→session click-to-decide round-trip is a separate later pillar.
- **One-shot generator, not a live server** (A2 don't-know → down-scoped): a generated HTML file matching the existing `docs/` pattern suffices; it is a strict subset of a future watching server (which would reuse the same render function on file-change), so the choice costs nothing toward a server later. Live-server filed to Blockers with a re-trigger.
- **First surface = the direction gate** (A3 accept): higher value + self-dogfooding vs a general project-state dashboard, which becomes orienting context around the brief.
- **Small dev-plan integration** (A4 accept): dev-plan emits a structured **direction-brief** (`.dev-wiki/direction-brief.json`) at the gate so options/approach render as visuals, not just chat prose.

## Why

Prior art de-risks it: the kit already ships **three** static-HTML generators sharing a house style (`generate-report.py`, `generate-workflow.py`, `generate-delivery-report.py`) — none on the *direction/steering* side. Phase 99 adds the 4th, self-contained, matching the pattern (no shared-helper refactor, no rewrite of the other three — surgical-changes discipline). Controls-first per [[HEU-012]]: tests assert the rendered HTML *contains* the brief content and a seeded malformed brief makes the generator fail loud — clean-on-seed = dead instrument. Human-facing presentation value is unmeasurable in-kit (Ph59/80 measured *model*-facing re-presentation, a different axis), so this ships on the maintainer's stated need, not a measured lift; tests assert mechanics only.

## Alternatives considered

- **Opinionated content / ride-the-rails / rung-D generalization** (the three soft Phase-99 candidates) — superseded by the maintainer's rung-C reframe; the contract-fidelity angle reframes rung-C *as* the opinionated-guardrail bet, not plumbing.
- **Interactive click-to-decide dashboard** — deferred (A1); needs a browser→session channel the harness lacks.
- **Live always-on server** — deferred to Blockers (A2 down-scope).
- **Render existing dev-wiki files only (no dev-plan integration)** — the A4 down-scope fallback if the integration proves non-trivial.

## Consequences

A 4th `docs/` HTML artifact + `make direction` target; a documented direction-brief schema; a minimal dev-plan emission step; controls-first tests. Sets up pillars 1–2 (contract-fidelity harness, downstream/local workers) as later phases. Ledger Phase-99 (all_accept:false).

## Source

Phase 99 direction gate 2026-06-22 (ledger Phase-99). Spec `specs/phase-99-direction-dashboard.md`. Builds on [[frontier-watch]] (Ph98) / [[frontier-positioning-sweep]] (Ph97, rung-C named) and the `docs/` generator prior art. Controls-first per [[HEU-012]].
