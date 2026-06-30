# Active Phase Context

Phase: 114 — Pi as the default daily engine (good tools) + workspace picker. DELIVERED + ACCEPTED 2026-06-30, 6/6 tasks [x]. No active phase — run /dev-plan for Phase 115.
Objective (done): fixed the dogfood "the tools are awful" at its ROOT — an accidental default (the agent ran on the Vercel adapter only via a Ph109 bring-up artifact, while the spec names Pi primary and Pi already ships the rich capped suite the gate covers). Made Pi the default (T1 make-or-break PASSED; threaded NANA_MAX_TOKENS; activated grep/find/ls) + a Rust-atomic workspace picker (native dialog FROM RUST → re-spawn the sidecar with the chosen NANA_WORKSPACE → fresh gate + approved-writes; webview gets NO dialog capability — tighter than planned).
Outcome: app suite 343/343 + npm run build + cargo check exit 0. T6 adversarial review (3 finders, orchestrator-verified) caught + fixed 6 confirmed findings incl. 1 HIGH — the secret deny-list was ANCESTOR-BLIND, so the now-active recursive grep/find/ls (not seatbelt-confined like bash) reached ~/.ssh / ~/.aws via an ancestor search root → pathReachesDeniedPath (ancestor-aware). Ledger Phase-114: A1/A3/A4 held, A2 BIT.
Residuals (do not over-claim): out-of-workspace READ stays the Ph112 residual (UNCHANGED — the fix tightened the SECRET class only); the native dialog→respawn round-trip is live-drive-only (cargo check = compile); #2 conversation memory → Ph115; PRE-EXISTING renderer-trust gap (a compromised renderer can auto-approve a held gate via engine_send{gate-verdict}, Ph108/109 trust model) flagged for a future phase, NOT a Ph114 regression.
Decision: [[pi-default-engine]] (high). Rides umbrella spec specs/gui-harness-architecture.md (Ph108-113 precedent, ADR-named).
Next candidates (Ph115): #2 conversation memory (the planned headline) / renderer-trust hardening / blocking out-of-ws READ / finally running the deferred live window-drive.
Gates:
- [x] spec — umbrella spec specs/gui-harness-architecture.md (nana:approved; Ph108-113 precedent, ADR-named — no separate phase spec)
- [x] Direction confirmed by user (assumption positions 2026-06-30, ledger Phase-114 all_accept:true A1-A4; --gate 114 exit 0)
- [x] Delivery accepted (/dev-debrief 2026-06-30; commit lands the BUILT + reviewed work)
