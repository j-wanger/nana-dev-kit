<!-- nana:approved 2026-05-24 -->
# Spec: Phase 32 — LongMemEval-S Memory Benchmark

## Objective

Benchmark the vendored memory_server's FTS5 and hybrid search recall against the LongMemEval-S dataset, producing per-category recall@5 and recall@10 numbers comparable to published baselines.

## Context

The memory_server (12 .py, 2,373 LOC) provides FTS5 full-text search and optional hybrid search (fastembed embeddings + sqlite-vec + Reciprocal Rank Fusion). It underpins all cross-session memory features (memory-bridge, memory-harvest, enforce-memory). No benchmark validates its retrieval quality. LongMemEval-S (xiaowu0162/longmemeval-cleaned on HuggingFace) has 500 questions across 5 categories with ~48 sessions per question. Published baselines from rohitg00/agentmemory: BM25 86.2% recall@5, hybrid 95.2% recall@5. These use different retrieval units (conversation chunks vs. our per-entry storage), so direct comparison requires caveats.

The benchmark is diagnostic first — results inform whether the memory server needs search quality improvements. README inclusion is conditional: only if results are meaningful (recall > 50% for FTS5, demonstrating the system works at scale).

## Scope

### In scope
- Python benchmark script (`benchmark/longmemeval.py`) that: downloads dataset, indexes sessions as memory entries, queries, scores recall
- Per-question SQLite DB isolation (fresh DB per question, prevents cross-contamination)
- Two search modes: FTS5-only, hybrid (when fastembed + sqlite-vec available)
- Recall@5 and recall@10 per category and overall
- Smoke test (3 hand-verified queries assert recall > 0 before full run)
- Results output (JSON + human-readable summary)
- README update (results section with baseline comparison + caveats on retrieval unit differences)
- Dataset version pinning (specific HuggingFace revision, not "latest")

### Out of scope
- Latency/throughput benchmarking (measuring recall, not speed)
- Modifying memory_server code to improve benchmark numbers
- Answer quality evaluation (recall only — did the right sessions appear in results?)
- LoCoMo or BEAM benchmarks (larger datasets, future phase)
- Custom embedding model tuning
- CI integration (benchmark takes minutes, run manually)

## Approach

Single Python script pattern. One entry point (`benchmark/longmemeval.py`) with three phases: (1) download + parse dataset, (2) per-question indexing + querying, (3) scoring + report generation.

Each of the 500 questions gets its own temporary SQLite DB. Each conversation session is stored as one memory entry: `content` = full session text (all turns concatenated with newlines), `category` = "fact", `tags` = [session_id]. For each question, query the memory_server with the verbatim question text as the search string (no preprocessing). Check if gold session IDs appear in top-K result IDs. Score recall = gold_sessions_found_in_top_k / total_gold_sessions.

Hybrid mode requires fastembed + sqlite-vec. Script detects availability and runs both modes when possible, FTS5-only otherwise. Results saved to `benchmark/results.json`.

## Constraints (CRITICAL)

- Each question MUST use an isolated SQLite DB — prevents: cross-question contamination inflating/deflating recall
- The smoke test (3 known-good queries) MUST pass before full benchmark runs — prevents: silent zero-recall from adapter misconfiguration
- Dataset MUST be pinned to a specific HuggingFace revision hash — prevents: non-reproducible results from dataset updates
- The benchmark MUST NOT modify any file in `memory_server/` — prevents: benchmark-tuned code diverging from production
- Results MUST report the retrieval unit used (one memory entry = one conversation session) alongside any baseline comparison — prevents: misleading apples-to-oranges claims
- The script MUST gracefully handle missing optional deps (fastembed, sqlite-vec) — prevents: crash on FTS5-only systems; report FTS5 results and skip hybrid

## Deliverables

1. `benchmark/longmemeval.py` — main benchmark script (~200-300 lines)
2. `benchmark/README.md` — usage instructions, dependencies, interpretation guide
3. `benchmark/results.json` — benchmark output (gitignored, generated)
4. Updated `README.md` — results section with caveats
5. `.gitignore` update — `benchmark/results.json`, `benchmark/data/`

## Exit Criteria (machine-checkable)

- [ ] `test -f benchmark/longmemeval.py && python3 -c "import ast; ast.parse(open('benchmark/longmemeval.py').read())"`
- [ ] `test -f benchmark/README.md`
- [ ] `grep -q 'recall@5\|LongMemEval' README.md`
- [ ] `grep -q 'benchmark/results' .gitignore`
- [ ] `python3 benchmark/longmemeval.py --smoke-test` (exits 0, prints recall > 0 for 3 queries)
- [ ] `make test`

## Checkpoints

- After smoke test passes (3 queries, recall > 0): report before full 500-question run
- After full FTS5 run completes: report numbers before attempting hybrid
- If recall@5 < 20% for FTS5: STOP and investigate — likely an adapter bug, not genuine performance

## Assumptions

- LongMemEval-S dataset is available at `xiaowu0162/longmemeval-cleaned` on HuggingFace. If false: find alternative source or use a subset from the paper's GitHub.
- Each question's gold answer references specific session IDs that can be matched against stored entries. If false: need a different evaluation oracle (e.g., string containment on answer text).
- `memory_server/storage.py` can be imported directly by adding the directory to sys.path. If false: use subprocess calls to the MCP server.
- fastembed + sqlite-vec are available in the memory_server venv for hybrid testing. If false: report FTS5-only results and document the gap.
