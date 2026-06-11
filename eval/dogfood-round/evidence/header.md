# Evidence Baseline Header — Phase 89 (written at T4, post-resync, per the pinned header deferral)

All Phase-89 evidence below this baseline was collected on these surfaces. A mid-window re-sync
would open a NEW separately-headed section (none planned).

- kit HEAD: 59afc2b (T3 commit; pre-registration first-add 45460bc anchors the phase range)
- maintainer ~/.claude sync timestamp: 2026-06-11 (install drift 0 post-sync; trims live)
- edge-screener re-sync timestamp: 2026-06-11T11:22:37 local (backup at
  /Users/jwang/edge-screener/.claude/backup-20260611T112237; detect-loop deregistered via
  rehearsals/deregister-detect-loop.jq, 17→16 commands, survivors intact; --project-local
  reinstall from edge-screener CWD)

## Resolved-surface hash comparison (installed vs kit template, post-resync)

- skill dev-plan: 6973d78c5bb574ac0cdb46612288ca4e vs 6973d78c5bb574ac0cdb46612288ca4e — MATCH
- skill dev-debrief: 57a9855d2312b7f64e9beabe6cd3bf40 vs 57a9855d2312b7f64e9beabe6cd3bf40 — MATCH
- skill wiki-query: 982ce02f1033870bc2f8ebceb4ed4a0b vs 982ce02f1033870bc2f8ebceb4ed4a0b — MATCH
- skill dev-check: a7e1658ad3057ed62000e53ec7c06957 vs a7e1658ad3057ed62000e53ec7c06957 — MATCH
- es-hook check-tests-were-run.sh: 1d38725f4f2666d92c1d1a8cf618d886 vs 1d38725f4f2666d92c1d1a8cf618d886 — MATCH (b8bd416 harden live in edge-screener)
- es-hook enforce-memory.sh: bb03497367cdc637de5a5a43ca9d13df vs bb03497367cdc637de5a5a43ca9d13df — MATCH
- es-hook session-start.sh: 856a56c821c9a1747273470bed6f3f25 vs 856a56c821c9a1747273470bed6f3f25 — MATCH
- detect-loop.sh: ABSENT in templates AND absent in edge-screener (75b48af cut propagated)

Verification: `bash eval/dogfood-round/check-currency.sh` → CURRENCY: PASS; survivor smoke:
one real PostToolUse event piped through dev-wiki-scope-check.sh fired exactly once (exit 0,
correct no-open-tasks advisory).
