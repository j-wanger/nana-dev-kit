---
title: "TypeScript design spec before implementation"
aliases: [ts-init-design-first, typescript-design-spec]
category: decisions
tags: [typescript, ts-init, design, scaffolding]
parents: [phase-34-upstream-sync-store-opt-ts-design]
created: 2026-05-24
updated: 2026-05-24
source: plan
confidence: high
---

## Context

The py-init skill (168 LOC SKILL.md + scanner.md + transform.md = 368 lines) scaffolds Python projects with pyproject.toml, ruff, mypy, pytest. TypeScript is the next target language for project scaffolding. The question: build ts-init by cloning py-init and adapting, or design deliberately first.

## Decision

Produce a design spec at `specs/ts-init-design.md` before any implementation. The spec maps every py-init assumption to its TypeScript equivalent or N/A: package manager (npm/pnpm/bun), config (tsconfig.json + package.json), project layout (src/ convention), linter/formatter (eslint+prettier vs biome), type checker (tsc vs mypy), test runner (vitest/jest), pre-commit hooks.

**Alternative rejected:** Clone py-init and adapt directly. Rejected because py-init assumptions (pyproject.toml single config file, ruff as linter+formatter, mypy as separate type checker) don't map 1:1 to TypeScript (tsconfig.json + package.json, eslint vs biome, tsc-is-the-compiler). Inheriting Python assumptions would confuse TypeScript developers.

**Rationale:** The cost of getting scaffolding wrong is high — developers use it on day one of every project. A design spec surfaces the assumption mismatches before implementation locks them in.

## Consequences

- Implementation is deferred to Phase 35+, allowing the design spec to be reviewed and refined.
- The spec must address: AGENTS.md template strategy, install.sh module group design, CI template differences, monorepo edge cases (nx, turborepo).
- May recommend refactoring py-init into a language-agnostic /init router, which would be a separate phase.
- Python remains acceptable as a dependency for memory/wiki infrastructure — the TS design covers project scaffolding only.
