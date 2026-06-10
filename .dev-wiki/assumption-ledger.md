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

## Phase 82 — QA & Verification Sweep (ultracode)
- date: 2026-06-09
- all_accept: false
- A1 | cost: high | position: don't-know | revisit-status: bit | "The seven repo-centric audit areas cover the silent-breakage surface that matters (maintainer named a missing axis: utilization/dead-weight, e.g. the barely-used MCP memory server)"
- A2 | cost: high | position: reject | revisit-status: held | "In-kit subagent context leak is acceptable for QA verification given an executed-command evidence standard plus orchestrator re-execution of clean rows"
- A3 | cost: medium | position: accept | revisit-status: held | "templates/ is the right direction-of-authority default and the planning-time 6-file resync overwrote no unbackported ~/.claude hot-fix"
- A4 | cost: medium | position: accept | revisit-status: held | "The pre-registered fix boundary (kit-managed + non-frozen + S/M + test-covered blast radius; coverage exception: writing the missing S/M functional test IS the fix; >10 confirmed defects stops the phase) is the right autonomy contract"
- A5 | cost: high | position: accept | revisit-status: held | "REVISES A1: eight areas — adding a deterministic usage/utilization audit whose under-use findings feed the parked Phase-79 prune-on-value item — cover the silent-breakage-and-dead-weight surface"
- A6 | cost: high | position: accept | revisit-status: held | "REVISES A2: subagents demoted to candidate-generators with orchestrator-executed deterministic commands as the SOLE verdict evidence (clean and defect-found alike) makes verification sound despite the leak"
