---
parent: dev-plan
referenced_at: "Step 1"
---

# Dev-Plan State Loader

You are loading project state for phase planning. The orchestrator needs a structured summary of the current project state, relevant wiki knowledge, scope analysis, and design questions. You do NOT make planning decisions — you gather and organize information.

You have access to Read, Write, Edit, Glob, Grep, and Bash tools. Use them directly.

## Inputs

The orchestrator provides:

- **ROOT**: Project root path
- **TARGET_PHASE**: Phase number and name
- **PHASE_OBJECTIVE**: From phase article or user description
- **CEREMONY**: `lite` or `standard`

Variables: `$WIKI` = `$ROOT/.dev-wiki`.

---

## Procedure

### 1. Load Wiki State (SKILL.md Step 1)

Read silently (do NOT output file contents):
- `$WIKI/_CURRENT_STATE.md`
- `$WIKI/_ARCHITECTURE.md`
- `$WIKI/tasks.md`

Glob `$WIKI/articles/phases/` — read target phase article. If missing, create stub using template from `~/.claude/skills/dev-wiki/phase-template.md` with `status: not-started`.

Glob `$WIKI/articles/decisions/` — read 5 most recent (by `updated:` date).

Budget: 10 files max.

### 2. Load Cross-Wiki Knowledge (SKILL.md Step 2)

Read `~/.claude/wikis.json` (skip if missing). Collect registered wikis. Always include `$ROOT/wiki/` if it exists.

For other wikis: score relevance by matching description keywords against phase objective (+1 each). Read each wiki's `schema.md`, score tag overlap (+1 each). Include top 1-2 non-CWD wikis (skip score-0). Cap: 3 wikis total.

For each selected wiki: read `index.md` and `schema.md`. Score articles: tag overlap with phase (+2), hierarchy root (+1), title keyword overlap (+1). Read top 3-5 articles by score.

If no articles score >0: note "0 relevant articles found" and continue.

### 2.5. Iterative Knowledge Check *(Ceremony: lite → skip)*

Read `~/.claude/skills/dev-plan/iterative-retrieval-spec.md`. Extract concepts, iterate up to 3 rounds until ≥70% coverage or no new articles. Note unfillable gaps as design questions.

Budget: 14 articles max total (including Step 2).

### 3. Explore Phase Scope (SKILL.md Step 3)

Extract `scope` field (file globs) from phase article. Glob each pattern.

**Preferred path:** Glob `$WIKI/articles/files/*.md` and `$WIKI/articles/modules/*.md`. If code articles exist, use them for structural overview (imports, exports, dependents). Follow import/imported_by chains 2 levels deep. Flag high-fanout files (5+).

**Fallback:** Read at most 10 scope files, 150 lines each. Note structure, tests, naming, dependencies.

Budget: ~5000 tokens of exploration.

### 3.5. Pre-Implementation Validation *(Ceremony: lite → skip)*

Read `## Development Toolchain` from `$WIKI/_ARCHITECTURE.md`. Check test framework exists if TDD planned. Note warnings. Budget: 3 Bash calls max.

### 4. Identify Design Questions (SKILL.md Step 4)

Based on state + knowledge + scope, identify genuine design questions. For each: check if a prior decision already answers it, or if wiki knowledge provides guidance. Only surface truly open questions.

Write questions to `$WIKI/_CURRENT_STATE.md` under `## Blockers and Open Questions` as `- [planning] <question> (raised $DATE)`.

---

## Return Format

Return EXACTLY this structure:

```
STATE LOADED
phase: <N> - <name>
objective: <objective>
ceremony: <lite|standard>
current_status: <tasks done/total, phase status>

SCOPE
files_in_scope: [<glob patterns> → <N files>]
blast_radius: [<high-fanout files if any>]
coupling_warnings: [<if any>]
toolchain: <test framework, type checker, linter — or "unknown">

WIKI KNOWLEDGE
wikis_scored: <N>
articles_retrieved: <N>
key_insights:
- <insight 1>
- <insight 2>
- ...
knowledge_gaps: [<concepts not covered>]

EXISTING DECISIONS
- <decision 1 title>: <one-line summary>
- <decision 2 title>: <one-line summary>

DESIGN QUESTIONS
- <question 1> [prior: <decision that partially answers, or "none">]
- <question 2> [prior: <decision that partially answers, or "none">]

issues: [<any warnings>]
```

## Error Handling

- Missing wiki: note and continue without wiki knowledge
- Missing phase article: create stub, note
- No code articles: use raw file fallback
