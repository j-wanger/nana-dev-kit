---
title: "Rename /init to /nana-init and expand to multi-stage orchestrator"
aliases: [nana-init-rename-and-expand, nana-init-rename, init-rename]
category: decisions
tags: [init, onboarding, rename, activation-gap, developer-experience]
parents: [phase-43-unified-init-activation-gap]
created: 2026-05-26
updated: 2026-05-26
source: plan
confidence: high
status: accepted
---

## Context

The /init skill (44-line language router) collides with Claude Code's built-in /init slash command. Users who type /init get Claude Code's built-in behavior, not the Nana skill. Additionally, the current /init only handles language scaffolding -- it does not bootstrap dev-wiki or knowledge wiki, leaving a gap where users must discover and invoke /dev-init and /wiki-init separately.

## Decision

Rename the init/ directory to nana-init/ and expand SKILL.md from a 44-line language router into an ~80-120 line multi-stage orchestrator. The orchestrator detects all component states first (language markers, .dev-wiki/ existence, wiki/ existence), then runs steps in sequence: language scaffold, dev-wiki bootstrap, optional knowledge wiki. Each step is independently skippable. All real work delegates to existing skills via Skill() dispatch -- no logic duplication.

Alternatives considered:
- (a) Keep init/ directory, change only skill triggers to /nana-init: fragile -- directory name still shadows built-in, discovery confusing
- (b) Add --full flag to existing /init: discoverable but most users would never find it
- (c) Post-scaffold advisory only ("run /dev-init next"): preserves modularity but doesn't close the activation gap

## Consequences

- The /init directory no longer exists -- all references must update (modules.json, install.sh, MANIFEST, README, tests, _ARCHITECTURE.md)
- Users get a single /nana-init entry point that bootstraps the full Nana experience
- No logic duplication: language detection stays in nana-init, scaffolding delegates to py-init/ts-init, dev-wiki delegates to dev-init, knowledge wiki delegates to wiki-init
- SKILL.md grows from 44 to ~80-120 lines, still well under the 350-line ceiling
- Old /init muscle memory requires relearning, but the collision fix makes this net positive
