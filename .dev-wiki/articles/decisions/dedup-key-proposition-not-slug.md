---
title: "Dedup key is proposition content, not source slug"
aliases: ["dedup-key-proposition-not-slug", "content-keyed-dedup"]
category: decisions
tags: [memory, hot-cache, working-knowledge, dedup, curation, bug-fix]
parents: [phase-62-harden-hot-cache-curation]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Context

`working-knowledge-spec.md` and the other curation touchpoints codify a dedup rule keyed on the `source:` slug: "if an entry with the same `source:` slug exists, increment `uses` instead of adding." This rule is wrong-when-followed. Distinct facts legitimately share a source phase — the live cache proves it: `phase-45` has 6 distinct entries under one source slug (eval calibration, IRON RULES conflict detection, judge variance, harder-scenario design, per-rule regression, status enum). Slug-keyed dedup would collapse those 6 into 1, silently destroying knowledge on a mandatory file. The live cache also shows 12 duplicate `source:` slugs present despite three paths all claiming "dedup by source slug" — the rule is both wrong and unenforced.

## Decision

Dedup MUST key on the **normalized proposition text only**, never the `source:` slug. Normalization strips the leading `- [uses: N] ` prefix, surrounding whitespace, and trailing punctuation so genuine duplicates collide while distinct same-topic facts (the 6 `phase-45` entries that all mention "heuristic") do not. On an exact-duplicate match the curator removes one copy and **keeps the survivor with the higher `uses` count** (re-emitting it in the exact `[uses: N]` token format other machinery parses). Fuzzy near-duplicates are NOT auto-removed — they are flagged to the stale queue (advisory) to avoid false-positive data loss.

Alternative rejected: keeping slug-keyed dedup (the status quo) — it is the source bug; following it as documented would collapse legitimate distinct facts.

## Consequences

A regression test asserts distinct-facts-same-slug survive (the `phase-45` ×6 fixture) alongside exact-dup removal. The corrected rule is documented in exactly one place ([[harden-hot-cache-curation-deterministic]] consolidates policy into `working-knowledge-spec.md`); the seed, carry-forward, and eviction-spec touchpoints reference it instead of restating it. The wrong "increment uses instead" directive is removed kit-wide (grep-asserted empty).
