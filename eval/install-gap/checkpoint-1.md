# Checkpoint 1 — Maintainer root (~/.claude), Phase 85

Date: 2026-06-10. HARD checkpoint per spec: no write to ~/.claude before approval.

## Evidence in hand

- **Rehearsal: GREEN** (`rehearsal.log`, reproducible via `rehearse.sh`):
  - A: `--project-local` into a mktemp project installs cleanly; the installed SessionStart chain
    exits 0 with all 3 curators (fixture provenance: session-start.sh reads no stdin fields —
    code-read verified; the empty-stdin event covers every path a captured event would).
  - B: full global install into a mktemp HOME exits 0; session-start.d is NOT shipped globally
    (consumer is scope:project); sandbox settings == scope:global set; fresh-root drift 0.
  - C: **live positive control** — a read-only copy of the real ~/.claude with one seeded-stale
    curator is flagged by the new dir-currency cells (instrument alive on the real root shape).
- **A1 (causal path) verdict: confirmed** (`inventory.md`) — incident 5 came from the Phase-82
  drift-guided resync whose shopping list (this checker) was blind to directories; the dir-cells
  fix closes the causal path; install.sh global never shipped session-start.sh (scope:project);
  py-init/ts-init are recursive (exempt). No other refresh machinery found.
- **Live root current state (read-only):** drift count **0** — the hand-repaired
  ~/.claude/hooks/session-start.d already matches templates byte-for-byte (the A3 "diff before
  overwrite" concern dissolves: there is no divergence to reconcile).
- **assert-global-set.sh:** PASS on the live settings.json today (kit-owned == {context-size-check.sh});
  seeded-ghost self-control rejects a planted extra hook; built-in positive control guards
  zero-extraction.

## A3 decision input — ship-vs-dispose (registration-dead copies)

~/.claude/hooks/session-start.sh (+ 10 other project-scope hook copies) are registration-dead:
zero references in ~/.claude/settings.json; all live registrations are project-local forms.
- **Keep-current (recommended this phase):** the copies stay; the new consumer-conditioned cells
  keep session-start.d compared (currently drift 0, no stale-invisible window). Disposal is
  routed to the next prune-on-value round together with the filed Phase-82 installed-only
  residue inventory — one subtraction decision over the whole residue class, not a one-off here.
- **Dispose now:** delete session-start.sh + session-start.d (+ optionally all unregistered
  project-scope copies) from ~/.claude/hooks; the checker's cells drop automatically
  (consumer-conditioned). Functionally safe per the registration-dead evidence, but it acts on
  the residue class piecemeal and ahead of its filed inventory.

## Proposed live action (on approval)

1. Timestamped backup: `tar -czf ~/.claude/backup-phase85-<ts>.tgz -C ~ .claude/settings.json .claude/hooks`
   — restore = `tar -xzf` (restore TESTED in a sandbox copy before the live run).
2. Run `bash install.sh` (full) from the kit root — refreshes kit-owned files (currently drift 0,
   so content-neutral), exercises the fixed installer + MCP idempotent merge against the live root.
3. Post-run assertions (logged): `check-install-drift.sh ~/.claude` → 0; `assert-global-set.sh` → PASS.
4. Revert-on-failure: any post-run assertion failure → restore the backup, file the divergence.

## Approval

- [x] Maintainer approved (date): 2026-06-10 (AskUserQuestion positions in-session)
- [x] A3 disposition chosen: **keep-current** — disposal routed to the next prune-on-value round
      with the Phase-82 installed-only residue inventory.

## Execution record (post-approval, 2026-06-10)

- Backup: `~/.claude/backup-phase85-20260610-093320.tgz` (settings.json + hooks; restore TESTED
  in sandbox before the live run — settings.json + curator files extract intact).
- Live run: `bash install.sh` (full) — exit 0.
- Post-run: `check-install-drift.sh ~/.claude` → exit 0 (drift 0, dir-currency cells active);
  `assert-global-set.sh` → PASS (kit-owned == {context-size-check.sh}); all 3 curators present.
- Revert: not needed.

## Recorded deviation (exit criterion 3 — fixture letter vs spirit)

The spec's criterion 3 asks for "a piped SessionStart event from a pinned real-capture fixture".
The rehearsal pipes EMPTY stdin instead, because session-start.sh consumes no stdin event fields
(code-read verified: no read/jq of stdin) — a captured event would exercise zero additional code
paths, and a hand-written JSON would be circularity theater. DEVIATION from the criterion's
letter, recorded here as such (review-gate finding, 2026-06-10); the provenance note in
rehearsal.log carries the same fact.
