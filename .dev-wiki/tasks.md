# Tasks

> Last updated: 2026-05-21 by /dev-plan (Phase 15 planned)

<details>
<summary>Phases 1-13 (all completed, 59 tasks)</summary>

<!-- phase:phase-01-foundation-and-packaging -->
## Phase 1: Foundation & Packaging

- [x] Create .gitignore with exclusions for settings.local.json, .nana/, .DS_Store, *.pyc, __pycache__/, .venv/ | scope: .gitignore | success: test -f .gitignore && grep -q settings.local.json .gitignore && grep -q '.nana/' .gitignore | size: S
- [x] Verify install.sh idempotency: test expected outputs exist (RED), run install.sh in temp HOME verify 3 files created (GREEN), fix error handling issues (REFACTOR) | scope: install.sh | success: THOME=$(mktemp -d) && HOME="$THOME" bash install.sh && test -f "$THOME/.claude/skills/py-init/SKILL.md" && test -f "$THOME/.claude/rules/nana-soul.md" && test -f "$THOME/.claude/.nana-dev-kit-path" && cp "$THOME/.claude/rules/nana-soul.md" /tmp/nana-first && HOME="$THOME" bash install.sh && diff /tmp/nana-first "$THOME/.claude/rules/nana-soul.md" && rm -rf "$THOME" /tmp/nana-first | size: M
- [x] Verify sync-rules.sh correctness: test outputs in temp dir (RED), run sync-rules.sh verify 4 output files with headers and content (GREEN), fix script issues (REFACTOR) | scope: scripts/sync-rules.sh, Makefile | success: TDIR=$(mktemp -d) && echo '# Test' > "$TDIR/AGENTS.md" && bash scripts/sync-rules.sh "$TDIR" "$TDIR" && grep -q 'AUTO-GENERATED' "$TDIR/CLAUDE.md" && grep -q 'Test' "$TDIR/CLAUDE.md" && grep -q 'AUTO-GENERATED' "$TDIR/GEMINI.md" && test -f "$TDIR/.github/copilot-instructions.md" && test -f "$TDIR/.cursor/rules/main.mdc" && rm -rf "$TDIR" | size: M
- [x] Write README.md — concise format with install + usage + 5-layer table: test -f README.md fails (RED), write README (GREEN), trim to 40-50 lines (REFACTOR) | scope: README.md | success: test -f README.md && grep -q 'install.sh' README.md && grep -q 'py-init' README.md && grep -qi 'layer' README.md && [ $(wc -l < README.md) -ge 30 ] | size: M
- [x] Initial git commit with clean project structure: no commit with all artifacts (RED), stage and commit (GREEN) | scope: * | success: git log --oneline -1 && git diff --quiet && git diff --cached --quiet && git ls-files | grep -q install.sh && git ls-files | grep -q README.md | size: S

<!-- phase:phase-02-automated-testing -->
## Phase 2: Automated Testing

- [x] Create tests/helpers.sh — shared assertion functions (assert_eq, assert_file_exists, assert_contains, assert_exit_code) + test summary reporting: bash -n tests/helpers.sh fails (RED), write helper functions (GREEN) | scope: tests/helpers.sh | success: test -f tests/helpers.sh && bash -n tests/helpers.sh | size: S
- [x] Create tests/test_install.sh — install.sh idempotency in temp HOME, verify 3 files created, diff between runs, verify kit path content: bash tests/test_install.sh fails (RED), write tests using HOME=$(mktemp -d) pattern (GREEN), clean up edge cases (REFACTOR) | scope: tests/test_install.sh | success: bash tests/test_install.sh && grep -q 'mktemp' tests/test_install.sh | size: M
- [x] Create tests/test_sync_rules.sh — 4 output files created, AUTO-GENERATED headers, content propagated, Cursor frontmatter, missing AGENTS.md exits non-zero with stderr: bash tests/test_sync_rules.sh fails (RED), write tests in temp dir (GREEN), add error case tests (REFACTOR) | scope: tests/test_sync_rules.sh | success: bash tests/test_sync_rules.sh && grep -q 'AUTO-GENERATED' tests/test_sync_rules.sh | size: M
- [x] Create tests/test_templates.sh — verify {{PACKAGE_NAME}}, {{PROJECT_DESCRIPTION}}, {{PROJECT_NAME}} placeholders exist in template files: bash tests/test_templates.sh fails (RED), write grep-based placeholder checks (GREEN) | scope: tests/test_templates.sh | success: bash tests/test_templates.sh | size: S
- [x] Add make test target and verify all tests pass — Makefile test target runs all test scripts fail-fast: make test fails (RED), add test target (GREEN) | scope: Makefile, tests/* | success: make test | size: S

<!-- phase:phase-03-distribution-and-polish -->
## Phase 3: Distribution & Polish

- [x] Create VERSION file with 0.1.0: test -f VERSION fails (RED), create VERSION containing "0.1.0" (GREEN) | scope: VERSION | success: test -f VERSION && grep -qx '0.1.0' VERSION | size: S
- [x] Harden install.sh edge cases — fix asymmetric error suppression, validate source files exist before copy, report clear errors on failure | scope: install.sh, tests/test_install.sh | success: bash tests/test_install.sh | size: M
- [x] Harden sync-rules.sh edge cases — validate target directory writability, guard against partial writes | scope: scripts/sync-rules.sh, tests/test_sync_rules.sh | success: bash tests/test_sync_rules.sh | size: M
- [x] Create .github/workflows/kit-ci.yml — shellcheck all .sh files + make test | scope: .github/workflows/kit-ci.yml | success: test -f .github/workflows/kit-ci.yml && grep -q 'shellcheck' .github/workflows/kit-ci.yml && grep -q 'make test' .github/workflows/kit-ci.yml | size: M
- [x] Update README.md — add "Upgrading" section | scope: README.md | success: grep -qi 'upgrad' README.md && [ $(wc -l < README.md) -le 55 ] | size: S
- [x] Tag release v0.1.0 | scope: VERSION, .github/workflows/kit-ci.yml, install.sh, scripts/sync-rules.sh, README.md | success: git tag -l 'v0.1.0' | grep -q 'v0.1.0' | size: S

<!-- phase:phase-04-dev-wiki-and-memory-integration -->
## Phase 4: Dev-Wiki & Memory Integration

- [x] Vendor memory_server from nanaclaw | scope: memory_server/ | success: test -f memory_server/server.py && test -f memory_server/requirements.txt | size: M
- [x] Update install.sh to register memory MCP server | scope: install.sh, tests/test_install.sh | success: bash tests/test_install.sh && grep -q 'mcpServers' tests/test_install.sh | size: M
- [x] Enhance session-start.sh — read .dev-wiki/_CURRENT_STATE.md | scope: templates/.claude/hooks/session-start.sh | success: bash -n templates/.claude/hooks/session-start.sh && grep -q 'dev-wiki' templates/.claude/hooks/session-start.sh | size: S
- [x] Update /py-init SKILL.md — add /dev-init suggestion | scope: templates/.claude/skills/py-init/SKILL.md | success: grep -q 'dev-init' templates/.claude/skills/py-init/SKILL.md | size: S
- [x] Update README.md — add Memory & Dev-Wiki section | scope: README.md | success: grep -qi 'memory' README.md && [ $(wc -l < README.md) -le 65 ] | size: S

<!-- phase:phase-05-memory-bootstrap-and-report -->
## Phase 5: Memory Bootstrap & Package Report

- [x] Bootstrap memory server deps in install.sh | scope: install.sh, tests/test_install.sh | success: bash tests/test_install.sh && grep -q 'venv' tests/test_install.sh | size: M
- [x] Create HTML package report generator | scope: scripts/generate-report.py, docs/report.html, Makefile | success: test -f scripts/generate-report.py && test -f docs/report.html | size: M
- [x] Update README.md — note memory deps auto-installed | scope: README.md | success: grep -qi 'auto.*install\|venv\|pip' README.md | size: S

<!-- phase:phase-06-ship-and-workflow-assessment -->
## Phase 6: Ship & Workflow Assessment

- [x] Create versioned workflow breakdown generator | scope: scripts/generate-workflow.py, docs/workflow.html, Makefile, README.md | success: test -f scripts/generate-workflow.py && test -f docs/workflow.html | size: M
- [x] Bump version to 0.2.0 and regenerate reports | scope: VERSION, docs/report.html, docs/workflow.html | success: grep -qx '0.2.0' VERSION | size: S
- [x] Commit all work + push to GitHub + tag v0.2.0 | scope: * | success: git tag -l 'v0.2.0' | grep -q 'v0.2.0' | size: S

<!-- phase:phase-07-soul-and-instructions-enhancement -->
## Phase 7: Soul & Instructions Enhancement

- [x] Add "Before acting" and "Memory discipline" sections to nana-soul.md | scope: templates/.claude/rules/nana-soul.md | success: grep -qi 'before acting' templates/.claude/rules/nana-soul.md && [ $(wc -l < templates/.claude/rules/nana-soul.md) -le 60 ] | size: M
- [x] Extract "Who you're working with" from template, install via install.sh | scope: templates/.claude/rules/nana-soul.md, templates/.claude/rules/nana-personal.md, install.sh, tests/test_install.sh | success: ! grep -qi 'jake' templates/.claude/rules/nana-soul.md && test -f templates/.claude/rules/nana-personal.md | size: M
- [x] Rename "Verification" to "Pre-commit sequence" in AGENTS.md | scope: templates/AGENTS.md | success: grep -qi 'pre-commit sequence' templates/AGENTS.md | size: S
- [x] Sync nana.instructions.md to match updated nana-soul.md | scope: templates/.github/instructions/nana.instructions.md | success: diff <(tail -n +5 templates/.github/instructions/nana.instructions.md) templates/.claude/rules/nana-soul.md | size: S
- [x] Add protocol assertions + instruction budget regression test | scope: tests/test_templates.sh | success: bash tests/test_templates.sh | size: S

<!-- phase:phase-08-spec-skill -->
<!-- gates: spec=8/10 approach=yes plan-review=7/10 tasks=yes -->
## Phase 8: Spec Skill

- [x] Create /spec SKILL.md + spec-reviewer-prompt.md | scope: templates/.claude/skills/spec/SKILL.md, templates/.claude/skills/spec/spec-reviewer-prompt.md | success: test -f templates/.claude/skills/spec/SKILL.md && test -f templates/.claude/skills/spec/spec-reviewer-prompt.md | size: M
- [x] Backport Constraints/Checkpoints/Assumptions into phase template + update dev-plan Step 6 | scope: ~/.claude/skills/dev-wiki/phase-template.md, ~/.claude/skills/dev-plan/SKILL.md | success: grep -qi 'constraints' ~/.claude/skills/dev-wiki/phase-template.md | size: M
- [x] Update install.sh to copy spec skill + add tests | scope: install.sh, tests/test_install.sh, tests/test_templates.sh | success: grep -q 'spec' install.sh && bash tests/test_install.sh | size: S
- [x] Update README with /spec mention | scope: README.md | success: grep -qi '/spec' README.md | size: S

<!-- phase:phase-09-file-lifecycle-reference -->
<!-- gates: spec=9/10 approach=yes plan-review=n/a(2-tasks) tasks=yes -->
## Phase 9: File Lifecycle Reference

- [x] Create file-lifecycle.md + remove PROJECT_STATE.md orphan | scope: templates/.claude/rules/file-lifecycle.md, templates/.claude/hooks/session-start.sh, install.sh | success: test -f templates/.claude/rules/file-lifecycle.md && grep -q 'file-lifecycle' install.sh | size: M
- [x] Update tests | scope: tests/test_install.sh, tests/test_templates.sh | success: bash tests/test_install.sh && bash tests/test_templates.sh | size: S
- [x] Commit + push to GitHub | scope: * | success: git diff --quiet | size: S

<!-- phase:phase-10-memory-lifecycle-convergence -->
<!-- gates: spec=8/10 approach=SKIPPED plan-review=SKIPPED(post-hoc=8/10) tasks=SKIPPED -->
## Phase 10: Memory Lifecycle Convergence

- [x] Remove MEMORY.md from session-start + update soul + file-lifecycle | scope: templates/.claude/hooks/session-start.sh, templates/.claude/rules/nana-soul.md, templates/.claude/rules/file-lifecycle.md | success: ! grep -q 'MEMORY.md' templates/.claude/hooks/session-start.sh | size: M
- [x] Verify tests + commit + push | scope: tests/test_templates.sh, * | success: bash tests/test_templates.sh && git diff --quiet | size: S

<!-- phase:phase-11-process-hardening -->
<!-- gates: spec=n/a(process-hardening) approach=yes plan-review=yes tasks=yes -->
## Phase 11: Process Hardening

- [x] Add pre-flight gate verification to implementation-guide.md | scope: ~/.claude/skills/dev-plan/implementation-guide.md | success: grep -qi 'gate.*unchecked.*STOP\|refuse.*unchecked' ~/.claude/skills/dev-plan/implementation-guide.md | size: M
- [x] Add gate-compliance audit to dev-debrief retro-check | scope: ~/.claude/skills/dev-debrief/SKILL.md | success: grep -qi 'gate.*compliance\|gate.*audit' ~/.claude/skills/dev-debrief/SKILL.md | size: M
- [x] Add gate-check reminder to session-start.sh | scope: templates/.claude/hooks/session-start.sh | success: grep -q 'gate-check\|unchecked.*gate' templates/.claude/hooks/session-start.sh | size: S
- [x] Add regression test + budget assertion | scope: tests/test_templates.sh | success: bash tests/test_templates.sh | size: S
- [x] Commit + push + regenerate reports | scope: docs/report.html, docs/workflow.html | success: git diff --quiet | size: XS

<!-- phase:phase-12-soul-enhancement-memory-harvest -->
<!-- gates: spec=9/10 approach=yes plan-review=pending tasks=yes -->
## Phase 12: Soul Enhancement & Memory Harvest

- [x] Compress soul + add Voice & presence section — free >=3 lines via compression (remove 3 redundant "What to avoid" bullets), add 5-bullet Voice & presence section. Sync nana.instructions.md. TDD: soul missing "Voice" section (RED), compress + add + sync (GREEN), verify reads coherently (REFACTOR) | scope: templates/.claude/rules/nana-soul.md, templates/.github/instructions/nana.instructions.md | success: grep -qi 'Voice.*presence' templates/.claude/rules/nana-soul.md && [ $(wc -l < templates/.claude/rules/nana-soul.md) -le 60 ] && diff <(tail -n +5 templates/.github/instructions/nana.instructions.md) templates/.claude/rules/nana-soul.md | size: M
- [x] Create memory-harvest companion + wire into dev-debrief — Write memory-harvest.md (~40 lines): extraction categories, memory_store output, 100-entry ceiling, stale removal. Add Step 4.7 to SKILL.md (~3 lines). Add step to executor-prompt.md. TDD: memory-harvest.md doesn't exist (RED), write companion + wire (GREEN), verify no overlap with Step 5 (REFACTOR) | scope: ~/.claude/skills/dev-debrief/memory-harvest.md, ~/.claude/skills/dev-debrief/SKILL.md, ~/.claude/skills/dev-debrief/executor-prompt.md | success: test -f ~/.claude/skills/dev-debrief/memory-harvest.md && grep -qi 'memory.harvest' ~/.claude/skills/dev-debrief/SKILL.md && grep -qi 'memory_store' ~/.claude/skills/dev-debrief/memory-harvest.md && grep -qi 'memory.harvest' ~/.claude/skills/dev-debrief/executor-prompt.md | size: M
- [x] Add spec-existence check to dev-plan pre-checks — New Step 0.6: standard ceremony checks specs/<phase-slug>.md or phase article ## Formal Spec. If neither: STOP. Lite: skip. TDD: no spec check exists (RED), add Step 0.6 (GREEN) | scope: ~/.claude/skills/dev-plan/SKILL.md | success: grep -qi 'spec.*exist\|spec.*check\|No spec found' ~/.claude/skills/dev-plan/SKILL.md | size: S
- [x] Add thinking-protocol T0 to dev-plan Step 6 — Inline check: challenge frame, read subtext, delay commitment. Conversational output only. TDD: no thinking protocol reference in Step 6 area (RED), add T0 check (GREEN) | scope: ~/.claude/skills/dev-plan/SKILL.md | success: grep -qi 'thinking.protocol\|challenge.*frame' ~/.claude/skills/dev-plan/SKILL.md | size: S
- [x] Add soul ceiling test + regression check — Assert soul <=60 lines in test_templates.sh. Run full suite. TDD: no soul ceiling test (RED), add assertion (GREEN) | scope: tests/test_templates.sh | success: bash tests/test_templates.sh && grep -qi 'soul.*60\|60.*soul\|wc.*nana-soul' tests/test_templates.sh | size: S
- [x] Commit + push + regenerate reports — make report && make workflow, git commit, git push. TDD: reports outdated (RED), regenerate + commit + push (GREEN) | scope: docs/report.html, docs/workflow.html | success: git diff --quiet && git diff --cached --quiet | size: XS

<!-- phase:phase-13-final-polish-and-ship -->
<!-- gates: spec=8/10(revised-to-accept) approach=yes plan-review=7/10(revised) tasks=yes -->
## Phase 13: Final Polish & Ship

- [x] [S] Add H8+H9 to soul + sync — Add 2 verbatim lines to Thinking protocol: "Before searching, name what you already know — then construct targeted queries from it, not generic topic keywords." and "Check adjacent domains: upstream causes, downstream effects, parallel developments." Sync nana.instructions.md. TDD: soul missing H8/H9 (RED), add + sync (GREEN), verify exactly 59 lines (REFACTOR) | scope: templates/.claude/rules/nana-soul.md, templates/.github/instructions/nana.instructions.md | success: grep -qi 'targeted queries' templates/.claude/rules/nana-soul.md && [ $(wc -l < templates/.claude/rules/nana-soul.md) -eq 59 ] && diff <(tail -n +5 templates/.github/instructions/nana.instructions.md) templates/.claude/rules/nana-soul.md | size: S
- [x] [M] Make personal profile template + conditional install — Replace templates/.claude/rules/nana-personal.md with generic placeholder (no Jake content). Update install.sh to conditionally copy (skip if existing). Write Jake's 7-line version to ~/.claude/rules/nana-personal.md locally. Update tests. TDD: template has 'jake' (RED), replace template + update install.sh + write local (GREEN), verify idempotency (REFACTOR) | scope: templates/.claude/rules/nana-personal.md, install.sh, tests/test_install.sh, tests/test_templates.sh | success: ! grep -qi 'jake' templates/.claude/rules/nana-personal.md && grep -qi 'conditional\|skip.*exist\|-f.*personal' install.sh && bash tests/test_install.sh | size: M
- [x] [S] Raise SKILL.md ceiling — Change complex-orchestration cap from 250 to 350 in self-check-checklist.md. TDD: grep shows 250 (RED), change to 350 (GREEN) | scope: ~/.claude/skills/dev-plan/self-check-checklist.md | success: grep -q 'complex.*350\|≤350' ~/.claude/skills/dev-plan/self-check-checklist.md | size: S
- [x] [S] Version bump + reports + tests — Write 0.3.0 to VERSION, regenerate reports, run make test. TDD: VERSION shows 0.2.0 (RED), update + regen + test (GREEN) | scope: VERSION, docs/report.html, docs/workflow.html | success: grep -qx '0.3.0' VERSION && make test | size: S
- [x] [XS] Commit + tag v0.3.0 + push — Annotated tag, push with tags. TDD: no v0.3.0 tag (RED), commit + tag + push (GREEN) | scope: * | success: git diff --quiet && git tag -l 'v0.3.0' | grep -q 'v0.3.0' | size: XS

</details>

<!-- phase:phase-14-adversarial-thinking-and-review -->
<!-- gates: spec=8/10 approach=yes plan-review=8/10 tasks=yes -->
## Phase 14: Adversarial Thinking & Review

- [x] [S] T0 Rewrite — force non-vacuous output in dev-plan Step 6: grep -qi 'weakest.*assumption' fails (RED), rewrite Step 6 T0 with output-format requirements: name weakest assumption + what breaks, identify alternative framing, state what info would change recommendation, add non-vacuity gate ~15 lines (GREEN) | scope: ~/.claude/skills/dev-plan/SKILL.md | success: grep -qi 'weakest.*assumption\|what breaks' ~/.claude/skills/dev-plan/SKILL.md | size: S
- [x] [M] Adversarial constraint generation — spec Step 2.5 + companion: test -f adversarial-constraints-prompt.md fails (RED), create adversarial-constraints-prompt.md (~40-50 lines) with clean-context subagent prompt for constraints with falsifiability tests, edge cases, scope risks + insert Step 2.5 in spec SKILL.md ~20 lines (GREEN), verify SKILL.md ≤ 350 lines (REFACTOR) | scope: templates/.claude/skills/spec/SKILL.md, templates/.claude/skills/spec/adversarial-constraints-prompt.md | success: test -f templates/.claude/skills/spec/adversarial-constraints-prompt.md && grep -qi 'adversarial.*constraint\|clean.context.*subagent' templates/.claude/skills/spec/SKILL.md && [ $(wc -l < templates/.claude/skills/spec/SKILL.md) -le 350 ] | size: M
- [x] [M] Install + tests + verification: grep -q 'adversarial-constraints-prompt' install.sh fails (RED), add copy line to install.sh + test assertions in test_install.sh and test_templates.sh (GREEN), run full suite (REFACTOR) | scope: install.sh, tests/test_install.sh, tests/test_templates.sh | success: grep -q 'adversarial-constraints-prompt' install.sh && make test && [ $(wc -l < templates/.claude/rules/nana-soul.md) -le 60 ] | size: M

<!-- phase:phase-15-wire-the-lifecycle -->
<!-- gates: spec=7/10(revised-to-accept) approach=yes plan-review=7/10(revised) tasks=yes -->
## Phase 15: Wire the Lifecycle

- [x] [M] Import dev-wiki skills — copy 6 dirs from ~/.claude/skills/{dev-wiki,dev-check,dev-debrief,dev-init,dev-plan,dev-scan} into templates/.claude/skills/. TDD: test -d templates/.claude/skills/dev-plan fails (RED), cp -r all 6 dirs (GREEN), verify cross-references with grep for companion file paths (REFACTOR) | scope: templates/.claude/skills/dev-*/ | success: ls -d templates/.claude/skills/dev-wiki templates/.claude/skills/dev-check templates/.claude/skills/dev-debrief templates/.claude/skills/dev-init templates/.claude/skills/dev-plan templates/.claude/skills/dev-scan && [ $(find templates/.claude/skills/dev-* -name "*.md" | wc -l) -ge 40 ] | size: M
- [x] [M] Import knowledge-wiki skills — copy 11 dirs from ~/.claude/skills/{knowledge-wiki,wiki-absorb,wiki-add,wiki-bootstrap,wiki-consolidate,wiki-health,wiki-index,wiki-init,wiki-query,wiki-reorg,wiki-registry} into templates/.claude/skills/. TDD: test -d templates/.claude/skills/wiki-query fails (RED), cp -r all 11 dirs (GREEN), verify cross-references (REFACTOR) | scope: templates/.claude/skills/wiki-*/, templates/.claude/skills/knowledge-wiki/ | success: ls -d templates/.claude/skills/knowledge-wiki templates/.claude/skills/wiki-absorb templates/.claude/skills/wiki-add templates/.claude/skills/wiki-bootstrap templates/.claude/skills/wiki-consolidate templates/.claude/skills/wiki-health templates/.claude/skills/wiki-index templates/.claude/skills/wiki-init templates/.claude/skills/wiki-query templates/.claude/skills/wiki-reorg templates/.claude/skills/wiki-registry && [ $(find templates/.claude/skills/wiki-* templates/.claude/skills/knowledge-wiki -name "*.md" | wc -l) -ge 45 ] | size: M
- [x] [S] Generate MANIFEST — create templates/.claude/skills/MANIFEST with sorted file listing + md5 checksums. Depends: tasks 1+2. TDD: test -f templates/.claude/skills/MANIFEST fails (RED), generate with find+sort+md5 (GREEN) | scope: templates/.claude/skills/MANIFEST | success: test -f templates/.claude/skills/MANIFEST && [ $(wc -l < templates/.claude/skills/MANIFEST) -gt 100 ] | size: S
- [x] [L] Refactor install.sh — module-group architecture with --all/--core-only/--no-python/--dry-run flags, dependency validation (exit non-zero on missing prereqs), directory-based iteration. Depends: tasks 1+2. TDD: bash install.sh --dry-run fails (RED), implement flag parsing + module definitions + iteration loop (GREEN), verify idempotency + existing tests pass (REFACTOR) | scope: install.sh | success: bash install.sh --dry-run 2>&1 | grep -q 'dev-plan' && THOME=$(mktemp -d) && HOME="$THOME" bash install.sh --core-only && test ! -d "$THOME/.claude/skills/dev-plan" && test -f "$THOME/.claude/rules/nana-soul.md" && rm -rf "$THOME" && THOME=$(mktemp -d) && HOME="$THOME" bash install.sh --no-python && test ! -d "$THOME/.claude/skills/py-init" && test -d "$THOME/.claude/skills/dev-plan" && rm -rf "$THOME" | size: L
- [x] [M] Add PreCompact hook — pure bash, reads _CURRENT_STATE.md + tasks.md + active-phase.md, outputs structured summary for context injection. TDD: test -f templates/.claude/hooks/pre-compact.sh fails (RED), write hook with graceful skips (GREEN), test against fixture with output validation (REFACTOR) | scope: templates/.claude/hooks/pre-compact.sh | success: bash -n templates/.claude/hooks/pre-compact.sh && mkdir -p /tmp/test-pc/.dev-wiki && printf '## Active Phase\n**Phase 15** (status: active)\n' > /tmp/test-pc/.dev-wiki/_CURRENT_STATE.md && (cd /tmp/test-pc && bash "$OLDPWD/templates/.claude/hooks/pre-compact.sh") 2>/dev/null | grep -qi 'phase' && rm -rf /tmp/test-pc | size: M
- [x] [S] Enhance session-start.sh — extract active task topic from dev-wiki state, output memory_search guidance line. TDD: grep -q 'memory_search' templates/.claude/hooks/session-start.sh fails (RED), add topic extraction + guidance output (GREEN) | scope: templates/.claude/hooks/session-start.sh | success: bash -n templates/.claude/hooks/session-start.sh && grep -q 'memory_search' templates/.claude/hooks/session-start.sh | size: S
- [x] [M] Update test suite — test_install.sh: flag combinations (--all, --core-only, --no-python), negative assertions, new skill dir presence. test_templates.sh: spot-check imported skills. TDD: new assertions fail (RED), add test cases (GREEN), verify make test <30s (REFACTOR) | scope: tests/test_install.sh, tests/test_templates.sh | success: make test && THOME=$(mktemp -d) && HOME="$THOME" bash install.sh && test -d "$THOME/.claude/skills/dev-plan" && test -d "$THOME/.claude/skills/wiki-query" && rm -rf "$THOME" | size: M
