<!-- nana:approved 2026-05-24 -->
# Spec: Phase 33 — Hybrid Retrieval Benchmark + Memory Server Fixes

## Objective

Run the LongMemEval-S benchmark with fastembed+sqlite-vec hybrid search, compare against the Phase 32 FTS5 baseline (recall@5 91.0%, recall@10 95.2%), and fix `_sanitize_fts_query` in memory_server/storage.py to handle the full set of FTS5 special characters.

## Context

Phase 32 established a FTS5-only retrieval baseline using 500 LongMemEval-S questions. The benchmark (benchmark/longmemeval.py, 240 lines) already has a hybrid code path that detects fastembed + sqlite-vec availability, but it was never activated because: (1) neither package is installed, and (2) the benchmark's `store()` call never passes embeddings during indexing — so even with deps installed, hybrid mode would silently degrade to FTS5-only via `search_hybrid`'s fallback path.

Separately, `_sanitize_fts_query` (storage.py:895) strips `()"*:` from query tokens but misses other FTS5 operators (`+`, `-`, `^`). The benchmark works around this with its own aggressive sanitizer (`re.sub(r'[^\w\s]', ' ', query)` at line 68-71). After fixing storage.py, the benchmark's redundant sanitizer should be evaluated for removal.

The storage.py copy in nana-dev-kit is byte-identical to the nanaclaw source. Fixing it here creates a known divergence. The same fix should be applied to nanaclaw separately.

## Scope

### In scope
- Install fastembed + sqlite-vec into the memory_server venv
- Fix `_sanitize_fts_query` to strip the full FTS5 operator set (`()"*:+-^`)
- Add embedding generation during benchmark indexing (the `store()` call must pass `embedding=` for each session)
- Add hybrid-mode assertion: verify that vec results were actually produced, fail loudly if hybrid mode silently degrades to FTS5
- Run full 500-question benchmark in both modes (FTS5 and hybrid), report comparison
- Update benchmark/README.md with hybrid results and comparison
- Update README.md benchmark section with hybrid numbers
- Verify FTS5 recall does not regress after sanitizer fix

### Out of scope
- Modifying the RRF fusion parameters (alpha=0.4, k=60 — use existing defaults)
- Changing the embedding model (nomic-ai/nomic-embed-text-v1.5, 768-dim)
- Applying the fix to nanaclaw (separate task, document as known divergence)
- Latency/throughput benchmarking
- Custom embedding model tuning or dimension reduction
- CI integration for benchmark runs

## Approach

Three workstreams, sequenced by dependency:

1. **Sanitizer fix** — Expand the character set in `_sanitize_fts_query` to include `+-^` alongside existing `()"*:`. Remove the benchmark's `sanitize_query()` function and use `_sanitize_fts_query` directly — if any benchmark query fails after removal, fix `_sanitize_fts_query` to handle that character rather than keeping the benchmark's sanitizer. Re-run FTS5 benchmark to confirm no recall regression.

2. **Hybrid indexing** — Modify `evaluate_question()` to create an `EmbeddingProvider`, embed each session's text during indexing, and pass `embedding=` to `store()`. Add a post-indexing assertion that `_vec_available` is True and at least one memories_vec row exists. Use `embed_batch()` for efficiency where possible.

3. **Hybrid benchmark run** — Run `--full --mode both` to produce side-by-side FTS5 vs hybrid numbers. Report per-category comparison.

## Constraints (CRITICAL)

- FTS5 recall MUST NOT regress below 91.0%@5 / 95.2%@10 after sanitizer fix — prevents: sanitizer over-stripping causing missed matches. Guard: re-run FTS5 benchmark after fix, compare against baseline.
- Hybrid mode MUST assert vec results were produced — prevents: silent degradation to FTS5-only producing misleading "hybrid" numbers. Guard: check `_vec_available == True` and `len(vec_results) > 0` for at least one question, or mark run as DEGRADED.
- Each question MUST continue using isolated SQLite DBs — prevents: cross-question contamination. Guard: existing per-question tempfile pattern preserved.
- `_vec_available` global state MUST be verified per-question in hybrid mode — prevents: a transient sqlite-vec load failure silently disabling vec for all subsequent questions. Guard: check `_vec_available` after each `init_db()` in hybrid mode.
- The benchmark's own `sanitize_query()` MUST be removed after fixing `_sanitize_fts_query` — prevents: masking bugs in the production sanitizer. Guard: remove `sanitize_query()` entirely; any resulting FTS5 errors are bugs in `_sanitize_fts_query` to fix there.

## Deliverables

1. `memory_server/storage.py` — fixed `_sanitize_fts_query` (expanded character set)
2. `benchmark/longmemeval.py` — hybrid indexing with embeddings, hybrid assertion, sanitizer cleanup
3. `benchmark/README.md` — updated with hybrid results and FTS5 vs hybrid comparison table
4. `README.md` — updated benchmark section with hybrid numbers
5. `tests/test_benchmark.sh` or equivalent — sanitizer regression test (FTS5 recall >= baseline)

## Exit Criteria (machine-checkable)

- [ ] `python3 -c "import sys; sys.path.insert(0,'memory_server'); from storage import _sanitize_fts_query; r=_sanitize_fts_query('test+foo-bar^baz'); assert '+' not in r and '-' not in r and '^' not in r, f'got: {r}'"` (sanitizer strips FTS5 operators)
- [ ] `python3 benchmark/longmemeval.py --smoke-test` (exits 0)
- [ ] `python3 benchmark/longmemeval.py --dry-run 3 --mode hybrid 2>&1 | grep -q 'HYBRID Results\|hybrid.*recall'` (hybrid mode produces actual results, not FTS5 fallback)
- [ ] `! grep -q 'def sanitize_query' benchmark/longmemeval.py` (redundant benchmark sanitizer removed)
- [ ] `grep -q 'hybrid' benchmark/README.md` (hybrid results documented)
- [ ] `grep -qi 'hybrid\|embedding' README.md` (README updated)
- [ ] `make test` (no regressions)

## Checkpoints

- After sanitizer fix: re-run FTS5-only benchmark (at least --dry-run 10). Report recall numbers. If recall@5 drops below 91.0%, STOP and investigate.
- After hybrid indexing works on --smoke-test: report before full run.
- After --dry-run 50 --mode hybrid succeeds: report recall numbers before full 500-question run.
- After full benchmark completes: report both FTS5 and hybrid numbers before updating docs.
- If hybrid recall@5 is within 1% of FTS5: note this explicitly — small delta means embeddings add minimal value for this dataset/retrieval-unit combination.

## Assumptions

- fastembed and sqlite-vec can be pip-installed into the memory_server venv (`~/.claude/memory_server/.venv/`). These are benchmark-only deps — do NOT add them to install.sh's venv setup (fastembed is ~500MB with ONNX). If pip install fails: create a benchmark-specific venv at `benchmark/.venv/`.
- nomic-ai/nomic-embed-text-v1.5 produces 768-dimension embeddings matching the vec0 table schema. If false: check embedding dimension at runtime and fail with a clear error before indexing.
- Embedding 500 × ~48 sessions (~24,000 texts) completes in reasonable time (<30 min). If false: add `--limit N` flag to cap question count for hybrid runs.
- `search_hybrid` RRF fusion works correctly with both FTS5 and vec results populated. If false: debug RRF scoring before reporting numbers.
