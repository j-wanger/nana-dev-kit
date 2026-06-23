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

## When to emit (Step 13 flow)

1. **Surface** the assumptions (see `assumption-gate.md`).
2. **Emit the brief** → write `.dev-wiki/direction-brief.json` (schema below). Positions are `"pending"`
   at this point — the maintainer has not yet decided.
3. **Generate + point** → run `make direction` (or `python3 scripts/generate-direction.py`) and tell the
   maintainer: *"Direction rendered at `docs/direction.html` — open it to review, then I'll take positions."*
4. **Take positions** via AskUserQuestion (the gate).
5. **Reflect the close (optional)** → fill each assumption's `position` + `resolution` from the closed
   gate and re-run `make direction` so `docs/direction.html` shows the final, decided gate.

Fail-open: if the generator errors (it fails loud on a malformed brief — controls-first, [[HEU-012]]),
or any act-from-page step below fails, fall back to the in-session AskUserQuestion text gate; never
block the gate on the dashboard or the server.

## Act-from-page channel (Phase 106 — OPT-IN)

By default the gate is answered in-session (AskUserQuestion). When `.dev-wiki/act-from-page` exists,
the maintainer can instead make the call ON the served dashboard, and it drives the gate directly —
no copy-paste. **Absence of the marker = today's path; the server is never spawned.**

Flow (only when the marker is present):
1. **Stamp a nonce.** When emitting the brief, add `nonce` (128-bit, `secrets.token_hex(16)`) +
   `gate_id` to `.dev-wiki/direction-brief.json`. (Legacy nonce-less briefs still render and fall
   open — the staleness guard simply doesn't bite.)
2. **Clear stale state.** `rm -f .dev-wiki/decision-response.json` BEFORE starting the server, so a
   leftover/foreign file can't wake the watcher on iteration 1.
3. **Serve.** `python3 scripts/decision-server.py` — binds `127.0.0.1` on an ephemeral port, serves
   the live dashboard (with the decision form), prints the URL (also in `.dev-wiki/.decision-server.url`).
   Tell the maintainer to open it.
4. **Watch — NEVER a foreground sleep** (it is blocked in this env and would self-brick every future
   gate, the Ph82 self-lock class). Wait via a `run_in_background` watcher / Monitor on ONE condition:
   `.dev-wiki/decision-response.json` exists AND its `brief_nonce` equals the brief's nonce (fresh, not
   stale/foreign) — this nonce check applies to BOTH a real decision AND the `{"status":"timeout"}`
   sentinel (the server stamps the brief nonce into the sentinel, so a leftover prior-gate sentinel
   cannot release this gate). **The SERVER owns the single
   timeout** (it writes the sentinel and exits); the orchestrator deadline is only a backstop strictly
   greater than the server's `--timeout`. (See the `watcher_ready` / `wait_for_decision` constructs
   validated in `tests/test_dashboard_roundtrip.sh` R4/R5.)
5. **Ingest deterministically.** Run `python3 scripts/validate-decision-response.py
   .dev-wiki/direction-brief.json .dev-wiki/decision-response.json` — the SAME validator the server
   used (a deterministic boundary, no LLM eyeballing of nonce/coverage/position). On exit 0, read the
   option pick + per-assumption positions + notes and drive the gate exactly as if taken via
   AskUserQuestion. **Consume once:** rename/remove the response file after reading so it can't replay.
6. **Fall open** on EVERY failure branch — marker absent, server won't start, the timeout sentinel, an
   invalid POST, a non-zero validator — revert to the in-session AskUserQuestion gate.

The gate's required outcome is **channel-agnostic**: positions on every assumption + the
assumption-ledger row are the SOLE firing evidence (`enforce-assumption-gate.sh`), identical whether
taken via AskUserQuestion or the served dashboard. The ledger-append, resolution, and all-accept rules
are UNCHANGED.

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
