---
title: "/init router belongs in CORE_SKILLS"
aliases: [init-router-in-core, init-router-core-skill]
category: decisions
tags: [init, routing, install, core-skills]
parents: [phase-39-resilience-health-probes]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: high
---

## Context

The `/init` command needs to route to either `/py-init` or `/ts-init` based on filesystem markers (pyproject.toml, package.json, etc.). It's language-agnostic routing logic that doesn't depend on either target skill being installed — it detects markers and dispatches.

## Decision

Place the `/init` router in CORE_SKILLS (installed by default, regardless of --no-python or --no-typescript flags). The skill detects language markers, handles polyglot cases (both detected → user choice), and dispatches via `Skill(skill="py-init")` or `Skill(skill="ts-init")`. If the target skill isn't installed, the Skill tool call will fail gracefully with a clear error.

Rejected alternatives:
- **Put in each language module** — duplicates routing logic, requires keeping two copies in sync.
- **Put in a "meta" module** — over-engineering for a single routing skill; CORE_SKILLS already serves this purpose.

## Consequences

- `/init` always available regardless of installed language modules.
- If user runs `/init` but hasn't installed the detected language module, they get a clear error pointing them to install.sh flags.
- install.sh cp -r pattern means the skill dir just needs to exist in templates/.claude/skills/init/.
- MANIFEST needs init entry with description comment.
