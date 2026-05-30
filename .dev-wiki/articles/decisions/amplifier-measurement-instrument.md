---
title: "Amplifier Measurement Instrument — build Frontier 0 (the ruler) before any cognitive frontier"
aliases: [amplifier-measurement-instrument, frontier-0, proxy-vector-emitter, real-transcript-proxy-emitter]
category: decisions
tags: [eval-validity, amplifier-vision, measurement, frontier-0, phase-68]
parents: [phase-68-amplifier-measurement-instrument]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Context

The amplifier vision needs a substrate of cognitive frontiers (escalation-classifier, the strategy map, the recognition loop). The strategic handover ranked the **escalation-classifier (Frontier 1)** highest and the cheap measurable foundation lowest — but that dependency order is **backwards**: the classifier is *unfalsifiable without a ruler*, the classifier needs the map, the map needs the recognition loop, and none of it can be scored against reality without a measurement instrument first. Phase 63 already proved the eval situation we are stepping into: the instrument is **MIXED** — the binary corpus is sensitive but every LLM-judge eval is blind-by-construction (a real +0.5 and a worthless feature read identical). Phase 65 killed a scored fixture-replay as **corpus-duplication** (it only re-ran the binary `lifecycle` corpus and added nothing). Phase 66 parked the enforcement scorer because its log was structurally unrepresentative (the kit's own `.dev-wiki` samples the maintainer editing the kit, not consuming-project agentic work) and **schema-gapped** (a record captures the hook's DECISION, not the agent's subsequent ACTION). Building any cognitive frontier now — without first having a deterministic, control-validated ruler grounded in *real* trace provenance — would repeat exactly those three failures. So before Frontier 1, build **Frontier 0: the measurement instrument**.

## Decision

Build **Frontier 0 first** — a deterministic, READ-ONLY proxy-vector emitter at `eval/amplifier/emit-proxy-vector.*` — and validate the *instrument* (not any harness verdict) via a positive/negative control pair, in Phase 68. Five sub-decisions:

1. **Frontier 0 before Frontier 1.** Build the ruler before the escalation-classifier the handover ranked highest. The handover's dependency order was backwards and the classifier is unfalsifiable without a ruler. Alternative considered (follow the handover and build the classifier first) rejected: unmeasurable ⇒ unfalsifiable.

2. **Substrate = the session transcript jsonl, NOT `enforcement.log`.** The transcript carries hook-firing + agent-action + human-response in one ordered stream, so it closes the **Phase-66 firing→action schema-gap** and supplies the **real trace provenance** that clears the **Phase-65 corpus-duplication bar** (the killed fixture-replay only duplicated the binary corpus). The emitter ingests a real Claude Code transcript + final git/test/lint state (+ optional `enforcement.log`) and emits a 4-group proxy-vector JSON: **mechanical** (tests-pass, lint count, commits-to-first-green, reverts/fixups by git-STRUCTURE not message-text), **interaction** (human-turns, AskUserQuestion/escalation count, tool-uses, a redirect proxy shipped only if computable from event STRUCTURE else `null`+deferred), **enforcement** (block-count from `enforcement.log` or an absent-SENTINEL, *not* 0), **ground_truth** (a `surfaced` bool for the same-day-close / look-ahead decision, scoped to escalation EVENT boundaries, not raw text).

3. **Validate with a positive/negative control pair**, minimally different, anchored on a real domain decision (the screener same-day-close), with a **differential-flip assertion** — the `rm -rf` guard-probe analog. The controls validate the **RULER**; they are explicitly **NOT** used to score harness value (that would repeat the Phase-65 fixture-scoring error). The pair must flip the detector AND ≥1 interaction proxy (value-asserted, not exit-code-only).

4. **Deterministic scoring path only — no LLM judge**, per the [[eval-validity-verdict]] (LLM judges are blind here). If the controls cannot pass deterministically, **PARK** (encode a committed runnable check, the Phase-66 pattern) rather than reach for an LLM judge.

5. **Separate instrument-validation from harness-measurement.** Phase 68 validates the instrument against *planted* ground truth (n=1 acceptable). Phase 69 does the actual harness measurement on a *real consuming-project* (n>1). This resolves the Phase-66 representativeness park by **NOT claiming any harness verdict from Phase 68**.

## Consequences

- **Phase 68 is TESTS/TOOLING only:** a new read-only emitter + control fixtures + make-test wiring + scope-honesty guards. It touches `eval/amplifier/` exclusively — no edits to `eval/comparison|corpus|reasoning`, no hooks, no `modules.json`/`settings.json`. `make eval` stays at 52; `test_registration` + `test_settings_template` stay green untouched.
- **The instrument earns its own falsifiability:** the control pair *is* the instrument's functional test (the only thing Phase 68 asserts is "the ruler flips when the underlying decision flips"), not a claim about whether the harness helps. This keeps the burden-of-proof on the instrument, not on a verdict it isn't entitled to make.
- **Three deferred unknowns become Phase-69 work, all representativeness-dependent:** the live off/on (harness-disabled vs harness-enabled) run, n>1 paired runs, the harness verdict, executing the `eval/comparison`+`eval/reasoning` apparatus disposition, and building Frontier 1 (the escalation layer the ruler will measure). Phase 68 deliberately does not provide representativeness; Phase 69 must.
- **Three plan-time knowledge gaps, each with an owner:** the exact transcript jsonl schema (T1 resolves; STOP+pivot-to-logging-hook if a needed human-turn/AskUserQuestion/tool-use field is absent); whether the redirect proxy is computable from event structure alone (T3 resolves, defer to `null` if it needs semantics); whether a deterministic keyword detector suffices for the same-day-close decision (PARK if not).
- **Tombstone respected:** `eval/comparison/` remains a Phase-65 "do not rebuild" tombstone; the amplifier instrument lives under a fresh `eval/amplifier/` and draws its distinguishing value from trace provenance, not fixture replay.
- **Phase-69 handoff (recorded):** Phase 69 = use the validated instrument for the actual harness measurement — a live off/on run on a real consuming-project (screener or successor), n>1 paired runs, the harness verdict, the `eval/comparison`+`eval/reasoning` apparatus disposition, and Frontier 1 (the escalation layer the ruler measures). These need representativeness, which Phase 68 does not provide.

Related: [[eval-validity-verdict]], [[phase-63-remediation-roadmap]], [[instrument-not-score-enforcement-firing-substrate]], [[park-enforcement-scorer-signal-insufficient]], [[eval-validity-instrument-sensitivity-probe]].
