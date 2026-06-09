# Assumption Ledger

<!-- Schema + validator: scripts/check-assumption-ledger.sh (the `## Ledger schema` block) is THE single
     source of truth for this format. APPEND-ONLY: one `## Phase` block per phase, newest at the bottom;
     never rewrite a prior block except to fill a blank `revisit-status:` at debrief. The dev-plan
     assumption gate APPENDS a block when positions are taken; dev-debrief FILLS revisit-status at close. -->

## Phase 80 — Assumption-Surfacer Completeness Screen
- date: 2026-06-09
- all_accept: false
- A1 | cost: high | position: accept | revisit-status: held | "Forced accept/reject/don't-know verdicts engage cognition rather than producing faster rubber-stamps"
- A2 | cost: high | position: reject | revisit-status: held | "The agent-CHOSEN assumption set can be trusted to be complete enough to gate on"
- A3 | cost: medium | position: accept | revisit-status: held | "The ledger's revisit-status will be filled (not write-only), given a debrief forcing-function"
- A4 | cost: medium | position: accept | revisit-status: held | "nana-dev-kit is the right substrate to build and dogfood this gate"
