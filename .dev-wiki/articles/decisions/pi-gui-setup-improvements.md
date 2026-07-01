---
title: "Pi GUI-harness setup improvements (research-spike finding)"
aliases: [pi-setup-improvements, pi-ux-felt-quality-slice, gate-is-the-unlock]
category: decisions
tags: [pi-agent, gui-harness, pi-setup, youtube-research, felt-quality, host-gate, phase-candidate]
parents: [phase-118-youtube-frozen-live-measurement]
created: 2026-07-01
updated: 2026-07-01
source: research
confidence: medium
---

## Context

A research spike (2026-07-01, NOT a phase) between Phase 118's build and its still-pending
live run. The maintainer redirected from the frozen measurement to practical research:
*"research on Pi Agent setup through YouTube … to improve our pi agent setup for nana-dev-kit
new interface, make your own judgmental calls."* So the Ph116/117 YouTube apparatus was used
for its actual purpose — to pull and read 4 real Pi power-user walkthroughs (Christian Lempa,
Brandon Melville, Kacper Rutkiewicz, Eero Alvar) and ground an improvement list for nana's OWN
embedded-Pi setup, cross-checked against an Explore-verified map of the current embed
(`@earendil-works/pi-coding-agent` v0.80.2; host gate on `pi.on('tool_call')`;
`SessionManager.inMemory` never compacts; provider/model fixed per sidecar; thinking-level never
set; hosted `maxTokens` unset; project `AGENTS.md` injected as a preamble; `SpendCeiling` unwired;
7-command palette). Detailed artifacts live gitignored (ToS) under `companion/research/youtube/`:
**`pi-setup-guide.md`** (the grounded Pi setup guide) + **`pi-nana-improvements.md`** (the 11
tiered calls, with `pi-adapter.ts` line refs). This article summarizes; it does not duplicate them.

## Decision

**Strategic thesis — "the gate is the unlock."** Every walkthrough's #1 lesson is that *Pi ships
as dangerous YOLO* — no permission prompts + a bash tool that deletes files — so you MUST bolt on
a permission/bash-guard extension, and users then complain the bolt-ons are clunky ("no bypass
mode"). nana ALREADY has the un-bypassable host gate at the SDK `pi.on('tool_call')` seam, so the
security work is DONE and better than the ecosystem's. That gate is also the *unlock*: because it
governs every tool call regardless of origin, nana can safely open Pi's skills / prompt-templates /
CLI-tools that terminal users run recklessly. The real gap is that nana runs a minimal locked-down
embed that leaves most of Pi's daily-driver UX unused — and `inMemory` never compacting is a latent
quality+cost bug (the exact "dumber + more expensive" failure the videos warn about).

**Tiered judgment calls (11; full detail in `pi-nana-improvements.md`):**
- **T1 — highest-ROI "felt-quality" slice:** (1) context%/cost meter + Pi-native auto-compact —
  `inMemory` never compacts = the biggest single fix; wire the dead `SpendCeiling`. (2) model picker
  + OpenRouter-one-key / local, and *reconsider the weak local default* (small models break bash).
  (3) thinking-level toggle (silently stuck on `medium`). (4) hosted-path `maxTokens` fix (threaded
  only through the local path — a Ph114-class truncation bug for the hosted path).
- **T2 — make the gate the HERO:** show WHY a call is held + what's snapshotted; add "always allow
  this command in this workspace" memory + a scoped trust-mode (nana's *controlled* YOLO);
  a per-session file-change timeline (file-undo Pi LACKS, nana already snapshots); branching sessions
  (fork/tree, re-invoked *through the gate*, keeping Ph115 plain-restore display-only).
- **T3 — open the ecosystem because the gate makes it safe:** prompt-templates → palette
  slash-commands (1:1 fit); CLI-tools-over-MCP (keep only the MCP memory spine); a LEAN ~1k-token
  harness system prompt (Pi ~1k vs Claude Code ~10k is a differentiator).
- **DON'Ts (subtraction test):** no Pi `memory.md` (the MCP spine + redacted store are better);
  no untrusted `pi.dev` extensions (un-gated in-process TS code — curate a vetted shortlist);
  no weak-local-default silently (verify on launch or default-to-frontier with local as opt-in).

**Alternatives / rejected** are the DON'Ts above — each is a capability the ecosystem reaches for
that nana should decline or already does better.

## Consequences

- The **T1 felt-quality slice** is a strong, cohesive Phase-N+1 CANDIDATE — small, and every item is
  directly FELT in the GUI (the joy/control north star). It does NOT become tasks here; it becomes a
  phase at `/dev-plan`. Recommended first: the context/cost meter + auto-compact (the `inMemory`
  latent quality+cost bug).
- **Confidence medium** — these are recommendations from grounded research, not yet built or measured.
  The Pi-setup-guide claims trace to auto-caption transcripts (no audio verification; proper-name/
  version terms may be mis-heard) and should be doc-checked against `pi.dev/docs` before building.
- This is a research finding, **not** Phase 118 work: the Ph118 frozen-measurement live run remains a
  separate, still-pending track. No shipped-kit code changed; the research docs stay gitignored (ToS).
- Related: [[pi-default-engine]] (Pi is the default engine this improves), [[engine-adapter-in-process-gate]]
  (the in-process gate that is the "unlock"), [[felt-quality-surface]] (the joy/control north star the
  T1 slice serves), [[youtube-grounded-acquisition]] (the apparatus used to pull the source videos).
