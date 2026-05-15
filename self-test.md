# Nana Dev Kit — Self-Test

Manual smoke test proving all 5 layers compose correctly.

## Setup

```bash
# 1. Install the kit
~/nana-dev-kit/install.sh

# 2. Create a toy project
mkdir /tmp/nana-test-project && cd /tmp/nana-test-project

# 3. Run /py-init in Claude Code
claude   # then type: /py-init
```

## Test 1: Layer 1 — Instruction files load

**In Claude Code:** Ask "What toolchain does this project use?"
- **Expected:** Claude references uv, ruff, mypy, pytest from AGENTS.md
- **Pass if:** Response mentions uv (not pip), ruff (not black/flake8)

**In VS Code with Copilot:** Open a .py file, ask the same question
- **Expected:** Copilot references the same tools from copilot-instructions.md
- **Pass if:** Same tools mentioned

## Test 2: Layer 2 — Identity persists

**In Claude Code:** Ask "Should I add comprehensive error handling with try/except around every function?"
- **Expected:** Nana pushes back — SOUL says "let errors propagate with useful context"
- **Pass if:** Response challenges the premise, suggests letting exceptions propagate

**In Claude Code:** Ask "I'm thinking of building an abstraction layer over the database, a generic query builder that handles all our models"
- **Expected:** Subtraction test — "does this earn its complexity?"
- **Pass if:** Response questions the complexity, asks what problem it solves

## Test 3: Layer 3 — Stop hook blocks without tests

**In Claude Code:** Ask "Create a hello world function in src/hello.py"
- Wait for Claude to write the file and attempt to stop
- **Expected:** Stop hook fires with "You haven't run the test suite yet"
- **Pass if:** Claude is forced to run pytest before declaring done

## Test 4: Layer 3 — PreToolUse blocks dangerous commands

**In Claude Code:** Ask "Run rm -rf ~/ to clean up"
- **Expected:** PreToolUse hook blocks with "Blocked: recursive force-delete"
- **Pass if:** Command is blocked, Claude sees the error message

## Test 5: Layer 4 — Pre-commit catches issues

```bash
# Write a file with a ruff violation
echo "import os\nimport sys\nx=1" > src/bad.py
git add src/bad.py
git commit -m "test"
```

- **Expected:** ruff hook auto-fixes unused imports, reformats
- **Pass if:** Commit proceeds with the fixed file (auto-fix mode)

## Test 6: Layer 5 — CI workflow valid

```bash
# Verify the workflow parses
python3 -c "
import json
# Basic YAML key check (no pyyaml dependency)
with open('.github/workflows/ci.yml') as f:
    content = f.read()
    assert 'pytest' in content
    assert 'pip audit' in content or 'uv pip audit' in content
    assert 'ruff' in content
    assert 'mypy' in content
    print('CI workflow contains all required steps')
"
```

## Test 7: Mode detection routes to scan

```bash
# Create a project with existing config
mkdir /tmp/nana-existing-test && cd /tmp/nana-existing-test
echo "# Existing" > CLAUDE.md
```

**In Claude Code:** Run `/py-init`
- **Expected:** Skill detects existing project, runs 10-dimension feasibility scan, presents report table
- **Pass if:** Shows feasibility scan results table with classifications (compatible/upgradeable/blocking). Does NOT immediately modify files — waits for approval.

## Test 8: SessionStart hook loads state

```bash
cd /tmp/nana-test-project
echo "## Current Focus\nBuilding the auth module.\n## Key Decisions\nUsing JWT tokens.\n## Last Updated\n2026-05-14" > PROJECT_STATE.md
```

**Start a new Claude Code session in that directory.**
- **Expected:** SessionStart hook outputs the PROJECT_STATE.md content
- **Pass if:** Claude acknowledges the project state at session start

## Test 9: Audit log writes

**In Claude Code:** Create or edit any .py file
- Then check: `cat .nana/audit.jsonl`
- **Expected:** JSONL entry with timestamp, tool name, file path
- **Pass if:** At least one valid JSON line exists in the audit log

## Retrofit Mock Fixture

Create a mock existing project for retrofit testing:

```bash
mkdir -p /tmp/nana-retrofit-test/mypackage
cd /tmp/nana-retrofit-test
git init

# Flat layout with package at root
cat > mypackage/__init__.py << 'PYEOF'
"""Mock package."""
PYEOF

# pyproject.toml with setuptools + partial ruff config (no mypy, no pytest, no coverage)
cat > pyproject.toml << 'PYEOF'
[project]
name = "mypackage"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

[build-system]
requires = ["setuptools>=68.0"]
build-backend = "setuptools.backends._legacy:_Backend"

[tool.ruff]
line-length = 88
select = ["E", "F"]
PYEOF

# .pre-commit-config.yaml with black + isort (no ruff, no gitleaks)
cat > .pre-commit-config.yaml << 'PYEOF'
repos:
  - repo: https://github.com/psf/black
    rev: 24.4.2
    hooks:
      - id: black
  - repo: https://github.com/pycqa/isort
    rev: 5.13.2
    hooks:
      - id: isort
PYEOF

# No .claude/, no CLAUDE.md, no tests, no CI, no uv.lock
```

## Test 10: Retrofit scan classifies correctly

**In Claude Code (in /tmp/nana-retrofit-test):** Run `/py-init`

- **Expected:** Mode detection identifies existing project, runs feasibility scan. Classifications:

| Dimension | Expected | Reason |
|-----------|----------|--------|
| Build system | compatible | setuptools is supported |
| Source layout | compatible | flat layout detected (source_dir=`.`, package=`mypackage`) |
| Linter/formatter | upgradeable | has black (no ruff) — will replace with ruff |
| Type checker | upgradeable | no mypy config — will add |
| Test framework | upgradeable | no pytest config — will add |
| Pre-commit | upgradeable | has black/isort repos — will replace with ruff |
| Dependency manager | upgradeable | no uv.lock — will init with uv |
| Agent config | upgradeable | no .claude/ — will create |
| CI workflows | upgradeable | no CI — will add GitHub Actions |
| Git secrets | upgradeable | no gitleaks in pre-commit — will add |

- **Pass if:** All 10 dimensions classified. No blocking items. Report shows flat layout with `source_dir: .` and `package_name: mypackage`. Approval prompt appears.

## Test 11: Retrofit transform upgrades correctly

**Continue from Test 10 — approve the transform.**

- **Expected after transform:**
  - pyproject.toml: `[tool.ruff]` has expanded `select` list (added I, N, UP, B, S, etc.), `src = ["."]`, `[tool.mypy]` added with `strict = true`, `[tool.pytest.ini_options]` added with `--cov=.`, `[tool.coverage.run]` added with `source = ["."]`
  - .pre-commit-config.yaml: black and isort repos replaced with ruff-pre-commit, gitleaks repo added, sync-rules local hook added
  - .claude/settings.json created with all 4 lifecycle hooks
  - AGENTS.md created from template (no prior CLAUDE.md)
  - .claude/skills/, .claude/hooks/, .claude/rules/ populated
  - scripts/sync-rules.sh copied

- **Pass if:** All files exist. `grep -q 'src = ["."]' pyproject.toml` succeeds. `grep -q ruff .pre-commit-config.yaml` succeeds. No black or isort repos remain in .pre-commit-config.yaml.

## Test 12: Retrofit validation runs post-transform

**Continue from Test 11 — check validation output.**

- **Expected:** Post-transform validation runs ruff, mypy, pytest, pre-commit. Some failures are expected (mypy strict on untyped code). Validation summary table presented.
- **Pass if:** Validation table shown. Ruff passes (auto-fixed). Failures are reported as informational, not as blockers.

## Test 13: Blocking scan stops transform

```bash
mkdir -p /tmp/nana-blocking-test
cd /tmp/nana-blocking-test
git init

# Poetry project — should be classified as blocking
cat > pyproject.toml << 'PYEOF'
[tool.poetry]
name = "blocked-pkg"
version = "0.1.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
PYEOF

touch poetry.lock
```

**In Claude Code (in /tmp/nana-blocking-test):** Run `/py-init`
- **Expected:** Feasibility scan classifies build system as blocking (poetry-core) and dependency manager as blocking (poetry.lock). Transform does NOT proceed.
- **Pass if:** "Feasibility scan found blocking issues" message. No files modified. User told to fix manually.

## Known Limitations

- **Blocking build systems halt the retrofit.** Poetry (`poetry-core`), PDM (`pdm-backend`), pipenv (`Pipfile.lock`), and conda projects cannot be retrofitted — their dependency models are incompatible with uv. The scanner fails closed: no files are modified, and the user is told which dimensions are blocking.
- **Ambiguous source layouts are blocking.** If both `src/<pkg>/__init__.py` and `./<pkg>/__init__.py` exist (dual layout), the scanner cannot determine the canonical source directory and halts.
- **Existing CLAUDE.md is not auto-merged.** If CLAUDE.md exists but AGENTS.md does not, the transform skips instruction file creation and tells the user to merge manually. This avoids overwriting user-authored agent instructions.
- **Copilot does not support hooks.** Layers 3 (PreToolUse, PostToolUse, Stop) only work in Claude Code. Copilot relies on pre-commit (Layer 4) and CI (Layer 5) to catch the same issues.
- **Memory MCP not yet portable.** Cross-session memory requires the memory MCP server, which may not be installable on enterprise hardware.

## Cleanup

```bash
rm -rf /tmp/nana-test-project /tmp/nana-existing-test /tmp/nana-retrofit-test /tmp/nana-blocking-test
```

## Results

| Test | Layer | Status |
|------|-------|--------|
| 1. Instructions load | L1 | |
| 2. Identity persists | L1+L2 | |
| 3. Stop hook blocks | L3 | |
| 4. PreToolUse blocks | L3 | |
| 5. Pre-commit catches | L4 | |
| 6. CI valid | L5 | |
| 7. Mode detection routes to scan | L2 | |
| 8. SessionStart hook | L3 | |
| 9. Audit log | L3 | |
| 10. Retrofit scan classifies | L2 | |
| 11. Retrofit transform upgrades | L2+L3+L4 | |
| 12. Retrofit validation runs | L2 | |
| 13. Blocking scan stops transform | L2 | |
