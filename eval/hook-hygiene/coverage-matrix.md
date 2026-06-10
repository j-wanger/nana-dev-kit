# Phase 84 — Ghost-Registration Coverage Matrix (T4a)

Generated 2026-06-10 by the T4a scan (bash, literal hook list, in-loop positive control —
the gate-time zsh word-splitting hazard). registered-locally = the root's own settings.json
names the hook (for the .claude row this IS the ghost registration itself); installed-copy =
md5 of the root's hooks copy vs the CURRENT template (post-T3, so the redesigned
post-commit.sh makes every pre-T3 copy stale). The kit repo itself is a row: it has NO
project settings.json and relies on the ghosts too.

roots: /Users/jwang/.claude /Users/jwang/nana-dev-kit /Users/jwang/ab-test/stock-screener /Users/jwang/ai-game /Users/jwang/edge-analyst /Users/jwang/edge-screener /Users/jwang/fate

| root | hook | registered-locally | installed-copy |
|---|---|---|---|
| .claude | session-start.sh | yes | current |
| .claude | session-stop.sh | yes | current |
| .claude | enforce-loop.sh | yes | current |
| .claude | pre-compact.sh | yes | current |
| .claude | post-compact.sh | yes | current |
| .claude | stale-queue.sh | yes | current |
| .claude | detect-loop.sh | yes | current |
| .claude | post-commit.sh | yes | stale |
| .claude | enforce-spec.sh | yes | current |
| .claude | enforce-memory.sh | yes | current |
| .claude | dev-wiki-scope-check.sh | yes | current |
| nana-dev-kit | session-start.sh | no | absent |
| nana-dev-kit | session-stop.sh | no | absent |
| nana-dev-kit | enforce-loop.sh | no | absent |
| nana-dev-kit | pre-compact.sh | no | absent |
| nana-dev-kit | post-compact.sh | no | absent |
| nana-dev-kit | stale-queue.sh | no | absent |
| nana-dev-kit | detect-loop.sh | no | absent |
| nana-dev-kit | post-commit.sh | no | absent |
| nana-dev-kit | enforce-spec.sh | no | absent |
| nana-dev-kit | enforce-memory.sh | no | absent |
| nana-dev-kit | dev-wiki-scope-check.sh | no | absent |
| stock-screener | session-start.sh | yes | stale |
| stock-screener | session-stop.sh | no | stale |
| stock-screener | enforce-loop.sh | no | stale |
| stock-screener | pre-compact.sh | yes | stale |
| stock-screener | post-compact.sh | no | stale |
| stock-screener | stale-queue.sh | no | stale |
| stock-screener | detect-loop.sh | no | stale |
| stock-screener | post-commit.sh | yes | stale |
| stock-screener | enforce-spec.sh | no | stale |
| stock-screener | enforce-memory.sh | no | stale |
| stock-screener | dev-wiki-scope-check.sh | no | stale |
| ai-game | session-start.sh | yes | stale |
| ai-game | session-stop.sh | no | stale |
| ai-game | enforce-loop.sh | no | stale |
| ai-game | pre-compact.sh | yes | stale |
| ai-game | post-compact.sh | no | stale |
| ai-game | stale-queue.sh | no | stale |
| ai-game | detect-loop.sh | no | stale |
| ai-game | post-commit.sh | yes | stale |
| ai-game | enforce-spec.sh | no | stale |
| ai-game | enforce-memory.sh | no | stale |
| ai-game | dev-wiki-scope-check.sh | no | stale |
| edge-analyst | session-start.sh | yes | stale |
| edge-analyst | session-stop.sh | yes | stale |
| edge-analyst | enforce-loop.sh | yes | stale |
| edge-analyst | pre-compact.sh | yes | stale |
| edge-analyst | post-compact.sh | yes | stale |
| edge-analyst | stale-queue.sh | yes | stale |
| edge-analyst | detect-loop.sh | yes | stale |
| edge-analyst | post-commit.sh | yes | stale |
| edge-analyst | enforce-spec.sh | yes | stale |
| edge-analyst | enforce-memory.sh | yes | stale |
| edge-analyst | dev-wiki-scope-check.sh | yes | stale |
| edge-screener | session-start.sh | yes | stale |
| edge-screener | session-stop.sh | yes | current |
| edge-screener | enforce-loop.sh | yes | current |
| edge-screener | pre-compact.sh | yes | current |
| edge-screener | post-compact.sh | yes | current |
| edge-screener | stale-queue.sh | yes | current |
| edge-screener | detect-loop.sh | yes | current |
| edge-screener | post-commit.sh | yes | stale |
| edge-screener | enforce-spec.sh | yes | stale |
| edge-screener | enforce-memory.sh | yes | stale |
| edge-screener | dev-wiki-scope-check.sh | yes | stale |
| fate | session-start.sh | yes | stale |
| fate | session-stop.sh | no | stale |
| fate | enforce-loop.sh | no | stale |
| fate | pre-compact.sh | yes | stale |
| fate | post-compact.sh | no | stale |
| fate | stale-queue.sh | no | stale |
| fate | detect-loop.sh | no | stale |
| fate | post-commit.sh | yes | stale |
| fate | enforce-spec.sh | no | stale |
| fate | enforce-memory.sh | no | stale |
| fate | dev-wiki-scope-check.sh | no | stale |

## T4a live findings (checkpoint addendum)

1. **Ghost registrations fire machine-wide, beyond kit roots** — the T2 capture window collected
   PostToolUse events from concurrent sessions in foreign projects (e.g. /Users/jwang/signal-watch).
2. **Ghost session-start was ERRORING every SessionStart (startup + resume) machine-wide** since
   the Phase-82 stale-copy refresh: the refreshed ~/.claude/hooks/session-start.sh sources
   session-start.d/{wk-prune,memory-nudge,cognitive-readiness}.sh, but no install path ever
   shipped session-start.d to ~/.claude (modules.json declares it only under
   project_local.extra_dirs; install.sh and check-install-drift.sh have zero references).
   5th instance of the registered+present+current-but-BROKEN class. REPAIRED 2026-06-10
   (modules copied from templates; startup + resume verified exit 0). Same breakage found
   project-locally in stock-screener (sources 3 modules, has 0) and fate (sources 2, has 0).
3. **detect-loop.sh structurally cannot fire** (T2 branch: upstream — no exit code in the event,
   no event on failure): every registration of it, ghost or local, is dead weight today.
4. **post-commit ghost runtime copy is stale**: ~/.claude/hooks/post-commit.sh still carries the
   dormant pre-T3 code; the woken hook reaches no project until copies sync.
5. **ai-game carries a literal `null` command entry** in its project hooks array (malformed).
6. Directory-level gap: single-file md5 currency (this matrix's column) missed the EMPTY
   session-start.d — extra_dirs need their own currency cells in any future scan.

## Post-execution state (T4b, 2026-06-10 — the table above is the pre-state the checkpoint decided on)

Checkpoint decision: **approve** (full package). Executed: 6 roots remediated (copies synced
incl. session-start.d, 11/11 registered project-locally, ai-game null entry dropped),
~/.claude/hooks runtime 11/11 current, 11 ghost entries deregistered from ~/.claude/settings.json
(assertion battery green; non-hook keys byte-identical), survivor smoke green (context-size-check
allow AND block). Live kit-owned global registrations == modules.json scope:global set
(context-size-check.sh only). Backup: see rehearsal.log; one-command restore available.
