---
title: Monorepo Skill Distribution
status: accepted
confidence: high
date: 2026-05-21
source: plan
tags: [architecture, install, distribution]
---

# Monorepo Skill Distribution

## Decision

Bundle dev-wiki skills, knowledge-wiki skills, and Python scaffolding in a single repo (nana-dev-kit) with modular install flags rather than maintaining separate repos with cross-repo coordination.

## Context

Three options evaluated: (1) monorepo with modular flags, (2) multi-repo with shared installer, (3) multi-repo with independent installers. A 3-agent architectural review analyzed installer mechanics, user adoption, and maintenance/CI implications.

## Rationale

- **Installer mechanics:** Multi-repo requires git submodules, curl, or co-located directory assumptions. All add friction. Monorepo is just `cp -r` with no external deps.
- **Adoption:** Soft coupling between systems (spec references dev-wiki, py-init suggests dev-init) means users benefit from co-installation. Modular flags (`--core-only`, `--no-python`) give granularity without requiring 4 repos.
- **Maintenance:** Single CI pipeline catches integration bugs immediately. Multi-repo creates diamond dependency on memory_server interfaces requiring coordinated version bumps.
- **Scale threshold:** At 22 skills / 111 files, coordination cost of multi-repo swamps modularity benefit. Revisit at 100+ skills or multiple contributors with different release cadences.

## Consequences

- install.sh grows to handle 17 skill directories via module-group iteration
- `~/.claude/skills/` on developer machine becomes a deployed artifact, not the source of truth
- Source repos (~/dev-wiki, ~/knowledge-wiki) become historical — monorepo is canonical after import
- Future skill changes must be made in nana-dev-kit/templates/.claude/skills/

## Module Dependency Graph

```
core (no deps) → python (requires core)
                → dev-wiki (requires core)  
                → knowledge-wiki (requires core)
```

## Related

- [[import-source-canonical-installed]] — import from ~/.claude/skills/ (ahead of source repos)
