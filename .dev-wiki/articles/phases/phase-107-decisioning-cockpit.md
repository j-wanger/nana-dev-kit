---
title: "Phase 107: Decisioning Cockpit (dashboard-as-primary gate)"
aliases: [phase-107, decisioning-cockpit, dashboard-as-primary, cockpit]
category: phases
tags: [dashboard, direction-dashboard, rung-c, act-from-page, decisioning-cockpit, ephemeral-server, html-generator, frontend-design, heu-012, dev-plan]
parents: [decisioning-cockpit]
created: 2026-06-23
updated: 2026-06-23
source: plan
status: completed
scope: ["scripts/generate-direction.py", "scripts/generate-dashboard.py", "scripts/generate-workflow.py", "scripts/decision-server.py", "scripts/validate-decision-response.py", "tests/test_dashboard.sh", "tests/test_decision_server.sh", "tests/test_dashboard_roundtrip.sh", "tests/test_scripts_smoke.sh", "tests/fixtures/dashboard-brief.cockpit.json", "tests/fixtures/dashboard-brief.stale.json", "Makefile", "README.md", "docs/dashboard.html", "docs/workflow.html", "templates/.claude/skills/dev-plan/direction-brief.md", "templates/.claude/skills/dev-plan/assumption-gate.md", "templates/.claude/skills/dev-plan/SKILL.md", "templates/.claude/skills/MANIFEST"]
entry_criteria: "Ph106 delivered + accepted 2026-06-23. The maintainer ran the shipped dashboard and found it unusable ('the UI is terrible, not enough info to make a decision, not usable at all'); redirected the 4 abstract Ph107 forks to fixing it. Direction locked across 3 AskUserQuestion rounds: refine-the-dashboard → dashboard-as-primary (flip Ph106's default) → re-render workflow natively (not iframe)."
exit_criteria: "make test green at 33 registered scripts (README matches, MANIFEST fresh); make dashboard exits 0 → docs/dashboard.html as a tabbed cockpit (Status|Decide|Workflow), exit 0 on a nonce-less and on a stale brief (stale → loud banner, not a silent decidable form); per-option reasoning+consequences render option-scoped; the Workflow tab carries native re-rendered content (≥2 distinct section markers, no iframe) AND generate-workflow.py still builds docs/workflow.html standalone; the stale-brief guard fires on a seeded phase-mismatch fixture; the served path falls open to AskUserQuestion on spawn-fail/timeout/headless (asserted by a test); validate-decision-response.py still the shared boundary; make eval unchanged (52); drift 0; zero settings.json change."
---

# Phase 107: Decisioning Cockpit (dashboard-as-primary gate)

## Objective

Rebuild `docs/dashboard.html` into a **tabbed decisioning cockpit** (`Status | Decide | Workflow`) that becomes the **primary `/dev-plan` direction-gate surface** — served live at each gate by the existing ephemeral `decision-server.py` — with **per-option reasoning + consequences** laid out for comparison, a **loud stale-brief guard**, and the harness **Workflow** page **re-rendered natively** into the shared visual system. AskUserQuestion stays the fail-open fallback. Reverses Ph106's STATUS+DIRECTION-floor subtraction on stated need. Decision [[decisioning-cockpit]].

## Context

The maintainer ran the Ph106 dashboard and declared it unusable. Two confirmed defects: it silently renders a 5-phase-stale Phase-103 brief, and option cards carry only label+description (no reasoning/consequences fields exist). UI quality is UNMEASURABLE in-kit (Ph59/80 carve-out) → ships on stated need + judgment at the delivery gate; tests assert MECHANICS only.

## Tasks (5)

- **T1 [M]** Brief schema (per-option reasoning+consequences) + deterministic stale-brief guard — the boundary, FIRST.
- **T2 [L]** Decisioning cockpit render: tabbed shell + comparable option cards + stale-banner-no-form + frontend-design visual pass.
- **T3 [M]** Workflow tab — native fragment re-render (not iframe), standalone generator preserved.
- **T4 [M]** Dashboard-as-primary gate flow (don't-self-brick) + served-path stale guard + companion flip.
- **T5 [S]** Discovery-maintenance + full suite green.

## Gates

- [x] Direction confirmed by user (3 AskUserQuestion rounds 2026-06-23; ledger Phase-107, all_accept:true).
- [x] Delivery accepted (2026-06-23; 5/5 tasks; adversarial review SHIP + 2 LOW fixed inline).
