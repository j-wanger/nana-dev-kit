#!/usr/bin/env python3
"""Reasoning eval data utility.

Computes stats from eval results, loads scenarios, and formats output.
The actual eval is run via Claude Code subagents (see README.md).

Usage:
    python3 eval/reasoning/run-eval.py --stats eval/reasoning/baseline/results.json
    python3 eval/reasoning/run-eval.py --compare BASELINE TREATMENT
    python3 eval/reasoning/run-eval.py --list
    python3 eval/reasoning/run-eval.py --ablation eval/reasoning/traces/
    python3 eval/reasoning/run-eval.py --analyze eval/reasoning/traces/
"""

import argparse
import json
import sys
from pathlib import Path

EVAL_DIR = Path(__file__).parent
CORPUS_DIR = EVAL_DIR / "corpus"
TRACES_DIR = EVAL_DIR / "traces"
SCHEMA_PATH = EVAL_DIR / "trace-schema.json"
DIMENSIONS = ["decision", "reasoning", "antipattern"]
DELTA_THRESHOLD = 0.5
VARIANCE_THRESHOLD = 0.5


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


def validate_trace(data: dict, schema: dict) -> list[str]:
    errors = []
    for field in schema.get("required", []):
        if field not in data:
            errors.append(f"Missing required field: {field}")
    if "runs" in data:
        if len(data["runs"]) < 3:
            errors.append(f"Expected >= 3 runs, got {len(data['runs'])}")
        for i, run in enumerate(data["runs"]):
            for entry in run:
                if "scenario_id" not in entry:
                    errors.append(f"Run {i}: entry missing scenario_id")
                if "scores" not in entry:
                    errors.append(f"Run {i}: entry missing scores")
                elif not all(d in entry["scores"] for d in DIMENSIONS):
                    errors.append(f"Run {i}: {entry.get('scenario_id','?')} missing score dimension")
    return errors


def per_scenario_means(data: dict) -> dict[str, dict[str, float]]:
    means: dict[str, dict[str, list[float]]] = {}
    for run in data.get("runs", []):
        for entry in run:
            sid = entry["scenario_id"]
            if sid not in means:
                means[sid] = {d: [] for d in DIMENSIONS}
            for d in DIMENSIONS:
                means[sid][d].append(entry["scores"][d])
    return {
        sid: {d: sum(vals) / len(vals) for d, vals in dims.items()}
        for sid, dims in means.items()
    }


def per_scenario_variance(data: dict) -> dict[str, dict[str, float]]:
    collected: dict[str, dict[str, list[float]]] = {}
    for run in data.get("runs", []):
        for entry in run:
            sid = entry["scenario_id"]
            if sid not in collected:
                collected[sid] = {d: [] for d in DIMENSIONS}
            for d in DIMENSIONS:
                collected[sid][d].append(entry["scores"][d])
    result = {}
    for sid, dims in collected.items():
        result[sid] = {}
        for d, vals in dims.items():
            avg = sum(vals) / len(vals) if vals else 0
            result[sid][d] = sum((v - avg) ** 2 for v in vals) / (len(vals) - 1) if len(vals) > 1 else 0
    return result


def cmd_ablation(traces_dir: Path):
    schema = json.loads(SCHEMA_PATH.read_text()) if SCHEMA_PATH.exists() else {}
    trace_files = sorted(f for f in traces_dir.glob("*.json") if f.name not in ("attribution-matrix.json", "selection-criteria.md"))
    if not trace_files:
        print("No trace files found in", traces_dir)
        sys.exit(1)

    full_set = None
    conditions = {}

    for f in trace_files:
        data = json.loads(f.read_text())
        errors = validate_trace(data, schema)
        if errors:
            print(f"WARN: {f.name}: {'; '.join(errors)}")

        cond = data.get("condition", f.stem)
        conditions[cond] = data
        if cond == "full-set":
            full_set = data

    if not full_set:
        print("ERROR: No full-set condition found. Cannot compute deltas.")
        sys.exit(1)

    full_means = per_scenario_means(full_set)

    print(f"Traces: {len(conditions)} conditions loaded")
    print(f"Full-set scenarios: {list(full_means.keys())}")
    print(f"\n{'Condition':40s}  {'Scenario':35s}  {'Dim':12s}  {'Full':>5s}  {'Cond':>5s}  {'Delta':>6s}")
    print("-" * 110)

    for cond_name, cond_data in sorted(conditions.items()):
        if cond_name == "full-set":
            continue
        cond_means = per_scenario_means(cond_data)
        for sid in sorted(set(full_means) & set(cond_means)):
            for d in DIMENSIONS:
                full_val = full_means[sid][d]
                cond_val = cond_means[sid][d]
                delta = round(cond_val - full_val, 2)
                sign = "+" if delta > 0 else ""
                print(f"{cond_name:40s}  {sid:35s}  {d:12s}  {full_val:5.2f}  {cond_val:5.2f}  {sign}{delta:5.2f}")


def classify_effect(delta: float, variance: float) -> str:
    if variance >= VARIANCE_THRESHOLD:
        return "uncertain"
    if delta >= DELTA_THRESHOLD:
        return "helped"
    if delta <= -DELTA_THRESHOLD:
        return "hurt"
    return "irrelevant"


def cmd_analyze(traces_dir: Path):
    trace_files = sorted(f for f in traces_dir.glob("*.json") if f.name != "attribution-matrix.json")
    full_set = None
    loo_conditions = {}

    for f in trace_files:
        data = json.loads(f.read_text())
        cond = data.get("condition", f.stem)
        if cond == "full-set":
            full_set = data
        elif cond.startswith("leave-one-out-"):
            heuristic_id = data.get("heuristic_id", cond.replace("leave-one-out-", ""))
            loo_conditions[heuristic_id] = data

    if not full_set:
        print("ERROR: No full-set condition. Run ablation first.")
        sys.exit(1)
    if not loo_conditions:
        print("ERROR: No leave-one-out conditions found.")
        sys.exit(1)

    full_means = per_scenario_means(full_set)
    classifications = []

    for heuristic_id, loo_data in sorted(loo_conditions.items()):
        loo_means = per_scenario_means(loo_data)
        loo_var = per_scenario_variance(loo_data)
        for sid in sorted(set(full_means) & set(loo_means)):
            for d in DIMENSIONS:
                full_val = full_means[sid][d]
                loo_val = loo_means[sid][d]
                delta = round(loo_val - full_val, 2)
                var = round(loo_var.get(sid, {}).get(d, 0), 4)
                effect = classify_effect(delta, var)
                classifications.append({
                    "heuristic_id": heuristic_id,
                    "scenario_id": sid,
                    "dimension": d,
                    "full_set_mean": round(full_val, 2),
                    "loo_mean": round(loo_val, 2),
                    "delta": delta,
                    "variance": var,
                    "classification": effect,
                })

    matrix = {
        "generated": "auto",
        "full_set_condition": full_set.get("condition", "full-set"),
        "heuristics_ablated": sorted(loo_conditions.keys()),
        "scenarios": sorted({c["scenario_id"] for c in classifications}),
        "dimensions": DIMENSIONS,
        "threshold": {"delta": DELTA_THRESHOLD, "variance": VARIANCE_THRESHOLD},
        "classifications": classifications,
    }

    out_path = traces_dir / "attribution-matrix.json"
    out_path.write_text(json.dumps(matrix, indent=2) + "\n")

    print(f"Attribution matrix: {len(classifications)} entries")
    print(f"  Heuristics: {matrix['heuristics_ablated']}")
    print(f"  Scenarios: {matrix['scenarios']}")
    print(f"  Output: {out_path}")

    counts = {"helped": 0, "hurt": 0, "irrelevant": 0, "uncertain": 0}
    for c in classifications:
        counts[c["classification"]] += 1
    print(f"\nClassifications: {counts}")

    print(f"\n{'Heuristic':12s}  {'Scenario':35s}  {'Dim':12s}  {'Delta':>6s}  {'Class':>10s}")
    print("-" * 85)
    for c in classifications:
        if c["classification"] in ("helped", "hurt"):
            sign = "+" if c["delta"] > 0 else ""
            print(f"{c['heuristic_id']:12s}  {c['scenario_id']:35s}  {c['dimension']:12s}  {sign}{c['delta']:5.2f}  {c['classification']:>10s}")


def main():
    parser = argparse.ArgumentParser(description="Reasoning eval data utility")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--stats", type=Path, help="Compute stats from results JSON")
    group.add_argument("--compare", nargs=2, type=Path, metavar=("BASELINE", "TREATMENT"), help="Compare two result sets")
    group.add_argument("--list", action="store_true", help="List available scenarios")
    group.add_argument("--ablation", type=Path, metavar="TRACES_DIR", help="Read ablation traces, validate, compute deltas vs full-set")
    group.add_argument("--analyze", type=Path, metavar="TRACES_DIR", help="Generate attribution matrix from ablation traces")

    args = parser.parse_args()

    if args.stats:
        cmd_stats(args.stats)
    elif args.compare:
        cmd_compare(args.compare[0], args.compare[1])
    elif args.list:
        cmd_list()
    elif args.ablation:
        cmd_ablation(args.ablation)
    elif args.analyze:
        cmd_analyze(args.analyze)


if __name__ == "__main__":
    main()
