# Active Phase Context

Phase: 71 — Cross-Boundary Retention Headroom Screen (status: active, ~0%)

Objective: Decide, as the cheapest go/no-go, whether the harness cross-compaction state machinery RECOVERS an earlier-established counter-default decision that a bare agent (residual context only) DROPS across a compaction boundary. The multi-turn analog of the Phase-70 anchor screen.

Scope: eval/amplifier/retention-screen/** (NEW repo-only; NOT wired into install.sh/Makefile/make test/make eval) + .dev-wiki/articles/decisions/cross-boundary-retention-headroom-screen.md.

Key constraints:
- FROZEN (the SUBJECT of measurement, git-diff-empty at T6): pre-compact.sh, post-compact.sh, session-start.sh + session-start.d/*, the recovery protocol, the memory bridge, the always-loaded rules; plus emit-proxy-vector.sh, measurability-gate.sh, anchor-screen/, eval/comparison|corpus|reasoning.
- OFF = model-authored compaction summary (real mechanism); ON = OFF + one appended [HARNESS STATE] block, byte-for-byte (assert-off-on-isolation.sh). NO LLM in the scoring path. Differential verdict: DEGENERATE/HAS-HEADROOM/INERT/UNSTABLE. Pre-registration committed in a SEPARATE ancestor commit before verdicts. Motivated-vs-arbitrary litmus + human authorization gate CONTINUE.

Exit criteria: single anchored PROGRAM-VERDICT on the graded ladder + no-harness-value disclaimer; controls pass (neg→DEGENERATE, pos→HAS-HEADROOM, middle→STABLE); ≥2 candidates screened; make eval 52/52, make test 19 scripts unchanged.

Abort rule: any control misbehavior (pos≠HAS-HEADROOM esp. INERT / neg≠DEGENERATE / middle false-positives) → STOP, write FINDING to screen-record.md, report, do NOT screen candidates.

## Gates
- [x] Direction confirmed by user (approach approved — Jake via two AskUserQuestions 2026-05-30; spec nana:approved)
- [ ] Delivery accepted

See [[cross-boundary-retention-headroom-screen]] + [[amplifier-anchor-headroom-screen]].
