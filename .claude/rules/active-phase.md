# Active Phase Context

Phase: 44 - Heuristic Learning System — Foundation
Status: PLANNED (0/7 tasks done)
Objective: Build heuristic store (wiki/heuristics/), seed with 10 transferable reasoning patterns from 43-phase history, integrate retrieval into session-start, establish baseline reasoning eval with LLM-as-judge scoring.

Scope: wiki/, wiki/heuristics/, templates/.claude/hooks/session-start.sh, eval/reasoning/
Key constraints: Heuristics must be transferable (not project-specific). Reasoning eval is non-deterministic (separate from make eval). Seed from decision articles + working-knowledge + git history.
Exit criteria: wiki with heuristic category, SCHEMA.md, 10 seed heuristics, session-start integration, eval runner + 10 scenarios + baseline scores, make test + make eval pass.
Abort: If wiki-init disrupts existing project structure or Anthropic SDK unavailable for eval runner.

Gates:
- [x] Direction confirmed by user (approach approved)
- [ ] Delivery accepted (post-implementation report)
