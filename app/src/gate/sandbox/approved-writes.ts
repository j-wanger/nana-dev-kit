// Phase 112 T4 — the C1-preserve gate→executor channel. Ph111 makes a DETECTABLE
// out-of-workspace bash write CONFIRMABLE (the host gate denies with the
// confirmation marker; the confirming-gate prompts the human). Without this
// channel the OS sandbox would HARD-block such a write even AFTER approval —
// dropping a Ph111 capability and diverging darwin from other platforms. So on
// approval the confirming-gate (via the host's onApprove) RECORDS the approved
// out-of-workspace target(s) keyed by the exact command; the bash executor (Pi
// spawnHook / Vercel runBash) CONSUMES them into the per-command seatbelt
// profile's extraWrites → the OS now allows that one write. approve-then-succeed,
// OS-enforced, platform-consistent. The verdict-loop CORE is untouched.
//
// SAFE by construction: consume-once + the gate-always-runs-first invariant. A
// command only reaches the executor after passing the gate (approved or allowed);
// the entry is removed on first read, so a later identical command re-triggers
// the gate (re-prompt) instead of silently reusing a stale approval. A lingering
// entry (approved but never executed) grants nothing on its own — a write only
// happens after the gate approves, which re-records anyway.

const approved = new Map<string, string[]>();

/** Record human-approved out-of-workspace write targets for the EXACT command. */
export function recordApprovedWrites(command: string, targets: string[]): void {
  if (targets.length > 0) approved.set(command, targets);
}

/** Read + REMOVE the approved targets for a command (consume-once). */
export function consumeApprovedWrites(command: string): string[] {
  const targets = approved.get(command);
  if (targets) approved.delete(command);
  return targets ?? [];
}

/** Test seam: clear all pending approvals. */
export function __clearApprovedWrites(): void {
  approved.clear();
}
