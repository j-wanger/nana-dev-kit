# Active Phase Context

Phase: 79 — Harness Hygiene (hook path resolution + working-knowledge size cap)
Status: COMPLETE — 4/4 tasks done; make test all-passed, make eval 52/52; delivery gate pending acceptance.

Result: both sub-fixes shipped. (A) register-settings.py + template + install.sh emit
${CLAUDE_PROJECT_DIR}/.claude/hooks/X.sh (all 17 project commands; global already absolute); all 17
hook scripts `cd "${CLAUDE_PROJECT_DIR:-.}"`; unconfirmable live check → committed hermetic wrong-CWD
test (resolution + function differentials). (B) working-knowledge 45,217→35,726 chars (4 amplifier
entries → 1 + pointers); non-destructive curator size_audit (WK_MAX_ENTRY_CHARS=1500, warns never
truncates) + terseness note in both seeding steps. test_harden 26/26, curation 15/15, firing 21/21.
Deferred: prune-on-value (subtraction framing); edge-screener re-sync (interim hand-patch holds).

Objective: Fix two kit defects degrading real consuming-project sessions.
(A) Hooks registered with bare relative `.claude/hooks/X.sh` 404 when Claude Code runs them from a
    non-project-root CWD (edge-screener Stop-hook dogfood). Claude Code does NOT guarantee CWD=root;
    the documented fix is `${CLAUDE_PROJECT_DIR}`. 4th dogfood→harden fix (Ph74/75/76 line).
(B) Always-loaded `working-knowledge.md` bloated to ~45k chars/99 entries → trips Claude Code's
    context-size warning. The curator caps entry-count(100)/lines(210) not SIZE, so 4 amplifier
    mega-entries (~11k chars) slip through.

Scope:
- `scripts/register-settings.py` + `templates/.claude/settings.json` (regenerated via `make template`) —
  project hooks → `${CLAUDE_PROJECT_DIR}/.claude/hooks/X.sh`, global → `$HOME/.claude/hooks/X.sh`.
- `templates/.claude/hooks/*.sh` (project) — `cd "${CLAUDE_PROJECT_DIR:-.}"` near top (internal refs).
- `.claude/rules/working-knowledge.md` — compress 4 amplifier entries → 1 + `[[decision:…]]` pointers.
- `templates/.claude/hooks/session-start.d/wk-prune.sh` — per-entry char-cap ADVISORY + size report.
- `tests/**` — settings-drift, hermetic wrong-CWD resolution, firing-coverage, curator size test.

Key constraints:
- Fail-open / NON-DESTRUCTIVE: size cap WARNS (never truncates/evicts); hook cd uses `|| true`.
- No bare-relative hook command may remain (assert in drift test).
- Hermetic tests only (mktemp -d + env override; never touch real ~/.claude or live working-knowledge).
- modules.json single source of truth; settings.json regenerated, never hand-edited.
- Firing-coverage 21/21 preserved (cd drops no coverage). edge-screener untouched (re-syncs later).

Tasks (in order): B1 compress wk (S, immediate relief) → A1 register-settings ${CLAUDE_PROJECT_DIR} +
drift/wrong-CWD tests (M) → A2 hook-internal cd (L) → B2 wk-prune size advisory + regression (M, LAST).

Decision: [[harness-hygiene]] (high). Spec: nana:approved 2026-06-04.
Abort rule: if blocked >3 attempts, mark [blocked] + ask user skip/abort.

Gates:
- [x] Direction confirmed by user (approach approved 2026-06-04 — "approved", bundled scope)
- [x] Delivery accepted (post-implementation report 2026-06-04)
