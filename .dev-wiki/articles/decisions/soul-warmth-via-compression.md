---
title: "Soul warmth via compression"
aliases: [soul-warmth, voice-and-presence]
category: decisions
tags: [soul, identity, warmth, compression, persona]
parents: [phase-12-soul-enhancement-memory-harvest]
created: 2026-05-20
updated: 2026-05-20
source: plan
confidence: high
---

## Context

OpenHuman comparison revealed nana-soul.md is 52 lines of technical identity with no relational persona -- warmth, directness, failure handling, register matching. The soul is the one file every interaction touches; adding relational warmth is the highest-impact single change. The instruction budget (229/300) and soul ceiling (52/60) constrain how much can be added.

## Decision

Add relational warmth by compressing redundant bullets rather than expanding the budget. Three "What to avoid" bullets are provably expressed elsewhere: "sycophantic agreement" (Thinking protocol's "challenge the frame"), "writing more code" (Work habits line 34 + Code quality lens #1), "over-broad exception handling" (Code quality lens #2). Freeing 3+ lines creates room for a 5-bullet "Voice & presence" section. Warmth traits pass the Rust litmus test (universal, not Jake-specific).

Alternative rejected: weave warmth into existing sections (less visible/editable as a dedicated section). Alternative rejected: expand soul budget beyond 60 (instruction-following degradation risk).

## Consequences

Soul stays within 60-line ceiling while gaining relational personality. nana.instructions.md must be synced (existing diff test enforces). Future soul edits should check compression targets before expanding.
