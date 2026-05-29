---
title: "DEADWEIGHT requires affirmative evidence (firing test or ablation), never loadedness or log-absence"
aliases: ["deadweight-requires-affirmative-evidence", "activation-vs-causal-influence", "no-cut-on-log-absence"]
category: decisions
tags: [harness, deadweight, classification, firing-test, ablation, audit, subtraction-test]
parents: [phase-63-harness-assessment-eval-validity]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Context

The utilization audit classifies every component USED / LATENT / DEADWEIGHT. The naive signals are dangerous: "it's loaded every session" proves activation but not causal influence, and "absent from recent logs" is absence-of-evidence, not evidence-of-absence — long-cadence hooks (pre-compact, session-stop, crash-recovery, memory-bridge) fire rarely by design. The working-knowledge entry "verify firing, never just file presence" already warns that a registered-but-dormant component passes a presence test and ships broken; the inverse is equally true — log-absence does not prove deadweight. The `uses` counter is inert (87/100 tied at the floor), so least-`uses`→cut is not a valid ranking either.

## Decision

A DEADWEIGHT verdict requires affirmative evidence: a firing test (synthesize the triggering event, pipe it, assert exit code + side effect) confirming the component never activates, OR an ablation showing removal produces delta ≈ 0. Never loadedness, never recent-log-absence, never least-`uses`. The audit must separate activation (did it fire / get loaded) from causal influence (did removing it change an outcome). When a layer is down to its last surviving member, the subtraction test applies to the scaffolding around it (matcher / judge / dashboard / lifecycle / schema), not to the leaf. Two alternatives rejected: classify-by-loadedness (conflates activation with influence) and classify-by-log-presence (false-negatives every long-cadence component).

## Consequences

Every executed "never-fired" cut must cite an affirmative firing test in its rationale, not log-absence. The never-fired cognitive system (12 HEU + 5 IRON at helpful:0/harmful:0) is not auto-cut on its zero counters: the cut-vs-fix decision turns on whether a cheap wired path to firing exists (a one-line counter-update bug → fix) or it is structurally never-reached (→ cut the scaffolding). The audit reconciles its classified count against an independent inventory computed from source (`INVENTORY=N CLASSIFIED=N MATCH=ok`) so no component is silently dropped from classification.
