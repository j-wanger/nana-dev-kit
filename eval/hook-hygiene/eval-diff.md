# Phase 84 — Eval Diff (instrument-first baseline + post-fix flips)

## Baseline

Post-instrument-fix run (eval-runner CLAUDE_PROJECT_DIR neutralization in place, BEFORE any hook
change), 2026-06-09. Command: `make eval`. Result: **52/52 (100%)** — the harness fix itself
flipped no scenario (the sandbox leak was not load-bearing for any green verdict).

| scenario | result |
|---|---|
| context-cognitive-readiness-empty | PASS |
| context-cognitive-readiness-populated | PASS |
| context-file-lifecycle-sections | PASS |
| context-rules-installed | PASS |
| context-session-start-guidance | PASS |
| context-soul-sections | PASS |
| hook-audit-log-no-file | PASS |
| hook-audit-log-write | PASS |
| hook-auto-ruff-non-python | PASS |
| hook-auto-ruff-py-file | PASS |
| hook-block-force-push | PASS |
| hook-block-no-verify | PASS |
| hook-block-reset-hard | PASS |
| hook-block-rm-rf | PASS |
| hook-block-safe-command | PASS |
| hook-check-tests-no-py | PASS |
| hook-check-tests-py-no-pytest | PASS |
| hook-context-size-jq | PASS |
| hook-detect-loop-2-no-warn | PASS |
| hook-detect-loop-3-failures | PASS |
| hook-enforce-loop-fail | PASS |
| hook-enforce-loop-pass | PASS |
| hook-enforce-memory-allow | PASS |
| hook-enforce-memory-block | PASS |
| hook-enforce-memory-inactive | PASS |
| hook-enforce-spec-allow-gate | PASS |
| hook-enforce-spec-allow-valid-spec | PASS |
| hook-enforce-spec-block-no-spec | PASS |
| hook-enforce-spec-no-marker | PASS |
| hook-post-commit-amend-skip | PASS |
| hook-post-commit-detected | PASS |
| hook-post-commit-non-commit | PASS |
| hook-pre-compact-active-phase | PASS |
| hook-scan-secrets-clean | PASS |
| hook-scan-secrets-pattern | PASS |
| hook-session-start-memory-broken | PASS |
| hook-session-start-memory-healthy | PASS |
| hook-session-start-populated | PASS |
| hook-session-start-recovery-detected | PASS |
| hook-session-start-recovery-suppressed | PASS |
| lifecycle-dangerous-command-flow | PASS |
| lifecycle-deliverable-enforcement | PASS |
| lifecycle-full-phase-cycle | PASS |
| lifecycle-full-session-flow | PASS |
| lifecycle-session-enforcement-status | PASS |
| lifecycle-spec-enforcement-flow | PASS |
| skill-decision-valid | PASS |
| skill-phase-invalid | PASS |
| skill-phase-valid | PASS |
| skill-prompt-valid | PASS |
| skill-spec-invalid | PASS |
| skill-spec-valid | PASS |

Category totals: hook 34/34, skill 6/6, lifecycle 6/6, context 6/6.

## Post-fix diff

Post-T3 run (post-commit.sh redesigned; detect-loop.sh untouched per the upstream branch),
2026-06-10. Final: **52/52 (100%)** — denominator unchanged.

Flips vs baseline and their resolutions (each verified by re-run):

| scenario | flip | cause | resolution |
|---|---|---|---|
| hook-post-commit-detected | PASS→FAIL→PASS | scenario piped a "successful commit" event into a workdir with NO git repo; the old hook false-fired with hash "unknown", the redesigned hook's git-state confirmation correctly rejects a commit that never happened | `setup.init_git: true` added — the fixture now holds a real commit (honest fixture, same contract) |
| lifecycle-full-phase-cycle | PASS→FAIL→PASS | same false-fire dependency in its post-commit step; additionally the runner's lifecycle branch ignored `setup.init_git` (only the hook branch processed it) | `setup.init_git: true` added + eval-runner lifecycle branch now honors init_git with identical semantics (DEPENDENCY deviation: small runner extension required by the scenario fix; hermeticity suite re-run green) |

detect-loop scenarios (hook-detect-loop-3-failures, hook-detect-loop-2-no-warn): no flip — the
hook is untouched (upstream branch) and its legacy-shape path is non-regression-tested in
tests/test_lifecycle_hooks_firing.sh.

Pinned Phase-82 repro status: line 48 (real-shape dormancy) PASS; line 56 (project-local
marker) PASS; line 52 (detect-loop dormancy) **N/A-upstream** — no failure signal exists on the
platform (no exit-code field in the event; no PostToolUse delivery for failing commands; see
capture-diagnosis.md). One legacy test fixture made honest (test_tooluse_hooks.sh: the
"successful commit" sandbox now holds a real commit instead of relying on the hash-"unknown"
false fire).
