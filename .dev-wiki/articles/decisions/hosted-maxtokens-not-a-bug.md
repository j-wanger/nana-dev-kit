---
title: "Hosted maxTokens is NOT a bug (Ph119 T9 verification)"
aliases: [hosted-maxtokens-not-a-bug, ph119-t9, maxtokens-verification]
category: decisions
tags: [pi-agent, pi-sdk, gui-harness, maxtokens, verification, phase-119]
parents: [phase-119-pi-ux-felt-quality-ecosystem]
created: 2026-07-01
updated: 2026-07-01
source: debrief
confidence: high
---

## Context

The [[pi-gui-setup-improvements]] research finding flagged a suspected defect: "the hosted path leaves `maxTokens` UNSET = an output-truncation bug." Phase 119 T9 was a fix-only-if-real verification of that hypothesis.

## Decision

**REFUTED — not a bug, no fix, no regression test.** Verified by source inspection: nana overrides `maxTokens` ONLY on the LOCAL path (`resolveMaxTokens` → `buildLocalModelsJson`; the local `models.json` default is a too-low 2048, so the override is needed there). The HOSTED path uses the model straight from Pi's `ModelRegistry`, whose generated table carries each model's REAL max-output — `anthropic.models.js`: 8192 (older Claude), 64000/128000 (Claude 4.x extended), 4096 (legacy); other providers 131072/262144/65536. So "unset by nana" = "the model's real limit" = correct, NOT truncated.

The load-bearing insight: a UNIFORM nana `maxTokens` override would be the ACTUAL bug — it would clamp a 128000-max model down to 8192. The safe design is exactly what ships: override only where the local default is wrong, defer to the registry everywhere else. Alternative REJECTED: apply a nana-wide `maxTokens` "fix" (would cause the very truncation the finding feared).

## Consequences

- No code change; a not-a-bug note is recorded in `resolveMaxTokens`' doc comment (so a future reader doesn't re-raise the finding).
- No truncation exists to pin, so no regression test was added (fix-only-if-real).
- Closes the last open item from the [[pi-gui-setup-improvements]] Tier-1 list; captured in memory `mem_pyUha2cato8s`.
