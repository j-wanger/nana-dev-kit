---
title: "Context eval as new runner category"
aliases: [context-eval-new-category]
category: decisions
tags: [eval, context, runner, category]
parents: [phase-21-eval-expansion]
created: 2026-05-22
updated: 2026-05-22
source: plan
confidence: medium
---

## Context

The eval runner has three categories: hook, skill, lifecycle. Phase 21 adds scenarios that validate rule files reach Claude's context window correctly (soul sections present, file-lifecycle installed, session-start guidance output). These could be folded into the hook category (since they often test hook output) or treated as a distinct category.

## Decision

Context eval is a new runner category (not folded into hook/skill). The runner gets a `context)` case branch with `file_exists`, `section_present`, and `hook_output` check types in the checks array. Category counters `CONTEXT_TOTAL`/`CONTEXT_PASSED` are added to the report.

Alternative considered: reuse hook category with tagging. Rejected because the eval report wouldn't distinguish context validation from hook plumbing -- "context 5/5" directly answers "do rules reach the model?" which is a different question than "do hooks execute correctly?"

## Consequences

Eval report gains a fourth category line. Runner complexity increases by ~20 lines for the new case branch. Context scenarios use the same `scenario.json` manifest format but with a `checks` array instead of a single `command`/`expected` pair. Future context scenarios (e.g., pre-compact output, sync-rules propagation) slot in naturally.
