---
title: "Phase 62: Harden Hot-Cache Curation"
aliases: ["phase-62", "harden-hot-cache-curation", "hot-cache-curation-quality"]
category: phases
tags: [memory, hot-cache, working-knowledge, curation, eviction, dedup, deterministic, context-engineering]
parents: [phase-61-validate-memory-knowledge-integration]
created: 2026-05-29
updated: 2026-05-29
source: plan
status: completed
scope:
  - "templates/.claude/hooks/session-start.d/wk-prune.sh"
  - "tests/test_working_knowledge_curation.sh"
  - "Makefile"
  - "templates/.claude/skills/dev-wiki/working-knowledge-spec.md"
  - "templates/.claude/skills/dev-debrief/active-knowledge-transition.md"
  - "templates/.claude/skills/dev-plan/SKILL.md"
  - "templates/.claude/skills/dev-plan/compaction-anchors-spec.md"
  - ".claude/rules/working-knowledge.md"
entry_criteria: "Phase 61 complete + delivery accepted + committed (all 5 runtime-retrieval directions CUT; hot-cache identified as the effective retrieval layer with affirmative evidence). Approved spec specs/harden-hot-cache-curation.md (nana:approved 2026-05-29)."
exit_criteria: "Deterministic curator + invariant test land the cap/dedup/well-formedness/atomic-write invariants; wrong dedup key fixed; cap/dedup/eviction policy consolidated to one source of truth; make test >=13 scripts green + make eval at baseline; step-numbering test still passes; dogfood no-op on the live cache."
---

# Phase 62: Harden Hot-Cache Curation

## Objective

Make the always-loaded hot cache (`.claude/rules/working-knowledge.md`) enforce its own integrity invariants — size cap, no duplicate propositions, well-formedness, pinned-protection — **deterministically and test-covered**, replacing the unreliable LLM-executed prose that currently maintains it, and correct the dedup key (proposition content, not source slug). This is the one memory/knowledge direction with affirmative evidence: Phase 61 proved the hot cache IS the effective retrieval layer ([[hot-cache-is-the-effective-retrieval-layer]], [[two-tier-curate-into-hot-cache]]). No reasoning-eval — the invariant test is the validation, sidestepping the Phase-59 unmeasurability trap ([[harden-hot-cache-curation-deterministic]]).

## Scope

Files and modules affected:
- `templates/.claude/hooks/session-start.d/wk-prune.sh` — extend `prune_working_knowledge()` into the single curator (cap-enforce + exact-proposition dedup + well-formedness bail + atomic write)
- `tests/test_working_knowledge_curation.sh` — NEW invariant test
- `Makefile` — wire the new test into `make test`
- `templates/.claude/skills/dev-wiki/working-knowledge-spec.md` — single source of truth for the cap/dedup/eviction policy (fix the dedup key)
- `templates/.claude/skills/dev-debrief/active-knowledge-transition.md` — reference the spec instead of restating the algorithm
- `templates/.claude/skills/dev-plan/SKILL.md` (Step 16f-ter) — reference the spec (do NOT renumber steps)
- `templates/.claude/skills/dev-plan/compaction-anchors-spec.md` (eviction-rule row) — reference the spec
- `.claude/rules/working-knowledge.md` — dogfood target (read-only verify)

## Exit Criteria

- [x] `bash tests/test_working_knowledge_curation.sh` passes: over-cap→cull to ≤100 oldest-first; `[pinned]` never evicted (incl. all-pinned-over-cap → pins win + warning); exact-dup→removed keeping max `uses`; distinct-facts-same-slug→NOT collapsed; malformed→whole-file no-op + warning; exactly-100→no-op; idempotent second run; existing >30d prune still works (11/11)
- [x] `grep -rEn "increment .?uses.? instead" templates/` returns nothing (wrong directive removed from all 4 touchpoints)
- [x] `grep -q "proposition text" templates/.claude/skills/dev-wiki/working-knowledge-spec.md` (corrected content-based dedup rule documented as single source of truth)
- [x] `make test` exits 0, output includes `test_working_knowledge_curation.sh`, suite runs 13 scripts
- [x] `make eval` unchanged at baseline (54/54, 100%)
- [x] `bash tests/test_step_numbering.sh` still passes (no step-renumber side effects)
- [x] Dogfood: curator on the real `.claude/rules/working-knowledge.md` (at exactly 100) = byte-identical no-op, 0 evictions / 0 dup-removals, all distinct `phase-45` entries intact

## Constraints

- Atomic write (temp file + structural validation + atomic rename); abort byte-intact on any validation failure — prevents shipping a truncated mandatory file to every project ([[curator-fail-safe-atomic]]).
- Never evict or alter a `[pinned]` entry; assert `(evicted ∩ pinned) = ∅`. If pins alone exceed the cap, pins win (cap exceeded + warning) — prevents overriding explicit human keeps.
- Dedup keys on normalized proposition text, never the `source:` slug — prevents collapsing distinct facts sharing a source phase (proven live: `phase-45` ×6) ([[dedup-key-proposition-not-slug]]).
- Any 2-line pairing failure → whole-file no-op + warning, byte-intact — no per-entry repair on a mandatory file.
- Cap is NON-STRICT: exactly 100 entries and ≤210 lines = no-op. Entry-count bound (≤100) is primary.
- Preserve the exact `[uses: N]` and `activated: YYYY-MM-DD` token format (other machinery parses them); idempotent; empty/absent file = clean no-op.
- All edits land in `templates/` (the `cp -r` install source). Do NOT renumber dev-plan steps (protects `tests/test_step_numbering.sh`).

## Checkpoints

- After the curator + test pass on synthetic fixtures, BEFORE running on the live cache: confirm the dogfood run is a no-op (file at exactly 100 = fixed point). If it would evict/remove anything, STOP — the logic is wrong.
- If well-formedness parsing reveals the live file violates the 2-line invariant: STOP and report (do not auto-fix a mandatory file).

## Outcome

READY FOR COMPLETION (4/4 tasks [x]; all exit criteria met — status held `active` pending the user's delivery-gate confirmation). The deterministic curator (`wk-prune.sh` extended: cap-enforce + exact-proposition dedup + well-formedness whole-file bail + atomic validate-temp→rename) landed with an 11-test invariant suite (`make test` 12→13 scripts), the wrong slug-dedup key was fixed across all 4 touchpoints + the policy consolidated into `working-knowledge-spec.md`, and the dogfood run on the live cache was a byte-identical no-op. Build constraint: bash-3.2-safe wrapper + inline python3 (macOS floor + `cp -r` blast radius). No new decisions surfaced. Phase-63 candidate: eviction value-signal (usage counter empirically inert ⇒ cap-eviction is de-facto recency). See [[2026-05-29-phase-62-harden-hot-cache-curation-complete]].

## Notes

Motivation is the documented cap-erosion anti-pattern (Phase 55: session-start.sh's 70-line cap eroded to 137 over 30 phases with no test catching it) — "caps need test assertions, not just documentation." Live-file evidence at planning time: the project cache is at 100 entries / 203 lines (cap 100 / 210), 87 of 100 at `[uses:1]` (usage counter empirically inert ⇒ eviction degenerates to recency among the floor), and the slug-keyed dedup rule is wrong-when-followed (12 duplicate `source:` slugs present). The curator extends the existing prune hook rather than adding one ([[extend-wk-prune-not-new-hook]]).
