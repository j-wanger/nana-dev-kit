# nana-init

Bootstrap the full Nana experience for a project: language scaffold, dev-wiki lifecycle tracking, and optional knowledge wiki. Each step detects existing state and skips if already initialized.

**Triggers:** `/nana-init`

---

## Step 1: Detect Component State

Check all three subsystems before taking any action:

```
# Language markers
PYTHON_MARKERS=$(ls pyproject.toml setup.py setup.cfg requirements.txt 2>/dev/null | wc -l | tr -d ' ')
TS_MARKERS=$(ls package.json tsconfig.json 2>/dev/null | wc -l | tr -d ' ')

# Lifecycle
HAS_DEVWIKI=$(test -d .dev-wiki && echo "yes" || echo "no")

# Knowledge wiki
HAS_WIKI=$(test -d wiki && echo "yes" || echo "no")
```

Report what will happen: "Detected: [language markers / no markers], [dev-wiki present / absent], [knowledge wiki present / absent]. Here's what I'll set up:"

---

## Step 2: Language Scaffold

| State | Action |
|-------|--------|
| Python markers only | Invoke `Skill(skill="py-init")` |
| TypeScript markers only | Invoke `Skill(skill="ts-init")` |
| Both detected (polyglot) | Ask user which language to scaffold, or skip |
| Neither detected | Ask: "Which language? Python (`/py-init`), TypeScript (`/ts-init`), or skip?" |

Pass through any user-provided arguments to the target skill. **Skipping is valid** — the user may only want lifecycle tracking.

---

## Step 3: Dev-Wiki Lifecycle

| State | Action |
|-------|--------|
| `.dev-wiki/` absent | Invoke `Skill(skill="dev-init")` |
| `.dev-wiki/` present | Skip: "Dev-wiki already initialized." |

Dev-wiki enables: phase tracking, task management, crash recovery, session continuity, enforcement context. **Recommended for all projects.**

---

## Step 4: Knowledge Wiki (Optional)

| State | Action |
|-------|--------|
| `wiki/` absent | Ask: "Set up a knowledge wiki? Recommended for domain-heavy work. (y/n)" |
| `wiki/` present | Skip: "Knowledge wiki already initialized." |

If user accepts: invoke `Skill(skill="wiki-init")`.
If user declines: skip. They can run `/wiki-init` later.

---

## Step 5: Summary

Report what was set up:

```
Nana initialized:
  Language scaffold: [Python / TypeScript / skipped]
  Dev-wiki lifecycle: [created / already present]
  Knowledge wiki: [created / skipped / already present]

Your next session will get full context: phase tracking, task state,
crash recovery, and memory search guidance.
```

---

## Supported Languages

- Python via `/py-init` — uv, ruff, mypy, pytest, pyproject.toml
- TypeScript via `/ts-init` — pnpm, biome, tsc, vitest, tsconfig.json

Additional languages: create a scaffold skill and add markers to the Detection table in Step 1.
