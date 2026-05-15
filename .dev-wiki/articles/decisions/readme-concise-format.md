---
title: "README concise format"
aliases: [readme format, readme structure]
category: decisions
tags: [documentation, readme]
parents: [phase-01-foundation-and-packaging]
created: 2026-05-15
updated: 2026-05-15
source: plan
confidence: high
---

## Context

The README needs to document the kit but the level of detail was debated. Templates are self-documenting, and self-test.md already serves as the detailed reference.

## Decision

README uses a concise ~40-50 line format with three sections: install, usage, and a 5-layer table. Detailed per-layer documentation is deferred to self-test.md and the templates themselves.

## Consequences

- README stays scannable and approachable for new users
- self-test.md remains the detailed reference
- Templates are self-documenting via their content
- Risk: users may miss nuances only visible in templates (mitigated by self-test.md reference)
