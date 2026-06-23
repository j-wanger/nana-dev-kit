---
title: "Phase 104: Emerging-Agent-Tooling Landscape Survey (frontier pillar, GitHub-trending discovery)"
aliases: [frontier-landscape-survey, emerging-agent-tooling-survey, github-trending-survey]
category: decisions
tags: [frontier, landscape-survey, discovery, github-trending, blind-baseline, companion-research, heu-012]
parents: [phase-104-frontier-landscape-survey]
created: 2026-06-22
updated: 2026-06-22
source: plan
confidence: medium
---

## Context

The frontier pillar (Ph97 [[frontier-positioning-sweep]] + Ph98 [[frontier-watch]]) was built as a
**positioning instrument**: lab-published artifacts PRIMARY (Anthropic/OpenAI/Google SDKs, eng blogs,
papers), OSS only SECONDARY corroboration via known incumbents (aider, opencode, OpenHands, LangGraph,
CrewAI), scored mechanically against a frozen DIFFERENTIATED/COMMODITIZED rule on a fixed B1–B5 primitive
list. The maintainer reviewed that pillar and named the gap: **it never did what he envisioned — a survey of
GitHub for emerging and trending repos for the latest agent / harness / tools / framework advancements.**
Positioning ≠ discovery; lab-primary ≠ GitHub-trending-primary; a verdict-on-our-bet ≠ a map-of-what's-new.

This is consistent with — and actually validates — the kit's own research posture. Ph59 cut web-research
injection as net-negative on *well-documented* topics but explicitly carved out the untested exception:
*genuinely novel / post-training-cutoff* topics. A trending-repo survey is precisely that regime (cutoff
Jan-2026; today Jun-2026 → the last ~6 months of emerging repos are not in parametric knowledge). Ph97 even
flagged it ("the one untested amplifier frontier — post-cutoff signal a bare model can't hold") before
executing lab-primary positioning instead.

## Decision

Run a **one-shot, GitHub-trending-PRIMARY discovery survey** of the OSS agent / harness / tooling ecosystem
(last ~6 months, ranked by traction), output as a **LANDSCAPE-AWARENESS** artifact — orientation, not an
adopt-list, not a positioning verdict. The maintainer chose the awareness lens over adopt-scout and
threat-refresh.

**Output = both layers (A4, maintainer-revised from my clusters-only rec):**
- **Spine — pattern/capability clusters:** what's appearing, what's gaining momentum, what's fading (the
  durable orientation signal — survives repo churn).
- **Appendix — repo-evidence table:** every cluster claim cited to a fetched source + date + traction signal
  (stars / velocity / curation appearance), so the map is auditable, not vibes.

**Two controls carry the rigor (there is no scored pass/fail verdict here, so the heavy Ph97/98 byte-freeze
earns nothing — A5 lightweight):**
- **Blind baseline (the load-bearing control + anti-retrofit seal):** write the trend map I'd produce from
  parametric memory *before any search*, committed first. The phase's VALUE is the measured DELTA (what's
  genuinely new). A ~0 delta is the pre-registered **informative null** — "the trend map is recoverable from
  parametric knowledge," a Ph59-consistent result. Fixing priors before search also prevents relabeling
  known repos as freshly "discovered."
- **Recency positive-control ([[HEU-012]]):** a known-established repo (e.g. LangGraph) MUST NOT classify as
  "emerging," or the trending/recency filter is dead.

A gitignored **method-note** (sources + "trending" operationalization + taxonomy seed + the two controls)
serves as the spec (Ph97 gitignored-deviation precedent — the apparatus is private). Lives entirely in
gitignored `companion/research/frontier-landscape/`. **Ships NOTHING** — any adoption of a surfaced
advancement is a separate gated follow-on (adopt-scout) phase.

**Alternatives considered:** (a) continue pillar-2 / contract-loop (the a/b/c/pivot fork I proposed) —
REJECTED by the maintainer's redirect to the frontier pillar. (b) adopt-scout lens (rank by kit-fit) or
threat/positioning-refresh (re-aim Ph97 with GitHub-trending primary) — both REJECTED in favor of landscape
awareness (lowest commitment; we already over-built one frontier artifact in Ph98). (c) a recurring
trend-scan capability now — DEFERRED (A3 one-shot-first); decide after we see one map's value. (d) a full
Ph97/98 byte-freeze — REJECTED (A5): no verdict to game; the blind baseline is the discipline that fits.

## Consequences

A one-shot orientation map, not an obligation. The genuine risk is **A1**: the survey may regress to the
Ph59 net-negative regime if 2026-H1 "trending" is dominated by incremental versions of repos already in
parametric memory — in which case the blind-baseline delta is ~0 and the honest result is the informative
null (the phase still earns its keep by *measuring* that, vs asserting novelty). Secondary risks: traction ≠
quality (a high-star repo can be hype); a snapshot stales fast (mitigated by the one-shot framing + the
durable cluster spine); my-cutoff bias could mislabel what's "new" (mitigated by date-verified citations on
every entry). The map informs later kit direction but commits to nothing — adopt decisions are out of scope.

## Outcome (delivered 2026-06-22)

NOT the informative null — **the value-delta is LARGE.** The survey surfaced categories I could not name from
parametric memory (the skills/plugins economy, the ~380k-star `openclaw` runtime ecosystem, agent-security
scanners over skill files, code-KG-as-MCP at scale, "harness engineering" as a discipline, meta-harnesses,
self-evolving/skill-lifecycle agents). Confirmed priors: MCP explosion, agent-memory growth, deep-research
agents, "context engineering." Overweighted: the first-gen orchestration frameworks (LangChain/CrewAI/AutoGen/
DSPy/LlamaIndex) are now incumbents, not the momentum story. **A1 resolves TRUE** — first empirical
demonstration of Ph59's carved-out exception (retrieval pays on genuinely post-cutoff topics). Confidence
raised low→medium at close. The controls earned their keep: a near-miss (real 2026 star magnitudes almost
discarded as hallucinated) was caught by orchestrator-executed ground-truth verification (24/24 sample real,
1 fabrication excluded, dead arXiv verifier caught by a positive control). Several emerging fronts rhyme with
the kit's own bets (deterministic scanners over skill files; retrieval-to-cut-tokens; skills as governed
assets) — orientation only; adopt-scouting is a separate gated follow-on.
