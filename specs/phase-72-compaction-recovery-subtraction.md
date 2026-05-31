<!-- nana:approved 2026-05-30 -->
# Spec: Phase 72 — Compaction-Recovery Subtraction (.session-anchor)

## Objective
Remove the dead `.claude/.session-anchor` recovery machinery from the harness — the read-branch in `templates/.claude/hooks/post-compact.sh` and its `.gitignore` entry — and record the rationale on a decision article. This is the first concrete "cash the Phase-70/71 conclusion" harness right-sizing.

## Context
The Phase 58–71 measurement campaign returned 14 consecutive CUT/TERMINATE verdicts. Phase 70 (single-decision anchor) and Phase 71 (single-compaction retention) both found the bare frontier model already does, unprompted, what the harness was hypothesized to add — and specifically that Claude Code's native compaction summary is decision-comprehensive, so the harness compaction-*recovery* pathway has no measured headroom. During Phase 71 a latent finding was recorded but deliberately NOT fixed (freeze-the-subject): `post-compact.sh` READS `.claude/.session-anchor` but nothing in the repo ever WRITES it. `pre-compact.sh` emits its state snapshot to stdout for context injection, never to a file. With measurement paused (Jake chose Engineering → Tight subtraction, AskUserQuestion 2026-05-30), the freeze no longer applies and the dead branch can be removed. This spec is self-contained and readable after compaction.

## Scope
### In scope
- `templates/.claude/hooks/post-compact.sh`: delete the `if [ -f "$ROOT/.claude/.session-anchor" ]; then … fi` block (lines 11-13), collapsing the surrounding blank lines so no double-blank remains. Preserve the `[nana:compact]` echo, the `[nana:devwiki]` block, and the `.context-warned` rm.
- `.gitignore`: delete the single line `.claude/.session-anchor`. Keep `.claude/.context-warned`, `.claude/.memory-consulted`, `.memory/*.db*` — all live.
- New decision article recording the subtraction rationale; supersede (not rewrite) the stale implication in the historical `hook-reconciliation.md`.

### Out of scope
- `pre-compact.sh`, `session-start.sh`, any other hook (cross-compaction machinery — was the measurement subject; unfrozen ONLY for this dead-branch removal).
- `modules.json` registration (post-compact.sh stays registered — only an internal branch is removed).
- `.memory/*.db*` gitignore item — ALREADY done (line 20).
- Gap 4.1 (language-agnostic core) — DEFERRED as YAGNI (open since Phase 25 / 46 phases, zero consuming-project demand). Re-trigger: first non-Python/non-TS consuming project.
- Rewriting historical dev-wiki records (decision articles, journals, screen-record, working-knowledge) — append/supersede, never rewrite history.

## Approach
Verify-then-delete. The load-bearing risk is "is it truly dead?" — gate on an exhaustive repo grep before deleting, then prove no regression with the existing deterministic gates. The change is pure subtraction; no new mechanism, no replacement. Reject the alternative of *wiring up* a writer to make `.session-anchor` live: Phase 70/71 measured the recovery pathway and found no headroom, so building machinery would add exactly the complexity the campaign proved inert.

### Domain Research Questions
- Does anything on the INSTALLED surface (a consuming project, an install.sh-copied artifact, a skill instruction) ever create `.claude/.session-anchor`? (Answer from verification: no — only the kit's own historical records name it.)
- Does the post-compact firing test (`test_long_cadence_hooks.sh`) assert the anchor branch? (Answer: no — it asserts the `.context-warned` removal and the recovery banner.)

## Constraints (CRITICAL)
- Confirm-truly-dead BEFORE deleting: exhaustive `grep -rn "session-anchor"` across the whole repo incl. `install.sh`, `templates/.claude/skills/`, `templates/.claude/rules/`, `AGENTS.md` — prevents silently killing a live recovery path. (Done: only post-compact.sh + .gitignore are live; all other hits are historical records.)
- Do NOT touch `pre-compact.sh` / `session-start.sh` / other hooks — prevents scope creep into the (now-unfrozen but out-of-scope) recovery machinery.
- post-compact.sh stays registered + keeps its `# fires:` declaration — prevents firing-coverage-gate / registration / settings-template drift and a README script-count bump.
- Do NOT rewrite historical dev-wiki records — prevents falsifying the project's own history; supersede via the new article instead.
- Preserve `set -euo pipefail` behavior and the other branches' exit codes — prevents a hook regression from an editing slip.

## Success Vision
A smaller, more honest harness: the dead `.session-anchor` recovery machinery gone, its removal traced line-for-line to measured evidence (Phase 70/71), the rationale on record as a reusable "right-size the harness from measurement" precedent, and every deterministic gate green at an unchanged surface (no script-count, registration, or settings drift).

## Exit Criteria (machine-checkable)
- [ ] `! grep -rn "session-anchor" templates/ scripts/ Makefile install.sh AGENTS.md` (no live reference remains)
- [ ] `! grep -q "session-anchor" .gitignore` (gitignore entry removed)
- [ ] `bash tests/test_long_cadence_hooks.sh` (post-compact firing test green)
- [ ] `make test` exits 0 at the unchanged script count (`grep -q "52-scenario\|52 script" README.md` unaffected; no Makefile change)
- [ ] `make eval 2>&1 | grep -qE "52/52|52 / 52"`
- [ ] `bash tests/test_registration.sh && bash tests/test_settings_template.sh` (no registration/settings drift)
- [ ] `test -f .dev-wiki/articles/decisions/cash-compaction-recovery-subtraction.md` (rationale recorded)

## Checkpoints
- Before deleting: confirm the exhaustive grep shows only post-compact.sh + .gitignore as live references. If ANY live writer/consumer is found → STOP, reassess delete-vs-wire.
- After deleting: re-run the post-compact firing test + firing-coverage gate. If either fails → STOP, the branch was load-bearing in a way the analysis missed.

## Assumptions
- Nothing in the kit or a consuming project writes `.claude/.session-anchor`. If false (a live writer is found): STOP and reconsider — the branch is unfinished, not dead, and the call becomes wire-vs-delete.
- A consuming-project user does not rely on the kit's gitignore entry to keep a hand-created `.session-anchor` out of git. If false: acceptable — the file is no longer a kit concept; a user keeping their own out-of-band file manages their own ignore rules.
- The post-compact firing test does not assert the anchor branch. If false: update the test to drop the anchor assertion as part of this phase (in-scope follow-through, not new scope).
