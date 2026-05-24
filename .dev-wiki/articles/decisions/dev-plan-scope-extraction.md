---
title: "Dev-plan Step 3 scope extraction"
aliases: [scope-exploration-companion]
category: decisions
tags: [dev-plan, skill, ceiling, companion]
parents: [phase-29-v051-grade-push]
created: 2026-05-23
updated: 2026-05-23
source: implementation
confidence: high
---

## Context

dev-plan SKILL.md is at 341/350 lines with zero headroom for future additions. Step 3 (Explore Phase Scope) is a self-contained exploration protocol that can be extracted without breaking the orchestration flow.

## Decision

Extract Step 3 to a companion file `scope-exploration-spec.md`. Replace the inline content with a 2-line Read pointer in SKILL.md. Target is <=330 lines post-extraction (relaxed from 320 per assumption fallback). This follows the established companion extraction pattern used for spec-auto-invoke.md, memory-bridge.md, and adversarial-constraints-prompt.md.

Alternative: compress existing content instead of extracting. Rejected because content is already dense — extraction provides structural headroom without losing clarity.

## Consequences

- SKILL.md drops to <=330 lines, freeing ~10-20 lines for future additions
- scope-exploration-spec.md is a standalone companion (cp -r auto-distributes)
- Cross-skill reference test must validate the new companion path
- No behavioral change — just structural reorganization
