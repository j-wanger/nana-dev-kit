---
title: "Codebase Snapshot 2026-06-09"
aliases: []
category: status
tags: [snapshot, phase-81]
parents: []
created: 2026-06-09
updated: 2026-06-09
source: debrief
---

# Codebase Snapshot — 2026-06-09 (Phase 81 ready for completion)

## Metrics
- Test scripts: **20** (`tests/test_*.sh`) — +1 this phase (`test_assumption_ledger.sh`, 22 assertions); ~450 assertions total
- Eval scenarios: **52** (`make eval` 52/52, unchanged — no new scenario)
- Reasoning eval scenarios: 25
- Skill dirs: 25 (`templates/.claude/skills/`)
- Hook scripts: 18 (`templates/.claude/hooks/*.sh`) — unchanged (NO new hook this phase)
- VERSION: 0.5.0

## Module / Structural Changes (Phase 81)
- NEW data store: `.dev-wiki/assumption-ledger.md` — append-only cross-phase ledger (one `## Phase` block per phase; Phase-80 A1-A4 seed)
- NEW validator: `scripts/check-assumption-ledger.sh` — deterministic NO-LLM (bash/awk), 4 modes (`--schema/--revisit/--gate/--append-only`) + `--selftest`; carries the canonical `## Ledger schema` block (the single schema source)
- dev-plan Step 13 reframed — positions (accept/reject/don't-know) REPLACE approach-approval; new companions `assumption-gate.md` + `assumption-gate-example.md`
- dev-debrief gained the "Assumption-Ledger Revisit" forcing-function at Step 21 (re-scans prior-phase unrevisited rows; NO new hook)

## Test Status
- `make test`: All tests passed
- `make eval`: Score: 52/52 (100%)
- `bash scripts/check-assumption-ledger.sh --selftest`: exit 0
- `tests/test_assumption_ledger.sh`: 22/22
- Reviewer: 9/10 ACCEPT (both findings fixed inline)

## Recent Commits (pre-Phase-81 commit)
- `ea710ef` Phase 80 — delivery accepted; flip delivery gate
- `04bc520` Phase 80 — debrief: journal + finalized decision + state refresh + wk seed
- `405b4f7` Phase 80 — T5/T6: silent-class runs scored => PROGRAM-VERDICT INSTRUMENT-DEAD
- `13f0242` Phase 80 — T4 fixtures + check.sh
- `d31c355` Phase 80 — T3 surfacer spec + coverage check

(Phase 81 work is uncommitted at snapshot time — 21 changed/new paths; the delivery-flow commits + flips the gate after acceptance.)

## Prior Scan
No fresh `/dev-scan` this phase. Last full structural scan reflected in `_ARCHITECTURE.md` (refreshed 2026-06-09 for the Phase-81 structural delta); broader file inventory in Project Shape may drift — run `/dev-scan` to refresh.
