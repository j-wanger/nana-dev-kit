---
title: "Codebase Snapshot 2026-05-28"
aliases: [2026-05-28-codebase-snapshot]
category: status
tags: [snapshot]
created: 2026-05-28
updated: 2026-05-28
---

# Codebase Snapshot 2026-05-28

## Metrics

| Metric | Value |
|--------|-------|
| Version | 0.5.0 |
| Shell scripts | 42 |
| Markdown files | 550+ |
| Eval scenarios | 54 |
| Completed phases | 56 |
| Test suite | make test passes (install 113/118, templates 169/169, harden 10/10, registration 40/40) |
| Eval suite | 54/54 (100%) |

## Recent Commits

See git log for full history. Phases 54-56 completed today.

## Phase 55-56 Changes (since last snapshot)

### Phase 55: Harness Activation Overhaul
- Fixed nana-init installation cascade failure (cp -r needs YAML frontmatter)
- Registered py-review-stop-prompt.md in modules.json
- Created test_registration.sh (40 assertions, bidirectional registration invariant)
- Spec template reformed: Deliverables -> Success Vision, Domain Research Questions added
- Cognitive readiness diagnostic extracted to session-start.d/cognitive-readiness.sh
- Dev-plan empty-wiki guidance added (wiki-bootstrap recommendation)

### Phase 56: Cognitive Activation & Memory Design
- Memory architecture classified: mandatory (working/active knowledge), automatic (dev wiki, knowledge wiki), voluntary (MCP memory)
- Cognitive readiness upgraded from diagnostic labels to actionable Recommended action output
- Dev-plan SKILL.md: wiki_article_count variable with structured recommendation + evidence citation
- Nana-init: wiki-bootstrap nudge at Step 4
- 4 domain articles seeded in wiki/articles/patterns/
- 2 new eval scenarios (context-cognitive-readiness-populated, context-cognitive-readiness-empty)

## Module Summary

See [[2026-05-27-codebase-snapshot]] for full module structure (unchanged in Phases 54-56).
