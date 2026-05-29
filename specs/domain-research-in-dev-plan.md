<!-- nana:approved 2026-05-28 -->
# Spec: Active Domain Research in dev-plan (Phase 58, Fix 2)

## Objective

Make planning *look things up* instead of guessing: add a bounded, gap-gated research step to dev-plan that answers the spec's `### Domain Research Questions` from the web + local wiki, injects the distilled findings into the proposed approach, and persists durable facts back into the knowledge wiki for reuse on later phases.

## Context

Phase 55 reformed the spec template so it now *poses* 1-3 Domain Research Questions per phase — but nothing ever answers them. dev-plan's flow (Steps 2/2.5) only reads the *existing* wiki; when coverage is thin it merely *recommends* the user run `/wiki-bootstrap` manually (`SKILL.md:154`). So the planner still guesses from parametric knowledge on uncovered topics. This is Fix 2 of the Phase 57+ harness-activation roadmap — the only genuinely-open high-value item (Fixes 1/4 done, 5 mostly done, 3 vague). A prior experiment reported a "+1.75" quality delta for open-ended prompts that do real domain research, but that experiment conflated several variables AND part of the win (less-prescriptive specs) was already captured by Phase 55. The true *residual* value of adding active research is therefore unknown and must be measured, not assumed. Mechanism (c) — a new Step 2.7 in dev-plan — was chosen by the user over routing research through `/spec` (a) or auto-firing `/wiki-bootstrap` (b), because findings should land where design decisions are made (the approach).

## Scope

### In scope
- A new dev-plan step (Step 2.7, after Step 2.5, before Step 3) that: gates on post-Step-2.5 coverage gaps, does bounded research on uncovered Domain Research Questions, distills findings, injects a capped summary into the Step 6 approach, and routes durable findings into the wiki via its existing capture path.
- The step's procedure lives in a **companion file** (dev-plan SKILL.md is 321/350 — the procedure is too long to inline without breaching the cap).
- Keep the existing dev-plan ≤350-line cap assertion (`tests/test_templates.sh:262-263`) green.
- Eval coverage: a "covered → research skipped" scenario, an "uncovered → research fires + finding referenced in approach" scenario, and a measured with-vs-without **residual delta** comparison, honestly recorded.
- Lite-ceremony skip for Step 2.7 (it depends on the Lite-skipped Step 2.5 coverage signal).

### Out of scope
- Fixes 3 (AGENTS.md reshape) and 5 (nana-init discoverability).
- Mechanisms (a) /spec-answers-its-own-questions and (b) auto-fire /wiki-bootstrap.
- Changing the spec template's Domain Research Questions section (Phase 55 shipped it; this work *consumes* it).
- Building a new web-research crawler from scratch — reuse the kit's existing capture/research conventions (`wiki-add` capture path; align findings format with `wiki-bootstrap`).
- Writing findings to MCP memory (the knowledge wiki is the durable store for domain facts).
- Language-agnostic core (Gap 4.1); auto-generating AGENTS.md (explicitly on the "What NOT to build" list).

## Approach

Insert a research step between knowledge-loading (Step 2.5) and approach-proposal (Step 6). Coverage is decided **per Domain Research Question**: for each question, query the local wiki/index; research fires only on questions the wiki does not already answer. (Step 2.5's concept-coverage number is a supplementary hint, not the gate — it scores concepts extracted from objective/scope, not the spec's questions.) So the common case (wiki already covers it) costs zero external calls. Retrieval is bounded and proportional to the gap. Findings are distilled to a small, context-shaped summary injected into the approach (Step 6), where they must visibly inform specific design decisions — not sit as a decorative appendix. Durable findings are routed through the wiki's normal capture path (so the `wiki-absorb` curation gate is not bypassed) and carry provenance (source URL, date, `auto-researched`) so later phases — and audits — can tell researched fact from human-curated knowledge and re-verify it. Untrusted question text is treated as data, never as instructions to the research agent. Everything fails open: no web, no questions, no writable wiki, or timeout → skip with an explicit marker and proceed, never relabel a parametric guess as "researched."

The headline `+1.75` is treated as unproven for *this* lever. The phase ships a measurement that isolates active-research as the only changed variable against the current Phase-55 baseline and records the delta honestly — a small or negative result is an acceptable, informative outcome (subtraction test: if research never changes the approach, the feature has not earned its complexity).

### Domain Research Questions
1. Can the existing `wiki-bootstrap` focus-topic mode be invoked in a *bounded* way (cap searches/fetches/time) from inside planning, or is a lightweight inline `WebSearch`+`WebFetch` retrieval the better fit given this runs on every standard-ceremony plan? (DRY vs cost trade-off — the adversarial pass warned against a redundant 4th crawler.)
2. What is the right durable-persistence path that keeps the `wiki-absorb` human-curation gate intact — route findings to the wiki **inbox** (deferred absorb) vs write polished articles directly with an `auto-researched` provenance marker? Which keeps `wiki-lint`/`wiki-health`/index integrity?
3. Per-question wiki-query is the coverage gate (not Step 2.5's concept score) — what query form and "already answered" threshold best avoids both over-researching (wasted budget, duplicate articles) and under-researching (missed gaps)? How should an absent/stale wiki index (the kit only builds one at 50+ articles) degrade the check?

## Constraints (CRITICAL)

- **Hallucinated findings poison later phases.** A persisted finding compounds, unlike a one-shot guess. — Guard: every persisted claim carries a real source URL fetched *this run* (or `source: local-wiki:<article>` for lookup hits); a title/snippet is not a source. Validation: a persisted research finding with zero retrievable source reference fails.
- **Runs on every standard plan → unbounded cost.** "Bounded" is falsifiable-vague. — Guard: explicit numeric caps in the companion (max questions/run, max searches/question, max total fetches, wall-clock/tool-call budget) that degrade to *partial findings* rather than blocking the plan.
- **Research theater: findings don't change the approach.** This is the central risk and the easiest to fake. — Guard: the approach must reference each used finding at the specific decision it influenced; a finding informing zero decisions is dropped, not persisted. The measurement must show ≥1 scenario where research-injected and baseline approaches differ in a *named* decision.
- **New finding silently contradicts an existing wiki article.** Append-only persistence guarantees this over time. — Guard: contradiction check against same-topic articles before persist; on conflict supersede-with-link or mark `under-review` (reuse existing supersession primitives), never blind-append.
- **No-network / sandbox reintroduces the original bug with false confidence.** — Guard: fail-open — skip research, emit `[research: web unavailable — local wiki only]` into the plan, persist nothing labeled researched. Mirror the kit's `command -v … || exit 0` fail-open pattern.
- **350-line SKILL.md cap breach** (history: session-start.sh eroded 70→137 with no test catching it). — Guard: research logic in a companion file (2-line Read pointer); the existing `tests/test_templates.sh:262-263` ≤350 assertion (run by `make test`) catches any breach — keep it green, do not duplicate it.
- **Verbose findings dilute planner context** (measured: ~1200-char / ~400-token injection threshold, scenario-012 regressions when payloads grew). — Guard: hard char cap on the injected summary, truncate-with-priority; a non-target planning scenario must not regress when injection is active.
- **Prompt-injection via the question text.** Research questions are LLM-generated text from a prior phase, fed to a web-searching agent. — Guard: question text is treated strictly as a search topic (data), never executed as an instruction.
- **Auto-persistence bypasses the `wiki-absorb` curation gate** at the highest-frequency wiki entry point. — Guard: route findings through the standard capture path (inbox/absorb) or mark `auto-researched` provenance; do not silently write polished, un-curated articles as ground truth.

## Success Vision

A standard-ceremony `/dev-plan` on a topic the wiki doesn't cover triggers a short, focused research pass whose findings *visibly shape* the proposed approach (each cited at the decision it informed) and land as reusable, provenance-tagged wiki entries — while the same command on a well-covered topic spends zero external calls. The planner stops guessing on uncovered domains and starts looking things up. The phase reports, honestly, how much (if anything) active research adds over the Phase-55 baseline — a credible negative result is a real outcome, not a failure to hide.

## Exit Criteria (machine-checkable)

- [ ] `test -f templates/.claude/skills/dev-plan/domain-research-spec.md` — companion exists
- [ ] `grep -q 'domain-research-spec.md' templates/.claude/skills/dev-plan/SKILL.md && grep -qiE 'Step 2\.7' templates/.claude/skills/dev-plan/SKILL.md` — step wired via pointer
- [ ] `grep -qi 'Lite' templates/.claude/skills/dev-plan/SKILL.md && grep -A2 -iE 'Step 2\.7' templates/.claude/skills/dev-plan/SKILL.md | grep -qi 'lite'` — Lite-skip noted on Step 2.7
- [ ] `[ $(wc -l < templates/.claude/skills/dev-plan/SKILL.md) -le 350 ]` — line cap honored
- [ ] `bash tests/test_templates.sh` passes — the existing dev-plan ≤350 cap assertion (line 262-263) stays green
- [ ] Companion contains explicit numeric caps and a fail-open clause: `grep -qiE 'max|cap|budget' templates/.claude/skills/dev-plan/domain-research-spec.md && grep -qiE 'fail-open|web unavailable|skip' templates/.claude/skills/dev-plan/domain-research-spec.md`
- [ ] Companion encodes provenance + injection-prompt safety: `grep -qiE 'source|provenance|url' templates/.claude/skills/dev-plan/domain-research-spec.md && grep -qiE 'data, not|not.*instruction|injection' templates/.claude/skills/dev-plan/domain-research-spec.md`
- [ ] The measurement exercises BOTH branches and records them in one artifact (the functional test of Step 2.7, since the binary runner cannot score an LLM-executed step): a **covered** topic asserts research is SKIPPED (no external search), an **uncovered** topic asserts research FIRES and ≥1 finding is cited at a *named* approach decision. Artifact path fixed at implementation; content-checked: `grep -qiE 'covered|skip' <artifact> && grep -qiE 'fired|uncovered' <artifact> && grep -qiE 'decision|cited' <artifact>`
- [ ] The residual-delta artifact records a **numeric** with-vs-without delta against the Phase-55 baseline (human-gated at Checkpoint 2 — `test -f` alone is NOT sufficient to self-declare done): `grep -qiE 'delta|baseline' <artifact> && grep -qE '[0-9]' <artifact>`
- [ ] `make test` green and `make eval 2>&1 | grep -qE 'Score: [0-9]+/[0-9]+ \(100%\)'` (regression gate only — anchored so a partial pass like `54/55` cannot false-positive)

## Checkpoints

- After the companion + Step 2.7 pointer are drafted (before eval work): report the bounded-research design (caps, persistence path, coverage gate) — confirm it answers DRQ 1-3.
- After the measurement runs: STOP and report the residual delta before declaring the phase done. If the delta is ~0 or negative, present that honestly and let the user decide whether to keep, trim, or cut Step 2.7 — do not silently ship a feature that earns nothing.
- If reusing `wiki-bootstrap` proves unbounded/unsuitable and a lightweight inline retrieval is needed instead: note the deviation, proceed (still no bespoke crawler beyond the minimal retrieval).

## Assumptions

- A per-question wiki-query can determine whether the wiki already answers each Domain Research Question (the primary coverage gate; Step 2.5's concept score is only a hint). If false (no index / query unavailable): fall back to a grep over `wiki/` article titles+bodies per question, and on doubt treat the question as uncovered (research rather than skip).
- `WebSearch`/`WebFetch` are available in the planning environment. If false: fail-open (skip + marker), and the measurement runs only the local-lookup path.
- The target phase has a spec with a populated `### Domain Research Questions` section. If false (empty/Lite/no spec): Step 2.7 no-ops cleanly — it does not invent questions from the phase title.
- The knowledge wiki (`wiki/`) exists and is writable. If false: use findings for this run only, skip persist, note `[research: wiki unwritable — findings not persisted]`.
- The measurement can isolate active-research as the only changed variable against the Phase-55 baseline. If false: report the confound explicitly rather than claiming a clean delta (do not re-inherit the original experiment's confound).
