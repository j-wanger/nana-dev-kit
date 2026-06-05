<!-- nana:approved 2026-06-04 -->
# Spec: Phase 79 — Harness Hygiene (hook path resolution + working-knowledge size cap)

## Objective
Fix two kit-hardening defects that degrade real consuming-project sessions: (A) hooks registered with
bare relative `.claude/hooks/X.sh` paths fail (`No such file or directory`) when Claude Code runs them
from a non-project-root CWD; (B) the always-loaded `working-knowledge.md` has bloated to ~45k chars /
~11k tokens because the curator caps by entry-count/line-count, not size, and a few mega-entries slip
through — triggering Claude Code's context-size warning every session.

## Context
- **(A) dogfood:** edge-screener (the real consuming project) emitted 4+ Stop-hook errors —
  `/bin/sh: .claude/hooks/enforce-loop.sh: No such file or directory` — although the scripts are
  present, executable, valid-shebang, and run fine from the project root. Confirmed root cause: Claude
  Code does NOT guarantee CWD = project root for hooks; the documented fix is `${CLAUDE_PROJECT_DIR}/...`
  (expanded before execution AND exported to the hook env). The kit ships bare relative paths everywhere
  (`register-settings.py`, `templates/.claude/settings.json`) and the hook scripts internally reference
  `.dev-wiki/`, `.claude/` relative to CWD — so fixing only the command path leaves them found-but-inert
  under CWD-drift. edge-screener's `settings.json` was hand-patched this session (interim; a reinstall
  would overwrite it — the durable fix is here). 4th dogfood→harden fix in the Ph74/75/76 line.
- **(B) self-inflicted:** `working-knowledge.md` = 45,217 chars / 99 entries. The curator
  (`session-start.d/wk-prune.sh`) caps WK_MAX_ENTRIES=100 and WK_MAX_LINES=210, with a comment assuming
  "strict 2-line entries." But the 4 amplifier entries (Ph70/71/77/78) are single mega-lines of
  1,613 / 2,332 / 3,259 / 3,821 chars (~11k total, ~24% of the file), all restating the same finding.
  They pass the count/line caps while blowing the token budget. Violates the kit's own memory-architecture
  principle ([[decision:memory-architecture-classification]]): the always-loaded layer should be terse
  pointers; detail belongs in the dev-wiki (decision articles + journals), which is NOT always-loaded.

## Scope
### In scope
- `scripts/register-settings.py` — emit `${CLAUDE_PROJECT_DIR}/.claude/hooks/X.sh` for project-scoped
  hooks; `$HOME/.claude/hooks/X.sh` for global-scoped hooks; regenerate `templates/.claude/settings.json`.
- `templates/.claude/hooks/*.sh` (project-scoped) — `cd "${CLAUDE_PROJECT_DIR:-.}"` near the top so
  internal CWD-relative references resolve under drift.
- `.claude/rules/working-knowledge.md` — one-time compression of the 4 amplifier entries into one dense
  entry + the four `[[decision:…]]` pointers.
- `templates/.claude/hooks/session-start.d/wk-prune.sh` — add a per-entry char-cap ADVISORY (warn,
  non-destructive) + total-size report; count/line caps unchanged.
- Tests: `test_settings_template.sh` (drift), a wrong-CWD hook-resolution test, firing-coverage,
  wk-prune curator tests, working-knowledge well-formedness.
- A terseness note in the dev-plan/dev-debrief working-knowledge seeding steps.

### Out of scope
- Pruning/removing hooks or working-knowledge entries on value grounds (the subtraction framing) — a
  separate lever; this phase makes the existing layer robust + terse, not smaller-by-deletion.
- Re-syncing edge-screener (the maintainer re-runs install.sh after this lands; the interim hand-patch holds).
- The global hook's own internal CWD assumptions (context-size-check is stdin-driven; no project refs).
- Auto-truncating or evicting over-long working-knowledge entries (destructive; advisory-only here).

## Approach
- **A1 — Generator + template (the find-the-script fix).** `register-settings.py` builds each hook
  command; prefix project-scoped hook scripts with `${CLAUDE_PROJECT_DIR}/` and global-scoped with
  `$HOME/` (or the documented absolute form). Regenerate `templates/.claude/settings.json` via
  `make template`. Update `test_settings_template.sh` expected output; add an assertion that NO hook
  command is a bare relative `.claude/hooks/...` path. Add a hermetic wrong-CWD test: run a representative
  hook from `mktemp -d` with `CLAUDE_PROJECT_DIR` set to a fixture project root and assert it resolves
  (exit 0, expected behavior) — converting the unconfirmable live check into a repeatable test.
- **A2 — Hook-internal CWD (the make-it-actually-work fix).** Add `cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true`
  near the top of each project-scoped hook (after `set -...`, before any project-relative reference), so
  `.dev-wiki/`/`.claude/` refs resolve regardless of launch CWD. For hooks that read tool-input paths
  from stdin (scan-secrets, block-dangerous-bash, auto-ruff-format, audit-log), verify the cd is harmless
  (those paths are absolute). session-start.sh computes `HOOK_DIR` from `$0` BEFORE the cd, so its
  `source` lines are unaffected. Firing-coverage stays green; every hook's firing test still passes.
- **B1 — Compress (immediate relief).** Replace the 4 amplifier entries in `working-knowledge.md` with
  ONE dense `[uses: 2]` entry capturing the cross-program finding ("harness headroom does NOT live in
  re-presenting what the model can recover — decisions Ph70/71/77 nor recoverable-goal tooling Ph78;
  surviving avenue = genuinely proprietary/post-cutoff") + the four `source:` `[[decision:…]]` pointers.
  ~45k → ~35k chars. Well-formed (`- [uses: N] …` + `source:`) so the curator preserves it.
- **B2 — Curator size advisory (prevent regression).** `wk-prune.sh` gains a non-destructive size audit:
  per-entry char cap (`WK_MAX_ENTRY_CHARS`, default ~1200) → emit a `[nana:wk]` advisory naming over-cap
  entries; report total file chars/tokens. NEVER truncate, evict, or whole-file-bail on size (advisory
  only — size is a human-compress signal, not a correctness failure). Add a curator test asserting the
  advisory fires on an over-cap entry and stays silent under cap, and that no entry is mutated.

## Constraints (CRITICAL)
- **Fail-open / non-destructive everywhere** — the size cap WARNS, never truncates/evicts; the hook cd
  uses `|| true`. A hygiene fix must not itself break a session or lose knowledge.
- **No bare relative hook command may remain** — assert it in the drift test; the whole bug class is the
  bare relative path.
- **Hermetic tests only** — wrong-CWD + curator tests run in `mktemp -d` with overridden HOME/env; never
  touch the real `~/.claude` or the live `working-knowledge.md`.
- **modules.json stays the single source of truth** — settings.json is regenerated, never hand-edited
  ([[decision:single-source-scope-tagged-hook-registration]]); the drift test enforces it.
- **Firing-coverage invariant preserved** — every registered hook keeps a firing test; the cd change
  must not drop coverage ([[decision:functional-smoke-invariant-rule]]).
- **edge-screener untouched** — this phase fixes the kit source; the consuming project re-syncs later.

## Success Vision
A consuming project's hooks resolve and function regardless of the CWD Claude Code launches them with,
proven by a committed wrong-CWD test (not a one-off live check). `working-knowledge.md` drops below the
context-size warning and the curator emits a loud, non-destructive advisory the moment any future entry
grows mega-sized — so the always-loaded layer stays terse by construction, with detail in the dev-wiki.
make test + make eval green at the regenerated surface; zero knowledge lost.

## Exit Criteria (machine-checkable)
- [ ] No hook command in `templates/.claude/settings.json` is a bare relative path:
      `! jq -r '.hooks[][].hooks[].command' templates/.claude/settings.json | grep -q '^\.claude/hooks/'`
      and project hooks use `${CLAUDE_PROJECT_DIR}/.claude/hooks/`.
- [ ] `make template` is idempotent (regenerated settings.json matches; `test_settings_template.sh` green).
- [ ] A wrong-CWD hook-resolution test passes (hook runs from a non-root CWD via `$CLAUDE_PROJECT_DIR`).
- [ ] Every project hook contains `cd "${CLAUDE_PROJECT_DIR` (or an equivalent guarded resolution).
- [ ] `working-knowledge.md` is materially smaller (4 amplifier entries → 1; total < 38k chars) and
      well-formed (curator `--selftest`/dry-run does not bail).
- [ ] `wk-prune.sh` size advisory: fires on an over-cap entry, silent under cap, mutates nothing (test).
- [ ] `make test` green (settings-drift, firing-coverage, registration, curator tests) and `make eval` green.

## Checkpoints
- After A1: if `test_settings_template.sh` shows drift the regeneration didn't capture, STOP and fix the
  generator (don't hand-edit settings.json).
- After A2: if any hook's firing test regresses from the cd, fix that hook before proceeding.
- After B1: re-run the curator dry-run; if it bails on the compressed file, the entry is malformed — fix
  before adding the B2 cap.

## Assumptions
- `${CLAUDE_PROJECT_DIR}` resolves to the correct project root in real sessions (confirmed by docs +
  the /tmp simulation). If a consuming session resolves the project dir itself wrongly, that is a Claude
  Code config issue outside the kit's control — the test cannot cover it; documented as a known limit.
- `cd "$CLAUDE_PROJECT_DIR"` is harmless for stdin-path-driven hooks (their paths are absolute). If a
  hook is found to depend on the original CWD, exempt it explicitly with a comment.
- The amplifier finding is fully preserved in the four dev-wiki decision articles + journals, so
  compressing the working-knowledge copies loses nothing recoverable.
