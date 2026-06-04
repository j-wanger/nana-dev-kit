# Active Phase Context

Phase: 77 — Cross-Session Retention Headroom Screen (audit-gated ablation)
Status: Active — planned, implementation pending

Objective: Measure whether the persistent on-disk dev-wiki substrate lets a fresh session recover
decisions/process-discipline a substrate-free session loses across a real session boundary — on the
READ-ONLY `/Users/jwang/edge-screener` substrate (Phase 73). The amplifier program's TERMINAL regime.

Approach: audit-gated, cheapest-first, in repo-only `eval/amplifier/xsession-screen/` (frozen on completion,
NOT wired into install.sh/Makefile/make test/make eval). T1 residual-audit GATE (dev-wiki decisions minus
git/code/test-recoverable, terminal-value-pinned, HEAD-resolvable) — EMPTY or <3 ⇒ TERMINATE/INCONCLUSIVE,
STOP (no T2/T3). T2/T3 (only if residual ≥ 3) controlled ablation: bare-OFF/padded-OFF/ON/positive-control,
n=5, frozen consensus-by-clause checker (NO LLM), pinned n≥3 floor + ancestor-guarded pre-registration.
Honest prior: degenerate (git-log+code+tests carry the decisions); positive control gates the null
(INSTRUMENT-DEAD blocks a false TERMINATE). edge-screener byte-identical before/after.

Decision: [[cross-session-retention-headroom-screen]] (high). Reuses the frozen
[[cross-boundary-retention-headroom-screen]] (Phase 71) apparatus; closes the regime ladder from
[[amplifier-anchor-headroom-screen]] (Phase 70).
Abort: if blocked >3 attempts, mark [blocked] + ask user skip/abort.

Gates:
- [x] Direction confirmed by user (approach approved 2026-06-04 — "audit-gated ablation")
- [ ] Delivery accepted (post-implementation report)
