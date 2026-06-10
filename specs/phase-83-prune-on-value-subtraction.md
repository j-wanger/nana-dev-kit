<!-- nana:approved 2026-06-09 -->
# Spec: Phase 83 — Prune-on-Value Subtraction

## Objective

Apply the subtraction test to the kit surface Phase 82 proved unused or never-firing: each of the 6 evidenced dead-weight candidates gets a keep / cut / harden / disable-at-boundary verdict grounded in the Phase-82 utilization evidence, and every cut removes the component AND its registrations, tests, MANIFEST checksums, and doc references atomically, with `make test` + `make eval` green at the reduced surface.

## Context

Phase 79 parked a prune-on-value item ("which of the 17 hooks / ~100 working-knowledge entries earn their keep?") with re-trigger "a prune-on-value subtraction phase." Phase 82's QA sweep armed it: the usage-area audit (verification-matrix.md `usage` rows + repro-runs.log) produced a subtraction-review list filed in `_CURRENT_STATE.md` Blockers — enforce-memory.sh has ZERO lifetime firings anywhere; the memory reinforcement machinery has 0 reinforcements across 55 entries; the memory MCP server is never called by the one real consuming project (edge-screener); audit-log's `model` field is always "unknown" (CLAUDE_MODEL never set by the harness); 3 orphan companions are pinned exemptions in test_companions.sh Direction C; harness-audit.sh is unwired. The precedent is Phase 72 ([[cash-compaction-recovery-subtraction]]): confirm-truly-dead first, subtraction over construction. The kit's history of 4 multi-phase registered-but-dormant breakages cuts BOTH ways here: it motivates shrinking the surface, and it warns that a "never fired" zero can measure broken plumbing rather than absent demand (enforcement itself was dormant 15 days; the memory MCP CWD was mis-pointed for ~34 phases). The kit installs copies into `~/.claude` and consuming projects, so a repo-side cut does not deregister installed copies.

## Scope

### In scope

The 6 Phase-82-evidenced candidates, each consuming its named matrix row / Blockers filing:

1. `enforce-memory.sh` (matrix: usage-enforce-memory-zero-lifetime-firings) — opt-in layer never opted into.
2. Memory reinforcement machinery in the vendored `memory_server/` (matrix: usage-memory-reinforcement-machinery-unused) — 0 reinforcements / 55 entries.
3. Memory-MCP-in-consuming-project shipping decision (matrix: usage-memory-mcp-unused-in-consuming-project) — verdict on whether the scaffold path keeps shipping it, NOT on the kit's own use (55 live entries).
4. audit-log `model` field (matrix: usage-audit-log-model-field-always-unknown) — fix-the-env-var vs drop-the-field; audit-log itself is constrained KEEP by [[audit-log-disposition]] (Phase 66).
5. The 3 orphan companions (dev-wiki/stale-queue-spec.md, knowledge-wiki/registry-schema.md, knowledge-wiki/session-context.md) + their pinned exemptions in test_companions.sh Direction C.
6. `harness-audit.sh` (unwired).

Plus, for every CUT verdict: the removal set (component, modules.json entry, settings regeneration, tests, MANIFEST checksums, README/doc refs) and installed-surface deregistration verification (`~/.claude`, edge-screener).

### Out of scope

- Working-knowledge entry pruning (~100 entries) — different evidence model (self-reported `[uses:]` counters, always-loaded blast radius); re-file, do not fold in.
- A fresh full-surface utilization audit of all 17 hooks — Phase 82 already defined the evidenced list; gathering new evidence is a different phase.
- The 4 deferred firing-defect candidates and the 11 ghost global registrations (Phase-82 `firing`/`drift` Blockers) — EXCEPT where a cut's own deregistration touches them; cite the filing when it does.
- Frozen apparatus: `eval/amplifier/**`, `eval/assumption-screen/**`, `eval/qa-sweep/**` (the evidence source), `.dev-wiki/assumption-ledger.md` — read-only; a cut whose removal set requires editing them is blocked by construction → defer with filing.
- Upstream memory_server feature work; consuming-project re-syncs beyond verifying deregistration.

## Approach

Evidence-first, verdict-gated, serialized cuts. Build a per-candidate verdict table BEFORE touching anything: for each candidate, classify its zero as **couldnt-fire vs didnt-fire** (spelled exactly so in the table; arm the precondition in a `mktemp -d` sandbox — opt-in marker, env var, seeded near-duplicate store — pipe a synthetic trigger, observe firing; a component that won't fire even when armed is a DEFECT finding, not demand evidence), define the removal set FIRST, then run liveness grep where alive = any reference from OUTSIDE the removal set (repo + `~/.claude` + the consuming project at `/Users/jwang/edge-screener`; record the grepped roots at the top of liveness-grep.log). Present the full verdict table to the maintainer mid-phase BEFORE any cut. Execute approved cuts serially, one commit per candidate with subject prefix `Phase 83 cut: <candidate>`, regenerating MANIFEST/settings per-cut and diffing the regenerated artifacts against the planned removal set (any extra deleted line fails the cut). Prefer disable-at-the-boundary over in-vendored-file deletion for memory_server candidates (near-zero upstream divergence is the vendoring contract).

Verdict execution semantics (closed enum):
- **cut** — remove the full removal set this phase, per-candidate commit.
- **disable-at-boundary** — remove the component's registration/exposure (settings entry, MCP registration, scaffold shipping) WITHOUT deleting code; same commit + deregistration discipline as a cut.
- **harden** — verdict + a filed follow-up task with re-trigger; implementation is OUT of this phase's scope unless the fix fits the per-cut commit discipline AND the maintainer approves it at the checkpoint.
- **keep** — re-affirmation with the evidence line that earned it; no change.

### Domain Research Questions

1. What is the expected base rate of reinforcement triggers for 55 diverse entries at cosine >0.90 — is 0/55 dormancy or the correct behavior of a working dedup gate?
2. What shape does the settings regeneration emit when a cut empties a matcher group, and does Claude Code's validation accept it?
3. Which documentation tiers reference each candidate (repo README/MANIFEST/wiki vs user-owned `~/.claude/rules/` files the repo cannot edit), and where is the atomic-cleanup boundary?

## Constraints (CRITICAL)

- Every verdict cites its specific Phase-82 matrix row or Blockers filing — prevents double-handling a component across phases with conflicting verdicts; evidence carrying the filed enforcement.log provenance hazard must not be a cut's sole anchor.
- Couldnt-fire vs didnt-fire classification is mandatory before any cut — prevents cutting a component whose trigger plumbing was broken during the measurement window (the kit's own dormancy history makes this the dominant hazard).
- Liveness grep semantics: removal set defined first; alive = references from outside it — prevents the false-alive trap (every registered component greps hot from its own test/manifest entries) AND the false-dead trap (grep scope must include `~/.claude` and edge-screener, not just the repo).
- Installed-surface deregistration is part of every cut — the settings merge is add/update-only, so a repo-side cut leaves ghost registrations pointing at deleted scripts that fail silently (fail-open) on every event; assert absence from installed settings + run `check-install-drift.sh` (pass 2b installed-presence) post-cut.
- One candidate per commit, MANIFEST/settings regenerated per-cut, regenerated-artifact diff ⊆ planned removal set — prevents wholesale regeneration from silently absorbing an accidental over-deletion into the new baseline.
- No hand-edits to generated artifacts (templates/.claude/settings.json via `make template`; MANIFEST via its generator) — single-source-of-truth invariant.
- memory_server/ verdict menu is keep / disable-at-boundary / cut-with-regenerated-patch; an in-file cut requires the patch series re-applying cleanly — prevents silent vendoring fork.
- Post-cut functional smoke on SURVIVING hooks (pipe a real event, assert firing), not presence checks — a malformed emptied matcher group can disable the remaining hooks, the exact 4-times-bitten failure class.
- Prior decisions bind: [[audit-log-disposition]] (audit-log stays), [[memory-architecture-classification]] (MCP memory is the voluntary layer), [[single-source-scope-tagged-hook-registration]].
- Zero cuts is a valid outcome — verdicts must be evidence-forced, not quota-driven.

## Success Vision

The kit's always-running surface shrinks (or is explicitly re-affirmed) with every verdict traceable to evidence: a reader of the verdict table can see, per candidate, what the zero meant (demand-absent vs plumbing-broken), what was removed or kept and why, and that nothing surviving was collaterally damaged. Installed copies and the repo agree afterward (drift 0). Cuts that touched user-visible counts (hook counts, skill lists) leave README/MANIFEST/working-knowledge consistent. The deferred residue (out-of-scope tiers, blocked-by-frozen-apparatus items) is filed with re-triggers, not silently dropped. The phase honors the posture: the burden of proof was on each component to earn its keep, and the proof standard was firing evidence, not vibes.

## Exit Criteria (machine-checkable)

Candidate row names are bare (unformatted) at line start in the verdict table, exactly one row each: enforce-memory, memory-reinforcement, memory-mcp-scaffold, audit-log-model-field, orphan-companions, harness-audit.

- [ ] `grep -oE '^\| (enforce-memory|memory-reinforcement|memory-mcp-scaffold|audit-log-model-field|orphan-companions|harness-audit) ' eval/prune-on-value/verdict-table.md | sort -u | wc -l | grep -qx 6` — verdict table exists with exactly the 6 candidate rows
- [ ] `! grep -E '^\| (enforce-memory|memory-reinforcement|memory-mcp-scaffold|audit-log-model-field|orphan-companions|harness-audit) ' eval/prune-on-value/verdict-table.md | grep -vE '\| (keep|cut|harden|disable-at-boundary) \|'` — NO candidate row lacks a closed-enum verdict (universal, not existential)
- [ ] `! grep -E '\| (cut|disable-at-boundary) \|' eval/prune-on-value/verdict-table.md | grep -vE 'couldnt-fire|didnt-fire'` — every cut/disable row carries its zero-classification (token spelled `couldnt-fire`/`didnt-fire`, no apostrophes, everywhere)
- [ ] `test -f eval/prune-on-value/liveness-grep.log && head -5 eval/prune-on-value/liveness-grep.log | grep -q edge-screener` — liveness evidence committed with grepped roots recorded
- [ ] `make test` — full suite green at reduced surface
- [ ] `make eval` — 52/52 (or updated denominator with the diff explained in the verdict table)
- [ ] `bash scripts/check-install-drift.sh` — exits 0 with drift 0 post-cuts
- [ ] `bash tests/test_settings_template.sh` — generated settings template matches modules.json (no hand-edits)
- [ ] `test "$(grep -c '^DEREG .*: absent$' eval/prune-on-value/liveness-grep.log)" -ge "$(grep -cE '\| (cut|disable-at-boundary) \|' eval/prune-on-value/verdict-table.md || true)"` — one `DEREG <name> <installed-root>: absent` log line per executed cut/disable (vacuously satisfied at zero cuts, which is a valid outcome)
- [ ] `test "$(git log --oneline --grep='^Phase 83 cut:' | wc -l | tr -d ' ')" = "$(grep -cE '\| (cut|disable-at-boundary) \|' eval/prune-on-value/verdict-table.md)"` — exactly one `Phase 83 cut:` commit per executed cut/disable (serialized, per-candidate; both sides 0 at zero cuts)

## Checkpoints

- After the verdict table is complete and BEFORE any cut: present the full table (candidate, evidence citation, zero-classification, proposed verdict, removal set) to the maintainer; cuts execute only on approval. Unconditional.
- If any candidate classifies as couldnt-fire (plumbing defect, not dead demand): STOP for that candidate, file as defect finding, report at the checkpoint — do not cut.
- If a removal set requires editing frozen apparatus or user-owned `~/.claude/rules/` files: defer that candidate with filing, report at the checkpoint.
- If a post-cut functional smoke on surviving hooks fails: revert that cut's commit before proceeding to the next candidate.

## Assumptions

- The Phase-82 usage evidence post-dates the enforcement restoration (enforce-memory's first-ever firing was verified post-fix), so the zeros measure demand, not the dormancy bug. If false for any candidate: re-measure in sandbox before verdict.
- `make template` + the MANIFEST generator cover all generated artifacts a cut touches. If false: fix the generator first (DEPENDENCY escape hatch), never hand-edit output.
- edge-screener is reachable read-only for installed-surface grep. If false: file the verification as deferred, do not block the phase.
- The kit's own 55 memory entries represent real voluntary-layer use that keeps the memory MCP itself out of cut scope (candidate 3 is the scaffold-shipping decision only). If false (entries are stale bridge spam): widen candidate 3 to the full memory layer ONLY via a new maintainer decision at the checkpoint, not unilaterally.
- The 3 orphan companions are truly unreferenced beyond their pinned test exemptions. If false (a SKILL.md Read-path resolves to one): reclassify as keep + un-orphan (fix the reference), file the test-exemption removal.
