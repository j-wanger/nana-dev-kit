---
title: "Phase 79: Harness Hygiene (hook path resolution + working-knowledge size cap)"
aliases: ["harness-hygiene", "phase-79-harness-hygiene"]
category: phases
tags: [hooks, settings, claude-project-dir, working-knowledge, curator, dogfood, harden]
parents: []
created: 2026-06-04
updated: 2026-06-04
source: plan
status: active
scope: ["scripts/register-settings.py", "templates/.claude/settings.json", "templates/.claude/hooks/**", ".claude/rules/working-knowledge.md", "tests/**", "specs/phase-79-harness-hygiene.md", ".dev-wiki/articles/**"]
entry_criteria: "Phase 78 complete/accepted. Two real defects: (A) edge-screener Stop hooks fail with No-such-file because hooks use bare relative paths + Claude Code doesn't guarantee CWD=root; (B) working-knowledge.md at 45k chars trips the context-size warning because the curator caps count/lines not size."
exit_criteria: "No bare-relative hook command in the regenerated settings.json (project hooks use ${CLAUDE_PROJECT_DIR}); make template idempotent; a hermetic wrong-CWD hook-resolution test passes; every project hook cds to $CLAUDE_PROJECT_DIR; working-knowledge.md < 38k chars (4 amplifier entries → 1) + well-formed; wk-prune size advisory fires over-cap / silent under-cap / mutates nothing; make test + make eval green."
---

# Phase 79: Harness Hygiene

## Objective
Fix two kit-hardening defects degrading real sessions: (A) bare-relative hook paths 404 when Claude Code
runs hooks from a non-root CWD (edge-screener dogfood); (B) the always-loaded `working-knowledge.md` has
bloated to ~45k chars because the curator caps count/lines, not size. The 4th dogfood→harden fix.

## Scope
- `scripts/register-settings.py`, `templates/.claude/settings.json` (regenerated) — hook commands use
  `${CLAUDE_PROJECT_DIR}/.claude/hooks/X.sh` (project) / `$HOME/.claude/hooks/X.sh` (global).
- `templates/.claude/hooks/*.sh` (project-scoped) — `cd "${CLAUDE_PROJECT_DIR:-.}"` near the top.
- `.claude/rules/working-knowledge.md` — compress 4 amplifier entries → 1 + pointers.
- `templates/.claude/hooks/session-start.d/wk-prune.sh` — per-entry char-cap advisory + size report.
- `tests/**` — settings-drift, wrong-CWD resolution, firing-coverage, curator size test.

## Exit Criteria
- [ ] `! jq -r '.hooks[][].hooks[].command' templates/.claude/settings.json | grep -q '^\.claude/hooks/'` (no bare relative) and project hooks use `${CLAUDE_PROJECT_DIR}/.claude/hooks/`
- [ ] `make template` idempotent + `bash tests/test_settings_template.sh`
- [ ] hermetic wrong-CWD hook-resolution test passes (hook runs from non-root CWD via `$CLAUDE_PROJECT_DIR`)
- [ ] every project hook contains `cd "${CLAUDE_PROJECT_DIR` (or guarded equivalent)
- [ ] `working-knowledge.md` < 38k chars (4 amplifier entries → 1) + curator dry-run does not bail
- [ ] `wk-prune.sh` size advisory: fires over-cap, silent under-cap, mutates nothing (test)
- [ ] `make test` green + `make eval` green

## Constraints
- Fail-open / non-destructive: size cap WARNS (never truncates/evicts); hook cd uses `|| true`.
- No bare-relative hook command may remain (assert in drift test).
- Hermetic tests only (mktemp -d + env override; never touch real ~/.claude or live working-knowledge).
- modules.json single source of truth; settings.json regenerated never hand-edited.
- Firing-coverage invariant preserved (cd change drops no coverage).
- edge-screener untouched (kit-source fix; consuming project re-syncs later).

## Checkpoints
- After A1: settings-drift → fix the generator, don't hand-edit settings.json.
- After A2: any firing-test regression from the cd → fix that hook before proceeding.
- After B1: curator dry-run bails on the compressed file → entry malformed, fix before B2.

## Assumptions
- `${CLAUDE_PROJECT_DIR}` resolves correctly in real sessions (docs + /tmp sim). A mis-resolved project
  dir is a Claude Code config issue outside kit control (test cannot cover; known limit).
- `cd "$CLAUDE_PROJECT_DIR"` is harmless for stdin-path hooks (absolute paths); exempt with a comment if not.
- The amplifier finding is fully preserved in 4 dev-wiki decision articles + journals.

## Notes
Bundled per Jake's choice (harness hygiene = robust always-run hooks + terse always-loaded knowledge).
Subtraction framing (prune hooks/entries on value grounds) deferred — this hardens, does not shrink-by-
deletion. A2 (17-hook cd) is the L and the risk; A1 stops the visible errors, A2 makes hooks actually
function under drift.
