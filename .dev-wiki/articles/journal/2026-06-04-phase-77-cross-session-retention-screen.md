---
title: "Phase 77 complete — Cross-Session Retention Headroom Screen (audit-gated ablation): residual 0/14 → TERMINATE, the amplifier decision-retention line closed across all three regimes"
aliases: []
category: journal
tags: [amplifier-vision, eval-validity, process-retention, cross-session, terminate, campaign-closed, audit-gate, anti-retrofit]
parents: [phase-77-cross-session-retention-screen]
created: 2026-06-04
updated: 2026-06-04
source: debrief
duration: long single session (plan → spec → implement T1-T4 → verdict)
---

# Phase 77 complete — Cross-Session Retention Headroom Screen (audit-gated ablation)

## What Happened

The amplifier program's **last untested regime**: when a session ends, Claude Code's native in-context compaction summary dies, but the on-disk dev-wiki substrate (decision articles, `_CURRENT_STATE.md`, `active-phase.md`, `working-knowledge.md`, roadmap) persists. Does a fresh session WITH the substrate recover decisions a substrate-free session loses across a real session boundary? Measured on the REAL external `/Users/jwang/edge-screener` substrate (Phase 73 stood it up to escape the Ph70/71 self-measurement confound; the decidable-when gate is now green — 9 phases, 14 decision articles, 11 journals across 3 dates, 28 commits).

Method = **audit-gated ablation** (Jake chose this at the direction gate, resolving the controlled-vs-naturalistic fork as BOTH): a cheap deterministic T1/T2 residual-audit GATE short-circuits to TERMINATE/INCONCLUSIVE before any expensive OFF/ON run; the controlled ablation (T3) runs ONLY on a residual ≥ 3.

- **T1 [M] — Residual-audit gate (apparatus).** Built `residual-audit.sh` (deterministic provenance absence-grep over the OFF corpus = code + tests + git-MESSAGES; `git log -p` EXCLUDED so the substrate stripped from the working tree is not resurrected from history; NO LLM) + `assert-subject-untouched.sh` (read-only guard). Both `--selftest` pass: residual-audit covers a both-ways control pair, substrate-strip, superseded-value, unresolved-at-HEAD, and gitmsg channel-gating; untouched covers unchanged / mutation / stray-file. Real-subject smoke validated READ-ONLY (edge-screener byte-identical before/after).
- **T2 [S] — Pre-registration + pinned n≥3 floor.** `token-list.tsv` (14 operative discriminators, one per edge-screener decision, pinned to terminal value) + `pre-registration.md` committed BEFORE the run (prereg `21a6c52`), THEN the gate audit ran → `residual.md`. Ancestor guard holds (`21a6c52 ⊂ HEAD`). **RESULT: residual 0/14** — every discriminator is RECOVERABLE from CODE+TESTS ALONE (the `gitmsg` channel was not even needed), INCLUDING the two residual-FAVORABLE candidates chosen because they were most likely to be substrate-only: `Shumway` (the −30% delisting-return citation) and `Stooq` (the deferred-alternative source) — both in the code.
- **T3 [L] — Controlled OFF/ON ablation. SKIPPED-BY-GATE.** Residual 0 < floor 3 ⇒ the pre-registered ladder forbids the ablation. No stripped-tree harness, no padded-OFF, no positive control built — the audit `--selftest` already proves instrument liveness (a planted substrate-only token DOES survive into the residual). The L cost was correctly NOT spent.
- **T4 [S] — Record / disposition / freeze.** `screen-record.md` (`^PROGRAM-VERDICT: TERMINATE`, no-harness-value disclaimer, git-log-as-competing-channel caveat, honest scope note) + the decision-article RESULT appended. `make test` green, `make eval` 52/52, zero surface churn.

**Headline finding:** *a decision that has been implemented IS in the implementation.* The residual is 0 from code+tests *before* commit messages are even consulted — stronger than the pre-registered git-log caveat anticipated. The substrate was never the sole carrier of any decision's operative value. This **closes the amplifier decision-retention line across all three regimes** (single-decision Ph70 DEGENERATE 5/5, single-session Ph71 TERMINATE-by-summary-robustness, cross-session Ph77 residual-0 TERMINATE). Harness headroom does not live in re-presenting decisions the model can recover from artifacts it already has. The substrate is kept on operational grounds; **no measured harness-value claim** is made.

## Decisions Made

- [[cross-session-retention-headroom-screen|Cross-Session Retention Headroom Screen (audit-gated ablation)]] — RESULT appended this session (PROGRAM-VERDICT: TERMINATE, residual 0/14); the decision article was created at plan, so no new article — verified consistent.

## Problems Solved

- **Anti-retrofit ordering (DISCOVERY, escape hatch).** The real `residual.md` production moved from T1 to T2: the discriminating-token list must be COMMITTED before the audit runs, else tokens could be cherry-picked to manufacture a residual. The OFF corpus was made channel-configurable (`tree` / `gitmsg`) and `git log -p` was EXCLUDED (it would resurrect the substrate stripped from the working tree but still in git history). Documented in the tasks.md T1 DISCOVERY note + the prereg commit message.
- **A null residual could be over-read as "substrate worthless" — pre-empted.** The OFF baseline's decision-rich commit bodies are themselves partly a downstream product of the harness's own debrief discipline, so a null means the harness's value precipitated INTO git, not that the substrate is worthless. Caveat carried in both `screen-record.md` and the decision article.

## Open Questions

- **Process/sequencing-roadmap retention was NOT separately sampled** (the Ph71 "diffuse process discipline" sub-thread) — only the operative discriminators of the 14 decision ARTICLES were. Strong prior it is also degenerate (process narration is in-tree via the edge-screener `METHODOLOGY.md`; the phase sequence is legible in git history). Re-trigger: a fresh, separately pre-registered round with process/sequencing tokens. → carried to Blockers as `[open: Phase-77]`.
- **Single subject (edge-screener) — n=1 at the project level** (n=14 at the decision level). A less-documented codebase is a separate question.

## Artifacts Changed

- `eval/amplifier/xsession-screen/` (NEW repo-only apparatus, sibling to `anchor-screen/` and `retention-screen/`): `residual-audit.sh`, `assert-subject-untouched.sh`, `token-list.tsv`, `pre-registration.md`, `residual.md`, `screen-record.md`, `.prereg-commit`. FROZEN, NOT wired into install.sh / Makefile / make test / make eval.
- `.dev-wiki/articles/decisions/cross-session-retention-headroom-screen.md` (RESULT section appended)

## Related

- [[phase-77-cross-session-retention-screen|Phase 77: Cross-Session Retention Headroom Screen]] — parent phase
- [[amplifier-anchor-headroom-screen|Phase 70: Anchor Headroom Screen]] + [[cross-boundary-retention-headroom-screen|Phase 71: Cross-Boundary Retention Screen]] — the two prior regime nulls this phase completes
- [[cross-session-substrate-stock-screener|Phase 73: Cross-Session Substrate]] — stood up the edge-screener subject

## Soft Observations / Phase N+1 Candidates

- Process/sequencing-roadmap retention is the one un-sampled sliver — strong-prior-degenerate; re-trigger = a fresh pre-registered round. | Phase-78 candidate (low priority): cross-session process/sequencing retention screen | evidence: `eval/amplifier/xsession-screen/screen-record.md` scope note + this journal Open Questions
- Meta-finding worth a working-knowledge entry: "a decision that has been implemented IS in the implementation" — code+tests+git already carry the decision-operative value; the dev-wiki substrate carries nothing UNRECOVERABLE. CLOSES the amplifier decision-retention line across all three regimes. Surviving untested avenue stays the Ph70 one: retrieval of genuinely PROPRIETARY/POST-CUTOFF facts the model cannot derive. | working-knowledge.md (carried forward this debrief) | evidence: decision-article RESULT section
- `_CURRENT_STATE.md` chronic 136>100 line-budget overage (pre-existing across phases) | standing cleanup candidate (not this phase) | evidence: `wc -l .dev-wiki/_CURRENT_STATE.md`

## Health Delta

- `make test` "All tests passed"; `make eval` 52/52 (unchanged).
- Zero surface churn: no new make-test scripts, README / modules.json / settings.json unchanged — the apparatus is repo-only.
- 2 commits this session (`21a6c52` prereg, `c063685` residual result); NOT pushed (orchestrator handles delivery-flow).
- Self-check clean: `active-phase.md` trimmed 25→17 lines; `_CURRENT_STATE.md` 136>100 is a chronic PRE-EXISTING overage, noted not fixed.

### Activation Quality

`.claude/rules/active-knowledge.md` carried 3 reference blocks: `[[amplifier-anchor-headroom-screen]]`, `[[cross-boundary-retention-headroom-screen]]`, `[[cross-session-retention-headroom-screen]]`. All 3 were load-bearing this session — the Ph70/71 nulls were the explicit prior this phase extended, and the cross-session decision was the phase itself. Hit rate 3/3 (100%). The pre-loaded "campaign method invariants" (NO LLM, controls gate the null, pre-registration before runs, cheapest-check-first) directly shaped the audit-gate design.
