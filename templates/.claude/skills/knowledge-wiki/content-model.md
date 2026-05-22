<!-- Canonical content model — SSOT for tiers, lifecycle, and episodic conventions -->
<!-- REFERENCE, DO NOT PASTE. Skills that handle content model logic should link here rather than duplicate definitions. -->

# Content Model

Three-tier content model with five-state article lifecycle and episodic entry conventions.

---

## Article Tiers

Three-tier model for wiki content. The model is architecturally three-tier (episodic, public, private) but only `public` and `private` appear as frontmatter values — episodic entries are implicit by directory (`episodic/`) and follow the Episodic Conventions section below, not the article frontmatter schema.

### Tier Definitions

| Tier | Semantics | Who Writes | Modifiable | Verification |
|------|-----------|------------|------------|--------------|
| `episodic` | What happened — session logs, task traces, research findings, worker outputs | Any caller (Claude Code, Nanaclaw, Qwen) | Append-only, never modified after creation | None required |
| `public` | Domain facts — should be verifiable, citable, shareable | Absorb, bootstrap | Yes, through absorb/reorg | Source-credibility verifier for high-density claims |
| `private` | Personal analysis — trading theses, subjective assessments, decisions without external validation | wiki-add (capture), manual | Yes, through wiki-add/reorg | None required |

### Tier Assignment Rules

| Skill | Default Tier | Rationale |
|-------|-------------|-----------|
| wiki-absorb | Analyst classifies as `public` or `private` based on content | Absorbed articles may contain either factual or personal content |
| wiki-bootstrap | Always `public` | Bootstrap produces domain facts from research |
| wiki-add (capture) | Default `private`, user may override | Session captures are personal analysis by default |
| wiki-add (ingest) | `public` for external refs, `private` for personal notes | Source type determines tier |
| synthesize (contrib) | Inherits dominant tier from source articles | Synthesis of public articles is public; mixed defaults to private |

### Tier Frontmatter

Articles use `tier:` in frontmatter:

```yaml
tier: public | private
```

Episodic entries do NOT use the `tier` field — they are implicitly episodic by virtue of living in `episodic/`. See the Episodic Conventions section below for their frontmatter format.

### Migration

For existing articles created before the tier model: default to `tier: public`, `status: reviewed` (they passed the reviewer subagent already).

### Tier Validation

- wiki-health check 11 (Tier Validity): every article must have `tier` field with value `public` or `private`. Severity: ERROR.
- Episodic entries are exempt from article-level lint checks.

---

## Article Lifecycle

Five-state lifecycle for wiki articles. Every article has exactly one `status` value.

### State Machine

```
draft → reviewed → verified → stale → archived
             ↓                   ↓
             └───────────────────┘ (reviewed can also go stale)
  ↑        ↑                     ↓
  └────────┴─────────────────────┘ (re-verify: back to draft)
```

### State Definitions

| Status | Meaning | Transitions From | Transitions To |
|--------|---------|------------------|----------------|
| `draft` | Newly created, not yet reviewed | (initial), stale | reviewed |
| `reviewed` | Passed reviewer subagent checks | draft | verified |
| `verified` | Human-confirmed or high-confidence | reviewed | stale |
| `stale` | Exceeded domain staleness threshold | verified, reviewed | draft (re-verify), archived |
| `archived` | Explicitly retired, excluded from query | stale | (terminal) |

### Default Status by Skill

| Skill | Initial Status | Rationale |
|-------|---------------|-----------|
| wiki-absorb | `reviewed` | Articles pass reviewer subagent during absorb |
| wiki-bootstrap | `draft` | Bootstrap articles need human review |
| wiki-add (capture) | `draft` | Quick captures need review before promotion |
| wiki-add (ingest) | `draft` | Ingested content needs review |
| synthesize (contrib) | `draft` | Synthesized content needs validation |
| wiki-reorg | Preserves existing status | Reorg restructures, doesn't change lifecycle |

### Staleness Thresholds

Staleness is domain-configurable via `staleness_rules` in the wiki's `schema.md`:

```yaml
staleness_rules:
  default_days: 180
  overrides:
    - tags: [sanctions, pep-lists]
      days: 30
    - tags: [regulations, directives]
      days: 90
    - tags: [typologies, methodologies]
      days: 365
```

Tag-specific overrides take precedence over `default_days`. When an article matches multiple tag overrides (e.g., an article tagged both `sanctions` and `regulations`), the shortest (most aggressive) threshold wins. An article is stale when `days_since_update > applicable_threshold` and its current status is `verified` or `reviewed`.

### Lifecycle Frontmatter

```yaml
status: draft | reviewed | verified | stale | archived
```

### Lifecycle Validation

- wiki-health check 12 (Status Validity): every article must have `status` field with a valid lifecycle value. Severity: ERROR.
- wiki-health check 13 (Staleness Detection): articles with `status: verified` or `reviewed` past their staleness threshold. Severity: WARNING.

---

## Episodic Conventions

Episodic entries are append-only records of what happened — session logs, task traces, research findings, worker outputs. They live in `<wiki_path>/episodic/` and are distinct from articles.

### Key Properties

- Content body is **NEVER modified** after creation (immutable below frontmatter fence)
- Are **NEVER absorbed** directly into articles (legacy tier — not actively fed by current pipeline)
- Are **NOT indexed** in `index.md` (discovered via filesystem listing or search index)
- **ARE searchable** via the search index (Phase 2)
- Carry `worker` and `task_id` fields for provenance tracking

### Directory

```
<wiki_path>/
  episodic/           # Append-only session/worker logs
```

### Filename Pattern

```
YYYY-MM-DDTHH-MM-SS-<slug>.md
```

Use ISO timestamp with hyphens replacing colons (filesystem-safe). Slug follows standard slugification rules.

### Episodic Frontmatter Format

```yaml
---
timestamp: 2026-04-25T14:30:00Z
worker: claude-code | qwen-local | nanaclaw
task_id: research-tbml-typologies-001
tags: [tbml, trade-based-laundering]
wiki: aml-compliance
---
```

#### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| timestamp | ISO 8601 datetime | When the entry was created |
| worker | string | Who created it: `claude-code`, `qwen-local`, `nanaclaw`, or other caller identifier |
| task_id | string | Identifier for the task/research that produced this entry |
| tags | string[] | Topic tags for search and consolidation grouping |
| wiki | string | Name of the target wiki (matches registry name) |

### Body Format

```markdown
## Research: <Topic>

[raw findings, observations, extracted facts, source URLs]

## Sources Consulted
- [url or file path]
- [url or file path]
```

The body structure is flexible — the key requirement is that findings and sources are present. The `## Sources Consulted` section is strongly recommended.

### Relationship to Articles

Episodic entries are NOT articles:
- They do not have `tier` or `status` frontmatter (they are implicitly tier: episodic)
- They are exempt from all article-level lint checks (checks 1-13; check 13 staleness doesn't apply — no status field)
- They are not listed in `index.md`
- They cannot be parents or children in the article hierarchy
