---
title: "Phase 79 complete — Harness Hygiene: hooks → ${CLAUDE_PROJECT_DIR} + working-knowledge size cap"
aliases: ["2026-06-04-phase-79-harness-hygiene"]
category: journal
tags: [hooks, settings, claude-project-dir, working-knowledge, curator, dogfood, harden]
created: 2026-06-04
updated: 2026-06-04
---

# Phase 79 complete — Harness Hygiene

Two kit-hardening fixes that degrade real consuming-project sessions, bundled (Jake's choice). The 4th
dogfood→harden fix in the Ph74/75/76 line. make test all-passed, make eval 52/52, zero knowledge lost.

## (A) Hook path resolution — the edge-screener Stop-hook dogfood
edge-screener emitted `/bin/sh: .claude/hooks/enforce-loop.sh: No such file or directory` on every turn,
though the scripts were present, executable, valid-shebang, and ran fine from the project root. Root
cause (confirmed via claude-code-guide): **Claude Code does NOT guarantee CWD = project root for hooks**;
the kit shipped bare relative `.claude/hooks/X.sh` paths everywhere (register-settings.py + template), and
the hook scripts internally referenced `.dev-wiki/`/`.claude/` relative to CWD — so even fixing the
command path would leave them found-but-inert under CWD-drift.

Fix at the source: register-settings.py project-local default → `${CLAUDE_PROJECT_DIR}/.claude/hooks`
(global hooks were already absolute `~/.claude/hooks` — untouched); dropped the `--hooks-dir .claude/hooks`
override from the Makefile + install.sh (the file COPY still lands in `.claude/hooks`; only the registered
command absolutizes). All 17 project hooks gained `cd "${CLAUDE_PROJECT_DIR:-.}"` — the `:-.` fallback is a
no-op when unset, so existing tests (which cd into the fixture) are unaffected. **The unconfirmable live
check became a committed hermetic test**: from a wrong CWD the anchored command resolves and the bare path
fails (resolution), and session-start's drift advisory FIRES from a wrong CWD via the cd but stays silent
without the var (function — proving internal refs resolve). edge-screener was hand-patched this session
(interim); it re-syncs via install.sh once this lands (recorded as a deferral).

## (B) working-knowledge size cap — self-inflicted
`working-knowledge.md` had bloated to 45,217 chars / 99 entries, tripping Claude Code's context-size
warning. Root cause: the curator (`wk-prune.sh`) caps entry-count (100) and line-count (210) but **not
size** — its comment assumed "strict 2-line entries," but the 4 amplifier entries (Ph70/71/77/78) were
single mega-lines of 1,613–3,821 chars (~11k total, ~24% of the file), all restating the same finding.
Fix: compressed them → ONE dense entry + 4 dev-wiki pointers (**45,217 → 35,726 chars**, no knowledge lost
— detail lives in the decision articles, which are NOT always-loaded), restoring
[[decision:memory-architecture-classification]]. Added a NON-DESTRUCTIVE Stage-0 `size_audit` to the
curator (WK_MAX_ENTRY_CHARS=1500) that warns + reports total chars/tokens but never truncates/evicts/bails
— silent now (densest entry ~1244), fires only on future mega-entries. Terseness note added to both
seeding steps (dev-plan 15f-ter + dev-debrief active-knowledge-transition).

## Subtraction framing (deferred, recorded in T0)
Both problems stem from the harness having grown heavy (17 always-on hooks, 96 always-loaded entries) —
and the amplifier program repeatedly found harness machinery inert. The honest alternative was prune-on-
value, not harden. Jake chose harden; prune-on-value is recorded as a re-trigger if the harness stays heavy.

## Verification
make test "All tests passed"; make eval 52/52; test_settings_template (drift + no-bare-relative +
${CLAUDE_PROJECT_DIR}-anchored), test_harden 26/26 (+4 wrong-CWD), test_working_knowledge_curation 15/15
(+2 size), firing-coverage 21/21, registration 41/41. 4/4 tasks (B1 S / A1 M / A2 L / B2 M).
