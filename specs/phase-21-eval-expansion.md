# Spec: Phase 21 — Eval Expansion

## Objective

Extend the eval harness from 18 to ~30 scenarios across three expansion axes: structural coverage for 5 uncovered bash hooks, a new `context` eval category that validates rule files reach Claude's context window correctly, and lifecycle scenarios that chain multiple hooks in realistic session flows.

## Context

Phase 20 built the eval harness with 18 fixture-based bash scenarios (10 hook, 5 skill, 3 lifecycle). All pass at 100%. However, 5 bash hooks have no eval coverage (audit-log, auto-ruff-format, block-dangerous-bash, check-tests-were-run, scan-secrets) and 1 prompt file (py-review-stop-prompt.md) has no validation. More critically, the eval doesn't test whether rules files (soul, file-lifecycle, personal profile) are properly surfaced to the agent — it only tests hook plumbing. The user observed the soul was installed but didn't feel it was shaping behavior. This phase addresses the testable layer: verifying that context injection works correctly so the right content reaches the model.

## Scope

### In scope
- **Structural:** 10-12 new hook scenarios for 5 uncovered bash hooks (2+ per hook: allow + block paths)
- **Context injection:** 3-5 new `context` category scenarios that validate rule files are present, syntactically valid, contain required sections, and get surfaced by session-start.sh
- **Prompt validation:** 1 scenario for py-review-stop-prompt.md as a `skill` artifact type with a content validator
- **Lifecycle expansion:** 2-3 additional multi-step sequences (full session flow: start -> work -> audit -> stop)
- **Validator:** 1 new validator for prompt artifacts (validate-prompt.sh)
- **Runner update:** support `context` category in eval-runner.sh

### Out of scope
- **Live Claude invocation** — no API calls, no model-as-judge
- **Soul effectiveness testing** — whether Claude _follows_ rules is model behavior, not kit behavior. This phase tests that rules _reach_ the model.
- **Hook implementation changes** — eval scenarios test existing behavior
- **Wiki-index Python eval** — language-agnostic concerns (Gap 4.1) are a separate phase
- **CI integration** — `make eval` is already separate from `make test`

## Approach

Extend the existing eval-runner.sh with a `context` category. Keep binary scoring. Each new scenario follows the existing `scenario.json` manifest pattern with HOME-isolated tmpdir execution.

**Context category execution model:** Context scenarios have a `checks` array in `scenario.json`. Each check has a `type` and parameters:

- `file_exists` — `{"type": "file_exists", "path": "<relative to HOME>"}` — verify rule file is installed
- `section_present` — `{"type": "section_present", "path": "<relative to HOME>", "sections": ["## Section Name", ...]}` — grep for H2 headers in file
- `hook_output` — `{"type": "hook_output", "hook": "<hook.sh>", "stdout_contains": [...]}` — run a hook and check output contains expected patterns

The runner iterates checks and scores binary pass/fail (all checks must pass for score=1).

**Required sections per rule file:**
- `nana-soul.md`: `## Technical posture`, `## Voice & presence`, `## Thinking protocol`, `## Memory discipline`, `## Work habits`, `## Code quality lens`
- `file-lifecycle.md`: `## Who updates what`, `## Decision routing`
- `nana-personal.md`: none required (template is customizable)

**Hook stdin contracts (per-hook, not uniform):**
- audit-log.sh, auto-ruff-format.sh, scan-secrets.sh: `{"tool_name":"...","input":{"file_path":"..."}}`
- block-dangerous-bash.sh: `{"tool_name":"Bash","input":{"command":"..."}}`
- check-tests-were-run.sh: `{"tool_uses":[{"input":{"file_path":"...","command":"..."}}]}`

For the 5 uncovered hooks: each gets 2 scenarios minimum (allow + block). Hooks with external dependencies (ruff, gitleaks) test the fallback/missing-tool path since the eval environment can't guarantee those tools exist.

For py-review-stop-prompt.md: use the existing `skill` category with a new `validate-prompt.sh` that checks structural content (numbered checklist items present, format directive present).

## Constraints (CRITICAL)

- **Binary scoring only** — no partial scores, no LLM-as-judge. Every assertion reduces to grep/jq/diff returning 0 or non-zero. Prevents: eval drift toward subjective scoring.
- **No live model calls** — all fixtures are pre-captured static inputs. Eval must complete in <60s total. Prevents: flaky tests, API costs, non-reproducible results.
- **CWD isolation for audit-log.sh** — audit-log writes `.nana/audit.jsonl` relative to CWD, not HOME. Scenarios must use the existing `WORK_DIR=$(mktemp -d)` pattern and verify no writes escape. Prevents: eval polluting the real project.
- **Safe fixture content** — block-dangerous-bash.sh fixtures must use obviously fake paths (`/FAKE/DO_NOT_EXECUTE`). Never include executable dangerous commands even in string literals. Prevents: accidental execution if isolation fails.
- **Fixture JSON must match each hook's actual field paths** — audit-log/auto-ruff/scan-secrets use `{"input":{"file_path":"..."}}`, block-dangerous-bash uses `{"input":{"command":"..."}}`, check-tests-were-run uses `{"tool_uses":[...]}`. Do NOT copy the detect-loop.sh fixture format (`tool_input`) for other PostToolUse hooks. Prevents: fixtures that parse correctly by the runner but fail against the actual hook.
- **External tool fallback** — auto-ruff-format.sh and scan-secrets.sh depend on `uv`/`ruff` and `gitleaks` respectively. Scenarios MUST test the missing-tool code path. Prevents: eval failures on machines without optional tools.

## Deliverables

1. **10-12 new hook scenarios** in `eval/corpus/hook-*` for the 5 uncovered hooks
2. **3-5 new context scenarios** in `eval/corpus/context-*` (rule presence, section validation, session-start output)
3. **1 prompt artifact scenario** in `eval/corpus/skill-prompt-*` (uses existing `skill` category)
4. **2-3 new lifecycle scenarios** in `eval/corpus/lifecycle-*`
5. **1 new validator:** `eval/validators/validate-prompt.sh`
6. **Updated eval-runner.sh:** support `context` category with `checks` array execution model
7. **Updated eval/README.md:** document new categories and hook stdin contracts
8. **Total scenarios: 30+** (18 existing + 12+ new), all passing

## Exit Criteria (machine-checkable)

- [ ] `[ $(find eval/corpus -name 'scenario.json' | wc -l) -ge 30 ]`
- [ ] `bash scripts/eval-runner.sh 2>&1 | grep -qE 'Score: [0-9]+/[0-9]+ \(100%\)'`
- [ ] `bash scripts/eval-runner.sh 2>&1 | grep -qE '^\s+context\s+[0-9]+/[0-9]+'`
- [ ] `[ $(find eval/corpus/hook-* -name 'scenario.json' | wc -l) -ge 20 ]`
- [ ] `test -f eval/validators/validate-prompt.sh && bash -n eval/validators/validate-prompt.sh`
- [ ] `make test`
- [ ] `make eval 2>&1 | grep -qE 'Score.*100%'`

## Checkpoints

- After first 5 new hook scenarios pass: report coverage delta, verify eval runtime still <60s
- After check-tests-were-run.sh scenarios (Stop hook with different stdin contract): verify fixture JSON uses `tool_uses[]` array, not PostToolUse format
- After context category implemented in runner: report before adding context scenarios
- If any hook has unexpected stdin contract: STOP and verify against the hook source before writing more fixtures

## Assumptions

- `py-review-stop-prompt.md` is used as a Stop hook prompt injection (not executed). If false: investigate how it's actually consumed and adjust the eval approach.
- The `context` eval category can reuse the existing runner infrastructure with the `checks` array model defined in Approach. If false: consider whether a separate validator approach is simpler.
- `auto-ruff-format.sh` exits 0 even when `uv`/`ruff` is missing (graceful skip). If false: the eval scenario will fail and needs adjustment.
- `scan-secrets.sh` always exits 0 (warnings go to stderr, no blocking). If false: adjust expected exit codes.
