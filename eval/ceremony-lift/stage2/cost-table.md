# Phase 87 Stage-2 Per-Arm Cost Table

Basis: pre-declared A3 fallback (amendment 003) — pty sessions persist title-only
transcripts (arm-b 141 bytes, arm-a 131 bytes; verified), so token columns are
NOT-EXTRACTABLE; wall-clock from driver timestamps, interruptions = verbatim
TRUST/GATE/CONT-RESPONSE lines in the interaction logs. /cost screen-scrape was removed
by amendment 003 (it opens an account-level dashboard, not per-session cost).

| arm | wall_s | interrupts | tokens_raw | tokens_adj | interaction_log |
|---|---|---|---|---|---|
| arm-b | 996 | 26 | NOT-EXTRACTABLE | NOT-EXTRACTABLE | arm-records/interactions-arm-b.txt |
| arm-a | 2106 | 22 | NOT-EXTRACTABLE | NOT-EXTRACTABLE | arm-records/interactions-arm-a.txt |

Notes (caveat column):
- arm-b: FINISHED at 846s work-wall + 150s stop sequence; 0 continuations; its 26
  interrupts include the assumption-gate AskUserQuestion menus its wrapper mandates plus
  permission prompts.
- arm-a: DNF (continuation budget exhausted): 15 gate menus answered through dev-plan's
  ceremony, then 6 idle→continuation cycles (21:47–22:02) with no ARM_DONE; ceremony
  overhead is visible as the 2.1x wall-clock at 0 additional deliverable margin.
- Same model both arms (claude-opus-4-8[1m], amendment 002); same 14,400s cap; neither
  approached the cap.
