<!-- nana:approved 2026-06-23 (dev-plan workflow-internal: 13-agent ground+adversarial-stress pass) -->
# Spec: Phase 106 — Project-State Dashboard + Act-from-Page Decision Gate

## Objective

Ship an **opt-in act-from-page direction gate** (the maintainer answers the `/dev-plan` assumption gate on a served dashboard that drives the gate) plus an **on-demand `make dashboard` project-state monitoring page**, with AskUserQuestion as the default and the fail-open fallback, and **exactly one gitignored repo write** — without changing any gate semantics or shipping a daemon. This is **pillar 3 of the rung-C program, extended**: it pulls forward Phase 99's two deferrals — A2 (a persistent/served surface) and A3 (a general project-state surface) — onto the input/steering side.

## Context

Phase 99 shipped a render-only direction dashboard (`generate-direction.py` → `docs/direction.html`) and explicitly deferred (A2) a watching/served surface to Blockers and (A3) a general project-state surface in favor of the narrow direction gate. The maintainer pulled both forward across four direction gates this session: **build a project-state monitoring dashboard · on-demand static for monitoring · act-from-page (decide ON the page) · ephemeral-server write-channel + session Monitor-watch.**

The hard constraint that shaped the design: a `file://` page is sandboxed and cannot write a repo file — this *is* the "browser→session channel the harness lacks" Ph99 cited. The resolution: at the gate, spin up a tiny **127.0.0.1 ephemeral server** that *serves* the live dashboard (same-origin POST is then trivial), accepts ONE decision POST, atomically writes `.dev-wiki/decision-response.json`, and exits; the orchestrator blocks on a `run_in_background` watch of that file and ingests it through one deterministic validator. Human-facing presentation/friction value is UNMEASURABLE in-kit (Ph59/80 carve-out) — the feature ships on the maintainer's stated need; tests assert MECHANICS only.

## Scope

### In scope
- `scripts/generate-dashboard.py` — static `make dashboard` page; pure `render_dashboard(panes, interactive=False)`; **imports** `render_options`/`render_assumptions`/`esc`/`load_brief`/`validate_brief` from `generate-direction.py` (anti-drift).
- `scripts/validate-decision-response.py` — ONE deterministic boundary validator for BOTH channels (server POST + dev-plan ingest).
- `scripts/decision-server.py` — ephemeral 127.0.0.1:0 server; single-accept latch, atomic write, server-owned watchdog sentinel, off-thread shutdown, Origin/Host/Content-Length/chunked guards.
- `make dashboard` target + `.PHONY` + smoke + `.gitignore` of the transient artifacts.
- dev-plan companion edits (`direction-brief.md`, `assumption-gate.md`, `SKILL.md` Step 13) — opt-in marker, fail-open flow, optional nonce.
- Controls-first tests (`test_dashboard.sh`, `test_decision_server.sh`, `test_dashboard_roundtrip.sh`) + fixtures.
- Discovery maintenance: README 30→33 scripts, MANIFEST md5 for the 2 edited companions, make-test registration.

### Out of scope
- Any always-on daemon.
- Architecture and Decisions monitoring panes (cut to a STATUS + DIRECTION floor).
- A YAML / inline-list frontmatter parser; a decisions-pane sortable grid / freshness badges.
- A shared-scaffold refactor of the 5 generators (themes diverge — deferred to a 6th generator + converged themes).
- Any new gate semantics, eval scenario (50 stays 50), or hook registration.
- Editing the live `.dev-wiki/` living docs (render-only consumer).

## Approach

Three stdlib-only scripts, dependency-ordered behind the boundary contract (T1 the validator first). The generator imports the direction brief-render fns (copies only the light CSS). The server is the only writer of the one repo artifact; it owns the single timeout. dev-plan integration is marker-gated (`.dev-wiki/act-from-page`); absence = today's AskUserQuestion path, server never spawns, and every failure branch falls open to AskUserQuestion. The orchestrator wait is a background watcher on ONE file condition (valid decision vs `{status:timeout}` sentinel) — never a foreground sleep.

## Constraints

- Render-only for monitoring panes: the dashboard MUST NOT write the living docs (dev-plan/debrief own `_CURRENT_STATE` sections).
- Static page is strictly render-only: `interactive=False` emits NO `<form>`.
- Exactly ONE repo write in the whole feature: `.dev-wiki/decision-response.json`, via the server only, gitignored.
- AskUserQuestion is the default AND the fail-open fallback; act-from-page is opt-in via `.dev-wiki/act-from-page`; absence = today's path, server never spawned.
- The gate's required outcome is channel-agnostic: positions on every assumption + the assumption-ledger row as the SOLE firing evidence (`enforce-assumption-gate.sh`) — unchanged regardless of channel.
- stdlib-only, zero new deps; `generate-dashboard.py` imports brief-render fns from `generate-direction.py`, copies only CSS classes.
- No foreground sleep (blocked in this env): the orchestrator wait is a `run_in_background` watcher / Monitor that self-releases; the SERVER owns the single timeout.
- HEU-012 controls-first: tests assert rendered HTML CONTAINS live fixture content + every seeded malformed/stale/partial/phantom/bad-position source FAILS LOUD; tests run on FIXTURES, never the always-loaded live docs.
- Path-traversal structurally impossible: the write path is a hardcoded constant; the POST body never influences a filename.
- 127.0.0.1 + port-0 bind only (never 0.0.0.0).

## Checkpoints

- After T1: `validate-decision-response.py` rejects all four seeded defects and accepts the valid response (the boundary contract is real before anything depends on it).
- After T2: the dashboard generator's G11 present-but-restructured control fires (a distinct marker, NOT a silent absent-placeholder on non-empty input) — the #1 dead-instrument hole closed.
- After T4: S3 (timeout-wrapped) proves the off-thread-shutdown deadlock manifests as a test FAILURE not a hang, and S4 proves bad POST → no write + server up.
- After T6: a nonce-less legacy brief still renders `make dashboard` exit 0 (backward-compat) and the default no-marker path provably never spawns the server.
- Final: `make test` green at 33 registered scripts, README matches, MANIFEST fresh, eval still 50/50.

## Assumptions

- A1 (weakest, rank 1): the act-from-page round-trip removes friction rather than swapping it — accepted because cheaply reversible via the opt-in marker + AskUserQuestion fallback.
- A2: a thin STATUS+DIRECTION floor (Architecture/Decisions panes cut) is the right monitoring scope.
- A3: one deterministic validator shared by server POST + dev-plan ingest is the correct boundary (no neural judge).
- A4: a `run_in_background` watcher with a server-owned single timeout avoids the foreground-sleep self-brick and the dual-deadline hang.
- A5: structural staleness (gitignore + fresh-nonce predicate + 128-bit nonce + consume-once + legacy-skip) prevents wrong-phase ingest.
- A6: Origin+Host+latch is sufficient localhost-CSRF defense for a loopback single-user endpoint.

## Exit Criteria

- `make test` passes with 33 registered test scripts; README says "33 scripts"; `grep -c 'bash.*tests/test_' Makefile` == 33.
- `make dashboard` exits 0 and writes `docs/dashboard.html` containing `<html>`; on a nonce-less brief it still exits 0.
- `test_dashboard.sh`: status+direction panes CONTAIN live fixture content; malformed/missing-field brief fails loud; missing source FILE degrades to "(section absent)" exit 0; present-but-restructured section shows a distinct marker; static output has NO form.
- `test_decision_server.sh` (under `timeout`): GET / serves live+form; valid POST atomically writes a schema-valid file then the server exits with the port closed; watchdog-no-POST writes a timeout sentinel and exits; malformed/partial/phantom/bad-position/wrong-Origin/bad-Host POST → non-2xx + no write + server up; two back-to-back POSTs → exactly one write + 409; bind is 127.0.0.1.
- `test_dashboard_roundtrip.sh`: full cycle field-integrity via `validate-decision-response.py`; the watcher predicate ignores a pre-seeded stale-nonce file; an abandoned-tab until-loop releases within a short injected deadline; stale-nonce/partial-coverage/phantom-option/bad-position all REJECTED.
- `validate-decision-response.py` is imported by `decision-server.py` AND invoked by the dev-plan ingest companion (one artifact, no reimplementation).
- dev-plan default path (no `.dev-wiki/act-from-page` marker) runs the existing AskUserQuestion gate and never spawns the server; ledger-append + resolution + all-accept rules unchanged in both channels.
- MANIFEST fresh (`test_manifest_freshness.sh`) for the 2 edited companions; `test_companions.sh` passes; eval count stays 50; ZERO change to settings.json / no hook registered.
