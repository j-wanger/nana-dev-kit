---
title: "Phase 35: ts-init Implementation"
aliases: []
category: phases
tags: [typescript, ts-init, scaffolding, skill, biome, vitest, pnpm]
parents: [phase-34-upstream-sync-store-opt-ts-design]
created: 2026-05-25
updated: 2026-05-25
source: plan
status: completed
scope: ["templates/AGENTS-ts.md", "templates/.claude/skills/ts-init/*", "templates/.github/workflows/ci-ts.yml", "install.sh", "templates/.claude/skills/MANIFEST", "tests/test_install.sh", "tests/test_templates.sh"]
entry_criteria: "Phase 34 complete, design spec approved at specs/ts-init-design.md, 201 tests passing, 47/47 eval"
exit_criteria: "AGENTS-ts.md exists with pnpm/biome/vitest/tsc, ts-init SKILL.md exists with two modes and cross-refs, scanner.md has 10 dimensions with React/monorepo paths, transform.md covers upgradeable dimensions, ci-ts.yml has full CI pipeline, install.sh --dry-run shows ts-init and --no-typescript excludes it, make test passes"
---

# Phase 35: ts-init Implementation

## Objective

Implement the ts-init TypeScript scaffolding skill following the design spec at specs/ts-init-design.md. Two-mode skill (new project scaffold + existing project retrofit) with 10-dimension feasibility scanner, AGENTS-ts.md template, CI template, and install.sh integration. Direct implementation from approved design spec.

## Scope

Files and modules affected:
- `templates/AGENTS-ts.md` -- TypeScript-specific AGENTS template (pnpm/Biome/Vitest/tsc)
- `templates/.claude/skills/ts-init/SKILL.md` -- Two-mode scaffolding skill (~160-170 lines)
- `templates/.claude/skills/ts-init/scanner.md` -- 10-dimension feasibility scanner
- `templates/.claude/skills/ts-init/transform.md` -- Per-dimension upgrade paths for existing projects
- `templates/.github/workflows/ci-ts.yml` -- TypeScript CI pipeline (pnpm/Biome/tsc/Vitest)
- `install.sh` -- TypeScript module group, --no-typescript flag
- `templates/.claude/skills/MANIFEST` -- ts-init entry
- `tests/test_install.sh` -- ts-init install assertions
- `tests/test_templates.sh` -- ts-init template assertions

## Exit Criteria

- [x] AGENTS-ts.md exists with pnpm, biome, vitest, tsc references (<=95 lines)
- [x] ts-init/SKILL.md exists with two modes, scanner.md/transform.md cross-refs, ES2023 (<=200 lines)
- [x] scanner.md has compatible/upgradeable/blocking categories, React/monorepo paths (<=130 lines)
- [x] transform.md covers biome, vitest, husky/lint-staged transforms (<=120 lines)
- [x] ci-ts.yml has pnpm, biome, tsc, vitest, setup-node
- [x] install.sh --dry-run shows ts-init, --no-typescript and --core-only exclude it
- [x] make test passes (all existing + new ts-init assertions)

## Constraints

- Design resolutions are final: Biome default, tsc only, ES2023, ESM default
- Follow py-init 3-file pattern (SKILL.md + scanner.md + transform.md)
- No bundler in scaffold (tsup/esbuild/vite added by users when needed)
- Scanner warns but does not block React/Next.js projects (Biome JSX rule coverage gap)
- Monorepo detection (pnpm-workspace.yaml, turbo.json, lerna.json) is blocking

## Checkpoints

- After AGENTS-ts.md: verify toolchain sections swapped correctly from AGENTS.md
- After SKILL.md: verify two-mode flow and cross-references to companion files
- After scanner.md: verify all 10 dimensions with correct categories
- After install.sh changes: verify idempotency + flag exclusion with temp HOME

## Assumptions

- py-init 3-file pattern is the correct structure for language scaffolding skills. If false: adapt.
- Design spec covers all implementation details. If false: resolve inline, document in decision article.
- install.sh module-group architecture supports adding a new module group. If false: extend.

## Notes

- Design spec at specs/ts-init-design.md (252 lines, approved)
- 4 design questions resolved: Biome default, tsc only, ES2023, ESM default (see [[ts-init-design-resolutions]])
- Tasks 1-5 are independent; Task 6 depends on Tasks 1-5; Task 7 depends on Tasks 1-6
