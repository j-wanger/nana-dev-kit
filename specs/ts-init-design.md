# Design Spec: ts-init — TypeScript Project Scaffolding Skill

## Overview

A `ts-init` skill that scaffolds or retrofits the Nana Dev Kit harness into TypeScript projects, following the same two-mode pattern as `py-init` (new project vs existing project). This document maps every py-init assumption to its TypeScript equivalent and defines the architectural decisions needed before implementation.

## py-init Assumptions → TypeScript Mapping

| # | Dimension | py-init (Python) | ts-init (TypeScript) | Notes |
|---|-----------|-----------------|---------------------|-------|
| 1 | Build system | pyproject.toml (PEP 621) | package.json + tsconfig.json | TS requires two config files vs one |
| 2 | Package manager | uv (uv.lock) | pnpm (pnpm-lock.yaml) | See [Package Manager Decision](#package-manager) |
| 3 | Source layout | src/pkg/__init__.py or flat | src/index.ts | No __init__.py equivalent; barrel exports optional |
| 4 | Linter/formatter | ruff (replaces black+isort+flake8) | Biome (replaces ESLint+Prettier) | See [Linter Decision](#linter-formatter) |
| 5 | Type checker | mypy (separate tool) | tsc (the compiler IS the type checker) | No separate install — `tsc --noEmit` |
| 6 | Test framework | pytest | Vitest | See [Test Framework Decision](#test-framework) |
| 7 | Pre-commit | pre-commit framework (Python-based) | lint-staged + husky | See [Pre-commit Decision](#pre-commit-hooks) |
| 8 | Dep manager | uv sync / uv add | pnpm install / pnpm add | Same role, different tool |
| 9 | CI | GitHub Actions: lint, typecheck, test | GitHub Actions: lint, typecheck, test | Same structure, different commands |
| 10 | Agent config | AGENTS.md with Python toolchain | AGENTS.md with TypeScript toolchain | See [AGENTS.md Strategy](#agentsmd-template-strategy) |
| 11 | Git secrets | gitleaks | gitleaks | Language-agnostic — no change |

## Key Decisions

### Package Manager

**Recommendation: pnpm**

| Option | Pros | Cons |
|--------|------|------|
| npm | Universal, zero-install | Slow, flat node_modules, no strict mode |
| pnpm | Fast, strict deps, disk-efficient | Extra install step, some edge cases with native modules |
| bun | Fastest, built-in test runner | Less mature, compatibility gaps with some packages |

pnpm is the best match for the kit's philosophy (strict by default, measurably faster). npm is the fallback for compatibility. bun is too young for a default recommendation.

**Scanner mapping:** `poetry-core → blocking` maps to `yarn v1 → blocking` (legacy). pnpm, npm, bun → compatible. No lockfile → upgradeable.

### Linter/Formatter

**Recommendation: Biome**

Biome is the TypeScript equivalent of ruff — a single Rust-based tool that replaces ESLint + Prettier. It's 10-100x faster, has a single config file (`biome.json`), and covers linting + formatting.

**Scanner mapping:** `ruff → compatible` maps to `biome → compatible`. ESLint+Prettier → upgradeable. None → upgradeable. ESLint-only (no Prettier) → upgradeable.

**Caveat:** Biome doesn't cover all ESLint rules (especially React-specific ones). For React/Next.js projects, ESLint may need to stay. Scanner should detect `next.config.*` or `react` in deps and flag as "Biome may not cover all React linting rules."

### Test Framework

**Recommendation: Vitest**

Vitest is the modern standard for TypeScript testing — built on Vite, native ESM, TypeScript support without config, compatible with Jest API. Jest still works but requires more config for TypeScript.

**Scanner mapping:** `pytest → compatible` maps to `vitest → compatible`. Jest → compatible (can coexist). Mocha/Jasmine → upgradeable. None → upgradeable.

### Pre-commit Hooks

**Recommendation: lint-staged + husky**

The Python pre-commit framework works for any language, but TS projects conventionally use husky (git hooks) + lint-staged (run linters on staged files). This feels more native to TS developers.

**Alternative:** Keep the Python pre-commit framework — it already works with any language. But this adds a Python dependency to a TypeScript project.

**Decision:** Use lint-staged + husky. The Python pre-commit framework should NOT be a dependency for TS-only projects.

### AGENTS.md Template Strategy

**Recommendation: Separate template**

Create `templates/AGENTS-ts.md` with TypeScript-specific toolchain sections. The shared sections (general conventions, PR process, security) stay identical.

**Sections that change:**

| Section | Python | TypeScript |
|---------|--------|-----------|
| Toolchain | uv, ruff, mypy, pytest | pnpm, biome, tsc, vitest |
| Pre-commit sequence | uv run ruff check, uv run mypy | pnpm biome check, pnpm tsc --noEmit |
| Test commands | uv run pytest | pnpm vitest |
| Package management | uv add/sync | pnpm add/install |
| Build | N/A (interpreted) | pnpm build (tsc/tsup/esbuild) |

**Rejected alternative:** Parameterized template with `{{LINTER}}` etc. — adds complexity for only 2 languages. Separate files are simpler and each can evolve independently.

### install.sh Module Group

**Recommendation: Add `typescript` module group**

```
Modules: core (rules + memory), python (py-init + spec), 
         typescript (ts-init), dev-wiki (6 dirs), knowledge-wiki (11 dirs)
```

Add `--no-typescript` flag. Default `--all` installs both language modules. Users pick their language with flags: `--no-python` for TS-only, `--no-typescript` for Python-only.

**Impact on existing code:**
- install.sh: ~15-20 new lines for the typescript module group
- Flag parsing: add `--no-typescript` alongside existing `--no-python`
- Getting Started output: add ts-init mention

## Feasibility Scanner — TypeScript Dimensions

Adapted from py-init's scanner.md (10 dimensions):

### 1. Build System
```bash
test -f package.json && test -f tsconfig.json
```
- Both present → compatible
- package.json only (no tsconfig) → upgradeable (generate tsconfig)
- Neither → new project mode
- tsconfig.json only (no package.json) → blocking (invalid state)

### 2. Source Layout
```bash
find . -maxdepth 3 -name "*.ts" -not -path "./node_modules/*" -not -path "./.git/*" -not -path "./dist/*" 2>/dev/null
```
- `src/index.ts` or `src/**/*.ts` → compatible
- Root-level `.ts` files only → upgradeable (suggest src/ migration)
- Both src/ and root → compatible (use src/ as source_dir)
- No `.ts` files → upgradeable (scaffold src/index.ts)

### 3. Linter/Formatter
```bash
test -f biome.json || test -f .eslintrc* || test -f eslint.config.*
```
- biome.json → compatible
- ESLint + Prettier → upgradeable
- ESLint only → upgradeable (add formatting)
- None → upgradeable

### 4. Type Checker
tsc IS the compiler — this dimension collapses. Check for strictness:
```bash
node -e "const c=require('./tsconfig.json'); console.log(c.compilerOptions?.strict)"
```
- `strict: true` → compatible
- `strict: false` or missing → upgradeable (enable strict mode)

### 5. Test Framework
```bash
node -e "const p=require('./package.json'); const d={...p.dependencies,...p.devDependencies}; 
  ['vitest','jest','mocha','jasmine'].forEach(t => d[t] && console.log(t))"
```
- vitest → compatible
- jest → compatible (keep, add vitest config if desired)
- mocha/jasmine → upgradeable
- None → upgradeable

### 6. Pre-commit
```bash
test -f .husky/pre-commit || test -f .lintstagedrc* || grep -q "lint-staged" package.json 2>/dev/null
```
- husky + lint-staged → compatible
- pre-commit framework (Python) → upgradeable
- None → upgradeable

### 7. Dependency Manager
```bash
test -f pnpm-lock.yaml && echo pnpm; test -f yarn.lock && echo yarn; 
test -f package-lock.json && echo npm; test -f bun.lockb && echo bun
```
- pnpm → compatible
- npm → compatible
- bun → compatible
- yarn v1 (yarn.lock, no .yarnrc.yml) → blocking (legacy)
- Multiple lockfiles → blocking (ambiguous)

### 8-11. Agent config, CI, Git secrets
Same as py-init — language-agnostic. Check for existing AGENTS.md, CI workflows, gitleaks config.

## New Project Scaffold (ts-init)

```bash
KIT=$(cat ~/.claude/.nana-dev-kit-path)

# Initialize
git init
pnpm init

# TypeScript setup
pnpm add -D typescript @types/node
npx tsc --init --strict --target es2022 --module nodenext --outDir dist --rootDir src

# Project structure
mkdir -p src tests
echo 'export {}' > src/index.ts

# Linter + formatter
pnpm add -D @biomejs/biome
npx biome init

# Test framework
pnpm add -D vitest
# Add "test": "vitest" to package.json scripts

# Pre-commit
pnpm add -D husky lint-staged
npx husky init
echo 'pnpm lint-staged' > .husky/pre-commit

# Kit harness (layers 1-5, same as py-init but with AGENTS-ts.md)
cp "$KIT/templates/AGENTS-ts.md" ./AGENTS.md
# ... (rest identical to py-init steps 4-8, with AGENTS-ts.md)

# Build config
# Add to package.json: "build": "tsc", "lint": "biome check .", "format": "biome format --write ."
```

## Monorepo Edge Cases

**Detection:**
```bash
test -f turbo.json || test -f nx.json || test -f lerna.json || test -f pnpm-workspace.yaml
```

**Behavior:** If a monorepo tool is detected, scanner reports as **blocking** with message: "Monorepo detected (turbo/nx/lerna/pnpm workspaces). ts-init scaffolds single-package projects. Run ts-init inside a package directory instead."

This matches py-init's handling of `poetry-core` — we don't try to support every project shape.

## CI Template Differences

`templates/.github/workflows/ci-ts.yml`:

```yaml
# Key differences from ci.yml (Python):
- uses: pnpm/action-setup@v4     # vs: uv, pip
- run: pnpm install               # vs: uv sync
- run: pnpm biome check .         # vs: ruff check
- run: pnpm tsc --noEmit          # vs: mypy
- run: pnpm vitest --run          # vs: pytest
```

## Implementation Estimate

| Task | Size | Notes |
|------|------|-------|
| AGENTS-ts.md template | S | Adapt from AGENTS.md, swap toolchain sections |
| ts-init/SKILL.md | M | Adapt from py-init/SKILL.md, same 2-mode structure |
| ts-init/scanner.md | M | 10 dimensions, adapted checks |
| ts-init/transform.md | M | Existing project retrofit logic |
| ci-ts.yml template | S | Adapt from ci.yml |
| install.sh module | S | Add typescript group + flag |
| Tests | M | test_install.sh + test_templates.sh assertions |
| **Total** | ~1 phase (5-7 tasks) | Estimated Phase 35 |

## Open Questions for Implementation

1. **Biome vs ESLint+Prettier default:** Biome is faster and simpler but has lower ESLint rule coverage. Should the scanner offer both paths, or default to Biome with ESLint as a "compatible" alternative?
2. **Build tool:** tsc for pure TypeScript, but projects often use tsup, esbuild, or Vite for bundling. Should ts-init scaffold a build tool beyond tsc?
3. **Node.js version:** Should tsconfig target ES2022 (Node 18+) or ES2023 (Node 20+)? Recommend ES2022 for broader compat.
4. **ESM vs CJS:** Modern TS projects should use ESM (`"type": "module"` in package.json). Should this be the default, or should the scanner detect and adapt?
