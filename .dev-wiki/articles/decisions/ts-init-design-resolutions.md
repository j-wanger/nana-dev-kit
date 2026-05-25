---
title: "ts-init Design Question Resolutions"
aliases: [ts-init-resolutions, ts-design-resolutions]
category: decisions
tags: [typescript, ts-init, biome, esm, toolchain]
parents: [phase-35-ts-init-implementation]
created: 2026-05-24
updated: 2026-05-24
source: plan
confidence: medium
---

## Context

The ts-init design spec (specs/ts-init-design.md) left 4 open questions: Biome vs ESLint default, build tool beyond tsc, Node.js target version, ESM vs CJS default. These must be resolved before implementation.

## Decision

1. **Biome default.** Matches ruff-as-default pattern from py-init. Scanner detects React/Next.js deps → warns about Biome's thinner JSX rule coverage. ESLint treated as "compatible" (kept if present, not offered as alternative scaffold).

2. **tsc only.** No bundler (tsup/esbuild/vite) in scaffold. Build tool choice depends on project type (library vs app vs fullstack) — too opinionated for a default. Users add bundlers when needed.

3. **ES2023 target (Node 20+).** Node 18 is EOL (April 2025). Node 22 is current LTS. ES2023 covers both Node 20 (maintenance) and Node 22 (active). Module: nodenext.

4. **ESM default** (`"type": "module"` in package.json). CJS is legacy. Modern TS tooling (Vitest, Biome) assumes ESM.

## Consequences

- React/Next.js projects may need manual ESLint setup after scaffold. Scanner warning covers this.
- No bundled output by default — `pnpm build` runs `tsc` only (type checking + declaration emit). Projects needing bundling add tsup/esbuild as a dev dependency.
- Node 18 projects won't work with the default target. Acceptable — Node 18 is EOL.
- CJS consumers need explicit interop. Acceptable — ESM is the standard.
