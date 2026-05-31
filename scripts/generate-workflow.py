#!/usr/bin/env python3
"""Generate a versioned HTML workflow breakdown of the Nana Dev Kit harness."""

import json
import subprocess
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parent.parent


def get_version():
    return (ROOT / "VERSION").read_text().strip()


def read_file(rel_path):
    p = ROOT / rel_path
    if p.is_file():
        return p.read_text()
    return ""


def count_lines(path):
    try:
        return sum(1 for _ in open(path))
    except (OSError, UnicodeDecodeError):
        return 0


def get_hook_scripts():
    hooks_dir = ROOT / "templates" / ".claude" / "hooks"
    scripts = []
    for f in sorted(hooks_dir.glob("*.sh")):
        content = f.read_text()
        lines = content.split("\n")
        comment = next((l.lstrip("# ") for l in lines if l.startswith("# ") and "hook" in l.lower()), lines[1].lstrip("# ") if len(lines) > 1 else "")
        scripts.append((f.name, count_lines(f), comment, content))
    return scripts


def get_settings_json():
    return read_file("templates/.claude/settings.json")


def get_template_files():
    result = subprocess.run(
        ["git", "ls-files", "templates/"], capture_output=True, text=True, cwd=ROOT
    )
    if result.returncode != 0:
        return []
    return sorted(f for f in result.stdout.strip().split("\n") if f)


def get_test_info():
    test_dir = ROOT / "tests"
    suites = []
    for f in sorted(test_dir.glob("test_*.sh")):
        content = f.read_text()
        test_count = content.count("assert_")
        comment = ""
        for line in content.split("\n"):
            if line.startswith("# ") and "test" in line.lower():
                comment = line.lstrip("# ")
                break
        suites.append((f.name, count_lines(f), test_count, comment))
    return suites


def get_precommit_hooks():
    content = read_file("templates/.pre-commit-config.yaml")
    hooks = []
    current_repo = ""
    for line in content.split("\n"):
        stripped = line.strip()
        if stripped.startswith("- repo:"):
            current_repo = stripped.split("repo:")[-1].strip()
        elif stripped.startswith("- id:"):
            hook_id = stripped.split("id:")[-1].strip()
            hooks.append((hook_id, current_repo))
    return hooks


def get_ci_jobs():
    content = read_file("templates/.github/workflows/ci.yml")
    jobs = []
    in_jobs = False
    current_job = ""
    steps = []
    for line in content.split("\n"):
        if line.strip() == "jobs:":
            in_jobs = True
            continue
        if in_jobs:
            if line and not line.startswith(" ") and not line.startswith("\t"):
                in_jobs = False
                continue
            if len(line) > 2 and line[2] != " " and line.strip().endswith(":"):
                if current_job:
                    jobs.append((current_job, steps))
                current_job = line.strip().rstrip(":")
                steps = []
            elif "- run:" in line:
                steps.append(line.split("- run:")[-1].strip())
            elif "- name:" in line:
                steps.append(line.split("- name:")[-1].strip())
    if current_job:
        jobs.append((current_job, steps))
    return jobs


CSS = """:root { --bg: #0d1117; --fg: #c9d1d9; --accent: #58a6ff; --border: #30363d;
         --card: #161b22; --green: #3fb950; --yellow: #d29922; --red: #f85149;
         --dim: #8b949e; --code-bg: #1c2128; }
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
       background: var(--bg); color: var(--fg); line-height: 1.6; padding: 2rem;
       max-width: 1200px; margin: 0 auto; }
h1 { color: var(--accent); font-size: 2rem; margin-bottom: 0.25rem; }
h2 { color: var(--accent); font-size: 1.4rem; margin: 2.5rem 0 1rem;
     border-bottom: 1px solid var(--border); padding-bottom: 0.5rem; }
h3 { color: var(--fg); font-size: 1.1rem; margin: 1.5rem 0 0.5rem; }
h4 { color: var(--dim); font-size: 0.95rem; margin: 1rem 0 0.3rem; text-transform: uppercase; letter-spacing: 0.05em; }
.subtitle { color: var(--dim); font-size: 0.95rem; margin-bottom: 2rem; }
.flow { background: var(--card); border: 1px solid var(--border); border-radius: 8px;
        padding: 1.25rem; margin: 0.75rem 0; }
.flow-title { color: var(--accent); font-weight: 700; font-size: 1.05rem; margin-bottom: 0.5rem; }
.flow-trigger { color: var(--dim); font-size: 0.85rem; margin-bottom: 0.5rem; }
.flow ol, .flow ul { margin-left: 1.5rem; margin-top: 0.3rem; }
.flow li { margin-bottom: 0.25rem; font-size: 0.92rem; }
table { width: 100%; border-collapse: collapse; margin: 1rem 0; font-size: 0.9rem; }
th, td { padding: 0.5rem 0.75rem; border: 1px solid var(--border); text-align: left; }
th { background: var(--card); color: var(--accent); font-weight: 600; }
tr:nth-child(even) { background: rgba(22,27,34,0.5); }
code { background: var(--code-bg); padding: 0.15rem 0.4rem; border-radius: 4px;
       font-size: 0.85rem; font-family: 'SF Mono', Menlo, monospace; }
pre { background: var(--code-bg); padding: 1rem; border-radius: 8px; font-size: 0.82rem;
      overflow-x: auto; line-height: 1.5; border: 1px solid var(--border); margin: 0.75rem 0; }
.badge { display: inline-block; padding: 0.15rem 0.5rem; border-radius: 12px;
         font-size: 0.75rem; font-weight: 600; }
.badge-green { background: rgba(63,185,80,0.15); color: var(--green); }
.badge-yellow { background: rgba(210,153,34,0.15); color: var(--yellow); }
.badge-blue { background: rgba(88,166,255,0.15); color: var(--accent); }
.quality-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(340px, 1fr)); gap: 1rem; margin: 1rem 0; }
.quality-card { background: var(--card); border: 1px solid var(--border); border-radius: 8px; padding: 1rem; }
.quality-card h4 { margin-top: 0; color: var(--accent); text-transform: none; letter-spacing: 0; }
.quality-card ul { margin-left: 1.2rem; margin-top: 0.3rem; }
.quality-card li { font-size: 0.88rem; margin-bottom: 0.2rem; }
.dep-arrow { color: var(--accent); font-weight: 600; }
.toc { background: var(--card); border: 1px solid var(--border); border-radius: 8px;
       padding: 1rem 1.5rem; margin: 1.5rem 0; }
.toc h3 { margin: 0 0 0.5rem; color: var(--accent); }
.toc ol { margin-left: 1.5rem; }
.toc li { margin-bottom: 0.2rem; font-size: 0.9rem; }
.toc a { color: var(--accent); text-decoration: none; }
.toc a:hover { text-decoration: underline; }
footer { margin-top: 3rem; padding-top: 1rem; border-top: 1px solid var(--border);
         color: var(--dim); font-size: 0.8rem; text-align: center; }"""


def generate_html():
    version = get_version()
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    hook_scripts = get_hook_scripts()
    settings = get_settings_json()
    template_files = get_template_files()
    test_suites = get_test_info()
    precommit_hooks = get_precommit_hooks()
    ci_jobs = get_ci_jobs()

    total_tests = sum(t[2] for t in test_suites)

    tpl_by_layer = {
        "Layer 1: Instructions": [],
        "Layer 2: Identity": [],
        "Layer 3: Hooks": [],
        "Layer 3: Skills": [],
        "Layer 4: Pre-commit": [],
        "Layer 5: CI & GitHub": [],
        "Config": [],
    }
    for f in template_files:
        if "AGENTS.md" in f or "instructions/" in f:
            tpl_by_layer["Layer 1: Instructions"].append(f)
        elif "/rules/" in f:
            tpl_by_layer["Layer 2: Identity"].append(f)
        elif "/hooks/" in f or "/settings.json" in f:
            tpl_by_layer["Layer 3: Hooks"].append(f)
        elif "/skills/" in f:
            tpl_by_layer["Layer 3: Skills"].append(f)
        elif "pre-commit" in f:
            tpl_by_layer["Layer 4: Pre-commit"].append(f)
        elif ".github/" in f:
            tpl_by_layer["Layer 5: CI & GitHub"].append(f)
        elif f.endswith(".toml"):
            tpl_by_layer["Config"].append(f)
        else:
            tpl_by_layer["Config"].append(f)

    # Parse settings.json for hook wiring
    try:
        hook_config = json.loads(settings)["hooks"]
    except (json.JSONDecodeError, KeyError):
        hook_config = {}

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Nana Dev Kit &mdash; Workflow Breakdown v{version}</title>
<style>{CSS}</style>
</head>
<body>

<h1>Nana Dev Kit &mdash; Workflow Breakdown</h1>
<p class="subtitle">7-Layer Python Development Harness &mdash; v{version} &mdash; Generated {now}</p>

<div class="toc">
<h3>Contents</h3>
<ol>
<li><a href="#flows">End-to-End Flows</a></li>
<li><a href="#layers">The 7 Layers &mdash; Deep Dive</a></li>
<li><a href="#hooks">Hook System Walkthrough</a></li>
<li><a href="#templates">Template Inventory</a></li>
<li><a href="#quality">Quality Signals</a></li>
<li><a href="#deps">Dependency &amp; Integration Map</a></li>
<li><a href="#memory">Memory &amp; Dev-Wiki Integration</a></li>
</ol>
</div>

<!-- ============================================================ -->
<h2 id="flows">1. End-to-End Flows</h2>

<div class="flow">
<div class="flow-title">Install Flow</div>
<div class="flow-trigger">Trigger: <code>git clone &hellip; &amp;&amp; ~/nana-dev-kit/install.sh [--all|--core-only|--no-python|--dry-run|--status]</code></div>
<ol>
<li>Validates source files exist. Parses module flags (default: <code>--all</code>)</li>
<li><strong>Core module:</strong> copies 3 identity rules (nana-soul.md, nana-personal.md, file-lifecycle.md) + kit path marker + memory_server/</li>
<li><strong>Python module:</strong> copies py-init + spec skills (skip with <code>--no-python</code>)</li>
<li><strong>Dev-wiki module:</strong> copies 6 dev-lifecycle skill dirs; enforcement/lifecycle hooks are project-scoped and install per-project (via <code>/py-init</code> or <code>--project-local</code>), not globally</li>
<li><strong>Knowledge-wiki module:</strong> copies 11 wiki skill dirs</li>
<li>Creates isolated venv at <code>~/.claude/memory_server/.venv/</code>, installs deps</li>
<li>Registers MCP server + hook events in <code>~/.claude/settings.json</code> via idempotent JSON merge</li>
<li>Creates <code>.claude/enforce</code> marker for project opt-in</li>
<li>Outputs &ldquo;Getting Started&rdquo; with 3 paths: <code>/dev-init</code>, <code>/py-init</code>, <code>/wiki-init</code></li>
</ol>
</div>

<div class="flow">
<div class="flow-title">Scaffold Flow &mdash; New Project</div>
<div class="flow-trigger">Trigger: <code>/py-init</code> in an empty directory</div>
<ol>
<li>Reads kit path from <code>~/.claude/.nana-dev-kit-path</code></li>
<li>Detects no existing project markers (pyproject.toml, setup.py, .pre-commit-config.yaml, etc.)</li>
<li>Prompts for package name and description</li>
<li>Copies all 5 layers from <code>templates/</code>:
  <ul>
  <li>AGENTS.md + GitHub instructions &rarr; Layer 1</li>
  <li>.claude/rules/nana-soul.md + py-session-state.md &rarr; Layer 2</li>
  <li>.claude/hooks/ (6 scripts) + settings.json &rarr; Layer 3</li>
  <li>.pre-commit-config.yaml &rarr; Layer 4</li>
  <li>.github/workflows/ci.yml + PR template + CODEOWNERS &rarr; Layer 5</li>
  </ul></li>
<li>Substitutes placeholders: <code>{{{{PACKAGE_NAME}}}}</code>, <code>{{{{PROJECT_DESCRIPTION}}}}</code>, <code>{{{{PROJECT_NAME}}}}</code></li>
<li>Runs <code>make sync-rules</code> to propagate AGENTS.md &rarr; CLAUDE.md, Copilot, Cursor, Gemini</li>
</ol>
</div>

<div class="flow">
<div class="flow-title">Scaffold Flow &mdash; Existing Project</div>
<div class="flow-trigger">Trigger: <code>/py-init</code> in a project with existing config</div>
<ol>
<li>Detects existing project markers</li>
<li><strong>Feasibility scan</strong>: 10-dimension assessment (build system, source layout, linter, type checker, test framework, pre-commit, deps, agent config, CI, secrets)</li>
<li>Each dimension classified: <span class="badge badge-green">compatible</span> <span class="badge badge-yellow">upgradeable</span> <span class="badge badge-yellow">blocking</span></li>
<li>Presents scan report table &mdash; requires explicit approval to proceed</li>
<li><strong>Transform</strong>: upgrades toolchain in place (merge, not overwrite)</li>
<li><strong>Validation</strong>: verifies all layers are wired correctly post-transform</li>
</ol>
</div>

<div class="flow">
<div class="flow-title">Development Flow</div>
<div class="flow-trigger">Trigger: opening Claude Code in a scaffolded project</div>
<ol>
<li><strong>SessionStart hook</strong> fires &rarr; loads context and runs checks:
  <ul>
  <li><code>.dev-wiki/_CURRENT_STATE.md</code> &mdash; active phase + recommended action</li>
  <li><code>.claude/rules/active-phase.md</code> &mdash; gate compliance check</li>
  <li><code>.claude/rules/py-session-state.md</code> &mdash; compaction-safe session state</li>
  <li>Memory search guidance from active task topic</li>
  <li>Stale <code>.pending-commit</code> sidecar detection</li>
  <li>Crash recovery (commit mtime vs state mtime)</li>
  <li>Enforcement status + <code>[nana:kit]</code> summary line</li>
  </ul></li>
<li><strong>During coding</strong>: hooks fire on tool use:
  <ul>
  <li>Every file write &rarr; auto-ruff-format + secret scan + audit log + post-commit detection</li>
  <li>Every bash command &rarr; dangerous command blocker + loop detection</li>
  <li>Implementation writes &rarr; enforce-spec blocks without approved spec</li>
  </ul></li>
<li><strong>On stop</strong>: enforce-loop checks deliverables, test gate checks pytest, 6-point code review prompt</li>
</ol>
</div>

<div class="flow">
<div class="flow-title">Lifecycle Flow</div>
<div class="flow-trigger">Trigger: <code>/dev-init</code> &rarr; <code>/spec</code> &rarr; <code>/dev-plan</code> &rarr; implement &rarr; <code>/dev-debrief</code></div>
<ol>
<li><code>/dev-init</code> &mdash; bootstraps <code>.dev-wiki/</code> with phases, architecture, state, tasks</li>
<li><code>/spec</code> &mdash; structured contract with adversarial constraints and two-tier review (Tier 0 structural lint + Tier 1 semantic subagent). Provenance marker <code>&lt;!-- nana:approved --&gt;</code></li>
<li><code>/dev-plan</code> &mdash; plans one phase: state loader &rarr; cross-wiki knowledge &rarr; T0 thinking &rarr; approach reviewer &rarr; plan reviewer &rarr; artifact writer</li>
<li><strong>Implement</strong> &mdash; follows task order with TDD cycle (RED &rarr; GREEN &rarr; REFACTOR &rarr; VERIFY). Success criteria verified per task. Blocked after 3 failed attempts.</li>
<li><code>/dev-debrief</code> &mdash; significance-scored capture: decisions, journal, memory harvest, review gate, state refresh</li>
</ol>
</div>

<div class="flow">
<div class="flow-title">Sync Flow</div>
<div class="flow-trigger">Trigger: <code>make sync-rules</code> after editing AGENTS.md</div>
<ol>
<li>Reads AGENTS.md (single source of truth)</li>
<li>Writes 4 outputs with AUTO-GENERATED headers:
  <ul>
  <li>CLAUDE.md &mdash; Claude Code</li>
  <li>.github/copilot-instructions.md &mdash; GitHub Copilot</li>
  <li>.cursor/rules/main.mdc &mdash; Cursor</li>
  <li>GEMINI.md &mdash; Gemini Code Assist</li>
  </ul></li>
<li>Pre-checks: validates AGENTS.md exists, target directory is writable</li>
</ol>
</div>

<!-- ============================================================ -->
<h2 id="layers">2. The 7 Layers &mdash; Deep Dive</h2>

<table>
<tr><th>Layer</th><th>What</th><th>When It Fires</th><th>Effect</th><th>Key Files</th></tr>
<tr>
  <td><strong>1. Instructions</strong></td>
  <td>Agent-surface config</td>
  <td>At session start (each agent reads its config file)</td>
  <td>All 4 AI coding agents share the same project instructions from a single source</td>
  <td><code>AGENTS.md</code>, <code>scripts/sync-rules.sh</code></td>
</tr>
<tr>
  <td><strong>2. Identity</strong></td>
  <td>Development personality + file lifecycle</td>
  <td>Loaded as global Claude Code rule (always active)</td>
  <td>Sets technical posture, voice, thinking protocol, memory discipline. File lifecycle routing table.</td>
  <td><code>.claude/rules/nana-soul.md</code>, <code>nana-personal.md</code>, <code>file-lifecycle.md</code></td>
</tr>
<tr>
  <td><strong>3. Hooks &amp; Skills</strong></td>
  <td>24 skills + 12 lifecycle hooks</td>
  <td>SessionStart, PreToolUse, PostToolUse, PreCompact, Stop</td>
  <td>Auto-format, block dangerous commands, scan secrets, audit writes, post-commit detection, loop detection, crash recovery, gate tests, review code. 24 skills including dev lifecycle, wiki, scaffold, spec, /nana, /memory-consolidate.</td>
  <td><code>.claude/hooks/*</code>, <code>.claude/skills/*</code>, <code>.claude/settings.json</code></td>
</tr>
<tr>
  <td><strong>4. Enforcement</strong></td>
  <td>Spec + deliverable gating</td>
  <td>PreToolUse (writes), Stop (session end), PostToolUse (failures)</td>
  <td>Blocks writes without approved spec. Checks deliverables at stop. Detects repeated failure loops. Events logged to <code>.dev-wiki/enforcement.log</code>.</td>
  <td><code>enforce-spec.sh</code>, <code>enforce-loop.sh</code>, <code>detect-loop.sh</code> (global)</td>
</tr>
<tr>
  <td><strong>5. Eval</strong></td>
  <td>43-scenario binary-scored harness</td>
  <td>On demand (<code>make eval</code>)</td>
  <td>Validates hook contracts, skill artifacts, lifecycle compliance, context injection. Requires jq.</td>
  <td><code>eval/corpus/*</code>, <code>scripts/eval-runner.sh</code></td>
</tr>
<tr>
  <td><strong>6. Pre-commit</strong></td>
  <td>Commit-time guardrails</td>
  <td>On <code>git commit</code> (via pre-commit framework)</td>
  <td>Enforces ruff lint+format, mypy strict, gitleaks secret scan, notebook hygiene, AGENTS.md sync</td>
  <td><code>.pre-commit-config.yaml</code></td>
</tr>
<tr>
  <td><strong>7. CI</strong></td>
  <td>GitHub Actions pipeline</td>
  <td>On push/PR to main</td>
  <td>4 parallel jobs: lint (ruff), typecheck (mypy), test (pytest 85% coverage gate), security (pip audit + gitleaks)</td>
  <td><code>.github/workflows/ci.yml</code></td>
</tr>
</table>

<h3>Layer Interaction Model</h3>
<p>Layers form a defense-in-depth chain. Each layer catches issues the previous one might miss:</p>
<pre>
  Code written by AI
       │
       ▼
  ┌─── Layer 3: Hooks ───────────────────────────────────────┐
  │ SessionStart → session-start.sh (context + crash recovery)│
  │ PreToolUse   → block-dangerous-bash (prevent rm -rf, etc) │
  │ PostToolUse  → auto-ruff-format (instant fix)             │
  │ PostToolUse  → scan-secrets (warn on write)               │
  │ PostToolUse  → audit-log (record every change)            │
  │ PostToolUse  → post-commit (detect git commits)           │
  │ PostToolUse  → detect-loop (warn on repeated failures)    │
  │ PreCompact   → pre-compact (inject state before compact)  │
  │ Stop         → check-tests-were-run (gate completion)     │
  │ Stop         → py-review (6-point checklist)              │
  └──────────────────────────────────────────────────────────┘
       │
       ▼
  ┌─── Layer 4: Enforcement (global hooks) ──────────────────┐
  │ PreToolUse  → enforce-spec (block writes without spec)    │
  │ Stop        → enforce-loop (check deliverables + debrief) │
  │ Events logged to .dev-wiki/enforcement.log (500-line cap) │
  └──────────────────────────────────────────────────────────┘
       │
       ▼
  ┌─── Layer 6: Pre-commit ───────────────┐
  │ ruff lint + format (catch what hooks   │
  │   missed or human edits introduced)    │
  │ mypy strict (type safety)              │
  │ gitleaks (secret scan)                 │
  │ sync-rules (AGENTS.md consistency)     │
  └────────────────────────────────────────┘
       │
       ▼
  ┌─── Layer 7: CI ──────────────────────────────┐
  │ 4 parallel jobs: lint, typecheck, test,       │
  │ security — final gate before merge to main    │
  │ 85% coverage floor enforced                   │
  └───────────────────────────────────────────────┘
</pre>

<!-- ============================================================ -->
<h2 id="hooks">3. Hook System Walkthrough</h2>

<p>Claude Code hooks are configured in <code>.claude/settings.json</code>. Each hook fires at a specific lifecycle event and receives tool input as JSON on stdin.</p>

<table>
<tr><th>Event</th><th>Matcher</th><th>Script</th><th>Behavior</th><th>Exit Codes</th></tr>
"""

    hook_details = [
        ("SessionStart", "—", "session-start.sh",
         "Loads context (dev-wiki state, gate check, session state), checks enforcement status, detects crash recovery, clears stale sidecars, emits <code>[nana:kit]</code> summary.",
         "0 = success (always)"),
        ("PreToolUse", "Bash", "block-dangerous-bash.sh",
         "Blocks: <code>rm -rf /|~|..</code>, <code>git push --force</code>, <code>--no-verify</code>, <code>git reset --hard</code>, <code>chmod 777</code>. Pattern-matched via jq + grep.",
         "0 = allow, 2 = block"),
        ("PreToolUse", "Write|Edit", "enforce-spec.sh",
         "Blocks implementation writes without approved spec. Checks provenance marker (<code>&lt;!-- nana:approved --&gt;</code>) or exit criteria. Path allowlist for meta/test/docs. Events logged.",
         "0 = allow, 2 = block (global hook)"),
        ("PostToolUse", "Write|Edit|MultiEdit", "auto-ruff-format.sh",
         "Auto-formats .py files with <code>ruff check --fix</code> + <code>ruff format</code>. Silent on non-Python files.",
         "0 = success (always)"),
        ("PostToolUse", "Write|Edit|MultiEdit", "scan-secrets.sh",
         "Scans written files via gitleaks (preferred) or fallback regex for API keys, tokens, passwords.",
         "0 = success (warning only)"),
        ("PostToolUse", "Write|Edit|MultiEdit", "audit-log.sh",
         "Appends JSONL record to <code>.nana/audit.jsonl</code>: timestamp, tool name, file path. Requires jq.",
         "0 = success (always)"),
        ("PostToolUse", "Bash", "post-commit.sh",
         "Detects <code>git commit</code> (not amend/fixup). Writes <code>.dev-wiki/.pending-commit</code> sidecar JSON. Emits <code>[dev-wiki:post-commit]</code>.",
         "0 = success (advisory)"),
        ("PostToolUse", "Bash", "detect-loop.sh",
         "Tracks consecutive identical failed commands. Warns after 3 repeats. Pure bash, no jq.",
         "0 = success (advisory)"),
        ("PreCompact", "—", "pre-compact.sh",
         "Reads dev-wiki state and active-phase.md. Outputs structured summary injected into compacted context.",
         "0 = success (always)"),
        ("Stop", "—", "check-tests-were-run.sh",
         "If Python files were modified, checks if <code>pytest</code> was run. Blocks stop if not.",
         "0 = allow, 2 = force continue"),
        ("Stop", "—", "enforce-loop.sh",
         "Checks file-existence exit criteria from spec. Advisories: open tasks, debrief status. Events logged.",
         "0 = allow, 2 = block (global hook)"),
        ("Stop", "—", "py-review-stop.sh",
         "Command hook: prompts a 6-point review only when Python changed; guards against the stop-loop.",
         "0 = allow, 2 = force continue"),
    ]

    for event, matcher, script, behavior, exits in hook_details:
        html += f"""<tr>
  <td><code>{event}</code></td>
  <td><code>{matcher}</code></td>
  <td><code>{script}</code></td>
  <td>{behavior}</td>
  <td><span style="font-size:0.82rem">{exits}</span></td>
</tr>
"""

    html += """</table>

<h3>Hook Data Flow</h3>
<pre>
  Claude Code invokes a tool (Write, Edit, Bash, etc.)
       │
       ├── PreToolUse hooks receive:  { "tool_name": "Bash", "input": { "command": "..." } }
       │     └── block-dangerous-bash.sh reads .input.command, pattern-matches
       │
       ├── Tool executes
       │
       └── PostToolUse hooks receive: { "tool_name": "Edit", "input": { "file_path": "..." } }
             ├── auto-ruff-format.sh reads .input.file_path, runs ruff if .py
             ├── scan-secrets.sh reads .input.file_path, scans content
             └── audit-log.sh reads .input.file_path + .tool_name, appends JSONL
</pre>

<!-- ============================================================ -->
<h2 id="templates">4. Template Inventory</h2>

<p>Templates scaffolded by <code>/py-init</code>. Placeholders (<code>{{PACKAGE_NAME}}</code>, <code>{{PROJECT_DESCRIPTION}}</code>, <code>{{PROJECT_NAME}}</code>) are substituted at scaffold time.</p>
"""

    for layer_name, files in tpl_by_layer.items():
        if not files:
            continue
        html += f"""<h3>{layer_name} <span class="badge badge-blue">{len(files)} files</span></h3>
<table>
<tr><th>File</th><th>Lines</th><th>Purpose</th></tr>
"""
        for f in files:
            lines = count_lines(ROOT / f)
            short = f.replace("templates/", "")
            purpose = _template_purpose(short)
            html += f"<tr><td><code>{short}</code></td><td>{lines}</td><td>{purpose}</td></tr>\n"
        html += "</table>\n"

    # Pre-commit hooks detail
    html += """<h3>Pre-commit Hooks (Layer 6 Detail)</h3>
<table>
<tr><th>Hook ID</th><th>Source</th><th>Purpose</th></tr>
"""
    precommit_purposes = {
        "sync-rules": "Sync AGENTS.md to 4 agent surfaces on commit",
        "ruff": "Lint Python code (auto-fix mode)",
        "ruff-format": "Format Python code",
        "mypy": "Strict type checking",
        "gitleaks": "Secret scanning",
        "nbstripout": "Strip notebook outputs before commit",
        "nbqa-ruff": "Lint notebook cells with ruff",
        "nbqa-mypy": "Type-check notebook cells",
        "validate-pyproject": "Validate pyproject.toml schema",
    }
    for hook_id, repo in precommit_hooks:
        purpose = precommit_purposes.get(hook_id, "")
        repo_short = repo.split("/")[-1] if "github.com" in repo else repo
        html += f"<tr><td><code>{hook_id}</code></td><td>{repo_short}</td><td>{purpose}</td></tr>\n"
    html += "</table>\n"

    # CI jobs detail
    html += """<h3>CI Pipeline (Layer 7 Detail)</h3>
<table>
<tr><th>Job</th><th>Steps</th></tr>
"""
    for job_name, steps in ci_jobs:
        steps_html = "<br>".join(f"<code>{s}</code>" for s in steps)
        html += f"<tr><td><strong>{job_name}</strong></td><td>{steps_html}</td></tr>\n"
    html += "</table>\n"

    # Quality signals
    html += """
<!-- ============================================================ -->
<h2 id="quality">5. Quality Signals</h2>

<div class="quality-grid">

<div class="quality-card">
<h4>Error Handling</h4>
<ul>
<li><strong>install.sh</strong>: upfront source validation (fail-fast before any copy), venv creation with graceful fallback (memory is optional), pip install failure warns but continues</li>
<li><strong>sync-rules.sh</strong>: validates AGENTS.md exists (exit non-zero with stderr), validates target directory is writable before any writes</li>
<li><strong>Hooks</strong>: all PostToolUse hooks exit 0 on error (non-blocking) — writes should never be blocked by hook failures. PreToolUse block-dangerous-bash uses exit 2 for intentional blocks only.</li>
<li><strong>MCP registration</strong>: idempotent JSON merge handles 3 cases (no file, partial, complete) without data loss</li>
</ul>
</div>

<div class="quality-card">
<h4>Idempotency</h4>
<ul>
<li><strong>install.sh</strong>: re-running produces identical results — file copies overwrite, venv reuses existing, JSON merge preserves other mcpServers entries</li>
<li><strong>sync-rules.sh</strong>: re-running overwrites outputs with same content (deterministic from AGENTS.md)</li>
<li><strong>MCP JSON merge</strong>: overwrites only the <code>memory</code> key — other MCP servers untouched</li>
<li><strong>Venv bootstrap</strong>: skips venv creation if <code>.venv/bin/python3</code> already exists, only runs pip install</li>
</ul>
</div>

<div class="quality-card">
<h4>Test Coverage</h4>
<table>
"""
    for suite_name, lines, assertions, comment in test_suites:
        html += f"<tr><td><code>{suite_name}</code></td><td>{assertions} assertions, {lines} lines</td></tr>\n"
    html += f"""</table>
<p style="margin-top:0.5rem;font-size:0.85rem">Total: <strong>{total_tests} assertions</strong> across {len(test_suites)} test scripts. Run with <code>make test</code>.</p>
<p style="font-size:0.85rem">Edge cases covered: missing source files, unwritable directories, MCP registration (no file / partial / complete), venv fallback, idempotency (diff between runs).</p>
</div>

<div class="quality-card">
<h4>Safety Boundaries</h4>
<ul>
<li><strong>PreToolUse gate</strong>: blocks rm -rf on /, ~, ..; blocks force-push; blocks --no-verify; blocks git reset --hard</li>
<li><strong>Secret scanning</strong>: dual-layer — gitleaks (preferred) + regex fallback on every file write</li>
<li><strong>Test gate</strong>: Stop hook blocks session completion if Python files modified but pytest not run</li>
<li><strong>Pre-commit gitleaks</strong>: scans all staged files at commit time</li>
<li><strong>CI secret scan</strong>: gitleaks-action as final barrier before merge</li>
</ul>
</div>

<div class="quality-card">
<h4>Graceful Degradation</h4>
<ul>
<li>Session-start hook: each context source independently optional — missing files silently skipped</li>
<li>auto-ruff-format: requires uv + ruff — silently no-ops if unavailable</li>
<li>scan-secrets: falls back from gitleaks to regex if gitleaks not installed</li>
<li>Venv bootstrap: warns and continues if python3 -m venv unavailable — memory is optional</li>
<li>Memory server fastembed: try/except guarded — embedding features degrade to text-only</li>
</ul>
</div>

<div class="quality-card">
<h4>Audit Trail</h4>
<ul>
<li>Every file write logged to <code>.nana/audit.jsonl</code> (timestamp, tool, path, model)</li>
<li>Dev-wiki journal captures session decisions and observations</li>
<li>Dev-wiki log tracks all planning and debrief events with timestamps</li>
<li>Git history preserves phase-attributed commits (one per phase)</li>
</ul>
</div>

</div>

<!-- ============================================================ -->
<h2 id="deps">6. Dependency &amp; Integration Map</h2>

<h3>Install-Time Dependencies</h3>
<pre>
  install.sh
       │
       ├── reads ─── templates/.claude/skills/py-init/SKILL.md
       ├── reads ─── templates/.claude/rules/nana-soul.md
       ├── reads ─── memory_server/*.py + requirements.txt
       │
       ├── writes ── ~/.claude/skills/py-init/SKILL.md
       ├── writes ── ~/.claude/rules/nana-soul.md
       ├── writes ── ~/.claude/.nana-dev-kit-path
       ├── writes ── ~/.claude/memory_server/  (12 .py files)
       ├── creates ─ ~/.claude/memory_server/.venv/  (isolated venv)
       └── merges ── ~/.claude/settings.json  (mcpServers.memory)
</pre>

<h3>Runtime Dependencies (Scaffolded Project)</h3>
<pre>
  Session start
       │
       ├── session-start.sh loads context + enforcement + crash recovery
       │
  Tool use
       │
       ├── Bash command ──→ block-dangerous-bash.sh (PreToolUse, jq)
       │               └──→ detect-loop.sh (PostToolUse, pure bash)
       │
       ├── File write ───→ enforce-spec.sh ──────→ requires: jq (global)
       │              ├──→ auto-ruff-format.sh ──→ requires: ruff
       │              ├──→ scan-secrets.sh ───────→ prefers: gitleaks
       │              └──→ audit-log.sh ──────────→ requires: jq

  git commit ──→ .pre-commit-config.yaml
       │
       ├── sync-rules ────→ requires: AGENTS.md, bash
       ├── ruff ───────────→ requires: uv (manages ruff)
       ├── mypy ───────────→ requires: uv (manages mypy)
       ├── gitleaks ───────→ requires: gitleaks binary
       └── nbstripout ────→ requires: uv (manages nbstripout)

  git push ──→ .github/workflows/ci.yml
       │
       ├── lint job ───────→ uv + ruff
       ├── typecheck job ──→ uv + mypy
       ├── test job ───────→ uv + pytest (85% coverage gate)
       └── security job ───→ uv pip audit + gitleaks-action
</pre>

<h3>Cross-Component Dependencies</h3>
<table>
<tr><th>Component</th><th>Depends On</th><th>Depended On By</th></tr>
<tr><td><code>install.sh</code></td><td>templates/, memory_server/</td><td>All scaffolded projects (one-time)</td></tr>
<tr><td><code>/py-init</code> (SKILL.md)</td><td><code>~/.claude/.nana-dev-kit-path</code>, templates/</td><td>Project scaffolding</td></tr>
<tr><td><code>sync-rules.sh</code></td><td>AGENTS.md</td><td>Pre-commit hook, <code>make sync-rules</code></td></tr>
<tr><td><code>settings.json</code></td><td>Hook scripts in .claude/hooks/</td><td>Claude Code runtime</td></tr>
<tr><td><code>memory_server/</code></td><td>pip deps (mcp, pydantic, pyyaml, nanoid, httpx)</td><td>MCP protocol, session-start.sh (reads .memory/)</td></tr>
<tr><td><code>.dev-wiki/</code></td><td>Dev-wiki skill suite (/dev-init, /dev-plan, etc.)</td><td>session-start.sh (reads _CURRENT_STATE.md)</td></tr>
</table>

<!-- ============================================================ -->
<h2 id="memory">7. Memory &amp; Dev-Wiki Integration</h2>

<h3>Memory MCP Server</h3>
<table>
<tr><th>Aspect</th><th>Detail</th></tr>
<tr><td>Transport</td><td>MCP stdio protocol — Claude Code spawns <code>~/.claude/memory_server/.venv/bin/python3 -m memory_server</code></td></tr>
<tr><td>Storage</td><td>SQLite + FTS5 full-text search per project (<code>.memory/memory.db</code>) and global (<code>~/.memory/global.db</code>)</td></tr>
<tr><td>Optional</td><td>fastembed for vector similarity search (try/except guarded, ~500MB download)</td></tr>
<tr><td>Tools exposed</td><td>store, search, verify, contradict, forget, tag, stats, export, prune, consolidate, import</td></tr>
<tr><td>Isolation</td><td>Deps in <code>~/.claude/memory_server/.venv/</code> — no system Python pollution</td></tr>
</table>

<h3>Context Flow Diagram</h3>
<pre>
  ┌─────────────────────────────────────────────────────────────────┐
  │                        Session Start                            │
  │                                                                 │
  │   .dev-wiki/_CURRENT_STATE.md ──┐                               │
  │   .claude/rules/active-phase.md ┤                               │
  │   py-session-state.md ──────────┼──→ session-start.sh ──→ stdout│
  │   crash recovery check ─────────┤    + [nana:kit] summary      │
  │   enforcement status ───────────┘                               │
  │                                                                 │
  │   Claude Code ingests stdout as session context                 │
  └─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │                      During Session                             │
  │                                                                 │
  │   Memory MCP server ◄──► Claude Code (store/search/verify)      │
  │         │                                                       │
  │         ▼                                                       │
  │   .memory/memory.db (project)                                   │
  │   ~/.memory/global.db (global)                                  │
  └─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │                     Session End (dev-debrief)                   │
  │                                                                 │
  │   Decisions ──→ .dev-wiki/articles/decisions/                   │
  │   Journal ────→ .dev-wiki/articles/journal/                     │
  │   Memory ─────→ memory_store (harvest corrections/preferences)  │
  │   State ──────→ .dev-wiki/_CURRENT_STATE.md                     │
  │   Tasks ──────→ .dev-wiki/tasks.md                              │
  └─────────────────────────────────────────────────────────────────┘
</pre>

<h3>Enforcement Layer</h3>
<pre>
  Implementation write attempt
       │
       ▼
  ┌─── enforce-spec.sh (PreToolUse) ─────────────────────────┐
  │ 1. Check .claude/enforce marker (opt-in per project)      │
  │ 2. Check path allowlist (meta/test/docs always allowed)   │
  │ 3. Check active-phase.md gate ([x] spec)                  │
  │ 4. Check specs/<slug>.md:                                 │
  │    ├── &lt;!-- nana:approved --&gt; marker → allow            │
  │    └── exit criteria present → allow (backward compat)    │
  │ 5. No valid spec → EXIT 2 (block)                         │
  │ All decisions logged to .dev-wiki/enforcement.log         │
  └──────────────────────────────────────────────────────────┘

  Session stop
       │
       ▼
  ┌─── enforce-loop.sh (Stop) ───────────────────────────────┐
  │ 1. Run file-existence exit criteria from spec             │
  │ 2. Count open tasks (advisory)                            │
  │ 3. Check debrief status (advisory)                        │
  │ Missing deliverable → EXIT 2 (block)                      │
  └──────────────────────────────────────────────────────────┘
</pre>

<h3>Memory Bridge Flow</h3>
<pre>
  /dev-plan (planning)
       │
       ├── memory_store ──→ bridge-decision entries
       │                    (category: custom, tags: [bridge-decision])
       │
  /wiki-query (retrieval)
       │
       ├── memory_search ──→ includes memory results in analysis
       │                     alongside wiki articles
       │
  /dev-debrief (capture)
       │
       ├── memory_store ──→ harvest corrections, preferences, lessons
       │                    (auto-supersession of conflicting entries)
       │
  /memory-consolidate (maintenance)
       │
       └── memory_search + memory_store + memory_forget
           ──→ Claude-powered cluster identification and merge
               (10-merge cap, dry-run mode, no Qwen sidecar needed)
</pre>

<footer>
  Nana Dev Kit v{version} &mdash; Workflow Breakdown &mdash; Generated {now}<br>
  <code>scripts/generate-workflow.py</code> &mdash; run <code>make workflow</code> to regenerate
</footer>

</body>
</html>
"""
    return html


def _template_purpose(path):
    purposes = {
        "AGENTS.md": "Single source of truth for agent instructions",
        ".github/instructions/nana.instructions.md": "Nana identity for GitHub Copilot",
        ".github/instructions/workflow.instructions.md": "Workflow instructions for Copilot",
        ".claude/rules/nana-soul.md": "Development personality and technical posture",
        ".claude/rules/nana-personal.md": "User profile template (preserved on re-install)",
        ".claude/rules/file-lifecycle.md": "File ownership routing table (user/agent/skill/hook)",
        ".claude/rules/py-session-state.md": "Compaction-safe session state template",
        ".claude/hooks/session-start.sh": "SessionStart: loads context, crash recovery, enforcement, [nana:kit]",
        ".claude/hooks/block-dangerous-bash.sh": "PreToolUse: blocks rm -rf, force-push, --no-verify",
        ".claude/hooks/enforce-spec.sh": "PreToolUse: blocks writes without approved spec (global)",
        ".claude/hooks/auto-ruff-format.sh": "PostToolUse: auto-formats Python with ruff",
        ".claude/hooks/scan-secrets.sh": "PostToolUse: scans for hardcoded secrets",
        ".claude/hooks/audit-log.sh": "PostToolUse: JSONL audit trail of all writes",
        ".claude/hooks/post-commit.sh": "PostToolUse: detects git commits, writes .pending-commit",
        ".claude/hooks/detect-loop.sh": "PostToolUse: warns on 3+ identical failed commands",
        ".claude/hooks/pre-compact.sh": "PreCompact: injects dev-wiki state before context compaction",
        ".claude/hooks/check-tests-were-run.sh": "Stop: gates completion on pytest execution",
        ".claude/hooks/enforce-loop.sh": "Stop: checks deliverables + debrief status (global)",
        ".claude/hooks/py-review-stop.sh": "Stop: 6-point review prompt, gated on Python changes (loop-safe)",
        ".claude/settings.json": "Hook wiring: maps lifecycle events to scripts",
        ".pre-commit-config.yaml": "9 pre-commit hooks: ruff, mypy, gitleaks, sync-rules, notebooks",
        ".github/workflows/ci.yml": "4-job CI: lint, typecheck, test (85% gate), security",
        ".github/PULL_REQUEST_TEMPLATE.md": "PR template with checklist",
        ".github/CODEOWNERS": "Code ownership for review assignment",
        "pyproject.toml": "Python project config with ruff + mypy settings",
    }
    if path in purposes:
        return purposes[path]
    manifest_descs = get_manifest_descriptions()
    for skill_dir, desc in manifest_descs.items():
        if skill_dir in path:
            return desc
    return ""


def get_manifest_descriptions():
    import re
    manifest = ROOT / "templates" / ".claude" / "skills" / "MANIFEST"
    descs = {}
    if manifest.is_file():
        for line in manifest.read_text().splitlines():
            m = re.match(r'^# (\S+): (.+)$', line)
            if m:
                descs[m.group(1)] = m.group(2)
    return descs


if __name__ == "__main__":
    output = ROOT / "docs" / "workflow.html"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(generate_html())
    print(f"Workflow breakdown generated: {output}")
