#!/usr/bin/env python3
"""Generate a delivery acceptance report for a dev-wiki phase.

Reads git diff, tasks.md, decision articles, test/eval results,
and produces an HTML report for human review before commit.

Usage:
    python3 scripts/generate-delivery-report.py [--phase N] [--output PATH] [--dry-run]
"""

import argparse
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WIKI = ROOT / ".dev-wiki"


def run(cmd, cwd=None, timeout=120):
    try:
        r = subprocess.run(
            cmd, capture_output=True, text=True,
            cwd=cwd or ROOT, timeout=timeout
        )
        return r.returncode, r.stdout.strip(), r.stderr.strip()
    except subprocess.TimeoutExpired:
        return 1, "", "timeout"
    except FileNotFoundError:
        return 1, "", f"command not found: {cmd[0]}"


def get_active_phase():
    ap = ROOT / ".claude" / "rules" / "active-phase.md"
    if not ap.exists():
        return None, None
    text = ap.read_text()
    m = re.search(r"Phase:\s*(\d+)\s*-\s*(.+)", text)
    if m:
        return int(m.group(1)), m.group(2).strip()
    return None, None


def get_git_diff_stats():
    _, diff, _ = run(["git", "diff", "--stat", "HEAD"])
    _, diff_staged, _ = run(["git", "diff", "--cached", "--stat"])
    _, diff_full, _ = run(["git", "diff", "HEAD"])
    lines_added = 0
    lines_removed = 0
    for line in diff_full.split("\n"):
        if line.startswith("+") and not line.startswith("+++"):
            lines_added += 1
        elif line.startswith("-") and not line.startswith("---"):
            lines_removed += 1
    _, files_changed, _ = run(["git", "diff", "--name-only", "HEAD"])
    changed = [f for f in files_changed.split("\n") if f.strip()]
    return {
        "files": changed,
        "lines_added": lines_added,
        "lines_removed": lines_removed,
        "stat": diff or diff_staged or "(no changes)",
    }


def get_tasks(phase_num):
    tasks_path = WIKI / "tasks.md"
    if not tasks_path.exists():
        return [], 0, 0
    text = tasks_path.read_text()
    in_phase = False
    tasks = []
    done = 0
    total = 0
    for line in text.split("\n"):
        if re.match(r"^## Phase\s+" + str(phase_num) + r"\b", line):
            in_phase = True
            continue
        if in_phase and line.startswith("## Phase"):
            break
        if in_phase and line.strip().startswith("- ["):
            total += 1
            is_done = line.strip().startswith("- [x]")
            if is_done:
                done += 1
            desc = re.sub(r"^- \[.\]\s*", "", line.strip())
            desc = desc.split("|")[0].strip()
            if len(desc) > 120:
                desc = desc[:117] + "..."
            tasks.append({"done": is_done, "desc": desc})
    return tasks, done, total


def get_decisions():
    dec_dir = WIKI / "articles" / "decisions"
    if not dec_dir.exists():
        return []
    decisions = []
    today = datetime.now().strftime("%Y-%m-%d")
    for f in sorted(dec_dir.glob("*.md"), key=lambda p: p.stat().st_mtime, reverse=True):
        text = f.read_text()
        m = re.search(r"^title:\s*(.+)", text, re.MULTILINE)
        title = m.group(1).strip().strip('"') if m else f.stem
        m = re.search(r"^created:\s*(.+)", text, re.MULTILINE)
        created = m.group(1).strip() if m else ""
        if created == today:
            m = re.search(r"^confidence:\s*(.+)", text, re.MULTILINE)
            conf = m.group(1).strip() if m else "unknown"
            decisions.append({"title": title, "confidence": conf, "file": f.name})
    return decisions[:10]


def run_tests():
    code, out, err = run(["make", "test"], timeout=120)
    pass_count = out.count("PASS") if out else 0
    fail_count = out.count("FAIL") if out else 0
    last_lines = "\n".join((out or err).split("\n")[-5:])
    return {"passed": code == 0, "pass_count": pass_count, "fail_count": fail_count, "summary": last_lines}


def run_eval():
    code, out, err = run(["make", "eval"], timeout=120)
    m = re.search(r"Score:\s*(\d+)/(\d+)", out or "")
    if m:
        score, total = int(m.group(1)), int(m.group(2))
    else:
        score, total = 0, 0
    return {"passed": code == 0, "score": score, "total": total, "summary": out.split("\n")[-1] if out else err}


def generate_html(phase_num, phase_name, diff_stats, tasks, done, total, decisions, test_result, eval_result):
    task_rows = ""
    for t in tasks:
        icon = "&#x2705;" if t["done"] else "&#x2B1C;"
        task_rows += f"<tr><td>{icon}</td><td>{esc(t['desc'])}</td></tr>\n"

    decision_rows = ""
    for d in decisions:
        decision_rows += f"<tr><td>{esc(d['title'])}</td><td>{esc(d['confidence'])}</td></tr>\n"

    file_rows = ""
    for f in diff_stats["files"][:50]:
        file_rows += f"<li><code>{esc(f)}</code></li>\n"

    test_status = "PASS" if test_result["passed"] else "FAIL"
    test_color = "#2d7d2d" if test_result["passed"] else "#c0392b"
    eval_status = f"{eval_result['score']}/{eval_result['total']}"
    eval_color = "#2d7d2d" if eval_result["passed"] else "#c0392b"

    pct = int(done / total * 100) if total > 0 else 0

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Delivery Report: Phase {phase_num}</title>
<style>
  body {{ font-family: -apple-system, system-ui, sans-serif; max-width: 900px; margin: 2em auto; padding: 0 1em; color: #333; line-height: 1.5; }}
  h1 {{ border-bottom: 2px solid #2c3e50; padding-bottom: 0.3em; }}
  h2 {{ color: #2c3e50; margin-top: 1.5em; }}
  .summary {{ display: grid; grid-template-columns: repeat(4, 1fr); gap: 1em; margin: 1.5em 0; }}
  .card {{ background: #f8f9fa; border-radius: 8px; padding: 1em; text-align: center; }}
  .card .num {{ font-size: 2em; font-weight: bold; }}
  .card .label {{ font-size: 0.85em; color: #666; }}
  table {{ width: 100%; border-collapse: collapse; margin: 1em 0; }}
  th, td {{ text-align: left; padding: 0.5em 0.8em; border-bottom: 1px solid #eee; }}
  th {{ background: #f0f0f0; font-weight: 600; }}
  ul {{ padding-left: 1.5em; }}
  code {{ background: #f0f0f0; padding: 0.15em 0.4em; border-radius: 3px; font-size: 0.9em; }}
  .status {{ display: inline-block; padding: 0.2em 0.6em; border-radius: 4px; color: white; font-weight: bold; }}
  .footer {{ margin-top: 3em; padding-top: 1em; border-top: 1px solid #ddd; color: #999; font-size: 0.85em; }}
</style>
</head>
<body>
<h1>Delivery Report: Phase {phase_num} &mdash; {esc(phase_name)}</h1>

<div class="summary">
  <div class="card"><div class="num">{done}/{total}</div><div class="label">Tasks ({pct}%)</div></div>
  <div class="card"><div class="num">{len(diff_stats['files'])}</div><div class="label">Files Changed</div></div>
  <div class="card"><div class="num" style="color:{test_color}">{test_status}</div><div class="label">Tests ({test_result['pass_count']} passed)</div></div>
  <div class="card"><div class="num" style="color:{eval_color}">{eval_status}</div><div class="label">Eval</div></div>
</div>

<div class="summary">
  <div class="card"><div class="num" style="color:#2d7d2d">+{diff_stats['lines_added']}</div><div class="label">Lines Added</div></div>
  <div class="card"><div class="num" style="color:#c0392b">-{diff_stats['lines_removed']}</div><div class="label">Lines Removed</div></div>
  <div class="card"><div class="num">{len(decisions)}</div><div class="label">Decisions</div></div>
  <div class="card"><div class="num">{datetime.now().strftime('%H:%M')}</div><div class="label">Generated</div></div>
</div>

<h2>Tasks</h2>
<table>
<tr><th width="30"></th><th>Description</th></tr>
{task_rows}
</table>

<h2>Decisions</h2>
{"<table><tr><th>Decision</th><th>Confidence</th></tr>" + decision_rows + "</table>" if decisions else "<p>No new decisions this phase.</p>"}

<h2>Files Changed</h2>
<ul>
{file_rows}
{"<li><em>... and " + str(len(diff_stats['files']) - 50) + " more</em></li>" if len(diff_stats['files']) > 50 else ""}
</ul>

<h2>Test Results</h2>
<p><span class="status" style="background:{test_color}">{test_status}</span> {test_result['pass_count']} passed, {test_result['fail_count']} failed</p>
<pre>{esc(test_result['summary'])}</pre>

<h2>Eval Results</h2>
<p><span class="status" style="background:{eval_color}">{eval_status}</span></p>
<pre>{esc(eval_result['summary'])}</pre>

<div class="footer">
  Generated {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} by generate-delivery-report.py
</div>
</body>
</html>"""


def esc(s):
    return str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def main():
    parser = argparse.ArgumentParser(
        description="Generate a delivery acceptance report for a dev-wiki phase."
    )
    parser.add_argument("--phase", type=int, help="Phase number (auto-detected from active-phase.md)")
    parser.add_argument("--output", type=str, default=None, help="Output HTML path (default: docs/delivery-report.html)")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be generated without running tests/eval")
    args = parser.parse_args()

    phase_num, phase_name = get_active_phase()
    if args.phase:
        phase_num = args.phase
    if not phase_num:
        print("Error: no active phase found. Set --phase N.", file=sys.stderr)
        sys.exit(1)
    if not phase_name:
        phase_name = f"Phase {phase_num}"

    output_path = Path(args.output) if args.output else ROOT / "docs" / "delivery-report.html"

    if args.dry_run:
        print(f"Phase: {phase_num} - {phase_name}")
        print(f"Output: {output_path}")
        tasks, done, total = get_tasks(phase_num)
        print(f"Tasks: {done}/{total}")
        diff = get_git_diff_stats()
        print(f"Files changed: {len(diff['files'])}")
        print("(dry run — skipping test/eval execution and HTML generation)")
        return

    print(f"Generating delivery report for Phase {phase_num}...", file=sys.stderr)

    diff_stats = get_git_diff_stats()
    tasks, done, total = get_tasks(phase_num)
    decisions = get_decisions()

    print("  Running tests...", file=sys.stderr)
    test_result = run_tests()
    print("  Running eval...", file=sys.stderr)
    eval_result = run_eval()

    html = generate_html(phase_num, phase_name, diff_stats, tasks, done, total, decisions, test_result, eval_result)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(html)
    print(f"Report written to {output_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
