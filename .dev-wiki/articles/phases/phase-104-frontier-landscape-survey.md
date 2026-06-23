---
title: "Phase 104: Emerging-Agent-Tooling Landscape Survey (frontier pillar, GitHub-trending discovery)"
aliases: [phase-104, frontier-landscape-survey, emerging-agent-tooling-survey]
category: phases
tags: [frontier, landscape-survey, discovery, github-trending, blind-baseline, companion-research, heu-012]
parents: [frontier-landscape-survey]
created: 2026-06-22
updated: 2026-06-22
source: plan
status: completed
scope: ["companion/research/frontier-landscape/**", ".dev-wiki/**", ".claude/rules/active-phase.md"]
entry_criteria: "Ph103 delivered + accepted (2026-06-22); maintainer reviewed the frontier pillar (Ph97/98) and redirected Phase 104 to the GitHub-trending discovery survey it skipped; direction gate closed 2026-06-22 (ledger Phase-104); landscape-awareness lens + both-layers + lightweight method-note + one-shot all positioned."
exit_criteria: "Gitignored method-note (spec) + committed blind baseline BEFORE any search; landscape-map.md (cluster spine + repo-evidence appendix, every entry cited source+date+traction); the value-delta vs blind baseline (genuinely-new vs already-known) OR the informative null; recency positive-control passes; ZERO kit code change; make test PASS + eval 50/50 + drift 0; git ls-files companion/ empty."
---

# Phase 104: Emerging-Agent-Tooling Landscape Survey (frontier pillar, GitHub-trending discovery)

## Objective

Survey GitHub for **emerging and trending repos** in the agent / harness / tools / framework space (last ~6
months, ranked by traction) and produce a **landscape-awareness map** — orientation on where the OSS agent
ecosystem is heading, not an adopt-list, not a positioning verdict. This is the frontier pillar re-aimed:
the discovery survey the maintainer envisioned but Ph97/98 (lab-primary positioning) never did. Lands on the
one untested amplifier frontier — post-cutoff signal a bare model can't hold (Ph59's carved-out exception).

## Scope

Files and modules affected:
- `companion/research/frontier-landscape/**` — the gitignored, local-only survey apparatus (method-note,
  blind baseline, raw candidate pool, landscape-map.md)
- `.dev-wiki/**` — planning + close-out bookkeeping
- `.claude/rules/active-phase.md` — compaction anchor

OUT: any kit code/config change; any *adoption* of a surfaced advancement (a separate gated adopt-scout
follow-on); a positioning verdict / re-score of the Ph97 frozen rule (different question); a recurring
trend-scan capability (A3 one-shot-first); `specs/` (the gitignored method-note IS the spec, Ph97 precedent).

## Exit Criteria

- [ ] `companion/research/frontier-landscape/` gitignored + `git ls-files companion/` empty
- [ ] `method-note.md` — sources (github/trending + GitHub search + curated awesome/this-week lists + HF
      trending/papers) + "emerging/trending" operationalization (date window + traction signal) + cluster
      taxonomy seed + the two controls, serving as the spec
- [ ] `blind-baseline.md` — the trend map from parametric memory, committed BEFORE any search (the
      anti-retrofit seal + the value-measurement control)
- [ ] `landscape-map.md` — pattern/capability cluster spine (appearing / momentum / fading) + repo-evidence
      appendix table, every entry cited (source + date + traction)
- [ ] The value-DELTA vs the blind baseline (genuinely-new vs already-known) OR the pre-registered
      informative null (~0 delta)
- [ ] Recency positive-control passes (a known-established repo does NOT classify as "emerging")
- [ ] ZERO kit code/config change; `make test` PASS + `make eval` 50/50 + drift 0

## Constraints

- **Blind baseline committed BEFORE any web search** — the anti-retrofit seal; without it, parametric recall
  masquerades as fresh discovery and the value-delta is uncomputable.
- **Cited-or-omit:** every repo / claim traces to a fetched source + date + traction signal — no entry from
  parametric memory presented as discovered ([[can't-measure-clean-context-in-kit]] discipline, inverted:
  here the leak is *my own* parametric knowledge, guarded by the blind baseline).
- **Recency positive-control** ([[HEU-012]]): a known-established repo MUST NOT pass the emerging filter, or
  the filter is dead — clean-on-control = instrument-dead.
- **Landscape-awareness only:** orientation, not adopt-ranking, not a positioning verdict (the two lenses the
  maintainer rejected). No adoption decision in this phase.
- **Ships NOTHING:** the map lives in gitignored `companion/`; the kit is unchanged.

## Checkpoints

- Before T2 (search): confirm `blind-baseline.md` is written + committed — no searching against an unsealed
  baseline (anti-retrofit).
- After T2: if the recency positive-control fails (a known-established repo classifies as emerging), STOP and
  fix the trending filter before synthesis (clean-on-control = instrument-dead).
- At T4: if the value-delta is ~0 (the map is recoverable from parametric memory), record the informative
  null (Ph59-consistent) — do NOT inflate known repos into "discoveries."

## Assumptions

- The survey surfaces genuinely novel signal beyond parametric recall — DON'T-KNOW, converted to a control:
  the blind-baseline delta measures it; ~0 = informative null (A1).
- Landscape-awareness is the right commitment level (not adopt-scout / threat-refresh) — maintainer chose it
  (A2).
- One-shot first, not a standing watch — maintainer accept (A3); a recurring scan is a gated follow-on.
- Both layers (cluster spine + repo-evidence appendix) is the right map unit — maintainer revised from my
  clusters-only rec (A4).
- A lightweight method-note (no byte-freeze) is sufficient rigor — there is no scored verdict to retrofit;
  the blind baseline is the anti-retrofit discipline (A5).

## Notes

Redirect, not continuation: the maintainer turned down the pillar-2 (contract-loop) a/b/c/pivot fork and
re-pointed Phase 104 at the frontier pillar's missing discovery survey. T0 weakest assumption = whether
trending-repo signal beats parametric recall (the Ph59 regime question); handled as the blind-baseline
control, not a bet. Decision: [[frontier-landscape-survey]].

## Outcome

IMPLEMENTATION COMPLETE 2026-06-22 (4/4 tasks; status stays **active** — delivery gate pending). Delivered 5
gitignored artifacts in `companion/research/frontier-landscape/`: `method-note.md` (spec), `blind-baseline.md`
(priors sealed before search), `candidates.md` (verified evidence pool), `landscape-map.md` (11-cluster spine
+ repo-evidence appendix), `delta.md` (value-delta).

**VERDICT — NOT the informative null; the value-delta is LARGE (the survey PAID).** The genuinely-new set is
dominated by categories I could not name from parametric memory: the **skills/plugins economy** (shipped
artifact = skill files, not code; vendor + community repos at 40–65k stars), the **`openclaw` runtime
ecosystem** (~380k stars, post-cutoff), **agent-security scanners over skill files** (SkillSpector,
agent-governance-toolkit — the kit's own boundary-validator posture as a named OSS front), **code-KG-as-MCP**
at 53–66k stars, **token/context compression as product**, **"harness engineering" as a named discipline**,
**meta-harnesses orchestrating other coding agents**, and **self-evolving/skill-lifecycle** agents. Correct
priors (already-known): MCP explosion, agent-memory growth, deep-research agents, "context engineering"
vocabulary. Overweighted (fading-relative): LangChain/CrewAI/AutoGen/DSPy/LlamaIndex are now incumbents, not
the momentum story. **A1 resolves TRUE** — first empirical demonstration of Ph59's carved-out exception
(retrieval pays on genuinely post-cutoff topics).

**Integrity (controls did their job, [[HEU-012]]):** the orchestrator nearly discarded real data as
hallucinated (the 2026 star magnitudes — e.g. 380k — violated my parametric prior), then verified a 24-repo
sample directly against `api.github.com` (24/24 real); caught one real fabrication (`NousResearch/Hermes` →
404, excluded); and caught its OWN dead arXiv verifier via a positive control (`1706.03762` returned NO
ENTRY → broken verifier, not fake papers; HF papers page resolved 200 as the fallback ground truth). Recency
positive-control PASSES (LangGraph 2023-08, browser-use 2024-10 correctly pre-window incumbents).

**Health:** SHIPS NOTHING — `make test` PASS, `make eval` 50/50, drift clean, `git ls-files companion/`
empty. On delivery acceptance: transition active→completed + flip the Delivery gate + fill A1 revisit-status
(→ bit) at `/dev-debrief`.
