<!-- nana:approved 2026-05-27 -->
# Spec: Prompt-Type Hooks — Heuristic-Informed Runtime Judging

## Objective

Build trigger-based heuristic matching and a heuristic-informed approach judge that fires during dev-plan Step 6.5, evaluating reasoning quality against relevant heuristics' criteria. Wire the infrastructure so future phases can add heuristic evolution scoring.

## Context

The nana-dev-kit heuristic learning system (Phases 44-50) has 15 heuristic articles (10 HEU + 5 IRON) with structured triggers, Always/Never clauses, and anti-pattern tables in `wiki/heuristics/`. A reasoning eval with 25 scenarios and exemplar-anchored judge (v2) exists at `eval/reasoning/`. The dev-plan skill has existing quality gates: T0 thinking protocol (Step 6), approach reviewer subagent (Step 6.5), plan reviewer subagent (Step 7.5). Three prior negative results constrain the design:

- Phase 47: Self-dialogue (same-context critique) is net negative/neutral — judge output must not be re-injected into planning context
- Phase 46: Context dilution at ~400 tokens — heuristic injection must be capped
- Phase 49: Type-based conditional injection shows zero delta — trigger-based matching (more granular) is the remaining hypothesis

The cognitive enhancement roadmap Phase 6 specifies "Prompt-type hooks (LLM-as-judge during execution)." Phase 7 (heuristic evolution with helpful/harmful scoring) follows.

## Scope

### In scope
- Heuristic trigger matcher: LLM-based subagent that selects relevant heuristics given a phase objective/scope
- Plan-adapted judge prompt: modified from judge v2 with plan-specific exemplars (approach prose, not scenario responses)
- Dev-plan Step 6.5 enhancement: approach reviewer receives matched heuristics' Always/Never/Anti-pattern content
- Selective injection eval mode: `run-eval.py --selective` mode comparing trigger-matched injection vs blanket injection on 25 scenarios
- Matching accuracy measurement: ground-truth mapping of which heuristics apply to which eval scenarios

### Out of scope
- Helpful/harmful counter updates (Phase 7: heuristic evolution)
- Heuristic deprecation logic (Phase 7)
- Judge integration during implementation (task execution)
- Blocking (hard-gate) judge verdicts — all advisory
- External model APIs
- New heuristic creation from runtime findings
- Modifying existing heuristics' content

## Approach

Three components, built sequentially:

1. **Heuristic trigger matcher** (~50-line companion file): Reads all heuristic articles from `wiki/heuristics/`, extracts trigger fields from YAML frontmatter. Given a phase objective and scope, uses an Agent subagent to match triggers against context. Returns a ranked list of matched heuristics with confidence scores. Caps output at top-3 matches (~1200-character budget for combined heuristic content). If 0 matches: skip judge integration entirely. If `wiki/heuristics/` missing or empty: skip silently.

2. **Plan-adapted judge prompt** (~60-line companion file): Modified from `eval/reasoning/judges/reasoning-judge-v2.md`. Key differences: (a) input is an approach description, not a scenario response; (b) "expert answer" replaced by "matched heuristics' Always/Never criteria"; (c) exemplar anchors rewritten for planning artifacts. Outputs a single `Score: N/10` plus `Verdict: accept|revise|reject` (consistent with existing approach reviewer format), with per-dimension justifications. Fire-and-forget: scores logged but NOT re-injected into planning context.

3. **Step 6.5 integration** (~5-line companion pointer in SKILL.md): After existing approach review, if heuristic wiki exists and matcher found ≥1 match, dispatch judge subagent with approach + matched heuristics. Incorporate verdict into Step 6.5 handling (score 6-10: proceed, score 1-5: note concerns in phase article). The planning agent never sees judge critique — only the orchestrator routes on the score.

4. **Selective injection eval** (~30 lines added to `run-eval.py`): New `--selective` mode runs trigger matcher on each scenario's context, injects only matched heuristics into the agent prompt (vs `--compare` which uses all IRON RULES). Produces matching accuracy report against a manually-created ground-truth mapping.

## Constraints (CRITICAL)

- Heuristic injection budget: max ~1200 characters of combined heuristic content per judge invocation (measurable via `len()` or `wc -c`). If top-3 matched heuristics exceed 1200 characters, truncate to Always/Never/Anti-pattern sections only (drop When/Why/Source). Prevents: context dilution (Phase 46 regression at ~400 tokens / ~1600 chars).
- Fire-and-forget architecture: judge scores are logged and used for routing in Step 6.5 verdict handling, but NEVER shown to or injected into the planning agent's context. The planner does not know what the judge said — only the orchestrator routes on the score. Prevents: self-dialogue hedging (Phase 47 negative result).
- Subagent isolation: both the trigger matcher and the judge must run as separate Agent subagents, not inline. The matcher receives only phase objective/scope + heuristic trigger list (no planning context). The judge receives only approach text + matched heuristic content (no planning history). Prevents: context contamination and same-agent-judges-itself ceiling effect.
- Latency budget: total judge overhead (matcher + judge) must complete within 60 seconds combined. If either subagent times out: skip heuristic judging for this invocation and proceed with existing approach reviewer verdict only. Log timeout but do not error. Prevents: breaking smooth stage transitions.
- Graceful degradation: if `wiki/heuristics/` doesn't exist, has 0 articles, or all articles fail YAML frontmatter parsing, skip the entire heuristic judge flow silently. No errors, no user-facing warnings. Prevents: mandatory dependency on heuristic wiki.
- Match cap: select at most 3 heuristics per invocation. If more than 3 match, rank by: (1) status=iron first, (2) confidence descending, (3) domain tag relevance to phase scope. Prevents: all-15-match scenario blowing context budget.

## Deliverables

1. `templates/.claude/skills/dev-plan/heuristic-matcher.md` — trigger matching protocol + subagent prompt (~50 lines)
2. `templates/.claude/skills/dev-plan/heuristic-judge-prompt.md` — plan-adapted judge prompt with plan-specific exemplars (~60 lines)
3. Modified `templates/.claude/skills/dev-plan/SKILL.md` — Step 6.5 heuristic judge integration (~5-line companion pointer)
4. `eval/reasoning/selective/ground-truth.json` — manual mapping: for each of 25 scenarios, which of the 15 heuristics are relevant. Schema: `{"<scenario-id>": {"relevant": ["HEU-001", "IRON-004"], "rationale": "..."}}` with empty `relevant` array for scenarios with no matching heuristics
5. Updated `eval/reasoning/run-eval.py` — `--selective` mode for trigger-matched injection analysis
6. `eval/reasoning/selective/results.json` — selective injection eval results
7. `eval/reasoning/traces/phase-51-analysis.md` — matching accuracy report + selective vs blanket injection comparison

## Exit Criteria (machine-checkable)

- [ ] `test -f templates/.claude/skills/dev-plan/heuristic-matcher.md`
- [ ] `test -f templates/.claude/skills/dev-plan/heuristic-judge-prompt.md`
- [ ] `grep -q 'heuristic.matcher\|heuristic-matcher' templates/.claude/skills/dev-plan/SKILL.md`
- [ ] `test -f eval/reasoning/selective/ground-truth.json && python3 -c "import json; g=json.load(open('eval/reasoning/selective/ground-truth.json')); assert len(g) >= 25, f'only {len(g)} scenarios'"`
- [ ] `python3 eval/reasoning/run-eval.py --help 2>&1 | grep -q 'selective'`
- [ ] `test -f eval/reasoning/selective/results.json && python3 -c "import json; r=json.load(open('eval/reasoning/selective/results.json')); assert 'scenarios' in r or 'runs' in r, 'missing expected structure'"`
- [ ] `test -f eval/reasoning/traces/phase-51-analysis.md`
- [ ] `make test && make eval`

## Checkpoints

- After heuristic matcher built (Deliverable 1, before judge prompt): test matcher on 5 eval scenarios manually — invoke with scenario context, verify it returns 1-3 relevant heuristics. If <3/5 scenarios produce appropriate matches (matches align with ground-truth.json), revise matching algorithm before building judge. This is the cheapest falsification test.
- After selective injection eval (Deliverable 6): if selective injection shows negative delta vs blanket injection on >50% of scenarios (trigger-matched injection scores lower than all-IRON-RULES injection), report negative finding. The matcher/judge infrastructure remains valuable for Phase 7 evolution — but the selective injection hypothesis is falsified.
- After Step 6.5 integration (Deliverable 3): run dev-plan on a dry-run Phase 52 stub to verify heuristic judge fires and produces valid 3-dimension scores. If judge fails to fire or produces malformed output, debug before marking integration complete.

## Assumptions

- LLM-based trigger matching via Agent subagent produces meaningful results (matches at least 1 relevant heuristic for scenarios where a relevant heuristic exists). If false: fall back to domain-tag-only matching (coarser but deterministic). The matcher companion file should support both strategies with a `strategy: llm|domain-tag` parameter.
- The judge v2 rubric transfers to planning artifacts with exemplar rewrites. If false: the judge produces structured scores that may be miscalibrated for plans. Phase 7 can recalibrate with plan-specific training data. This phase validates the mechanism, not the absolute calibration.
- Dev-plan SKILL.md has room for the integration pointer (~5 lines). Current: 309/350 lines. If adding the pointer pushes past 350: extract Step 6.1 (contradiction check, ~15 lines) to a companion file first to free space.
- `wiki/heuristics/` articles have parseable YAML frontmatter with a `trigger` field. If false: the matcher logs which articles failed to parse and skips them. Articles without `trigger` fields are excluded from matching.
