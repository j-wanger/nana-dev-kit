---
title: Import Source — Canonical Installed Versions
status: active
confidence: high
date: 2026-05-21
source: plan
tags: [architecture, import, source-of-truth]
---

# Import Source — Canonical Installed Versions

## Decision

Import skill files from `~/.claude/skills/` (the installed versions), not from `~/dev-wiki` or `~/knowledge-wiki` source repos.

## Context

Both sources exist. md5 comparison showed:
- dev-plan SKILL.md and implementation-guide.md diverge (installed versions modified by Phases 12-14 of nana-dev-kit)
- knowledge-wiki files match their source repo

## Rationale

The installed files at `~/.claude/skills/` include all changes made during nana-dev-kit's development (T0 rewrite, self-check-checklist ceiling, state-loader-prompt, task-schema, artifact-writer-prompt — all added in Phases 12-14). The source repos are behind and lack these modifications. Importing from source repos would regress functionality.

## Consequences

- Source repos (~/dev-wiki, ~/knowledge-wiki) become historical after import
- Any future skill development happens in nana-dev-kit/templates/.claude/skills/
- MANIFEST generated at import time serves as the baseline for drift detection

## Related

- [[monorepo-skill-distribution]] — the monorepo architectural decision this implements
