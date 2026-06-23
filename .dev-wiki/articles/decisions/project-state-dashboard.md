---
title: "Phase 106: Project-State Dashboard + Act-from-Page Decision Gate — opt-in ephemeral-server write-channel, render-only monitoring floor"
aliases: [project-state-dashboard, act-from-page-gate, dashboard-decision-server, phase-106-dashboard]
category: decisions
tags: [dashboard, direction-dashboard, rung-c, act-from-page, ephemeral-server, decision-boundary-validator, html-generator, heu-012, dev-plan]
parents: [phase-106-project-state-dashboard]
created: 2026-06-23
updated: 2026-06-23
source: plan
confidence: high
---

## Context

Phase 99 ([[direction-dashboard]]) shipped a render-only direction dashboard and explicitly **deferred** two things: A2 a persistent/served surface (filed to Blockers with a re-trigger — "if regenerate-by-hand becomes a friction bottleneck") and A3 a general project-state surface ("becomes orienting context around the brief"). At the Phase-106 direction gate the maintainer pulled **both** forward across four AskUserQuestion rounds: build a project-state monitoring dashboard; **on-demand** static regen is fine for monitoring; but the real requirement is **act-from-page** — "how do I drive phase decisions from there?"; and the channel should be **the dashboard writes a file the Claude Code process monitors**, not a copy-paste.

The hard constraint that shaped everything: a `file://` page is **sandboxed** and cannot write a repo file — this *is* the "browser→session channel the harness lacks" Ph99 cited as the reason A1 (interactivity) was deferred. A static page genuinely cannot do it; the File System Access API is Chrome-only/permission-prompted/`file://`-hostile (a clever-but-fragile path, rejected per the subtraction test).

## Decision

Ship an **opt-in act-from-page direction gate** + an **on-demand `make dashboard` monitoring page**, via three stdlib-only scripts, with AskUserQuestion as the default and fail-open fallback and exactly one gitignored repo write.

- **Ephemeral, decision-scoped server, not a daemon** (write channel = ephemeral-server gate, maintainer-chosen): the `/dev-plan` gate spins up a tiny **127.0.0.1 port-0** server that *serves* the live dashboard (so a same-origin form POST is trivial — no clipboard, no FS API), accepts ONE `POST /decision`, atomically writes `.dev-wiki/decision-response.json`, then **exits**. Alive for the seconds of the decision, not the always-on watcher Ph99 declined.
- **The server owns the single timeout** (A4): on watchdog expiry it writes a `{status:"timeout"}` sentinel and exits; the session waits on ONE file condition and branches on contents. This kills the dual-deadline-coupling hang. The orchestrator wait is a `run_in_background` watcher / Monitor — **never a foreground sleep** (blocked in this env; a foreground until-sleep loop would self-brick every future gate, the Ph82 class).
- **One deterministic boundary validator** (A3): `validate-decision-response.py` is RUN by BOTH the server POST path and the dev-plan ingest. An LLM-prose ingest would be the *neural-judge-at-boundary* the kit rejects and would drift from the server schema. This is the kit's own "deterministic validators at boundaries over neural judges" posture.
- **Safe-by-default, opt-in** (A1): the new path fires only when `.dev-wiki/act-from-page` is present (the `.claude/enforce`-marker convention). Absence = today's AskUserQuestion path, server never spawned. Every failure branch (no marker / server won't start / tab abandoned / bad POST / timeout sentinel) falls open to AskUserQuestion. The gate's required outcome — positions on every assumption + the ledger row as the SOLE firing evidence — is **channel-agnostic and unchanged**.
- **Render-only monitoring floor, panes cut** (A2): the generator renders a thin STATUS digest + the DIRECTION pane (imported from `generate-direction.py`, anti-drift). The **Architecture and Decisions panes are CUT** — the highest-LOC, lowest-evidence, fully-unmeasurable additions; cutting honors the subtraction test and keeps the phase to one L task.
- **Structural staleness defense** (A5): gitignore the response file + unconditional pre-launch `rm` + 128-bit nonce + a watcher predicate requiring existence AND fresh-nonce + consume-once rename + nonce OPTIONAL only at render/ingest (legacy-skip), so existing nonce-less briefs still render and fall open.
- **Localhost-CSRF defense** (A6): Origin==own-origin + Host allowlist + Content-Length cap + reject-chunked + a single-accept latch (checked BEFORE the write → 2nd POST 409, no double-write).

## Why

Human-facing presentation/friction value is **UNMEASURABLE in-kit** (Ph59/80 carve-out measured *model*-facing re-presentation, a different axis), so this ships on the maintainer's stated need, not a measured lift — and the weakest assumption (A1: the round-trip removes friction rather than swapping it) is accepted ONLY because it is **cheaply reversible**: opt-in marker + fallback, retire = `rm` the marker, zero gate-semantics change. Controls-first per [[HEU-012]]: tests assert the rendered HTML CONTAINS live *fixture* content (never the always-loaded live docs — Ph80 leak), a present-but-restructured source produces a *distinct visible marker* (not a silent placeholder — the #1 dead-instrument guard), and every malformed/stale/partial/phantom/bad-position input FAILS LOUD. The design was hardened by a 13-agent ground+adversarial-stress pass (6 failure-mode lenses: concurrency/race, localhost security, surgical/DRY, controls adequacy, gate self-brick, subtraction/value).

## Alternatives considered

- **Serverless clipboard directive** (the page assembles a token, the maintainer pastes it) — works on pure `file://`, zero process, but keeps the copy-paste step the maintainer asked to drop. Rejected at the write-channel gate.
- **Always-on watching server** (the literal Ph99 A2) — re-renders + serves on file change; truest "monitoring" feel but a managed daemon/port/lifecycle. Declined at the persistence gate ("on-demand is fine").
- **File System Access API** — no server, but Chrome-only, permission-prompted, `file://`-hostile. Rejected (fragile).
- **Architecture + Decisions monitoring panes** — cut to the STATUS+DIRECTION floor (subtraction test; unmeasurable, highest-LOC). Re-add only on reported real friction.
- **Shared-scaffold DRY refactor of the 5 generators** — the count trigger is met, but themes diverge (light steering vs dark package); deferred to a 6th generator + converged themes.
- **Pillars 1–2 (contract-fidelity spine + downstream workers)** — the Ph99 journal's "natural next phase"; the maintainer chose to continue pillar 3 (the dashboard) instead.

## Consequences

3 new scripts + a `make dashboard` target + 3 controls-first test scripts + fixtures + opt-in dev-plan companion edits. ONE gitignored repo write (`.dev-wiki/decision-response.json`). No daemon, no new gate semantics, no eval scenario (50 stays 50), no hook registration. Discovery maintenance: README 30→33 scripts, MANIFEST md5 for 2 edited companions. Ledger Phase-106 (all_accept:true — the 4 direction forks were decided across the gate rounds; the 6 build-assumptions accepted under the maintainer's "Continue", each shaping the build, A1 flagged weakest + cheaply reversible).

## Source

Phase 106 direction gate 2026-06-23 (ledger Phase-106; 4 AskUserQuestion rounds → "Continue"). Spec `specs/phase-106-project-state-dashboard.md`. Builds on [[direction-dashboard]] (Ph99, pillars + the A2/A3 deferrals). Design hardened by a 13-agent ground+adversarial-stress workflow. Controls-first per [[HEU-012]].
