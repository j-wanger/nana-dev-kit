---
title: "Companion metadata format: parent + referenced_at YAML frontmatter"
aliases: [companion-frontmatter, companion-metadata]
category: decisions
tags: [companion, metadata, frontmatter, validation, skills]
parents: [phase-41-harness-hardening-process-safeguards]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: high
---

## Context

92 companion .md files across 26 skill dirs have no machine-readable metadata linking them to their parent skill. When companions are referenced by SKILL.md via `Read` instructions, there is no validation that the reference is bidirectionally consistent (companion knows its parent, parent references the companion). This makes orphaned or mislinked companions invisible.

## Decision

Add YAML frontmatter to each companion file:
- `parent:` = owning skill directory name (e.g., `dev-debrief` for files in `dev-debrief/`)
- `referenced_at:` = step within parent SKILL.md where the companion is consumed (e.g., "Step 2.5")

Cross-skill references (skill A reading skill B's companion) are NOT tracked via the `parent:` field. Instead, Direction B validation (file existence check at test time) covers cross-skill references by verifying every `Read ~/.claude/skills/` path in any SKILL.md resolves to an existing file.

Implementation uses a scripted batch approach: helper script scans SKILL.md Read references, programmatically adds frontmatter. Forward-only -- no retroactive validation of historical entries.

## Consequences

- Enables bidirectional validation: test_companions.sh can verify parent matches directory name
- Companion files remain compatible with cp -r distribution (frontmatter is inert to bash copy)
- ~92 files modified with frontmatter addition (batch scripted, not manual)
- Future companion additions must include frontmatter (enforced by test)
