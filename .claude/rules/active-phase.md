# Active Phase Context

Phase: 91 — Consuming-Project Memory E2E + Assumption-Gate Forcing Function (implemented 2026-06-14; READY FOR DELIVERY GATE)
Objective: (Track 3) bind the dev-plan assumption gate with a forcing-function hook so it cannot be
skipped — Phase-90's "fix" was prose and didn't bind (3rd skip); (Track 1) make Memory MCP actually fire
in consuming projects (root cause: `-m memory_server` resolves only from the package-bearing kit cwd;
fix = PYTHONPATH=$HOME/.claude env on the registration). Track 2 (recovery) DEFERRED per gate A4.
Status: implemented. 6/6 tasks [x]. Track 3 — enforce-assumption-gate.sh (PreToolUse Write|Edit|MultiEdit,
`--gate`-only, both-landings, 7 firing cases). Track 1 — register-settings.py cmd_mcp emits env +
modules.json mcp env; verified by FIRING a consumer memory_search (DB created). make test ALL-PASS.
Scope: enforce-assumption-gate.sh, modules.json, register-settings.py, dev-plan {assumption-gate,SKILL}.md,
tests/**, ~/.claude + ~/.claude.json landings, docs, consumer propagation (USER OVERRIDE), .dev-wiki records.
Key constraints: verify-by-FIRING not presence (HEU-012); `--gate`-only (whole-file --schema false-locks
properly-gated projects — aml-substrate); no-lockout consumer propagation (armed in kit+aml-substrate, staged
in 4 consumers, signal-watch deferred); fix-then-judge unblocks Phase-92's prune. Next: delivery → accept → push.
Standing (Phases 90-93): EVERY working session appends window-events attestation rows to
eval/dogfood-round/evidence/window-events.md until the Phase-93 trim-trial disposition. Attestation owed.
Gates:
- [x] Direction confirmed by user (assumption positions 2026-06-14: A1/A2/A3 accept held, A4 don't-know → deferred)
- [ ] Delivery accepted (post-implementation report)
