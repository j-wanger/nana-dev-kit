---
title: "Phase 18: Spec/Dev-Plan UX Unification"
aliases: []
category: phases
tags: [spec, dev-plan, ux, skill-routing]
parents: []
created: 2026-05-22
updated: 2026-05-22
source: plan
status: completed
scope: ["templates/.claude/skills/dev-plan/*", "install.sh", "tests/*"]
entry_criteria: "Phase 17 complete, spec approved 8/10"
exit_criteria: "Companion file exists, SKILL.md references it, STOP removed, line count ≤350, routing article, tests pass"
---

# Phase 18: Spec/Dev-Plan UX Unification

## Objective

Eliminate the manual /spec -> /dev-plan handoff by making dev-plan auto-invoke /spec when no spec exists, and investigate /spec routing failure.

## Approach

Use a companion file `spec-auto-invoke.md` (~30-40 lines) referenced from SKILL.md Step 0.6. Step 0.6 becomes a ~3-line pointer replacing the current STOP block. Companion defines: user notification, Skill tool invocation of /spec, three terminal states (approved->restart Step 1, rejected->abort, failed->abort), restart protocol. Routing investigation documents findings in decision article. install.sh copies companion file in dev-wiki module.

## Scope

Files and modules affected:
- `templates/.claude/skills/dev-plan/spec-auto-invoke.md` -- new companion file
- `templates/.claude/skills/dev-plan/SKILL.md` -- Step 0.6 modification
- `install.sh` -- copy companion file in dev-wiki module
- `tests/test_install.sh`, `tests/test_templates.sh` -- new assertions
- `.dev-wiki/articles/decisions/spec-routing-investigation.md` -- routing findings

## Constraints

- dev-plan SKILL.md must stay <=350 lines (338 currently, 12 headroom)
- Restart = re-read state in same execution, NOT recursive self-invocation
- Three terminal states only: approved->continue, rejected->abort, failed->abort
- No circular invocation (spec's pre-check guards this)

## Exit Criteria

- [x] `test -f templates/.claude/skills/dev-plan/spec-auto-invoke.md`
- [x] `grep -q 'spec-auto-invoke' templates/.claude/skills/dev-plan/SKILL.md`
- [x] `! grep -q 'Run.*\/spec.*first.*STOP' templates/.claude/skills/dev-plan/SKILL.md`
- [x] `[ $(wc -l < templates/.claude/skills/dev-plan/SKILL.md) -le 350 ]`
- [x] `test -f .dev-wiki/articles/decisions/spec-routing-investigation.md`
- [x] `grep -q 'spec.auto.invoke\|auto_invoke_spec' tests/test_templates.sh`
- [x] `make test` (120 tests passing)

## Assumptions

- Skill tool invocation reliably invokes /spec from dev-plan context. If false: fall back to better UX messaging.
- spec's pre-check prevents circular invocation. If false: add re-entry guard.
- 12 lines headroom insufficient for inline; companion file is default path.

## Tasks

5 tasks (3S 2M), all completed. See tasks.md Phase 18 section.

## Decisions

- [[companion-file-spec-auto-invoke]] -- high confidence, companion file pattern for auto-invocation logic
- [[spec-routing-investigation]] -- high confidence, platform issue mitigated by auto-invocation

## Completion

All 5 tasks done, all exit criteria met. Phase READY FOR COMPLETION. Journal: [[2026-05-22-phase-18-spec-devplan-ux-complete]].
