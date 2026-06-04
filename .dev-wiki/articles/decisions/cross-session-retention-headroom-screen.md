---
title: "Phase 77 — Cross-Session Retention Headroom Screen (audit-gated ablation): the amplifier program's terminal regime, measured on the real edge-screener substrate"
aliases: [cross-session-retention-headroom-screen, xsession-retention-screen, phase-77-screen]
category: decisions
tags: [eval-validity, amplifier-vision, measurement, retention, cross-session, headroom, ablation, audit-gated, edge-screener, phase-77]
parents: [phase-77-cross-session-retention-screen]
created: 2026-06-04
updated: 2026-06-04
source: plan
confidence: high
---

## Context

The amplifier headroom-search has measured NULL in every regime so far: single-decision recall (Phase 70 — bare `claude-opus-4-8` does the AML reasoning unprompted, all 4 anchors DEGENERATE 5/5, TERMINATE) and single-session / single-compaction retention (Phase 71 — the native model-authored compaction summary is decision-comprehensive WITHIN a session, TERMINATE-by-summary-robustness). Both nulls were a property of the *boundary*, not a dead instrument — controls validated each. The ONE untested regime named at the close of Phase 71 is **cross-SESSION**: when a session ends, the native in-context summary dies, but the on-disk substrate (decision articles, `_CURRENT_STATE.md`, `active-phase.md`, `working-knowledge.md`, roadmap) persists. Phase 73 deliberately stood up an EXTERNAL real project — `/Users/jwang/edge-screener` — as the substrate to escape the Ph70/71 self-measurement confound, and deferred this measurement until that substrate accrued real multi-session history. That decidable-when gate is now GREEN: edge-screener has 9 completed phases, 14 decision articles, 11 journals across 3 distinct dates (2026-05-31, 06-01, 06-02), 28 commits. This is the LAST regime; a degenerate result here closes the headroom-search line (the substrate would then be kept on operational grounds, not measured-headroom grounds).

The honest prior is degenerate: the decisions are likely recoverable from code + tests + decision-rich commit bodies, so the substrate-unique surface is expected to be small. Jake chose **"audit-gated ablation"** at the direction gate (2026-06-04); the approach is formalized in `specs/phase-77-cross-session-retention-screen.md` (marker `nana:approved`).

## Decision

**Approach: run the amplifier program's terminal (cross-session) regime as an AUDIT-GATED ABLATION on the real edge-screener substrate** — cheapest-first, in a new repo-only apparatus `eval/amplifier/xsession-screen/` (sibling to `anchor-screen/` and `retention-screen/`, NOT wired into install.sh / Makefile / make test / make eval, frozen on completion). edge-screener is a READ-ONLY subject (assert byte-identical before/after).

1. **T1 — Residual audit (the GATE).** For every decision in edge-screener's dev-wiki (decision articles + `_CURRENT_STATE.md` Recent-Decisions + `active-phase.md` + roadmap), extract a pre-registered *discriminating token* (the value distinguishing the chosen path from the alternative — a threshold, a named clause, a sentinel, a negative decision's rejected option). Run a deterministic provenance check: the token must be ABSENT from everything the OFF condition can see (`git grep` over the source tree, `grep -r` over tests, `git log -p` commit bodies) AND still RESOLVE at HEAD AND be PINNED to its terminal value (a later phase's reversal supersedes the original — recovering the dead value is a MISS). The residual = the surviving set = the substrate's unique cross-session payload. **EMPTY residual, or below the pinned n≥3 floor ⇒ PROGRAM-VERDICT: TERMINATE / INCONCLUSIVE; STOP — do NOT build T2/T3.** `residual-audit.sh --selftest` must prove its predicate BOTH ways on a planted control pair (a token present in OFF inputs is excluded; a genuinely-absent token survives), matching the `check.sh` selftest discipline — a no-op `exit 0` does not satisfy this.

2. **T2/T3 — Controlled OFF/ON ablation (only if residual ≥ 3).** On exactly the residual items, at real session boundaries, over a *physically stripped* throwaway copy of the subject: **bare-OFF** (source + tests + `.git` incl. commit bodies, all substrate paths deleted; a manifest assertion fails the run if any substrate file is present), **padded-OFF** (bare-OFF + equal-token decision-EMPTY filler — the Phase-59 length/volume control), **ON** (bare-OFF + the real dev-wiki substrate), **positive-control** (a planted substrate-only decision ON MUST recover, else the verdict is INSTRUMENT-DEAD, not NULL). n=5 per condition; the frozen `retention-screen/` consensus-by-clause checker scores on the discriminating token (exact match, NO prose similarity, NO LLM in scoring). Pre-registration — including the pinned n≥3 floor committed BEFORE the residual count is consulted — is committed in a SEPARATE commit that must be a git ancestor of the verdict (`git merge-base --is-ancestor`). ON scores HAS-VALUE only if it beats BOTH bare-OFF and padded-OFF on the same items.

3. **T3-record / disposition.** `screen-record.md` carries a grep-able `^PROGRAM-VERDICT:` from the closed vocabulary {TERMINATE | NULL | HAS-HEADROOM | INSTRUMENT-DEAD | INCONCLUSIVE}, plus a no-harness-value disclaimer AND the git-log-as-competing-substrate-channel caveat: the OFF baseline's decision-rich commit bodies are themselves partly a downstream product of the harness's own debrief discipline, so a null residual means the harness's value precipitated INTO git — NOT that the substrate is worthless.

## Alternatives considered + rejected

- **(a) A synthetic Ph71-clone cross-session screen** — REJECTED: re-imports the self-measurement confound Phase 73 stood up edge-screener specifically to escape.
- **(b) Naturalistic observation only** — REJECTED as the sole method: no counterfactual, can't causally attribute retention to the substrate. Folded in as the residual-audit pre-screen instead.
- **(c) Full controlled ablation across all boundaries regardless of the pre-screen** — REJECTED: risks spending the whole phase confirming a foregone degenerate that the cheap audit catches in one pass. The audit gates whether T2 is built at all.

## Honest prior + interpretive guard

Degenerate is the expected outcome (git-log + code + tests already carry the decisions), placing this one regime past Ph70/71. The positive control GATES the null (INSTRUMENT-DEAD blocks a false TERMINATE), and the n≥3 floor forces INCONCLUSIVE below it (the Phase-58/70/71 n=1-lucky-draw scar). Excellence is the verdict being un-foolable in EITHER direction, not the direction it points. A null residual ≠ substrate worthless — record that caveat so the verdict is not over-read.

## RESULT: PROGRAM-VERDICT: TERMINATE

The audit gate HALTED at **residual 0 / 14** — every pre-registered operative discriminator (one per edge-screener decision, pinned to terminal value, committed in prereg `21a6c52` BEFORE the run) is RECOVERABLE from the OFF corpus, in fact from **code + tests alone** (the `gitmsg` channel was not even needed). This includes the two residual-FAVORABLE candidates chosen because they were most likely to be substrate-only: `Shumway` (the −30% delisting citation) and `Stooq` (the deferred-alternative source) — both in the code. Per the pre-registered ladder, residual 0 < floor 3 ⇒ **TERMINATE**; the T3 OFF/ON ablation correctly did NOT run (no positive control needed — the audit `--selftest` already proves instrument liveness: a planted substrate-only token DOES survive into the residual, so residual-0 is a property of the SUBJECT, not a broken grep). `git merge-base --is-ancestor 21a6c52 HEAD` passes; edge-screener byte-identical pre/post.

Stronger than the pre-registered git-log caveat anticipated: the residual is 0 from CODE+TESTS, *before* commit messages are consulted — **a decision that has been implemented IS in the implementation**. The substrate was never the sole carrier of any decision's operative value.

**The decision-retention line is now closed across all three regimes** (single-decision Ph70, single-session Ph71, cross-session Ph77). Harness headroom does not live in re-presenting decisions the model can recover from artifacts it already has. Scope of this TERMINATE: the operative discriminators of the 14 decision ARTICLES (incl. citation + negative candidates); pure rationale and roadmap process/sequencing discipline were NOT separately sampled (strong prior they are also degenerate — process narration is in-tree via `METHODOLOGY.md` and the phase sequence is legible in git history — re-trigger = a fresh pre-registered round). No measured harness-value claim is made; the substrate is kept on operational grounds. Full record: `eval/amplifier/xsession-screen/screen-record.md`.

## Links

- [[cross-session-substrate-stock-screener]] (Phase 73) — the substrate this measures.
- [[cross-boundary-retention-headroom-screen]] (Phase 71) — the within-session null + the frozen `retention-screen/` apparatus reused here byte-verbatim.
- [[amplifier-anchor-headroom-screen]] (Phase 70) — the single-decision null that started the regime ladder.
