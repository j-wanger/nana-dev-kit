# init

Detect the project language and route to the appropriate scaffolding skill.

**Triggers:** `/init`, "set up a project", "scaffold this project"

## Detection

Check the current directory for language markers:

| Marker | Language |
|--------|----------|
| `pyproject.toml`, `setup.py`, `setup.cfg`, `requirements.txt` | Python |
| `package.json`, `tsconfig.json` | TypeScript |

Run detection:
```
PYTHON_MARKERS=$(ls pyproject.toml setup.py setup.cfg requirements.txt 2>/dev/null | wc -l | tr -d ' ')
TS_MARKERS=$(ls package.json tsconfig.json 2>/dev/null | wc -l | tr -d ' ')
```

## Routing

**Single language detected:**
- Python markers only → invoke `Skill(skill="py-init")`
- TypeScript markers only → invoke `Skill(skill="ts-init")`

**Both detected (polyglot):**
Ask the user which language to scaffold. Do NOT auto-invoke — polyglot repos need explicit choice.

**Neither detected (empty/ambiguous):**
Ask the user: "No language markers found. Which scaffold do you want?"
Present options: Python (`/py-init`) or TypeScript (`/ts-init`).

## After Routing

Pass through any user-provided arguments (e.g., project name, flags) to the target skill. The target skill handles all scaffolding — this skill only detects and dispatches.

## Supported Languages

- Python via `/py-init` — uv, ruff, mypy, pytest, pyproject.toml
- TypeScript via `/ts-init` — pnpm, biome, tsc, vitest, tsconfig.json

Additional languages can be added by creating a new scaffold skill and adding markers to the Detection table.
