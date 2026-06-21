---
title: "Codebase Snapshot — 2026-06-21 (post Phase 97 implementation)"
aliases: []
category: status
tags: [snapshot, phase-97]
parents: [phase-97-frontier-positioning-sweep]
created: 2026-06-21
updated: 2026-06-21
source: debrief
---

# Codebase Snapshot — 2026-06-21

Captured at Phase 97 (Frontier Positioning Sweep) implementation-complete. **Verdict-only phase — ZERO
shippable-kit code/config change** (all new artifacts are gitignored under `companion/research/`).

## Metrics

- Version: 0.5.0
- Skill directories: 26 (`templates/.claude/skills/`)
- Lifecycle hooks: 18 `.sh` (17 project-scoped in modules.json + 1 global; detect-loop CUT Phase 88)
- Test scripts: 28 (`make test`, ~500 assertions) — ALL PASSED this session
- Eval scenarios: 50 (`make eval`) — denominator unchanged
- Install drift: 0 (kit + all 7 consumers CLEAN)

## Module Structure (unchanged this phase)

Shell/Markdown/Python scaffolding kit. install.sh (module-group installer) + modules.json (5-module manifest)
+ memory_server/ (vendored MCP) + wiki/ (knowledge wiki) + eval/ (measurement programs, repo-only) + scripts/
+ tests/ + templates/.claude/{hooks,rules,skills}. **NEW this phase:** `companion/` — gitignored, local-only
research apparatus (NEVER shipped); `companion/research/` holds the Phase-97 frozen instrument + sweep + verdict.

## Phase 97 Outcome

VERDICT = **INCONCLUSIVE — forced-under-observed (differentiated-leaning)**. K_low=0 / K_high=1 (B5 boundary-
validator CONTESTED); CORE (B1 blocking gates + B4 assumption gate) UNCOMMODITIZED. External frontier gives NO
case to shrink the kit's bet; both arms of the Ph92 re-measure now agree (with the Phase-95 internal memory
KEEP). Detail: [[frontier-positioning-sweep]].

## Recent Commits (last 5)

- 650f3c5 Debrief: post-Phase-96 hook hardening session
- 4b1a502 check-install-drift --consumer: detect stale hook CONTENT (not just registration)
- 55ab629 Fix block-dangerous-bash: precise rm target match (no relative-path false positive)
- 3fa2f0b Fix enforce-memory freshness anchor: per-session_id keyed, not global
- 54d91e0 Post-Phase-96: self-resync nana-dev-kit's own hooks to current kit (--migrate-to-local dogfood)

> Phase 97 is not yet committed — delivery gate pending user acceptance.
