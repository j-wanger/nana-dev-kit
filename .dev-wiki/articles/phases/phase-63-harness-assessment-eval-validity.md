---
title: "Phase 63: Harness Assessment & Eval-Validity"
aliases: ["phase-63-harness-assessment-eval-validity", "phase-63"]
category: phases
tags: [harness, assessment, eval-validity, instrument-sensitivity, deadweight, subtraction-test]
parents: []
created: 2026-05-29
updated: 2026-05-29
source: plan
status: active
scope: ["scripts/harness-audit.sh", ".gitignore", "eval/**", "templates/**", "modules.json", "wiki/heuristics/**", ".dev-wiki/articles/**"]
entry_criteria: "Phase 62 complete + committed; spec specs/harness-assessment-eval-validity.md nana:approved 2026-05-29; direction confirmed 2026-05-29"
exit_criteria: "harness-audit.sh runs + emits classified output + MATCH=ok; instrument-sensitivity probe recorded with verdict token + delta; make test ≥13 green AND make eval 54/54 AND test_registration.sh AND referential integrity all pass AFTER batched cuts; .memory/*.db gitignored; eval-validity verdict article + roadmap where every item carries decidable-when:; every never-fired cut cites a firing test"
---

# Phase 63: Harness Assessment & Eval-Validity

## Objective

Assess the nana-dev-kit harness as a whole from four angles — what is USED / LATENT / DEADWEIGHT, whether the parts compose coherently, and (the spine) whether the evaluation apparatus can even detect whether the harness helps a real agentic workflow — then execute the evidence-confirmed slam-dunk subtractions in-phase and leave a remediation roadmap for the rest.

## Scope

Files and modules affected:
- `scripts/harness-audit.sh` (new, re-runnable utilization audit)
- `.gitignore` (measurement hygiene — gitignore `.memory/*.db*`)
- `eval/**` (instrument-sensitivity probe; prune frozen dead eval records)
- `templates/**`, `modules.json`, `wiki/heuristics/**` (quarantine-first cuts)
- `.dev-wiki/articles/**` (verdict decision article + remediation roadmap)

## Exit Criteria

- [ ] `test -x scripts/harness-audit.sh && ./scripts/harness-audit.sh | grep -qE 'USED|LATENT|DEADWEIGHT'`
- [ ] `./scripts/harness-audit.sh | grep -q 'MATCH=ok'` — classified count reconciles against an independent source inventory (`INVENTORY=N CLASSIFIED=N MATCH=ok`)
- [ ] Instrument-sensitivity probe recorded with a verdict token (`grep -qE 'instrument: (sensitive|blind|mixed|untested)'` in the verdict article) + a delta value
- [ ] `make test` ≥13 scripts green AFTER the batched cuts
- [ ] `make eval` at the Phase-61 baseline (54/54) AFTER the batched cuts
- [ ] `tests/test_registration.sh` passes after cuts (bidirectional registration invariant)
- [ ] Referential integrity: every `source:`/`[[...]]` link in `working-knowledge.md` + `active-knowledge.md` resolves, before and after deletions
- [ ] `grep -qE '\.memory/.*\.db' .gitignore`
- [ ] Eval-validity verdict persisted as a decision article AND a roadmap where `grep -c '^- '` item count equals `grep -c 'decidable-when:'` count
- [ ] Every executed "never-fired" cut cites an affirmative firing test (not log-absence)

## Constraints

- No cut on log-absence or loadedness — prevents false-negativing long-cadence hooks (pre-compact, session-stop, crash-recovery, memory-bridge); a never-triggered verdict needs an affirmative firing test. ([[deadweight-requires-affirmative-evidence]])
- No cut on the distrusted instrument's net-zero until the sensitivity probe shows it can produce a non-zero delta — prevents driving cuts from a blind instrument. ([[eval-validity-instrument-sensitivity-probe]])
- Every template deletion is a migration (quarantine-first) — prevents the cascade-failure blast radius of `cp -r`-to-every-project. ([[cuts-are-frozen-batched-migrations]])
- Cuts are batched at the end of a frozen-state pass — prevents later findings running on a mutated harness (assessor=assessed).
- A cut that breaks `make test` / moves `make eval` off baseline / breaks `test_registration.sh` or a referential link is reverted and kicked to the roadmap.
- The `uses` counter is not the cut signal — prevents least-`uses`→cut (87/100 tied at the floor; inert).
- Roadmap items each carry a canonical `decidable-when:` line — prevents reproducing the 58/59/61 stuck-decision backlog. ([[roadmap-decidable-when]])

## Checkpoints

- After the utilization audit's first classification but BEFORE any cut: report the USED/LATENT/DEADWEIGHT table + proposed cut list + confirm the instrument-sensitivity result.
- If the probe shows the apparatus is blind: STOP cut-justification-by-eval; pivot remaining effort to the eval proposal.
- If any proposed cut would break `test_registration.sh` / a referential link / `make test` / `make eval`: STOP that cut, revert, move it to the roadmap.
- If the cognitive-system counter turns out to be a one-line wiring bug (cheap path to firing): STOP the cut and surface fix-vs-cut as a decision.

## Assumptions

- The multi-agent workflow tool is available for the assessment fan-out. If false: run the four angles sequentially as ordinary tasks (single-perspective) and note the downgrade.
- `make test` (13 scripts) and `make eval` (54 scenarios) are green at phase entry. If false: capture pre-existing failures and exclude them from the regression gate.
- Eval dependencies (`jq`, judge model, embedding provider) are available; any silent degrade to a weaker path (word-overlap fallback) is announced in the eval-validity write-up.

## Notes

The harness is both the artifact under test AND the tool doing the test — there is no separate production system. Hard evidence already gathered at phase entry: all 12 HEU + 5 IRON heuristics sit at helpful:0/harmful:0 (the cognitive system, "7/7 complete" Phases 44-52, never recorded firing); `audit-log` PostToolUse hook produces no `.nana/audit.jsonl` in the live repo; `enforcement.log` has 242 lines (enforce hooks genuinely used); MCP memory store ⊂ the always-loaded hot cache (Phase 61). Authoritative contract: `specs/harness-assessment-eval-validity.md` (nana:approved 2026-05-29). Governed by [[harness-self-assessment-multi-angle]], [[eval-validity-instrument-sensitivity-probe]], [[deadweight-requires-affirmative-evidence]], [[cuts-are-frozen-batched-migrations]], [[roadmap-decidable-when]].
