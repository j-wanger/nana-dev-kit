# Active Phase Context

Phase: 61 - Validate Memory & Knowledge Integration
Status: Active (2/7 tasks). EXPERIMENT-FIRST — validate integration directions by A/B, defer build to Phase 62.
  T1 done (signal gate + pre-reg). T2 done → **wiki-search arm D1 CUT** (measured −0.67 composite, variance-dominated; best-case firewall retrieval showed no lift + mild reasoning harm = Phase-59-redux confirmed by measurement). Meta-finding: the always-loaded working-knowledge.md IS the effective retrieval layer (baseline strong because of it).
  REMAINING: MCP-memory read-path A/B (D2); 2-tier/3-tier (D3, informed — lean curate-into-hot-cache); T6 step-renumber (deterministic, wide ref-refactor); T7 gate. RESUME: eval/memory-integration/results.md has pre-reg + T1/T2. Recommend FRESH session for the rest (marathon session; step-renumber better done fresh).
Objective: Decide by A/B evidence which memory/knowledge-retrieval integrations earn a place in the harness flow — wire the real retrieval engines (knowledge-wiki knowledge.db FTS5/vector; MCP memory_search) into planning vs the always-loaded-markdown status quo. Plus a deterministic step-renumber (whole numbers), walled off from the A/B.

Scope: eval/memory-integration/; templates/.claude/skills/{dev-plan,dev-debrief,spec}/SKILL.md (step-renumber ONLY); tests/

5 directions (factored): WHAT (wiki-search D1 / MCP memory D2 / baseline) × HOW (raw vs retrieval-subagent firewall D5) × PREP (raw knowledge.db vs absorbed D4); 2-tier/3-tier (D3) derived from D2.

Key constraints:
  - Phase-59-redux risk: candidate wikis are RAW COMMODITY SCRAPES (where retrieval was net-negative). Signal gate FIRST; topics must be weak-parametric AND wiki-covered or declare redux + stop the retrieval arm. Don't run an A/B that can't show lift.
  - Reuse Phase 58-59 method: pre-registration-first, clean-context A/B, blind judge, ≥3 runs + variance gate, burden-of-proof-on-feature, cost ledger.
  - Measure context poisoning (non-target regression) — the firewall's reason to exist.
  - EXPERIMENT-ONLY: decide, don't build the integrations (that's Phase 62). Only code = experiment harness + the independent step-renumber.
  - Step-renumber is deterministic (no A/B); update EVERY cross-ref kit-wide + numbering-continuity test.

Tasks: T1 signal-gate+pre-reg → T2 Stage-0 falsification (CHECKPOINT) → T3 Stage-1 source×mechanism (cond.) → T4 Stage-2 conclusions (cond.) → T5 aggregate+decide → T6 step-renumber (independent) → T7 regression gate.

Exit criteria: results.md w/ pre-reg first; signal gate + weak-parametric topics (or redux stop); Stage-0 delta; firewall + poisoning + cost recorded; per-direction keep/cut + P62 build list; step-renumber done w/ refs resolved + continuity test; make test green + eval 100%.

Abort: if a stage can't meet its pre-registered criterion after 3 attempts, mark [blocked:], report, ask. Execution may use Workflow (user opt-in).

Gates:
- [x] Direction confirmed by user (approach approved 2026-05-29 "yes" — experiment-first, 5 directions incl. user-added subagent firewall, falsification-first staging)
- [ ] Delivery accepted (post-implementation report)
