---
title: "Phase 68: Amplifier Measurement Instrument"
aliases: [phase-68, amplifier-measurement-instrument, frontier-0]
category: phases
tags: [eval-validity, amplifier-vision, measurement, frontier-0, phase-68]
parents: []
created: 2026-05-29
updated: 2026-05-29
source: plan
status: completed
scope: ["eval/amplifier/*", "Makefile", "tests/*", ".gitignore"]
entry_criteria: "Phase 67 delivered; eval-validity verdict (instrument MIXED) and the Phase-63 remediation roadmap establish the need for a non-blind, provenance-grounded ruler before any cognitive frontier"
exit_criteria: "emitter exists; control pair flips detector + ≥1 interaction proxy; buried-phrase-outside-escalation=false; absent enforcement.log⇒sentinel; corrupt line⇒parse_errors; read-only proven; no LLM in eval/amplifier; make test green at new count; make eval 52/52; no edits to eval/comparison|corpus; Phase-69 handoff recorded"
---

# Phase 68: Amplifier Measurement Instrument

## Objective

Build **Frontier 0 of the amplifier vision — the measurement instrument** — BEFORE any cognitive frontier, because the escalation-classifier (Frontier 1) the strategic handover ranked highest is unfalsifiable without a ruler. Ship a deterministic, READ-ONLY proxy-vector emitter that ingests a REAL Claude Code session transcript and emits a control-validated 4-group proxy-vector. See [[amplifier-measurement-instrument]].

## Scope

Files and modules affected:
- `eval/amplifier/emit-proxy-vector.*` — the new read-only emitter
- `eval/amplifier/SCHEMA-NOTES.md` — T1 feasibility probe output (proxy→field table)
- `eval/amplifier/` control fixtures (surfaced/buried pair + edge cases)
- `tests/*` — the emitter's RED test + make-test wiring + scope-honesty guards
- `Makefile` — wire the emitter test into `make test`
- `.gitignore` — as needed for amplifier run artifacts

**Out of scope (do NOT touch):** `eval/comparison/` (Phase-65 tombstone — do not rebuild), `eval/corpus/`, `eval/reasoning/`, hooks, `modules.json`, `settings.json`, `specs/`.

## Tasks

5 tasks (see `tasks.md` for enriched fields):

- **T1 [S] (FIRST/checkpoint)** — transcript-schema feasibility probe → `eval/amplifier/SCHEMA-NOTES.md` (proxy→field table mapping each proxy to a transcript field). **STOP + pivot-to-logging-hook** if a needed field (human-turn / AskUserQuestion / tool-use) is absent.
- **T2 [M]** — proxy-vector schema + control fixtures: the surfaced/buried pair, plus buried-outside-escalation, corrupt-line, and absent-enforcement-log edge cases.
- **T3 [L]** — the emitter, built TDD against its own RED test. Value assertions: surfaced→`true` / buried→`false`; ≥1 interaction proxy differs; sentinel for absent enforcement.log; `parse_errors` on a corrupt line; read-only proven.
- **T4 [S]** — wire into `make test` + scope-honesty guards (no LLM reference in `eval/amplifier`, no `verdict` field anywhere in the output).
- **T5 [S]** — regression gate (`make eval` 52/52, no edits to `eval/comparison`|`corpus`) + Phase-69 handoff recorded.

## Exit Criteria

ALL MET — implementation complete (5/5 tasks). Status held `active` pending the delivery gate (flips to `completed` on user acceptance).

- [x] emitter `eval/amplifier/emit-proxy-vector.sh` exists
- [x] control pair flips the detector AND ≥1 interaction proxy (value-asserted)
- [x] buried-phrase-outside-escalation ⇒ `surfaced=false`
- [x] absent `enforcement.log` ⇒ enforcement SENTINEL (`null`, not 0)
- [x] corrupt line ⇒ `parse_errors` (does not crash)
- [x] read-only proven (shasum unchanged + no `.dev-wiki`/`.nana` writes)
- [x] no LLM reference in `eval/amplifier`; no `verdict` field in output
- [x] `make test` green at the new count (18→19 scripts; `test_amplifier_emitter.sh` 14/14)
- [x] `make eval` 52/52
- [x] no edits to `eval/comparison` | `eval/corpus`
- [x] Phase-69 handoff recorded (decision article Phase-69 Handoff section)

## Constraints

- **Deterministic scoring path only, no LLM judge** (per [[eval-validity-verdict]] — LLM judges are blind here). Prevents: re-introducing the blind instrument the verdict already condemned.
- **READ-ONLY emitter** — shasum-proven, zero writes to the kit's own `.dev-wiki`/`.nana`. Prevents: an "instrument" that mutates the thing it measures (the Phase-67 isolation failure mode).
- **Substrate = real session transcript jsonl**, not `enforcement.log`. Prevents: the Phase-66 schema-gap (record = decision, not action) and supplies the trace provenance that clears the Phase-65 corpus-duplication bar.
- **Controls validate the RULER, not harness value.** Prevents: repeating the Phase-65 fixture-scoring error (scoring the harness off planted fixtures).
- **Sentinel, not 0, for absent enforcement data.** Prevents: a missing-log silently reading as "zero blocks" (a false signal).
- **No harness verdict claimed from Phase 68.** Prevents: claiming representativeness Phase 68 deliberately does not provide.

## Checkpoints

- **After T1 (FIRST/checkpoint):** report the proxy→field feasibility from `SCHEMA-NOTES.md`. If a needed human-turn / AskUserQuestion / tool-use field is absent, STOP and pivot to a logging-hook approach before building the emitter.
- **If the controls cannot pass deterministically:** PARK like Phase 66 (encode a committed runnable check), do NOT reach for an LLM judge.

## Assumptions

- The transcript jsonl distinguishes human turns, AskUserQuestion/escalation events, and tool-uses by event structure. If false: STOP + pivot to a logging-hook that emits the needed structure (T1 resolves this).
- The redirect proxy is computable from event STRUCTURE alone. If false: ship it as `null` + deferred to Phase 69 (T3 resolves this).
- A deterministic keyword detector suffices for the same-day-close / look-ahead `surfaced` decision. If false: PARK the detector (encode a runnable check).

## Phase-69 Handoff

Phase 69 = use the **validated** instrument for the actual harness measurement: a **live off/on** (harness-disabled vs harness-enabled) run on a **real consuming-project** (screener or successor), **n>1** paired runs, the **harness verdict**, executing the `eval/comparison`+`eval/reasoning` **apparatus disposition**, and building **Frontier 1** (the escalation layer the ruler will measure). These all need representativeness, which Phase 68 deliberately does not provide.

## Notes

- This phase reframes the strategic handover's dependency order: the handover ranked Frontier 1 (escalation-classifier) highest and the measurable foundation lowest; the corrected order builds the ruler (Frontier 0) first because the classifier is unfalsifiable without it.
- Lineage: closes the [[eval-validity-verdict]] gap (instrument MIXED — binary corpus sensitive, LLM-judge blind) with a non-blind ruler; respects the Phase-65 `eval/comparison` tombstone; resolves the Phase-66 representativeness/schema-gap park by separating instrument-validation (here) from harness-measurement (Phase 69).
- The session transcript is the chosen substrate precisely because it carries firing + agent action + human response in one ordered stream — the real trace provenance that distinguishes a real eval from corpus duplication.
- Apparatus references: `enforcement.log` schema `{schema_version, ts, hook, action, reason, phase}` (Phase 65); HOME-override isolation pattern (`tests/test_install.sh`).
- **Delivery (2026-05-29):** all 5 tasks `[x]`, all exit criteria met. T1 GO (schema-probe passes on a real transcript, no logging-hook pivot). Emitter 14/14 green; `make test` 18→19 scripts, `make eval` 52/52 unchanged. New repo-only `eval/amplifier/` tree (8 files; NOT in install.sh — consistent with the benchmark-only split). DISCOVERY: the `test_templates.sh` README script-count drift-guard required a manual README bump 18→19 when the test was added (no auto-sync). READY FOR COMPLETION — status held `active` pending the delivery gate.
