<!-- nana:approved 2026-05-23 -->
# Spec: Phase 31 — Integration Eval + Memory Gating

## Objective

Add a multi-step lifecycle eval scenario testing hook composition across a full phase cycle, and an opt-in memory-gating enforcement hook that blocks implementation writes if memory_search hasn't been called this session.

## Context

The existing 43 eval scenarios test individual hooks in isolation. Nothing verifies that hooks compose correctly across a multi-step lifecycle (session-start → enforce-spec → post-commit → enforce-loop). The eval runner already supports multi-step lifecycle scenarios via `steps[]` arrays (eval-runner.sh lines 208-242), so no runner extension is needed — only a new scenario.

The soul's Memory Discipline section says "call memory_search at session start" and "check memory for prior decisions before recommendations," but nothing enforces this mechanically. For compliance-domain work (AML, financial crime), guaranteed cross-session recall isn't optional. The enforcement layer already has enforce-spec.sh and enforce-loop.sh as patterns. A third enforcement hook (enforce-memory.sh) extends the existing opt-in marker pattern with a separate marker (.claude/enforce-memory) for independent activation.

Cross-skill reference validation test already exists (Phase 26, test_templates.sh:388) — no work needed there.

## Scope

### In scope
- New lifecycle eval scenario: multi-step hook composition (4 steps, same staged directory)
- New enforcement hook: enforce-memory.sh (PreToolUse, Write|Edit)
- Session-start.sh modification: clear `.claude/.memory-consulted` at session start
- install.sh: copy enforce-memory.sh to ~/.claude/hooks/ + register as global PreToolUse hook in ~/.claude/settings.json (flat format, matching enforce-spec.sh pattern)
- Eval scenarios for enforce-memory: block (no marker), allow (marker present), inactive (no opt-in)
- Test assertions in test_templates.sh and test_install.sh

### Out of scope
- Eval runner extension (already supports multi-step)
- Cross-skill reference validation (already exists)
- Auto-detection of memory_search calls via PostToolUse (too complex; trust-based marker is sufficient)
- Soul modifications (59/60 lines, ceiling constraint; hook's stderr message is self-documenting)
- LongMemEval-S benchmarking (deferred to future phase)
- Custom lifecycle eval corpus (deferred)

## Approach

Two independent deliverable tracks:

**Track A — Integration eval:** Create `eval/corpus/lifecycle-full-phase-cycle/` with a 4-step scenario exercising session-start → enforce-spec (allow) → post-commit (detect) → enforce-loop (pass). Fixture files simulate a project with active phase, approved spec, enforcement enabled, and deliverable present. Each step asserts exit code and stdout/stderr patterns. Uses the existing `lifecycle` category and `steps[]` format.

**Track B — Memory gating:** Create `templates/.claude/hooks/enforce-memory.sh` following enforce-spec.sh patterns: jq fail-open guard, opt-in marker check (`~/.claude/enforce-memory`, home-relative), CI bypass (`$CI=true`), path allowlist (copy enforce-spec.sh case statement lines 38-42 verbatim), gate check (`.claude/.memory-consulted`, CWD-relative), enforcement.log event writing. Session-start.sh clears `.memory-consulted` inline (next to existing `.loop-state` cleanup). The hook's block message tells the agent exactly what to do: call memory_search, then `touch .claude/.memory-consulted`.

**Path conventions:** Opt-in marker `~/.claude/enforce-memory` is home-relative (persists across projects, set once). Gate marker `.claude/.memory-consulted` is CWD-relative (project-local, cleared each session). Registration is global `~/.claude/settings.json` via install.sh Python JSON merge (flat `{matcher, command}` format, matching enforce-spec.sh).

## Constraints (CRITICAL)

- enforce-memory.sh MUST fail-open when jq is absent (jq guard pattern, established Phase 24)
- enforce-memory.sh MUST fail-open when `~/.claude/enforce-memory` marker is absent (opt-in, home-relative, separate from `.claude/enforce`)
- enforce-memory.sh MUST fail-open in CI environments (`$CI=true`) where MCP tools are unavailable
- enforce-memory.sh MUST copy enforce-spec.sh case statement (lines 38-42) verbatim for path allowlist — prevents: memory gate blocking spec writes, test files, or dev-wiki updates
- Session-start.sh MUST clear `.claude/.memory-consulted` at each session start — prevents: stale marker carrying across sessions, making the gate permanently satisfied
- The lifecycle eval scenario MUST NOT modify the eval runner — prevents: regression risk to existing 43 scenarios
- enforcement.log writes MUST follow existing tail -n 500 truncation pattern — prevents: unbounded log growth

## Deliverables

1. `eval/corpus/lifecycle-full-phase-cycle/scenario.json` + fixture files (4-step lifecycle scenario)
2. `templates/.claude/hooks/enforce-memory.sh` (~40-50 lines, PreToolUse hook)
3. `eval/corpus/hook-enforce-memory-block/scenario.json` + fixtures
4. `eval/corpus/hook-enforce-memory-allow/scenario.json` + fixtures
5. `eval/corpus/hook-enforce-memory-inactive/scenario.json` + fixtures
6. Updated `templates/.claude/hooks/session-start.sh` (clear memory-consulted marker)
7. Updated `install.sh` (copy enforce-memory.sh to ~/.claude/hooks/ + flat PreToolUse JSON registration in ~/.claude/settings.json)
8. Updated `tests/test_templates.sh` and `tests/test_install.sh` (assertions)

## Exit Criteria (machine-checkable)

- [ ] `test -f eval/corpus/lifecycle-full-phase-cycle/scenario.json`
- [ ] `test -f templates/.claude/hooks/enforce-memory.sh && bash -n templates/.claude/hooks/enforce-memory.sh`
- [ ] `grep -q 'enforce-memory' install.sh && grep -q 'PreToolUse' install.sh`
- [ ] `grep -q 'memory-consulted' templates/.claude/hooks/session-start.sh`
- [ ] `make test`
- [ ] `make eval`

## Checkpoints

- After lifecycle eval scenario passes: report before starting Track B
- If enforce-memory.sh pattern diverges from enforce-spec.sh (different allowlist, different log format): STOP and ask — consistency matters more than optimization

## Assumptions

- The eval runner's existing `steps[]` lifecycle support handles per-step `setup_delta` correctly for 4+ steps. If false: reduce to 3 steps or fewer.
- `.claude/.memory-consulted` file existence is a sufficient gate mechanism (trust-based: agent touches after memory_search). If false: would need PostToolUse auto-detection, which is out of scope.
- The soul's 60-line ceiling cannot accommodate memory-consulted guidance. If false: add one line to Memory Discipline. Either way, the hook's stderr message is the primary agent guidance channel.
- Session-start.sh inline cleanup (next to existing `.loop-state` removal) is the right pattern for `.memory-consulted`. If false: extract to session-start.d/ module.
