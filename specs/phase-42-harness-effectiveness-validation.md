<!-- nana:approved 2026-05-25 -->
# Spec: Phase 42 — Harness Effectiveness Validation

## Objective

Design and run a controlled clean-room comparison measuring whether nana-dev-kit improves development outcomes, producing a repeatable evaluation methodology and quantified results.

## Context

nana-dev-kit has been built over 41 phases with ~303 tests and 50 eval scenarios validating individual components (hooks, skills, artifacts). However, there has been no end-to-end validation that the harness as a whole improves development outcomes. The existing eval proves components work correctly; this phase proves (or disproves) that they compose into measurable value. The user chose clean-room comparison: same task(s) run with and without the harness on fresh repos, comparing objective metrics.

## Scope

### In scope
- Evaluation methodology document defining tasks, metrics, controls, and scoring rubric
- 2 standardized Python task definitions (one multi-session, one short-scoped)
- Metric collection scripts (parse git log, count files, measure test coverage, time tracking)
- Starter repos for both conditions (harness-installed vs Claude Code defaults)
- Execution guide (step-by-step protocol for running both conditions)
- Results template for recording and comparing outcomes
- Hook invocation wrapper that instruments existing harness hooks with timing and exit-code logging

### Out of scope
- Running the actual comparison trials (user runs these manually after the phase delivers tooling)
- Statistical analysis frameworks (N=2 tasks, not a stats problem)
- Automated Claude Code session orchestration (no programmatic session control exists)
- Multiple repo archetypes (greenfield only for v1; existing-codebase variant is a future extension)
- Changes to the harness itself based on findings (separate phase)

## Approach

Build the evaluation infrastructure as executable scripts and structured documents. Two task archetypes test different harness value propositions: (1) a multi-step Python feature build that exercises lifecycle management (spec, plan, implement, test, debrief), and (2) a short Python bug-fix task where harness overhead could plausibly hurt. Both run on fresh repos with identical starting conditions. The baseline is explicitly "Claude Code with default configuration, no nana-dev-kit" — not "no help." Metrics prioritize output quality (code correctness, test coverage, automated code review score) over activity measures (time, commits, files touched). The harness condition instruments every hook with a timing wrapper that logs invocation, exit code, and duration as JSONL — surfacing enforcement friction so overhead is visible, not hidden in timing data.

## Constraints (CRITICAL)

- Baseline condition must have zero harness artifacts: no `.claude/rules/` from nana-dev-kit, no memory entries, no AGENTS.md harness content, no hooks, no skills — prevents operator-knowledge contamination of the "without" condition
- Primary quality metric: automated code review via `/code-review` skill run against both conditions' output repos, reviewer unaware of which condition produced the code. Scale: the skill's existing finding-count and severity output. Secondary: test pass rate, linter score (ruff/mypy). Activity metrics (time, commits) are tertiary — prevents measuring ceremony as value
- Task definitions must be written BEFORE any trial runs and not modified after. Enforcement: `setup-harness.sh` and `setup-baseline.sh` record SHA256 of task files at setup time; `collect-metrics.sh` verifies hashes unchanged — prevents post-hoc task tuning to favor one condition
- Both tasks are Python (the harness has py-lint, py-review, py-test, py-init skills) — prevents measuring harness in a language where its skills don't apply
- At least one task must be short enough that harness overhead could plausibly hurt (< 30 minutes expected completion) — prevents selection bias toward harness strengths
- At least one task must force context pressure (enough work to approach compaction boundary) — harness benefits like pre-compact hooks only activate across session boundaries
- Hook instrumentation: a wrapper script replaces each harness hook command in settings.json, delegating to the real hook while logging {hook_name, timestamp, exit_code, duration_ms} as JSONL to `.claude/hook-invocations.jsonl` — prevents invisible friction; enables distinguishing "harness overhead" from "harness obstruction"
- Both conditions must run on the same Claude Code version and model on the same day — prevents model drift confound
- Results must be recorded in a structured format reviewable by someone unfamiliar with the project — prevents methodology opacity

## Deliverables

1. `eval/comparison/methodology.md` — evaluation design document with required sections: ## Tasks, ## Metrics, ## Controls, ## Scoring Rubric, ## Limitations
2. `eval/comparison/tasks/feature-build.md` — multi-step Python feature build task definition (CLI tool with tests)
3. `eval/comparison/tasks/bug-fix.md` — short Python bug-fix task definition (< 30 min expected)
4. `eval/comparison/scripts/collect-metrics.sh` — post-trial metric collection from git history + file analysis + task-hash verification
5. `eval/comparison/scripts/hook-wrapper.sh` — wrapper script that instruments a harness hook with JSONL timing/exit-code logging
6. `eval/comparison/scripts/setup-baseline.sh` — creates clean baseline repo (Claude Code defaults only, verifiable: no .claude/rules/, no hooks, no skills)
7. `eval/comparison/scripts/setup-harness.sh` — creates harness-installed repo with hook instrumentation wired in
8. `eval/comparison/results-template.md` — structured template for recording trial outcomes
9. `eval/comparison/run-guide.md` — step-by-step execution protocol for running both conditions

## Exit Criteria (machine-checkable)

- [ ] `test -f eval/comparison/methodology.md && grep -q '## Metrics' eval/comparison/methodology.md && grep -q '## Controls' eval/comparison/methodology.md && grep -q '## Scoring' eval/comparison/methodology.md && [ $(wc -l < eval/comparison/methodology.md) -ge 50 ]`
- [ ] `test -f eval/comparison/tasks/feature-build.md && grep -qi 'python\|cli\|pytest' eval/comparison/tasks/feature-build.md && test -f eval/comparison/tasks/bug-fix.md && grep -qi 'bug\|fix' eval/comparison/tasks/bug-fix.md`
- [ ] `bash -n eval/comparison/scripts/collect-metrics.sh && grep -q 'sha256\|checksum' eval/comparison/scripts/collect-metrics.sh`
- [ ] `bash -n eval/comparison/scripts/hook-wrapper.sh && grep -q 'hook-invocations' eval/comparison/scripts/hook-wrapper.sh`
- [ ] `T=$(mktemp -d) && bash eval/comparison/scripts/setup-baseline.sh "$T/baseline" eval/comparison/starters/feature-build && test -d "$T/baseline/.git" && ! test -d "$T/baseline/.claude/rules" && ! test -d "$T/baseline/.claude/hooks" && rm -rf "$T"`
- [ ] `T=$(mktemp -d) && bash eval/comparison/scripts/setup-context.sh "$T/context" eval/comparison/starters/feature-build && test -d "$T/context/.git" && test -f "$T/context/.claude/rules/nana-soul.md" && ! test -d "$T/context/.claude/hooks" && rm -rf "$T"`
- [ ] `T=$(mktemp -d) && bash eval/comparison/scripts/setup-harness.sh "$T/harness" eval/comparison/starters/feature-build && test -d "$T/harness/.git" && test -d "$T/harness/.claude/rules" && rm -rf "$T"`
- [ ] `test -f eval/comparison/results-template.md && grep -q '## Quality Metrics' eval/comparison/results-template.md && test -f eval/comparison/run-guide.md`
- [ ] `make test && make eval 2>&1 | grep -qE 'Score.*100'`

## Checkpoints

- After methodology + task definitions (deliverables 1-3): review tasks and metrics coherence before building scripts
- After setup scripts (deliverables 6-7): verify both repos scaffold correctly in temp dirs before writing the rest
- After all deliverables: full `make test && make eval` to confirm no regressions

## Assumptions

- Claude Code sessions produce enough observable artifacts (git history, file state, terminal output) to measure outcomes post-hoc. If false: add an in-session logging mechanism (e.g., timestamped transcript capture).
- A single greenfield Python task pair (one multi-step, one short) provides sufficient signal to evaluate harness value. If false: extend with an existing-codebase task variant in a follow-up phase.
- The user will run both conditions manually on the same day. If false: document model version and Claude Code version as control variables for later comparison.
- The `/code-review` skill can be run against an arbitrary repo's diff to produce a comparable score. If false: use automated quality proxies (test pass rate, ruff finding count, mypy error count) as the primary quality metric instead.
- Hook wrapper can instrument existing hooks by replacing the command in settings.json with `hook-wrapper.sh <original-command>`. If false: use a simpler approach of adding a single PostToolUse hook that logs its own context without wrapping others.
