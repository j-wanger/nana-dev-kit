---
title: "Phase 83: Prune-on-Value Subtraction"
aliases: [phase-83, prune-on-value]
category: phases
tags: [subtraction, prune-on-value, hooks, memory, usage-evidence, heu-012]
parents: []
created: 2026-06-09
updated: 2026-06-09
source: plan
status: active
scope: ["templates/.claude/hooks/enforce-memory.sh", "templates/.claude/hooks/audit-log.sh", "memory_server/*", "scripts/harness-audit.sh", "templates/.claude/skills/dev-wiki/stale-queue-spec.md", "templates/.claude/skills/knowledge-wiki/registry-schema.md", "templates/.claude/skills/knowledge-wiki/session-context.md", "tests/test_companions.sh", "modules.json", "templates/.claude/settings.json", "templates/.claude/skills/MANIFEST", "eval/prune-on-value/*", "README.md", "Makefile", "tests/test_audit_log.sh", "tests/test_scripts_smoke.sh"]
entry_criteria: "Phase 82 delivery accepted; usage-evidence list filed in _CURRENT_STATE.md Blockers; spec specs/phase-83-prune-on-value-subtraction.md nana:approved"
exit_criteria: "10 machine-checkable criteria in specs/phase-83-prune-on-value-subtraction.md (verdict table with 6 closed-enum rows, zero-classification on every cut/disable, liveness-grep.log committed, make test + make eval green, drift 0, settings template clean, one DEREG line + one 'Phase 83 cut:' commit per executed cut/disable)"
---

# Phase 83: Prune-on-Value Subtraction

## Objective

Apply the subtraction test to the 6 dead-weight candidates Phase 82's usage audit evidenced (enforce-memory.sh, memory reinforcement machinery, memory-MCP-in-consuming-project scaffold shipping, audit-log model field, 3 orphan companions, harness-audit.sh): each gets a keep / cut / harden / disable-at-boundary verdict grounded in eval/qa-sweep evidence; cuts remove component + registrations + tests + MANIFEST checksums + doc refs atomically with installed-surface deregistration (~/.claude, edge-screener); make test + make eval green at the reduced surface.

## Scope

Files and modules affected:
- `templates/.claude/hooks/enforce-memory.sh` + its modules.json entry, markers, 3 eval scenarios
- `memory_server/` (reinforcement machinery — disable-at-boundary preferred per vendoring contract)
- `templates/.claude/hooks/audit-log.sh` (model field only; audit-log itself constrained KEEP)
- 3 orphan companions + `tests/test_companions.sh` ORPHAN_EXEMPT pins
- `scripts/harness-audit.sh` (+ test_scripts_smoke.sh entry)
- `modules.json`, regenerated `templates/.claude/settings.json`, `MANIFEST`, README
- NEW: `eval/prune-on-value/` (verdict-table.md + liveness-grep.log)

## Exit Criteria

- [ ] See spec `specs/phase-83-prune-on-value-subtraction.md` — 10 machine-checkable criteria (verdict table, zero-classification, liveness log, make test, make eval, drift 0, settings template, DEREG lines, per-cut commits)

## Constraints

- Every verdict cites its Phase-82 matrix row / Blockers filing; enforcement.log-provenance-hazard evidence cannot be a cut's sole anchor.
- couldnt-fire vs didnt-fire classification mandatory before any cut (arm precondition in mktemp -d sandbox, pipe synthetic trigger).
- Liveness grep: removal set first; alive = references from OUTSIDE it; roots = ALL mechanically DISCOVERED installed-surface roots (kit-marker scan of this machine — A3 reject: discovered, not assumed).
- Installed-surface deregistration is part of every cut, limited to each cut's OWN ghosts (Jake 2026-06-09; the other 10 ghost registrations stay deferred under the Phase-82 drift filing); one candidate per commit; regenerated-artifact diff ⊆ planned removal set; no hand-edits to generated artifacts.
- memory_server verdict menu: keep / disable-at-boundary / cut-with-regenerated-patch.
- Post-cut functional smoke on SURVIVING hooks (pipe a real event), not presence checks.
- Prior decisions bind: [[audit-log-disposition]], [[memory-architecture-classification]], [[single-source-scope-tagged-hook-registration]].
- Zero cuts is a valid outcome.

## Checkpoints

- After verdict table complete, BEFORE any cut: present full table to maintainer (unconditional); cuts execute only on approval.
- Any couldnt-fire classification: STOP for that candidate, file as defect, do not cut.
- Removal set requires editing frozen apparatus or user-owned ~/.claude/rules/: defer with filing.
- Post-cut smoke fails on a surviving hook: revert that cut's commit before next candidate.

## Assumptions

- Phase-82 usage evidence post-dates the enforcement restoration. If false for a candidate: re-measure in sandbox before verdict.
- make template + MANIFEST generator cover all generated artifacts a cut touches. If false: fix generator first (DEPENDENCY), never hand-edit.
- edge-screener reachable read-only. If false: file verification deferred, don't block.
- The kit's 55 memory entries are real voluntary-layer use (candidate 3 = scaffold-shipping decision only). If false: widen only via maintainer decision at checkpoint.
- The 3 orphan companions are truly unreferenced beyond pinned exemptions. If false: keep + un-orphan, file exemption removal.

## Notes

Precedent: Phase 72 [[cash-compaction-recovery-subtraction]] (confirm-truly-dead first). Evidence source: `eval/qa-sweep/verification-matrix.md` usage rows + `repro-runs.log` (frozen, read-only). Hazard: the kit's 4 registered-but-dormant breakages mean a zero can measure broken plumbing, not absent demand — enforcement itself was dormant 15 days within the measurement window's history.
