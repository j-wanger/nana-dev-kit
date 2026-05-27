<!-- nana:approved -->
# Phase 44: Heuristic Learning System — Foundation

> Spec derived from user-authored Cognitive Enhancement Plan (2026-05-26).
> Maps to plan's "Phase 41: Heuristic Learning System — Foundation" (41a + 41b + 41c).

## Objective

Build the heuristic storage layer, seed it with 10 transferable reasoning patterns from nana-dev-kit's 43-phase history, integrate retrieval into session-start, and establish a baseline reasoning eval pipeline with LLM-as-judge scoring.

## Scope

- `wiki/` — knowledge wiki scaffold (via /wiki-init)
- `wiki/heuristics/` — heuristic articles (SCHEMA.md + 10 seed HEU-*.md)
- `templates/.claude/hooks/session-start.sh` — heuristic count + guidance
- `eval/reasoning/` — reasoning eval infrastructure (runner, judge, scenarios, baseline)

## Exit Criteria

1. `wiki/schema.md` exists with "heuristic" as a category
2. `wiki/heuristics/SCHEMA.md` defines structured format (id, trigger, domain, always/never/why/anti-pattern/source)
3. 10 seed heuristics in `wiki/heuristics/HEU-*.md`, each with all required sections
4. Session-start emits `[nana:heuristics]` count when `wiki/heuristics/` exists
5. `eval/reasoning/` has runner, judge prompt, and 10 decision scenarios
6. Baseline scores recorded in `eval/reasoning/baseline/results.json`
7. `make test` passes, `make eval` 100%

## Constraints

- Heuristics must be TRANSFERABLE — "always validate parser against actual input format" not "always use jq in hooks"
- Reasoning eval is LLM-based (non-deterministic) — separate from deterministic `make eval`
- Seed heuristics sourced from: decision articles, working-knowledge, specs, git history
- Judge variance < 0.5 across 3 runs (consistency check)

## Assumptions

- Knowledge wiki can be initialized without disrupting existing project structure
- Anthropic SDK available for LLM-as-judge eval runner
- 10 decision scenarios extractable from 43-phase history with clear expert answers

## Checkpoints

- After wiki-init: verify schema.md includes heuristic category
- After seed heuristics: transferability check (≥6/10 apply beyond dev harness projects)
- After eval infrastructure: --help works, scenarios parse correctly
- After baseline run: variance < 0.5 confirms judge consistency

## Context: Full Cognitive Enhancement Roadmap

This phase is first of 7+ in the cognitive enhancement plan:
- Phase 44 (this): Heuristic schema, 10 seeds, baseline eval
- Phase 45: Heuristic capture in dev-debrief
- Phase 46: IRON RULES + anti-pattern tables
- Phase 47: Self-dialogue in dev-plan
- Phase 48: Trace collection + pattern analysis
- Phase 49: Prompt-type hooks (LLM-as-judge during execution)
- Phase 50: Heuristic evolution (helpful/harmful scoring, deprecation)

Sequencing rule: Phase 44 must complete before any other — the heuristic schema and baseline eval are the foundation.
