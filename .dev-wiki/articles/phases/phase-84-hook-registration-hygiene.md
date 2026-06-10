---
title: "Phase 84: Hook & Registration Hygiene"
aliases: [hook-registration-hygiene]
category: phases
tags: [hooks, registration, settings, eval-hermeticity, ghost-registrations, deregistration, heu-012]
parents: []
created: 2026-06-09
updated: 2026-06-10
source: plan
status: active
scope: ["templates/.claude/hooks/post-commit.sh", "templates/.claude/hooks/detect-loop.sh", "scripts/eval-runner.sh", "tests/**", "eval/corpus/**", "eval/hook-hygiene/**", "modules.json", "MANIFEST", "README.md"]
entry_criteria: "Phase 83 delivery accepted; spec specs/phase-84-hook-registration-hygiene.md nana:approved"
exit_criteria: "All 10 machine-checkable criteria via bash eval/hook-hygiene/run-exit-criteria.sh (make test green; make eval + explained eval-diff.md; 3 pinned Phase-82 repros exit 0; hermetic-leak test + seeded-leak self-check; kit-owned global registrations == modules.json scope:global set or documented exceptions; coverage-matrix.md with copy-currency column; timestamped backup + rehearsal.log restore-exercised; check-install-drift.sh --count 0)"
---

# Phase 84: Hook & Registration Hygiene

## Objective

Restore the two dormant lifecycle hooks (post-commit.sh, detect-loop.sh) to verified firing, close the marker-resolution and eval-sandbox environment leaks (scripts/eval-runner.sh CLAUDE_PROJECT_DIR/HOME), and bring the 11 ghost global hook registrations in ~/.claude/settings.json into agreement with modules.json scope tags — with rollback safety and no silently disarmed consuming project.

## Scope

Files and modules affected:
- `templates/.claude/hooks/post-commit.sh`, `templates/.claude/hooks/detect-loop.sh` (defects 1–3)
- `scripts/eval-runner.sh` (defect 4: CLAUDE_PROJECT_DIR/HOME hermeticity)
- `tests/` new/extended functional tests with real-event fixtures
- `eval/corpus/` scenario-expectation updates only where waking the hooks flips a documented expectation
- `eval/hook-hygiene/` exit-criteria aggregator, coverage matrix, eval-diff, rehearsal log
- `~/.claude/settings.json` ghost-registration surgery (maintainer-gated, sandbox-rehearsed)
- `modules.json` only if registration data is wrong; README/_ARCHITECTURE doc rows; MANIFEST regen

## Exit Criteria

- [ ] `make test` green (22+ scripts, including new functional tests)
- [ ] `make eval` green; `eval/hook-hygiene/eval-diff.md` explains every scenario flip
- [ ] Pinned Phase-82 post-commit repro (repro-runs.log line 48) exits 0
- [ ] Pinned detect-loop repro (line 52) exits 0
- [ ] Pinned HOME-only-marker repro (line 56) exits 0
- [ ] eval-runner CLAUDE_PROJECT_DIR neutralized + hermetic-leak test passes + seeded-leak self-check RED-verifies
- [ ] Kit-owned global registrations in ~/.claude/settings.json == modules.json scope:global set, or documented exceptions at eval/hook-hygiene/registration-exceptions.md
- [ ] eval/hook-hygiene/coverage-matrix.md: row per consuming root × 11 hooks + copy-currency column, no unaccounted cell
- [ ] Timestamped settings backup + rehearsal.log restore-exercised line
- [ ] `bash scripts/check-install-drift.sh --count` → 0

## Constraints

- Instrument-first ordering: defect 4 fixed + live-state tripwire green before any hook-fix verification through the eval harness.
- Real-event fixture provenance: ≥1 captured real event per hook defect; assertions check artifact content.
- Coverage matrix before deregistration; maintainer checkpoint unconditional (HARD gate before any live settings edit).
- Surgery safety: timestamped backup + tested restore; sandbox-rehearsed jq filter; fresh-session post-surgery verification.
- Hermetic sandboxes only (HOME + CLAUDE_PROJECT_DIR overridden); allow AND block paths asserted.
- Explained eval diff; historical supersession (never rewrite Phase-82/83 zeros); non-dev-wiki suppression verified; parser edge fixtures; single-source registration (modules.json → make template).

## Approach

Three serialized stages, instrument-first, capture-anchored ([[hook-registration-hygiene]], high):

- **Stage A (T1)** — hermetic instrument BEFORE anything else: run_hook in scripts/eval-runner.sh exports CLAUDE_PROJECT_DIR="$WORK_DIR" (the hooks' Phase-79 `cd "${CLAUDE_PROJECT_DIR:-.}"` line otherwise escapes mktemp sandboxes into the live repo); live-state tripwire; seeded-leak self-check (reverted copy must turn the leak test RED — controls-first per [[qa-verification-sweep]]); unset-variant for the `:-.` fallback; post-instrument 52-scenario baseline into eval/hook-hygiene/eval-diff.md.
- **Stage B (T2–T3)** — capture a REAL PostToolUse event with provenance BEFORE any fix (pinned Phase-82 repro events carry NO exit-code field; tool_response has only stdout/stderr). Three pre-declared evidence-forced branches per hook: remap (signal exists, fix field paths) / redesign (post-commit verifies via actual git state with failed-commit rigor; detect-loop keys on tool_response.stderr/error markers) / upstream (platform-defect filing + disable-at-boundary at the checkpoint; pinned-repro criteria N/A-upstream). Fixes: canonical jq parse (detect-loop off raw grep), legacy top-level .exit_code fallback retained (unchanged 52 denominator), marker resolution cd-project-dir → .claude/enforce → $HOME/.claude/enforce over the 4-matrix, HEU-002 fail-loud on signal-absence, parser-edge fixtures, artifact-CONTENT assertions.
- **Stage C (T4a/T4b)** — coverage matrix over all kit-marker-discovered roots (registration presence + copy-currency md5; the ghosts ARE the only wiring for 8 hooks in 3 roots), basename-normalized jq extraction, sandbox-rehearsed remediate-then-deregister with timestamped backup + tested restore, HARD maintainer checkpoint BEFORE any live settings edit, fresh-session one-command post-surgery verification; defer/partial → registration-exceptions.md.
- **T5** — run-exit-criteria.sh aggregator (10 criteria, explicit N/A-upstream pass rule for 3–5), supersession notes for the Phase-82/83 firing zeros measured on the leaky instrument (never rewrite history), README/_ARCHITECTURE rows, MANIFEST regen, drift 0.

## Direction Gate (2026-06-09)

Assumption positions: **A1 accept** (capture-first, three branches); **A2 don't-know → evidence-revised → still don't-know → DEFERRED** (must-revisit; no live settings execution rides on the direction gate; T4a hard checkpoint is the decision point with the completed matrix; remediate-then-deregister pre-signaled as default); **A3 accept** (WORK_DIR semantics + unset hedge); **A4 dissolved to verified fact** (all four Phase-82 repros confirmed reproducing at HEAD at gate time); **A5 accept** (unchanged 52 denominator, explained-diff discipline, mass unexplained flips = hard stop). all_accept: false; ledger block appended + validated (exit 0). Tasks reviewed 9/10 accept.

## Outcome (2026-06-10)

6/6 tasks [x]; 10/10 exit criteria via eval/hook-hygiene/run-exit-criteria.sh (make test 25 scripts green incl. 3 new; make eval 52/52 unchanged denominator, 2 explained flips; drift 0); reviewer 9/10 ACCEPT (4 MEDIUM: 2 fixed inline, 2 deferred-with-rationale). Branch verdicts: post-commit REDESIGN (event-arrival-as-success — PostToolUse carries no exit-code field and does not fire for failing commands), detect-loop UPSTREAM (platform defect filed; criteria 3-5 N/A-upstream). T4a checkpoint approved the full remediate-then-deregister package: 6 roots remediated, 11 ghosts deregistered, survivor smoke green, end-state == modules.json scope:global set. Live mid-phase repair: ~/.claude/hooks/session-start.d/ empty → every SessionStart errored machine-wide (5th registered-but-broken instance; install-gap Blocker filed). Full outcome: [[hook-registration-hygiene]]. **READY FOR COMPLETION — delivery gate pending acceptance** (status flips at delivery-flow D3, not here).

## Notes

Full approved spec: `specs/phase-84-hook-registration-hygiene.md` (authoritative contract). Defect evidence: `eval/qa-sweep/repro-runs.log` lines 47–61 (re-verified 2026-06-09). Gate-time registration scan: edge-analyst 11/11, edge-screener 11/11, stock-screener 3/11, ai-game 3/11 (plus a literal null command entry — T4a matrix note), fate 3/11. Stub created by /dev-plan state loader 2026-06-09; filled at plan write.
