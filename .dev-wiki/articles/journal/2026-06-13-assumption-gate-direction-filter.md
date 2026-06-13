---
title: "Assumption-gate hardening + 4-project re-sync (Phase-90 follow-on)"
date: 2026-06-13
phase: 90
tags: [dev-plan, assumption-gate, install-sync, comply-in-form, fable-5]
status: complete
---

# Assumption-gate hardening + 4-project re-sync (Phase-90 follow-on)

Post-Phase-90 session work, three threads:

## 1. Assumption-gate hardening (the headline — "record this fix")

signal-watch dogfood: Jake flagged the assumption gate surfacing "direction gates pretending to be assumptions" — direction/approach choices dressed as assumptions, which regresses the gate back into the "approve the approach? → blind yes" it was built (Phase 80/81) to escape. He'd corrected this once before (after fable→opus) and it worked that session but did NOT persist.

Root cause: `assumption-gate.md` Surfacing defined load-bearing as "outcome changes if false" — which direction choices satisfy, with no filter to exclude them. Fix: a checkable **"assumption, not direction"** filter — each candidate must pass `If FALSE, then [specific breakage]`; if the negation is incoherent or just "I'd have chosen differently," it's a direction → drop. Shipped both-landings + MANIFEST + the 4 synced projects (signal-watch via global); `make test` green; commit **9309fe0**. Decision: [[assumption-gate-direction-filter]]. Feedback persisted to memory so it survives the session (the actual failure last round). This is the same comply-in-form class Phase 90 targeted — the gate's own degeneration it missed.

## 2. 4-project re-sync

Answering "are all installs synced?" surfaced that **install.sh has no project-local re-sync path** and consuming-project drift is undetected (Phase-76 (B) deferral). Four projects (edge-screener, edge-analyst, ai-game, fate) held project-local copies 23+ skills files stale (py-init's one-time `cp -r`, never updated). Manually re-synced all four (kit-managed skills + nana-soul + file-lifecycle), explicitly **preserving** project-owned files (nana-personal, py-session-state, active-phase, working-knowledge — verified byte-identical) and **deleting nothing**. Not committed in their repos (2 are heavily dirty) — left as working changes for the owner.

## 3. Phase-91 setup

Jake directed the install-sync fix as the next phase: **Phase 91 = Install Re-Sync + Consuming-Project Drift Detection** (an idempotent install.sh update mode codifying the safe sync + close the Phase-76 drift-detection deferral). Memory-prune renumbered 91 → **92**. Committed (09f2a71); next-action repointed.

## Health Delta

No code paths changed (skill prose + the assumption-gate filter). `make test` green throughout; `make eval` 50/50. Commits this thread: f2d3658/f05280d (Phase 90), 09f2a71 (Phase-91 setup), 9309fe0 (assumption-gate fix).

## Soft Observations / Phase N+1 Candidates

- **Clean-context surfacing subagent** — if the instruction-level assumption filter still degenerates in practice, surface assumptions from a subagent that never holds the approach (the B2 move Phase 90 staged). The instruction is the cheap fix; the subagent is the structural one. Watch the next signal-watch `/dev-plan`.
- **Phase 91 hard part** — the install re-sync must handle REMOVED kit content (retired `active-knowledge.md`, the cut `detect-loop` hook still registered in those 4 projects' `settings.json`), which a copy-based refresh doesn't clean up. Named at the Phase-90 close; carry into the Phase-91 direction gate.
- **4 projects carry uncommitted kit-sync changes** — edge-screener/edge-analyst/ai-game/fate now have updated kit files in their working trees; their owners commit when ready.
