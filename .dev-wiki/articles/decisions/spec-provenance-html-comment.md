---
title: "Spec provenance via HTML comment"
aliases: [spec-provenance-marker]
category: decisions
tags: [spec, provenance, enforcement, backward-compat]
parents: [phase-29-v051-grade-push]
created: 2026-05-23
updated: 2026-05-23
source: plan
confidence: medium
---

## Context

Specs lack a machine-readable approval marker. enforce-spec.sh checks for specs/<slug>.md existence and open tasks, but cannot distinguish an approved spec from a draft. The v0.5.0 critique flagged this as an enforcement gap. There are ~20 existing specs without any provenance marker.

## Decision

Use an HTML comment `<!-- nana:approved YYYY-MM-DD -->` as the first line of approved specs. Enforce via OR logic in enforce-spec.sh: marker present OR exit-criteria present (backward compat). This avoids reformatting existing specs with YAML frontmatter.

Alternative rejected: add YAML frontmatter to all specs. Rejected because it requires format changes across ~20 existing files and specs are Markdown documents without existing frontmatter convention.

## Consequences

- New specs get marker automatically via /spec Step 6
- Existing 20 specs continue to pass enforcement via exit-criteria fallback
- OR logic means enforcement is weaker for old specs (no provenance check) but no breakage
- Future specs will have machine-readable approval date for audit trails
