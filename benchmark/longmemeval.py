#!/usr/bin/env python3
"""LongMemEval-S benchmark for memory_server retrieval quality.

Measures recall@5 and recall@10 of FTS5 and hybrid search against
the LongMemEval-S dataset (500 questions, ~50 sessions each).

Usage:
    python benchmark/longmemeval.py --smoke-test   # 3 questions, verify setup
    python benchmark/longmemeval.py --dry-run 3    # N questions, full pipeline
    python benchmark/longmemeval.py --full         # all 500 questions
"""

import argparse
import json
import os
import sys
import tempfile
from pathlib import Path

DATASET_REPO = "xiaowu0162/longmemeval-cleaned"
DATASET_FILE = "longmemeval_s_cleaned.json"
DATASET_REVISION = "main"  # pin after first successful run

SCRIPT_DIR = Path(__file__).parent
REPO_ROOT = SCRIPT_DIR.parent
DATA_DIR = SCRIPT_DIR / "data"

sys.path.insert(0, str(REPO_ROOT / "memory_server"))
from storage import init_db, store, search_fts  # noqa: E402

# Optional: hybrid search deps
try:
    from storage import search_hybrid  # noqa: E402
    from embedding import EmbeddingProvider  # noqa: E402
    from config import EmbeddingConfig  # noqa: E402
    HYBRID_AVAILABLE = True
except ImportError:
    HYBRID_AVAILABLE = False

try:
    import fastembed  # noqa: F401
    import sqlite_vec  # noqa: F401
    HYBRID_DEPS = True
except ImportError:
    HYBRID_DEPS = False


def download_dataset() -> list[dict]:
    """Download and cache the LongMemEval-S dataset."""
    data_path = DATA_DIR / DATASET_FILE
    if data_path.exists():
        with open(data_path) as f:
            return json.load(f)

    from huggingface_hub import hf_hub_download
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    hf_hub_download(
        DATASET_REPO,
        DATASET_FILE,
        repo_type="dataset",
        revision=DATASET_REVISION,
        local_dir=str(DATA_DIR),
    )
    with open(data_path) as f:
        return json.load(f)


def sanitize_query(query: str) -> str:
    """Remove characters that cause FTS5 syntax errors."""
    import re
    return re.sub(r'[^\w\s]', ' ', query).strip()


def session_to_text(session: list[dict]) -> str:
    """Concatenate all turns in a session into a single text block."""
    parts = []
    for turn in session:
        role = turn.get("role", "unknown")
        content = turn.get("content", "")
        parts.append(f"{role}: {content}")
    return "\n".join(parts)


def evaluate_question(question: dict, mode: str = "fts5") -> dict:
    """Run one question: index sessions, search, compute recall."""
    sessions = question["haystack_sessions"]
    session_ids = question["haystack_session_ids"]
    gold_ids = set(question["answer_session_ids"])
    query = sanitize_query(question["question"])

    # Create isolated DB
    tmp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
    tmp.close()
    db_path = tmp.name

    try:
        conn = init_db(db_path)

        # Index all sessions
        id_map = {}  # memory_id -> session_id
        for sid, session in zip(session_ids, sessions):
            text = session_to_text(session)
            result = store(conn, text, tags=[sid])
            id_map[result.id] = sid

        # Search
        if mode == "hybrid" and HYBRID_AVAILABLE and HYBRID_DEPS:
            embedder = EmbeddingProvider(EmbeddingConfig())
            query_emb = embedder.embed(query)
            results = search_hybrid(conn, query, query_emb, limit=10)
            result_ids = [entry.id for entry, _score, _match in results]
        else:
            results = search_fts(conn, query, limit=10)
            result_ids = [entry.id for entry, _score in results]

        # Map back to session IDs
        retrieved_session_ids = [id_map.get(rid) for rid in result_ids if rid in id_map]

        # Compute recall
        top5 = set(retrieved_session_ids[:5])
        top10 = set(retrieved_session_ids[:10])
        recall_at_5 = len(gold_ids & top5) / len(gold_ids) if gold_ids else 0.0
        recall_at_10 = len(gold_ids & top10) / len(gold_ids) if gold_ids else 0.0

        conn.close()
        return {
            "question_id": question["question_id"],
            "question_type": question["question_type"],
            "recall_at_5": recall_at_5,
            "recall_at_10": recall_at_10,
            "gold_count": len(gold_ids),
            "retrieved_5": len(top5 & gold_ids),
            "retrieved_10": len(top10 & gold_ids),
        }
    finally:
        os.unlink(db_path)


def run_benchmark(questions: list[dict], mode: str = "fts5", report_every: int = 50) -> dict:
    """Run benchmark on a list of questions, return aggregate results."""
    results = []
    categories: dict[str, list[dict]] = {}

    for i, q in enumerate(questions):
        r = evaluate_question(q, mode=mode)
        results.append(r)

        cat = r["question_type"]
        categories.setdefault(cat, []).append(r)

        if report_every and (i + 1) % report_every == 0:
            avg_r5 = sum(x["recall_at_5"] for x in results) / len(results)
            print(f"  [{mode}] {i+1}/{len(questions)} questions — recall@5: {avg_r5:.1%}")

    # Aggregate
    overall_r5 = sum(x["recall_at_5"] for x in results) / len(results) if results else 0
    overall_r10 = sum(x["recall_at_10"] for x in results) / len(results) if results else 0

    per_category = {}
    for cat, cat_results in sorted(categories.items()):
        per_category[cat] = {
            "count": len(cat_results),
            "recall_at_5": sum(x["recall_at_5"] for x in cat_results) / len(cat_results),
            "recall_at_10": sum(x["recall_at_10"] for x in cat_results) / len(cat_results),
        }

    return {
        "mode": mode,
        "total_questions": len(results),
        "overall_recall_at_5": overall_r5,
        "overall_recall_at_10": overall_r10,
        "per_category": per_category,
    }


def smoke_test(data: list[dict]) -> bool:
    """Run 3 questions, assert recall > 0 for at least one."""
    print("Running smoke test (3 questions)...")
    subset = data[:3]
    passed = 0
    for q in subset:
        r = evaluate_question(q, mode="fts5")
        print(f"  {q['question_id']}: recall@5={r['recall_at_5']:.0%}, recall@10={r['recall_at_10']:.0%}")
        if r["recall_at_5"] > 0 or r["recall_at_10"] > 0:
            passed += 1

    print(f"Smoke test: {passed}/3 questions with recall > 0")
    return passed > 0


def main():
    parser = argparse.ArgumentParser(description="LongMemEval-S memory benchmark")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--smoke-test", action="store_true", help="Run 3 questions to verify setup")
    group.add_argument("--dry-run", type=int, metavar="N", help="Run N questions with full pipeline")
    group.add_argument("--full", action="store_true", help="Run all 500 questions")
    parser.add_argument("--mode", choices=["fts5", "hybrid", "both"], default="fts5",
                        help="Search mode (default: fts5)")
    args = parser.parse_args()

    print("Downloading/loading LongMemEval-S dataset...")
    data = download_dataset()
    print(f"Loaded {len(data)} questions")

    if args.smoke_test:
        ok = smoke_test(data)
        sys.exit(0 if ok else 1)

    n = args.dry_run if args.dry_run else len(data)
    questions = data[:n]
    modes = ["fts5", "hybrid"] if args.mode == "both" else [args.mode]

    all_results = {}
    for mode in modes:
        if mode == "hybrid" and not (HYBRID_AVAILABLE and HYBRID_DEPS):
            print(f"Skipping hybrid mode — fastembed/sqlite-vec not available")
            continue
        print(f"\nRunning {mode} benchmark on {len(questions)} questions...")
        result = run_benchmark(questions, mode=mode, report_every=50 if n > 10 else 0)
        all_results[mode] = result

        print(f"\n{'='*50}")
        print(f"  {mode.upper()} Results ({result['total_questions']} questions)")
        print(f"{'='*50}")
        print(f"  Overall recall@5:  {result['overall_recall_at_5']:.1%}")
        print(f"  Overall recall@10: {result['overall_recall_at_10']:.1%}")
        print(f"\n  Per category:")
        for cat, stats in result["per_category"].items():
            print(f"    {cat:30s} recall@5={stats['recall_at_5']:.1%}  recall@10={stats['recall_at_10']:.1%}  (n={stats['count']})")

    # Save results
    results_path = SCRIPT_DIR / "results.json"
    with open(results_path, "w") as f:
        json.dump(all_results, f, indent=2)
    print(f"\nResults saved to {results_path}")


if __name__ == "__main__":
    main()
