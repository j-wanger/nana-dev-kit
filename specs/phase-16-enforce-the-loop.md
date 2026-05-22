# Spec: Enforce the Loop (Phase 16)

## Objective

Add mechanically-enforced hooks that prevent an AI agent from (1) writing implementation code without an approved spec, (2) declaring done without exit criteria passing, and (3) ending a session without debriefing when meaningful work was done.

## Context

Phase 15 shipped the monorepo (22 skills, modular install, 92 tests). The kit now installs a complete lifecycle — but compliance is advisory. The spec skill creates contracts, the dev-wiki tracks phases, and the Stop hook only checks pytest. An eager agent can blow past all of these. This is the Tier 2 gap from the engineering gap analysis: "proven patterns that measurably improve agent outcomes." Evidence: zircote/claude-spec implements PreToolUse spec-enforcement (exit 2 blocks the tool); LangChain showed +13.7 SWE-Bench points from self-verification alone.

The existing hook ecosystem has: PreToolUse (`block-dangerous-bash.sh` for Bash), PostToolUse (`audit-log.sh`, `scan-secrets.sh`, `auto-ruff-format.sh`), Stop (`check-tests-were-run.sh`, `py-review-stop-prompt.md`), SessionStart (`session-start.sh`), PreCompact (`pre-compact.sh`). This phase adds one PreToolUse hook (spec-enforcement) and one enhanced Stop hook (exit-criteria + debrief check).

## Scope

### In scope

- PreToolUse hook on Write/Edit: blocks implementation writes when no approved spec covers the active phase
- Enhanced Stop hook: verifies exit criteria for completed tasks AND checks debrief was run when meaningful work occurred
- Opt-in mechanism: enforcement enabled/disabled via `.claude/settings.json` or a marker file
- Install.sh integration: hooks install with `--all` and dev-wiki module (not `--core-only`)
- Test coverage: hook exit codes, allowlist bypass, graceful degradation, opt-in toggle

### Out of scope

- Loop/drift detection (Gap 2.3 — Phase 17)
- Memory ↔ wiki bridging (Gaps 1.3, 3.3 — Phase 17+)
- Working-knowledge auto-pruning (Gap 3.4)
- Modifying existing hooks (block-dangerous-bash, audit-log, scan-secrets)
- Language-agnostic refactoring of check-tests-were-run.sh

## Approach

**Three enforcement points, two hook files:**

1. **`enforce-spec.sh` (PreToolUse on Write|Edit):** Check if active phase has an approved spec. Approved = `specs/<phase-slug>.md` exists with non-empty Exit Criteria section, OR `active-phase.md` has `Gates: [x] Spec reviewed`. If neither: exit 2 with "No approved spec for active phase. Run /spec first."

2. **`enforce-loop.sh` (Stop hook):** Two checks:
   - Exit-criteria: parse `tasks.md` for ALL tasks marked `[x]` in the active phase section. For each that has a `success:` field, run the command via `bash -c`. If any fail: exit 2 with "Task exit criteria not met: <command>." Tasks without a `success:` field are skipped. This re-runs all completed tasks' criteria — it doubles as a regression check.
   - Debrief: if `.dev-wiki/` exists AND `git log --since="2 hours ago" --author="$(git config user.email)" --oneline` produces output, check if a journal entry exists at `.dev-wiki/articles/journal/$(date +%Y-%m-%d)-*.md`. If not: output warning (stdout, not stderr) "Consider running /dev-debrief." This is advisory only — does NOT exit 2.

**Opt-in:** Enforcement enabled by presence of `.claude/enforce` marker file (created by `install.sh --all`). Hooks exit 0 immediately if marker absent. Users disable with `rm .claude/enforce`.

**Path allowlist (spec-enforcement bypass):**
- `.dev-wiki/`, `.claude/`, `wiki/`, `specs/`, `tests/`, `templates/` — meta/lifecycle paths
- Files matching `*_test.*`, `test_*.*`, `*_spec.*` — test files
- `*.md` — documentation (specs, articles, notes). Note: SKILL.md files are declarative instructions, not implementation code — the allowlist is intentional.

## Constraints (CRITICAL)

- Hooks execute in <100ms per invocation. Prevents: compounding latency across hundreds of tool calls in a session. Guard: use file-existence checks and grep only — no subprocess parsing, no Python, no network calls.
- Hooks exit 0 (allow) when outside dev-wiki lifecycle (no `.dev-wiki/` directory, no `active-phase.md`). Prevents: blocking writes in non-lifecycle projects that install the kit for py-init only.
- Spec-enforcement does NOT block exploratory actions (reading files, running tests, git operations). Only Write and Edit tool events are gated. Prevents: the adversarial "blocks legitimate investigation" failure mode.
- A stub spec (empty sections, TODO placeholders) must NOT satisfy the approval check. Prevents: agent gaming the gate with vacuous specs. Guard: exact pattern `grep -qE '^\- \[ \] `.+`' specs/<slug>.md` — requires at least one unchecked criterion line containing a backtick-wrapped command. This is the spec format convention; specs without backtick exit criteria are malformed.
- Exit-criteria verification has a 30s timeout per command. Prevents: hanging on flaky criteria. Guard: wrap with `gtimeout 30` (GNU coreutils on macOS via Homebrew) or `timeout 30` (Linux). Detect availability: `command -v gtimeout || command -v timeout`. If neither available: run without timeout and document the degradation.
- Debrief check is advisory (stdout warning), not blocking (exit 2). Prevents: annoying users who intentionally skip debrief on small sessions. The spec-enforcement and exit-criteria hooks are the hard blocks.
- Enforcement must not govern its own source files — paths under `templates/.claude/hooks/`, `.claude/hooks/`, and `tests/` are exempt. Prevents: meta-circularity deadlock during hook development.
- `install.sh --core-only` must NOT install enforcement hooks. They belong to the dev-wiki module group (require lifecycle artifacts to function). Prevents: broken enforcement in minimal installs.
- Tasks in tasks.md without a `success:` field are silently skipped by exit-criteria verification. Prevents: hook crash on malformed or legacy task entries. Guard: parse with `grep -oP 'success: \K.*'`; if empty, skip.
- The Stop hook identifies "active phase tasks" by parsing the `<!-- phase:<slug> -->` HTML comment markers in tasks.md that delimit phase sections. Prevents: re-running ALL completed tasks across all phases (expensive, irrelevant). Guard: extract active phase slug from `active-phase.md`, find matching section in tasks.md.

## Deliverables

1. `templates/.claude/hooks/enforce-spec.sh` — PreToolUse hook (~40-60 lines)
2. `templates/.claude/hooks/enforce-loop.sh` — Stop hook (~60-80 lines)
3. Updated `install.sh` — enforcement hooks in dev-wiki module, creates `.claude/enforce` marker
4. Updated `tests/test_install.sh` — enforcement hook presence, marker file, --core-only exclusion
5. New `tests/test_enforce.sh` — minimum 8 test cases: (a) allow when no .dev-wiki, (b) allow when allowlisted path, (c) block when no spec, (d) block when stub spec, (e) allow when valid spec exists, (f) allow when gate marked [x], (g) exit-criteria pass, (h) exit-criteria fail, (i) debrief advisory warning, (j) enforce marker absent = allow all
6. Updated `templates/.claude/hooks/session-start.sh` — report enforcement status on session start

## Exit Criteria (machine-checkable)

- [ ] `test -f templates/.claude/hooks/enforce-spec.sh && bash -n templates/.claude/hooks/enforce-spec.sh`
- [ ] `test -f templates/.claude/hooks/enforce-loop.sh && bash -n templates/.claude/hooks/enforce-loop.sh`
- [ ] `echo '{"tool_name":"Write","input":{"file_path":"src/main.py"}}' | bash templates/.claude/hooks/enforce-spec.sh; [ $? -eq 0 ]` (no .dev-wiki = allow)
- [ ] Blocking case: create fixture with `.dev-wiki/` + `active-phase.md` (Phase: test, no spec), pipe Write JSON → assert exit 2
- [ ] `bash tests/test_enforce.sh` (wired into `make test` via Makefile)
- [ ] `THOME=$(mktemp -d) && HOME="$THOME" bash install.sh --core-only && test ! -f "$THOME/.claude/hooks/enforce-spec.sh" && rm -rf "$THOME"`
- [ ] `THOME=$(mktemp -d) && HOME="$THOME" bash install.sh && test -f "$THOME/.claude/hooks/enforce-spec.sh" && test -f "$THOME/.claude/enforce" && rm -rf "$THOME"`
- [ ] `make test` (includes test_enforce.sh)

## Checkpoints

- After enforce-spec.sh written: test exit codes (0 for allowlisted, 0 for no .dev-wiki, 2 for blocked) before proceeding
- After enforce-loop.sh written: test against a fixture tasks.md with known pass/fail criteria before integration
- After install.sh changes: run existing test suite to catch regressions before writing new tests
- If either hook exceeds 100ms in testing: profile and simplify (likely: reduce greps, cache file reads)

## Assumptions

- Claude Code pipes tool input as JSON to PreToolUse hooks on stdin, with `tool_name` and `input` fields. Exit 0 = allow, exit 2 = block (stderr shown to agent). If false: check Claude Code docs for current hook protocol and adapt.
- The Stop hook receives session context JSON on stdin (same as check-tests-were-run.sh uses). If false: the exit-criteria check degrades to checking all `[x]` tasks (not just session tasks).
- `active-phase.md` reliably reflects the current phase slug (used to locate the spec file). If false: fall back to grepping `_CURRENT_STATE.md` for the active phase name.
- Exit criteria commands in tasks.md are safe to re-run (idempotent, no side effects). If false: skip destructive-looking commands (those with rm, git push, etc.) during verification.
- Hook ordering in Claude Code is deterministic — existing PreToolUse hooks (block-dangerous-bash) run before or after the new one without conflict. If false: combine into a single dispatcher script.
- `timeout` or `gtimeout` is available for exit-criteria command wrapping. If false (stock macOS without Homebrew coreutils): degrade gracefully — run commands without timeout, document in session-start output that timeout protection is unavailable.
