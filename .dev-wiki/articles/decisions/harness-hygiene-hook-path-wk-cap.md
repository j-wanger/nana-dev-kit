---
title: "Harness Hygiene — hook path resolution + working-knowledge size cap (Phase 79)"
aliases: ["harness-hygiene", "phase-79-harness-hygiene", "hook-path-resolution", "working-knowledge-size-cap"]
category: decisions
tags: [hooks, settings, claude-project-dir, working-knowledge, curator, dogfood, harden, consuming-project, edge-screener]
parents: []
created: 2026-06-04
updated: 2026-06-04
source: plan
confidence: high
status: active
---

# Harness Hygiene — hook path resolution + working-knowledge size cap (Phase 79)

## Decision
Bundle two kit-hardening fixes that degrade real sessions into one "harness hygiene" phase (Jake chose
bundled over two separate phases, AskUserQuestion 2026-06-04):

**(A) Hook path resolution.** The kit registers hooks with bare relative `.claude/hooks/X.sh`. Claude
Code does NOT guarantee CWD = project root for hooks, so consuming projects (edge-screener dogfood) hit
`No such file or directory` even though the scripts exist. Fix at the source: `register-settings.py` +
`templates/.claude/settings.json` emit `${CLAUDE_PROJECT_DIR}/.claude/hooks/X.sh` (project-scoped) /
`$HOME/.claude/hooks/X.sh` (global-scoped), AND the hook scripts `cd "${CLAUDE_PROJECT_DIR:-.}"` so their
internal CWD-relative refs resolve too (command-path fix alone leaves them found-but-inert). 4th
dogfood→harden fix (Ph74/75/76 line). The unconfirmable live check is converted into a committed
hermetic wrong-CWD test.

**(B) working-knowledge size cap.** The curator (`wk-prune.sh`) caps entry-count (100) + line-count (210)
but NOT size, so a few mega-entries (the 4 amplifier entries, ~11k chars / ~24% of a 45k file) blow the
always-loaded token budget and trip Claude Code's context-size warning. Fix: one-time compress the 4
amplifier entries into one dense entry + dev-wiki pointers, AND add a non-destructive per-entry char-cap
ADVISORY to the curator (warn, never truncate/evict). Restores the kit's memory-architecture principle
([[decision:memory-architecture-classification]]): terse always-loaded layer, detail in the dev-wiki.

## Why this framing
- **Source-fix, not symptom-patch** (Ph74 lineage): edge-screener's hand-patched settings.json would be
  overwritten on reinstall; the durable fix is in the generator + template + scripts.
- **Found-but-inert is a real bug**: fixing only the command path stops the visible error but leaves
  hooks silently non-functional under CWD-drift — so A2 (hook-internal cd) is in scope, not deferred.
- **Non-destructive curation**: the size cap is advisory because the curator is deterministic and cannot
  semantically compress; auto-truncating/evicting would lose findings. Humans (or a debrief) compress on
  the warning; the seeding steps get a terseness rule.
- **Compress, don't delete**: the amplifier finding is fully preserved in 4 dev-wiki decision articles +
  journals; the working-knowledge copies are redundant always-loaded weight.

## Verification strategy (gates the unconfirmable live check)
A hermetic test runs a representative hook from a wrong CWD (`mktemp -d`) with `CLAUDE_PROJECT_DIR` set to
a fixture project root and asserts it resolves + behaves — repeatable, independent of any live session.
Plus: settings-drift test (no bare relative path; `make template` idempotent), firing-coverage unchanged,
curator test (advisory fires over cap / silent under cap / mutates nothing), working-knowledge well-formed.

## Rejected / deferred
- **Prune hooks/entries on value grounds** (the subtraction framing surfaced in T0). A separate lever;
  this phase hardens the existing layer, it does not shrink-by-deletion. Re-trigger if the harness stays
  heavy after this.
- **Auto-truncate/evict over-cap working-knowledge entries** — destructive; advisory-only.
- **Defer A2** (ship A1+B, leave hooks CWD-fragile internally) — Jake approved the full approach incl. A2.
- **Re-sync edge-screener as part of this phase** — out of scope; the maintainer re-runs install.sh after.

## Caveats
- If a consuming session resolves the *project dir itself* wrongly, `${CLAUDE_PROJECT_DIR}` is wrong too
  and the fix is moot — a Claude Code config issue outside the kit's control; documented as a known limit
  (the hermetic test cannot cover it).
- The size cap is advisory; it prevents regression only insofar as the warning is heeded + the seeding
  steps stay terse.

## Result
**COMPLETE (2026-06-04). Both sub-fixes shipped; make test all-passed, make eval 52/52.**
- **(A) Hook path resolution.** register-settings.py project-local default → `${CLAUDE_PROJECT_DIR}/.claude/hooks`; dropped the `--hooks-dir .claude/hooks` override from the Makefile template target + install.sh --project-local (the file copy still uses `.claude/hooks`; only the registered command absolutizes). Global hooks were already absolute (`~/.claude/hooks`) — untouched. Regenerated template: all 17 project commands `${CLAUDE_PROJECT_DIR}`-anchored, `make template` idempotent. All 17 project hook scripts gained `cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true` (the `:-.` fallback makes it a no-op when unset, so existing tests are unaffected). **The unconfirmable live check is now a committed hermetic test**: from a wrong CWD, the `${CLAUDE_PROJECT_DIR}`-anchored command resolves while the bare path fails (resolution), AND session-start's drift advisory FIRES from a wrong CWD via the cd while staying silent without the var (function — internal refs resolve).
- **(B) working-knowledge size cap.** Compressed the 4 amplifier entries (Ph70/71/77/78) → 1 dense entry + 4 dev-wiki pointers: **45,217 → 35,726 chars** (99 → 96 entries), well-formed, no knowledge lost (detail in the decision articles). Added a NON-DESTRUCTIVE Stage-0 `size_audit` to wk-prune.sh (WK_MAX_ENTRY_CHARS=1500) that warns on over-cap entries + reports total chars/tokens, never truncating/evicting/bailing — silent now, fires only on future mega-entries. Terseness note added to both seeding steps (dev-plan 15f-ter + dev-debrief).
- **Verification:** test_settings_template (drift + no-bare-relative + ${CLAUDE_PROJECT_DIR}-anchored), test_harden (+4 wrong-CWD resolution+function tests, 26/26), test_working_knowledge_curation (+2 size tests, 15/15), firing-coverage 21/21, registration 41/41; make test all-passed; make eval 52/52. Confidence high. 4/4 tasks.

## Source
Phase 79 plan (2026-06-04). Direction approved by Jake ("approved"; bundled scope chosen via
AskUserQuestion). Sub-fix A surfaced from the edge-screener Stop-hook dogfood this session; sub-fix B from
the working-knowledge.md context-size warning. Successor in the dogfood→harden line ([[harden-consuming-project-scaffold]] Ph74, [[delivery-commit-verification]] Ph75, [[installed-copy-drift-guard]] Ph76).
