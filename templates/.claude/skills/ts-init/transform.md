# Existing Project Transform (TypeScript)

Apply changes based on scanner results. Follow this order — later steps depend on earlier ones.

## Step 1: tsconfig.json — Strictness Upgrade

**If missing:** Generate with `npx tsc --init --strict --target es2023 --module nodenext --moduleResolution nodenext --outDir dist --rootDir src --declaration --declarationMap --sourceMap --esModuleInterop --skipLibCheck`.

**If exists:** Check for strict mode:
```bash
node -e "const c=JSON.parse(require('fs').readFileSync('tsconfig.json','utf8').replace(/\/\/.*/g,'')); console.log(JSON.stringify(c.compilerOptions||{}))"
```

For upgradeable dimensions:
- `strict` not true → enable `"strict": true`
- `target` older than es2023 → upgrade to `"target": "es2023"`
- `module` not nodenext → set `"module": "nodenext"`, `"moduleResolution": "nodenext"`
- Missing `outDir` → add `"outDir": "dist"`
- Missing `rootDir` → add `"rootDir": "src"` (use detected source_dir)

Do NOT overwrite existing compiler options that aren't listed above.

## Step 2: package.json — Scripts + ESM

**If missing:** Run `pnpm init`, then configure. **If exists:**

Ensure `"type": "module"` is set (ESM default).

Add missing scripts (do NOT overwrite existing):
```json
{
  "build": "tsc",
  "lint": "biome check .",
  "format": "biome format --write .",
  "test": "vitest --run",
  "typecheck": "tsc --noEmit"
}
```

## Step 3: Linter/Formatter — Biome Setup

**If biome.json exists:** Leave as-is (compatible).

**If ESLint + Prettier (upgradeable):**
1. Install Biome: `pnpm add -D @biomejs/biome`
2. Run `npx biome init`
3. Warn: "Existing ESLint config detected. Biome is installed alongside — remove ESLint configs manually after verifying Biome covers your rules."
4. Do NOT auto-remove ESLint/Prettier configs (user may need them for React rules)

**If none:** Install and init: `pnpm add -D @biomejs/biome && npx biome init`

## Step 4: Test Framework — Vitest Setup

**If vitest present:** Leave as-is (compatible).

**If jest present:** Leave jest, add vitest alongside:
```bash
pnpm add -D vitest
```
Warn: "Jest config preserved. Vitest installed alongside — migrate tests at your pace."

**If mocha/jasmine (upgradeable) or none:**
```bash
pnpm add -D vitest
```
Add `"test": "vitest --run"` to package.json scripts if missing.

## Step 5: Pre-commit — Husky + lint-staged

**If husky + lint-staged present:** Leave as-is (compatible).

**If Python pre-commit framework (upgradeable):**
1. Install husky + lint-staged: `pnpm add -D husky lint-staged`
2. Init husky: `npx husky init`
3. Write pre-commit hook: `echo 'pnpm lint-staged' > .husky/pre-commit`
4. Add lint-staged config to package.json: `"lint-staged": { "*.{ts,tsx,js,jsx}": ["biome check --write"] }`
5. Warn: ".pre-commit-config.yaml preserved — remove manually after verifying husky setup."

**If none (upgradeable):**
```bash
pnpm add -D husky lint-staged
npx husky init
echo 'pnpm lint-staged' > .husky/pre-commit
```
Add lint-staged config to package.json.

## Step 6: Agent Config + Harness Files

**.claude/settings.json:** If missing, copy template. If exists, append template hooks per lifecycle point (match by `command` path). Never remove existing hooks.

**AGENTS.md:** If neither AGENTS.md nor CLAUDE.md exists, copy AGENTS-ts.md template as AGENTS.md and replace placeholders. If CLAUDE.md exists, skip (tell user to merge manually). If AGENTS.md exists, leave as-is.

**Copy remaining template files if absent:** instructions, skills, hooks, rules, CI (ci-ts.yml → ci.yml), PR template, CODEOWNERS, sync-rules.sh. Add `dist/`, `node_modules/`, `.nana/` to .gitignore if missing. Run `bash scripts/sync-rules.sh . .` after copy.

## Post-Transform Validation

Run and report (failures are informational, not blocking):
`pnpm biome check .`, `tsc --noEmit`, `pnpm vitest --run`. Present as summary table.

## Merge Strategy Reference

| File | Missing | Exists |
|------|---------|--------|
| tsconfig.json | Generate via tsc --init | Field-level upgrade: strict, target, module |
| package.json | pnpm init + configure | Script-level inject: add missing, leave existing |
| biome.json | Install + init | Leave as-is |
| .claude/settings.json | Copy template | Hook union by command path, never remove |
| AGENTS.md | Copy AGENTS-ts.md (if no CLAUDE.md) | Leave as-is |
| All other template files | Copy | Skip existing |
