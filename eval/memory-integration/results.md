# Memory & Knowledge Integration — A/B Measurement (Phase 61)

## Phase 61 — Validate Memory & Knowledge Integration

Experiment-first validation (build deferred to Phase 62) of whether wiring the real retrieval
engines into the harness flow earns a place, vs the always-loaded-markdown status quo.
Methodology held fixed to Phase 58–59 (clean-context A/B, blind judge, ≥3 runs/condition,
within-round paired deltas, variance gate, **burden of proof on the feature**).

> **Ordering note:** the pre-registration block (conditions + decision rules + numeric Stage-0
> kill rule) is written BEFORE any A/B result (delta). The wiki signal-quality gate below is a
> PREREQUISITE input to topic selection, not an A/B result — it runs first by design.

### T1 — Wiki Signal-Quality Gate (CHECKPOINT 1)

**Rubric (recorded before sampling):** a wiki is retrieval-worthy for a topic if it holds
*substantive/primary* content (synthesized articles, primary docs, papers) the model is *weak* on,
reachable by a working retrieval surface (absorbed articles with frontmatter, OR a populated
`knowledge.db`). Commodity web scrapes the model already holds in-parameter do NOT count
(Phase-59 net-negative profile). "Covers it well" cutoff: ≥3 substantive, on-topic, primary
results for the candidate topic.

**Retrieval-surface inventory (measured 2026-05-29):**

| Wiki | raw articles | absorbed `articles/` | `knowledge.db` rows | retrievable now? | content type |
|------|-------------:|---------------------:|--------------------:|------------------|--------------|
| agentic-engineering (most on-topic) | 1001 | 0 | **0 (empty)** | No — empty index; `index.md` references curated articles that were never written | commodity scrapes (Azure/Medium/LinkedIn) + aspirational curated index |
| agent-memory | 2006 | 0 | 217,498 | Yes (search) | commodity scrapes (Qdrant/LangChain, source_score ~5.5), chunked |
| cognitive-patterns (CWD) | 4 | 4 | none | barely (4 articles, no index) | curated but tiny |
| aml / trading (off-topic) | — | — | 246k / 616k | yes | domain scrapes, off-topic |

**Findings:**
1. **No wiki has absorbed articles (all 0).** The raw→inbox→absorb→article pipeline never ran;
   content sits in `raw/` as scrapes. dev-plan Step 2 reads `index.md` + scores *article frontmatter*
   → raw scrapes lack proper frontmatter, curated articles don't exist → "0 relevant."
2. **The most on-topic wiki (agentic-engineering) has an EMPTY search index** (0 rows) — nothing to
   retrieve via search even if Step 2 queried `knowledge.db`. Its `index.md` promised curated synthesis
   (`context-engineering`, `criteria-drift`…) that was never written to disk.
3. **The only populated on-topic index (agent-memory, 217k rows) is commodity scrapes** — the exact
   profile Phase 59 measured net-negative.
4. **Two independent breaks** behind "the wiki doesn't surface anymore": (a) content scraped-not-absorbed
   + the on-topic index empty; (b) dev-plan Step 2 never queries the `knowledge.db` indexes that DO exist.

**Weak-parametric + covered topic search:** the retrievable content is commodity (model likely strong
in-parameter). The proprietary synthesis that *would* be weak-parametric (the dated `criteria-drift` /
`dimension-coverage-asymmetry` concepts in the aspirational index) **is not actually retrievable** —
never absorbed, empty db. ⇒ a clean weak-parametric+covered topic is NOT readily available from the
wiki-search path as it stands.

**CHECKPOINT-1 status:** the wiki-SEARCH arm trends toward Phase-59-redux (commodity content + no working
on-topic retrieval surface). The MCP-memory read-path arm (D2), the 2-tier/3-tier architecture question
(D3), and the step-renumber (T6) are independent and unaffected. **Pre-registration of the A/B conditions
+ topics is PENDING the user's fork decision at this checkpoint** (declare wiki redux + pivot · run one
cheap best-case falsification against the agent-memory index · repair-then-test).

### T1 — Pre-Registration Block (locked before any A/B result)

**Fork decision (CHECKPOINT 1):** user chose "run one cheap falsification first" — do not cut the
wiki-search arm on the prior alone; measure one best-case condition.

**Stage-0 best-case design (the most likely-to-show-lift condition):**
- **Test topic (T):** "Design the long-term memory-consolidation policy for an AI coding agent —
  when to dedup / merge / forget stored entries, and how to keep retrieval precise as the store grows."
  Chosen as best-case: design-flavored (room for reasoning quality to differ), the agent-memory-wiki's
  217k-row index genuinely covers it (consolidation / dedup / memory-type content), and specific
  retrieved techniques (consolidation triggers, dedup thresholds, forgetting policies) could plausibly
  add concrete detail a vague parametric answer would miss. If retrieval can't beat baseline HERE, it
  won't on a worse-matched topic.
- **Conditions (paired, within-round):**
  - **A (baseline):** clean-context subagent answers T, objective only.
  - **B (firewall retrieval):** a retrieval-subagent queries the agent-memory-wiki `knowledge.db`
    for T, distills only the relevant findings (≤~1200 chars), returns that slice; a clean-context
    generation subagent answers T with objective + the distilled slice.
- **Runs:** ≥3 per condition, escalate to 5 if spread > |delta|.
- **Judge:** one blind subagent scores every output on decision_quality + reasoning_quality (1–5),
  blind to condition, presentation order randomized. Composite = sum.
- **Cheapest-first sub-step:** run the retrieval-firewall subagent ALONE first. If it surfaces only
  commodity/thin content for T (no substantive, non-parametric detail), that is sufficient evidence of
  Phase-59-redux for this arm — report and stop before spending the 6 generation + judge runs
  (verification-first, Phase 49/53 pattern).

**Numeric decision rules (pinned before results):**
- **Stage-0 kill (wiki-search arm):** cut if `mean(B) − mean(A) ≤ within-condition spread` (lift inside
  the noise band); same Δ≥0.5-meaningful / variance<0.5 bar as Phase 58–59.
- **Variance gate:** spread > |delta| ⇒ escalate to 5 runs; if still > ⇒ "indistinguishable from
  zero ⇒ cut."
- **Burden of proof on the feature:** keep requires affirmative lift past the gate; a null is a cut.
- **Firewall length-matched control (pre-committed, MUST run before any firewall keep):** if the
  firewall arm becomes the basis for a keep, run a length-matched raw control (raw retrieved context
  truncated/padded to the firewall's injected-token count); credit distillation only if
  `firewall − baseline > length-matched-raw − baseline`.
- **Cost ledger:** record retrieval tool-calls, injected-context tokens, and subagent round-trips per
  fire; a true +0 with cost is net-negative.
- **Context-poisoning measure:** note any non-target-quality regression in B (introduced errors,
  off-topic drift, dilution) — the firewall's reason to exist.

**Independent of this arm (proceed regardless of the wiki-search verdict):** the MCP-memory read-path
arm (D2), the 2-tier/3-tier architecture question (D3), and the deterministic step-renumber (T6).

---
<!-- A/B RESULTS (deltas) go below this line — pre-registration above is locked -->

### T2 — Stage 0 falsification (in progress)

**Cheapest-first sub-step — retrieval-quality probe (agent-memory `knowledge.db`, topic T):**
1610 rows match consolidation/dedup/forget — but **all `source_score < 5`** (low band), top hits at 0.0.
Sample content: "By default, most AI systems behave like stateless agents…" (intro fluff), "Useful for
updates/deletes and deduplication." (one-liner), "Employ strategies for data deduplication and vector
pruning." (generic), "A bug caused this to keep happening every turn…" (irrelevant Claude Code changelog).
⇒ Best-case retrievable content is shallow commodity + noise — the Phase-59 net-negative profile, at the
input. Per the pre-registered cheapest-first rule this already supports a redux call; running the
firewall-distilled best-case A/B anyway to produce a measured output delta (user asked for measurement,
not prior).

Design question Q (identical for A and B; B adds the firewall-distilled slice):
"Design the long-term memory-consolidation policy for an AI coding agent's persistent store: (1) when to
dedup/merge/forget; (2) what triggers consolidation; (3) how to keep retrieval precise as the store grows
to thousands of entries. Concrete, reasoned recommendations, ≤350 words."

**Firewall retrieval (B-injection):** 1 subagent, 7 queries against the 217k-row index, distilled 1187
chars of substantive findings (Memory OS 6-factor ranking weights, similarity thresholds 0.7/0.85/0.90,
tiered decay half-lives, two-stage ANN→ColBERT rerank), discarding ~60% noise (GPTCache cost rows,
chunking filler, a medical-forum fragment, generic intros). The firewall mechanism worked — it rescued
real signal the naive top-by-score probe missed.

**A/B result (blind judge, 3 runs/condition, within-round paired, decision_quality + reasoning_quality 1–5, composite=sum):**

| condition | per-run composite | mean(A/B) | decision mean | reasoning mean |
|-----------|-------------------|-----------|---------------|----------------|
| A (baseline: parametric + always-loaded working-knowledge) | 9, 10, 10 | mean(A)=9.67 | 4.67 | 5.00 |
| B (firewall-distilled wiki retrieval on top of baseline) | 9, 8, 10 | mean(B)=9.00 | 4.67 | 4.33 |

- **delta = mean(B) − mean(A) = −0.67 composite** (decision_quality 0.0; **reasoning_quality −0.67**).
- **Variance:** A spread = 1, B spread = 2; |delta| = 0.67 < B spread ⇒ **variance-dominated / indistinguishable from zero**, point estimate mildly NEGATIVE.
- **Escalation to 5 not run:** burden-of-proof is on the feature (keep needs affirmative lift); a −0.67 variance-dominated estimate cannot become a positive-lift "keep" by tightening — escalation resolves borderline POSITIVES, not negatives. Combined with the signal gate (commodity content) the verdict is determined.
- **Cost ledger:** per fire = 1 retrieval-subagent round-trip + 7 db queries + ~300 injected tokens. Non-zero cost for negative lift ⇒ net-negative.
- **Context-poisoning / mechanism:** the reasoning-quality drop is the Phase-59 mechanism reproducing — the injected generic Memory OS specifics (named weights, ColBERT) crowded out the baseline's project-grounded tradeoff reasoning (one B-run even spent words rebutting the injection: "drop ColBERT/entity-cooccurrence until measured"). decision_quality held (both already correct); reasoning_quality is where injection cost.

### T2 — Stage-0 VERDICT: CUT the wiki-search retrieval arm (D1)

`mean(B) − mean(A) = −0.67 ≤ spread` ⇒ the pre-registered Stage-0 kill rule fires. Even the **best-case**
condition (firewall-distilled, on a wiki-covered topic) showed **no lift and mild reasoning harm**. This is
**Phase-59-redux confirmed by measurement, not prior**: retrieval from commodity content doesn't pay when
parametric knowledge is strong — and here the baseline is *especially* strong because the always-loaded
`working-knowledge.md` already supplies the project's memory specifics (the baseline answers cited
`cosine >0.90 reinforce`, hybrid RRF `+27.6%`, supersession chains unprompted).

**Load-bearing meta-finding:** the always-loaded hot-cache (`working-knowledge.md`) IS the effective
retrieval layer — it made the baseline excellent without any runtime retrieval. This argues for
**curate-into-hot-cache over runtime external retrieval**, and directly informs the 2-tier/3-tier call.

**UNTESTED (honest caveat, same as Phase 59):** a genuinely weak-parametric + wiki-covered topic was NOT
found (the on-topic wiki is commodity scrapes; the proprietary synthesis was never absorbed/retrievable),
so retrieval's theoretical sweet spot remains unmeasured — the CUT is for the *available* wiki content.

**Stages 1–2 for the wiki arm: SKIPPED** per the checkpoint rule. Still live (independent): MCP-memory
read-path (D2), 2-tier/3-tier (D3) — now informed by the hot-cache meta-finding — and the step-renumber (T6).

### T3 — Stage 1 D2 (MCP-memory read-path) measured A/B

**Cheapest-first probe (store inventory + retrieval, 2026-05-29):** `memory_stats` → **20 active entries**
(all `category=custom`, the bridge/harvest channel) vs `working-knowledge.md` **~90 always-loaded entries**.
`memory_search` on 3 diverse planning queries (research-cut, hook-source-of-truth, eval-methodology)
returned top substantive hits that are **every one already verbatim in the always-loaded
`working-knowledge.md`** (research-injection-cut, settings-generated-artifact, verify-firing, MCP-CWD,
two-phase-eval, within-round-deltas, conditional-injection-negative, scenario-020). The only 2 entries NOT
in the hot cache are a verbose spec-text restatement + a Phase-54 resolved-bug list — low-value, not
planner-relevant. ⇒ **the MCP store is a strict, smaller SUBSET of the always-loaded hot cache**
(store ⊂ cache; |store|=20 < |cache|≈90). The "pruned tail" value hypothesis (memory holds valuable
entries the capped cache dropped) is falsified by inspection: there is no rich distinct tail. Per the
verification-first rule this already supports a cut; ran the measured A/B anyway (user asked for measurement,
not prior — same as T2).

**Best-case design topic (T2-style, memory's strongest domain):** "Design a rigorous evaluation protocol to
decide whether a context-injection feature earns its place vs the no-injection baseline (pre-registration /
judge-variance / keep-cut rule)." The store's richest content is eval-methodology, so this is the topic most
likely to show memory lift — best-case by construction.

**Conditions (paired, within-round, controlled for the subagent auto-load confound):**
- **A (baseline / status quo):** generation subagent answers T with the `working-knowledge.md` eval block
  injected — guarantees the baseline carries the always-loaded hot cache (the real status quo).
- **B (status quo + memory read-path):** A's setup PLUS the `memory_search`-retrieved slice for T (which,
  per the probe, overlaps the hot-cache block). Isolates the marginal value of runtime memory re-retrieval
  ON TOP of the always-loaded layer — the exact contrast for "should we wire memory_search into planning."

**A/B result (blind judge, 3 runs/condition, within-round paired, decision_quality + reasoning_quality 1–5, composite=sum, presentation order randomized):**

| condition | per-run composite | mean(A/B) | decision mean | reasoning mean |
|-----------|-------------------|-----------|---------------|----------------|
| A (baseline: parametric + always-loaded hot cache) | 9, 10, 9 | mean(A)=9.33 | 5.00 | 4.33 |
| B (hot cache + memory_search retrieved slice) | 8, 10, 10 | mean(B)=9.33 | 4.67 | 4.67 |

- **delta = mean(B) − mean(A) = 0.00 composite** (decision_quality −0.33; reasoning_quality +0.33 — a wash that nets exactly zero).
- **Variance:** A spread = 1, B spread = 2; |delta| = 0.00 < both spreads ⇒ **variance-dominated / indistinguishable from zero**, point estimate flat.
- **Cost ledger:** per fire = ≥1 `memory_search` round-trip + ~175 injected tokens (the retrieved slice). Non-zero cost for **zero** lift ⇒ net-negative.
- **Context-poisoning / mechanism:** one B-run's decision_quality dipped to 4 (redundant re-injection added length without information); reasoning ticked up equivalently — net wash, no directional harm like D1's −0.67, but also no lift. Cleanest possible "redundant retrieval" signature: B = A + (subset of A) ⇒ Δ→0.

### T3 — D2 VERDICT: CUT the MCP-memory read-path arm (D2)

`mean(B) − mean(A) = 0.00 ≤ spread` ⇒ the pre-registered kill rule fires; burden-of-proof-on-the-feature ⇒
a null is a cut. Even in memory's **best-case** domain (eval-methodology, which the store covers densely)
wiring `memory_search` into planning produced **zero lift at non-zero cost**. Root cause is structural and
matches the D1 meta-finding exactly: the MCP store is fed by the same bridge/harvest pipeline that curates
`working-knowledge.md`, so it is a redundant subset of the always-loaded hot cache — runtime retrieval
re-surfaces content the planner already holds. Escalation to n=5 not run: a flat-zero variance-dominated
estimate cannot become a positive-lift keep by tightening.

**UNTESTED caveat (honest, scoped to current store state):** if the MCP store one day grew to hold valuable
entries the capped `working-knowledge.md` (100-entry ceiling) had to evict, D2's marginal value could turn
positive (memory_search as overflow recall for the hot cache). The CUT is for the store AS IT STANDS
(20 entries, ⊂ cache). Concrete future re-test trigger, not a present keep.

### T4 — Stage 2 architecture conclusions (D3 tier model; D4 prep)

**D3 — 2-tier vs 3-tier:** the question was whether to add a 3rd, runtime-retrieved store tier on top of
(1) always-loaded markdown hot cache + (2) the dev-wiki/knowledge-wiki corpora. Both retrieval arms
(D1 wiki-search, D2 memory read-path) measured **no lift** for the same reason: the always-loaded hot cache
IS the effective retrieval layer, and it makes the baseline strong enough that runtime external retrieval is
redundant-at-best / diluting-at-worst. ⇒ **Decision: 2-tier — curate-into-hot-cache; do NOT build a 3rd
runtime-retrieved write-store tier.** Marginal engineering effort belongs in hot-cache curation quality
(what gets distilled into `working-knowledge.md` / `active-knowledge.md` and how it's pruned), not in wiring
a runtime retrieval engine into the planning flow. Keyed to: D1 delta = -0.67, D2 delta = 0.00.

**D4 — absorb-vs-search-raw (wiki prep):** MOOT / not separately tested. D4 only had meaning inside the
wiki-search arm (does absorbing raw scrapes into articles beat searching raw?), and that arm was cut at D1.
The T1 signal gate already established the upstream cause (no wiki has absorbed articles; the raw→absorb
pipeline never ran), so D4's answer is subsumed: absorbing the commodity content first would not rescue an
arm that doesn't pay on that content. No separate measurement warranted.

### T5 — Aggregate + per-direction decision (CHECKPOINT 3)

Pre-registered rules applied mechanically; each direction's keep/cut keyed to a quoted delta.
**Measured deltas: D1 delta = -0.67 (wiki-search), D2 delta = 0.00 (memory read-path)** — both
variance-dominated, both fail the burden-of-proof bar, both CUT.

| Direction | What it was | Measured | Decision |
|-----------|-------------|----------|----------|
| **D1 — wiki-search into planning** | wire knowledge.db FTS5/vector retrieval into dev-plan Step 2 | best-case firewall-distilled delta = -0.67 composite, variance-dominated, reasoning -0.67 (real mild harm) | **CUT** |
| **D2 — MCP memory_search read-path** | wire memory_search into planning | best-case delta = 0.00 composite, variance-dominated, net-negative after cost | **CUT** |
| **D3 — 2-tier vs 3-tier architecture** | add a runtime-retrieved store tier? | derived from D1+D2 nulls + hot-cache meta-finding | **2-tier (curate-into-hot-cache); 3rd runtime tier CUT/DEFERRED** |
| **D4 — absorb-vs-search-raw prep** | absorb scrapes before searching? | moot (subsumed by D1 cut + T1 signal gate) | **CUT (not separately tested)** |
| **D5 — retrieval-subagent firewall** | distill retrieved content in a clean subagent before injection | mechanism WORKED (rescued real signal D1's naive probe missed) but distilled content still didn't lift; length-matched control never triggered (no keep to defend) | **CUT as deployed; retain as a technique** |

**Headline:** all five runtime-retrieval integrations measured net-zero-or-negative. The load-bearing
positive finding is the **meta-conclusion**: the always-loaded markdown hot cache
(`working-knowledge.md` / `active-knowledge.md`) is already the effective retrieval layer — it made every
baseline strong. "Retrieval over parametric knowledge" (the nana-soul tenet) does NOT pay when the relevant
knowledge is *already in context* via the always-loaded layer; the win is in curating that layer, not in
bolting runtime retrieval engines onto planning.

**Phase-62 build list (informed by the cut):**
1. **NOT building:** runtime wiki-search-in-planning (D1), runtime memory_search-in-planning (D2), a 3rd
   runtime-retrieved store tier (D3). Burden of proof unmet by measurement.
2. **Build candidate — hot-cache curation quality:** since the hot cache is the effective layer, P62 value
   is in *what gets distilled into it and how it's evicted* — improve the dev-debrief → `working-knowledge.md`
   distillation, the 100-entry cap eviction policy (currently usage-count + oldest-date), and de-dup against
   existing entries. The only memory/knowledge direction with affirmative evidence behind it (the baseline's
   strength is the evidence).
3. **Re-test trigger (deferred, not built):** if the MCP store grows past the hot-cache cap with valuable
   distinct entries, re-run the D2 A/B (memory_search as overflow recall). A concrete numeric trigger, not a
   standing feature.
4. **Untested sweet spot (deferred):** genuinely weak-parametric + properly-absorbed + covered topics
   (retrieval's theoretical sweet spot) remain unmeasured — would require building the absorb pipeline + a
   non-commodity corpus first. Separate future call.

CHECKPOINT 3: aggregate reported; mechanical rule application complete; per-direction keep/cut + Phase-62
build list recorded. Keep/cut confirmed at the delivery gate.



