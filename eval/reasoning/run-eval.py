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
    python3 eval/reasoning/run-eval.py --conditional
    python3 eval/reasoning/run-eval.py --length-test
    python3 eval/reasoning/run-eval.py --cross-judge
    python3 eval/reasoning/run-eval.py --selective
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


def cmd_length_test():
    condition_dirs = {
        "baseline": EVAL_DIR / "baseline",
        "iron-rules": EVAL_DIR / "with-iron-rules",
        "filler": EVAL_DIR / "length-sensitivity",
    }

    results = {}
    for label, d in condition_dirs.items():
        rpath = d / "results.json"
        if not rpath.exists():
            print(f"WARN: {rpath} not found — skipping {label}")
            continue
        results[label] = json.loads(rpath.read_text())

    if len(results) < 2:
        print("ERROR: Need at least 2 condition result files for comparison.")
        sys.exit(1)

    means = {label: per_scenario_means(data) for label, data in results.items()}
    all_sids = sorted(set().union(*(m.keys() for m in means.values())))
    labels = [l for l in ["baseline", "iron-rules", "filler"] if l in results]

    baseline_means = means.get("baseline", {})
    iron_means = means.get("iron-rules", {})
    filler_means = means.get("filler", {})

    affected = []
    for sid in all_sids:
        for d in DIMENSIONS:
            bv = baseline_means.get(sid, {}).get(d, 0)
            iv = iron_means.get(sid, {}).get(d, 0)
            if iv - bv <= -0.3:
                affected.append((sid, d))

    print(f"Affected scenarios (iron-rules delta <= -0.3 vs baseline): {len(affected)}")
    for sid, d in affected:
        bv = baseline_means.get(sid, {}).get(d, 0)
        iv = iron_means.get(sid, {}).get(d, 0)
        print(f"  {sid} / {d}: baseline={bv:.2f} iron={iv:.2f} delta={iv-bv:+.2f}")

    header_scores = "  ".join(f"{l:>10s}" for l in labels)
    print(f"\n{'Scenario':35s}  {'Dim':12s}  {header_scores}  {'IR Delta':>8s}  {'Fill Delta':>10s}  {'Match':>5s}")
    print("-" * 120)

    length_matches = 0
    for sid in all_sids:
        for d in DIMENSIONS:
            vals = [means.get(l, {}).get(sid, {}).get(d, 0) for l in labels]
            score_strs = "  ".join(f"{v:10.2f}" for v in vals)
            bv = baseline_means.get(sid, {}).get(d, 0)
            iv = iron_means.get(sid, {}).get(d, 0)
            fv = filler_means.get(sid, {}).get(d, 0)
            ir_delta = iv - bv
            fill_delta = fv - bv
            is_affected = (sid, d) in affected
            match = ""
            if is_affected and filler_means:
                match = "YES" if abs(fill_delta - ir_delta) <= 0.3 else "NO"
                if match == "YES":
                    length_matches += 1
            print(f"{sid:35s}  {d:12s}  {score_strs}  {ir_delta:+8.2f}  {fill_delta:+10.2f}  {match:>5s}")

    if affected and filler_means:
        pct = length_matches / len(affected) * 100 if affected else 0
        threshold_met = pct > 50
        print(f"\nLength-sensitivity result: {length_matches}/{len(affected)} affected dimensions matched ({pct:.0f}%)")
        print(f"Threshold (>50%): {'MET — length is the driver' if threshold_met else 'NOT MET — content matters'}")
    else:
        print("\nInsufficient data for length-sensitivity analysis.")

    print(f"\nConditions loaded: {', '.join(labels)}")


def cmd_conditional():
    condition_dirs = {
        "baseline": EVAL_DIR / "baseline",
        "always-inject": EVAL_DIR / "with-iron-rules",
        "conditional": EVAL_DIR / "with-conditional",
    }

    results = {}
    for label, d in condition_dirs.items():
        rpath = d / "results.json"
        if not rpath.exists():
            print(f"WARN: {rpath} not found — skipping {label}")
            continue
        results[label] = json.loads(rpath.read_text())

    if len(results) < 2:
        print("ERROR: Need at least 2 condition result files for comparison.")
        sys.exit(1)

    scenario_types = {}
    for f in sorted(CORPUS_DIR.glob("*.json")):
        s = json.loads(f.read_text())
        scenario_types[s["id"]] = s.get("scenario_type", "unknown")

    means = {label: per_scenario_means(data) for label, data in results.items()}
    variances = {label: per_scenario_variance(data) for label, data in results.items()}
    all_sids = sorted(set().union(*(m.keys() for m in means.values())))

    labels = [l for l in ["baseline", "always-inject", "conditional"] if l in results]
    header_scores = "  ".join(f"{l:>12s}" for l in labels)
    print(f"{'Scenario':35s}  {'Type':20s}  {'Dim':12s}  {header_scores}  {'Cond-Inj':>8s}  {'Cond-Base':>9s}")
    print("-" * (35 + 20 + 12 + 12 * len(labels) + 8 + 9 + 2 * (len(labels) + 4)))

    type_deltas: dict[str, list[float]] = {}
    for sid in all_sids:
        stype = scenario_types.get(sid, "unknown")
        for d in DIMENSIONS:
            vals = []
            for l in labels:
                v = means.get(l, {}).get(sid, {}).get(d, 0)
                vals.append(v)
            score_strs = "  ".join(f"{v:12.2f}" for v in vals)
            cond_vs_inj = ""
            cond_vs_base = ""
            if "conditional" in means and "always-inject" in means:
                cv = means["conditional"].get(sid, {}).get(d, 0)
                iv = means["always-inject"].get(sid, {}).get(d, 0)
                delta = round(cv - iv, 2)
                sign = "+" if delta > 0 else ""
                cond_vs_inj = f"{sign}{delta:5.2f}"
                if stype not in type_deltas:
                    type_deltas[stype] = []
                type_deltas[stype].append(delta)
            if "conditional" in means and "baseline" in means:
                cv = means["conditional"].get(sid, {}).get(d, 0)
                bv = means["baseline"].get(sid, {}).get(d, 0)
                delta = round(cv - bv, 2)
                sign = "+" if delta > 0 else ""
                cond_vs_base = f"{sign}{delta:5.2f}"
            print(f"{sid:35s}  {stype:20s}  {d:12s}  {score_strs}  {cond_vs_inj:>8s}  {cond_vs_base:>9s}")

    print(f"\n--- Per-Type Summary (conditional vs always-inject) ---")
    for stype in sorted(type_deltas):
        deltas = type_deltas[stype]
        mean_d = sum(deltas) / len(deltas) if deltas else 0
        print(f"  {stype:20s}  mean_delta={mean_d:+.3f}  n={len(deltas)}")

    if "conditional" in variances:
        high_var = []
        for sid, dims in variances["conditional"].items():
            for d, v in dims.items():
                if v >= VARIANCE_THRESHOLD:
                    high_var.append(f"{sid}/{d} ({v:.3f})")
        if high_var:
            print(f"\nHigh-variance scenarios (conditional, >= {VARIANCE_THRESHOLD}):")
            for hv in high_var:
                print(f"  {hv}")

    print(f"\nConditions loaded: {', '.join(labels)}")


def cmd_cross_judge():
    self_path = EVAL_DIR / "with-iron-rules" / "results.json"
    cross_path = EVAL_DIR / "cross-model" / "results.json"

    if not self_path.exists():
        print(f"ERROR: {self_path} not found")
        sys.exit(1)
    if not cross_path.exists():
        print(f"ERROR: {cross_path} not found")
        sys.exit(1)

    self_data = json.loads(self_path.read_text())
    cross_data = json.loads(cross_path.read_text())

    agent_model = cross_data.get("agent_model", "unknown")
    judge_model = cross_data.get("judge_model", "unknown")
    print(f"Agent model: {agent_model}")
    print(f"Self-judge model: {agent_model}")
    print(f"Cross-judge model: {judge_model}")

    self_means = per_scenario_means(self_data)
    cross_means = per_scenario_means(cross_data)
    self_stats = compute_stats(self_data)
    cross_stats = compute_stats(cross_data)

    print(f"\n{'':35s}  {'Self-Judge':>30s}  {'Cross-Judge':>30s}")
    print(f"{'Dimension':35s}  {'Mean':>8s}  {'Var':>8s}  {'<5%':>8s}  {'Mean':>8s}  {'Var':>8s}  {'<5%':>8s}")
    print("-" * 100)

    for d in DIMENSIONS:
        s_avg = self_stats["averages"][d]
        s_var = self_stats["variance"][d]
        c_avg = cross_stats["averages"][d]
        c_var = cross_stats["variance"][d]

        s_below5 = sum(1 for run in self_data["runs"] for r in run if r["scores"][d] < 5)
        s_total = sum(len(run) for run in self_data["runs"])
        s_pct = s_below5 / s_total * 100 if s_total else 0

        c_below5 = sum(1 for run in cross_data["runs"] for r in run if r["scores"][d] < 5)
        c_total = sum(len(run) for run in cross_data["runs"])
        c_pct = c_below5 / c_total * 100 if c_total else 0

        print(f"{d:35s}  {s_avg:8.2f}  {s_var:8.4f}  {s_pct:7.1f}%  {c_avg:8.2f}  {c_var:8.4f}  {c_pct:7.1f}%")

    print(f"\n--- Calibration Check ---")
    for label, stats in [("Self-judge", self_stats), ("Cross-judge", cross_stats)]:
        overall_mean = sum(stats["averages"].values()) / len(stats["averages"])
        data = self_data if label == "Self-judge" else cross_data
        total = sum(len(run) * len(DIMENSIONS) for run in data["runs"])
        below5 = sum(1 for run in data["runs"] for r in run for d in DIMENSIONS if r["scores"][d] < 5)
        pct_below = below5 / total * 100 if total else 0
        mean_ok = "PASS" if overall_mean < 4.5 else "FAIL"
        pct_ok = "PASS" if pct_below >= 15 else "FAIL"
        print(f"  {label}: mean={overall_mean:.2f} ({mean_ok}), below-5={pct_below:.1f}% ({pct_ok})")

    print(f"\n--- Per-Scenario Comparison ---")
    all_sids = sorted(set(self_means) | set(cross_means))
    print(f"{'Scenario':35s}  {'Dim':12s}  {'Self':>6s}  {'Cross':>6s}  {'Delta':>6s}")
    print("-" * 75)
    for sid in all_sids:
        for d in DIMENSIONS:
            sv = self_means.get(sid, {}).get(d, 0)
            cv = cross_means.get(sid, {}).get(d, 0)
            delta = round(cv - sv, 2)
            if abs(delta) >= 0.3:
                sign = "+" if delta > 0 else ""
                print(f"{sid:35s}  {d:12s}  {sv:6.2f}  {cv:6.2f}  {sign}{delta:5.2f}")


def cmd_selective():
    """Selective injection: analyze ground-truth heuristic-scenario mapping coverage."""
    gt_path = EVAL_DIR / "selective" / "ground-truth.json"
    heuristics_dir = Path(__file__).parent.parent.parent / "wiki" / "heuristics"

    if not gt_path.exists():
        print(f"ERROR: ground-truth.json not found at {gt_path}", file=sys.stderr)
        sys.exit(1)

    ground_truth = json.loads(gt_path.read_text())
    scenarios = load_scenarios(CORPUS_DIR)

    heuristic_ids = set()
    if heuristics_dir.exists():
        for f in sorted(heuristics_dir.glob("*.md")):
            if f.name == "SCHEMA.md":
                continue
            text = f.read_text()
            for line in text.split("\n"):
                if line.startswith("id:"):
                    heuristic_ids.add(line.split(":")[1].strip().strip('"'))
                    break

    print("=== Selective Injection: Matching Coverage Analysis ===\n")
    print(f"Scenarios: {len(ground_truth)}")
    print(f"Heuristics available: {len(heuristic_ids)}")

    with_matches = sum(1 for v in ground_truth.values() if v["relevant"])
    without_matches = sum(1 for v in ground_truth.values() if not v["relevant"])
    print(f"Scenarios with ≥1 match: {with_matches} ({with_matches/len(ground_truth)*100:.0f}%)")
    print(f"Scenarios with 0 matches: {without_matches}")

    heuristic_usage: dict[str, int] = {}
    for v in ground_truth.values():
        for hid in v["relevant"]:
            heuristic_usage[hid] = heuristic_usage.get(hid, 0) + 1

    print(f"\n--- Heuristic Usage Distribution ---")
    print(f"{'Heuristic':15s}  {'Scenarios':>10s}")
    print("-" * 27)
    for hid in sorted(heuristic_usage, key=lambda x: (-heuristic_usage[x], x)):
        print(f"{hid:15s}  {heuristic_usage[hid]:10d}")

    unused = heuristic_ids - set(heuristic_usage.keys())
    if unused:
        print(f"\nUnused heuristics (0 scenario matches): {', '.join(sorted(unused))}")

    match_counts = [len(v["relevant"]) for v in ground_truth.values()]
    print(f"\n--- Match Count Distribution ---")
    for count in range(max(match_counts) + 1):
        n = match_counts.count(count)
        if n:
            print(f"  {count} matches: {n} scenarios")

    print(f"\n--- Per-Scenario Mapping ---")
    print(f"{'Scenario':40s}  {'Matches':>8s}  {'Heuristics'}")
    print("-" * 80)
    for sid in sorted(ground_truth.keys()):
        entry = ground_truth[sid]
        hids = ", ".join(entry["relevant"]) if entry["relevant"] else "(none)"
        print(f"{sid:40s}  {len(entry['relevant']):8d}  {hids}")

    print(f"\n--- Coverage Summary ---")
    print(f"coverage: {with_matches}/{len(ground_truth)} scenarios ({with_matches/len(ground_truth)*100:.0f}%)")
    total_matches = sum(len(v["relevant"]) for v in ground_truth.values())
    avg = total_matches / len(ground_truth)
    print(f"avg matches per scenario: {avg:.1f}")
    print(f"blanket injection: 5 IRON RULES per scenario (always)")
    print(f"selective injection: {avg:.1f} heuristics per scenario (average)")


def main():
    parser = argparse.ArgumentParser(description="Reasoning eval data utility")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--stats", type=Path, help="Compute stats from results JSON")
    group.add_argument("--compare", nargs=2, type=Path, metavar=("BASELINE", "TREATMENT"), help="Compare two result sets")
    group.add_argument("--list", action="store_true", help="List available scenarios")
    group.add_argument("--ablation", type=Path, metavar="TRACES_DIR", help="Read ablation traces, validate, compute deltas vs full-set")
    group.add_argument("--analyze", type=Path, metavar="TRACES_DIR", help="Generate attribution matrix from ablation traces")
    group.add_argument("--conditional", action="store_true", help="3-way comparison: baseline vs always-inject vs conditional injection")
    group.add_argument("--length-test", action="store_true", help="Length-sensitivity: compare baseline vs iron-rules vs filler text injection")
    group.add_argument("--cross-judge", action="store_true", help="Cross-model judging: compare self-judge vs cross-model judge scores")
    group.add_argument("--selective", action="store_true", help="Selective injection: matching coverage analysis from ground-truth mapping")

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
    elif args.conditional:
        cmd_conditional()
    elif args.length_test:
        cmd_length_test()
    elif args.cross_judge:
        cmd_cross_judge()
    elif args.selective:
        cmd_selective()


if __name__ == "__main__":
    main()
