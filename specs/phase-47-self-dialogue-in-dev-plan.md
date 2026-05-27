<!-- nana:approved 2026-05-27 -->
# Spec: Phase 47 — Self-Dialogue in Dev-Plan

## Objective

Add a structured self-dialogue step to dev-plan approach formulation where a clean-context subagent generates heuristic-armed counterarguments to the proposed approach, and the orchestrator resolves each before presenting to the user. Measure reasoning quality delta via the existing eval pipeline.

## Context

Phase 4 of 7 in the cognitive enhancement roadmap (Phases 44-50). The dev-plan approach formulation currently has:
- **T0 thinking protocol** (inline, pre-proposal): names weakest assumption, alternative framing, what would change recommendation — previously flagged as performative
- **Step 6.5 approach reviewer** (subagent, post-proposal): checks 5 quality dimensions — but doesn't generate adversarial counterarguments

Self-dialogue fills the gap between T0 and the reviewer: after the approach is drafted, argue against it using heuristics as ammunition, then resolve. Structurally distinct from both existing mechanisms (post-proposal adversarial critic, not pre-proposal assumption check or post-proposal quality audit).

Eval pipeline: 20 scenarios, judge v2 (exemplar-anchored), 3 differentiating scenarios (012, 014, 018). Current best condition: IRON RULES + anti-pattern tables (mean ~4.83). Scenario 012 already regressed -0.67 from expanded injection payload (context dilution).

## Scope

### In scope
- `self-dialogue-prompt.md` companion file for dev-plan (~40-50 lines)
- Step 6.0.5 pointer in dev-plan SKILL.md (~5-10 lines)
- `eval/reasoning/self-dialogue-injection.md` — eval-mode self-dialogue protocol for inline prompt injection
- `eval/reasoning/with-self-dialogue-inline/` — eval condition: self-dialogue as prompt technique in same agent context
- `eval/reasoning/with-self-dialogue-subagent/` — eval condition: self-dialogue via separate devil's advocate subagent
- Delta measurement for both conditions against `with-anti-patterns/` (current best)
- Test assertions for companion file, SKILL.md line count, eval conditions
- Updated `eval/reasoning/README.md` with both self-dialogue conditions
- Updated cognitive enhancement roadmap with Phase 47 status

### Out of scope
- Modifying T0 thinking protocol (separate mechanism, stays as-is)
- Modifying approach reviewer Step 6.5 (separate mechanism)
- Adding new eval scenarios (existing 20 sufficient)
- Heuristic evolution/scoring (Phase 50)
- Modifying judge v2 prompt (already calibrated)
- Cross-model judging (separate lever, not this phase's variable)

## Approach

Three artifacts serve production and two eval conditions:

**Production (dev-plan Step 6.0.5):** After the approach is drafted (Step 6) and before the contradiction check (Step 6.1), dispatch a clean-context subagent that receives: (1) the proposed approach text, (2) IRON RULES in the same condensed format as `iron-rules-injection-v2.md` (Always/Never + anti-pattern failure modes), (3) phase objective and exit criteria. The subagent generates 2-3 specific counterarguments, each citing which IRON RULE or heuristic it draws from. The orchestrator resolves each counterargument inline (accept → revise approach, reject → state specific reason) before proceeding.

**Eval condition A — inline** (`with-self-dialogue-inline/`): Self-dialogue protocol injected into the agent system prompt alongside IRON RULES + anti-pattern tables. The agent internally: (a) forms initial recommendation, (b) generates counterarguments citing IRON RULES, (c) resolves each, (d) presents final recommendation. Single subagent, same as existing eval methodology.

**Eval condition B — subagent** (`with-self-dialogue-subagent/`): Orchestrated multi-step eval. (1) Agent subagent forms initial recommendation with IRON RULES. (2) Devil's advocate subagent receives recommendation + IRON RULES, generates counterarguments. (3) Resolution subagent receives original recommendation + counterarguments, resolves and presents final recommendation. (4) Judge scores final output. Three separate subagent dispatches per scenario.

Comparing A vs B isolates whether subagent isolation (clean-context critic) adds value over the prompt technique alone.

## Constraints (CRITICAL)

- SKILL.md must stay ≤ 350 lines (currently 309) — self-dialogue MUST be a companion file with a ≤10 line Read pointer in SKILL.md.
  Prevents: ceiling breach requiring emergency extraction of existing content.

- Self-dialogue subagent produces max 200 words total (counterarguments + inline resolutions combined), single invocation, 2-3 counterarguments each citing an IRON RULE by ID. Companion prompt must enforce this.
  Prevents: context dilution regression (scenario 012 already at -0.67).

- Each counterargument must cite a specific IRON RULE or heuristic by ID — no generic "have you considered..." style arguments.
  Prevents: performativity (strawman arguments pre-decided to be dismissed).

- Self-dialogue output must be resolved and consumed before Step 6.5 — the approach reviewer receives the revised approach text, NOT raw counterarguments or self-dialogue trace.
  Prevents: approach reviewer dimension 5 (alternative awareness) becoming trivially satisfied.

- Single-pass design: no retry mechanism in self-dialogue. Total retry budget across T0 + self-dialogue capped at 2 (T0's existing non-vacuity gate owns retries).
  Prevents: stall loops between T0 non-vacuity gate and self-dialogue.

- Eval tests self-dialogue as incremental addition to current best condition (IRON RULES + anti-pattern tables + self-dialogue vs IRON RULES + anti-pattern tables alone). Delta ≥ 0.5 on at least one differentiating scenario (012, 014, 018) is the success criterion.
  Prevents: claiming improvement from wrong baseline comparison.

- No per-scenario regression > 1.0 on any of 20 scenarios. Scenario 012 must not drop below mean 4.0 (currently ~4.33).
  Prevents: net-negative context dilution masked by average improvement.

- If subagent output lacks specific IRON RULE citations (no "IRON-NNN" reference), discard and proceed without self-dialogue revision (fail-open). Do not retry.
  Prevents: unconstrained generic counterarguments that add noise without heuristic grounding.

## Deliverables

1. `templates/.claude/skills/dev-plan/self-dialogue-prompt.md` — companion file (~40-50 lines)
2. `templates/.claude/skills/dev-plan/SKILL.md` — Step 6.0.5 pointer added (≤10 lines net)
3. `eval/reasoning/self-dialogue-injection.md` — eval-mode inline protocol for prompt injection
4. `eval/reasoning/with-self-dialogue-inline/results.json` — 3-run eval results (inline condition)
5. `eval/reasoning/with-self-dialogue-subagent/results.json` — 3-run eval results (subagent condition)
6. Updated `eval/reasoning/README.md` — both conditions documented in results table
7. Updated `tests/test_templates.sh` — companion file existence, SKILL.md references, line count
8. Updated cognitive enhancement roadmap (`roadmap-cognitive-enhancement.md`) — Phase 47 status

## Exit Criteria (machine-checkable)

- [ ] `test -f templates/.claude/skills/dev-plan/self-dialogue-prompt.md`
- [ ] `grep -q 'self-dialogue' templates/.claude/skills/dev-plan/SKILL.md`
- [ ] `[ $(wc -l < templates/.claude/skills/dev-plan/SKILL.md) -le 350 ]`
- [ ] `test -f eval/reasoning/self-dialogue-injection.md`
- [ ] `test -f eval/reasoning/with-self-dialogue-inline/results.json`
- [ ] `test -f eval/reasoning/with-self-dialogue-subagent/results.json`
- [ ] `make test`
- [ ] `make eval 2>&1 | grep -qE 'Score.*100'`
- [ ] Eval delta: ≥ 0.5 improvement on at least one differentiating scenario (012, 014, or 018) vs `with-anti-patterns/` condition (verified via `run-eval.py --compare`)
- [ ] Eval regression: no scenario drops > 1.0 vs `with-anti-patterns/`; scenario 012 mean ≥ 4.0

## Checkpoints

- After self-dialogue-prompt.md: review companion standalone readability and heuristic citation format
- After SKILL.md integration: verify line count ≤ 350 and no companion reference breakage (test_templates.sh)
- After first eval run: check scenario 012 score — if below 4.0, compress injection payload before continuing
- After 3 eval runs: report per-scenario delta table and variance; if delta < 0.5 on all differentiating scenarios, document negative result

## Assumptions

- Clean-context subagent can effectively use IRON RULES as counterargument ammunition. If false: fall back to inline self-dialogue with structured heuristic prompting (loses isolation but still measurable).
- 20 existing scenarios are sufficient to detect reasoning improvement from self-dialogue. If false: document as limitation, defer stronger measurement to Phase 48 (trace collection with larger corpus).
- Self-dialogue adds incremental value beyond T0 + approach reviewer. If false: document negative result, update cognitive enhancement roadmap, proceed to Phase 48 — a measured null is a valid outcome.
