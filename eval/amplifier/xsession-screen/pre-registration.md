# Pre-Registration — Phase 77 Cross-Session Retention Headroom Screen

**Committed BEFORE the residual audit is run on edge-screener.** The anti-retrofit guard is the git
ancestry: this file's commit (recorded in `.prereg-commit`) MUST be an ancestor of the `residual.md`
commit (`git merge-base --is-ancestor "$(cat .prereg-commit)" HEAD`). The discriminating-token list
(`token-list.tsv`) and the floor below are fixed here so neither can be retrofitted to the observed
result.

## Subject
`/Users/jwang/edge-screener` — a real consuming project: 9 completed phases, 14 decision articles, 11
journals across 3 dates, 28 commits. READ-ONLY for the measurement (`assert-subject-untouched.sh`
brackets every run; drift fails closed).

## OFF corpus (pinned channels: `tree,gitmsg`)
A substrate-free (OFF) session's recoverable inputs are defined as:
- **tree** — every file under the subject EXCEPT the substrate (`.dev-wiki/`, `.claude/`, `AGENTS.md`),
  `.git/`, `__pycache__/`, and binary/data blobs. (code + tests)
- **gitmsg** — `git log` commit-message bodies.

**`git log -p` is DELIBERATELY EXCLUDED.** The substrate is in git *history*, so `-p` diffs would
resurrect the very `.dev-wiki/` content the OFF condition strips, manufacturing a false-empty residual.
Commit *messages* are included because any real bare session has `git log` — and they are decision-rich
here. NOTE (the git-log-as-channel caveat, carried into the verdict): those rich commit messages are
themselves partly a *harness product* (the dev-debrief discipline wrote them). So a near-empty residual
means the harness's value **precipitated into git**, NOT that the substrate is worthless.

## Discriminating tokens
`token-list.tsv` — one operative discriminator per decision, pinned to terminal value, chosen as the
natural discriminator (not to inflate the residual). RESIDUAL = tokens ABSENT from every OFF channel.

## Pinned floor (committed before the residual count is known)
**n ≥ 3 distinct RESIDUAL decisions.** Rationale: below 3, a HAS-HEADROOM reading off the downstream
ablation is an n=1/2 lucky-draw — the Phase-58/70/71 scar (a single favorable draw read as a banked
effect). The floor may only move UP at review (never down to fit an observed residual).

## Verdict ladder
The residual audit (T1/T2) gates the ablation (T3):
- **residual ≥ 3** → `PROCEED`: run the T3 controlled OFF/ON ablation on exactly the residual items.
- **0 < residual < 3** → `PROGRAM-VERDICT: INCONCLUSIVE` (below floor; no ablation).
- **residual = 0** → `PROGRAM-VERDICT: TERMINATE` (cross-session substrate carries nothing the OFF
  corpus does not; the amplifier headroom-search closes — substrate kept on operational grounds).

If T3 runs, its differential verdict (per `check.sh` consensus-by-clause, n=5, NO LLM) is:
- bare-OFF honors ≥4/5 → `DEGENERATE`.
- bare-OFF drops ≥4/5 AND ON honors ≥4/5 AND ON beats padded-OFF on the same items → `HAS-HEADROOM`.
- the planted **positive control** (a substrate-only decision) MUST be recovered by ON; if ON fails it,
  the verdict is `INSTRUMENT-DEAD` (blocks a false TERMINATE), not NULL.

## Instrument liveness (why a TERMINATE here is trustworthy, not a dead instrument)
The audit's `--selftest` is its liveness proof: a planted token present in the OFF corpus is correctly
EXCLUDED, and a planted substrate-only token correctly SURVIVES into the residual (both directions,
plus the substrate-strip and gitmsg-channel-gating cases). A residual of 0 is therefore a property of
the subject, not a broken grep — exactly the Ph70/71 "controls validate the instrument" discipline.

## Honest prior (pre-stated)
Degenerate is expected: edge-screener's decisions are materialized in code/tests, and its commit
messages are decision-rich. The residual is expected to be small (citations / cut-alternatives) and
likely below the floor ⇒ INCONCLUSIVE or TERMINATE. Either outcome is the deliverable; this is the
last untested regime of the amplifier headroom-search.
