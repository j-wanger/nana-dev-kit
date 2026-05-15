---
title: "install.sh"
aliases: []
category: files
tags: [bash]
parents: []
created: 2026-05-15
updated: 2026-05-15
source: scan
type: file
path: "install.sh"
content_hash: "c95f47165aebacce"
exports: []
imports: []
imported_by: []
data_reads: ["templates/.claude/skills/py-init/SKILL.md", "templates/.claude/rules/nana-soul.md"]
data_writes: ["~/.claude/skills/py-init/SKILL.md", "~/.claude/rules/nana-soul.md", "~/.claude/.nana-dev-kit-path"]
---

# install.sh

Global installer script that copies the py-init skill and nana-soul identity rule to `~/.claude/`, and stores the kit's absolute path in `~/.claude/.nana-dev-kit-path` for later use by `/py-init`.

## Dependencies

External: none (pure bash, no external tools).

## Dependents

None — this is a user-invoked entry point.

## Key Logic

- Resolves its own directory via `BASH_SOURCE[0]` to locate templates regardless of invocation path.
- Creates target directories with `mkdir -p` (idempotent).
- Copies `SKILL.md` with `2>/dev/null || true` to suppress errors if the source is missing.
- Copies `nana-soul.md` without error suppression (required file).
- Writes the kit's absolute path to `~/.claude/.nana-dev-kit-path` so `/py-init` can find templates at scaffold time.
