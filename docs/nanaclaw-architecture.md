# Nanaclaw Memory Server — End-to-End Architecture

> Generated 2026-05-26 from vendored copy at `memory_server/` (12 files, 2,376 LOC).
> Near-zero divergence from upstream — only `_sanitize_fts_query` differs (patch at `patches/nanaclaw-sanitize-fts.patch`).

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    NANACLAW MEMORY SERVER                                │
│                    MCP stdio transport                                   │
│                                                                         │
│  Entry: python -m memory_server                                         │
│  Protocol: Model Context Protocol (FastMCP)                             │
│  Transport: stdio (stdin/stdout JSON-RPC)                               │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                        server.py                                 │   │
│  │                    MCP Tool Registration                         │   │
│  │                                                                  │   │
│  │  11 tools: store, search, verify, forget, contradict,           │   │
│  │            tag, stats, export, prune, consolidate, import       │   │
│  └──────────┬──────────┬──────────────────────┬─────────────────────┘   │
│             │          │                      │                          │
│             ▼          ▼                      ▼                          │
│  ┌──────────────┐ ┌──────────────┐  ┌──────────────────┐               │
│  │  storage.py  │ │ embedding.py │  │   sidecar.py     │               │
│  │  930 lines   │ │              │  │   (Qwen LLM)     │               │
│  │              │ │  fastembed   │  │                   │               │
│  │  SQLite3     │ │  or HTTP     │  │  Verify relevance│               │
│  │  FTS5        │ │              │  │  Consolidate text│               │
│  │  vec0        │ │  768-dim     │  │  Extract memories│               │
│  └──────┬───────┘ └──────────────┘  └──────────────────┘               │
│         │                                                               │
│         ▼                                                               │
│  ┌───────────────────────────────────────┐                              │
│  │  ┌─────────┐ ┌────────┐ ┌─────────┐  │                              │
│  │  │memories │ │mem_fts │ │mem_vec  │  │                              │
│  │  │ (table) │ │ (FTS5) │ │ (vec0) │  │                              │
│  │  └─────────┘ └────────┘ └─────────┘  │                              │
│  │         SQLite3 Database              │                              │
│  │  project: ~/.claude/memory_server/    │                              │
│  │           memory.db                   │                              │
│  │  global:  ~/.claude/memory_server/    │                              │
│  │           global.db                   │                              │
│  └───────────────────────────────────────┘                              │
│                                                                         │
│  ┌──────────────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │   consolidator.py    │  │ extractor.py │  │     migrate.py       │  │
│  │   Cluster + merge    │  │ Transcript   │  │   MEMORY.md import   │  │
│  │   via Qwen           │  │ extraction   │  │                      │  │
│  └──────────────────────┘  └──────────────┘  └──────────────────────┘  │
│                                                                         │
│  ┌──────────────┐  ┌──────────────┐                                     │
│  │  models.py   │  │  config.py   │                                     │
│  │  Pydantic    │  │  Dataclasses │                                     │
│  │  enums       │  │  YAML/env    │                                     │
│  └──────────────┘  └──────────────┘                                     │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Module Dependency Graph

```
__main__.py
  └── server.py
        ├── storage.py
        │     ├── models.py (MemoryEntry, SearchResult, StoreResult, enums)
        │     └── (sqlite3, struct, re, nanoid)
        ├── embedding.py
        │     └── (fastembed or httpx, depending on mode)
        ├── sidecar.py
        │     └── (httpx)
        ├── config.py
        │     └── (yaml, dataclasses)
        └── consolidator.py
              ├── storage.py
              ├── sidecar.py
              └── embedding.py

extractor.py
  ├── sidecar.py
  └── models.py

extract_cli.py
  ├── extractor.py
  └── storage.py

migrate.py
  └── storage.py
```

---

## Database Schema

```
┌─────────────────────────────────────────────────────────────────────┐
│                          SQLite3 DATABASE                           │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  TABLE: memories                                             │   │
│  │                                                              │   │
│  │  id              TEXT PK        mem_<nanoid12>               │   │
│  │  content         TEXT NOT NULL  The memory text              │   │
│  │  context         TEXT           When/how it was learned      │   │
│  │  category        TEXT           fact|preference|correction|  │   │
│  │                                 entity|custom                │   │
│  │  trust           TEXT           high|medium|low              │   │
│  │  strength        INT DEFAULT 1  Reinforcement count         │   │
│  │  source          TEXT           user-explicit|observed|      │   │
│  │                                 inferred|imported|           │   │
│  │                                 consolidated                │   │
│  │  source_session  TEXT           Session ID                   │   │
│  │  tags            TEXT           JSON array ["tag1","tag2"]   │   │
│  │  active          INT DEFAULT 1  1=live, 0=superseded         │   │
│  │  superseded_by   TEXT           FK → memories.id             │   │
│  │  contradicts     TEXT           JSON array of mem_* IDs      │   │
│  │  embedding       BLOB           struct.pack('<768f', ...)    │   │
│  │  created_at      TEXT           ISO 8601 UTC                 │   │
│  │  updated_at      TEXT           ISO 8601 UTC                 │   │
│  │  access_count    INT DEFAULT 0  Hit counter (search reads)   │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                    │                                                │
│            ┌───────┼──────────┐                                     │
│            │       │          │                                     │
│            ▼       ▼          ▼                                     │
│  ┌──────────────┐ ┌──────────────────┐ ┌────────────────────────┐  │
│  │ memories_fts │ │  memories_vec    │ │   reinforcements       │  │
│  │  (VIRTUAL)   │ │  (VIRTUAL)       │ │                        │  │
│  │              │ │                  │ │   id      INT PK AUTO  │  │
│  │  FTS5 table  │ │  vec0 table      │ │   memory_id TEXT FK    │  │
│  │  content     │ │  embedding       │ │   session_id TEXT      │  │
│  │  tags        │ │    float[768]    │ │   timestamp  TEXT      │  │
│  │              │ │                  │ │   context    TEXT      │  │
│  │  Auto-synced │ │  Optional:       │ │                        │  │
│  │  via INSERT/ │ │  needs sqlite-vec│ │  Audit trail for       │  │
│  │  UPDATE/     │ │  extension       │ │  reinforcement events  │  │
│  │  DELETE      │ │                  │ │                        │  │
│  │  triggers    │ │  KNN cosine      │ └────────────────────────┘  │
│  │              │ │  distance search │                              │
│  │  BM25        │ │                  │ ┌────────────────────────┐  │
│  │  ranking     │ └──────────────────┘ │   meta                 │  │
│  └──────────────┘                      │                        │  │
│                                        │   key   TEXT PK        │  │
│                                        │   value TEXT            │  │
│                                        │                        │  │
│                                        │   schema_version: "1"  │  │
│                                        │   has_vectors: "0"|"1" │  │
│                                        └────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Core Data Flows

### Flow 1: memory_store() — Full Write Path

```
MCP request: memory_store(content, context, category, trust, tags, scope)
  │
  ▼
server.py: memory_store()
  │
  ├── 1. EMBED (optional)
  │   │
  │   ▼
  │   embedding.py: embed(content)
  │   ┌──────────────────────────────────────┐
  │   │  Local mode:                          │
  │   │    fastembed.TextEmbedding(            │
  │   │      "nomic-ai/nomic-embed-text-v1.5" │
  │   │    ).embed([content])                  │
  │   │    → float[768]                        │
  │   │                                        │
  │   │  Server mode:                          │
  │   │    POST endpoint                       │
  │   │    {"input": content, "model": "..."}  │
  │   │    → float[768]                        │
  │   │                                        │
  │   │  Unavailable: → None                   │
  │   └──────────────────────────────────────┘
  │   │
  │   ▼
  ├── 2. GET CONNECTION
  │   │
  │   ▼
  │   get_conn(config, scope)
  │   ┌──────────────────────────────────┐
  │   │  scope="project" → memory.db     │
  │   │  scope="global"  → global.db     │
  │   │  Cached in _connections dict     │
  │   └──────────────────────────────────┘
  │   │
  │   ▼
  ├── 3. EXACT DEDUP CHECK
  │   │
  │   ▼
  │   storage.py: _find_exact_duplicate(conn, content)
  │   ┌──────────────────────────────────────────────┐
  │   │  SELECT * FROM memories                       │
  │   │  WHERE LOWER(TRIM(content)) = ?               │
  │   │    AND active = 1                              │
  │   │                                                │
  │   │  Match found? → reinforce(conn, existing.id)   │
  │   │    UPDATE strength += 1, updated_at = now      │
  │   │    INSERT INTO reinforcements                  │
  │   │    RETURN StoreResult(action="reinforced")     │
  │   │                                                │
  │   │  No match? → continue to near-dedup            │
  │   └──────────────────────────────────────────────┘
  │   │
  │   ▼
  ├── 4. NEAR DEDUP CHECK
  │   │
  │   ▼
  │   storage.py: _find_near_duplicate(conn, content, embedding)
  │   ┌──────────────────────────────────────────────────────────┐
  │   │                                                          │
  │   │  IF embedding + sqlite-vec available:                    │
  │   │  ┌──────────────────────────────────────────────────┐   │
  │   │  │  COSINE PATH                                     │   │
  │   │  │                                                   │   │
  │   │  │  SELECT rowid, distance                           │   │
  │   │  │  FROM memories_vec                                │   │
  │   │  │  WHERE embedding MATCH ?                          │   │
  │   │  │  ORDER BY distance LIMIT 50                       │   │
  │   │  │                                                   │   │
  │   │  │  For each candidate:                              │   │
  │   │  │    unpack BLOB → float[768]                       │   │
  │   │  │    sim = dot(a,b) / (|a| * |b|)                   │   │
  │   │  │                                                   │   │
  │   │  │    sim > 0.90 → REINFORCE (auto-merge)            │   │
  │   │  │    sim 0.85-0.90 → WARN (create new, flag)        │   │
  │   │  │    sim < 0.85 → no action                         │   │
  │   │  └──────────────────────────────────────────────────┘   │
  │   │                                                          │
  │   │  ELSE (fallback):                                        │
  │   │  ┌──────────────────────────────────────────────────┐   │
  │   │  │  WORD OVERLAP PATH                               │   │
  │   │  │                                                   │   │
  │   │  │  words_new = set(content.lower().split())         │   │
  │   │  │                                                   │   │
  │   │  │  _sanitize_fts_query(content) → "w1 OR w2 OR .." │   │
  │   │  │  FTS5 MATCH → LIMIT 50 candidates                │   │
  │   │  │                                                   │   │
  │   │  │  For each candidate:                              │   │
  │   │  │    words_cand = set(cand.lower().split())         │   │
  │   │  │    overlap = |intersection| / |union|             │   │
  │   │  │                                                   │   │
  │   │  │    overlap > 0.90 → WARN (create new, flag)       │   │
  │   │  │    overlap ≤ 0.90 → no action                     │   │
  │   │  └──────────────────────────────────────────────────┘   │
  │   └──────────────────────────────────────────────────────────┘
  │   │
  │   ▼
  ├── 5. INSERT
  │   │
  │   ▼
  │   storage.py: INSERT INTO memories (...)
  │   ┌──────────────────────────────────────────────────┐
  │   │  id = f"mem_{nanoid(size=12)}"                    │
  │   │  embedding = struct.pack('<768f', *floats)        │
  │   │             if embedding provided and vec0 exists │
  │   │  tags = json.dumps(tags_list)                     │
  │   │  created_at = updated_at = utcnow().isoformat()   │
  │   │                                                    │
  │   │  INSERT INTO memories (...)                        │
  │   │                                                    │
  │   │  FTS5 trigger fires automatically:                 │
  │   │    INSERT INTO memories_fts(rowid, content, tags)  │
  │   │                                                    │
  │   │  If vec0 available + embedding provided:           │
  │   │    INSERT INTO memories_vec(rowid, embedding)      │
  │   │                                                    │
  │   │  conn.commit()                                     │
  │   └──────────────────────────────────────────────────┘
  │   │
  │   ▼
  └── 6. RETURN
      │
      ▼
      StoreResult {
        id: "mem_abc123def456",
        action: "created" | "reinforced",
        existing_id: null | "mem_...",
        warning: null | "near-duplicate detected (similarity: 0.87)"
      }
```

### Flow 2: memory_search() — Full Read Path

```
MCP request: memory_search(query, limit=10, category, active_only=true, scope, verify)
  │
  ▼
server.py: memory_search()
  │
  ├── 1. EMBED QUERY
  │   │
  │   ▼
  │   embedding.py: embed(query) → float[768] or None
  │
  ├── 2. ROUTE BY SCOPE
  │   │
  │   ├── scope="project" ──► search_hybrid(project.db, ...)
  │   ├── scope="global"  ──► search_hybrid(global.db, ...)
  │   └── scope="all"     ──► search_all()
  │                               │
  │                               ▼
  │                         ┌──────────────────────────┐
  │                         │  search_all():            │
  │                         │    project = hybrid(proj) │
  │                         │    global  = hybrid(glob) │
  │                         │    merged  = RRF(both)    │
  │                         │    project preferred      │
  │                         │    on ties                │
  │                         └──────────────────────────┘
  │
  ├── 3. HYBRID SEARCH (search_hybrid)
  │   │
  │   ▼
  │   ┌────────────────────────────────────────────────────────────┐
  │   │                                                            │
  │   │  PARALLEL RETRIEVAL:                                       │
  │   │                                                            │
  │   │  ┌─────────────────────────┐  ┌──────────────────────────┐│
  │   │  │  FTS5 PATH              │  │  VECTOR PATH             ││
  │   │  │                         │  │                          ││
  │   │  │  _sanitize_fts_query:   │  │  _embedding_to_blob:    ││
  │   │  │   re.sub(r'[^\w\s]',' ')│  │   struct.pack('<768f')  ││
  │   │  │   strip AND/OR/NOT/NEAR │  │                          ││
  │   │  │   " OR ".join(tokens)   │  │  SELECT rowid, distance ││
  │   │  │                         │  │  FROM memories_vec       ││
  │   │  │  SELECT m.*, bm25(...)  │  │  WHERE embedding MATCH ? ││
  │   │  │  FROM memories_fts f    │  │  ORDER BY distance      ││
  │   │  │  JOIN memories m        │  │  LIMIT 2×limit          ││
  │   │  │  WHERE f MATCH query    │  │                          ││
  │   │  │  AND m.active = 1       │  │  Fetch full rows by     ││
  │   │  │  ORDER BY bm25          │  │  rowid from memories    ││
  │   │  │  LIMIT 2×limit          │  │                          ││
  │   │  └────────────┬────────────┘  └────────────┬─────────────┘│
  │   │               │                             │              │
  │   │               └──────────┬──────────────────┘              │
  │   │                          ▼                                 │
  │   │  RRF FUSION:                                               │
  │   │  ┌──────────────────────────────────────────────────────┐  │
  │   │  │                                                      │  │
  │   │  │  For each unique memory ID:                          │  │
  │   │  │                                                      │  │
  │   │  │    fts_rank = position in FTS5 results (1-indexed)   │  │
  │   │  │    vec_rank = position in vector results (1-indexed) │  │
  │   │  │                                                      │  │
  │   │  │    score = 0.4/(60 + fts_rank)    ← FTS5 contrib     │  │
  │   │  │          + 0.6/(60 + vec_rank)    ← vector contrib   │  │
  │   │  │                                                      │  │
  │   │  │    (if only in one index, other term = 0)            │  │
  │   │  │                                                      │  │
  │   │  │  Sort by score DESC                                  │  │
  │   │  │  Tiebreak (within 0.05 tolerance):                   │  │
  │   │  │    1. Trust rank: high=3 > medium=2 > low=1          │  │
  │   │  │    2. Strength (reinforcement count)                 │  │
  │   │  │    3. Recency (updated_at DESC)                      │  │
  │   │  │                                                      │  │
  │   │  │  Return top `limit` results                          │  │
  │   │  └──────────────────────────────────────────────────────┘  │
  │   │                                                            │
  │   │  FALLBACK CHAIN:                                           │
  │   │    Both available → hybrid RRF                             │
  │   │    No embeddings  → FTS5-only                              │
  │   │    No FTS results → vector-only                            │
  │   │    Both empty     → []                                     │
  │   └────────────────────────────────────────────────────────────┘
  │
  ├── 4. OPTIONAL VERIFICATION (if verify=true)
  │   │
  │   ▼
  │   sidecar.py: verify_candidates(query, results)
  │   ┌──────────────────────────────────────────────────┐
  │   │  Cap at max_candidates (default 10)               │
  │   │                                                    │
  │   │  POST /v1/chat/completions (Qwen)                 │
  │   │  ┌────────────────────────────────────────────┐   │
  │   │  │  System: "You are a relevance verifier"    │   │
  │   │  │  User: query + numbered candidates          │   │
  │   │  │  Expected: "1. relevant" / "2. not-relevant"│  │
  │   │  └────────────────────────────────────────────┘   │
  │   │                                                    │
  │   │  Parse response via regex:                         │
  │   │    ^\d+[.)]\s*(relevant|not[-\s]?relevant)\s*$    │
  │   │                                                    │
  │   │  Filter: keep only verified=True candidates        │
  │   │                                                    │
  │   │  FAIL-OPEN: error → return all with verified=None  │
  │   └──────────────────────────────────────────────────┘
  │
  └── 5. RETURN
      │
      ▼
      [ SearchResult {
          memory: MemoryEntry { id, content, ... },
          score: 0.0164,
          match_type: "hybrid" | "fts5" | "vector",
          verified: true | false | null
        }, ... ]
```

### Flow 3: memory_consolidate() — Cluster & Merge

```
MCP request: memory_consolidate(dry_run, min_cluster_size=3, similarity_threshold=0.80)
  │
  ▼
server.py → consolidator.py: consolidate()
  │
  ├── 1. LOAD MEMORIES WITH EMBEDDINGS
  │   │
  │   ▼
  │   SELECT * FROM memories WHERE active = 1 AND embedding IS NOT NULL
  │   │
  │   ▼
  │   Unpack each embedding: struct.unpack('<768f', blob) → float[768]
  │
  ├── 2. BUILD SIMILARITY MATRIX
  │   │
  │   ▼
  │   For each pair (i, j):
  │     cosine_similarity(embedding[i], embedding[j])
  │     Store if > threshold
  │
  ├── 3. UNION-FIND CLUSTERING
  │   │
  │   ▼
  │   ┌────────────────────────────────────────────────┐
  │   │  Initialize: parent = [0, 1, 2, ..., n-1]      │
  │   │                                                 │
  │   │  For each pair where sim > 0.80:               │
  │   │    union(i, j)                                  │
  │   │                                                 │
  │   │  Group by find(i) → clusters                    │
  │   │  Filter: keep clusters with ≥ 3 members         │
  │   └────────────────────────────────────────────────┘
  │
  ├── 4. DRY RUN?
  │   │
  │   ├── Yes → RETURN cluster info without merging
  │   │
  │   └── No → continue to merge
  │
  └── 5. MERGE EACH CLUSTER
      │
      ▼
      For each cluster:
      ┌────────────────────────────────────────────────────┐
      │  POST /v1/chat/completions (Qwen)                   │
      │  ┌────────────────────────────────────────────┐     │
      │  │  "Merge these memories into one:            │     │
      │  │   1. <content_a>                            │     │
      │  │   2. <content_b>                            │     │
      │  │   3. <content_c>"                           │     │
      │  └────────────────────────────────────────────┘     │
      │                                                      │
      │  Parse: extract consolidated text from response      │
      │                                                      │
      │  memory_store(                                       │
      │    content = merged_text,                            │
      │    source = "consolidated",                          │
      │    trust = "low",                                    │
      │    tags = ["consolidated", "source-ids:a,b,c"]       │
      │  )                                                   │
      │                                                      │
      │  For each original:                                  │
      │    memory_forget(                                    │
      │      memory_id = original.id,                       │
      │      superseded_by = new_merged.id                  │
      │    )                                                 │
      │                                                      │
      │  FAIL-CLOSED: if Qwen fails → skip this cluster     │
      │               (don't partially merge)                │
      └────────────────────────────────────────────────────┘
      │
      ▼
      RETURN {
        clusters_found: 5,
        clusters_merged: 4,
        clusters_skipped: 1 (Qwen failure)
      }
```

---

## Data Models

### Enums

```
Category:  fact | preference | correction | entity | custom
Trust:     high | medium | low
Source:    user-explicit | observed | inferred | imported | consolidated
```

### MemoryEntry (Pydantic)

```
┌────────────────────────────────────────────────────┐
│  MemoryEntry                                        │
│                                                     │
│  id:              str       "mem_<nanoid12>"        │
│  content:         str       The memory text         │
│  context:         str?      When/how learned        │
│  category:        Category  Classification          │
│  trust:           Trust     Confidence level         │
│  strength:        int ≥ 1   Reinforcement count     │
│  source:          Source?   How it was created       │
│  source_session:  str?      Session identifier       │
│  tags:            [str]     Classification tags       │
│  active:          bool      Live or superseded       │
│  superseded_by:   str?      Replacement memory ID    │
│  contradicts:     [str]     Conflicting memory IDs   │
│  created_at:      datetime  UTC ISO 8601             │
│  updated_at:      datetime  UTC ISO 8601             │
│  access_count:    int       Search hit counter       │
└────────────────────────────────────────────────────┘
```

### SearchResult

```
┌────────────────────────────────────────────────────┐
│  SearchResult                                       │
│                                                     │
│  memory:      MemoryEntry   The matched entry       │
│  score:       float         RRF or BM25 score       │
│  match_type:  str           "fts5"|"vector"|"hybrid"│
│  verified:    bool?         True|False|None          │
│                             (None = no verification) │
└────────────────────────────────────────────────────┘
```

### StoreResult

```
┌────────────────────────────────────────────────────┐
│  StoreResult                                        │
│                                                     │
│  id:           str    New or existing memory ID     │
│  action:       str    "created" | "reinforced"      │
│  existing_id:  str?   ID of reinforced entry        │
│  warning:      str?   Near-duplicate notice         │
└────────────────────────────────────────────────────┘
```

---

## Configuration

```
┌──────────────────────────────────────────────────────────────────┐
│  config.py                                                        │
│                                                                   │
│  MemoryConfig                                                     │
│  ├── project_dir: ".memory"          (project-scoped DB)          │
│  ├── global_dir:  "~/.memory"        (global DB)                  │
│  ├── embedding:                                                   │
│  │   ├── mode: "local" | "server"                                 │
│  │   ├── model: "nomic-ai/nomic-embed-text-v1.5"                 │
│  │   └── endpoint: "http://localhost:8000/v1/embeddings"          │
│  └── sidecar:                                                     │
│      ├── enabled: false                                           │
│      ├── endpoint: "http://localhost:8080/v1/chat/completions"    │
│      ├── model: "qwen"                                            │
│      ├── timeout_ms: 3000                                         │
│      └── max_candidates: 10                                       │
│                                                                   │
│  Loading precedence:                                              │
│    1. Explicit config file path                                   │
│    2. MEMORY_CONFIG env var                                       │
│    3. Individual env vars (MEMORY_PROJECT_DIR, etc.)              │
│    4. Hardcoded defaults                                          │
└──────────────────────────────────────────────────────────────────┘
```

---

## Auxiliary Modules

### extractor.py — Transcript → Memories

```
Transcript text
  │
  ▼
POST /v1/chat/completions (Qwen)
  │
  ├── System prompt: extract facts, preferences, corrections
  │
  ▼
Parse JSON response: { memories: [{content, category, context, tags}] }
  │
  ├── Force: trust=LOW, source=INFERRED
  │   (deterministic boundary — extraction is never high-trust)
  │
  ▼
[MemoryEntry, MemoryEntry, ...]
```

### migrate.py — MEMORY.md → SQLite

```
MEMORY.md file
  │
  ▼
Parse headings: ## [type] Title (YYYY-MM-DD)
  │
  ├── type mapping:
  │   user     → category: fact
  │   feedback → category: correction, trust: high
  │   project  → category: fact
  │   reference → category: custom
  │
  ▼
For each entry: storage.store(source=IMPORTED)
  │
  ▼
Report: {imported: N, reinforced: M, errors: K}
```

---

## Key Algorithms

### Cosine Similarity

```
          Σ(aᵢ × bᵢ)
sim = ─────────────────────
      √Σ(aᵢ²) × √Σ(bᵢ²)

Thresholds:
  > 0.90  →  REINFORCE (auto-merge)
  0.85-0.90 →  WARN (create new, flag to user)
  < 0.85  →  No action (truly distinct)
```

### RRF (Reciprocal Rank Fusion)

```
score(id) = α/(k + rank_fts) + (1-α)/(k + rank_vec)

Parameters:
  α = 0.4   (FTS5 weight = 40%, vector weight = 60%)
  k = 60    (rank scaling, prevents divide-by-zero dominance)

Properties:
  - Symmetric: order of FTS5/vec doesn't matter
  - Single-source: missing index contributes 0
  - Diminishing returns: rank 1→2 has bigger impact than rank 50→51
```

### _sanitize_fts_query (kit-patched version)

```python
def _sanitize_fts_query(query: str) -> str:
    # 1. Strip ALL punctuation (char-level, not token-level)
    cleaned = re.sub(r'[^\w\s]', ' ', query)

    # 2. Remove FTS5 keywords
    fts_keywords = {'AND', 'OR', 'NOT', 'NEAR'}
    tokens = [t for t in cleaned.split() if t.upper() not in fts_keywords]

    # 3. OR-join for broad recall
    return " OR ".join(tokens) if tokens else ""
```

**Known limitation:** C++ → "C" (punctuation stripped). Acceptable tradeoff for query safety.

---

## Fail-Safety Properties

```
┌─────────────────────────────────────────────────────────────────┐
│  FAIL-OPEN (continue without feature):                          │
│                                                                  │
│  fastembed unavailable  → search FTS5-only, no cosine dedup     │
│  sqlite-vec unavailable → FTS5-only, no vector search/dedup     │
│  httpx unavailable      → no server-mode embeddings             │
│  Sidecar verify fails   → return all results (verified=None)    │
│  Embedding fails        → store without embedding, search FTS5  │
│                                                                  │
│  FAIL-CLOSED (don't corrupt data):                              │
│                                                                  │
│  Qwen consolidation fails → skip cluster entirely               │
│  Malformed extraction     → return [], don't store garbage      │
│  Store fails mid-write    → SQLite rollback (ACID)              │
└─────────────────────────────────────────────────────────────────┘
```

---

## MCP Registration (nana-dev-kit integration)

```json
// ~/.claude/settings.json (written by install.sh via register-settings.py)
{
  "mcpServers": {
    "memory": {
      "command": "<venv-python>",
      "args": ["-m", "memory_server"],
      "cwd": "/Users/<user>/.claude"
    }
  }
}
```

**Note:** CWD must be `~/.claude` (parent), not `~/.claude/memory_server/` (package dir).
This was a bug fixed in Phase 4 — install.sh now has import-check verification after MCP registration.
