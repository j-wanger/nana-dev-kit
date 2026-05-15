# Tasks

> Last updated: 2026-05-15 by /dev-plan

<!-- phase:phase-01-foundation-and-packaging -->
## Phase 1: Foundation & Packaging

- [x] Create .gitignore with exclusions for settings.local.json, .nana/, .DS_Store, *.pyc, __pycache__/, .venv/ | scope: .gitignore | success: test -f .gitignore && grep -q settings.local.json .gitignore && grep -q '.nana/' .gitignore | size: S
- [x] Verify install.sh idempotency: test expected outputs exist (RED), run install.sh in temp HOME verify 3 files created (GREEN), fix error handling issues (REFACTOR) | scope: install.sh | success: THOME=$(mktemp -d) && HOME="$THOME" bash install.sh && test -f "$THOME/.claude/skills/py-init/SKILL.md" && test -f "$THOME/.claude/rules/nana-soul.md" && test -f "$THOME/.claude/.nana-dev-kit-path" && cp "$THOME/.claude/rules/nana-soul.md" /tmp/nana-first && HOME="$THOME" bash install.sh && diff /tmp/nana-first "$THOME/.claude/rules/nana-soul.md" && rm -rf "$THOME" /tmp/nana-first | size: M
- [x] Verify sync-rules.sh correctness: test outputs in temp dir (RED), run sync-rules.sh verify 4 output files with headers and content (GREEN), fix script issues (REFACTOR) | scope: scripts/sync-rules.sh, Makefile | success: TDIR=$(mktemp -d) && echo '# Test' > "$TDIR/AGENTS.md" && bash scripts/sync-rules.sh "$TDIR" "$TDIR" && grep -q 'AUTO-GENERATED' "$TDIR/CLAUDE.md" && grep -q 'Test' "$TDIR/CLAUDE.md" && grep -q 'AUTO-GENERATED' "$TDIR/GEMINI.md" && test -f "$TDIR/.github/copilot-instructions.md" && test -f "$TDIR/.cursor/rules/main.mdc" && rm -rf "$TDIR" | size: M
- [x] Write README.md — concise format with install + usage + 5-layer table: test -f README.md fails (RED), write README (GREEN), trim to 40-50 lines (REFACTOR) | scope: README.md | success: test -f README.md && grep -q 'install.sh' README.md && grep -q 'py-init' README.md && grep -qi 'layer' README.md && [ $(wc -l < README.md) -ge 30 ] | size: M
- [ ] Initial git commit with clean project structure: no commit with all artifacts (RED), stage and commit (GREEN) | scope: * | success: git log --oneline -1 && git diff --quiet && git diff --cached --quiet && git ls-files | grep -q install.sh && git ls-files | grep -q README.md | size: S

<!-- phase:phase-02-automated-testing -->
## Phase 2: Automated Testing

- [ ] make test runs an automated test suite
- [ ] Tests cover install.sh idempotency (run twice, same result)
- [ ] Tests cover sync-rules correctness (output files match expected content)
- [ ] Tests cover template placeholder substitution
- [ ] All tests pass

<!-- phase:phase-03-distribution-and-polish -->
## Phase 3: Distribution & Polish

- [ ] Tagged release exists with semantic version
- [ ] Upgrade path documented (re-running install.sh on existing installs)
- [ ] CI validates the kit itself (lint scripts, run tests)
- [ ] Edge cases handled: missing dirs, partial installs, permission errors
