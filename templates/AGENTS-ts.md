# Project: {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Toolchain

- TypeScript 5.x, Node.js 20+. Package manager: pnpm (never npm or yarn).
- Install: `pnpm install`. Run: `pnpm <script>`. Add dep: `pnpm add <pkg>`.
- Lint/format: `pnpm biome check --write .`
- Types: `tsc --noEmit` (strict mode — reads config from tsconfig.json).
- Tests: `pnpm vitest --run` (reads config from vitest.config.ts or vite.config.ts).
- Lock: `pnpm-lock.yaml` is committed. Never run `pnpm add` without checking the package exists on npm.
- Build: `pnpm build` runs `tsc` (type checking + declaration emit). No bundler by default.

## Conventions

- ESM only (`"type": "module"` in package.json). No CommonJS `require()`.
- Database access through `src/repositories/`; routers never import database drivers directly.
- Logging via structured logger (e.g., pino); never `console.log()` in production code.
- Config via environment variables loaded through validated schemas (e.g., zod + dotenv).
- Imports: use path aliases or relative imports within `src/`. No circular imports.
- Error handling: let exceptions propagate. No empty `catch {}` blocks. No `catch (e) { /* ignore */ }`.
- One function, one job. If a docstring needs "and", split the function.

## Testing

- Tests live in `tests/` or colocated as `*.test.ts` / `*.spec.ts`.
- Every exported function has at least one positive and one negative test.
- Test names are specifications: `it('returns empty array when no matching records')`.
- Shared setup in test helper files. No test-specific database setup outside fixtures.
- Mock external services only. Never mock the database — use a test database.

## Branch + Commit

- Branch names: `feat/<ticket>-slug`, `fix/<ticket>-slug`, `chore/<ticket>-slug`.
- Conventional Commits required. Subject <= 72 chars. Body explains why, not what.
- AI-authored commits include trailer: `AI-Author: <tool> (<model>)`

## Hard Rules

- Never commit secrets. `.env*` is gitignored and contains placeholders only.
- Never modify migration files after merge — generate new migrations.
- Run `pnpm lint-staged` (via husky pre-commit hook) before declaring any task done.
- Never add a dependency without verifying it exists on npm and is actively maintained.
- Never use `@ts-ignore` without an inline comment explaining why. Prefer `@ts-expect-error`.

## Project Structure

```
{{PROJECT_NAME}}/
  src/
    index.ts
    models/          # Domain types and validation schemas
    repositories/    # Database access layer
    services/        # Business logic
    api/             # HTTP handlers / routes
  tests/
    unit/
    integration/
    helpers.ts
  package.json
  tsconfig.json
  biome.json
  pnpm-lock.yaml
```

## Where to Look

- Architecture: `docs/architecture.md`
- Testing patterns: `docs/testing.md`
- API conventions: `docs/api.md`
- Security checklist: `docs/security.md`

## Pre-commit sequence

Before declaring any task complete, run this sequence:

```bash
pnpm biome check .
tsc --noEmit
pnpm vitest --run
```

All three must pass. If any fails, fix before proceeding.

<!-- Instruction budget: this file + nana identity + workflow instructions ~ 170 lines always-loaded.
     Ceiling before instruction-following degrades: ~300 lines total across all always-loaded files.
     If agent stops following rules, audit total line count across AGENTS.md + .claude/rules/ + .github/instructions/. -->
