#!/usr/bin/env python3
"""Reasoning eval data utility.

Computes stats from eval results, loads scenarios, and formats output.
The actual eval is run via Claude Code subagents (see README.md).

Usage:
    # Compute stats from existing results
    python3 eval/reasoning/run-eval.py --stats eval/reasoning/baseline/results.json

    # Compare two result sets
    python3 eval/reasoning/run-eval.py --compare eval/reasoning/baseline/results.json eval/reasoning/with-heuristics/results.json

    # List scenarios
    python3 eval/reasoning/run-eval.py --list
"""

import argparse
import json
import sys
from pathlib import Path

EVAL_DIR = Path(__file__).parent
CORPUS_DIR = EVAL_DIR / "corpus"


def load_scenarios(corpus_dir: Path, limit: int | None = None) -> list[dict]:
    scenarios = []
    for f in sorted(corpus_dir.glob("*.json")):
        scenarios.append(json.loads(f.read_text()))
    if limit:
        scenarios = scenarios[:limit]
    return scenarios


def compute_stats(results: dict) -> dict:
    dimensions = ["decision", "reasoning", "antipattern"]
    all_runs = results.get("runs", [])

    dim_scores = {d: [] for d in dimensions}
    for run in all_runs:
        for d in dimensions:
            valid = [r["scores"][d] for r in run if r["scores"][d] > 0]
            run_avg = sum(valid) / len(valid) if valid else 0
            dim_scores[d].append(run_avg)

    averages = {}
    variance = {}
    for d in dimensions:
        vals = dim_scores[d]
        avg = sum(vals) / len(vals) if vals else 0
        var = sum((v - avg) ** 2 for v in vals) / len(vals) if len(vals) > 1 else 0
        averages[d] = round(avg, 2)
        variance[d] = round(var, 4)

    return {"averages": averages, "variance": variance}


def cmd_stats(path: Path):
    data = json.loads(path.read_text())
    stats = compute_stats(data)

    print(f"Mode: {data.get('mode', 'unknown')}")
    print(f"Scenarios: {data.get('scenarios', '?')}, Runs: {len(data.get('runs', []))}")
    print(f"Averages:  D={stats['averages']['decision']}  R={stats['averages']['reasoning']}  A={stats['averages']['antipattern']}")
    print(f"Variance:  D={stats['variance']['decision']}  R={stats['variance']['reasoning']}  A={stats['variance']['antipattern']}")
    all_ok = all(v < 0.5 for v in stats["variance"].values())
    print(f"Variance check: {'PASS (all < 0.5)' if all_ok else 'FAIL (some >= 0.5)'}")

    for i, run in enumerate(data.get("runs", []), 1):
        print(f"\nRun {i}:")
        for r in run:
            s = r["scores"]
            j = r.get("justifications", {})
            print(f"  {r['scenario_id']:35s}  D={s['decision']}  R={s['reasoning']}  A={s['antipattern']}")
            if j.get("decision"):
                print(f"    {j['decision']}")


def cmd_compare(path_a: Path, path_b: Path):
    a = json.loads(path_a.read_text())
    b = json.loads(path_b.read_text())
    stats_a = compute_stats(a)
    stats_b = compute_stats(b)

    print(f"{'Dimension':20s}  {'Baseline':>8s}  {'Treatment':>9s}  {'Delta':>6s}")
    print("-" * 50)
    for d in ["decision", "reasoning", "antipattern"]:
        va = stats_a["averages"][d]
        vb = stats_b["averages"][d]
        delta = round(vb - va, 2)
        sign = "+" if delta > 0 else ""
        print(f"{d:20s}  {va:8.2f}  {vb:9.2f}  {sign}{delta:5.2f}")

    print(f"\nBaseline: {a.get('mode', '?')} ({path_a.name})")
    print(f"Treatment: {b.get('mode', '?')} ({path_b.name})")


def cmd_list():
    scenarios = load_scenarios(CORPUS_DIR)
    for s in scenarios:
        print(f"  {s['id']:35s}  {s['question'][:60]}")


def main():
    parser = argparse.ArgumentParser(description="Reasoning eval data utility")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--stats", type=Path, help="Compute stats from results JSON")
    group.add_argument("--compare", nargs=2, type=Path, metavar=("BASELINE", "TREATMENT"), help="Compare two result sets")
    group.add_argument("--list", action="store_true", help="List available scenarios")

    args = parser.parse_args()

    if args.stats:
        cmd_stats(args.stats)
    elif args.compare:
        cmd_compare(args.compare[0], args.compare[1])
    elif args.list:
        cmd_list()


if __name__ == "__main__":
    main()
