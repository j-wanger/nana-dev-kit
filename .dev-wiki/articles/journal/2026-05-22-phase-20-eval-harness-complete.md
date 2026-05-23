---
title: "Phase 20: Eval Harness — complete"
aliases: []
category: journal
tags: [eval, testing, benchmark, hooks, lifecycle, corpus, scoring]
parents: [phase-20-eval-harness]
created: 2026-05-22
updated: 2026-05-22
source: debrief
---

# Phase 20: Eval Harness — complete

## What Happened
- Created scripts/eval-runner.sh (~270 lines): scenario discovery, HOME isolation per scenario (tmpdir + trap cleanup), fixture staging from JSON manifests, binary scoring (pass=1.0, fail=0.0), category breakdown, summary report with Score: line. Hard-requires jq.
- Built eval/ top-level directory with 3 subdirectories: corpus/ (18 scenarios in 3 categories), schemas/ (4 JSON input schemas), validators/ (3 bash validation scripts).
- Hook fidelity corpus covers 5 hooks: enforce-spec (4 scenarios), enforce-loop (2), detect-loop (2), session-start (1), pre-compact (1). 10 hook scenarios total.
- Skill artifact validators: validate-spec.sh, validate-phase-article.sh, validate-decision-article.sh. 5 skill scenarios (spec valid/invalid, phase valid/invalid, decision valid).
- Lifecycle compliance corpus: 3 scenarios testing multi-hook chains (deliverable enforcement, session enforcement status, spec enforcement flow).
- Added eval: target to Makefile. eval/README.md documents corpus structure and scoring.
- All 18 scenarios score 18/18. Existing 128 tests still pass.

## Decisions Made
- [[eval-binary-scoring-only|Binary scoring only for eval harness]] — medium confidence (created during planning, validated in implementation)
- [[eval-jq-hard-dependency|jq as hard dependency for eval runner]] — medium confidence (created during planning, validated in implementation)
- [[eval-top-level-directory|eval/ as top-level directory]] — medium confidence (created during planning, validated in implementation)

## Problems Solved
- No significant blockers. bash 3.2 compatibility (macOS) was a recurring constraint — no associative arrays, careful with parameter expansion.

## Open Questions
- None.

## Artifacts Changed
- `scripts/eval-runner.sh` (new — ~270 lines, corpus runner with scoring and isolation)
- `eval/corpus/` (new — 18 scenario directories: 10 hook-*, 5 skill-*, 3 lifecycle-*)
- `eval/schemas/` (new — 4 JSON input schemas: pre-tool-use, post-tool-use, stop, session-start)
- `eval/validators/` (new — 3 bash validators: validate-spec.sh, validate-phase-article.sh, validate-decision-article.sh)
- `eval/README.md` (new — corpus documentation)
- `Makefile` (new eval: target)

## Health Delta
- Tests: 128 (unchanged). Eval: 18/18 scenarios. Budget: 245/300. Soul: 59/60.
- New dependency: jq (eval-only, not required for make test).

## Gate Compliance
- spec: approved -- present, standard gate
- approach: yes -- present, standard gate
- plan-review: yes -- present, standard gate
- tasks: yes -- present, standard gate
All 4 standard gates present. No gates SKIPPED without justification.

## Activation Quality
4/4 active-knowledge entries referenced during implementation (hook exit codes, enforcement architecture, eval design decisions, existing test patterns). Hit rate: 100%. No dead entries.

### Retro Check (Phases 16-20)

| Dimension | Findings | Signal |
|-----------|----------|--------|
| 1. Recurring Blockers | 0 | none |
| 2. Decision Reversals | 0 | none |
| 3. User Corrections | 0 | none |

Retro check: no systemic issues in Phases 16-20. /spec routing issue (carried Phases 14-17) was resolved in Phase 18. bash 3.2 compatibility is a recurring constraint but handled ad-hoc without blocking. Gate compliance clean across all 5 phases.

## Soft Observations / Phase N+1 Candidates
- Template-only hooks (audit-log, auto-ruff-format, block-dangerous-bash, check-tests-were-run, scan-secrets) not covered by eval — corpus expansion candidate for future phase | suggest: add 5+ scenarios for template hooks | evidence: eval corpus gap analysis
- bash 3.2 compatibility is a recurring constraint (macOS ships old bash, no associative arrays) — worth documenting as project convention | suggest: add to AGENTS.md or working-knowledge | evidence: Phase 20 implementation + multiple prior phases

## Related
- [[phase-20-eval-harness|Phase 20: Eval Harness]] -- parent phase
