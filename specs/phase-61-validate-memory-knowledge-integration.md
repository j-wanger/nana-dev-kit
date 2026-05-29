<!-- nana:approved 2026-05-29 -->
# Spec: Validate Memory & Knowledge Integration (Phase 61)

## Objective

Decide, by A/B evidence rather than blind build, **which memory/knowledge-retrieval integrations earn a place in the harness flow** — wiring the *real* retrieval engines (the knowledge wiki's `knowledge.db` FTS5/vector index; MCP memory's `memory_search`) into planning, vs the status quo (always-loaded markdown + naive `index.md` frontmatter scoring + write-mostly MCP memory). Experiment-first: this phase validates directions and pre-registers decisions; the build of the winners is deferred to Phase 62. The deterministic step-numbering cleanup (whole numbers across dev-plan/dev-debrief/spec) rides along, walled off from the A/B.

## Context

Two diagnoses (this session, evidence-grounded) motivate the phase:

1. **Wiki-retrieval regression — root cause found.** `agentic-engineering-wiki` (1002 files) and `agent-memory-wiki` (2007 files) ARE registered in `~/.claude/wikis.json`, indexed (`knowledge.db`), and on-topic — yet dev-plan never surfaces them. Cause: they are **raw web scrapes** (`raw/` + a `knowledge.db`; ~0 absorbed `articles/`, stale `index.md`), and dev-plan Step 2 retrieves by reading `index.md` + scoring **article frontmatter tags/hierarchy** — it never queries the `knowledge.db` search index. Raw scrapes have no frontmatter → score 0 → "0 relevant articles." The retrieval path diverged from how the wikis are actually stored.

2. **MCP memory is write-mostly.** 20 active entries, all auto-written by the dev-plan bridge + dev-debrief harvest, but the only automatic read is `wiki-query` (rare) + the bridge's own dedup. session-start *nudges*, never `memory_search`es. Working-knowledge.md (always-loaded) is the layer doing the real work, but its `uses` counter tracks re-seeding, not reads — so what's load-bearing is unmeasured.

The unifying insight: **both subsystems own a real retrieval engine the flow doesn't use.** "Make memory integrated" = wire those engines into the flow. But this is NOT a foregone win: **Phase 59 measured retrieval injection to be net-negative** when the model's parametric knowledge is strong (commodity, well-documented topics). The candidate wikis are raw scrapes of commodity web content (LinkedIn/Medium/GitHub, plus visible junk) — exactly that profile. Phase 59 explicitly left UNTESTED the case of genuinely weak-parametric / proprietary knowledge (retrieval's theoretical sweet spot). This phase tests precisely that boundary — so the experiment must be able to show lift *if it exists* (weak-parametric + wiki-covered test topics) and must lead with a falsification so a Phase-59-redux null kills it cheap.

Methodology is held fixed to the Phase 58–59 protocol (reuse, do not re-derive): clean-context A/B generation, blind third judge (decision_quality + reasoning_quality, 1–5), within-round paired deltas only, ≥3 runs/condition escalating to 5 on variance, pre-registration ordered before results, **burden of proof on the feature** (keep requires affirmative lift), cost ledger, and the known judge facts (inter-run mean 2.97–4.85; filler discarded, Phase 50).

## Scope

### In scope
- A **wiki signal-quality gate**: sample the candidate wikis (agentic-engineering, agent-memory, cognitive-patterns), score retrieval-worthiness (substantive/primary vs scrape/SEO/junk), and identify ≥2 test topics where the model is *genuinely weak* AND a wiki covers it well. If none exists, the retrieval arm is unfalsifiable-as-beneficial here → record Phase-59-redux and stop the retrieval arm (the architecture/2-tier and step-renumber work still proceed).
- A written **pre-registration block** (in the results artifact, ordered before results), pinning BEFORE any run: the signal-quality scoring rubric + the "covers it well" cutoff (recorded before sampling); the weak-parametric topic criterion; conditions; per-direction decision rules incl. the **numeric Stage-0 kill rule** (cut if `mean(B)−mean(A) ≤ spread`); variance + cost gates; the **firewall length-matched-control trigger** (run it before any firewall keep); and the context-poisoning measure (non-target-quality regression).
- **Staged A/B** over the 5 directions, factored into 3 axes + 1 conclusion:
  - WHAT to retrieve: wiki-search (D1) · MCP memory (D2) · baseline (always-loaded markdown only)
  - HOW to inject: raw-into-context vs **retrieval-subagent firewall** (D5 — subagent queries + distills, returns only the relevant slice)
  - PREP (wiki): search raw `knowledge.db` vs absorbed articles (D4)
  - CONCLUSION: 2-tier vs 3-tier (D3), derived from whether the memory read-path earns lift
  - Stage 0 = signal gate + single best-case falsification; Stage 1 = source×mechanism (only if Stage 0 shows lift); Stage 2 = architecture + prep conclusions.
- A **per-direction keep/cut decision** applying the pre-registered rules mechanically to quoted numbers. Winners are recorded as Phase-62 build candidates.
- **Deterministic step-renumber** (no A/B): renumber dev-plan/dev-debrief/spec SKILL.md steps to whole numbers, update every cross-reference (companions, hooks, memory, dev-wiki), add a numbering-continuity test.
- Regression gate: `make test` green + `make eval` 100%.

### Out of scope
- **Implementing the winning integrations** (Phase 62 — this phase only validates + decides).
- Re-absorbing / curating the raw wikis at scale (D4 tests whether absorption is worth it on a sample; full absorption is downstream).
- Changing the MCP memory server internals (`memory_server/*.py`) — integration is at the harness/skill layer.
- Cutting MCP memory (explicitly rejected by the user — keep the good parts; the question is how to integrate, and whether 2-tier or 3-tier).

## Approach

Reuse the Phase 58–59 A/B harness. Run as a Workflow fan-out ([[measurement-fan-out-as-workflow]]) if the user opts in; otherwise serial subagents. Stages gate on cheap falsification:

1. **T1 — pre-flight + signal gate + pre-registration.** Confirm judge/generation prompts reusable. Sample + score the wikis; classify retrieval-worthiness; pick ≥2 weak-parametric + wiki-covered topics (or declare Phase-59-redux and stop the retrieval arm). Write the pre-registration block ordered first. CHECKPOINT before any A/B.
2. **T2 — Stage 0 falsification.** Best-case condition (wiki-search via subagent-firewall, weak-parametric topic) vs baseline, ≥3 runs, blind judge. The numeric kill rule is PINNED in the pre-registration before the run (not chosen after seeing scores): cut the retrieval thesis if `mean(B) − mean(A) ≤ within-condition spread` (i.e. lift inside the noise band) — same Δ≥0.5-meaningful / variance<0.5 bar as Phase 58-59, escalate to 5 runs if spread > |delta|. CHECKPOINT: report the delta/spread; no lift in the best case → cut, skip Stages 1–2, proceed to step-renumber + write-up.
3. **T3 — Stage 1 source×mechanism** (only if T2 shows lift): wiki-source + memory-source × raw vs subagent-firewall, vs baseline; ≥3 runs/condition + variance gate + cost ledger + context-poisoning measure.
4. **T4 — Stage 2 conclusions** (conditional): 2-tier/3-tier from D2; absorb-vs-search-raw from the wiki arm.
5. **T5 — aggregate + per-direction decision** against pre-registered rules; record P62 build candidates.
6. **T6 — deterministic step-renumber** (runs regardless of A/B outcome).
7. **T7 — regression gate.**

## Constraints (CRITICAL)

- **Testing a foregone conclusion (Phase-59-redux unrecognized).** If the wikis are commodity scrapes the model already knows, the A/B can't show lift and a null is uninformative. Guard: the signal gate runs FIRST; topics must be verified weak-parametric (model demonstrably struggles without retrieval) AND wiki-covered. If no such topic exists, declare it and stop the retrieval arm — do not run an A/B that cannot show lift and then read the null as "retrieval useless."
- **Burden of proof on the feature.** Every integration ships only on affirmative lift past the variance gate; absence of disproof is not "keep." The decision quotes the mean/spread it is keyed to.
- **Judge noise mistaken for signal.** ≥3 runs/condition, within-round paired deltas only (never pool cross-round absolute scores), escalate to 5 on spread > |delta|; spread > |delta| ⇒ indistinguishable-from-zero ⇒ cut that direction.
- **Context poisoning unmeasured.** The whole point of D5 (firewall) is to avoid raw retrieval polluting context. Guard: measure non-target-quality regression on the raw-injection arm (Phase 46 dilution signal); a direction that lifts the target but regresses non-target nets out.
- **Cost never entered.** Net quality delta against per-fire cost (retrieval tool-calls, latency, injected/subagent tokens). A true +0 with cost is net-negative. The subagent-firewall's extra round-trip is a cost term.
- **p-hacking via topic/condition selection.** Pre-register topics, conditions, and decision rules in the artifact before any result; no post-hoc topic swaps without logging the discard + reason; conditions added after results are exploratory and excluded from the primary decision.
- **Subagent-firewall confound (PRE-REGISTERED control, not advisory).** If the firewall arm wins, the lift could be distillation (less noise) OR merely shorter context. Guard (mirrors Phase 59's pre-committed length-matched control, not post-hoc discretion): the pre-registration commits that IF the firewall arm becomes the basis for a "keep/adopt firewall" decision, a length-matched raw control — raw retrieved context truncated/padded to the firewall arm's injected-token count — is RUN before crediting distillation, and "firewall > raw" is asserted only as `firewall − baseline > length-matched-raw − baseline`. Record injected-token counts per arm. No firewall keep verdict without this control having run.
- **Step-renumber breaks references.** The renumber is wide (companions, hooks, memory, dev-wiki cross-refs cite `Step N.x`). Guard: grep every `Step \d` reference across the kit, update all, add a numbering-continuity test; `make test` + `make eval` stay green.
- **Scope creep into building.** This phase decides; it does not implement the integrations. Guard: T3/T4 produce measurements + a decision, not wired-in features. The only code changes are the experiment harness + the (independent) step-renumber.

## Success Vision

The keep/cut question for each integration direction is answered with evidence a skeptic accepts: a recorded wiki signal-quality assessment, weak-parametric + covered test topics, ≥3 runs/condition with within-round paired deltas and a variance gate, a cost ledger, a context-poisoning measure, and a verdict that follows mechanically from a pre-registered rule. The retrieval-subagent firewall is tested as a first-class mechanism, not assumed. Whatever the outcome — wire wiki-search in, adopt the firewall, collapse to 2-tier, or "retrieval doesn't earn it, curate instead" — the artifact reads as honest measurement willing to kill directions, and it leaves a clean Phase-62 build list. Separately, the harness steps read as whole numbers with every cross-reference intact and the suite green.

## Exit Criteria (machine-checkable)

`R=eval/memory-integration/results.md`; `P61()` = `awk '/^##[^#]*Phase 61/{f=1} f' "$R"` (most checks scoped to the Phase-61 section).
- [ ] `grep -qE '^##[^#]*Phase 61' eval/memory-integration/results.md` — results artifact exists
- [ ] pre-registration precedes results: first `pre-?regist` line number < first `delta ?= ?[+-]?[0-9]` line number
- [ ] `P61 | grep -qiE 'signal|retrieval-worth|scrape|noise|primary'` — wiki signal-quality gate recorded
- [ ] `P61 | grep -qiE 'weak.?parametric|baseline.?weak|model.?weak'` — weak-parametric topic selection recorded (or an explicit Phase-59-redux stop)
- [ ] `P61 | grep -qE 'delta ?= ?[+-]?[0-9]'` — at least the Stage-0 falsification delta recorded (more if stages proceed)
- [ ] `P61 | grep -qiE 'firewall|subagent|distill'` — the retrieval-subagent-firewall direction addressed
- [ ] `P61 | grep -qiE 'poison|dilution|non-target|regress'` — context-poisoning measure recorded
- [ ] `P61 | grep -qiE 'cost|tool-?call|token'` — cost ledger recorded
- [ ] per-direction decision is keyed to numbers, not vocabulary: the decision sub-section names both `keep|adopt` AND `cut|drop|defer` AND sits in a section that also contains ≥1 `delta ?= ?[+-]?[0-9]` (decision-words alone cannot satisfy it — the Stage-0 delta gate above is the run-proof and must co-occur)
- [ ] step-renumber, against the EDITED source of truth (`templates/.claude/skills/`, the path `make test` validates — NOT the installed `~/.claude/skills/` copy): `! grep -qE '^#{2,4} Step [0-9]+\.[0-9]' templates/.claude/skills/dev-plan/SKILL.md templates/.claude/skills/dev-debrief/SKILL.md templates/.claude/skills/spec/SKILL.md` (no decimal/postfix steps remain in any of the three)
- [ ] numbering-continuity test asserts the INVARIANT (not a vocabulary match): for each of the three SKILL.md templates, the `## Step N` headings are whole-numbered AND gap-free 1..N (no skips, no decimals, no `a`/`b` postfixes). The test extracts the step numbers and checks the sequence; it fails on a stub. Wired into `make test`.
- [ ] `make test` exits 0; `make eval 2>&1 | grep -qE 'Score: [0-9]+/[0-9]+ \(100%\)'`

## Checkpoints

- After the signal gate + pre-registration (T1), BEFORE any A/B: report wiki signal quality, the chosen weak-parametric+covered topics (or the Phase-59-redux stop), and the pre-registered conditions/rules. Confirm the design can show lift if it exists.
- After Stage 0 (T2): STOP and report the best-case delta + spread + cost. No lift ⇒ cut the retrieval thesis, skip Stages 1–2.
- After each subsequent stage: report per-condition deltas + variance + poisoning + cost before proceeding.
- Before the final per-direction decision (T5): report the aggregate + mechanical rule application; the keep/cut calls + the Phase-62 build list are confirmed at the delivery gate.
- The step-renumber (T6) is independent — verify all cross-refs resolve before marking done.

## Assumptions

- The Phase 58–59 A/B harness (clean-context subagents, blind judge, two dimensions) is reproducible. If false: STOP and report — a non-comparable method invalidates the result.
- A weak-parametric + wiki-covered test topic is findable. If false: the retrieval arm cannot show lift here; declare Phase-59-redux for these wikis and proceed only with the architecture/2-tier question + step-renumber. Do not force a misleading null.
- The wiki `knowledge.db` is queryable for retrieval in a condition (via wiki-query/wiki-index search). If false: the wiki-search arm degrades to a documented limitation; the memory arm + step-renumber still proceed.
- `make test`/`make eval` run clean modulo the known optional-`sqlite-vec` memory path (guarded since Phase 58). A new halt is a regression of this phase.
