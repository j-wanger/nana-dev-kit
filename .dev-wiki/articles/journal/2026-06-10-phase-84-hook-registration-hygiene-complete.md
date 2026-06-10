---
title: "Phase 84 complete — Hook & Registration Hygiene: post-commit redesigned on event-arrival-as-success, detect-loop filed upstream, 11 ghost registrations deregistered after 6-root remediation"
aliases: []
category: journal
tags: [hooks, registration, eval-hermeticity, ghost-registrations, deregistration, platform-defect, session-start, heu-012]
parents: [phase-84-hook-registration-hygiene]
created: 2026-06-10
updated: 2026-06-10
source: debrief
duration: ~3.5 hours (planning + implementation, one session 2026-06-09 evening → 2026-06-10)
---

# Phase 84 complete — Hook & Registration Hygiene

## What Happened
- Three serialized stages, instrument-first, capture-anchored. **T1** made the eval harness hermetic (run_hook exports CLAUDE_PROJECT_DIR="$WORK_DIR"; seeded-leak self-check turned the leak test RED on the reverted copy — controls-first held) and recorded the post-instrument 52-scenario baseline: ZERO flips, so the Phase-82/83 leak was not load-bearing for any prior verdict (supersession noted, never rewritten).
- **T2** live-probed real PostToolUse events: NO exit-code field anywhere (tool_response keys: interrupted/isImage/noOutputExpected/stderr/stdout) AND no event delivery at all for failing commands — event arrival IS the success signal. Foreign-session events arrived via the ghost registration (fires machine-wide, incl. non-kit signal-watch) — live proof the ghost cleanup mattered.
- **T3** branch verdicts: post-commit **REDESIGN** (event-arrival-as-success + legacy .exit_code failure guard + loose *git*commit* prefilter + git-recency ≤120s confirmation + project-local OR HOME marker + HEU-002 fail-loud); detect-loop **UPSTREAM** (consecutive-failure counter structurally unimplementable hook-side; hook untouched, platform defect filed, prune-on-value candidate).
- **T4a/T4b** the HARD checkpoint: maintainer approved the FULL remediate-then-deregister package. 6 roots remediated (hooks + session-start.d synced, 11/11 project-local registration, ai-game null entry dropped), 11 ghosts deregistered (removed=11, no empty arrays, context-size-check intact, non-hook keys byte-identical), survivor smoke green (allow AND block), end-state == modules.json scope:global set. Backup + tested restore retained; fresh-session verification handed to maintainer (rehearsal.log).
- **T5** close-out: run-exit-criteria.sh 10/10 (criteria 3-5 N/A-upstream); make test 22→25 scripts; make eval 52/52; drift 0.

## Decisions Made
- [[hook-registration-hygiene]] -- outcome appended this debrief (confidence stays high)

## Problems Solved
- Zsh checker instrument-death ×2 -- unquoted $VAR lists don't word-split in zsh: the registration scan produced a false 0/11-everywhere matrix and a cross-ref self-check produced a false MISSING; both caught by the now-mandatory positive control (a known non-zero cell) before any matrix output counted as evidence.
- Eval lifecycle init_git gap -- two scenarios (hook-post-commit-detected, lifecycle-full-phase-cycle) had passed ONLY via the hook's false-fire (hash "unknown" in repos with no commit); given setup.init_git:true and the eval-runner lifecycle branch extended to honor it (DEPENDENCY deviation — hook-branch semantics duplicated).
- Legacy-test fixture circularity made honest -- hand-written fixtures that passed while the hooks were dormant replaced/anchored by byte-for-byte real-event captures with provenance sidecars (tests/fixtures/real-events/).
- session-start.d live breakage (user-reported mid-phase) -- ~/.claude/hooks/session-start.d/ was EMPTY while the Phase-82-refreshed session-start.sh hard-sources 3 modules under set -e: EVERY SessionStart errored machine-wide since 2026-06-09. 5th registered+present+current-but-BROKEN instance. Repaired live (modules copied from templates, both sources verified exit 0); same gap fixed in stock-screener + fate; root cause (modules.json declares session-start.d only under project_local.extra_dirs; install.sh + drift checker blind) filed as the install-gap Blocker.
- Python Stop hooks misfiring in the kit repo -- the kit's new self-consumed project-local settings carried the full 17-hook Python-harness set; check-tests-were-run.sh + py-review-stop.sh misfired at Stop in this bash/markdown repo → trimmed from the kit repo's settings only (rehearsal.log, reversible).

## Escape Hatches
- DEPENDENCY: eval-runner lifecycle init_git extension (required by the scenario fix).
- DISCOVERY ×2: Makefile test wiring for the 3 new scripts; .gitignore entries for the kit repo's installed state (.claude/settings.json + .claude/hooks/).
- USER-REPORTED live repair: session-start.d global restore (restoring files the kit ships; verified; logged in the coverage-matrix addendum).

## Open Questions
- Already filed in Blockers by T5 (not duplicated here): Phase-84 platform defect (PostToolUse failure signal); Phase-84 install-gap (extra_dirs not shipped globally, drift checker blind); detect-loop prune candidate; A5 memory-layer must-revisit (prior).

## Artifacts Changed
- `scripts/eval-runner.sh` (hermetic: CLAUDE_PROJECT_DIR=$WORK_DIR in run_hook; lifecycle init_git support)
- `templates/.claude/hooks/post-commit.sh` (redesigned: event-arrival-as-success)
- `tests/test_eval_hermeticity.sh`, `tests/test_fixture_provenance.sh`, `tests/test_lifecycle_hooks_firing.sh` (NEW, Makefile-wired; 23rd-25th make-test scripts)
- `tests/fixtures/real-events/` (NEW: byte-for-byte captures + provenance sidecars)
- `eval/hook-hygiene/` (NEW: eval-diff.md, capture-diagnosis.md, coverage-matrix.md, check-matrix.sh, rehearsal.log, run-exit-criteria.sh)
- `eval/corpus/hook-post-commit-detected/scenario.json`, `eval/corpus/lifecycle-full-phase-cycle/scenario.json` (init_git:true)
- `tests/test_tooluse_hooks.sh` (real-shape updates); machine-wide: ~/.claude/settings.json 11 ghosts removed, 6 roots remediated + self-registered

### Health Delta
- +3 test scripts / +25 tests (4+5+16); make test 25 scripts green; make eval 52/52 maintained (2 explained flips, resolved); drift 0; SessionStart machine-wide error → fixed; 2 Python Stop hooks trimmed from kit repo settings.

### Review Gate
- 9/10 ACCEPT. 4 MEDIUM: 2 fixed inline (missing 4-matrix cell added — 16/16 firing tests; dead RC removed); 2 deferred-with-rationale (post-commit 120s-window header note + detect-loop cannot-fire header note would re-stale 8 just-synced installed copies for comment-only changes; the facts live in capture-diagnosis.md + Blockers). 3 suggestions incl. the decision-article outcome append — done this debrief.

### Gate Compliance
- tasks.md gate-log line present: `direction=approved delivery=pending` — compliant. The direction gate was the assumption gate (ledger block appended 2026-06-09, all_accept:false; A2 a deferred don't-know resolved at its declared T4a decision point). Delivery gate flips post-commit (D3).

### Activation Quality
- active-knowledge.md: 3 source sections, 3 load-bearing this session — hit rate 3/3 (100%). Defect diagnosis lines drove T2/T3 (exit-code absence, marker paths); registration surface + A2 deferral drove T4a/T4b (mixed-form normalization, checkpoint default); execution discipline (zsh hazard + flip surface) used at T1/T3/T4a (positive controls, explained flips).

### Retro Check
- Not triggered (74 completed phases; 84's acceptance would make 75 — retro defers to post-acceptance).

## Related
- [[phase-84-hook-registration-hygiene|Phase 84: Hook & Registration Hygiene]] -- parent phase

## Soft Observations / Phase N+1 Candidates
- modules.json has no language tag on project-scoped hooks → --project-local registration is Python-harness-shaped everywhere; non-Python roots (ai-game? fate?) may want the same Stop-hook trim | language-conditional registration field | evidence: rehearsal.log post-T4b trim
- Single-file md5 currency misses directory-level absence (extra_dirs) → drift checker + any future coverage matrix needs directory cells | install-gap fix phase | evidence: the session-start.d breakage (coverage-matrix addendum)
- Globally-registered hooks capture/fire across ALL concurrent sessions incl. foreign projects — a hazard (capture privacy, noise) AND the reason ghost cleanup mattered | registration-scope hygiene doctrine | evidence: T2 foreign-session captures
- detect-loop.sh shipped + registered in 7 locations but structurally cannot fire (upstream) | prune-on-value round 2 alongside the A5 memory-layer question | evidence: capture-diagnosis.md
- The zsh word-splitting/positive-control hazard bit TWICE at the gate (false 0/11 scan; false MISSING cross-ref) — already seeded to working-knowledge | n/a (seeded) | evidence: [[hook-registration-hygiene]] gate notes
- Provenance hazard re-confirmed live: piping SessionStart events into the live hook with CWD=repo ran the wk-prune curator against the repo's working-knowledge.md (benign, idempotent) | enforcement.log/run-provenance separation (Phase-82 filing's class) | evidence: Phase-82 misc Blocker

## Post-debrief addendum (same session): exec-bit incident

User-visible PostToolUse/Stop hook errors traced to exit-126 Permission denied: T4b's fresh hook
copies inherited non-executable modes (Write-tool rewrite of post-commit.sh = 644; 10 template
hooks latently tracked 100644 in git all along, masked by bash-prefix ghosts + cp preserving
existing-destination modes). Fixed everywhere (templates chmod'd → commit records 100755; 6 roots +
~/.claude re-chmod'd), verified by platform-faithful direct-exec firing, guarded permanently in
test_templates.sh (exec-bit contract test, 179th). Lesson stacked on the session-start.d finding:
copy-currency needs md5 AND mode AND directory cells. The firing tests' `bash <path>` invocation
was mode-blind — platform-faithful invocation (direct exec) belongs in functional smokes.
