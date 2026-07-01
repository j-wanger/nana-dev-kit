---
title: Manager's Desk — Loop-2 Design Sketch
type: design-sketch
updated: 2026-07-01
status: framing approved; reference for the first build
related: [[NORTHSTAR]], [[interface-design-brief]], [[project-loop-engineering-northstar]]
---

# Manager's Desk — Loop-2 Design Sketch

*First-pass design, 2026-07-01. The Loop-2 "steer" surface from the north star. Framing approved by Jake. Built ON the existing engine — feasibility confirmed against the code: an additive view, not a rebuild.*

## What it is
The screen where the human (product-owner / manager role, Loop 2) reviews what a worker did and steers — instead of watching a chat and approving every action.

## The desk

```
┌─ nana · manager's desk ──────────────────────────── ⌘K ──── today $2.14 ─┐
│                                                                           │
│  YOUR LOOPS                      │  REVIEW · "add rule-engine v2"         │
│  ──────────────────────────────  │  ───────────────────────────────────  │
│  ● add rule-engine v2            │  Goal    port the AML rules to v2 API  │
│    Claude · ⚠ needs you (2)      │  Worker  Claude · round 3 of ~5        │
│    review: per-round·high stakes │  Review  per round  (high cost of err) │
│    $1.90                         │                                        │
│  ──────────────────────────────  │  WHAT IT DID                           │
│  ○ migrate test suite            │   ✓ changed 6 files — rules/*, api.ts  │
│    local · running               │       [▸ feel it — run the app]        │
│    review: whole job·low stakes  │   ✓ added 4 tests — all passing        │
│    $0.00                         │       [▸ feel it — watch them run]     │
│  ──────────────────────────────  │   ✓ undid 1 change it caught itself    │
│  ○ enrich case notes             │                                        │
│    local → Claude · running      │  CALLS IT MADE      (react — or feel)  │
│    review: whole job             │   • "structuring" = 3+ txns <$10k/24h  │
│    $0.30                         │      [ok] [fix…] [▸ feel — last wk]    │
│  ──────────────────────────────  │   • 30-day lookback (chose over 90)    │
│  ✓ docs cleanup · local · done   │      [ok] [fix…] [▸ feel — 30 vs 90]   │
│                                  │                                        │
│  [ + new loop ]                  │  ⚠ NEEDS YOU                           │
│                                  │   • wants to file a REAL SAR — no undo │
│                                  │      [review & approve]  [deny]        │
│                                  │   • which client id is primary? (2)    │
│                                  │      [answer…]                         │
│                                  │  ───────────────────────────────────  │
│                                  │  STEER   ▸ on "30-day lookback":       │
│                                  │   [ use 90-day — see case #1123 _____ ]│
│                                  │   [ send feedback + run round 4 ]      │
└───────────────────────────────────────────────────────────────────────────┘
```

**Three review buckets:**
- **WHAT IT DID** — grouped outcomes (files changed, tests), each with `[feel it]`.
- **CALLS IT MADE** — the worker's decisions/assumptions, each `[ok] [fix…] [feel it]`. (Repurposes the assumption-surfacing work.)
- **NEEDS YOU** — the rare escalations only: irreversible actions + genuine questions. The small slice of Loop 1 the human keeps.

**Cadence** shows per loop (`per-round · high stakes` vs `whole job · low stakes`), set by complexity × cost of error, overridable.

## "Feel it" — the core principle
Every reviewable item can be *experienced*, not just read — because some judgments can't be made from a summary. **Build rule: every component ships with its felt mode from the start.**

Per type:
- **code / screen change** → run the app live (we have the safe sandbox).
- **rule / decision** → fire it on real cases; see catches and misses.
- **threshold** → side-by-side on real data.
- **test** → watch it run and catch a real break.
- **judgment call** → show the actual evidence the worker used.

The hard, high-value one — feeling a *decision* on real data:

```
┌─ feel it · "30-day vs 90-day lookback" ───────────── [back to review] ─┐
│  Same rules, run on LAST WEEK's real cases — what changes at 90 days:  │
│            30-day (its pick)        90-day (the alternative)           │
│  flagged   18 cases                 27 cases                           │
│  ───────────────────────────────────────────────────────────────────  │
│  only 90-day catches these 9:                                          │
│   · #1123  ***4471   3 txns $9,800 over 41 days   ← the one you named  │
│   · #1140  ***2210   4 txns $9,950 over 55 days           [see all 9 ▸]│
│  but 90-day also adds 2 likely false alarms:                          │
│   · #1150  regular payroll     · #1166  loan draw-down                 │
│   feels right? →  [ keep 30-day ]   [ switch to 90-day ]   [ note… ]   │
└────────────────────────────────────────────────────────────────────────┘
```

## The chain (human → Claude → cheaper worker)
Review at the level you want; default is Claude's summary of a cheap worker's output, with a way to go deeper:

```
  REVIEW · "enrich case notes"   (local worker, coached by Claude)
   Reviewing: Claude's summary of 40 edits  ·  38 clean, 2 flagged   [go deeper ▸]
    • case #88 asserts a shell-company link on thin evidence   [ok] [fix…] [▸ feel it]
```

## Build inventory (from the code feasibility check)
**Reuse as-is:** desk shell, loops list, the gate / "needs you" queue, diff view, revert, cost meter, palette, "run next round" (the existing gated submit path). *Existence proof:* the Ph119 cost meter is already a second view over the same engine stream.

**Two genuinely NEW pieces (the spine) — neither touches the engine or the safety gate:**
1. **Capture the worker's decisions/assumptions** — the reasoning isn't in the event stream today (the Pi adapter drops non-text), so `CALLS IT MADE` needs a new extraction/summarization step.
2. **"Feel a decision on data"** — replay a rule/threshold on real cases.

## First build (decided 2026-07-01)
**No de-risking slice.** Feasibility is already proven (code check) and value is judged by feel, not measurement — so a "prove-it slice" has nothing left to prove. Just build the spine, **riskiest piece first: decision-capture** — because it gates everything visible on the desk (if the captured decisions are noisy, the desk is untrustworthy), and it's the fastest path to something real to *feel* and steer. Continue in a **new session**.
