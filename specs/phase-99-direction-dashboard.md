<!-- nana:approved 2026-06-22 (dev-plan --internal) -->
# Spec: Phase 99 — Direction Dashboard (render-only, dashboard-first)

## Objective

Make design directions legible at human pace by rendering the `/dev-plan` **direction gate** as a static, scannable HTML page — so the maintainer reviews the recommendation, options, and cost-sorted assumptions visually instead of parsing a fast in-session text stream, then answers the gate in-session. This is **pillar 3 (the dashboard) of the rung-C contract-driven-delegation program**, delivered FIRST per the maintainer's direction; the contract-fidelity harness and downstream workers (pillars 1–2) are later phases.

## Context

The maintainer cannot process the rate/density of in-session text fast enough to steer design directions ("output speed from agents is too fast to keep up and process in pure text; a dashboard with visuals would help greatly"). The Ph97 frontier verdict located the kit's moat in *opinionated, value-capturing guardrails*; rung-C applies that thesis to delegation. Phase 99 starts at the human-interaction surface.

Prior art lowers the risk: the kit already ships **three** static-HTML generators sharing a house style (inline CSS, cards/tables, no server/JS framework, output to `docs/`) — `generate-report.py` (package), `generate-workflow.py` (harness), `generate-delivery-report.py` (the *delivery* gate). None covers the *direction/steering* side. Phase 99 adds the 4th, on the input side.

Direction gate (2026-06-22, ledger Phase-99, all_accept:false): A1 render-only **accept** (bottleneck is processing text, not decide-latency), A2 generator-vs-server **don't-know → down-scoped** to the generator (strict subset of a future watching server; live-server filed to Blockers), A3 first-surface = direction gate **accept**, A4 small dev-plan brief-emission integration **accept**.

## Scope

### In scope
- `scripts/generate-direction.py` → `docs/direction.html`: render-only generator reading a structured **direction brief** plus dev-wiki context; self-contained, matching the existing 3 generators' house style.
- A documented **direction-brief schema** (`.dev-wiki/direction-brief.json`): recommendation/approach, option set (label/description/recommended), cost-sorted assumptions (id/cost/text/position/resolution), phase + objective.
- `Makefile` `direction` target; `tests/test_direction_dashboard.sh` registered in `make test`.
- A minimal `/dev-plan` integration: a `direction-brief.md` companion (schema + emission step) under `templates/.claude/skills/dev-plan/`, referenced from the assumption-gate step — emit brief → `make direction` → point the user at `docs/direction.html` → then take positions.
- Dogfood: Phase 99's own direction brief rendered.

### Out of scope
- The contract-fidelity harness and downstream/local (opencode) workers — pillars 1–2, later phases.
- Any **interactive** click-to-decide round-trip (browser → session) — deferred (A1 boundary).
- An always-on **live server** that watches files and auto-re-renders — deferred to Blockers (A2 down-scope).
- Refactoring the 3 existing generators into a shared HTML helper (surgical-changes discipline; a separate cleanup if ever justified).
- Any kit code change beyond the above; no `modules.json`/hook changes.

## Approach

A self-contained Python generator (matching the existing 3) reads `.dev-wiki/direction-brief.json` for the gate content and the dev-wiki files (`_CURRENT_STATE.md` recommended-next-action/active-phase, `assumption-ledger.md` positions, open `Blockers`) for orienting context, and writes one self-contained `docs/direction.html`: recommendation up top, options as cards (recommended highlighted), cost-sorted assumptions as a table with positions/resolutions, orienting context alongside. `/dev-plan` (future runs) writes the brief and generates the page at the gate *before* asking for positions, so the maintainer reviews visually then decides.

## Constraints
- **Render-only** — the page is read; decisions happen in-session (A1). No server, no browser→session channel.
- **Controls-first / [[HEU-012]]** — tests assert the rendered HTML *contains* the brief's content (recommendation, every option label, every assumption text), not merely that the file exists; a seeded **malformed brief** (bad JSON / missing required field) MUST make the generator fail loud (non-zero exit + stderr), never silently emit an empty/broken page. Clean-on-seed = dead instrument.
- **Match the surrounding code** — self-contained generator in the established house style; do not introduce a shared helper used by only one caller, do not rewrite the other three.
- **Judgment, not measurement** — human-facing presentation value is unmeasurable in-kit (Ph59/80 are *model*-facing); shipped on the maintainer's stated need. Tests assert mechanics only.
- **Parity** — the dev-plan companion ships in `templates/`; `~/.claude` is synced via `install.sh --update` (drift accounts for the new file).

## Checkpoints
- After T1: the generator renders a fixture brief end-to-end (content present) before hardening.
- After T4 (close-out): `make test` ALL-PASS, `make eval` unchanged, drift 0, the Phase-99 dogfood page renders, and the A2 live-server re-trigger is filed.

## Assumptions
(Direction-gate ledger Phase-99; revisit at debrief.)
- A1 render-only relieves the pain (accept).
- A2 generator suffices over a live server (don't-know → down-scoped; Blockers re-trigger).
- A3 the direction gate is the right first surface (accept).
- A4 a small dev-plan brief-emission integration is in-scope (accept; down-scopes to render-existing-files-only if non-trivial).

## Exit Criteria
- [ ] `bash tests/test_direction_dashboard.sh` passes: from a valid fixture brief, `docs/direction.html` CONTAINS the recommendation text, every option label, and every assumption text; the recommended option is marked.
- [ ] Controls-first: a seeded malformed brief (bad JSON; missing required field) makes `generate-direction.py` exit non-zero with a stderr message; clean-on-seed would fail the test.
- [ ] `make direction` generates `docs/direction.html` from `.dev-wiki/direction-brief.json`; the page renders recommendation + option cards (recommended highlighted) + cost-sorted assumptions table (with positions) + orienting context.
- [ ] Dogfood: Phase 99's own direction brief (`.dev-wiki/direction-brief.json`) renders correctly.
- [ ] `/dev-plan` integration: `templates/.claude/skills/dev-plan/direction-brief.md` documents the schema + emission step and is referenced from the assumption-gate step.
- [ ] `make test` ALL-PASS (new test registered); `make eval` denominator unchanged (50/50); kit `check-install-drift` drift 0.
- [ ] Blockers: A2 live-server question filed with a concrete re-trigger; `## Phase 99` window-events append; decision article written.
