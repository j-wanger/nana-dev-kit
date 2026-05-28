---
title: "Phase 55 complete (harness activation overhaul — cascade fix, spec reform, cognitive readiness)"
aliases: [2026-05-28-phase-55-harness-activation-overhaul-complete]
category: journal
tags: [harness, installation, spec-reform, registration, cognitive-readiness, experiment]
parents: [phase-55-harness-activation-overhaul]
created: 2026-05-28
updated: 2026-05-28
source: debrief
---

# Phase 55 complete (harness activation overhaul — cascade fix, spec reform, cognitive readiness)

## What Happened
- Diagnosed and fixed cascade failure: nana-init not installed -> enforce marker missing -> all enforcement silently disabled. Root cause for experiment's "harness only +0.25 over bare Claude" finding
- Added YAML frontmatter to nana-init/SKILL.md (was the missing piece preventing install.sh cp -r)
- Registered py-review-stop-prompt.md in modules.json (orphaned prompt file) with Stop event hook support added to register-settings.py
- Built bidirectional registration completeness test (test_registration.sh, 40 assertions) checking filesystem <-> modules.json both directions
- Reformed spec template: Deliverables -> Success Vision, added Domain Research Questions subsection, added Reasoning Enablement reviewer dimension. Based on +1.75 open-ended prompt experimental finding
- Extracted cognitive-readiness.sh from session-start.sh, consolidating 5 scattered advisory outputs into 1 structured diagnostic. session-start.sh back to 70 lines (was 137, over cap since Phase 23)
- Added empty-wiki guidance in dev-plan Step 2 (suggests /wiki-bootstrap when wiki exists but has no articles)
- Phase used USER OVERRIDE escape hatch: skipped /spec --internal because experiment data directly informed direction

## Decisions Made
- [[cascade-failure-diagnosis|Cascade Failure: nana-init -> Enforcement Disabled]] -- high confidence
- [[spec-reform-reasoning-over-compliance|Spec Reform: Reasoning Over Compliance]] -- medium confidence
- [[bidirectional-registration-invariant|Bidirectional Registration Invariant]] -- high confidence

## Problems Solved
- nana-init not installed despite being in modules.json -- YAML frontmatter missing from SKILL.md
- py-review-stop-prompt.md existing on disk but not registered in modules.json -- orphaned component
- session-start.sh at 137 lines, over 70-line cap since Phase 23 -- extracted cognitive-readiness.sh module

## Open Questions
- (carried forward) Haiku judge inter-run variance: mean ranges 2.97-4.85 across runs (raised 2026-05-27)
- Knowledge wiki has 16 heuristic articles but zero non-heuristic content -- /wiki-bootstrap needed to seed domain knowledge

## Artifacts Changed
- `install.sh` (nana-init installation fix)
- `modules.json` (py-review-stop-prompt.md registration)
- `scripts/register-settings.py` (prompt-type hook support)
- `templates/.claude/skills/nana-init/SKILL.md` (YAML frontmatter added)
- `templates/.claude/skills/spec/SKILL.md` (Deliverables -> Success Vision, Domain Research Questions)
- `templates/.claude/skills/spec/spec-reviewer-prompt.md` (Reasoning Enablement dimension)
- `templates/.claude/hooks/session-start.sh` (refactored, back to 70 lines)
- `templates/.claude/hooks/session-start.d/cognitive-readiness.sh` (new module)
- `templates/.claude/skills/dev-plan/SKILL.md` (empty-wiki guidance)
- `tests/test_registration.sh` (new, 40 assertions)
- `Makefile` (test_registration wired)

## Related
- [[phase-55-harness-activation-overhaul|Phase 55: Harness Activation Overhaul]] -- parent phase

## Soft Observations / Phase N+1 Candidates
- The functional smoke invariant (Phase 41) checks "does registered stuff work?" but not "is stuff registered?". The bidirectional test fills this gap. The invariant definition in spec SKILL.md Step 2.6 could be expanded. | Expand functional smoke invariant definition | test_registration.sh demonstrates the pattern
- session-start.sh was 137 lines before this phase (over the 70-line cap from Phase 22). The cap eroded over Phases 23-54 without any test catching it. | Add line-count assertion for session-start.sh | Phase 55 refactoring experience
- Knowledge wiki has 16 heuristic articles but zero non-heuristic content. The cognitive layer can't deliver value if there's no domain knowledge to inject. | Run /wiki-bootstrap to seed domain content | cognitive-readiness.sh reports wiki state

### Retro Check (Phases 51-55)

| Dimension | Findings | Signal |
|-----------|----------|--------|
| 1. Recurring Blockers | 0 | none |
| 2. Decision Reversals | 0 | none |
| 3. User Corrections | 1 (USER OVERRIDE: skipped /spec for Phase 55) | low |

The USER OVERRIDE in Phase 55 is a legitimate escape hatch, not a correction -- experiment data directly informed the direction, making a prescriptive spec counterproductive. No systemic issues across Phases 51-55. The cascade failure diagnosis was the most significant finding: a single root cause (nana-init not installed) explained multiple categories of "harness not helping" in the effectiveness experiment.

Recommendations:
- No action needed. Override was justified and documented.

### Health Delta
- +1 test script: test_registration.sh (9 total)
- +40 test assertions (registration completeness)
- 7 eval fixture updates (session-start output format changes)
- README: 8 -> 9 scripts
- All tests pass (except pre-existing memory venv dyld issue)
- Eval: 52/52 (100%)
