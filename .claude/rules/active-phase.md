# Active Phase Context

Phase: 84 — Hook & Registration Hygiene (READY FOR COMPLETION — delivery gate pending)
Objective: DONE — post-commit.sh restored via REDESIGN (event-arrival-as-success: PostToolUse
carries no exit-code field and does not fire for failing commands); detect-loop.sh filed UPSTREAM
(platform defect; counter unimplementable hook-side); eval-runner hermetic
(CLAUDE_PROJECT_DIR=$WORK_DIR) + lifecycle init_git; 11 ghost global registrations deregistered
after 6-root remediation (T4a checkpoint approved; end-state == modules.json scope:global set).
Scope: scripts/eval-runner.sh, templates/.claude/hooks/post-commit.sh, tests/**, eval/corpus/**,
eval/hook-hygiene/**; checkpoint-approved out-of-repo: ~/.claude/settings.json + 6 roots.
Constraints honored: instrument-first; capture-before-fix (3 evidence-forced branches); checkpoint
before live settings edits; legacy .exit_code fallback retained; 52 denominator unchanged
(2 explained flips); frozen apparatus + ledger read-only; positive control before matrix evidence.
Exit: 10/10 via eval/hook-hygiene/run-exit-criteria.sh; make test 25 scripts green; drift 0.
Next: accept delivery → gate flip + commit/push; then next direction (A5 memory-layer /
edge-screener dogfood / install-gap extra_dirs fix).
Gates:
- [x] Direction confirmed by user (assumption positions A1/A3/A5 accept, A2 deferred, A4 verified — 2026-06-09)
- [ ] Delivery accepted (post-implementation report)
