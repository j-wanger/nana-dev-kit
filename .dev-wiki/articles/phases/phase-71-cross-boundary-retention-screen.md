---
title: "Phase 71: Cross-Boundary Retention Headroom Screen"
aliases: [phase-71-cross-boundary-retention-screen, retention-headroom-screen]
category: phases
tags: [amplifier-vision, measurement, retention, compaction, process-retention, headroom]
parents: [phase-70-anchor-headroom-screen]
created: 2026-05-30
updated: 2026-05-30
source: plan
status: active
scope: ["eval/amplifier/retention-screen/**", ".dev-wiki/articles/decisions/cross-boundary-retention-headroom-screen.md"]
entry_criteria: "Phase 70 named long-horizon/multi-turn process-retention as a surviving avenue (decidable-when: a multi-turn substrate exists); Jake selected it via AskUserQuestion 2026-05-30; spec nana:approved."
exit_criteria: "A pre-registered differential screen runs over controls + ≥2 candidates and yields a single anchored PROGRAM-VERDICT on the graded ladder; frozen machinery git-diff-empty; make eval 52/52, make test 19 scripts unchanged."
---

# Phase 71: Cross-Boundary Retention Headroom Screen

## Objective

Decide — as the cheapest go/no-go — whether the harness's cross-compaction state machinery has any retention headroom: across a context-loss (compaction) boundary, does the harness state RECOVER an earlier-established counter-default project decision that a bare agent (residual context only) DROPS? The multi-turn analog of the Phase-70 anchor screen.

## Scope

Files and modules affected:
- `eval/amplifier/retention-screen/*` (NEW repo-only tree; cloned from `anchor-screen/`; NOT wired into install.sh/Makefile/make test/make eval)
- `.dev-wiki/articles/decisions/cross-boundary-retention-headroom-screen.md`

FROZEN (the SUBJECT of measurement — must be git-diff-empty at T6): `templates/.claude/hooks/{pre-compact,post-compact,session-start}.sh` + `session-start.d/*`, the recovery protocol in `.claude/rules/dev-wiki-hooks.md`, the memory bridge, the always-loaded rule files; plus `emit-proxy-vector.sh`, `measurability-gate.sh`, `anchor-screen/`, code under `eval/comparison|corpus|reasoning`.

## Exit Criteria

- [ ] `check.sh --selftest` / `--verify-pins` / `leak-check.sh` / `assert-off-on-isolation.sh` exit 0
- [ ] `git merge-base --is-ancestor <pre-registration commit> <first verdicts/ commit>` exits 0
- [ ] `grep -c '^PROGRAM-VERDICT:' screen-record.md` returns exactly 1; the no-harness-value disclaimer string is present
- [ ] Bare-derivation gate result + motivated|arbitrary classification recorded per candidate; 3 controls present (negative→DEGENERATE, positive→HAS-HEADROOM, middle→STABLE); ≥2 candidates screened
- [ ] `check.sh --stability <middle-b1> <middle-b2>` prints `STABLE`; 10 middle-control run files exist
- [ ] Engineered-favorable backstop screens DEGENERATE or is recorded bare-disqualified
- [ ] ≥1 candidate reached a lossy boundary (OFF-fail) OR `TERMINATE-by-summary-robustness` is recorded
- [ ] `make eval` 52/52; `make test` runs the UNCHANGED 19 scripts; frozen set `git diff`-empty

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
