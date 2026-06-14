---
title: "Phase 91 complete — Consuming-Project Memory E2E + Assumption-Gate Forcing Function"
aliases: []
category: journal
tags: [phase-91, memory, mcp, pythonpath, enforce-assumption-gate, hook, forcing-function, consumer-propagation, fix-then-judge]
parents: [phase-91-memory-e2e-and-gate-forcing-function]
created: 2026-06-14
updated: 2026-06-14
source: debrief
duration: ~3h
---

# Phase 91 complete — Consuming-Project Memory E2E + Assumption-Gate Forcing Function

## What Happened
- Two-track phase, 6 tasks (T1-T6) all [x]. **Track 3 (assumption-gate forcing function):** the dev-plan
  assumption gate was skipped a 3rd time despite the Phase-90 prose fix — caught by the maintainer this
  session, not the kit. Built `enforce-assumption-gate.sh` (PreToolUse Write|Edit|MultiEdit, mirrors
  enforce-spec) that BLOCKS implementation writes when the active phase has no valid assumption-ledger block.
  Hook-bound, not prose-only. The hook decision narrowed (DISCOVERY) from whole-file `--schema` + `--gate` to
  **`--gate` only** after whole-file `--schema` was shown to false-lock a properly-gated project (aml-substrate
  passes `--gate` for its active phase, fails whole-file `--schema` on prior-block format drift).
- **Track 1 (memory MCP E2E):** root-caused the consumer break — `python -m memory_server` resolves the
  package only from a cwd that CONTAINS it (only nana-dev-kit does), so the server was DEAD in every consumer
  (rc=1 "No module named memory_server" from a consumer cwd, rc=0 with PYTHONPATH). Fixed by adding an `env`
  `{PYTHONPATH: $HOME/.claude}` to the modules.json mcp block + teaching `register-settings.py` `cmd_mcp` to
  emit env; landed in BOTH `~/.claude/settings.json` AND the authoritative `~/.claude.json`. Verified by FIRING
  (T5): a consumer-context `memory_search` returns without error and `<project>/.memory/memory.db` is created.
  Per-project `.memory/` topology (gate A3) + gitignore shipped to 6 consumers + py-init/ts-init scaffold.
- **Spec discovery:** 3 exit-criteria assumptions were wrong vs the live machine (enforce hooks register
  per-project not in ~/.claude/settings.json; the template settings has no mcpServers block; there is no
  template .gitignore) — corrected to reality; the approved spec carries a post-approval discovery note.
- **Maintainer-directed propagation (USER OVERRIDE):** "apply updates to all consumer projects" — memory fix
  reaches all consumers (global config); gate armed in nana-dev-kit + aml-substrate, STAGED in 4 consumers
  (their active phases were never gated — arming would block existing work), signal-watch deferred (no kit hooks
  installed; needs install.sh --project-local).

## Decisions Made
- [[memory-mcp-consumer-e2e-fix|Memory MCP Consumer E2E Fix (fix-then-judge + PYTHONPATH env)]] -- repair the
  consumer break NOW so Phase 92 judges demand on a WORKING layer; couldn't-fire is inadmissible prune evidence.
- [[assumption-gate-hook-binding|Assumption-Gate Hook Binding (prose → enforce-assumption-gate.sh, --gate-only)]]
  -- bind the gate's firing with a deterministic boundary hook; supersedes Phase-81's "NO new hook" disposition.

## Open Questions
- **A4 deferred don't-know:** Phase-90's codifiable behaviors LANDED is not provably a Phase-90 EFFECT (no
  pre-90 opus baseline; the eval showed signal-watch fable exhibits the 5 natively). Track 2 dropped the "Track A
  effective" claim; the B2 pilot / pre-90 baseline is the measurement. Ledger A4 open — revisit at the B2 pilot.
- **DRQ-1:** do multiple PreToolUse hooks on one matcher each surface stderr, or only the first to exit 2?
  Mitigated by self-contained per-hook messages.
- 4 consumers have the gate STAGED-not-armed; signal-watch has no kit hooks (needs install.sh --project-local) —
  detail in Soft Observations + _CURRENT_STATE Blockers.

## Artifacts Changed
- `templates/.claude/hooks/enforce-assumption-gate.sh` + `~/.claude/hooks/` (NEW, 18th hook) + `tests/test_enforce_assumption_gate.sh` (NEW, 7 cases)
- `scripts/register-settings.py` (cmd_mcp env emission) + `modules.json` (hook entry + mcp env) + `MANIFEST` (4 checksums)
- `templates/.claude/settings.json` + `~/.claude/settings.json` + `~/.claude.json` (regen: hook reg + mcp env)
- `templates/.claude/skills/dev-plan/{SKILL.md,assumption-gate.md}` (HARD-GATE names the hook) + `.claude/rules/working-knowledge.md` (supersession note)
- consumer repos: 6 `.gitignore` (`.memory/`), 5 `.claude/hooks`+scripts+settings, py-init/ts-init scaffold

## Related
- [[phase-91-memory-e2e-and-gate-forcing-function|Phase 91]] -- parent phase
- [[assumption-approval-gate]] (Phase 81 — the gate this binds), [[assumption-gate-direction-filter]] (Phase-90
  follow-on — the gate's content filter), [[memory-layer-prune-round]] (Phase 92 — now judges a working layer)

## Review Gate

Unified reviewer (Standard ceremony, post-implementation): **8/10 → revise**. Code praised — mirrors `enforce-spec` faithfully, fail-open paths sound, shell-safe under `set -euo pipefail`, the `--gate`-only tradeoff "honestly reasoned," verify-by-firing (HEU-012), single-source registration. Revise driver: the spec's machine-checkable exit criteria still described three things the implementation deliberately does NOT do — the malformed-*current*-block block (superseded by `--gate`-only), the global `~/.claude/settings.json` registration (it is project-scoped), and the template `mcpServers` read-back (template is hooks-only; env lands in `~/.claude/settings.json` + `~/.claude.json`). **All three corrected inline** (source-text only, no code change) — the contract now matches what shipped, which is this phase's own thesis. One LOW noted (register-settings.py `expanduser` expands only a leading `~`; non-issue for the single `$HOME/.claude` value, relevant only if env values ever become path-lists).

## Soft Observations / Phase N+1 Candidates
- signal-watch lacks kit hooks entirely | the idempotent `install.sh` update / consuming-project re-sync mode
  (the ORIGINAL Phase-91 scope, still unbuilt) is the right next phase — it would also backfill the gate to the
  4 staged consumers | _CURRENT_STATE Blockers + Recommended Next Action.
- Spec exit criteria assumed kit structures that differ from the live machine (3 wrong) | future specs touching
  install/registration should verify assumptions against the live machine before pinning exit criteria | this
  session's spec discovery note.
- Consumer assumption-ledgers carry format drift (old blocks fail strict --schema) | a normalization/migration
  pass is a candidate cleanup (also unblocks whole-file --schema enforcement if ever wanted) | tasks_discovered.
- The memory layer now FIRES in consumers | Phase 92's prune must re-measure demand on the working layer (its
  prior "zero use" was couldn't-fire, now inadmissible) | [[memory-layer-prune-round]].
- Two-gate review caught a real gap (register-settings env support) at 4/10 reject → revised → 8/10 | the review
  gate earned its keep this phase.
