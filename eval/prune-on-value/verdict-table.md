# Phase 83 — Prune-on-Value Verdict Table

Evidence: eval/qa-sweep/verification-matrix.md rows L93-96 + L54-56/L79 + repro-runs.log + this dir's
liveness-grep.log / arming-runs.log. Verdict enum: keep / cut / harden / disable-at-boundary.
zero-class enum: couldnt-fire / didnt-fire (filled by T2 arming; couldnt-fire rows are DEFECT findings —
presented at the T3 checkpoint with no cut offered, maintainer may override).
Proposed verdicts are evidence-forced drafts pending the T3 checkpoint; final cells reflect approved verdicts.

| candidate | matrix-row | arming-procedure | zero-class | proposed-verdict | removal-set |
|---|---|---|---|---|---|
| enforce-memory | usage-enforce-memory-zero-lifetime-firings | sandbox: arm marker + pipe PreToolUse Write event, assert exit 2 (block) AND exit 0 (allow path); check post-restoration enforcement.log firings | couldnt-fire | keep | (if cut) templates hook; modules.json L53 entry + L39 marker decl; 3 eval scenarios (52→49); refs in test_settings_template/test_tooluse_hooks/test_install/test_firing_log/test_templates; MANIFEST; README; installed: 6 hookfile copies, 3 registrations (~/.claude, edge-screener, edge-analyst), ~/.claude/enforce-memory marker |
| memory-reinforcement | usage-memory-reinforcement-machinery-unused | A7 triple: exact-dup store→reinforced; near-dup→warn-not-reinforce on live no-fastembed path; sandbox venv WITH fastembed→cosine reinforce | couldnt-fire | harden | N/A (vendored code untouched; filing: install fastembed OR document warn-only as the de facto contract) |
| memory-mcp-scaffold | usage-memory-mcp-unused-in-consuming-project | shipping-surface inventory (T1, complete): py-init/ts-init ship nothing memory-specific; no per-project surface exists | didnt-fire | keep | N/A (no per-project surface; DEREG artifact: none exists; kit-side layer value = A5 deferred Blocker, must-revisit) |
| audit-log-model-field | usage-audit-log-model-field-always-unknown | sandbox: CLAUDE_MODEL=test pipe event → assert model captured (plumbing works); unset → "unknown" (source never provided) | couldnt-fire | cut | audit-log.sh L19 MODEL= line + L24 --arg model + jq field; any test asserting model field; audit-log itself STAYS ([[audit-log-disposition]]) |
| orphan-companions | qa-sweep orphan rows L54-56 | Read-path resolution over all SKILL.md files (T1: zero live refs) | didnt-fire | cut | 3 files (dev-wiki/stale-queue-spec.md, knowledge-wiki/registry-schema.md, knowledge-wiki/session-context.md); ORPHAN_EXEMPT entries in tests/test_companions.sh L101; 3 MANIFEST checksums |
| harness-audit | coverage-harness-audit-script-untested-unwired | direct run in sandbox (does it even execute?); invocation grep (zero invokers) | didnt-fire | harden | scripts/harness-audit.sh; tests/test_scripts_smoke.sh entry; MANIFEST; (out-of-boundary FILED: ~/.claude/rules/dev-wiki-hooks.md "/dev-harness H6" ref — user-owned, not edited) |

## T1 findings that reframe candidates (for the T3 checkpoint)

1. **enforce-memory is NOT "opt-in never opted into"** — modules.json L39 declares `~/.claude/enforce-memory`
   as a SHIPPED marker; install.sh created it 2026-05-28. The lifetime zero is the event-shape dormancy
   (couldnt-fire era, fixed in Phase 82). Post-restoration it is CONFIRMED LIVE: 69 enforcement.log records
   including phase:83 block+allow entries written during this very session. Proposed keep (it works and is
   working); Jake may override to cut as a demand-owner call ("I never asked for this nudge").
2. **A3 reject vindicated**: 4 consuming projects discovered beyond the assumed roots (stock-screener,
   edge-analyst, fate, ai-game); edge-analyst has enforce-memory REGISTERED — any cut's DEREG set grew.
3. **Candidate 3 collapses structurally**: nothing memory-specific ships per-project; zero .memory DBs in
   all 5 consuming projects; nothing to disable at the boundary → keep + A5 deferred Blocker.

## Checkpoint decisions

Presented 2026-06-09 via AskUserQuestion, BEFORE any cut. couldnt-fire rows presented as defect findings.

- enforce-memory: approved 2026-06-09 — keep (confirmed live; demand question revisits with real firing data)
- memory-reinforcement: override 2026-06-09 — harden WITH approved implementation: install fastembed into the live venv now (<= per-cut discipline; vendored code untouched), verify cosine reinforcement live
- memory-mcp-scaffold: approved 2026-06-09 — keep (no per-project surface; layer-value question stays A5 deferred must-revisit)
- audit-log-model-field: override 2026-06-09 — cut the field now (S, field-level; audit-log itself stays per [[audit-log-disposition]])
- orphan-companions: approved 2026-06-09 — cut (3 files + ORPHAN_EXEMPT entries + 3 MANIFEST checksums; installed copies removed too)
- harness-audit: override 2026-06-09 — harden: wire it in (keep + register + functional test) instead of cut

## Close-out (2026-06-09)

| area | command | evidence | verdict |
|---|---|---|---|
| exit criteria | bash eval/prune-on-value/run-exit-criteria.sh | 10/10 PASS | clean |
| test suite | make test | All tests passed (22 scripts; companions Direction C now stricter — exemption list emptied) | clean |
| eval corpus | make eval | 52/52 (denominator UNCHANGED — enforce-memory kept, its 3 scenarios live) | clean |
| install drift | bash scripts/check-install-drift.sh | exit 0 (installed copies refreshed with the model-field cut) | clean |
| settings template | bash tests/test_settings_template.sh | green (modules.json untouched — no hook was cut) | clean |

Outcome: 6 verdicts — 2 cuts executed (audit-log-model-field, orphan-companions: -200 repo lines,
23 installed-surface assertions: 5 project audit-log copies refreshed + 18 orphan files removed across 6 roots), 2 keeps (enforce-memory: couldnt-fire, now live;
memory-mcp-scaffold: no per-project surface), 2 hardens IMPLEMENTED via checkpoint override
(fastembed installed → cosine reinforcement live; harness-audit wired as `make audit` + functional smoke).
4 of 6 Phase-82 "dead-weight" zeros were measurement artifacts (couldnt-fire / no-surface), not absent
demand — the couldnt-fire-vs-didnt-fire gate earned its keep. Zero cuts would also have been valid;
two were evidence-forced.
