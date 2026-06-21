# Active Phase Context

Phase: 95 — Memory-Layer Disposition (Reconcile-and-Close)
Objective: adjudicate EVERY open memory-layer obligation to ONE recorded, evidence-cited closed-enum verdict — no obligation left silently open, whatever the verdicts. Reconcile-and-dispose, NOT a cut hunt.
Scope: eval/memory-disposition/** + .dev-wiki/** (ledger A5 flip ONLY) + specs/phase-92-memory-layer-prune.md + eval/dogfood-round/evidence/window-events.md + scripts/check-assumption-ledger.sh; CONDITIONAL on a destructive enforce-memory verdict ONLY: templates/.claude/hooks/enforce-memory.sh, modules.json, templates/.claude/settings.json, eval/cases/**, tests/**. ZERO kit code UNLESS enforce-memory flips.
Dispositions: memory-mcp-layer KEEP (Ph94 reversal); bridge/harvest-writer KEEP-by-affirmation (evidence-split asymmetry — consumer evidence may keep not cut); enforce-memory the ONE live fork (keep|redesign|retire) at a HARD checkpoint on a firing audit + redesign spike (redesign GATED on SPIKE: PASS); ak-ride-along/wk-seeding CONFIRM (windows clean, REVERT-COUPLED). Closes ledger Phase-83 A5 (open->held) + Phase-88 A4/A6/A5; supersedes specs/phase-92-memory-layer-prune.md.
Key constraints: verdict row schema PINNED `| <id> | <verdict> | <evidence> |` (verdict col 2); JSON tool_use never grep (positive-control-gated); verify-by-firing not presence (HEU-012); destructive verdict classifies couldnt-fire|didnt-fire + supersedes enforce-memory@Phase-88; no subsystem-zero as demand; zero destructive verdicts is valid.
Exit: run-exit-criteria.sh (+ --selftest) ALL-PASS; ledger validator + --gate 95 green; make test + eval (denom 50 unless enforce-memory flips) + check-install-drift drift 0.
Abort: enforce-memory checkpoint = HARD (no execution on direction-gate authority); SPIKE: FAIL removes redesign; a retire revealing another armed marker → STOP + re-scope; >3 attempts → ask user skip|abort.
Spec: specs/phase-95-memory-layer-disposition.md (nana:approved). Decision: [[memory-layer-disposition]] (high).
Status: IMPLEMENTATION COMPLETE 2026-06-21 — 4/4 tasks [x]; run-exit-criteria 12/12, make test PASS, make eval 50/50 (denom unchanged), drift 0. Outcome: memory-mcp-layer + bridge/harvest-writer KEEP; enforce-memory REDESIGNED (real memory_search assertion vs gameable marker, ts>=session-start-ts; survivor-smoke PASS, installed-copy synced); ak-ride-along + wk-seeding CONFIRMED. Ledger Phase-83 A5 open->held; Phase-88 A4/A6 + trim re-triggers resolved. Awaiting delivery acceptance.
Gates:
- [x] Direction confirmed (2026-06-20: A1/A2/A4 accept, A3 reject->keep-by-affirmation; all_accept:false; ledger Phase-95)
- [ ] Delivery accepted (post-implementation report)
