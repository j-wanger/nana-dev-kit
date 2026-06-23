---
parent: dev-plan
referenced_at: "Step 13"
---

# Direction Brief — visual rendering of the direction gate (dev-plan Step 13)

The direction gate is dense: a recommendation, an option set with trade-offs, and 3–6 cost-sorted
assumptions, presented as fast in-session text. The maintainer cannot always process that at reading
speed. The **direction brief** is a structured artifact dev-plan emits at the gate so a render-only HTML
**direction dashboard** (`scripts/generate-direction.py` → `docs/direction.html`) can show it as a
scannable page. Decisions still happen in-session — the dashboard is read, not clicked
(Phase 99 [[direction-dashboard]], render-only by design).

## Step 13 flow — dashboard-as-primary (Phase 107)

The decisioning **cockpit** (`scripts/generate-dashboard.py` → `docs/dashboard.html`, served live by
`scripts/decision-server.py`) is the PRIMARY surface for the gate: the maintainer decides ON the served
page and it drives the gate directly — no copy-paste. AskUserQuestion is the **fail-open fallback**, and
it is never removed (the flip changes the default, not the safety net — [[HEU-012]] / Ph82: don't
self-brick the gate).

1. **Surface** the assumptions (see `assumption-gate.md`).
2. **Emit the brief** → write `.dev-wiki/direction-brief.json` (schema below) with, for EACH option, its
   `reasoning` (the case for it) and `consequences` (what it commits to / forecloses) — the cockpit lays
   these out per-option for comparison, the core of the Phase-107 rebuild — plus a 128-bit `nonce`
   (`secrets.token_hex(16)`) and `gate_id`. Positions are `"pending"`. Pre-clear stale state:
   `rm -f .dev-wiki/decision-response.json` so a leftover can't wake the watcher on iteration 1.
3. **Decide on the page** (the DEFAULT, when the cockpit scripts are present AND the session is
   interactive):
   - `python3 scripts/decision-server.py` — binds `127.0.0.1` on an ephemeral port, serves the live
     cockpit (the Decide tab + the decision form), prints the URL (also in
     `.dev-wiki/.decision-server.url`). Tell the maintainer to open it.
   - **Watch — NEVER a foreground sleep** (blocked here; a foreground until-sleep would self-brick every
     future gate, the Ph82 self-lock class). Wait via a `run_in_background` watcher on ONE condition:
     `.dev-wiki/decision-response.json` exists AND its `brief_nonce` equals the brief's nonce (fresh, not
     stale/foreign) — this applies to BOTH a real decision AND the `{"status":"timeout"}` sentinel (the
     server stamps the brief nonce into the sentinel, so a leftover prior-gate sentinel cannot release
     this gate). **The SERVER owns the single timeout**; the orchestrator deadline is only a backstop
     strictly greater than the server `--timeout`. (See the `watcher_ready` / `wait_for_decision`
     constructs in `tests/test_dashboard_roundtrip.sh` R4/R5.)
   - **Ingest deterministically** → `python3 scripts/validate-decision-response.py
     .dev-wiki/direction-brief.json .dev-wiki/decision-response.json` — the SAME validator the server ran
     (a deterministic boundary, never LLM-eyeballed for nonce/coverage/position). On exit 0, read the
     option pick + per-assumption positions + notes and drive the gate exactly as if taken via
     AskUserQuestion. **Consume once:** rename/remove the response file after reading so it can't replay.
4. **Fall open to AskUserQuestion on EVERY other path** (the gate is never blocked on the cockpit):
   - the cockpit scripts are absent (a consuming project ships `templates/`, not `scripts/`);
   - the session is **headless / autonomous / non-interactive** — there is no human at a served page, so
     use the in-session AskUserQuestion path; do NOT spawn-and-hang;
   - an explicit opt-out marker `.dev-wiki/no-act-from-page` is present;
   - the server won't start, the generator fails loud (malformed brief — controls-first, [[HEU-012]]),
     the watcher hits the `{status:timeout}` sentinel, the POST is invalid, or the validator exits
     non-zero.
   In every one of these, revert to the in-session AskUserQuestion text gate.

A **stale brief** (its `phase` != the active phase) is never silently decidable: the cockpit shows a loud
banner and emits no form, and the server refuses the POST (409) — the maintainer regenerates the gate. A
legacy nonce-less brief still renders and falls open.

The gate's required outcome is **channel-agnostic**: positions on every assumption + the assumption-ledger
row are the SOLE firing evidence (`enforce-assumption-gate.sh`), identical whether taken via AskUserQuestion
or the served cockpit. The ledger-append, resolution, and all-accept rules are UNCHANGED. (`make dashboard`
writes the static, form-LESS cockpit for reading at any time — render-only, never the living docs.)

## Schema — `.dev-wiki/direction-brief.json`

```json
{
  "phase": 99,                                  // required (int)
  "phase_name": "Direction Dashboard",          // optional
  "generated": "2026-06-22",                     // optional (ISO date)
  "nonce": "f1e2d3c4…",                          // optional; REQUIRED in the act-from-page WRITE path (128-bit, secrets.token_hex(16))
  "gate_id": "direction",                         // optional; echoed back by the decision response
  "objective": "One-sentence phase objective.",  // optional
  "recommendation": "The lead recommendation.",  // required (non-empty)
  "options": [                                    // required (non-empty list)
    {
      "label": "Option name",                    // required per option
      "description": "Trade-off in one or two sentences.",
      "reasoning": "The case FOR this option.",   // optional (Phase 107) — rendered inside the option card
      "consequences": "What it commits/forecloses.", // optional (Phase 107) — rendered inside the option card
      "recommended": true,                        // optional — renders a "Recommended" badge
      "chosen": true                              // optional — renders a "Chosen" badge + highlight
    }
  ],
  "assumptions": [                                // required (non-empty list)
    {
      "id": "A1",                                // required per assumption
      "cost": "high",                            // high | medium | low (color-coded)
      "text": "The load-bearing assumption.",    // required per assumption
      "position": "accept",                      // accept | reject | don't-know | pending
      "resolution": "How a reject/don't-know was resolved."
    }
  ],
  "context": {                                   // optional orienting context
    "active_phase": "Phase 99 — …",              // falls back to .claude/rules/active-phase.md
    "open_decisions": ["A short open question"]
  }
}
```

Required fields (the generator rejects a brief missing any, exiting non-zero): `phase`,
`recommendation`, `options` (non-empty, each with `label`), `assumptions` (non-empty, each with
`id` + `text`). The `position`/`resolution`/`cost`/`context` fields are optional and render when present.
