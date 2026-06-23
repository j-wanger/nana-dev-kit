---
title: "Phase 107: Decisioning Cockpit (dashboard-as-primary gate) — tabbed cockpit, per-option reasoning+consequences, stale-brief guard, native workflow tab"
aliases: [decisioning-cockpit, dashboard-as-primary, cockpit, phase-107-cockpit]
category: decisions
tags: [dashboard, direction-dashboard, rung-c, act-from-page, decisioning-cockpit, ephemeral-server, html-generator, frontend-design, heu-012, dev-plan]
parents: [phase-107-decisioning-cockpit]
created: 2026-06-23
updated: 2026-06-23
source: plan
confidence: high
---

## Context

Phase 106 ([[project-state-dashboard]]) shipped the project-state dashboard + the opt-in act-from-page ephemeral-server gate, all tests green. The maintainer then **ran it and declared it unusable**: *"the UI is terrible, it doesn't possess enough information for anyone to even make a decision, can we not easily integrate the workflow.html file into it as a tab, and design better UI to actually help user decisioning? like every option should have reasoning and consequences mapped, right now its not usable at all."*

Two concrete defects confirmed from source (not taste): **(1) it's stale** — `make dashboard` renders whatever is in `.dev-wiki/direction-brief.json`, which is the **Phase-103 gate (5 phases old)**, with no freshness signal (the "why is this not in the dashboard now" complaint); **(2) it's thin by construction** — Ph106 cut the panes to a "STATUS+DIRECTION floor," and option cards render only `label`+`description` (`render_options`, generate-direction.py:86) — **no reasoning/consequences fields exist** in the schema or render — and `docs/workflow.html` (85K, from `generate-workflow.py`) is unlinked.

This reopened the four abstract Phase-107 forks the maintainer had been offered (post-cutoff screen / opinionated-content build / rung-D / dogfood) and **redirected** all of them: fix the dashboard he just shipped. Human-facing UI quality is **UNMEASURABLE in-kit** (the Ph59/80 carve-out): it ships on stated need + the maintainer's judgment at the delivery gate, and tests assert MECHANICS only.

## Decision

Rebuild `docs/dashboard.html` into a **tabbed decisioning cockpit** (`Status | Decide | Workflow`) that becomes the **PRIMARY `/dev-plan` direction-gate surface** — served live at each gate by the existing ephemeral `decision-server.py` — with **per-option reasoning + consequences** laid out for comparison, a **loud stale-brief guard**, and the harness **Workflow** page **re-rendered natively** into the shared visual system. This legitimately **reverses Ph106's STATUS+DIRECTION-floor subtraction** on stated need.

Direction locked across **3 AskUserQuestion rounds** (2026-06-23):
1. **Refine-the-dashboard** — the maintainer rejected the 4 abstract forks and redirected to the shipped dashboard.
2. **Dashboard-as-PRIMARY gate** (over on-demand+freshness-fix) — the ephemeral server serves the live decision at every gate by default; AskUserQuestion chips become the **fail-open fallback**. This **FLIPS Ph106's** AskUserQuestion-default / opt-in `.dev-wiki/act-from-page` marker.
3. **Re-render workflow NATIVELY** (over iframe) — refactor `generate-workflow.py` to emit content fragments the cockpit restyles into the shared system; its standalone page keeps building.

## Constraints (load-bearing)

- **Don't self-brick the gate (HARD, [[HEU-012]] / Ph82 class):** dashboard-as-default MUST fail open to AskUserQuestion on EVERY failure branch (spawn fail, render/import error, validator error, `{status:timeout}` sentinel, headless/no-browser). The default flips; the fallback never disappears — "is the fallback reachable" is a TEST, not a claim. *(Ledger A2, the HARD constraint.)*
- **No foreground sleep** (blocked in this env): the orchestrator waits on a `run_in_background` watcher; the SERVER owns the single bounded timeout.
- **Stale brief is never silently decidable:** phase-mismatch/malformed/empty → a loud banner + NO submittable form on the served page; the deterministic validator (shared by server-accept + planner-ingest) rejects a wrong-phase/wrong-nonce POST. A fresh, phase-matching brief is the ONLY decidable state.
- **`interactive=False`** → the rendered HTML contains NO form and the render path performs NO `.dev-wiki` write.
- **Keep the 5 generators separate** — import render fns / compose fragments; do NOT unify their themes; each still renders independently. The **iframe fallback is ship-blocking** (locked OUT at the gate → escalate, never ship autonomously).
- One gitignored write; stdlib-only; HTML-escape all brief text; 127.0.0.1 + port-0 only.

## Why (the maintainer's working style, reconfirmed)

He wants **visual steering surfaces he can decide on at human pace**, and he reframes guardrail-bearing infra as the kit's bet ([[direction-dashboard]], Ph99/Ph106). The Ph106 dashboard failed *because* it gave him a stale, information-thin page — exactly the friction the dashboard pillar exists to remove. The fix is information architecture for decisioning (per-option reasoning+consequences, no stale masquerade), not just prettier CSS.

## Assumptions

`all_accept: true` (ledger Phase-107). **A1** (cockpit removes friction) is the weakest + cheaply reversible (static page + AskUserQuestion fallback survive any revert) — UNMEASURABLE in-kit, ships on stated need. **A2** (fail-open holds on every branch) is the HARD constraint. **A3** (the workflow fragment seam is surgical) — if it forces a deep restyle, escalate (iframe is locked out). **A4** reasoning/consequences are authored at the gate. **A5** nonce + phase-match prevent wrong-phase ingest. **A6** dashboard-primary is interactive-only; the server-timeout is the headless backstop.

## Spec

`specs/phase-107-decisioning-cockpit.md` (nana:approved 2026-06-23; Tier-1 reviewed 7/10 → revised: the gameable reasoning/consequences criterion tightened to option-scoped containment, stale=no-form pinned, workflow structural markers, iframe-escalates, A6 timeout-backstop).
