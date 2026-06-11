# Amendment 002 — arm model + operational stop rule (2026-06-10, pre-unblinding, pre-arm)

Two execution parameters the addendum left unpinned, ruled before either arm has started:

1. **Arm model (maintainer ruling, T5 checkpoint Q):** both arms run
   `claude --model claude-opus-4-8[1m]` (Opus 4.8, 1M context) — the maintainer's
   default-class model, chosen for representativeness over cheaper alternatives (a
   weaker-model win for ceremony would not transfer; amplifier-null reasoning).
2. **Operational stop rule (deterministic):**
   - The shared task statement (byte-identical across arms) gains the final sentence:
     "When the task is fully complete and the gate is green, use the Write tool to
     create a file named ARM_DONE in the repository root containing exactly: done".
   - Driver mechanics: idle = 180 s with zero pty output (6 consecutive 30 s drain
     timeouts). At idle without ARM_DONE: send the pinned continuation string
     ("Proceed with your best judgment within the stated task; no additional
     constraints.") — at most 6 times per arm. ARM_DONE observed, continuation budget
     exhausted, gate-stall (900 s on a displayed menu), or the 14,400 s deadline →
     STOP SEQUENCE: capture `/cost` output; for arm B only, pose the leak canary
     verbatim and capture the reply; `/exit`.
   - STATUS: FINISHED iff ARM_DONE exists at stop; DNF otherwise (deadline /
     stall / budget-exhausted-idle).
   - Generic menu detection: rendered highlighted-option row `❯ … 1.` (single-token-safe);
     every send logged verbatim pre-send (TRUST/GATE/CONT/COST/CANARY-RESPONSE lines).
