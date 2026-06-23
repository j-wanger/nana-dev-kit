---
title: "Phase 107 — Decisioning Cockpit (dashboard-as-primary gate): delivered + accepted"
date: 2026-06-23
tags: [dashboard, decisioning-cockpit, rung-c, act-from-page, frontend-design, gate-flow, heu-012]
phase: 107
---

# Phase 107 — Decisioning Cockpit (dashboard-as-primary gate)

## What shipped

The maintainer ran the Ph106 dashboard and found it **unusable** ("the UI is terrible, it doesn't possess enough information for anyone to even make a decision, can we not easily integrate the workflow.html file into it as a tab... every option should have reasoning and consequences mapped, right now its not usable at all"). This redirected the four abstract Ph107 forks (post-cutoff screen / opinionated-content / rung-D / dogfood) to **fixing the shipped dashboard**.

Rebuilt `docs/dashboard.html` into a **tabbed decisioning cockpit** (Status | Decide | Workflow), now the PRIMARY `/dev-plan` direction-gate surface:
- **T1** — brief schema gains optional per-option `reasoning`/`consequences` (backward-compatible) + a deterministic `is_stale(brief, active_phase)` guard.
- **T2** — `render_dashboard` rebuilt as a tabbed cockpit in a deliberate dark "control-instrument" visual system (consulted the `frontend-design` skill — monospace structure + sans prose, semantic green/amber/red); option cards carry paired Reasoning/Consequences zones; a stale brief → loud banner + no form.
- **T3** — `generate-workflow.py` gains `render_fragments()`; the Workflow tab re-renders natively (no iframe); the standalone `docs/workflow.html` is byte-untouched.
- **T4** — `decision-server.py` serves the cockpit + refuses a stale gate (409 before any body read); the dev-plan companions flipped to **dashboard-as-primary** (default for interactive sessions, AskUserQuestion the fail-open fallback on every branch — scripts-absent / headless / opt-out / spawn-fail / timeout).
- **T5** — count 33/33, MANIFEST fresh, gitignore + the `.dev-wiki/no-act-from-page` opt-out.

**Root-cause fix demonstrated:** `make dashboard` on the live brief now renders a loud "Stale gate" banner (the Phase-103 brief, 5 phases old) instead of silently presenting it as decidable — the "why is this not in the dashboard now" defect.

## Problems encountered

- **Stale-guard ripple:** adding the stale guard meant the served brief (phase 106 fixture) was now "stale" vs the live active phase (107), which would have broken the existing S1/R1 server tests. Fixed by adding `--active-phase` to the server (mirroring `build_panes`), so tests inject the phase deterministically (decoupled from the live `active-phase.md`, which advances each phase — Ph80 robustness). The in-process S4lat latch test had to inject it too, or the latch would pass for the wrong reason (a stale 409 firing before the latch).
- **bash apostrophe-in-heredoc gotcha:** a comment containing `brief's` inside a `$(python3 - <<'PY' … PY)"` command substitution broke macOS bash 3.2 parsing (it treats `'` as opening a quote in `$()` even inside a heredoc body). Fixed by passing the value via argv (no inner quotes).

## Health Delta

`make test` green; `make eval` 50/50 (the real count is 50 — Ph106's "52" was a stale note); zero settings.json change; no new scripts/tests (workflow + stale assertions folded into existing suites → count stays 33). The kit↔`~/.claude` install drift is exactly the 3 edited dev-plan companions (the `scripts/*.py` aren't installed) — clears on the maintainer's next `install.sh` re-sync, which is when the live dashboard-primary flow activates.

### Review Gate

L/Standard phase → unified adversarial reviewer dispatched on the gate-flow changes. Verified all 7 load-bearing invariants empirically (don't-self-brick/fail-open, interactive=False no-form, stale-guard order [409 before body read], boundary validator unchanged, fail-soft native workflow, HTML escaping, CSS class collisions). Verdict **SHIP**; 2 LOW cosmetics (phase-0 falsy fallback, a stale POST-guard docstring) fixed inline.

### Gate Compliance

direction=confirmed + delivery=accepted both present. Ledger Phase-107 all_accept:true; revisit-status all `held` (no late bites at close).

## Soft Observations / Phase N+1 Candidates

- **Dogfood the live round-trip (highest value).** The full *orchestrator spawns server → run_in_background watch → ingest* loop with a real browser is mechanically tested but NOT yet exercised end-to-end. The maintainer's NEXT `/dev-plan` gate (after an `install.sh` re-sync) is its first live test — watch for friction A1 predicts. Evidence: this phase's own gate ran via AskUserQuestion (the cockpit scripts existed but the flip post-dates this run).
- **A1 (cockpit-removes-friction) is unmeasurable in-kit and the weakest assumption** — only real usage tells; cheaply reversible (revert the render, keep schema + stale-guard). Re-confirm or retire after a few live gates.
- **Consumer reach is unaddressed by design** — the cockpit is kit-internal (`scripts/` isn't installed to consumers). If decisioning-on-a-page is wanted for consuming projects, that's a separate phase (ship the generators).
