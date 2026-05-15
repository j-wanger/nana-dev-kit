# Active Knowledge
# userEmail
The user's email address is wang.jan.tried@gmail.com.
# currentDate
Today's date is 2026-05-15.

# Phase 3 Context

## install.sh behavior
- Copies exactly 3 files: py-init/SKILL.md, nana-soul.md, .nana-dev-kit-path
- Hooks are NOT global (not copied by install.sh)
- Has asymmetric error handling: `2>/dev/null || true` on SKILL.md copy but not on nana-soul.md copy
- Task 2 must unify this error handling and add source-file existence checks

## sync-rules.sh behavior
- Exits non-zero on missing AGENTS.md but has no other error handling
- No writability pre-check on target directory
- Task 3 must add writability guards and consistent error reporting

## Versioning decisions
- VERSION file at repo root is single source of truth (decision: v0-versioning-strategy)
- Git tags (v0.1.0) created from VERSION file
- install.sh gets NO version-awareness at v0.x -- unconditional overwrite

## CI decisions
- Kit CI at .github/workflows/kit-ci.yml (decision: kit-ci-separate-from-template)
- Distinct from templates/.github/workflows/ci.yml (Python CI template for scaffolded projects)
- shellcheck is CI-only (ubuntu-latest has it); not a local dependency
- Zero-dependency principle preserved

## README constraints
- Target ~40-50 lines, hard cap 55 lines (current ~54)
- Task 5 adds upgrade section while trimming to stay within budget
