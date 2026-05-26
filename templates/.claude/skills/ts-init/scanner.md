---
parent: ts-init
referenced_at: "referenced (step unknown)"
---

# Feasibility Scanner — 10 Dimensions (TypeScript)

Run all checks. Record each as: **compatible**, **upgradeable**, or **blocking**.

## 0. Monorepo Detection (Pre-check)
```bash
test -f turbo.json || test -f nx.json || test -f lerna.json || test -f pnpm-workspace.yaml
```
- Any monorepo tool detected → **blocking**: "Monorepo detected (turbo/nx/lerna/pnpm workspaces). ts-init scaffolds single-package projects. Run ts-init inside a package directory instead."
- None → proceed to dimension checks

## 1. Build System
```bash
test -f package.json && test -f tsconfig.json
```
- Both present → compatible
- package.json only (no tsconfig) → upgradeable (generate tsconfig)
- Neither → new project mode (exit scanner)
- tsconfig.json only (no package.json) → **blocking** (invalid state)

## 2. Source Layout
```bash
find . -maxdepth 3 -name "*.ts" -not -path "./node_modules/*" -not -path "./.git/*" -not -path "./dist/*" 2>/dev/null
```
- `src/index.ts` or `src/**/*.ts` → compatible (source_dir=`src`)
- Root-level `.ts` files only → upgradeable (suggest src/ migration)
- Both src/ and root → compatible (use src/ as source_dir)
- No `.ts` files → upgradeable (scaffold src/index.ts)

## 3. Linter / Formatter
```bash
test -f biome.json || test -f biome.jsonc
test -f .eslintrc.js || test -f .eslintrc.json || test -f .eslintrc.yml || test -f eslint.config.js || test -f eslint.config.mjs
test -f .prettierrc || test -f .prettierrc.json || test -f prettier.config.js
```
- biome.json present → compatible
- ESLint + Prettier → upgradeable
- ESLint only → upgradeable (add formatting)
- None → upgradeable

**React/Next.js warning:** If `react` or `next` is in package.json dependencies:
```bash
node -e "const p=require('./package.json'); const d={...p.dependencies,...p.devDependencies}; if(d.react||d.next) console.log('REACT_PROJECT')"
```
If detected, warn: "React/Next.js project detected. Biome has thinner JSX rule coverage than ESLint. Consider keeping ESLint for React-specific rules alongside Biome for formatting."

## 4. Type Checker
tsc IS the TypeScript compiler — check strictness:
```bash
node -e "const c=JSON.parse(require('fs').readFileSync('tsconfig.json','utf8').replace(/\/\/.*/g,'')); console.log(c.compilerOptions?.strict ? 'strict' : 'not-strict')"
```
- `strict: true` → compatible
- `strict: false` or missing → upgradeable (enable strict mode)

## 5. Test Framework
```bash
node -e "const p=require('./package.json'); const d={...p.dependencies,...p.devDependencies}; ['vitest','jest','mocha','jasmine'].forEach(t => d[t] && console.log(t))"
```
- vitest → compatible
- jest → compatible (can coexist)
- mocha/jasmine → upgradeable
- None → upgradeable

## 6. Pre-commit Hooks
```bash
test -d .husky || test -f .lintstagedrc || test -f .lintstagedrc.json
node -e "const p=require('./package.json'); if(p['lint-staged']) console.log('lint-staged:package.json')" 2>/dev/null
test -f .pre-commit-config.yaml && echo "python-precommit"
```
- husky + lint-staged → compatible
- Python pre-commit framework → upgradeable (migrate to husky)
- None → upgradeable

## 7. Dependency Manager
```bash
test -f pnpm-lock.yaml && echo "pnpm"
test -f yarn.lock && echo "yarn"
test -f package-lock.json && echo "npm"
test -f bun.lockb && echo "bun"
```
- pnpm → compatible
- npm → compatible
- bun → compatible
- yarn v1 (yarn.lock present, no .yarnrc.yml) → **blocking** (legacy)
- Multiple lockfiles → **blocking** (ambiguous)

## 8. Agent Config
```bash
test -d .claude && echo "has:.claude"; test -f .claude/settings.json && echo "has:settings.json"
test -f CLAUDE.md && echo "has:CLAUDE.md"; test -d .claude/rules && echo "has:rules"
```
- No .claude/ or CLAUDE.md → upgradeable
- settings.json/CLAUDE.md exists → upgradeable (merge)

## 9. CI Workflows
```bash
test -d .github/workflows && ls .github/workflows/ 2>/dev/null
test -f .gitlab-ci.yml && echo "gitlab-ci"; test -f Jenkinsfile && echo "jenkins"
```
- No CI → upgradeable
- GitHub Actions present → compatible
- Non-GitHub CI → compatible (skip CI layer)

## 10. Git Secrets Scanning
```bash
test -f .husky/pre-commit && grep -q 'gitleaks' .husky/pre-commit 2>/dev/null && echo "has-gitleaks"
test -f .pre-commit-config.yaml && grep -qE '(gitleaks|detect-secrets|trufflehog)' .pre-commit-config.yaml 2>/dev/null && echo "has-scanner-precommit"
```
- Scanner present → compatible
- No scanner → upgradeable
