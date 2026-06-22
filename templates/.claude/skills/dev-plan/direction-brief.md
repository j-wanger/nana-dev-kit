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
fall back to the in-session text gate; never block the gate on the dashboard.

## Schema — `.dev-wiki/direction-brief.json`

```json
{
  "phase": 99,                                  // required (int)
  "phase_name": "Direction Dashboard",          // optional
  "generated": "2026-06-22",                     // optional (ISO date)
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
