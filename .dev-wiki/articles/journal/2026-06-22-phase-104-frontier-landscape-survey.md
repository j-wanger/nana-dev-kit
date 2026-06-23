---
title: "Phase 104 complete — Emerging-Agent-Tooling Landscape Survey (frontier pillar re-aimed): large delta, the post-cutoff retrieval sweet spot DEMONSTRATED"
date: 2026-06-22
tags: [frontier, landscape-survey, discovery, github-trending, post-cutoff-retrieval, blind-baseline, heu-012, companion-research]
phase: 104
type: journal
---

# Phase 104 — Emerging-Agent-Tooling Landscape Survey

## What happened

Planned as pillar-2 (contract-loop) follow-on; the maintainer **redirected** at the first question — turned
down the a/b/c/pivot fork and re-pointed Phase 104 at the **frontier pillar's missing discovery survey**:
"surveying GitHub for emerging and trending repos for the latest agent/harness/tools/framework advancements."
Ph97/98 were lab-PRIMARY *positioning*; this INVERTS the object (GitHub OSS by traction PRIMARY) and the
orientation (DISCOVERY, not a verdict). Lens chosen: **landscape awareness** (over adopt-scout / threat-refresh).
Output: **both layers** (cluster spine + repo-evidence appendix). Rigor: **lightweight method-note** as the
gitignored spec (Ph97 precedent), no byte-freeze — the **blind baseline** is the anti-retrofit discipline.

4 tasks, all done. 4 parallel research agents fanned out (GitHub search API / trending pages / curated 2026
lists / HF+papers). **VERDICT: NOT the informative null — the value-delta is LARGE.**

## Key result — the delta (survey vs sealed priors)

GENUINELY-NEW (could not name from parametric memory): the **skills/plugins economy** (shipped artifact =
skill files, not code; vendor + community repos at 40–65k stars), the **`openclaw` runtime ecosystem** (~380k
stars, post-cutoff), **agent-security scanners over skill files** (SkillSpector, agent-governance-toolkit,
AgentDoG — the kit's own boundary-validator posture as a named OSS front), **code-KG-as-MCP** at 53–66k stars,
**token/context-compression as product**, **"harness engineering" as a discipline**, **meta-harnesses
orchestrating other coding agents**, **self-evolving/skill-lifecycle** agents. Correct priors: MCP explosion,
agent-memory growth, deep-research agents, "context engineering." Overweighted (now incumbents, not momentum):
LangChain/CrewAI/AutoGen/DSPy/LlamaIndex. The center of gravity moved **down-stack + toward governance**.

**A1 resolves TRUE** — first empirical demonstration of Ph59's carved-out exception: retrieval DOES pay on
genuinely post-cutoff topics (cutoff Jan-2026, survey window Dec-2025→Jun-2026).

## Health Delta

None — SHIPS NOTHING. `make test` PASS, `make eval` 50/50, drift clean, `git ls-files companion/` empty.
Apparatus gitignored `companion/research/frontier-landscape/` (5 files: method-note, blind-baseline,
candidates, landscape-map, delta).

## Problems / near-misses (the integrity story)

1. **Near-miss: almost discarded real data as hallucinated.** The 2026 star magnitudes (a 380k-star
   6-month-old repo; "+48k stars/month") violated my parametric prior so hard I suspected the subagents
   fabricated their API responses. Per [[HEU-012]]/Ph82 I verified against ground truth instead of trusting
   OR discarding — and the data was **real**. The mismatch WAS the post-cutoff signal. Lesson: in post-cutoff
   surveys, parametric implausibility is a SIGNAL, not a defect — verify, don't discard.
2. **Caught one real fabrication:** `NousResearch/Hermes` (claimed ~140k) → HTTP 404, excluded (Agent C had
   already flagged it). cited-or-omit held.
3. **Caught my own dead verifier:** the arXiv CLI check returned NO ENTRY even for `1706.03762` ("Attention
   Is All You Need") → broken verifier, not fake papers (clean-on-positive-control = instrument-dead, HEU-012).
   Fallback ground truth: `hf.co/papers/<id>` resolved 200.
4. **zsh word-split trap (re-bit, working-knowledge Ph84):** an unquoted `$repos` list didn't split → the
   verify loop ran once (HTTP 000). Fixed with an explicit zsh array + a positive control (`${#repos}`==35).
5. **Unauth GitHub rate limit (HTTP 403 at ~60 req):** mid-verification the curl batch hit the limit.
   Resolved with authenticated **`gh api`** (5000/hr) → all remaining 30 repos verified. Final tally:
   **~65/65 named repos orchestrator-verified real**, 1 fabrication excluded.

## Decisions

- [[frontier-landscape-survey]] (medium→ confidence raised at close) — the redirect + the landscape-awareness
  / both-layers / lightweight-method-note / one-shot design.

## Gate Compliance

Direction gate confirmed 2026-06-22 (ledger Phase-104, all_accept:false — A1 don't-know→blind-baseline
control; A2-A5 accept). Delivery gate accepted 2026-06-22 (maintainer "Yes"). Ledger revisit filled: A1 held
(resolved TRUE — large delta, novel signal confirmed), A2-A5 held.

## Soft Observations / Phase N+1 Candidates

- **Adopt-scout follow-on (strongest):** the **agent-security-scanner** category (deterministic scanners over
  skill/trajectory files — SkillSpector, agent-governance-toolkit, AgentDoG) and **code-KG-as-MCP** rhyme
  directly with the kit's boundary-validator / retrieval-over-parametric bets. A gated adopt-scout phase
  could evaluate what (if anything) to borrow. Evidence: `delta.md` "what this means for the kit."
- **Post-cutoff retrieval sweet spot is now demonstrated, not hypothesized** — this UPDATES the Ph59
  working-knowledge claim ("value on post-cutoff topics was not measured"). Candidate: a one-line
  working-knowledge amendment (deferred — WK is over its size cap; capture lives here + in the decision article).
- **Recurring trend-scan (A3 deferred):** if the map proves useful kept-fresh, a discovery-aimed standing
  scan is a gated follow-on (NOT the Ph98 positioning watch — a different instrument).
- **Reusable method:** blind-baseline-before-search (priors sealed → value = measured delta) is a clean
  anti-retrofit + value-measurement pattern for any post-cutoff discovery survey.
