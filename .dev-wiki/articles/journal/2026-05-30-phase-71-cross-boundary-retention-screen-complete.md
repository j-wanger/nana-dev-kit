---
title: "Phase 71 complete — Cross-Boundary Retention Headroom Screen → PROGRAM-VERDICT: TERMINATE-by-summary-robustness"
aliases: []
category: journal
tags: [amplifier-vision, measurement, retention, compaction, process-retention, headroom, eval-validity, terminate]
parents: [phase-71-cross-boundary-retention-screen]
created: 2026-05-30
updated: 2026-05-30
source: debrief
duration: long
---

# Phase 71 complete — Cross-Boundary Retention Headroom Screen → PROGRAM-VERDICT: TERMINATE-by-summary-robustness

## What Happened

Built AND ran the multi-turn analog of the Phase-70 anchor screen — the cheapest go/no-go for the Phase-70 surviving "long-horizon / multi-turn process-retention" avenue (Jake-chosen). The binding question: across a compaction boundary, does the harness cross-compaction state machinery RECOVER an earlier-established counter-default decision that a bare agent (residual context only) DROPS? Jake steered three forks mid-flow via AskUserQuestion — direction=multi-turn retention, instrument=checkable-decision, substrate-depth=rigorous-long-session-test.

- **T1 (RED-first apparatus):** cloned the Phase-70 `anchor-screen/` spine into a NEW repo-only `eval/amplifier/retention-screen/` tree. `check.sh` ports `run_check`/`aggregate`/`stability`/`verify_pins` byte-VERBATIM from `../anchor-screen/check.sh`; only `diff_verdict` + `--diff` are new (differential OFF×ON over two n=5 aggregates: DEGENERATE / HAS-HEADROOM / INERT[same-clause] / UNSTABLE). Authored `leak-check.sh` + committed `leak-vocab.txt`, `assert-off-on-isolation.sh` (OFF text is an exact byte-prefix of ON). NO LLM in the scoring path — the model is confined to one-time frozen summary authoring.
- **T2 (pre-register + commit SEPARATELY, `896e096`):** authored pinned synthetic transcripts, generated model-authored compaction summaries (bare subagent, frozen once produced — never iterated to force a drop), built OFF (summary + last-K turns) and ON (OFF + appended `[HARNESS STATE]` block) prompts, ran the bare-derivation gate + rationale-probe per candidate, classified motivated/arbitrary. Committed the whole apparatus BEFORE any verdict run — `git merge-base --is-ancestor 896e096 d7067e6` holds (anti-retrofit).
- **T3 (controls — load-bearing):** negative→DEGENERATE; **positive→HAS-HEADROOM** (THE load-bearing proof the ON pathway is LIVE: a state-block decision absent from the residual IS read and honored 5/5, while the bare model REFUSES to invent it — "I don't know; I won't fabricate it"); middle→STABLE across two independent n=5 batches. Instrument validated.
- **T4 (candidates):** all candidates DEGENERATE-by-summary-robustness — see below.
- **T5 (aggregate + finalize):** the pre-committed ladder → `PROGRAM-VERDICT: TERMINATE-by-summary-robustness`; `screen-record.md` + the decision article finalized to `confidence: high` with a realized Result section.
- **T6 (regression):** `make eval` 52/52, `make test` green at the UNCHANGED 19-script count (retention-screen NOT in the Makefile → no README bump), frozen machinery `git diff`-empty, no-LLM token sweep clean over the scoring path.

The deciding finding held across two transcript scales: **a model-authored compaction summary RETAINS explicit project decisions.** Two short probes and one long (1,213-word, ~12-decision) session were each pinned-then-summarised and ACCEPTED as produced. The long session's 356-word summary retained ALL THREE candidates — the MOTIVATED EUR 8,000 monitoring threshold (chosen over the EUR 10,000 regulatory default), the MOTIVATED rolling-7-day structuring window, AND the ARBITRARY `hit_flag` sentinel 9 (every token grep-verified present). In OFF the bare model HONORED every retained decision 5/5, including choosing the counter-default EUR 8,000. No candidate reached a lossy boundary, so the single-session cross-boundary-retention line is TERMINATE-by-summary-robustness — the precise multi-turn analog of Phase 70's "the bare model does the reasoning unprompted," extended from reasoning to decision-retention. There is nothing for the harness state machinery to RECOVER in the single-compaction regime.

## Decisions Made

- [[cross-boundary-retention-headroom-screen|Cross-Boundary Retention Headroom Screen]] — finalized this session to `confidence: high` with a realized Result section (the decision article was authored at plan time and completed at T5; not duplicated here).

## Problems Solved

- **Short-probe summaries too lossless to stress compaction** — initial short-probe transcripts produced decision-retaining summaries (too short to stress the boundary). Escalated (Jake-approved, AskUserQuestion fork 3) to one realistic long session, pinned-then-summarised, ACCEPTED as produced (no iterating-to-force-a-drop). Documented in `pre-registration.md` + `screen-record.md`.
- **Brittle pre-registered forbid clause** — `cand-sentinel`'s `forbid not-boolean` (`\btrue\b|\bboolean\b`) fired on the CORRECT answer's *explanation* ("9, not boolean true"), reading a false HAS-HEADROOM. Withdrawn as INVALID; the committed check left UNCHANGED (editing after the runs would be retrofitting); verdict taken from the valid `require honored-9` (5/5 PASS) + the deterministic retention grep, disambiguated by the positive control (a REAL OFF-failure states NO value; the sentinel runs stated 9).

## Open Questions

- **Cross-SESSION persistence of harness state** — the native compaction summary does NOT survive a new session; the harness `active-phase.md` / `_CURRENT_STATE.md` files DO. This is the genuine untested harness-value regime, re-gated on a real multi-session substrate that still does not exist. NO Phase-72 rig authorized.
- **Cumulative MULTI-compaction degradation** — untested (the screen covers a single compaction).
- **Diffuse process discipline** — out of scope by construction (not single-output checkable).
- **Dead `.session-anchor` read-branch** — `post-compact.sh` READS `.claude/.session-anchor` but nothing in the repo WRITES it. A latent bug for a future fix-phase, recorded (NOT fixed — freeze-the-subject).

## Artifacts Changed

- `eval/amplifier/retention-screen/` (NEW repo-only tree, 79 files: `check.sh` + `leak-check.sh` + `assert-off-on-isolation.sh` + `leak-vocab.txt` + `fixtures/` + `prompts/` + `checks/` + `probes/` + `transcripts/` + `summaries/` + 40 `runs/` + 8 `verdicts/` + `pre-registration.md` + `screen-record.md`; NOT wired into install.sh / Makefile / make test / make eval)
- `.dev-wiki/articles/decisions/cross-boundary-retention-headroom-screen.md` (finalized to `confidence: high`, realized Result section)
- FROZEN (git-diff-empty, the subject of measurement): `templates/.claude/hooks/{pre-compact,post-compact,session-start}.sh` + `session-start.d/*`, the recovery protocol, memory bridge, always-loaded rule files; `emit-proxy-vector.sh`, `measurability-gate.sh`, `anchor-screen/`

## Related

- [[phase-71-cross-boundary-retention-screen|Phase 71: Cross-Boundary Retention Headroom Screen]] — parent phase
- [[amplifier-anchor-headroom-screen|Phase 70 anchor screen]] — the parent screen this extends (the single-decision analog)

## Soft Observations / Phase N+1 Candidates

- **Cross-SESSION persistence is the genuine untested harness-retention regime** | a future phase needs a real multi-session / multi-compaction substrate (the Phase-70 decidable-when, still unmet) | evidence: `screen-record.md` SCOPE section + decision article Result.
- **Dead `.session-anchor` read-branch in post-compact.sh** | a future phase could write a session-anchor or remove the dead read | evidence: `screen-record.md` "Discovered latent finding" + phase article Notes.
- **Check-design lesson** | a substring `forbid` must target the ANSWER (e.g. `hit_flag = true`), never explanatory vocab, or it false-positives on correct answers that explain "not X"; disambiguate via a positive control showing what a REAL OFF-failure looks like | evidence: `cand-sentinel` verdict + decision article DISCOVERED brittle-forbid.
- **The amplifier program now has BOTH single-decision (Phase 70) and single-session/single-compaction retention (Phase 71) closed** as summary-robust/degenerate | surviving avenues: cross-session/multi-compaction retention (needs substrate), retrieval-on-genuinely-proprietary (needs corpus+absorb), engineering roadmap (gap 4.1 language-agnostic core) | evidence: this journal + the Phase-70 journal.

## Health Delta

- `make test` unchanged at 19 make-test scripts (screen NOT a make-test gate → no README script-count bump)
- `make eval` 52/52 unchanged
- No test-count change; frozen machinery `git diff`-empty
- Pre-registration `896e096` is a git ancestor of verdict commit `d7067e6` (anti-retrofit guard holds)

### Activation Quality

`.claude/rules/active-knowledge.md` carried 2 source slugs this phase: `[[decision:cross-boundary-retention-headroom-screen]]` (Phase 71, the active decision — directly referenced by every task) and `[[decision:amplifier-anchor-headroom-screen]]` (Phase 70 parent — its ported `check.sh` spine + controls-first method were load-bearing in T1/T2/T3). Hit rate 2/2: both seeded propositions were used. Carried forward to working-knowledge at this debrief (Phase 71 new entry; Phase 70 entry incremented to uses:2).
