---
title: "Assumption-Gate Hook Binding (prose → enforce-assumption-gate.sh, --gate-only)"
aliases: ["assumption-gate-hook-binding", "enforce-assumption-gate", "assumption-gate-forcing-function"]
category: decisions
tags: [assumption-gate, enforcement, hook, pretooluse, forcing-function, no-lockout, prose-doesnt-bind, gate-only, phase-91]
parents: [phase-91-memory-e2e-and-gate-forcing-function]
created: 2026-06-14
updated: 2026-06-14
source: plan
confidence: high
status: active
---

# Assumption-Gate Hook Binding (Phase 91, Track 3)

## Context
The dev-plan assumption gate ([[assumption-approval-gate]], Phase 81) was SKIPPED a 3rd time this session —
caught by the maintainer, not the kit. The Phase-90 fix was prose (a HARD-GATE instruction in dev-plan
SKILL.md), and prose in a SKILL.md is advisory to the agent, not enforced. [[assumption-gate-direction-filter]]
(Phase-90 follow-on) sharpened the gate's CONTENT; this phase binds its FIRING. The Phase-81 decision
explicitly deferred a hook ("NO new hook — the debrief-finalization check is the firing point"); the 3rd skip
is the re-trigger that decision named.

## Decision
Build **`enforce-assumption-gate.sh`** — a PreToolUse `Write|Edit|MultiEdit` hook (the 18th project-scoped
hook) that mirrors `enforce-spec.sh`: opt-in via `.claude/enforce` OR `~/.claude/enforce`; `.dev-wiki`/`*.md`
allowlist; jq parse + project-relative normalize; parses the phase number from `.claude/rules/active-phase.md`;
**BLOCKS implementation writes (exit 2)** when the active phase has no valid assumption-ledger block. Hook-bound,
not prose-only. Registered single-source in modules.json (`make template` regenerates the settings + MANIFEST);
landed in both `templates/.claude/hooks/` and `~/.claude/hooks/`, verified by FIRING (exit 2 with no block, exit
0 with a block), never presence-only.

**--gate-only narrowing (DISCOVERY escape hatch).** The decision was narrowed from whole-file
`check-assumption-ledger.sh --schema` + `--gate` to **`--gate` ONLY**. Whole-file `--schema` false-BLOCKS a
PROPERLY-gated project when an OLDER/prior phase block has format drift — verified on aml-substrate: it passes
`--gate` for its active phase but fails whole-file `--schema`. `--gate` (a phase block with ≥1 position line)
catches the ACTUAL failure mode (skipping the gate for the active phase). Acknowledged limit: a determined agent
could hand-write a schema-valid all-accept block anyway — the hook enforces FIRING, not reasoning quality
(consistent with the gate's all-accept-warn design).

## Consequences
- The gate is now hook-bound; the working-knowledge note is superseded (gate is enforcement-backed, not
  prose-only). Phase-81's "NO new hook" disposition is superseded by this article (append-only — Phase-81's
  block is not rewritten).
- **Consumer-propagation safety (no-lockout, HEU-012):** arm the gate in a consumer ONLY where its active phase
  already has a valid ledger block. Armed in nana-dev-kit + aml-substrate; STAGED (hook+checker present, NOT
  armed) in 4 consumers (edge-screener ph9, edge-analyst ph10, ai-game ph3, fate ph2) whose active phases were
  never gated — arming would block existing work; they arm naturally on their next `/dev-plan`. signal-watch has
  no kit hooks installed at all (needs `install.sh --project-local` — the unbuilt Phase-91 re-sync scope).
- **DRQ-1 open:** when multiple PreToolUse hooks share one matcher (enforce-spec + enforce-assumption-gate), do
  they all surface stderr or only the first to exit 2? Mitigated by self-contained per-hook messages.
- Health: +1 test (`tests/test_enforce_assumption_gate.sh`, 7 firing cases); `test_install.sh` hook count
  16→17; README reconciled (18 total / 17 project-scoped, modules.json authoritative); 4 MANIFEST checksums
  regenerated.

## Rejected Alternatives
- **More prose** — the measured failure mode (3rd skip); a deterministic boundary hook is the lever.
- **Whole-file `--schema` enforcement** — false-locks properly-gated projects with prior-block drift
  (aml-substrate evidence); `--gate` for the active phase is the right scope.
- **A semantically strict gate (block all-accept / weak assumptions)** — out of scope; the hook enforces firing,
  the dev-plan gate + [[assumption-gate-direction-filter]] handle content.

## Source
[[assumption-approval-gate]], [[assumption-gate-direction-filter]], [[HEU-012]]
