#!/usr/bin/env python3
"""Generate a comprehensive HTML report of the Nana Dev Kit package."""

import os
import subprocess
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parent.parent


def count_lines(path):
    try:
        return sum(1 for _ in open(path))
    except (OSError, UnicodeDecodeError):
        return 0


def get_version():
    v = (ROOT / "VERSION").read_text().strip()
    return v


def get_file_tree():
    result = subprocess.run(
        ["git", "ls-files"], capture_output=True, text=True, cwd=ROOT
    )
    if result.returncode != 0:
        return []
    files = sorted(result.stdout.strip().split("\n"))
    return [f for f in files if f and not f.startswith(".dev-wiki/")]


def count_tests():
    result = subprocess.run(
        ["make", "test"], capture_output=True, text=True, cwd=ROOT
    )
    total = 0
    for line in result.stdout.split("\n"):
        if "run," in line and "passed" in line:
            parts = line.strip().split()
            for i, p in enumerate(parts):
                if p == "run,":
                    total += int(parts[i - 1])
    return total


def get_git_info():
    tags = subprocess.run(
        ["git", "tag", "-l", "--sort=-v:refname"],
        capture_output=True, text=True, cwd=ROOT,
    ).stdout.strip().split("\n")
    commits = subprocess.run(
        ["git", "log", "--oneline", "-5"],
        capture_output=True, text=True, cwd=ROOT,
    ).stdout.strip()
    return tags[0] if tags and tags[0] else "none", commits


def get_memory_deps():
    req = ROOT / "memory_server" / "requirements.txt"
    opt = ROOT / "memory_server" / "requirements-optional.txt"
    required = [l.strip() for l in open(req) if l.strip() and not l.startswith("#")]
    optional = [l.strip() for l in open(opt) if l.strip() and not l.startswith("#")]
    return required, optional


def categorize_files(files):
    categories = {
        "Core Scripts": [],
        "Test Suite": [],
        "Memory Server": [],
        "Templates — Layer 1: Instructions": [],
        "Templates — Layer 2: Identity": [],
        "Templates — Layer 3: Hooks": [],
        "Templates — Layer 3: Skills": [],
        "Templates — Layer 4: Pre-commit": [],
        "Templates — Layer 5: CI & GitHub": [],
        "Templates — Config": [],
        "Documentation": [],
        "CI & Build": [],
        "Other": [],
    }
    for f in files:
        lines = count_lines(ROOT / f)
        entry = (f, lines)
        if f.startswith("memory_server/"):
            categories["Memory Server"].append(entry)
        elif f.startswith("tests/"):
            categories["Test Suite"].append(entry)
        elif f.startswith("templates/.claude/hooks/") or f == "templates/.claude/settings.json":
            categories["Templates — Layer 3: Hooks"].append(entry)
        elif f.startswith("templates/.claude/skills/"):
            categories["Templates — Layer 3: Skills"].append(entry)
        elif f.startswith("templates/.claude/rules/"):
            categories["Templates — Layer 2: Identity"].append(entry)
        elif f in ("templates/AGENTS.md", "templates/.github/instructions/nana.instructions.md",
                    "templates/.github/instructions/workflow.instructions.md"):
            categories["Templates — Layer 1: Instructions"].append(entry)
        elif f == "templates/.pre-commit-config.yaml":
            categories["Templates — Layer 4: Pre-commit"].append(entry)
        elif f.startswith("templates/.github/") or f == "templates/pyproject.toml":
            categories["Templates — Layer 5: CI & GitHub"].append(entry)
        elif f.startswith("templates/"):
            categories["Templates — Config"].append(entry)
        elif f.startswith("scripts/") or f == "Makefile":
            categories["Core Scripts"].append(entry)
        elif f.startswith(".github/") or f == ".gitignore":
            categories["CI & Build"].append(entry)
        elif f in ("install.sh",):
            categories["Core Scripts"].append(entry)
        elif f in ("README.md", "self-test.md", "VERSION"):
            categories["Documentation"].append(entry)
        else:
            categories["Other"].append(entry)
    return {k: v for k, v in categories.items() if v}


LAYERS = [
    ("1. Instructions", "Agent-surface config synced to CLAUDE.md, Copilot, Cursor, Gemini",
     "AGENTS.md, scripts/sync-rules.sh"),
    ("2. Identity", "Development personality and technical posture",
     ".claude/rules/nana-soul.md"),
    ("3. Hooks & Skills", "Claude Code lifecycle hooks + /py-init, /py-lint, /py-test, /py-review",
     ".claude/hooks/, .claude/skills/, .claude/settings.json"),
    ("4. Pre-commit", "Commit-time guardrails: ruff, mypy, gitleaks, sync-rules",
     ".pre-commit-config.yaml"),
    ("5. CI", "GitHub Actions: lint, typecheck, test, security audit",
     ".github/workflows/ci.yml"),
]

WORKFLOWS = [
    ("Install", "git clone → install.sh", "Copies py-init skill, nana-soul identity, memory server to ~/.claude/. Creates venv, installs deps, registers MCP server."),
    ("Scaffold", "/py-init in a project", "New: full 5-layer scaffold. Existing: 10-dimension feasibility scan → approval gate → transform → validation."),
    ("Develop", "Daily coding with Claude Code", "Session-start loads dev-wiki state + memory snapshot. Hooks auto-format, block dangerous ops, audit, gate tests."),
    ("Lifecycle", "/dev-init → /dev-plan → implement → /dev-debrief", "Phase-based planning, TDD task execution, session capture. Decisions and journal tracked in .dev-wiki/."),
    ("Memory", "Persistent cross-session context", "MCP server stores project decisions, conventions, user preferences. FTS5 search. Optional vector similarity via fastembed."),
    ("Sync", "make sync-rules", "Propagates AGENTS.md to CLAUDE.md, copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md."),
    ("Test", "make test", "Runs 40 automated bash tests across install, sync, and template verification."),
]


def generate_html():
    version = get_version()
    files = get_file_tree()
    categories = categorize_files(files)
    total_lines = sum(count_lines(ROOT / f) for f in files)
    test_count = count_tests()
    tag, commits = get_git_info()
    req_deps, opt_deps = get_memory_deps()
    now = datetime.now().strftime("%Y-%m-%d %H:%M")

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Nana Dev Kit — Package Report v{version}</title>
<style>
  :root {{ --bg: #0d1117; --fg: #c9d1d9; --accent: #58a6ff; --border: #30363d;
           --card: #161b22; --green: #3fb950; --yellow: #d29922; --red: #f85149; }}
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
         background: var(--bg); color: var(--fg); line-height: 1.6; padding: 2rem; max-width: 1200px; margin: 0 auto; }}
  h1 {{ color: var(--accent); font-size: 2rem; margin-bottom: 0.5rem; }}
  h2 {{ color: var(--accent); font-size: 1.4rem; margin: 2rem 0 1rem; border-bottom: 1px solid var(--border); padding-bottom: 0.5rem; }}
  h3 {{ color: var(--fg); font-size: 1.1rem; margin: 1.5rem 0 0.5rem; }}
  .subtitle {{ color: #8b949e; font-size: 0.95rem; margin-bottom: 2rem; }}
  .stats {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 1rem; margin: 1.5rem 0; }}
  .stat {{ background: var(--card); border: 1px solid var(--border); border-radius: 8px; padding: 1rem; text-align: center; }}
  .stat .num {{ font-size: 2rem; font-weight: 700; color: var(--accent); }}
  .stat .label {{ font-size: 0.85rem; color: #8b949e; }}
  table {{ width: 100%; border-collapse: collapse; margin: 1rem 0; font-size: 0.9rem; }}
  th, td {{ padding: 0.5rem 0.75rem; border: 1px solid var(--border); text-align: left; }}
  th {{ background: var(--card); color: var(--accent); font-weight: 600; }}
  tr:nth-child(even) {{ background: rgba(22,27,34,0.5); }}
  code {{ background: var(--card); padding: 0.15rem 0.4rem; border-radius: 4px; font-size: 0.85rem; }}
  .badge {{ display: inline-block; padding: 0.15rem 0.5rem; border-radius: 12px; font-size: 0.75rem; font-weight: 600; }}
  .badge-green {{ background: rgba(63,185,80,0.15); color: var(--green); }}
  .badge-yellow {{ background: rgba(210,153,34,0.15); color: var(--yellow); }}
  .category {{ margin: 1.5rem 0; }}
  .category h3 {{ color: var(--accent); font-size: 1rem; margin-bottom: 0.5rem; }}
  .file-list {{ list-style: none; font-family: monospace; font-size: 0.85rem; }}
  .file-list li {{ padding: 0.2rem 0; display: flex; justify-content: space-between; border-bottom: 1px solid rgba(48,54,61,0.5); }}
  .file-list .lines {{ color: #8b949e; }}
  .workflow {{ background: var(--card); border: 1px solid var(--border); border-radius: 8px; padding: 1rem; margin: 0.75rem 0; }}
  .workflow strong {{ color: var(--accent); }}
  .workflow .trigger {{ color: #8b949e; font-size: 0.85rem; }}
  footer {{ margin-top: 3rem; padding-top: 1rem; border-top: 1px solid var(--border); color: #8b949e; font-size: 0.8rem; text-align: center; }}
</style>
</head>
<body>

<h1>Nana Dev Kit</h1>
<p class="subtitle">5-Layer Python Development Harness Scaffolder &mdash; Package Report v{version} &mdash; Generated {now}</p>

<div class="stats">
  <div class="stat"><div class="num">{len(files)}</div><div class="label">Files</div></div>
  <div class="stat"><div class="num">{total_lines:,}</div><div class="label">Lines of Code</div></div>
  <div class="stat"><div class="num">{test_count}</div><div class="label">Automated Tests</div></div>
  <div class="stat"><div class="num">5</div><div class="label">Harness Layers</div></div>
  <div class="stat"><div class="num">{tag}</div><div class="label">Latest Tag</div></div>
</div>

<h2>Architecture: The 5 Layers</h2>
<p>Every scaffolded project receives all 5 layers, configured and wired together.</p>
<table>
  <tr><th>Layer</th><th>Purpose</th><th>Key Files</th></tr>
"""
    for name, purpose, key_files in LAYERS:
        html += f"  <tr><td><strong>{name}</strong></td><td>{purpose}</td><td><code>{key_files}</code></td></tr>\n"

    html += """</table>

<h2>Workflows</h2>
"""
    for name, trigger, desc in WORKFLOWS:
        html += f"""<div class="workflow">
  <strong>{name}</strong> <span class="trigger">&mdash; {trigger}</span>
  <p>{desc}</p>
</div>
"""

    html += """<h2>Memory System</h2>
<p>Persistent cross-session memory via MCP server. Installed globally by <code>install.sh</code> in an isolated venv.</p>
<table>
  <tr><th>Component</th><th>Details</th></tr>
  <tr><td>Storage</td><td>SQLite + FTS5 full-text search. Optional vector similarity via fastembed.</td></tr>
  <tr><td>Scope</td><td><code>.memory/memory.db</code> (project) and <code>~/.memory/global.db</code> (global)</td></tr>
  <tr><td>Transport</td><td>MCP stdio protocol via <code>python3 -m memory_server</code></td></tr>
  <tr><td>Tools</td><td>store, search, verify, contradict, forget, tag, stats, export, prune, consolidate, import</td></tr>
"""
    html += f"  <tr><td>Required Deps</td><td>{', '.join(req_deps)}</td></tr>\n"
    html += f"  <tr><td>Optional Deps</td><td>{', '.join(opt_deps)} <span class='badge badge-yellow'>~500MB</span></td></tr>\n"
    html += """</table>

<h2>Dev-Wiki Lifecycle</h2>
<p>Phase-based development lifecycle tracked in <code>.dev-wiki/</code>. Integrated into session-start hook.</p>
<table>
  <tr><th>Artifact</th><th>Purpose</th></tr>
  <tr><td><code>_CURRENT_STATE.md</code></td><td>Living project state: active phase, next action, key artifacts</td></tr>
  <tr><td><code>_ARCHITECTURE.md</code></td><td>Project structure, modules, dependencies, test organization</td></tr>
  <tr><td><code>tasks.md</code></td><td>Phase-ordered task list with TDD cycles and success criteria</td></tr>
  <tr><td><code>articles/decisions/</code></td><td>Architectural decision records with confidence and rationale</td></tr>
  <tr><td><code>articles/journal/</code></td><td>Session debrief entries with health delta and observations</td></tr>
</table>

<h2>Session Context Injection</h2>
<p>The session-start hook composes context from 4 sources (frozen snapshot pattern &mdash; read once, never edited mid-session):</p>
<table>
  <tr><th>#</th><th>Source</th><th>What It Provides</th></tr>
  <tr><td>1</td><td><code>.dev-wiki/_CURRENT_STATE.md</code></td><td>Active phase, recommended next action</td></tr>
  <tr><td>2</td><td><code>.memory/MEMORY.md</code></td><td>Project memory snapshot (decisions, conventions)</td></tr>
  <tr><td>3</td><td><code>PROJECT_STATE.md</code></td><td>Manual cross-session notes</td></tr>
  <tr><td>4</td><td><code>.claude/rules/py-session-state.md</code></td><td>Compaction-safe session state</td></tr>
</table>

"""
    html += "<h2>File Inventory</h2>\n"
    for cat_name, cat_files in categories.items():
        cat_total = sum(lines for _, lines in cat_files)
        html += f"""<div class="category">
  <h3>{cat_name} <span class="badge badge-green">{len(cat_files)} files, {cat_total:,} lines</span></h3>
  <ul class="file-list">
"""
        for fname, lines in cat_files:
            html += f"    <li><span>{fname}</span><span class='lines'>{lines}</span></li>\n"
        html += "  </ul>\n</div>\n"

    html += """<h2>Test Coverage</h2>
<table>
  <tr><th>Suite</th><th>File</th><th>Focus</th></tr>
  <tr><td>Install</td><td><code>tests/test_install.sh</code></td><td>Idempotency, MCP registration, venv bootstrap, edge cases</td></tr>
  <tr><td>Sync</td><td><code>tests/test_sync_rules.sh</code></td><td>4 output files, headers, content propagation, error cases</td></tr>
  <tr><td>Templates</td><td><code>tests/test_templates.sh</code></td><td>Placeholder presence in AGENTS.md and pyproject.toml</td></tr>
  <tr><td>Manual</td><td><code>self-test.md</code></td><td>13 scenarios across all 5 layers + retrofit</td></tr>
</table>

<h2>Recent Git History</h2>
<pre style="background: var(--card); padding: 1rem; border-radius: 8px; font-size: 0.85rem;">"""
    html += commits
    html += """</pre>

<footer>
  Generated by <code>scripts/generate-report.py</code> &mdash; run <code>make report</code> to regenerate
</footer>

</body>
</html>
"""
    return html


if __name__ == "__main__":
    output = ROOT / "docs" / "report.html"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(generate_html())
    print(f"Report generated: {output}")
