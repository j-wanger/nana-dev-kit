---
title: "Phase 68 complete — Amplifier Measurement Instrument (Frontier 0, the control-validated ruler)"
aliases: []
category: journal
tags: [eval-validity, amplifier-vision, measurement, frontier-0, phase-68, instrument-validation]
parents: [phase-68-amplifier-measurement-instrument]
created: 2026-05-29
updated: 2026-05-29
source: debrief
duration: ~2-3h (post-compaction estimate)
---

# Phase 68 complete — Amplifier Measurement Instrument (Frontier 0, the ruler)

## What Happened

- Built **Frontier 0 of the amplifier vision — the deterministic measurement instrument ("ruler")** — BEFORE any cognitive frontier. The strategic handover ranked the escalation-classifier (Frontier 1) highest, but it is **unfalsifiable without an instrument** and the dependency order was backwards (classifier needs the private-knowledge map needs the recognition loop; the cheap measurable foundation was ranked lowest). This phase corrects the order: ship the ruler first.
- **T1 (BEHAVIORAL feasibility checkpoint, first):** `eval/amplifier/schema-probe.sh` PASSES on a real session transcript — the jsonl distinguishes human turns, AskUserQuestion/escalation events, and tool-uses by event structure. GO, no pivot to a logging-hook. Output: `SCHEMA-NOTES.md` with the proxy→field table + pinned predicates (escalation = AskUserQuestion-only for v1).
- **T2:** froze the 4-group proxy-vector schema (mechanical / interaction / enforcement / ground_truth) + authored 5 control fixtures: the surfaced/buried **minimal pair**, buried-phrase-outside-escalation, a corrupt-line, and an enforcement-with-blocks log.
- **T3:** built the emitter `eval/amplifier/emit-proxy-vector.sh` (bash+jq, deterministic, read-only) TDD against `tests/test_amplifier_emitter.sh` → **14/14 green**. The control pair FLIPS the detector + ≥1 interaction proxy (the rm-rf-guard-probe analog); absent `enforcement.log` ⇒ null sentinel (not silent 0); corrupt line ⇒ `parse_errors`; read-only proven (shasum unchanged); real transcript reads clean.
- **T4:** wired the test into the Makefile `test` target; executables-only no-LLM sweep clean; no `verdict` field anywhere in the output (the instrument makes NO harness claim).
- **T5:** regression gate — `make test` 0 FAIL, `make eval` 52/52 unchanged, `eval/comparison`+`eval/corpus` untouched, Phase-69 handoff recorded in the decision article.
- The decision article [[amplifier-measurement-instrument]] was authored at planning (confidence: high) and covers all 6 sub-decisions; not duplicated here.

## Decisions Made
- [[amplifier-measurement-instrument|Amplifier Measurement Instrument — build Frontier 0 (the ruler) before any cognitive frontier]] -- authored at planning, confirmed at delivery (confidence high)

## Problems Solved
- **Makefile script-count drift-guard fired (DISCOVERY).** Adding the new test to the Makefile bumped the script count that `tests/test_templates.sh:485` drift-guards against `README.md:114`. No auto-sync exists — hand-bumped README 18→19 this session. Added to the mental model.
- **Substrate choice closed two prior eval kills.** Using the session transcript jsonl (not `enforcement.log`) closes the parked Phase-66 firing→action schema-gap (the transcript carries firing + agent action + human response in one ordered stream) AND supplies the real trace provenance that clears the Phase-65 corpus-duplication bar.

## Open Questions
- Is the **AskUserQuestion-only escalation predicate** too narrow? Decisions may also surface via ExitPlanMode or plain assistant text — revisit if a real Phase-69 run shows it. (Phase-69 consideration, not a blocker.)
- The **redirect_proxy** (unsolicited-human-turn count) shipped EXPERIMENTAL/structural-only and is not yet validated against a known redirect — Phase-69 candidate to either validate or cut. (Phase-69 consideration, not a blocker.)

## Artifacts Changed
- `eval/amplifier/emit-proxy-vector.sh` (NEW — the read-only deterministic ruler; bash+jq)
- `eval/amplifier/schema-probe.sh` (NEW — T1 feasibility gate)
- `eval/amplifier/SCHEMA-NOTES.md` (NEW — frozen 4-group schema + proxy→field table + pinned predicates)
- `eval/amplifier/fixtures/` (NEW — 5 control fixtures: surfaced/buried pair + buried-outside-escalation + corrupt-line + enforcement-with-blocks.log)
- `tests/test_amplifier_emitter.sh` (NEW — 14 assertions; wired into `make test`)
- `Makefile` (wired the emitter test into `test`; 18→19 scripts)
- `README.md` (hand-bumped script count 18→19 to satisfy the test_templates drift-guard)
- `specs/phase-68-amplifier-measurement-instrument.md` (the phase spec)
- `.dev-wiki/articles/decisions/amplifier-measurement-instrument.md` (authored at planning, confidence high)

## Related
- [[phase-68-amplifier-measurement-instrument|Phase 68: Amplifier Measurement Instrument]] -- parent phase
- [[eval-validity-verdict]] -- the MIXED verdict this ruler answers (non-blind, deterministic)
- [[instrument-not-score-enforcement-firing-substrate]] (Phase 65) + [[park-enforcement-scorer-signal-insufficient]] (Phase 66) -- the two prior eval kills this substrate clears

## Soft Observations / Phase N+1 Candidates
- Phase 69 = **USE the validated ruler for the actual harness measurement** | live off/on (harness-disabled vs harness-enabled) run on a real consuming-project (the ab-test / stock-screener transcripts already exist at `~/.claude/projects/-Users-jwang-ab-test*`), n>1 paired runs, the harness verdict — needs representativeness, which Phase 68 deliberately did not provide | evidence: decision article Phase-69 handoff section
- Phase 69 also unblocks the `eval/comparison` + `eval/reasoning` apparatus disposition (Phase-63 roadmap item) | now decidable because a non-blind instrument exists | evidence: [[phase-63-remediation-roadmap]]
- Frontier 1 (the escalation/classification layer) is the eventual target the ruler measures | cheap paper-probe first: retro-label a sample of the 154 decisions into execution/domain/directional to falsify it before building | evidence: decision article
- The `redirect_proxy` interaction field is experimental and unvalidated | Phase-69 candidate: validate against a real redirect or cut | evidence: SCHEMA-NOTES.md
- ENV issue worth a wiki-capture: the dedicated Grep/Glob tools were absent from the tool registry (not a settings deny — ToolSearch couldn't find them); worked via Bash grep + rg. Terminal also duplicated/mangled command output repeatedly this session.
