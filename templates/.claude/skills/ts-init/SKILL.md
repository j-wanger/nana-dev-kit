---
name: ts-init
description: Scaffold the Nana 5-layer TypeScript dev harness. New projects get full scaffold; existing projects go through scan-approve-transform-validate. Use when the user says "init", "scaffold", or "set up a project" in a TypeScript context.
---

Scaffold or retrofit the Nana Dev Kit harness into the current directory for TypeScript projects. Two modes: **new project** (full scaffold) and **existing project** (feasibility scan → approval → transform → validation).

## Prerequisites

Check that the kit path is available and Node.js/pnpm are installed:
```bash
cat ~/.claude/.nana-dev-kit-path
node --version   # Must be >= 20
pnpm --version   # Must be installed
```
If kit path missing, tell the user to run `~/nana-dev-kit/install.sh` first.
If node/pnpm missing, tell the user to install Node.js 20+ and pnpm (`npm install -g pnpm`).

## Mode Detection

Detect whether this is a new or existing project:
```bash
test -f package.json || test -f tsconfig.json || test -f CLAUDE.md || test -f .claude/settings.json
```

- **If NONE exist:** New project → go to [New Project Steps](#new-project-steps)
- **If ANY exist:** Existing project → continue to Feasibility Scan below

---

## Feasibility Scan

Read `scanner.md` (in this skill directory) and follow its procedure. Run all 10 dimension checks. Do NOT modify any files during this phase.

Classifications: **compatible** (works as-is), **upgradeable** (automated changes needed), **blocking** (manual fix required).

After all checks, compile the report table:

```
| # | Dimension          | Status       | Detail                          |
|---|-------------------|--------------|----------------------------------|
| 1 | Build system      | <status>     | <what was detected>              |
| 2 | Source layout      | <status>     | <layout, source_dir>             |
| 3 | Linter/formatter   | <status>     | <what was detected>              |
| 4 | Type checker       | <status>     | <strict mode status>             |
| 5 | Test framework     | <status>     | <what was detected>              |
| 6 | Pre-commit         | <status>     | <what was detected>              |
| 7 | Dependency manager | <status>     | <what was detected>              |
| 8 | Agent config       | <status>     | <what was detected>              |
| 9 | CI workflows       | <status>     | <what was detected>              |
|10 | Git secrets        | <status>     | <what was detected>              |
```

### Approval Gate

**If ANY dimension is blocking:** STOP. Tell the user which dimensions are blocking and why. No files are modified. "Fix these manually, then re-run /ts-init."

**If ALL dimensions are compatible or upgradeable:** Present the report and ask: "Feasibility scan passed. N upgradeable, M compatible. Proceed with transform? (y/n)"

Wait for explicit approval before proceeding.

---

## Existing Project Transform

Read `transform.md` (in this skill directory) and follow its procedure. Key operations: add/upgrade biome config, add vitest if missing, set up husky + lint-staged, merge hooks. Runs Post-Transform Validation and presents summary.

---

## New Project Steps

1. **Initialize git** (if not already a repo):
   ```bash
   git init
   ```

2. **Initialize pnpm project** (if no package.json):
   ```bash
   pnpm init
   ```
   Then set `"type": "module"` in package.json.

3. **Set up TypeScript**:
   ```bash
   pnpm add -D typescript @types/node
   npx tsc --init --strict --target es2023 --module nodenext --moduleResolution nodenext --outDir dist --rootDir src --declaration --declarationMap --sourceMap --esModuleInterop --skipLibCheck
   ```

4. **Create source structure**:
   ```bash
   mkdir -p src tests
   echo 'export {}' > src/index.ts
   ```

5. **Set up linter + formatter**:
   ```bash
   pnpm add -D @biomejs/biome
   npx biome init
   ```

6. **Set up test framework**:
   ```bash
   pnpm add -D vitest
   ```
   Add to package.json scripts: `"test": "vitest --run"`.

7. **Set up pre-commit hooks**:
   ```bash
   pnpm add -D husky lint-staged
   npx husky init
   echo 'pnpm lint-staged' > .husky/pre-commit
   ```
   Add to package.json: `"lint-staged": { "*.{ts,tsx,js,jsx}": ["biome check --write"] }`.

8. **Add build + lint scripts** to package.json:
   ```json
   "scripts": {
     "build": "tsc",
     "lint": "biome check .",
     "format": "biome format --write .",
     "test": "vitest --run",
     "typecheck": "tsc --noEmit"
   }
   ```

9. **Copy template files** from the kit:
   ```bash
   KIT=$(cat ~/.claude/.nana-dev-kit-path)

   # Layer 1: Instruction files
   cp "$KIT/templates/AGENTS-ts.md" ./AGENTS.md

   # Layer 1: Identity + workflow instructions
   mkdir -p .github/instructions
   cp "$KIT/templates/.github/instructions/nana.instructions.md" .github/instructions/
   cp "$KIT/templates/.github/instructions/workflow.instructions.md" .github/instructions/

   # Layer 2: Skills
   cp -r "$KIT/templates/.claude/skills/" .claude/skills/

   # Layer 3: Hooks
   mkdir -p .claude/hooks
   cp "$KIT/templates/.claude/settings.json" .claude/settings.json
   cp "$KIT/templates/.claude/enforce" .claude/enforce   # opt-in marker → scaffold self-enforces
   cp "$KIT/templates/.claude/hooks/"*.sh .claude/hooks/
   cp "$KIT/templates/.claude/hooks/"*.md .claude/hooks/
   cp -r "$KIT/templates/.claude/hooks/session-start.d" .claude/hooks/   # sourced by session-start.sh under `set -euo pipefail` — omitting it aborts the whole SessionStart hook
   chmod +x .claude/hooks/*.sh .claude/hooks/session-start.d/*.sh

   # Layer 3: Identity rule + session state template
   mkdir -p .claude/rules
   cp "$KIT/templates/.claude/rules/"*.md .claude/rules/

   # Layer 5: CI + PR template + CODEOWNERS
   mkdir -p .github/workflows
   cp "$KIT/templates/.github/workflows/ci-ts.yml" .github/workflows/ci.yml

   cp "$KIT/templates/.github/PULL_REQUEST_TEMPLATE.md" .github/
   cp "$KIT/templates/.github/CODEOWNERS" .github/

   # Sync script
   mkdir -p scripts
   cp "$KIT/scripts/sync-rules.sh" scripts/
   chmod +x scripts/sync-rules.sh

   # Audit log directory (gitignored)
   mkdir -p .nana
   echo '.nana/' >> .gitignore
   echo 'dist/' >> .gitignore
   echo 'node_modules/' >> .gitignore
   echo '.dev-wiki/enforcement.log' >> .gitignore   # enforcement firing log: runtime state, not source
   ```

10. **Run sync** to generate per-surface copies from AGENTS.md:
    ```bash
    bash scripts/sync-rules.sh . .
    ```

11. **Customize AGENTS.md**: Replace `{{PROJECT_NAME}}` and `{{PROJECT_DESCRIPTION}}` placeholders with actual values. Update `.github/CODEOWNERS` with actual team handles.

12. **Re-run sync** after customization:
    ```bash
    bash scripts/sync-rules.sh . .
    ```

## What NOT to do

- Do not modify any files during the feasibility scan phase — scan is read-only.
- Do not proceed past the approval gate if any dimension is blocking.
- Do not modify generated surface copies (CLAUDE.md, copilot-instructions.md) directly — edit AGENTS.md and re-sync.

## After scaffolding

For **new projects**, tell the user:
- "5-layer harness scaffolded. Edit AGENTS.md to customize, then `bash scripts/sync-rules.sh . .` to propagate."
- "Run `pnpm vitest --run` after writing code, `pnpm biome check .` to lint, `/py-review` before committing."
- "Run `/dev-init` to set up development lifecycle tracking (phases, tasks, decisions)."

For **existing projects** (after transform), tell the user:
- "Harness retrofitted. Review the changes, then `bash scripts/sync-rules.sh . .` to propagate."
- "Run `/dev-init` to set up development lifecycle tracking if not already configured."
