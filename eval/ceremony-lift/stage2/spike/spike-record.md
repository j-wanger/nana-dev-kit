# T1 Drivability Spike Record (Phase 87, ledger A4 — spike-defended)

Date: 2026-06-10. Verdict: **PASS** — `assert-spike.sh` 3/3 (stop marker exact-content,
≥1 verbatim GATE-RESPONSE, mechanism named). A gate-bearing claude session was driven
non-interactively to its stop point under the closed response policy.

## Mechanism (pinned candidate for the execution-protocol addendum)

`expect`-driven pty of the interactive CLI (`spike-driver.exp`, wrapped by
`drive-spike.sh`): `claude --model haiku --permission-mode acceptEdits "<prompt>"` in a
mktemp sandbox. Closed policy implemented as `<Enter>` on the highlighted first option;
every send logged verbatim with timestamp BEFORE sending. Run 3 evidence: trust answered
+7s, gate answered +7s after that, STOP_MARKER observed 3s after the gate answer.

## Hard-won mechanics (addendum MUST pin these)

1. **Pty backpressure (run-2 failure):** any wait loop must keep DRAINING the pty
   (`expect -timeout 2 -re {.+}`); a non-reading sleep loop fills the pty buffer within
   seconds of spinner redraws and freezes the claude process mid-turn.
2. **TUI pattern matching:** cursor-positioning escapes land BETWEEN words — only
   single-token patterns match ("safety" for the trust screen). Gate detection by rendered
   option-row shape `2\.[^\n]{0,24}<label>` — cannot false-positive on the transcript echo
   of the prompt (no numbered rows there). The spawn command echo is NOT in the match
   buffer (expect's own stdout).
3. **Workspace-trust dialog** fires in every fresh dir (arm clones will hit it); answer is
   part of the driver protocol and logged (TRUST-RESPONSE).
4. **enforce-memory is globally armed** on this machine: pre-touch
   `.claude/.memory-consulted` in the sandbox/clone or the first Write is blocked
   (provisioning-manifest item for T4).
5. **AskUserQuestion renders 4 rows** (2 custom options + "Type something" + "Chat about
   this"); policy "first option" = the agent's first listed option. Confirmed selection
   feedback line: "User answered Claude's questions: … → Proceed".

## DISCOVERY — transcript persistence trade-off (feeds T2 addendum + A3)

- **Pty-interactive sessions did NOT persist conversation entries**: both expect-driven
  runs left title-only jsonl files (130/119 bytes) in `~/.claude/projects/<cwd-slug>/`,
  even the run that completed cleanly. Token-cost extraction from transcripts is
  therefore UNAVAILABLE for pty-driven arms unless T4's rehearsal finds a flush path
  (candidate: capture the TUI `/cost` output before `/exit` as the per-arm token source).
- **Headless `-p` sessions persist full transcripts** (18,666 bytes observed) — but the
  gate probe shows **AskUserQuestion FAILS in `-p` mode** (tool errored: "Answer
  questions?"); a headless ceremony arm would degrade every gate. Headless is therefore
  NOT viable for gate-bearing arms; pty is the mechanism.
- Consequence: if no flush path is found at T4, the pre-declared A3 fallback applies —
  per-arm cost table reports wall-clock + interruption counts from the driver's verbatim
  logs, token columns marked NOT-EXTRACTABLE. Ship criteria are unaffected.
- Transcript-dir slug mapping confirmed: cwd `/var/.../tmp.XYZ` →
  `~/.claude/projects/-private-var-...-tmp-XYZ` (`/`, `_`, `.` → `-`; `/private` prefix
  added for /var paths).

## Artifacts

`run/` (response-log.txt, STOP_MARKER, mechanism.txt, expect-session.log,
sandbox-path.txt) from the passing run 3; `assert-spike.sh` is the deterministic gate.
Attempt ledger: run 1 driver bug (spawn-echo/multi-word patterns — no gate), run 2 pty
backpressure (gate answered, turn froze), run 3 PASS. Mechanism attempts used: 1 of 2
(headless was probed as a cost-side question, not consumed as a gate mechanism attempt).
