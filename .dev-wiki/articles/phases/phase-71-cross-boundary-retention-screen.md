---
title: "Phase 71: Cross-Boundary Retention Headroom Screen"
aliases: [phase-71-cross-boundary-retention-screen, retention-headroom-screen]
category: phases
tags: [amplifier-vision, measurement, retention, compaction, process-retention, headroom]
parents: [phase-70-anchor-headroom-screen]
created: 2026-05-30
updated: 2026-05-30
source: plan
status: completed
scope: ["eval/amplifier/retention-screen/**", ".dev-wiki/articles/decisions/cross-boundary-retention-headroom-screen.md"]
entry_criteria: "Phase 70 named long-horizon/multi-turn process-retention as a surviving avenue (decidable-when: a multi-turn substrate exists); Jake selected it via AskUserQuestion 2026-05-30; spec nana:approved."
exit_criteria: "A pre-registered differential screen runs over controls + ≥2 candidates and yields a single anchored PROGRAM-VERDICT on the graded ladder; frozen machinery git-diff-empty; make eval 52/52, make test 19 scripts unchanged."
---

# Phase 71: Cross-Boundary Retention Headroom Screen

> **READY FOR COMPLETION (delivery gate pending, 2026-05-30).** All 6 tasks [x]; exit criteria met. **PROGRAM-VERDICT: TERMINATE-by-summary-robustness** — controls validated the instrument (neg→DEGENERATE, pos→HAS-HEADROOM [ON pathway LIVE], middle→STABLE); then no candidate reached a lossy boundary because Claude Code's native model-authored compaction summary RETAINS explicit project decisions and bare opus HONORS them 5/5 in OFF. Committed `896e096` (pre-registration, BEFORE runs) + `d7067e6` (verdicts). make eval 52/52, make test unchanged at 19 scripts, frozen cross-compaction machinery git-diff-empty. See [[cross-boundary-retention-headroom-screen]] (Result section) + the full record at `eval/amplifier/retention-screen/screen-record.md`.

## Objective

Decide — as the cheapest go/no-go — whether the harness's cross-compaction state machinery has any retention headroom: across a context-loss (compaction) boundary, does the harness state RECOVER an earlier-established counter-default project decision that a bare agent (residual context only) DROPS? The multi-turn analog of the Phase-70 anchor screen.

## Scope

Files and modules affected:
- `eval/amplifier/retention-screen/*` (NEW repo-only tree; cloned from `anchor-screen/`; NOT wired into install.sh/Makefile/make test/make eval)
- `.dev-wiki/articles/decisions/cross-boundary-retention-headroom-screen.md`

FROZEN (the SUBJECT of measurement — must be git-diff-empty at T6): `templates/.claude/hooks/{pre-compact,post-compact,session-start}.sh` + `session-start.d/*`, the recovery protocol in `.claude/rules/dev-wiki-hooks.md`, the memory bridge, the always-loaded rule files; plus `emit-proxy-vector.sh`, `measurability-gate.sh`, `anchor-screen/`, code under `eval/comparison|corpus|reasoning`.

## Exit Criteria

- [x] `check.sh --selftest` / `--verify-pins` / `leak-check.sh` / `assert-off-on-isolation.sh` exit 0
- [x] `git merge-base --is-ancestor 896e096 d7067e6` exits 0 (pre-registration precedes verdicts)
- [x] `grep -c '^PROGRAM-VERDICT:' screen-record.md` returns exactly 1; the no-harness-value disclaimer string is present
- [x] Bare-derivation gate result + motivated|arbitrary classification recorded per candidate; 3 controls present (negative→DEGENERATE, positive→HAS-HEADROOM, middle→STABLE); 3 candidates screened
- [x] `check.sh --stability <middle-b1> <middle-b2>` prints `STABLE`; 10 middle-control run files exist
- [x] Engineered-favorable backstop screened (summary-robust — no lossy boundary reached)
- [x] No candidate reached a lossy boundary → `TERMINATE-by-summary-robustness` recorded
- [x] `make eval` 52/52; `make test` runs the UNCHANGED 19 scripts; frozen set `git diff`-empty

## Constraints

- **OFF/ON isolation confound** (the A-vs-C scar): ON MUST equal OFF byte-for-byte plus one appended `[HARNESS STATE]` block — prevents the differential measuring the wrong variable.
- **Residual leak of the target decision**: `leak-check.sh` fails if the OFF summary/turns restate the decision — prevents an artifact OFF-pass; per-run leak → VOID, never PASS.
- **Lobotomized / starved summary**: OFF is a MODEL-AUTHORED summary (real mechanism), not hand-truncation — prevents ON looking valuable for a non-reproducing reason; a synthetic-boundary HAS-HEADROOM earns at most PARKED.
- **False victory by rediscovering unknowables**: the pinned motivated-vs-arbitrary rationale-probe litmus gates CONTINUE — prevents re-declaring the Phase-70 unknown-facts result in multi-turn clothing.
- **Retrofitted verdict**: `pre-registration.md` committed in a SEPARATE ancestor commit; predicates are pre-named ERE tokens, no similarity threshold.
- **No-LLM scoring**: the model is confined to one-time frozen summary authoring; the scoring path stays bash-only.

## Checkpoints

- **T2 (pre-register):** apparatus + transcripts + summaries + OFF/ON + bare-gate results committed SEPARATELY before any verdict run.
- **T3 (controls — load-bearing):** if positive≠HAS-HEADROOM (esp. INERT), negative≠DEGENERATE, or middle false-positives → STOP, instrument-broken / inert-machinery; report before any candidate run.
- **T5:** if a MOTIVATED candidate is HAS-HEADROOM → STOP and surface the CONTINUE recommendation (do NOT auto-authorize a rig).

## Assumptions

- The Phase-70 `check.sh` single-run semantics port without change. If false: keep `run_check` verbatim, build only `diff_verdict` fresh.
- A model-authored summary of a staged transcript can naturally DROP a counter-default decision. If false: items screen DEGENERATE-by-summary-robustness (an honest finding the native summary retains decisions).
- The model treats an in-context `[HARNESS STATE]` block as authoritative when it is the sole source (the positive control tests this). If false: STOP and report the inert-machinery finding — that IS the phase result.

## Notes

- Honest expectation: likely TERMINATE (the native 11,470-char summary may re-derive dropped decisions), but a real shot at the FIRST positive harness-value signal in the program if a motivated decision is recovered.
- Discovered latent finding (recorded, NOT fixed — fixing it would violate freeze-the-subject): `post-compact.sh` READS `.claude/.session-anchor` but nothing in the repo WRITES it (a dead recovery branch). Handed to a future phase.
- See [[cross-boundary-retention-headroom-screen]] (decision) and [[amplifier-anchor-headroom-screen]] (the Phase-70 parent screen this extends).
