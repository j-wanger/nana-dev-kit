# Nana Dev Kit — Memory & Knowledge System Architecture

> Generated 2026-05-26 from Phase 43 codebase. Two interconnected persistence systems serving AI-assisted development.

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        NANA DEV KIT — PERSISTENCE LAYER                        │
│                                                                                │
│  ┌─────────────────────────────┐      ┌──────────────────────────────────────┐  │
│  │     MEMORY SYSTEM           │      │      KNOWLEDGE WIKI SYSTEM           │  │
│  │  (episodic, per-session)    │◄────►│  (curated, cross-project)            │  │
│  │                             │      │                                      │  │
│  │  MCP Server (nanaclaw)      │      │  Multi-wiki with semantic indexing   │  │
│  │  SQLite + FTS5 + vec0       │      │  Markdown articles + YAML frontmatter│  │
│  │  768d embeddings            │      │  SQLite FTS5+vec0 index (optional)   │  │
│  └─────────────┬───────────────┘      └──────────────┬───────────────────────┘  │
│                │                                      │                          │
│  ┌─────────────▼──────────────────────────────────────▼───────────────────────┐  │
│  │                    HARNESS INTEGRATION LAYER                               │  │
│  │                                                                            │  │
│  │  Hooks (session-start, enforce-memory, pre-compact)                        │  │
│  │  Skills (dev-plan bridge, debrief harvest, wiki-query, memory-consolidate) │  │
│  │  Rules (working-knowledge.md, active-knowledge.md, active-phase.md)        │  │
│  └────────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## Part 1: Memory System — End to End

### Data Flow Overview

```
                    ┌──────────────────────────────────┐
                    │        MCP TOOL CALLS             │
                    │  (Claude ↔ memory_server stdio)   │
                    └──────────┬───────────────────────┘
                               │
         ┌─────────────────────┼─────────────────────────┐
         │                     │                          │
         ▼                     ▼                          ▼
┌─────────────────┐  ┌─────────────────┐       ┌─────────────────┐
│  memory_store   │  │  memory_search  │       │  memory_forget  │
│  memory_tag     │  │  memory_verify  │       │  memory_prune   │
│  memory_import  │  │  memory_export  │       │  memory_consolidate│
│                 │  │  memory_stats   │       │  memory_contradict│
└────────┬────────┘  └────────┬────────┘       └────────┬────────┘
         │                    │                          │
         ▼                    ▼                          ▼
┌────────────────────────────────────────────────────────────────┐
│                     storage.py  (930 lines)                    │
│                                                                │
│  ┌────────────┐   ┌──────────────┐   ┌──────────────────────┐  │
│  │   WRITE    │   │    SEARCH    │   │    LIFECYCLE         │  │
│  │            │   │              │   │                      │  │
│  │ store()    │   │ search_fts() │   │ forget()             │  │
│  │ reinforce()│   │ search_vec() │   │ prune()              │  │
│  │ tag()      │   │ search_hybrid│   │ mark_contradiction() │  │
│  │            │   │ search_all() │   │                      │  │
│  └─────┬──────┘   └──────┬───────┘   └──────────┬───────────┘  │
│        │                 │                       │              │
│        ▼                 ▼                       ▼              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              DEDUPLICATION GATE                          │   │
│  │                                                         │   │
│  │  1. _find_exact_duplicate (normalized text match)       │   │
│  │     → match? REINFORCE existing, return early           │   │
│  │                                                         │   │
│  │  2. _find_near_duplicate                                │   │
│  │     ┌─────────────────────┬──────────────────────────┐  │   │
│  │     │ COSINE PATH         │ WORD OVERLAP FALLBACK    │  │   │
│  │     │ (if vec0 available) │ (if no embeddings)       │  │   │
│  │     │                     │                          │  │   │
│  │     │ vec0 KNN LIMIT 50   │ FTS5 MATCH LIMIT 50     │  │   │
│  │     │ cosine_sim(a, b)    │ jaccard(words_a, words_b)│  │   │
│  │     │                     │                          │  │   │
│  │     │ >0.90 → reinforce   │ >0.90 → warn            │  │   │
│  │     │ 0.85-0.90 → warn    │                          │  │   │
│  │     │ <0.85 → create new  │ <0.90 → create new      │  │   │
│  │     └─────────────────────┴──────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    SQLite3 DATABASE                      │   │
│  │                                                         │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐ │   │
│  │  │   memories   │  │ memories_fts │  │ memories_vec  │ │   │
│  │  │  (main table)│  │   (FTS5)     │  │   (vec0)      │ │   │
│  │  │              │  │              │  │   (optional)   │ │   │
│  │  │ id           │  │ content      │  │               │ │   │
│  │  │ content      │◄─┤ tags         │  │ embedding     │ │   │
│  │  │ context      │  │              │  │   float[768]  │ │   │
│  │  │ category     │  │ Auto-synced  │  │               │ │   │
│  │  │ trust        │  │ via triggers │  │ KNN cosine    │ │   │
│  │  │ strength     │  │              │  │ distance      │ │   │
│  │  │ tags (JSON)  │  └──────────────┘  └───────────────┘ │   │
│  │  │ embedding    │                                       │   │
│  │  │ active       │  ┌──────────────┐  ┌───────────────┐ │   │
│  │  │ superseded_by│  │reinforcements│  │     meta      │ │   │
│  │  │ contradicts  │  │ (audit trail)│  │ (schema ver,  │ │   │
│  │  │ access_count │  │              │  │  has_vectors) │ │   │
│  │  │ created_at   │  │ memory_id    │  │               │ │   │
│  │  │ updated_at   │  │ session_id   │  └───────────────┘ │   │
│  │  └──────────────┘  │ timestamp    │                     │   │
│  │                     └──────────────┘                     │   │
│  │                                                         │   │
│  │  DUAL STORE:                                            │   │
│  │    project: ~/.claude/memory_server/memory.db           │   │
│  │    global:  ~/.claude/memory_server/global.db           │   │
│  │    search_all: fanout to both, RRF merge                │   │
│  └─────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────┘
```

### Hybrid Search Pipeline (search_hybrid)

```
Query: "dark mode preferences"
  │
  ├──────────────────────────────────────┐
  │                                      │
  ▼                                      ▼
┌──────────────────────┐    ┌──────────────────────┐
│      FTS5 PATH       │    │     VECTOR PATH      │
│                      │    │                      │
│ _sanitize_fts_query  │    │ embed(query)         │
│   re.sub punctuation │    │   → float[768]       │
│   strip FTS keywords │    │                      │
│   OR-join tokens     │    │ vec0 MATCH (KNN)     │
│                      │    │   → top 2×limit      │
│ BM25 ranking         │    │     by L2 distance   │
│   → top 2×limit      │    │                      │
└──────────┬───────────┘    └──────────┬───────────┘
           │                           │
           └──────────┬────────────────┘
                      ▼
        ┌──────────────────────────┐
        │    RRF FUSION            │
        │                          │
        │  score(id) =             │
        │    α/(k + fts_rank)      │
        │  + (1-α)/(k + vec_rank)  │
        │                          │
        │  α = 0.4  (40% FTS5)    │
        │  k = 60   (rank scale)   │
        │                          │
        │  Tiebreak:               │
        │  1. trust (high>med>low) │
        │  2. strength             │
        │  3. recency              │
        └─────────────┬────────────┘
                      │
                      ▼
        ┌──────────────────────────┐
        │  OPTIONAL: Sidecar      │
        │  (Qwen verification)    │
        │                          │
        │  verify=True?            │
        │  → POST /v1/chat/       │
        │    completions           │
        │  → binary relevant/      │
        │    not-relevant per      │
        │    candidate             │
        │  → filter to relevant    │
        │                          │
        │  Fail-open: on error,   │
        │  return all unfiltered   │
        └─────────────┬────────────┘
                      │
                      ▼
              [ SearchResult[] ]
              score, match_type,
              verified (T/F/None)
```

### Memory Lifecycle in the Harness

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SESSION LIFECYCLE                                     │
│                                                                         │
│  SESSION START                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  session-start.sh                                               │   │
│  │                                                                 │   │
│  │  1. Load dev-wiki state (_CURRENT_STATE.md)                    │   │
│  │  2. Check active phase gates                                    │   │
│  │  3. Memory health probe (3-layer):                             │   │
│  │     ┌──────────────────────────────────────────────────────┐   │   │
│  │     │ Layer 1: jq reads .mcpServers.memory from settings  │   │   │
│  │     │ Layer 2: $MCP_CMD -c "import memory_server"         │   │   │
│  │     │ Layer 3: sqlite3 "SELECT COUNT(*) FROM memories"    │   │   │
│  │     │                                                      │   │   │
│  │     │ → [nana:memory] server healthy (N entries)          │   │   │
│  │     │ → [nana:memory] server broken (<reason>)            │   │   │
│  │     │ → [nana:memory] not configured                      │   │   │
│  │     └──────────────────────────────────────────────────────┘   │   │
│  │  4. Memory search guidance (emit topic from tasks.md)          │   │
│  │  5. Consolidation nudge (if entries ≥ 500, weekly cooldown)    │   │
│  │  6. Clear .loop-state, stale .pending-commit                   │   │
│  │  7. Clear .claude/.memory-consulted (reset enforcement gate)   │   │
│  │  8. Write $HOME/.claude/.session-start-ts                      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  DURING SESSION                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                                                                 │   │
│  │  enforce-memory.sh (PreToolUse, optional)                      │   │
│  │  ┌────────────────────────────────────────────────────────┐    │   │
│  │  │ Activated by: touch ~/.claude/enforce-memory            │    │   │
│  │  │                                                         │    │   │
│  │  │ On Write/Edit of non-allowlisted file:                 │    │   │
│  │  │   .claude/.memory-consulted exists? → allow (exit 0)   │    │   │
│  │  │   missing? → BLOCK (exit 2)                            │    │   │
│  │  │   "Run memory_search before implementation"            │    │   │
│  │  │                                                         │    │   │
│  │  │ Allowlist: .dev-wiki/*, .claude/*, wiki/*, specs/*,    │    │   │
│  │  │            tests/*, *.md, *_test.*, *_spec.*           │    │   │
│  │  └────────────────────────────────────────────────────────┘    │   │
│  │                                                                 │   │
│  │  Agent calls memory_search(query) → sets .memory-consulted     │   │
│  │  Agent calls memory_store() → creates/reinforces entries       │   │
│  │                                                                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  PLANNING (dev-plan Step 8a-bis)                                        │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  memory-bridge.md                                               │   │
│  │                                                                 │   │
│  │  Phase decisions → memory                                      │   │
│  │                                                                 │   │
│  │  1. memory_stats() → budget check (≥400? skip)                │   │
│  │  2. Select 1-3 key decisions from phase planning               │   │
│  │  3. memory_search("bridge-decision <phase-slug>")              │   │
│  │     → find existing entries for same phase                     │   │
│  │  4. memory_store(                                              │   │
│  │       category="custom",                                       │   │
│  │       tags=["bridge-decision", "<phase-slug>"],                │   │
│  │       trust="medium"                                           │   │
│  │     )                                                          │   │
│  │  5. memory_forget(old_id, superseded_by=new_id)               │   │
│  │     → if conflicting entry found                              │   │
│  │                                                                 │   │
│  │  Budget: ≤10 MCP calls per run. Fail-open.                    │   │
│  │  Ceiling: 500 entries advisory.                                │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  DEBRIEF (dev-debrief Step 4.7)                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  memory-harvest.md                                              │   │
│  │                                                                 │   │
│  │  Corrections/preferences/lessons → memory                      │   │
│  │                                                                 │   │
│  │  Extract from conversation:                                    │   │
│  │    harvest-correction  (user override, trust: high)            │   │
│  │    harvest-preference  (workflow style, trust: medium)         │   │
│  │    harvest-lesson      (failed approach, trust: medium)        │   │
│  │    harvest-constraint  (non-obvious boundary, trust: medium)   │   │
│  │                                                                 │   │
│  │  1. memory_search(<topic>) → dedup check                      │   │
│  │  2. memory_store(category="custom", tags=["harvest-<type>"])   │   │
│  │  3. memory_forget(old, superseded_by=new) → if conflict       │   │
│  │                                                                 │   │
│  │  Scope boundaries: NEVER duplicate phase decisions (wiki),     │   │
│  │  task progress (tasks.md), or architecture (ARCHITECTURE.md)   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  CONSOLIDATION (/memory-consolidate)                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Skill-based consolidation (no Python changes to memory_server) │   │
│  │                                                                 │   │
│  │  1. memory_search(broad queries) → gather candidates           │   │
│  │  2. Identify overlapping clusters                               │   │
│  │  3. For each cluster:                                           │   │
│  │     a. Synthesize merged content                                │   │
│  │     b. memory_store(merged entry)                               │   │
│  │     c. memory_forget(originals, superseded_by=merged_id)        │   │
│  │  4. Cap: 10 merges per invocation                               │   │
│  │                                                                 │   │
│  │  Also: consolidator.py (server-side, uses Qwen for merge)      │   │
│  │    → single-link cosine clustering (threshold 0.80)             │   │
│  │    → Qwen synthesizes merged text                               │   │
│  │    → source=CONSOLIDATED, trust=LOW                             │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Part 2: Knowledge Wiki System — End to End

### Two-Stage Article Pipeline

```
                        CAPTURE                              PROCESS
                    ┌──────────────┐                    ┌──────────────────┐
                    │   wiki-add   │                    │   wiki-absorb    │
                    │              │                    │                  │
  Conversation ────►│  identify    │    inbox/          │  Analyst         │
  File/URL    ────►│  extract     │───► entry-1.md ───►│    plan layout   │
  Paste       ────►│  format      │    entry-2.md     │  Verifier (cond) │
                    │              │    entry-3.md     │    credibility   │
                    └──────────────┘                    │  Writer          │
                                                        │    YAML + body   │
                                                        │  Reviewer        │
                                                        │    quality gate  │
                                                        └────────┬─────────┘
                                                                 │
                            ┌────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                          WIKI STRUCTURE                                  │
│                                                                          │
│  <wiki-root>/                                                            │
│  ├── schema.md          Domain definition, tags, hierarchy, conventions  │
│  ├── index.md           Article inventory (TOC)                          │
│  ├── log.md             Append-only changelog                            │
│  ├── articles/                                                           │
│  │   ├── <category>/                                                     │
│  │   │   └── <slug>.md  ◄── Article with YAML frontmatter               │
│  │   │                       ---                                         │
│  │   │                       title: <title>                              │
│  │   │                       category: concept|process|decision|pattern  │
│  │   │                       tags: [tag1, tag2]                          │
│  │   │                       parents: [parent-slug]                      │
│  │   │                       tier: public|private                        │
│  │   │                       status: draft|reviewed|verified|stale       │
│  │   │                       ---                                         │
│  │   │                       <body with [[cross-links]]>                 │
│  │   │                                                                   │
│  │   ├── phases/        Phase lifecycle articles                         │
│  │   ├── decisions/     Decision records with confidence                 │
│  │   └── journal/       Session debrief entries                          │
│  │                                                                       │
│  ├── inbox/                                                              │
│  │   ├── entry-1.md     Raw captures (pending wiki-absorb)               │
│  │   └── .processed/    Archived after absorption                        │
│  │                                                                       │
│  ├── episodic/          Raw session findings (pending wiki-consolidate)   │
│  │                                                                       │
│  └── .wiki-index.db    SQLite FTS5+vec0 search index (optional)          │
│                                                                          │
│  ~/.claude/wikis.json   Multi-wiki registry                              │
│    [{ name, path, last_used }]                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

### Wiki Operations Map

```
┌──────────────────────────────────────────────────────────────────────┐
│                     WIKI SKILL OPERATIONS                            │
│                                                                      │
│  ROUTING                                                             │
│  ┌──────────────────┐                                                │
│  │  knowledge-wiki  │  Routes to correct sub-skill                   │
│  │  (dispatcher)    │  Validates wiki exists                         │
│  └────────┬─────────┘                                                │
│           │                                                          │
│  CREATE   │        READ             MAINTAIN           SEARCH        │
│  ─────    │        ────             ────────           ──────        │
│           │                                                          │
│  wiki-init         wiki-query       wiki-health        wiki-index    │
│  ┌────────┐        ┌──────────┐     ┌──────────┐      ┌──────────┐  │
│  │ 9-Q    │        │ Search   │     │ Dashboard│      │ Build    │  │
│  │ inter- │        │ plan     │     │ Audit    │      │ FTS5+vec │  │
│  │ view   │        │ Memory   │     │ Staleness│      │ SQLite   │  │
│  │ → schema│       │ bridge   │     │ marking  │      │ index    │  │
│  │ → index │       │ Synthe-  │     └──────────┘      └──────────┘  │
│  │        │        │ size     │                                      │
│  └────────┘        │ Working- │     wiki-reorg         wiki-registry│
│                    │ knowledge│     ┌──────────┐      ┌──────────┐  │
│  wiki-add          │ activate │     │ Restruc- │      │ List     │  │
│  ┌────────┐        └──────────┘     │ ture     │      │ Rename   │  │
│  │ Capture│                         │ hierarchy│      │ wikis    │  │
│  │ → inbox│        wiki-bootstrap   │ Retag    │      └──────────┘  │
│  └────────┘        ┌──────────┐     └──────────┘                     │
│                    │ Seed via │                                       │
│  wiki-absorb       │ research │     wiki-consolidate                 │
│  ┌────────┐        │ Gap      │     ┌──────────┐                     │
│  │ inbox  │        │ analysis │     │ episodic/│                     │
│  │ → article│      │ 5 parallel│    │ → inbox  │                     │
│  │ → .processed│   │ agents   │     │ dedup    │                     │
│  └────────┘        └──────────┘     └──────────┘                     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### wiki-query Search Pipeline (with Memory Bridge)

```
User asks domain question
  │
  ▼
┌─────────────────────────────────────────────────┐
│  wiki-query                                      │
│                                                  │
│  PARALLEL SEARCH:                                │
│  ┌──────────────────────┐  ┌──────────────────┐ │
│  │  Wiki Search          │  │  Memory Bridge   │ │
│  │                       │  │                  │ │
│  │  Tier 1/2: hybrid     │  │  memory_search(  │ │
│  │    .wiki-index.db     │  │    query,        │ │
│  │    BM25 + vec0        │  │    limit=5       │ │
│  │                       │  │  )               │ │
│  │  Tier 3 fallback:     │  │                  │ │
│  │    grep + frontmatter │  │  → Memory Results│ │
│  │    keyword scoring    │  │    in context    │ │
│  └──────────┬────────────┘  └────────┬─────────┘ │
│             │                        │            │
│             └────────┬───────────────┘            │
│                      ▼                            │
│  SYNTHESIS:                                       │
│  ┌──────────────────────────────────────────────┐│
│  │  Analyst: search plan from wiki + memory     ││
│  │  Writer:  synthesize answer, cite sources    ││
│  │  Reviewer: verify citations match content    ││
│  └──────────────────────────────────────────────┘│
│                      │                            │
│                      ▼                            │
│  OUTPUT:                                          │
│  ┌──────────────────────────────────────────────┐│
│  │  Answer + sources (article links) + gaps     ││
│  │                                              ││
│  │  If multi-source + multi-turn relevant:      ││
│  │    → offer activation to working-knowledge   ││
│  │    → append [uses: 1] to                     ││
│  │      .claude/rules/working-knowledge.md      ││
│  └──────────────────────────────────────────────┘│
│                                                  │
└──────────────────────────────────────────────────┘
```

### Cross-Wiki Retrieval in dev-plan (Steps 2-2.5)

```
dev-plan: planning Phase N
  │
  ▼
┌───────────────────────────────────────────────────────────────┐
│  Step 2: Load Cross-Wiki Knowledge                            │
│                                                               │
│  1. DISCOVER (cap: 3 wikis)                                   │
│     ┌──────────────────────────────────────────────────┐      │
│     │  ~/.claude/wikis.json → all registered wikis      │      │
│     │  $ROOT/wiki/ → CWD wiki (always included)         │      │
│     │                                                    │      │
│     │  Score each non-CWD wiki:                          │      │
│     │    +1 per keyword overlap (description ↔ objective)│      │
│     │    +1 per tag overlap (schema.md ↔ phase tags)     │      │
│     │    +1 per hierarchy root keyword overlap           │      │
│     │  Include top 1-2 by score (skip score-0)           │      │
│     └──────────────────────────────────────────────────┘      │
│                                                               │
│  2. INDEX                                                     │
│     Read index.md + schema.md from each selected wiki         │
│                                                               │
│  3. MATCH (across all wikis)                                  │
│     Score each article:                                       │
│       +2 per frontmatter tag overlap with phase tags          │
│       +1 per hierarchy root membership                        │
│       +1 per title keyword overlap with phase objective       │
│     Read top 3-5 articles by combined score                   │
│                                                               │
│  Step 2.5: Iterative Completeness (standard ceremony)         │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  Extract key concepts from phase scope (frozen set)   │    │
│  │  Loop (max 3 rounds):                                 │    │
│  │    Coverage = concepts explained / total concepts      │    │
│  │    If ≥ 70%: STOP                                     │    │
│  │    If no new articles found: STOP                     │    │
│  │    Else: retrieve next batch of articles              │    │
│  │  Unfilled gaps → Step 4 design questions              │    │
│  └──────────────────────────────────────────────────────┘    │
│                                                               │
└────────────────────────────┬──────────────────────────────────┘
                             │
                             ▼
┌───────────────────────────────────────────────────────────────┐
│  Step 8f-bis: Active Knowledge (phase-scoped rules file)     │
│                                                               │
│  Filter: 2 of 3 must pass:                                   │
│    - multi-turn relevant (affects multiple tasks)             │
│    - non-obvious (can't derive from code reading)             │
│    - phase-dependent (specific to this phase's work)          │
│                                                               │
│  → .claude/rules/active-knowledge.md (≤40 lines)             │
│    Distilled facts for this phase only                        │
│    Overwritten each phase                                     │
│                                                               │
│  Step 8f-ter: Working Knowledge (cross-phase facts)           │
│                                                               │
│  Facts that FAILED phase-dependent filter but                 │
│  PASSED multi-turn + non-obvious:                             │
│                                                               │
│  → .claude/rules/working-knowledge.md (≤100 entries)          │
│    [uses: N] format, sorted by usage count                    │
│    Pruned: lowest-count entries removed at cap                 │
│    Persists across phases                                      │
└───────────────────────────────────────────────────────────────┘
```

---

## Part 3: Integration Points (Memory ↔ Knowledge)

### Bidirectional Bridge

```
┌─────────────────────────┐              ┌──────────────────────────┐
│    MEMORY SYSTEM         │              │   KNOWLEDGE WIKI          │
│                          │              │                          │
│  memory_store()    ◄─────┼── dev-plan ──┼── decision articles      │
│  (bridge-decision)       │   Step 8a-bis│   Step 8a               │
│                          │              │                          │
│  memory_store()    ◄─────┼── debrief ───┼── journal entries        │
│  (harvest-*)             │   Step 4.7   │   Step 4                │
│                          │              │                          │
│  memory_search()  ──────►├── wiki-query ┼── search results         │
│  (bridge in query)       │   Step 1     │   + Memory Results      │
│                          │              │                          │
│  memory_store()    ◄─────┼── spec ──────┼── approved spec         │
│  (bridge-decision)       │   Step 6     │   in specs/             │
│                          │              │                          │
│  memory_search()  ──────►├── dev-plan ──┼── Step 5 questions      │
│  (inform planning)       │   pre-Step 5 │   informed by memory    │
│                          │              │                          │
└─────────────────────────┘              └──────────────────────────┘

                    ┌──────────────────────────────┐
                    │   WORKING KNOWLEDGE           │
                    │   .claude/rules/              │
                    │   working-knowledge.md        │
                    │                               │
                    │   Fed by:                     │
                    │     dev-plan Step 8f-ter      │
                    │     wiki-query Step 8         │
                    │                               │
                    │   Consumed by:                │
                    │     All rules (always loaded) │
                    │     dev-plan (planning context)│
                    │                               │
                    │   Maintained by:              │
                    │     wk-prune.sh (staleness)   │
                    │     wiki-query (usage bumps)  │
                    │     dev-plan (cap at 100)     │
                    └──────────────────────────────┘
```

### Data Flow Summary

```
SESSION START ─────► memory_search (guidance) ─────► enforce-memory gate
                                                          │
                                                          ▼
                                                    Implementation
                                                          │
PLANNING ──────────► wiki retrieval ───────────────► active-knowledge
(dev-plan)           memory_search                   working-knowledge
                     wiki articles                        │
                          │                               │
                          ▼                               │
                     memory_store ◄───────────────── decisions
                     (bridge-decision)                    │
                                                          │
DEBRIEF ───────────► memory_store ◄───────────────── corrections
(dev-debrief)        (harvest-*)                     preferences
                                                     lessons
                                                          │
                                                          ▼
SESSION END ───────► cooldown advisory ──────────► next session
                     (≥2 phase commits)             reads stored
                                                    corrections
```

---

## Fail-Safety Summary

| Component | Failure Mode | Behavior |
|-----------|-------------|----------|
| MCP server down | memory_search/store fails | Hooks exit 0 (fail-open), skip memory |
| sqlite-vec missing | No vector search | FTS5-only search, no cosine dedup |
| fastembed missing | No embeddings | FTS5-only, word-overlap dedup fallback |
| Qwen sidecar down | No verification | Return unfiltered results (verified=None) |
| Wiki missing | No wiki retrieval | Planning proceeds without wiki knowledge |
| .wiki-index.db missing | No hybrid wiki search | Keyword fallback (grep + frontmatter) |
| enforce-memory marker absent | No memory gate | All writes allowed without memory_search |
| Budget exceeded (≥400) | memory-bridge skips | Decisions still in wiki, just not in memory |

---

## Scale Limits

| Resource | Limit | Enforcement |
|----------|-------|-------------|
| Memory entries | 500 advisory | memory_stats budget guard at 400 |
| Working knowledge | 100 entries / 210 lines | Prune lowest-count on overflow |
| Active knowledge | 40 lines hard cap | Skip if oversized after distillation |
| Bridge decisions | ≤10 MCP calls per run | Hard cap in memory-bridge.md |
| Harvest entries | ≤10 MCP calls per run | Hard cap in memory-harvest.md |
| Consolidation merges | 10 per invocation | Skill-level cap |
| Wiki articles per search | 3-5 (Step 2), up to 14 (Step 2.5) | Budget in dev-plan |
| Wikis per planning | 3 max | Cap in dev-plan Step 2 |
