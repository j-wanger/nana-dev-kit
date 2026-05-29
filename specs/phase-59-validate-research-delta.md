<!-- nana:approved 2026-05-28 -->
# Spec: Validate Active-Research Residual Delta (Phase 59)

## Objective

Turn Phase 58's n=1, threshold-level residual delta into a defensible keep / trim / cut decision: re-run the same with-vs-without measurement on additional wiki-uncovered topics — including at least one deliberately research-POOR-but-gate-firing topic — at enough runs to clear judge noise, and resolve, against a pre-registered decision rule, whether dev-plan's Step 2.7 active domain research earns its standing complexity.

## Context

Phase 58 shipped Step 2.7 (gap-gated active domain research in dev-plan) and measured its value exactly once: +0.5 composite (reasoning_quality 3→4, decision_quality 4→4), n=1, single judge, single run, on a deliberately research-FAVORABLE topic ("structured outputs"). `eval/research-measurement/results.md` records the honest standing claim — "promising on research-rich gaps, likely ~0 on research-poor ones" — and flags +0.5 as sitting AT the project's own significance bar (Δ≥0.5 meaningful, variance<0.5) with unknown variance. Checkpoint 2 (keep/trim/cut) was deferred to the user, who has now chosen to strengthen the evidence before deciding. Phase 58's abort rule carries in: if research never changes the approach, present honestly and let the user decide — do not silently ship a feature that earns nothing. This phase is that reckoning.

The measurement (held fixed for comparability): for a software-engineering phase objective the wiki does NOT cover, two clean-context subagents independently generate a design approach — baseline **A** (objective only) vs research-injected **B** (objective + ≤2 distilled web findings). A third blind judge scores both on decision_quality and reasoning_quality (1–5 each). The within-topic, within-round delta (B−A) is the unit of interest.

Known measurement-environment facts (from project memory; must be respected, not re-derived):
- The LLM judge has high inter-run variance: mean has ranged 2.97–4.85 across identical-condition runs. A single A-run vs single B-run yields a delta whose noise band exceeds the +0.5 effect being claimed.
- Within-round paired comparisons are valid; cross-round absolute scores diverge (fresh-runs methodology) and must not be pooled.
- The judge actively discards irrelevant filler text (Phase 50) — length alone does not inflate scores.
- This is an LLM-executed measurement with no binary eval runner: the measurement artifact IS the functional test.

## Scope

### In scope
- ≥3 NEW held-out measurement topics, all wiki-UNCOVERED so the Step 2.7 gate fires research, spanning the web-richness axis and domain-diverse: ≥2 research-RICH (distinct domains, not the same family as Phase 58's "structured outputs") + ≥1 research-POOR-but-gate-firing.
- ≥3 runs per condition (A and B) per topic; per-topic delta = mean(B) − mean(A), with within-topic spread reported. Each topic's result line records the literal tokens `mean(A)=`, `mean(B)=`, and `delta=` followed by a number, so the gates can count topics that actually ran (not just vocabulary).
- A written **pre-registration block** committed to the artifact BEFORE any approach is generated: exact topics, each topic's web-richness classification + falsifiable rationale, runs-per-condition, and the full keep/trim/cut decision rule including aggregation and veto/variance gates.
- Reuse of the Phase 58 methodology verbatim (clean-context A/B subagents, blind third judge, two dimensions, same calibration); A and B paired within the same round, judged blind, presentation order randomized; the ONLY difference between A and B is the ≤2 injected findings.
- Per topic: evidence the gate actually FIRED (search/fetch counts > 0) and the ACTUAL retrieval quality (count of substantive/primary sources vs SEO/listicle/snippet-only), so "research-poor" is auditable, not asserted. Raw query results captured.
- Per topic: whether the injected findings were load-bearing in B's approach (cited at a named decision) vs decorative — distinguishing real lift from finding-presence reward.
- Aggregate: per-topic deltas, mean across topics, cross-topic and within-topic spread, and the cost side (per-fire tool calls / injected-context tokens).
- A written keep/trim/cut decision applying the pre-registered rule mechanically to the observed numbers, quoting them.
- IF the decision is TRIM or CUT: the minimal corresponding change to `templates/.claude/skills/dev-plan/domain-research-spec.md` (and/or its SKILL.md pointer), keeping `tests/test_templates.sh`, `make test`, `make eval`, and the SKILL.md ≤350-line cap green.

### Out of scope
- Changing the measurement methodology (dimensions, judge model, A/B design) — comparability with Phase 58 requires holding it fixed. Documented weaknesses are recorded as caveats, not fixed mid-stream.
- Re-running or re-litigating the Phase 58 topic's result (it stands as a single-run prior data point; the strengthened claim rests on the new ≥3-run topics, not on pooling Phase 58's single run).
- New features or capabilities for Step 2.7 (only trim/cut remediation if the data demands it).
- Building any new measurement harness or eval-runner integration; cross-model judging; a judge re-calibration project (note as future lever if variance dominates).
- Phase 59-adjacent candidates: Fix 3 (AGENTS.md reshape), Fix 5 (session-start nudge), vector-search-default-on.

## Approach

Hold the methodology constant and vary only the topic's web-richness. The within-topic paired delta (B−A) is chosen because it cancels the judge's large baseline variance and topic difficulty — the only statistically valid comparison here is within-round, same-topic, same-judge. Because a single draw is noisier than the effect, take ≥3 runs per condition per topic and reduce to mean(B)−mean(A) with a reported spread; "n≥3" means ≥3 topics each at ≥3 runs/condition, not 3 single-shot deltas. Gather each topic's research findings ONCE (the feature's actual output), then reuse that fixed payload across the B-runs, so the variance measured is generation+judge noise, not retrieval jitter.

Pre-register everything decision-relevant before generating a single approach, so topic selection and thresholds cannot be reverse-engineered to a desired conclusion. The research-POOR topic is the load-bearing test and must be chosen to FIRE research yet return thin/low-quality findings — not so thin that the gate or fail-open SKIPS it (a skip yields B==A=0 by construction and measures the fail-open guard Phase 58 already verified, not the harm question). Its result is read carefully: a negative delta is direct harm; a ≈0 delta is NOT automatically safe — if research fired and injected findings and the delta is ≈0 only because the judge discarded the junk (the Phase 50 effect), that is a TRIM signal (the feature spent cost and the judge, not the gate, averted harm; production has no such judge), distinct from a ≈0 that arises because the gate/distillation correctly produced nothing to inject.

The decision rule places the burden of proof on the feature: KEEP requires affirmative evidence, not absence of disproof. The cost side of the ledger is entered explicitly (the subtraction test applied to the measurement itself), so "harmless ~0 but resources spent" is recognized as net-negative rather than a free pass. A null or negative residual is an acceptable, even valuable, outcome that triggers trim/cut.

### Domain Research Questions
1. Given the judge's documented inter-run variance (mean 2.97–4.85), how many runs per condition make a per-topic delta trustworthy, and does the within-round paired design adequately cancel that variance — or must variance be bound as a hard decision gate (spread > effect ⇒ inconclusive ⇒ trim/cut)?
2. How is a topic verifiably classified "research-POOR-but-gate-firing" BEFORE measurement (a falsifiable, pre-stated coverage protocol — e.g., top-K results are SEO/listicle/vendor-marketing with no primary source, yet coverage is enough to fire rather than fail-open), and how is the actual retrieval inspected afterward to confirm the classification held?
3. Is research-injected B confounded by being longer than baseline A? Does Phase 50's "filler is discarded" finding fully neutralize a length-bias concern, or does the linchpin research-rich topic warrant a length-matched-but-irrelevant control to isolate substance from verbosity?

## Constraints (CRITICAL)

- **P-hacking via topic selection** — choosing topics until the aggregate clears "keep". Guard: pre-register the exact topic list, each topic's richness classification, and the decision rule in the artifact BEFORE any approach is generated; the artifact must show pre-registration ordered before results. No topic swaps after seeing any score; a forced swap logs the replacement, the reason, and the discarded topic's partial data — never a silent drop. Topics added after results are disclosed as exploratory and excluded from the primary n.
- **Self-serving "keep" by default** — the feature ships unless proven worthless. Guard: KEEP requires affirmative satisfaction of every gate below; absence of disproof is not keep. The written decision applies the rule mechanically and quotes the observed mean/spread it is keyed to.
- **Judge noise mistaken for signal** — a single noisy draw decides the call. Guard: ≥3 runs per condition per topic; within-round paired deltas only (never pool cross-round absolute scores); report within-topic spread. Variance is a decision GATE: if within-topic or cross-topic spread exceeds the |delta| claimed, the verdict is "indistinguishable from zero ⇒ trim/cut", regardless of a positive point estimate.
- **Poor-topic VETO** — a favorable topic washing out a harmful poor topic via averaging. Guard: the research-poor topic delta is a veto, not an average term — a negative poor-topic delta forces TRIM/CUT even if rich topics win.
- **Poor topic SKIPS instead of firing** — fail-open makes B==A=0, measuring nothing. Guard: confirm and record search/fetch counts > 0 on the poor topic (research actually fired); if it skips, force-fire or swap to a thin-but-fireable topic before scoring. Distinguish "fired-but-thin" (tests harm) from "skipped" (tests fail-open, out of scope here).
- **~0 on poor topic read as safe when the judge did the filtering** — the Phase 50 discard effect masks spent cost. Guard: if research fired + injected on the poor topic and delta ≈ 0, classify the source of the zero — gate/distillation produced nothing to inject (keep-compatible) vs judge discarded injected junk (TRIM signal: harden the upstream finding-quality gate). Record which.
- **"Research-poor" asserted, not verified** — an assumed-thin topic is actually web-rich, invalidating the load-bearing test. Guard: record actual retrieval (substantive/primary sources vs SEO/snippet counts) and capture raw query results; if the "poor" topic surfaced rich sources, the classification failed — relabel/swap, do not proceed on a false premise.
- **Length / finding-presence confound** — B scores higher for being longer or for merely containing findings. Guard: rely on Phase 50's "filler discarded" as baseline defense; record whether each injected finding was load-bearing (cited at a named decision) vs decorative; on the linchpin rich topic, note whether the lift plausibly survives a length-matched-irrelevant control (run it if that topic is the basis for "keep").
- **Cost side never entered** — "harmless ~0" silently means keep. Guard: the decision nets quality delta against per-fire cost (tool calls, latency, injected-context tokens). A true +0 on a fired topic is net-negative (resources spent, nothing gained); the gate keeping COVERED topics free does not excuse cost on uncovered fires.
- **Trim/cut remediation breaks the shipped feature** — editing the companion silently breaks the cap test or eval. Guard: if remediation is triggered, `tests/test_templates.sh` + `make test` + `make eval` stay green and SKILL.md ≤350 lines preserved.

## Success Vision

The keep/trim/cut question is answered with evidence a skeptic would accept: ≥3 domain-diverse topics on the web-richness axis, each with a verified-fired gate, recorded retrieval quality, and ≥3 runs per condition; deltas computed the only valid way (within-round paired, mean±spread); variance bound as a gate; cost entered into the ledger; and a verdict that follows mechanically from a rule fixed in advance. The research-poor topic does its job — it tells us whether firing research on a thin gap is harmless, cost-without-value, or harmful — and the source of any near-zero is diagnosed, not assumed. Whatever the outcome (keep, trim, or cut), the artifact reads as honest measurement willing to kill the feature, not a feature looking for justification.

## Exit Criteria (machine-checkable)

These gates verify the experiment was **run**, not merely described — most content checks are scoped to the Phase-59 section so pre-existing Phase-58 prose cannot pre-satisfy them, and topic count is proven numerically. `R=eval/research-measurement/results.md`; `P59()` extracts the Phase-59 section: `awk '/^##[^#]*Phase 59/{f=1} f' "$R"`.

- [ ] `grep -qE '^##[^#]*Phase 59' eval/research-measurement/results.md` — Phase-59 section exists
- [ ] `grep -qi 'Phase 58' eval/research-measurement/results.md` — Phase-58 section preserved (artifact appended, not overwritten)
- [ ] `[ $(awk '/^##[^#]*Phase 59/{f=1} f' eval/research-measurement/results.md | grep -cE 'delta ?= ?[+-]?[0-9]') -ge 3 ]` — ≥3 per-topic numeric deltas inside the Phase-59 section (proves ≥3 topics ran; defeats "wrote one paragraph with the right nouns")
- [ ] `[ $(awk '/^##[^#]*Phase 59/{f=1} f' eval/research-measurement/results.md | grep -cE 'mean\(B\) ?=') -ge 3 ] && [ $(awk '/^##[^#]*Phase 59/{f=1} f' eval/research-measurement/results.md | grep -cE 'mean\(A\) ?=') -ge 3 ]` — per-topic A/B means reported (aggregation over runs), one per topic
- [ ] pre-registration precedes results (p-hacking ordering gate): `preg=$(grep -nEi 'pre-?regist' eval/research-measurement/results.md | head -1 | cut -d: -f1); res=$(grep -nE 'delta ?= ?[+-]?[0-9]' eval/research-measurement/results.md | head -1 | cut -d: -f1); [ -n "$preg" ] && [ -n "$res" ] && [ "$preg" -lt "$res" ]`
- [ ] `awk '/^##[^#]*Phase 59/{f=1} f' eval/research-measurement/results.md | grep -qi 'keep' && awk '/^##[^#]*Phase 59/{f=1} f' eval/research-measurement/results.md | grep -qiE 'trim|cut'` — decision rule + verdict name keep AND trim/cut, in-section
- [ ] `awk '/^##[^#]*Phase 59/{f=1} f' eval/research-measurement/results.md | grep -qiE 'research-poor|poor topic|poor-but|web-thin' && awk '/^##[^#]*Phase 59/{f=1} f' eval/research-measurement/results.md | grep -qiE 'research-rich|web-rich|rich topic'` — both richness classes present, in-section
- [ ] `awk '/^##[^#]*Phase 59/{f=1} f' eval/research-measurement/results.md | grep -qiE '(search|fetch)e?s?[^0-9]{0,8}[0-9]'` — gate-fired evidence (numeric search/fetch counts), in-section
- [ ] `awk '/^##[^#]*Phase 59/{f=1} f' eval/research-measurement/results.md | grep -qiE 'source|snippet|SEO|primary|retriev'` — poor-topic retrieval quality recorded, in-section
- [ ] `awk '/^##[^#]*Phase 59/{f=1} f' eval/research-measurement/results.md | grep -qiE 'load-bearing|cited|decorative'` — findings load-bearing-vs-decorative recorded, in-section
- [ ] `make test` exits 0 (regression gate)
- [ ] `make eval 2>&1 | grep -qE 'Score: [0-9]+/[0-9]+ \(100%\)'` — eval regression gate (anchored so a partial pass like 54/55 cannot false-positive)
- [ ] If (and only if) the decision is trim/cut: `bash tests/test_templates.sh` exits 0 and `[ $(wc -l < templates/.claude/skills/dev-plan/SKILL.md) -le 350 ]`

## Checkpoints

- After the pre-registration block (topics + falsifiable richness rationale + runs/condition + full decision rule incl. veto + variance + cost gates) is written, BEFORE generating any approach: report the design and confirm it answers DRQ 1–3 and is not reverse-engineered to a conclusion.
- After the research-poor topic runs: STOP and report its per-run scores, mean delta, spread, gate-fired evidence (search/fetch counts), actual retrieval quality, and the diagnosed source of any near-zero. This is the load-bearing result; if its spread > |delta|, decide repeats vs swap before continuing.
- If the emerging verdict leans KEEP and rests on a research-rich topic's lift: run the length-matched-irrelevant control on that linchpin topic BEFORE finalizing — do not finalize a KEEP-on-rich verdict without it (closes the length/finding-presence confound on the one path where it decides the outcome).
- After all topics run, BEFORE writing the final decision: report the aggregate (per-topic deltas, mean, cross-topic spread, cost ledger) and the mechanical application of the decision rule. The keep/trim/cut call is the user's to confirm at the delivery gate.
- If a "research-poor" topic turns out web-rich, or a topic is silently wiki-covered, or the poor topic SKIPS research: note the deviation, swap/relabel/force-fire as the rule prescribes, and do not proceed on the false premise.

## Assumptions

- The Phase 58 methodology (clean-context A/B subagents, blind judge, two dimensions) is reproducible this round. If false (judge/subagent unavailable): STOP and report — a non-comparable methodology invalidates the strengthening; do not substitute a different design silently.
- `WebSearch`/`WebFetch` are available so research can actually fire on uncovered topics. If false: fail-open is NOT acceptable here (the whole phase measures the fire path) — STOP and report that the environment cannot exercise the feature.
- At least one genuinely research-POOR-but-gate-firing, wiki-uncovered topic is findable and verifiable as thin. If false (cannot confirm a thin-but-firing topic): label the poor-topic conclusion as weaker/exploratory and do not assert a verified harmless/harmful call.
- The within-round paired delta adequately controls the judge's baseline variance. If false (within-topic spread swamps the delta): escalate to more repeats; if still indeterminate, report "variance-dominated, inconclusive ⇒ trim/cut" rather than forcing a positive call.
- n=3 topics × ≥3 runs/condition is sufficient for a directional (not publication-grade) decision appropriate to a single dev-kit feature. If false (user wants higher confidence): report the n reached and offer to extend; do not overclaim statistical significance.
