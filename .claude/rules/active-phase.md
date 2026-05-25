# Active Phase Context

Phase: 40 - install.sh Extraction & Anti-Pattern Hardening
Status: COMPLETED (7/7 tasks done, all exit criteria verified)
Objective: Decompose install.sh into modules.json + register-settings.py. Fix PostToolUse normalization gap. Codify functional smoke invariant. Clean up stale phase articles.

Results:
- install.sh: 542 to 318 lines (41% reduction), zero inline Python
- modules.json: 5 module groups, single source of truth
- register-settings.py: ~120 lines, hooks + mcp subcommands
- PostToolUse normalization: stale-queue.sh + post-commit.sh fixed
- Functional smoke invariant: codified in spec + dev-plan

Next: Run /dev-plan to start Phase 41.

Gates: [x] direction=approved [ ] delivery=pending
