<!-- nana:approved 2026-05-27 -->
# Spec: Eval Advancement — Cross-Model Judging, Harder Scenarios & Length-Sensitivity

## Objective

Three sequential experiments to advance reasoning eval capability: (1) length-sensitivity test to isolate whether prompt length vs content drives interference, (2) cross-model judging to break self-grading bias, (3) harder scenarios to increase differentiation power beyond 4/20 below ceiling.

## Context

Phases 44-49 built a reasoning eval: 20 scenarios, 3 dimensions (decision/reasoning/antipattern, 1-5), judge v2 with exemplar anchoring, 3-run protocol (delta >= 0.5, variance < 0.5). Current state: 16/20 at ceiling (5/5/5), self-grading bias acknowledged (same model family generates + judges), 19.4% below ceiling (meets >15% target). Phase 49 found conditional injection (type-based gating) provides zero delta. Phase 46 found context dilution (scenario 012 regressed when injection payload grew ~400 tokens). The length-sensitivity hypothesis: prompt length, not heuristic content, drives interference.

Cross-model judging uses Claude Code's Agent `model` parameter — dispatch judge subagent as Sonnet while agent runs on Opus. No external API keys needed. Requires storing raw agent responses (currently only scores in results.json).

## Scope

### In scope
- Length-sensitivity experiment: inject length-matched coherent unrelated text, compare to IRON RULES injection and no injection
- Cross-model judging infrastructure: response storage in results schema, separate judge pass with different model
- Cross-model calibration comparison: self-judge vs cross-model-judge on same responses
- 5 new harder scenarios with genuine multi-stakeholder ambiguity
- Judge variance check on new scenarios (fixed-response variance test)
- Updated run-eval.py with `--cross-judge` and `--length-test` analysis modes

### Out of scope
- External model APIs (OpenAI, Gemini) — stay within Claude model family
- Production integration of cross-model judging into dev-plan reasoning flow
- Modifying IRON RULES content
- Scenario-type conditional injection (Phase 49 negative result — not revisited)
- Expanding beyond 25 total scenarios

## Approach

Three sequential experiments, each with its own falsification checkpoint. Order: length-sensitivity first (cheapest, highest information value), cross-model judging second (infrastructure), harder scenarios third (uses improved infrastructure).

**Experiment 1 — Length-Sensitivity:** Count actual IRON RULES injection word count (549 words), then create a coherent-but-irrelevant text block matching that length (520-580 words). Run 3-condition eval: no-inject vs IRON RULES vs length-matched-filler on existing 20 scenarios. "Affected scenarios" = scenarios where IRON RULES injection caused delta <= -0.3 on any dimension vs no-inject baseline (pin the list from existing results before running). If filler causes similar interference to IRON RULES (filler delta within 0.3 of IRON RULES delta on >50% of affected scenarios), length is the driver. Use coherent text (e.g., cooking recipe), not gibberish — random tokens cause different attention patterns.

**Experiment 2 — Cross-Model Judging:** Extend results schema to store raw agent responses. Run eval as usual (Opus generates + self-judges), then re-judge the same responses using Agent with `model: "sonnet"`. Compare score distributions. Calibration criterion: cross-model judge must also achieve mean < 4.5 and >=15% below 5 to be considered valid.

**Experiment 3 — Harder Scenarios:** Write 5 new scenarios with genuine ambiguity (multi-stakeholder tradeoffs, no single right answer, expert disagreement plausible). Judge variance check: run judge 3 times on a fixed response per new scenario — reject if any dimension variance > 0.5 (scenario is "judge-hard" not "agent-hard"). Report both original-20 and full-25 metrics to preserve cross-phase comparability.

## Constraints (CRITICAL)

- Pre-commit interpretation thresholds before running length-sensitivity: "affected scenarios" = those where IRON RULES delta <= -0.3 on any dimension vs baseline. "Length is the driver" = filler delta within 0.3 of IRON RULES delta on >50% of affected scenarios. Pin the affected-scenario list from existing results BEFORE running the experiment. Prevents: post-hoc rationalization of ambiguous findings.
- Each experiment uses independent A/B pairs, not crossed comparisons: length-sensitivity uses existing 20 scenarios + existing judge; cross-model uses existing 20 scenarios + new judge; harder scenarios are scored with both judges for validation but primary metrics use the validated judge. Prevents: confounding multiple variables.
- New scenarios go in the same corpus directory but run-eval.py reports both original-20 and full-25 metrics: never silently expand the denominator. All working-knowledge entries citing score thresholds reference original-20. Prevents: breaking cross-phase comparability.
- Cross-model judge must pass calibration criterion (mean < 4.5, >=15% below 5) on the existing 20 scenarios before trusting it for harder scenarios: a lenient cross-model judge cancels the gains from harder scenarios. Prevents: false sense of improved differentiation.
- Use coherent unrelated text for length-sensitivity control, not random tokens: gibberish triggers different model behavior (safety filters, parsing overhead) than irrelevant-but-coherent text. Prevents: confounding length with incoherence.
- Judge variance check required for each new scenario: 3 judge runs on a single fixed response; reject if any dimension variance > 0.5. Prevents: adding scenarios that are "judge-hard" (noisy scoring) rather than "agent-hard" (requires better reasoning).

## Deliverables

1. `eval/reasoning/length-sensitivity/` — filler text, results, analysis
2. Updated results schema (results.json) with `responses` field storing raw agent output
3. `eval/reasoning/judges/cross-model-judge.md` — prompt template for cross-model judging pass (reuses reasoning-judge-v2.md structure with model-parameter instructions)
4. `eval/reasoning/cross-model/results.json` — cross-model judge scores on existing 20 scenarios
5. 5 new scenario files in `eval/reasoning/corpus/` (IDs 021-025)
6. Updated `eval/reasoning/run-eval.py` with `--length-test` and `--cross-judge` analysis modes
7. `eval/reasoning/traces/phase-50-analysis.md` — combined analysis document

## Exit Criteria (machine-checkable)

- [ ] `test -f eval/reasoning/length-sensitivity/results.json`
- [ ] `test -f eval/reasoning/length-sensitivity/filler-text.md && wc -w eval/reasoning/length-sensitivity/filler-text.md | awk '{exit ($1 < 520 || $1 > 580) ? 1 : 0}'`
- [ ] `python3 -c "import json; r=json.load(open('eval/reasoning/cross-model/results.json')); assert 'responses' in r, 'missing responses field'"`
- [ ] `python3 -c "import json; r=json.load(open('eval/reasoning/cross-model/results.json')); assert r.get('judge_model','') != r.get('agent_model',''), 'judge and agent model must differ'"`
- [ ] `[ $(find eval/reasoning/corpus -name '*.json' | wc -l) -ge 25 ]`
- [ ] `python3 eval/reasoning/run-eval.py --help 2>&1 | grep -q 'length-test'`
- [ ] `python3 eval/reasoning/run-eval.py --help 2>&1 | grep -q 'cross-judge'`
- [ ] `test -f eval/reasoning/traces/phase-50-analysis.md`
- [ ] `test -f eval/reasoning/judges/cross-model-judge.md`
- [ ] `make test && make eval`

## Checkpoints

- After length-sensitivity experiment (before cross-model judging): if filler text causes equivalent interference to IRON RULES on >50% of affected scenarios, report finding and discuss implications before proceeding — this changes the interpretation of all prior heuristic content experiments.
- After cross-model calibration comparison: if cross-model judge fails calibration criterion (mean >= 4.5 or <15% below 5), try Haiku as alternative. If both fail calibration: report negative finding, proceed with harder scenarios using self-judge (existing v2).
- After judge variance check on new scenarios: if >2 of 5 new scenarios fail variance check, revise rubrics before running full eval. If still failing after revision: drop those scenarios from the corpus with documented rationale.

## Assumptions

- Claude Code Agent `model` parameter enables cross-model judging without API key changes. If false: scope cross-model to API-based judging script using Anthropic Python SDK (requires API key in environment).
- 5 new scenarios are sufficient to meaningfully reduce the ceiling effect. If false: the phase produces the infrastructure (cross-model judging, response storage) as the durable value, and scenario expansion continues in a follow-up phase.
- The length-sensitivity experiment is separable from content effects. If false: the filler text itself may influence reasoning in scenario-specific ways. Mitigation: use domain-irrelevant text (cooking/gardening) that has zero topical overlap with software engineering scenarios.
- Sonnet as cross-model judge produces meaningfully different calibration from Opus self-judge. If false: try Haiku; if all Claude models correlate too strongly, cross-model judging requires a non-Claude model (out of scope for this phase).
