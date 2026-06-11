# Amendment 003 — canary posing fix + /cost removal (2026-06-10, pre-unblinding)

Defect found after arm B stopped (arm A not yet started; no diffs opened): the stop
sequence's `/cost` command opened the account-level usage dashboard, which swallowed
input focus — the canary question typed afterward never reached the model (empty reply
= NOT-POSED, a capture failure; an empty reply is NEVER a CLEAN verdict). The pty
transcript-persistence finding (T1) also kills `--resume` re-posing: arm B's jsonl is
title-only, so no conversation context exists to restore.

Ruling (apparatus fix, pre-unblinding):
1. **Canary verdict for arm B = headless probe + capture grep, both required CLEAN:**
   (a) `claude -p --model claude-opus-4-8[1m]` posing the verbatim canary question from
   the arm-b clone cwd — same environment (always-loaded surfaces, reachable files),
   same model; the contamination channel the canary exists to detect is environmental,
   and the conversation itself is unrecoverable. Pinned matcher unchanged
   (CONTAMINATED iff 'string.?keyed' AND 'drq1-verification|install-gap' both match).
   (b) The arm's COMPLETE pty capture (tui-capture.log, everything the model rendered)
   greps negative for DRQ-1 content — corroborates the live session never touched it.
2. **/cost is dropped from the stop sequence** (it is a dashboard, not per-session
   cost): the cost caveat column reads NOT-CAPTURED; per-arm cost = wall-clock +
   interruption counts from the driver's verbatim log (the pre-declared A3 fallback).
   Arm A's driver runs with the /cost step removed; arm B's records are normalized to
   the same basis (its cost-arm-b.txt was empty anyway).
