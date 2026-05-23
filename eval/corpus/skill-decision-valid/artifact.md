---
title: Use YAML for widget definitions
confidence: high
source: plan
created: 2026-01-15
updated: 2026-01-15
tags: [widget, config]
---

# Use YAML for widget definitions

## Decision

Widget definitions will use YAML format rather than JSON or TOML.

## Rationale

YAML supports comments (JSON doesn't), is more human-readable for non-developers, and the team already uses it for CI configuration.

## Alternatives Considered

- JSON: no comments, harder to read
- TOML: less familiar to the team

## Consequences

- Need PyYAML dependency
- Schema validation required (YAML is permissive)
