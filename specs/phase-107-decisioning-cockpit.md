<!-- nana:approved 2026-06-23 (dev-plan workflow-internal: adversarial-constraint + Tier-1 review pass) -->
# Spec: Phase 107 — Decisioning Cockpit (dashboard-as-primary gate)

## Objective

Rebuild the Phase-106 dashboard into a **tabbed decisioning cockpit** (`Status | Decide | Workflow`) that becomes the **primary `/dev-plan` direction-gate surface** — served live at each gate by the existing ephemeral server — with **per-option reasoning + consequences** laid out for comparison, a **loud stale-brief guard**, and the harness **Workflow** page re-rendered natively into the shared visual system. AskUserQuestion stays the fail-open fallback. This legitimately reverses Phase 106's "STATUS+DIRECTION floor" subtraction on the maintainer's stated need.

## Context

Phase 106 shipped `generate-dashboard.py` (a thin static monitor), `decision-server.py` (a 127.0.0.1 ephemeral server that serves the live page and accepts ONE decision POST → atomically writes `.dev-wiki/decision-response.json`), and `validate-decision-response.py` (the shared deterministic boundary). The maintainer ran it and declared it unusable: "the UI is terrible, it doesn't possess enough information for anyone to even make a decision, not usable at all." Two concrete defects confirmed from source: (1) the dashboard silently renders whatever is in `direction-brief.json` — currently the **Phase-103 gate (5 phases stale)** — with no freshness signal; (2) option cards render only `label`+`description` (`render_options`, generate-direction.py:86) — **no reasoning/consequences fields exist** in the schema or render — and `docs/workflow.html` (85K, from `generate-workflow.py`) is unlinked. Direction was locked across three AskUserQuestion rounds this session: refine-the-dashboard → **dashboard-as-primary gate** (flip Ph106's AskUserQuestion-default/opt-in) → **re-render workflow natively** (not iframe). Human-facing UI quality is UNMEASURABLE in-kit (Ph59/80 carve-out); the feature ships on stated need and the maintainer's judgment at the delivery gate, and tests assert MECHANICS only.

## Scope

### In scope
- `scripts/generate-direction.py` — extend the brief schema: each option gains optional `reasoning` and `consequences`; `render_options` renders them; `validate_brief` stays backward-compatible (reasoning/consequences optional; legacy briefs still render).
- `scripts/generate-dashboard.py` — rebuild `render_dashboard(panes, interactive=...)` into a tabbed cockpit shell (`Status | Decide | Workflow`); the `Decide` tab carries the recommendation + comparable option cards (reasoning/consequences) + the assumptions table, and (interactive only) the decision form; add the deterministic **stale-brief guard**.
- `scripts/generate-workflow.py` — refactor to expose its section content as **fragments** a caller can compose; its standalone `main()` → `docs/workflow.html` keeps working unchanged.
- `scripts/decision-server.py` — serves the cockpit (already via `render_dashboard(interactive=True)`); minimal changes only if the cockpit render signature requires them.
- `scripts/validate-decision-response.py` — unchanged contract unless the stale-brief/nonce/position checks must move into the shared validator.
- dev-plan companion edits (`templates/.claude/skills/dev-plan/{direction-brief,assumption-gate,SKILL.md}`) — author the richer brief at the gate; flip Step 13 to **cockpit-by-default for interactive sessions** with mandatory fail-open + an opt-out escape; headless/autonomous → existing path.
- Controls-first tests + fixtures (`test_dashboard.sh`, `test_decision_server.sh`, `test_dashboard_roundtrip.sh`, and a workflow-fragment assertion); Makefile/`docs/` targets; `.gitignore`; README + MANIFEST discovery maintenance.

### Out of scope
- Any always-on daemon (the server stays ephemeral, per-gate, spawns→exits).
- A **shared-scaffold refactor that unifies the 5 generators** — keep them separate; the cockpit *imports* render fns and *composes* workflow fragments; each generator must still render independently.
- A YAML/inline-list frontmatter parser; new gate **semantics** (positions stay accept/reject/don't-know; the assumption-ledger row stays the SOLE firing evidence); a new eval scenario (50 stays 50); a new hook registration / settings.json change (prefer none).
- Editing the live `.dev-wiki/` living docs from a generator (render-only consumer); tests run on FIXTURES, never the always-loaded live docs.
- Auto-deriving reasoning/consequences — they are authored at the gate (the only honest source).

## Approach

Work behind the boundary contract first, then the render, then the flow. Extend the brief schema with optional per-option `reasoning`/`consequences` (backward-compatible — a legacy brief without them still validates and renders). Rebuild the dashboard's pure `render_dashboard` into a self-contained tabbed shell using CSS/JS tabs in the house single-file style; `interactive` continues to gate form emission (the static `make dashboard` page emits NO form). The `Decide` tab presents options as a scannable comparison (reasoning = the case for it; consequences = what it commits/forecloses). Refactor `generate-workflow.py` so its content is available as fragments the cockpit restyles into the shared system, while its standalone page still builds. Add a deterministic stale-brief guard: when the brief's phase ≠ the live active phase, the cockpit renders a prominent staleness banner and the served (interactive) page is NOT silently decidable. Flip the dev-plan Step 13 flow to spawn the server by default in interactive sessions and fall open to AskUserQuestion on every failure branch.

### Domain Research Questions
- What visual layout makes 3-4 options with reasoning+consequences genuinely *comparable* at a glance (side-by-side columns vs stacked cards with paired reasoning/consequence blocks)? Consult the `frontend-design` skill before committing.
- Where should the stale-brief / phase-mismatch check live so BOTH the served-accept and the planner-ingest honor it without duplication (the shared validator vs the render layer vs both)?
- Can `generate-workflow.py` be fragment-ized with a surgical seam (a function returning section HTML) that leaves its standalone output byte-stable, or does native re-render force a deeper restyle?

## Constraints

- **Don't self-brick the gate (HARD, HEU-012 / Ph82 class):** dashboard-as-default MUST fail open to AskUserQuestion on EVERY failure branch — server won't bind, render/import error, validator error, timeout sentinel, headless/no-browser. The fallback path stays wired and reachable; "is the fallback reachable" is asserted by a test, not claimed.
- **No foreground sleep** (blocked in this env — self-bricks future gates): the orchestrator waits on a `run_in_background` watcher of the response file; the SERVER owns the single bounded timeout (`{status:timeout}` sentinel).
- **Stale/wrong-phase decision can't be ingested as fresh:** the brief carries phase-id + a per-gate 128-bit nonce; the deterministic validator (run by BOTH server-accept and planner-ingest, never eyeballed) rejects a response whose phase/nonce ≠ the live gate; consume-once; pre-launch `rm` of the gitignored response; fresh-nonce watcher predicate.
- **Stale brief is never silently decidable (decisive rule):** on a stale (phase-mismatch), malformed, or empty brief the served interactive page renders a loud staleness banner in the `Decide` tab and emits **NO submittable `<form>`**; defense-in-depth, the server/validator still **rejects** any wrong-phase/wrong-nonce POST (4xx, no write). A *fresh, phase-matching* brief is the ONLY state that yields a decidable form. `make dashboard` (static) still exits 0 on a nonce-less/legacy brief (render-only).
- **`interactive=False` → the rendered HTML contains NO form, and the render path performs NO `.dev-wiki` write** — the static and live-decidable renders share `render_dashboard`, but `interactive` is the sole gate for form emission (no leak into the static path). The generator's `main()` writing `docs/dashboard.html` is the expected static output, not a living-doc write.
- **Exactly ONE repo write in the feature:** `.dev-wiki/decision-response.json`, via the server only, gitignored; the POST body never influences a filename (hardcoded write path).
- **Keep the generators separate:** import render fns / compose fragments; do NOT unify the 5 generators' themes; each still renders independently (assert it).
- **One shared schema authority:** `validate-decision-response.py` is imported by server-accept AND invoked by the planner-ingest; the cockpit path and the AskUserQuestion fallback path produce the SAME ingested decision shape.
- stdlib-only, zero new deps; HTML escaping on all brief-derived text (no raw interpolation); 127.0.0.1 + port-0 bind only; Origin/Host/Content-Length/chunked guards + single-accept latch retained.
- Surgical: every changed line traces to this objective; eval stays 50; drift 0.

## Success Vision

The maintainer opens one URL at a `/dev-plan` gate and can *actually decide*: the recommendation is obvious, each option's reasoning and consequences sit side by side so the trade-off is legible at human pace, the assumptions and their costs are right there, and a stale or wrong-phase brief is impossible to mistake for a live one. The Workflow tab shows the harness's own structure in the same visual language. If anything in the served path fails — no browser, a bind error, a timeout — the gate quietly falls back to in-session questions and planning continues; nothing about the flip can wedge a future phase. The design is good enough that the maintainer stops calling it unusable.

## Exit Criteria

- [ ] `make test` passes; the registered test count in README matches `grep -c 'bash.*tests/test_' Makefile`; MANIFEST fresh for edited companions (`bash tests/test_manifest_freshness.sh`); `bash tests/test_companions.sh` passes.
- [ ] `make dashboard` exits 0 and writes `docs/dashboard.html` containing the three tab controls (`Status`, `Decide`, `Workflow`); exits 0 on a nonce-less legacy brief and on a stale (phase-mismatch) brief.
- [ ] `test_dashboard.sh`: each option's `reasoning` AND `consequences` from a fixture brief render **co-located inside that option's own card container** (option-scoped, not merely present somewhere in the HTML — the comparability floor; the aesthetic itself is judged at the delivery gate); a stale-brief fixture (phase ≠ active) renders the staleness banner AND the `Decide` tab emits NO `<form>`; a malformed/missing-field brief fails loud; the Workflow tab contains native re-rendered content — **≥2 distinct section markers AND the native section container** present, and NO `<iframe>`; the static render emits NO `<form>`.
- [ ] `generate-workflow.py` still builds `docs/workflow.html` standalone (its `main()` exits 0 and output contains `<html>`), proving the fragment refactor didn't break the standalone generator.
- [ ] `test_decision_server.sh` (under `timeout`): GET / serves the interactive cockpit (form present); a valid POST atomically writes a schema-valid response then the server exits; watchdog-no-POST writes the timeout sentinel; malformed/wrong-Origin/bad-Host/oversized POST → non-2xx + no write + server up; two back-to-back POSTs → exactly one write + 409; bind is 127.0.0.1; GET on a stale-brief (phase-mismatch) gate serves the banner with NO submittable form, and a wrong-phase/wrong-nonce POST → 4xx + no write.
- [ ] `test_dashboard_roundtrip.sh`: full brief→cockpit→submitted-choice field integrity via `validate-decision-response.py` (option id + each position survive); the watcher predicate ignores a pre-seeded stale-nonce file; an all-accept response with no restated shaping is handled per the unchanged gate rule; stale-nonce/phantom-option/bad-position all REJECTED.
- [ ] `validate-decision-response.py` is imported by `decision-server.py` AND invoked by the dev-plan ingest companion (one artifact, no reimplementation); the cockpit path and the AskUserQuestion fallback yield an identical-schema decision.
- [ ] The dev-plan companion encodes: cockpit-by-default in interactive sessions, fail-open to AskUserQuestion on every failure branch (incl. headless and an opt-out marker), the server never spawned in headless/autonomous runs (companion-prose discipline; the server-owned timeout in `test_decision_server.sh` is the programmatic backstop if a spawn happens anyway); the ledger-append + resolution + all-accept rules unchanged across both channels.
- [ ] `make eval` stays 50/50; `bash tests/test_settings_template.sh` clean (zero settings.json change); kit drift 0.

## Checkpoints

- After the schema/validator task: a fixture brief with reasoning/consequences validates; a legacy brief without them still validates and renders; the stale-brief (phase-mismatch) guard fires on a seeded fixture. The boundary is real before the render depends on it.
- After the cockpit render task: `make dashboard` produces the three tabs and the option comparison; the static page emits no form; the served interactive page (via the server) shows the form ONLY on a fresh, phase-matching brief.
- After the workflow refactor: `docs/workflow.html` still builds standalone AND the Workflow tab carries the same content in the cockpit style — if the fragment seam forces a deep restyle that risks the standalone output, STOP and **escalate to the maintainer**: iframe is the safe fallback but was locked OUT at the direction gate, so it does not ship without sign-off.
- After the gate-flow task: a simulated server-spawn failure / timeout provably falls through to the AskUserQuestion path in a test, not a hang.
- Final: `make test` green at the registered count, README + MANIFEST fresh, eval 50/50, drift 0, zero settings.json change.

## Assumptions

- **A1 (weakest, rank 1):** a well-designed cockpit with per-option reasoning+consequences actually removes the maintainer's decision friction (vs swapping one friction for another). UNMEASURABLE in-kit (Ph59/80) → accepted on stated need; cheaply reversible (the static page + AskUserQuestion fallback survive any revert). If false: revert the render, keep the schema + stale-guard (independently useful).
- **A2 (HARD):** dashboard-as-default never removes the only working path — fail-open to AskUserQuestion holds on every branch. If false (a branch that can't fall open): that branch must be made to fall open before ship; the flip does not land otherwise.
- **A3:** `generate-workflow.py` can be fragment-ized with a surgical seam that leaves its standalone output stable. If false: iframe-embedding `docs/workflow.html` is the safe fallback, but the maintainer **locked "not iframe" at the direction gate** — so an iframe fallback is **ship-blocking: STOP and escalate to the maintainer**, never ship it autonomously.
- **A4:** per-option reasoning/consequences are authored at the gate by the orchestrator + the dev-plan companion. If false (the maintainer expects auto-derivation): there is no honest auto-source — surface this and keep authored content.
- **A5:** the existing nonce + a phase-match stale guard prevent wrong-phase ingest. If false: tighten the validator (the single schema authority) rather than adding a parallel check.
- **A6:** dashboard-primary is an interactive-session feature; the companion keys cockpit-vs-existing-path on the same non-interactive signal the orchestrator already uses (autonomous-loop / no-TTY), best-effort. If a headless run spawns the server anyway, the **server-owned timeout is the hard backstop** — it writes the sentinel and the gate falls open to the existing path (A2), so an A6 mis-detection degrades to a bounded wait, never a hang. Enforcement is companion-prose discipline, not a programmatic gate (like the rest of the gate flow).
