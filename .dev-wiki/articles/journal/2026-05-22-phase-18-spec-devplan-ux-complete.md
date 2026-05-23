---
title: "Phase 18: Spec/Dev-Plan UX Unification — complete"
aliases: []
category: journal
tags: [spec, dev-plan, ux, companion-file, skill-routing, auto-invocation]
parents: [phase-18-spec-dev-plan-ux-unification]
created: 2026-05-22
updated: 2026-05-22
source: debrief
---

# Phase 18: Spec/Dev-Plan UX Unification — complete

## What Happened
- Investigated /spec routing failure: confirmed it is a Claude Code platform behavior, not a nana-dev-kit issue. Agent-side Skill tool invocation works reliably. Documented as decision article [[spec-routing-investigation]].
- Created spec-auto-invoke.md companion file (~35 lines) defining auto-invocation protocol: user notification, Skill tool call, three terminal states (approved->restart, rejected->abort, failed->abort), restart protocol.
- Modified dev-plan SKILL.md Step 0.6: replaced STOP block with 3-line pointer to companion file. SKILL.md remains at 338/350 lines.
- install.sh required no changes — directory-based copy (`cp -r`) in dev-wiki module automatically distributes new companion files.
- Added 5 test assertions for spec-auto-invoke: companion file exists, SKILL.md references it, STOP removed, line count check, install.sh copies it.

## Decisions Made
- [[companion-file-spec-auto-invoke|Companion file for spec auto-invocation]] — high confidence (already created during dev-plan)
- [[spec-routing-investigation|Spec routing is a platform issue]] — high confidence (already created during dev-plan)

## Problems Solved
- /spec routing blocker (carried across 4+ phases) resolved by mitigation: dev-plan auto-invokes /spec via Skill tool, bypassing user-side routing entirely.
- Spec/dev-plan UX friction (user-flagged) resolved: manual /spec -> /dev-plan handoff eliminated.

## Open Questions
- None new. Both carried-forward blockers resolved in this phase.

## Artifacts Changed
- `templates/.claude/skills/dev-plan/spec-auto-invoke.md` (new — auto-invocation protocol companion)
- `templates/.claude/skills/dev-plan/SKILL.md` (Step 0.6 modified — STOP replaced with companion reference)
- `tests/test_templates.sh` (5 new assertions)
- `tests/test_install.sh` (companion copy assertion)
- `.dev-wiki/articles/decisions/spec-routing-investigation.md` (new — routing investigation findings)
- `.dev-wiki/articles/decisions/companion-file-spec-auto-invoke.md` (new — companion file pattern decision)

## Health Delta
- Tests: 115 -> 120 (+5 spec-auto-invoke assertions)
- Budget: 245/300 (unchanged)
- Soul: 59/60 (unchanged)
- SKILL.md: 338/350 (unchanged — replacement was equal length)

## Gate Compliance
- spec: 8/10 (revised) -- present, standard gate
- approach: yes -- present, standard gate
- plan-review: 9/10 -- present, standard gate
- tasks: yes -- present, standard gate
All 4 standard gates present. No gates SKIPPED without justification.

## Activation Quality
Active-knowledge had 3 entries for Phase 18: skill-tool-invocation-pattern, spec-precheck-between-phases, companion-file-spec-auto-invoke. All 3 referenced during implementation. No dead entries.

## Related
- [[phase-18-spec-dev-plan-ux-unification|Phase 18: Spec/Dev-Plan UX Unification]] -- parent phase
- [[roadmap-gap-analysis|Roadmap]] -- closes U.1 (spec routing) and U.2 (spec/dev-plan UX)

## Soft Observations / Phase N+1 Candidates
- install.sh's directory-based copy means new companion files auto-distribute without install.sh changes — a property worth documenting as a decision or convention | suggest: document in architecture or working-knowledge | evidence: Task 4 required no install.sh changes
- Roadmap gap analysis article is a new artifact type for tracking phase candidates across sessions — useful for maintaining continuity | suggest: consider formalizing as dev-wiki convention | evidence: roadmap-gap-analysis.md
- User feedback pattern: skills should auto-invoke dependencies rather than requiring manual invocation sequences — generalizable beyond spec/dev-plan | suggest: audit other skill boundaries for similar friction | evidence: Phase 18 motivation
