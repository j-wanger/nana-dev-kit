---
title: "Phase 106: Project-State Dashboard + Act-from-Page Decision Gate"
aliases: [phase-106, project-state-dashboard, act-from-page-gate]
category: phases
tags: [dashboard, direction-dashboard, rung-c, act-from-page, ephemeral-server, decision-boundary-validator, html-generator, heu-012, dev-plan]
parents: [project-state-dashboard]
created: 2026-06-23
updated: 2026-06-23
source: plan
status: completed
scope: ["scripts/generate-dashboard.py", "scripts/validate-decision-response.py", "scripts/decision-server.py", "tests/test_dashboard.sh", "tests/test_decision_server.sh", "tests/test_dashboard_roundtrip.sh", "tests/fixtures/dashboard-*", "tests/fixtures/decision-response.*", "Makefile", ".gitignore", "README.md", "templates/.claude/skills/dev-plan/*.md", "templates/.claude/skills/MANIFEST"]
entry_criteria: "Ph105 delivered + accepted + committed (a3657e6, 2026-06-23); maintainer chose a NEW direction over the three Ph105 NEXT candidates — extend Ph99's direction dashboard into a project-state monitoring + act-from-page decision surface. Direction locked across 4 AskUserQuestion gates."
exit_criteria: "make test green at 33 registered scripts (README matches, MANIFEST fresh); make dashboard exits 0 → docs/dashboard.html; the 3 controls-first test scripts pass (incl. every seeded-defect control firing); validate-decision-response.py shared by server + ingest; default no-marker path provably never spawns the server; eval 50/50; drift 0; zero settings.json change."
---

# Phase 106: Project-State Dashboard + Act-from-Page Decision Gate

## Objective

Extend Phase 99's render-only direction dashboard into (1) an **on-demand `make dashboard` project-state monitoring page** and (2) an **opt-in act-from-page direction gate** where the maintainer makes the phase decision ON a served dashboard that drives `/dev-plan` — pulling forward Ph99's deferred A2 (served surface) and A3 (general project-state). AskUserQuestion stays the default + fail-open fallback; exactly one gitignored repo write; no daemon, no new gate semantics. **Pillar 3 of the rung-C program, extended.** See [[project-state-dashboard]].

## Approach

Three stdlib-only scripts, behind the boundary contract:
1. `validate-decision-response.py` (T1, first) — ONE deterministic validator RUN by both the server POST and the dev-plan ingest (no neural judge at the boundary).
2. `generate-dashboard.py` (T2) — static `make dashboard` page; `render_dashboard(panes, interactive=False)`; **imports** the brief-render fns from `generate-direction.py` (anti-drift); thin STATUS digest + DIRECTION pane; Architecture/Decisions panes CUT to the floor.
3. `decision-server.py` (T4) — ephemeral 127.0.0.1:0 server; serves the live interactive dashboard; `POST /decision` with Origin/Host/Content-Length/chunked guards + single-accept latch + atomic `mkstemp→fsync→os.replace` + off-thread shutdown; **server owns the single watchdog** (writes `{status:timeout}` sentinel on expiry).

dev-plan integration is marker-gated (`.dev-wiki/act-from-page`): absence = today's AskUserQuestion path (server never spawns); presence = serve + `run_in_background` watch on ONE file condition (valid decision vs timeout sentinel) + consume-once ingest via the validator + fall-open to AskUserQuestion on every failure. The ledger-append / resolution / all-accept rules are channel-agnostic and UNCHANGED.

## Scope

IN: the 3 scripts + `make dashboard` target/.PHONY/smoke + `.gitignore` of transient artifacts + 3 controls-first tests + fixtures + dev-plan companion edits (direction-brief.md / assumption-gate.md / SKILL.md Step 13, opt-in marker + optional nonce + fail-open) + discovery maintenance (README 30→33, MANIFEST md5 for 2 companions).
OUT: any daemon; Architecture/Decisions panes; a YAML/list parser or decisions grid; a shared-scaffold refactor of the 5 generators (themes diverge); any new gate semantics / eval scenario (50 stays 50) / hook registration; editing the live `.dev-wiki/` living docs (render-only consumer).

## Direction gate (4 rounds → Continue)

1. Direction: a project-state monitoring dashboard, extension of Ph99 (over the three Ph105 NEXT candidates a/b/c). 2. Persistence: on-demand regen ("on-demand is fine, except how do I drive phase decisions from there?"). 3. Drive mode: act-from-page. 4. Write channel: ephemeral server (the maintainer's "dashboard writes a file the Claude Code process monitors", once the file:// sandbox constraint was surfaced). Then "Continue" → 6 build-assumptions accepted (ledger Phase-106, all_accept:true; A1 the round-trip-removes-friction bet flagged weakest + cheaply reversible). Design hardened by a 13-agent ground+adversarial-stress workflow (6 failure-mode lenses).

## Health

Target: nana-dev-kit `make test` green at 33 scripts, `make eval` 50/50, drift 0, zero settings.json change. Apparatus ships in-repo (scripts/ + tests/ + docs/dashboard.html); the only gitignored runtime artifact is `.dev-wiki/decision-response.json` + `.dev-wiki/.decision-server.url` + `.dev-wiki/act-from-page`.
