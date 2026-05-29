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



