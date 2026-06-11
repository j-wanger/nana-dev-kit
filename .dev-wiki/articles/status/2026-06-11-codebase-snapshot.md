---
title: "Codebase Snapshot (Phase 88 ready for completion)"
aliases: []
category: status
tags: [snapshot, phase-88]
parents: [phase-88-trim-follow-on]
created: 2026-06-11
updated: 2026-06-11
source: debrief
---

# Codebase Snapshot — 2026-06-11

## Metrics
- Test suite: `make test` green — 27 scripts (~500 assertions; Phase 88 added test_check_tests_were_run.sh paired block/allow smoke; −5 detect-loop test surfaces absorbed)
- Eval: `make eval` 50/50 (denominator 52→50 explained in eval/trim-round/verdict-table.md — detect-loop's 2 scenarios removed with the cut)
- Exit criteria: 10/10 ALL-PASS via eval/trim-round/run-exit-criteria.sh
- Skills: 25 dirs + MANIFEST (−2 companion files: active-knowledge-transition.md, active-knowledge-spec.md); hooks: 17 template .sh (+3 session-start.d; 16 project-scoped + 1 global in modules.json)
- Seeded controls: 14/14 (run-seeded-controls.sh); stage-2 allowlist confined to the 3 routed files (cmp byte-identity elsewhere)

## Structure Changes (Phase 88)
- NEW `eval/trim-round/` (verdict table + checker, evidence re-snapshots, checker-fixtures, rehearsals with revert SHAs, ghost-registration sweep, seeded-controls + allowlist checks, exit-criteria runner)
- `templates/.claude/hooks/detect-loop.sh` CUT (75b48af; session-start.sh:110 split; own installed surfaces deregistered incl. the gitignored kit-local settings.json)
- `templates/.claude/hooks/check-tests-were-run.sh` hardened (b8bd416; HEU-007 dual-condition — .py condition keys on write-class tools)
- Active-knowledge layer removed from the skill pipeline (d43950f/df3e623; writer/reader steps tombstoned across dev-plan/dev-debrief/wiki-query/dev-check)
- `eval/ceremony-lift/stage2/`: 3 routed checker tightenings only (6677157; everything else byte-frozen)
- `.claude/rules/active-knowledge.md` retired at this debrief (final instance deleted, no carry-forward)

## Test Status
make test: all 27 scripts pass. make eval: 50/50. Review gate 9/10 accept (4 MEDIUMs fixed inline, 2 noted pre-existing).

## Recent Commits
- 6f6b9a3 Phase 88 T5/T6 close-out: exit-criteria runner ALL-PASS 10/10
- df3e623 Phase 88 trim-trial: wk-seeding (execution-corrected, revert-coupled)
- d43950f Phase 88 trim-trial: ak-ride-along
- b8bd416 Phase 88 harden: check-tests-were-run (HEU-007 dual-condition)
- 75b48af Phase 88 cut: detect-loop (couldnt-fire upstream-PERMANENT)
(Review-gate inline fixes + debrief artifacts are in the working tree, pending the delivery commit.)
