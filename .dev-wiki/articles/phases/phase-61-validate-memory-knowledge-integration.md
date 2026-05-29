---
title: "Phase 61: Validate Memory & Knowledge Integration"
aliases: ["validate-memory-knowledge-integration", "memory-integration-ab"]
category: phases
tags: [memory, knowledge-wiki, retrieval, ab-testing, mcp-memory, context-engineering, subagent-firewall, experiment-first, step-renumber]
parents: [phase-60-harness-activation-residuals]
created: 2026-05-29
updated: 2026-05-29
source: plan
status: active
scope: ["eval/memory-integration/", "templates/.claude/skills/dev-plan/SKILL.md", "templates/.claude/skills/dev-debrief/SKILL.md", "templates/.claude/skills/spec/SKILL.md", "tests/"]
entry_criteria: "Phase 60 complete + committed (harness-activation roadmap closed); approved spec specs/phase-61-validate-memory-knowledge-integration.md; user chose experiment-first (validate, defer build to P62), all 5 integration directions incl. the user-added retrieval-subagent firewall; direction gate approved."
exit_criteria: "Results artifact eval/memory-integration/results.md with pre-registration ordered first; wiki signal-quality gate + weak-parametric topic selection recorded (or explicit Phase-59-redux stop); Stage-0 falsification delta recorded; retrieval-subagent-firewall direction addressed; context-poisoning + cost ledger recorded; per-direction keep/cut decisions naming both outcomes + a Phase-62 build list; step-renumber to whole numbers across dev-plan/dev-debrief/spec with all cross-refs resolved + a numbering-continuity test; make test green + make eval 100%."
---

# Phase 61: Validate Memory & Knowledge Integration

## Objective

Decide by A/B evidence (not blind build) which memory/knowledge-retrieval integrations earn a place in the harness flow: wire the real retrieval engines (knowledge-wiki `knowledge.db` FTS5/vector; MCP `memory_search`) into planning, vs the status quo (always-loaded markdown + naive `index.md` scoring + write-mostly MCP). Experiment-first — validate + pre-register decisions; build the winners in Phase 62. Deterministic step-renumber (whole numbers) rides along, walled off from the A/B.

## Scope

- `eval/memory-integration/results.md` — primary write target (pre-registration + staged A/B results + per-direction decisions)
- `templates/.claude/skills/dev-plan|dev-debrief|spec/SKILL.md` — step-renumber only (the A/B does NOT modify these as features — that's Phase 62)
- `tests/` — numbering-continuity test; any A/B harness scripts
- Read-only inputs: `~/.claude/wikis.json`, the candidate wikis, `memory_server/`, the Phase 58-59 A/B harness

## Exit Criteria

- [ ] `eval/memory-integration/results.md` exists with a pre-registration block ordered BEFORE any results.
- [ ] Wiki signal-quality gate recorded (retrieval-worthy vs scrape/noise) + ≥2 weak-parametric + wiki-covered test topics chosen — OR an explicit Phase-59-redux stop for the retrieval arm.
- [ ] Stage-0 best-case falsification delta recorded (≥3 runs, blind judge, within-round paired); further stages only if it shows lift.
- [ ] Retrieval-subagent-firewall (D5) addressed; context-poisoning (non-target regression) + cost ledger recorded.
- [ ] Per-direction keep/cut decisions naming both outcomes, applied mechanically to quoted numbers, with a Phase-62 build list.
- [ ] Step-renumber: no decimal/postfix steps remain in dev-plan/dev-debrief/spec SKILL templates; all cross-refs (companions, hooks, dev-wiki, memory) updated; numbering-continuity test passes.
- [ ] `make test` exits 0; `make eval` reports 100%.

## Constraints

- Testing a foregone conclusion (Phase-59-redux) — Guard: signal gate FIRST; topics verified weak-parametric AND wiki-covered; if none, declare + stop the retrieval arm (don't run an A/B that can't show lift then read the null as "useless").
- Burden of proof on the feature — Guard: keep requires affirmative lift past the variance gate; decision quotes the numbers.
- Judge noise as signal — Guard: ≥3 runs/condition, within-round paired only, escalate to 5; spread > |delta| ⇒ cut that direction.
- Context poisoning unmeasured — Guard: measure non-target regression on the raw-injection arm (the firewall's reason to exist).
- Cost never entered — Guard: net delta against tool-calls/latency/tokens incl. the subagent round-trip.
- p-hacking via topic/condition selection — Guard: pre-register before any result; log discards; post-hoc conditions are exploratory.
- Subagent-firewall confound — Guard: record injected-token counts; note if a length-matched control is needed before crediting firewall > raw.
- Step-renumber breaks references — Guard: grep every `Step \d` ref kit-wide, update all, numbering-continuity test, suite green.
- Scope creep into building — Guard: this phase decides; only code changes are the experiment harness + the independent step-renumber. Integrations are Phase-62.

## Checkpoints

- After signal gate + pre-registration (T1), before any A/B: report wiki signal quality, chosen topics (or Phase-59-redux stop), pre-registered conditions/rules; confirm the design can show lift if it exists.
- After Stage 0 (T2): STOP, report best-case delta/spread/cost; no lift ⇒ cut retrieval thesis, skip Stages 1-2.
- After each stage: report deltas + variance + poisoning + cost.
- Before final decision (T5): report aggregate + mechanical rule application; keep/cut + Phase-62 list confirmed at the delivery gate.
- Step-renumber (T6): verify all cross-refs resolve before marking done.

## Assumptions

- Phase 58-59 A/B harness reproducible. If false: STOP and report.
- A weak-parametric + wiki-covered topic is findable. If false: declare Phase-59-redux for these wikis; proceed only with architecture/2-tier + step-renumber.
- The wiki `knowledge.db` is queryable in a condition. If false: wiki-search arm becomes a documented limitation; memory arm + step-renumber proceed.
- make test/eval clean modulo the guarded optional-sqlite-vec path.

## Notes

- 5 directions factored into 3 axes + 1 conclusion: WHAT (wiki-search D1 / memory D2 / baseline) × HOW (raw vs subagent-firewall D5) × PREP (raw knowledge.db vs absorbed D4); 2-tier/3-tier (D3) is derived from D2.
- Execution: A/B fan-out via Workflow ([[measurement-fan-out-as-workflow]]) if user opts in, else serial subagents.
- This phase tests precisely the boundary Phase 59 left open ([[cut-active-research-step-2-7]]: retrieval doesn't pay when parametric knowledge is strong — UNTESTED on weak-parametric/proprietary). [[deterministic-success-over-eval-ceremony]] is why the step-renumber is walled off from the A/B (deterministic → no judge).
