# Spec: Eval Harness

## Objective

Build a benchmark corpus and reproducible eval runner that validates nana-dev-kit's hooks, skill contracts, and lifecycle compliance against realistic fixture scenarios — producing quantitative scores that track harness quality over time.

## Context

nana-dev-kit has 128 structural/integration tests (933 lines of bash) that verify files exist, contain expected strings, and pass syntax checks. These prove the harness is correctly assembled but do NOT prove it works correctly in realistic scenarios. Specifically: hooks are tested with minimal JSON stubs (test_enforce.sh, test_harden.sh), but never against the full range of inputs a real Claude Code session produces. Skill outputs (specs, plans, decision articles) are never validated against their own template contracts. There's no way to detect quality regressions when hooks or skills change — only structural regressions. Gap 4.2 from the roadmap.

## Scope

### In scope
- Benchmark corpus: 16-25 fixture scenarios with per-category minimums (at least 8 hook, 5 skill, 3 lifecycle)
- Eval runner script (`scripts/eval-runner.sh`) that processes the corpus and produces scored results
- Hook contract schemas (JSON) pinned in the corpus for drift detection
- Skill artifact validators: check real/synthetic skill outputs against template contracts (all 9 spec sections, phase article required fields, decision article format)
- Scoring report: per-category pass rates, overall harness score, diffable text output for trend tracking
- `make eval` target, separate from `make test`
- Full HOME/tmpdir isolation for every scenario

### Out of scope
- Live Claude API calls — all scenarios use captured/synthetic fixtures, no LLM invocation
- A/B comparison (with/without harness on same task)
- Performance benchmarking (latency, token count)
- CI integration (that's a follow-up; `make eval` is manual for now)
- Changes to existing tests in `tests/` — eval supplements, doesn't replace
- Modifying hooks or skills to accommodate eval — eval tests the harness as-is
- Visual dashboard or web UI — text report is sufficient

## Approach

**Corpus structure:** `eval/corpus/` with one directory per scenario. Each scenario has a `scenario.json` manifest declaring: category (`hook` | `skill` | `lifecycle`), fixture requirements (files to stage), input (JSON stdin or project state), expected outputs (exit codes, file contents, structural checks), scoring mode (`binary` for pass/fail or `ternary` with an explicit `partial_condition` field), and a human-readable description. The runner iterates scenarios, sets up isolated fixtures, runs the test, scores the result.

**Three evaluation categories:**

1. **Hook fidelity** (at least 8 scenarios): Feed realistic JSON inputs to each hook (enforce-spec, enforce-loop, detect-loop, session-start, pre-compact). Validate exit codes, stdout/stderr content, side effects (files created/modified). Covers: valid/invalid spec states, mid-phase vs between-phases, loop detection with realistic command sequences, session-start with populated vs empty dev-wiki. Hook input JSON shapes are derived from the hook scripts themselves (`templates/.claude/hooks/*.sh` — each parses specific fields from stdin).

2. **Skill contract compliance** (at least 5 scenarios): Validate that skill output artifacts conform to their template contracts. E.g., a spec file must have all 9 H2 headers, exit criteria with backtick commands, constraints with guard mechanisms. A phase article must have required frontmatter fields. A decision article must follow the decision-template.md format. Uses hand-crafted synthetic exemplars — no real project data, API keys, or user-identifying information (project names, paths, and content are fictional).

3. **Lifecycle compliance** (at least 3 scenarios): Given a fixture project state (dev-wiki with phases, tasks, specs), validate that the hook chain produces correct enforcement behavior end-to-end. E.g., enforce-spec blocks implementation without an approved spec; enforce-loop blocks stop without deliverables; session-start reports correct enforcement status.

**Scoring:** Each scenario manifest declares `"scoring": "binary"` (pass=1.0, fail=0.0) or `"scoring": "ternary"` with a `"partial_condition"` field that specifies the exact check for partial credit (0.5). Ternary is used only for advisory hooks (detect-loop, session-start) where the hook emits useful output but doesn't block. Category scores are averages. Overall score is weighted average (hooks 40%, skills 35%, lifecycle 25%). Report includes per-scenario detail and summary.

**Hook contract schemas:** Pin the expected JSON shapes for PreToolUse, PostToolUse, Stop, and SessionStart hook inputs as `eval/schemas/*.json`, derived from the actual field-access patterns in `templates/.claude/hooks/*.sh`. The eval runner validates that fixture inputs conform to these schemas before running scenarios — if schemas are stale, eval exits non-zero with "schema drift detected" error, producing no scores.

## Constraints (CRITICAL)

- Every eval scenario runs in a fresh tmpdir with isolated HOME (`HOME=$(mktemp -d)`): prevents eval from corrupting the developer's actual `~/.claude/` or the nana-dev-kit repo state. Cleanup via `trap cleanup EXIT`.
- Eval runner is pure bash (no Python dependency): consistent with existing test infrastructure (`tests/helpers.sh`). Reuses assertion helpers where applicable.
- `make eval` is a separate target, never called by `make test`: eval may be slower and has different failure semantics (scores vs pass/fail). Running `make test` must still complete in <30s.
- Scenario manifests are JSON, not embedded in bash: enables future tooling (corpus analysis, scenario generation) without parsing bash. `jq` is the only new dependency — already commonly available and used in hooks.
- Hook contract schemas must be validated BEFORE scoring scenarios: if a schema doesn't match the real hook input format, the eval exits non-zero with "schema drift detected" and produces no scores — not partial/misleading results.
- Synthetic skill exemplars must NOT contain real project data, API keys, or user-identifying information: corpus is committed to the repo and may be public. Use fictional project names, paths, and content.

## Deliverables

1. `eval/corpus/` — 16-25 scenario directories, each with `scenario.json` manifest and fixture files
2. `eval/schemas/` — JSON schema files for hook input contracts (PreToolUse, PostToolUse, Stop, SessionStart)
3. `eval/validators/` — bash validation scripts for skill artifact contracts (spec, phase-article, decision-article)
4. `scripts/eval-runner.sh` — corpus runner with scoring, isolation, and reporting
5. `eval/README.md` — corpus structure documentation, how to add scenarios, scoring methodology
6. Updated `Makefile` — `eval` target

## Exit Criteria (machine-checkable)

- [ ] `test -d eval/corpus && [ $(find eval/corpus -name 'scenario.json' | wc -l) -ge 16 ]`
- [ ] `test -d eval/schemas && [ $(ls eval/schemas/*.json 2>/dev/null | wc -l) -ge 3 ]`
- [ ] `test -f scripts/eval-runner.sh && bash -n scripts/eval-runner.sh`
- [ ] `test -f eval/README.md`
- [ ] `grep -q '^eval[[:space:]]*:' Makefile`
- [ ] `make eval && make eval 2>&1 | grep -qE 'Score: [0-9]'`
- [ ] `make test`

## Checkpoints

- After corpus structure and first 3 hook scenarios are implemented: report runner output and scoring format
- After all hook scenarios complete: report hook fidelity category score
- After skill validators and lifecycle scenarios complete: report full eval scores before final commit

## Assumptions

- `jq` is available on the eval machine for JSON manifest parsing. If false: fall back to Python JSON parsing (available via memory_server venv) or grep-based extraction with degraded validation.
- Hook JSON input shapes match the fields actually parsed by `templates/.claude/hooks/*.sh` (e.g., enforce-spec reads `tool_name` and `input.file_path`; detect-loop reads `tool_name`, `tool_input.command`, `exit_code`). If false: update schemas to match reality and document the discrepancy.
- Synthetic skill exemplars can be constructed by hand without running Claude. If false: reduce skill contract scenarios to template-structure-only checks (verify headers exist, not content quality).
- Eval runner completes in under 60 seconds for the full corpus. If false: add a `--quick` flag that runs only hook scenarios (fastest category).
