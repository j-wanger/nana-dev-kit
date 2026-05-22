---
title: Global hooks with project-level opt-in
status: accepted
confidence: high
date: 2026-05-22
source: plan
tags: [hooks, enforcement, distribution]
---

# Global hooks with project-level opt-in

## Context

Enforcement hooks need to be distributed to developer machines. Three options: (1) global install to ~/.claude/hooks/ with per-project opt-in marker, (2) project-level only (requires scaffolding per project), (3) manual copy by user.

## Decision

Install hooks globally to `~/.claude/hooks/` via install.sh but gate enforcement on presence of `.claude/enforce` marker file in CWD. Hooks check CWD for marker at entry — if absent, exit 0 immediately (fail-open).

## Rationale

- **Existing projects:** Global install works for all projects without re-scaffolding. Opt-in via `touch .claude/enforce` is zero-friction.
- **Safety:** Fail-open default means hooks never block work in projects that haven't opted in.
- **Distribution:** Consistent with install.sh module-group pattern — hooks are another module alongside core, python, dev-wiki, knowledge-wiki.
- **Alternative rejected:** Project-level only requires adding hooks to every project's .claude/hooks/ directory, creating maintenance burden and version drift.

## Consequences

- install.sh gains a hooks module (requires core dependency)
- ~/.claude/hooks/ becomes a new managed directory alongside skills/ and rules/
- Per-project enforcement requires explicit opt-in (`.claude/enforce` marker)
- Hooks must be registered in ~/.claude/settings.json (hooks arrays)
- Existing hook templates in templates/.claude/hooks/ remain project-level; enforcement hooks are global

## Related

- [[monorepo-skill-distribution]] — same one-install-many-projects philosophy
