---
source_type: session
source_path: conversation
ingested: 2026-06-10T14:30:00
---

# Raw: Headless Probe Sessions for Undocumented Platform Semantics

## Context

nana-dev-kit Phase 85: before migrating a consuming project's hand-patched hook registrations,
the plan assumed duplicate registrations across settings.json + settings.local.json would
double-fire. The assumption was gated behind a mandatory empirical verification (DRQ-1) instead
of being acted on — and it was wrong.

## Insight

When a design depends on an undocumented platform behavior (config merge, precedence, dedupe
semantics on an agent platform), don't argue from docs or assumption — build a disposable
mktemp sandbox project that encodes the question as observable side effects (file-append
counters per hook firing), run one cheap headless agent session per probe
(`claude -p "Reply ok" --model haiku`), and read the answer off the counters. Every run must
carry a positive control (a solo-registered hook known to fire, asserted to produce exactly one
row) so a zero reads as instrument failure, not as the answer. Expected (not yet demonstrated)
to generalize to any hook/config-merge/precedence question on agent platforms.

## Evidence

Worked example (version-pinned: Claude Code, 2026-06-10 — a platform behavior, not a guarantee):
probe 1, identical command string in both settings files → 1 firing (dedupe); probe 2, two
DIFFERENT command strings invoking the same script → 2 firings. Verdict: dedupe is STRING-KEYED,
so double-fire is conditional on form mismatch. Control hook fired exactly once in every run.
Cost: two haiku headless sessions, ~1 minute each. The verdict reframed the migration from
urgent correctness fix to hygiene and marked the assumption-ledger row `bit` — the guard caught
a wrong working model before any live surgery. Record: nana-dev-kit
eval/install-gap/drq1-verification.md (commit 3f04979). Related: HEU-004 (functional smoke),
HEU-012 (verify firing, not presence), IRON-001 (measure before optimizing).
