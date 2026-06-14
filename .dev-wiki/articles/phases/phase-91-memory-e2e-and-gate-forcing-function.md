---
title: "Phase 91: Consuming-Project Memory E2E + Assumption-Gate Forcing Function"
aliases: [phase-91, phase-91-memory-e2e-and-gate-forcing-function]
category: phases
tags: [memory, mcp, pythonpath, enforce-assumption-gate, hook, forcing-function, consumer-propagation, fix-then-judge]
parents: []
created: 2026-06-14
updated: 2026-06-14
source: plan
status: active  # READY FOR COMPLETION — 6/6 tasks [x], make test ALL-PASS, ledger A1/A2/A3 held + A4 open; delivery gate pending (D3 flips post-commit; completion = user confirmation)
scope: ["templates/.claude/hooks/enforce-assumption-gate.sh", "tests/test_enforce_assumption_gate.sh", "scripts/register-settings.py", "modules.json", "templates/", "~/.claude (both-landings)", "docs/", "eval/"]
entry_criteria: "Phase 90 delivery accepted (f05280d) + assumption-gate direction-filter follow-on (9309fe0); the gate was skipped a 3rd time this session (re-trigger for the hook); the memory MCP consumer break root-caused via the real -m launch"
exit_criteria: "6 machine-checkable criteria (specs/phase-91-memory-e2e-and-gate-forcing-function.md): enforce-assumption-gate.sh fires (exit 2 no-block / 0 block); registered single-source + regen; both-landings; register-settings env emits PYTHONPATH; verify-by-firing memory_search in a consumer (DB created); template .memory/ gitignore + consumer memory-setup doc"
---

# Phase 91: Consuming-Project Memory E2E + Assumption-Gate Forcing Function

## Objective

Two narrow, independent tracks. **Track 3 (assumption-gate forcing function):** bind the dev-plan
assumption gate's FIRING with a deterministic hook — the Phase-90 prose fix did not bind (the gate was
skipped a 3rd time, caught by the maintainer). **Track 1 (memory MCP end-to-end in consumers):** repair the
consumer break so a future prune (Phase 92) judges memory-layer demand on a WORKING layer — "couldn't-fire"
is inadmissible prune evidence (fix-then-judge, gate A1). Track 2 (Phase-90 recovery continuation) was
DROPPED to a deferred don't-know (gate A4 — no pre-90 baseline; the B2 pilot is the measurement).

## Scope

- `templates/.claude/hooks/enforce-assumption-gate.sh` + `~/.claude/hooks/` (NEW, 18th project hook)
- `tests/test_enforce_assumption_gate.sh` (NEW, 7 firing cases)
- `scripts/register-settings.py` (cmd_mcp gains `env` emission) + `modules.json` (hook entry + mcp `env`)
- `templates/.claude/settings.json` + `~/.claude/settings.json` + `~/.claude.json` (regen: hook reg + mcp env)
- `MANIFEST` (4 checksums) + `templates/.claude/skills/dev-plan/{SKILL.md,assumption-gate.md}` (HARD-GATE names the hook)
- `.claude/rules/working-knowledge.md` (gate-now-hook-bound supersession note)
- consumer repos (USER OVERRIDE propagation): 6 `.gitignore`, 5 `.claude/hooks`+scripts+settings, py-init/ts-init scaffold

## Exit Criteria

- [x] The spec's 6 machine-checkable criteria (specs/phase-91-memory-e2e-and-gate-forcing-function.md) — make test ALL-PASS; T5 verify-by-firing confirmed (consumer memory_search returns, DB created); register-settings env emits PYTHONPATH; both-landings present.

## Constraints

- **Verify by FIRING, not presence** (HEU-012): the gate hook proven by exit-2/exit-0 firing; the memory fix proven by a real `-m` launch + a fired-consumer memory_search round-trip (STOP-on-fail).
- **--gate-only** (DISCOVERY): the hook decides via `check-assumption-ledger.sh --gate` ONLY — whole-file `--schema` false-locks a properly-gated project with prior-block format drift (verified on aml-substrate).
- **No-lockout consumer propagation** (HEU-012): arm the gate in a consumer ONLY where its active phase has a valid ledger block — staged elsewhere (would block existing work).
- **Fix-then-judge** (gate A1): repair the memory layer NOW so Phase 92 judges a working layer; per-project `.memory/` topology (gate A3), MEMORY_PROJECT_DIR not set.

## Outcome

6/6 tasks [x]. Track 1 + Track 3 shipped; Track 2 deferred (A4 open). Decisions
[[memory-mcp-consumer-e2e-fix]] (high), [[assumption-gate-hook-binding]] (high). Review gate 4/10 reject
(caught the missing register-settings env support) → revised → 8/10. Health: +1 test, hook count 16→17 in
modules.json (18 project hooks total), 4 MANIFEST checksums regenerated, `make test` ALL-PASS.

Discovered (route to next /dev-plan): the idempotent `install.sh` re-sync mode (ORIGINAL Phase-91 scope, still
unbuilt — signal-watch + 4 staged consumers need it); consumer ledger format-drift normalization; Phase-92
must re-measure memory demand on the now-working layer.

## Related

- [[memory-mcp-consumer-e2e-fix]], [[assumption-gate-hook-binding]] — this phase's decisions
- [[assumption-approval-gate]] (Phase 81, the gate this binds), [[assumption-gate-direction-filter]] (Phase-90
  follow-on, the gate's content filter), [[memory-layer-prune-round]] (Phase 92, now judges a working layer)
- [[2026-06-14-phase-91-memory-e2e-and-gate-forcing-function-complete]] — session journal
