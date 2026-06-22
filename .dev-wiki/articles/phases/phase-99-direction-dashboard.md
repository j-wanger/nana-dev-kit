---
title: "Phase 99: Direction Dashboard (render-only, dashboard-first)"
aliases: [direction-dashboard, direction-gate-dashboard]
category: phases
tags: [direction-dashboard, dashboard, rung-c, contract-delegation, html-generator, heu-012]
parents: [direction-dashboard]
created: 2026-06-22
updated: 2026-06-22
source: plan
status: completed
scope: ["scripts/generate-direction.py", "Makefile", "docs/direction.html", "tests/test_direction_dashboard.sh", "tests/fixtures/**", "templates/.claude/skills/dev-plan/**", ".dev-wiki/**"]
entry_criteria: "Ph98 delivered + accepted (fb82864); rung-C pulled forward + dashboard-first selected by the maintainer; direction gate closed 2026-06-22 (ledger Phase-99)."
exit_criteria: "Render-only generate-direction.py + make direction + controls-first tests (content-present + recommended-highlight + seeded-malformed fail-loud); Phase-99 dogfood brief renders; dev-plan direction-brief companion + reference; make test PASS, make eval 50/50, drift 0; A2 live-server Blockers re-trigger filed."
---

# Phase 99: Direction Dashboard (render-only, dashboard-first)

## Objective

Make design directions legible at human pace by rendering the `/dev-plan` **direction gate** as a static, scannable HTML page — recommendation, option set, and cost-sorted assumptions + positions, plus orienting context — so the maintainer reviews visually instead of parsing a fast in-session text stream, then answers the gate in-session. This is **pillar 3 (the dashboard) of the rung-C contract-driven-delegation program**, delivered FIRST per the maintainer's direction; the contract-fidelity harness and downstream/local workers (pillars 1–2) are later phases.

## Approach

A self-contained Python generator (`scripts/generate-direction.py` → `docs/direction.html`, `make direction`), the 4th member of the existing `docs/` HTML-generator family and matching its house style (inline CSS, cards/tables, no server/JS framework). It reads a structured **direction brief** (`.dev-wiki/direction-brief.json`) for the gate content and dev-wiki files for orienting context, and renders: recommendation up top, options as cards (recommended highlighted), cost-sorted assumptions as a table with positions/resolutions, orienting context (active phase + open decisions) alongside. A minimal `/dev-plan` integration documents the brief schema + an emission step so future gates emit a brief and generate the page *before* asking for positions.

## Key decisions

- **Render-only** (A1): the page is read; decisions stay in-session. Interactive click-to-decide is a later pillar.
- **One-shot generator, not a live server** (A2 don't-know → down-scoped; live-server → Blockers re-trigger).
- **First surface = the direction gate** (A3); general state/roadmap is orienting context around it.
- **Small dev-plan brief-emission integration** (A4; down-scopes to render-existing-files-only if non-trivial).
- **Controls-first / [[HEU-012]]**: tests assert the rendered HTML *contains* the brief content; a seeded malformed brief MUST fail the generator loud. Judgment, not measurement (Ph59/80 are model-facing).

See [[direction-dashboard]] (decision) and `specs/phase-99-direction-dashboard.md`.

## Tasks

T1 [M] generator + brief schema · T2 [S] controls-first robustness + recommended-highlight + test registration · T3 [S] dev-plan brief-emission integration · T4 [S] dogfood + close-out. See `.dev-wiki/tasks.md`.

## Status

COMPLETED + DELIVERY ACCEPTED 2026-06-22 (work commit 46473a7; 4/4 tasks; review gate CLEAN + 1 LOW [esc→html.escape] fixed inline). Direction gate closed (ledger Phase-99; all_accept:false). make test PASS, make eval 50/50, drift 0.
