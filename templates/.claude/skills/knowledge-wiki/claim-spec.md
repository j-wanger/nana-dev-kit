---
parent: knowledge-wiki
referenced_at: "companion"
---

# Claim System Specification (Deprecated)

The claim provenance system was removed in Phase 42. Claims were an intermediate representation compensating for Qwen limitations in the multi-stage pipeline. Claude handles synthesis with inline citations directly.

The current citation convention uses `[source-slug]` inline markers and `sources: [slug1, slug2]` in article frontmatter. See `container/skills/wiki-manager/instructions.md` for the inline citation convention.
