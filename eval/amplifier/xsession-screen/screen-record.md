# Screen Record — Phase 77 Cross-Session Retention Headroom Screen

PROGRAM-VERDICT: TERMINATE

(Closed vocabulary: TERMINATE | NULL | HAS-HEADROOM | INSTRUMENT-DEAD | INCONCLUSIVE.)

## What was measured
The amplifier headroom-search's **terminal regime**: does the persistent on-disk dev-wiki substrate let
a fresh session recover decisions a substrate-free (OFF) session loses across a real cross-session
boundary, on the real `/Users/jwang/edge-screener` subject (9 phases, 14 decision articles, 28 commits)?
Audit-gated: a deterministic residual audit (the cheap gate) precedes any expensive OFF/ON ablation.

## Result
**RESIDUAL = 0 / 14.** Every pre-registered operative discriminator — one per edge-screener decision,
pinned to terminal value (`token-list.tsv`, committed in prereg `21a6c52` BEFORE the run) — is
RECOVERABLE from the OFF corpus, in fact from **code + tests alone** (the `tree` channel; the `gitmsg`
commit-message channel was not even needed). This INCLUDES the two candidates chosen *because* they were
the most likely to be substrate-only: `Shumway` (the −30% delisting citation) and `Stooq` (the
deferred-alternative source). Both were in the code. Per the pre-registered ladder, residual 0 < floor 3
⇒ **TERMINATE**; the T3 controlled OFF/ON ablation correctly did **not** run (`residual.md`).

## Why this TERMINATE is trustworthy (not a dead instrument, not retrofitted)
- **Instrument liveness:** `residual-audit.sh --selftest` proves both directions on planted fixtures —
  a token present in the OFF corpus is EXCLUDED, and a token carried ONLY by the substrate (`.dev-wiki/`
  or `AGENTS.md`) SURVIVES into the residual. So residual-0 is a property of the SUBJECT, not a broken
  grep. (The Ph70/71 "controls validate the instrument" discipline; here the selftest is the control.)
- **Anti-retrofit:** the token list + the n≥3 floor were committed (`21a6c52`) before the audit ran;
  `git merge-base --is-ancestor 21a6c52 HEAD` passes (the residual-result commit is a descendant).
- **Read-only subject:** `assert-subject-untouched.sh` confirmed edge-screener byte-identical pre/post.
- **Not gamed toward degenerate:** the tokens were the natural operative discriminators, and the two
  residual-FAVORABLE candidates were included on purpose — they still landed RECOVERABLE.

## The git-log-as-channel caveat — strengthened
The pre-registration anticipated a near-empty residual *because the decision-rich commit messages are a
harness product (the debrief discipline wrote them)*. The actual result is stronger: the residual is 0
from CODE + TESTS, before commit messages are consulted at all. **A decision that has been implemented
IS in the implementation.** The substrate's content did not fail to transfer across the session boundary
— it was never the sole carrier of any decision's operative value. Its value (if any) precipitated into
the code itself, one step earlier than git.

## No-harness-value disclaimer
This does NOT claim the substrate is worthless. It establishes one thing precisely: the dev-wiki
substrate carries no decision-operative value that is UNRECOVERABLE from the subject's own code + tests +
commit messages. Operational/ergonomic value — having state pre-loaded at session-start instead of
re-derived, the dev-wiki as a writing surface during work — is real, is the basis on which the substrate
is KEPT, and is explicitly NOT what this screen measured. No measured harness-value claim is made.

## Honest scope (what was and was not sampled)
- Sampled: the **operative discriminator** of each of the 14 decision ARTICLES (the value a fresh
  session must know to HONOR the decision), incl. citation + negative-decision candidates.
- NOT separately sampled: **pure rationale ("why")** and **roadmap process/sequencing discipline**
  (Ph71's "diffuse process discipline" sub-thread) — these live in phase roadmaps, not decision
  articles. Strong prior they are ALSO degenerate (process narration is in-tree via `METHODOLOGY.md`,
  and the phase SEQUENCE is legible in the git history itself), but they were not directly measured.
  Re-trigger: a fresh, separately pre-registered round with process/sequencing tokens. This bounds the
  TERMINATE to the decision-retention line; it does not claim the process sub-thread closed by fiat.
- Single subject (n=1 at the project level; n=14 at the decision level). edge-screener is the designed,
  representative substrate; a less-documented codebase is a separate question.

## Program disposition
The amplifier headroom-search's **decision-retention line is now closed across all three regimes**:
single-decision (Ph70, DEGENERATE 5/5), single-session/compaction (Ph71, TERMINATE-by-summary-
robustness), and cross-session (Ph77, residual 0 → TERMINATE). The recurring structural finding holds
one regime further out: harness headroom does not live in re-presenting decisions the model can recover
from the artifacts it already has (code, tests, git, native summary). The only avenues never falsified
remain the Ph70 ones — retrieval of genuinely PROPRIETARY / POST-CUTOFF facts the model cannot derive —
which edge-screener's decisions are not (they are all derivable from its own tree). The substrate is
kept on operational grounds.

## Review + robustness
Independent review gate: **accept (9/10)**. It attacked residual-0 from every angle — false-match generic
tokens, dead selftest, retrofit hole — and could not break it: all 14 tokens match in genuine on-point
code context (`Shumway` in `delisting.py` + its test; `Stooq` as `class StooqSource`), the selftest is an
honest both-ways control, and the anti-retrofit ancestry is intact. One LOW finding (binary/cache blobs
`cat` into the NUL-bearing corpus temp) was hardened post-review: the OFF-corpus `find` now excludes
`.mypy_cache/.pytest_cache/.ruff_cache/.hypothesis/.coverage` and the grep uses `-a` — bringing the
implementation into line with the pre-registration's already-committed "binary/data blobs excluded" spec
(not a retrofit). The hardening is directionally safe (it can only ever INFLATE the residual, never
manufacture a false TERMINATE). Robustness re-run with the hardened instrument: **residual still 0/14**.

## Apparatus (frozen, repo-only)
`residual-audit.sh` (gate + selftest), `assert-subject-untouched.sh` (read-only guard), `token-list.tsv`
(pinned discriminators), `pre-registration.md` (`21a6c52`), `residual.md` (gate result), this record.
NOT wired into install.sh / Makefile / make test / make eval.
