---
title: "Research spike — Pi setup via YouTube → improve nana's GUI-harness Pi embed"
aliases: []
category: journal
tags: [pi-agent, gui-harness, pi-setup, youtube-research, felt-quality, host-gate, research-spike]
parents: [phase-118-youtube-frozen-live-measurement]
created: 2026-07-01
updated: 2026-07-01
source: debrief
duration: unknown
---

# Research spike — Pi setup via YouTube → improve nana's GUI-harness Pi embed

## What Happened
- A deliberate research spike (NOT a phase) between Phase 118's build and its still-pending live run.
  The maintainer redirected from the frozen measurement to practical research: *"research on Pi Agent
  setup through YouTube … to improve our pi agent setup for nana-dev-kit new interface, make your own
  judgmental calls."*
- Used the Ph116/117 YouTube apparatus for its actual purpose — pulled + read 4 real Pi-agent-setup
  walkthroughs (Christian Lempa `04EL2_Llenc`, Brandon Melville `8Dt0HM8HIq4`, Kacper Rutkiewicz
  `B5_lAbGeBDY`, Eero Alvar `DWWrLlM3gwQ`; transcripts gitignored under `run117/`), synthesized a
  grounded setup guide, then mapped it against an Explore-verified current-state read of nana's embed.
- Produced two gitignored research docs + 11 tiered improvement calls. Central finding — **"the gate
  is the unlock":** every video's #1 lesson is that Pi ships as dangerous YOLO and you must bolt on a
  clunky permission extension; nana already has the un-bypassable gate at `pi.on('tool_call')`, so the
  security work is DONE and better — AND it lets nana safely open Pi's skills / prompt-templates /
  CLI-tools that terminal users run recklessly.
- Two maintainer corrections landed (see below). Installed `yt-dlp` into the companion venv for search.

## Decisions Made
- [[pi-gui-setup-improvements|Pi GUI-harness setup improvements (research-spike finding)]] (medium) —
  the strategic thesis + the 11 tiered calls, summarizing the two gitignored docs.

## Problems Solved
- "Where does Pi's daily-driver UX go unused in nana?" — resolved by the current-state map: `inMemory`
  never compacts (the latent quality+cost bug), no model/thinking/compact/fork UX, hosted `maxTokens`
  unset, `SpendCeiling` written-but-unwired, no harness-owned system prompt.

## Open Questions
- Whether to build the T1 felt-quality Pi-UX slice as the next phase (offer `/dev-plan`).
- Phase 118 live manual-drive run still pending the maintainer — a SEPARATE, unchanged track.

## Artifacts Changed
- `companion/research/youtube/pi-setup-guide.md` (NEW, gitignored — grounded Pi setup guide from 4 videos)
- `companion/research/youtube/pi-nana-improvements.md` (NEW, gitignored — the 11 tiered improvement calls)
- `companion/research/youtube/run117/{8Dt0HM8HIq4,B5_lAbGeBDY,DWWrLlM3gwQ}.txt` (NEW, gitignored — 3 new transcripts)
- `.dev-wiki/articles/decisions/pi-gui-setup-improvements.md` (NEW — the research-finding decision article)
- companion venv: `yt-dlp` added (research tooling)
- Memory bridge `mem_nhKhVSP-1EtO` (strategic thesis + current-state map + tiered calls)

## Related
- [[phase-118-youtube-frozen-live-measurement|Phase 118: YouTube grounded-acquisition frozen live measurement]] — the active phase this spike rode between (unchanged; live run still pending)

## Escape Hatches
- USER OVERRIDE: the maintainer redirected from the Ph118 frozen measurement to practical Pi research,
  then scoped it to improving nana's own GUI-harness Pi setup — a deliberate spike outside the phase plan.
- Correction 1 (high): the repeated "I can't run T9" claim was WRONG — Ph117 proved the agent CAN drive
  the run on this machine (residential IP, Claude-as-extractor); the true blocker is narrower (no
  `ANTHROPIC_API_KEY` → can't run the rail-BLIND API extractor that IS the phase's distinguishing A2
  measurement). Stored `mem_ebN6Mhm_ISGc`.
- Correction 2 (high, live Ph80-leak re-confirmation): the "use subagents as rail-blind" idea was
  empirically tested — a zero-tool subagent RECITED the grounding rail from inherited always-loaded
  rules, so subagents are rail-AWARE, not blind. Stored `mem_QsygVzi3fZ9n`.

## Health Delta
- None to nana: no shipped-code or test changes; companion pytest 169 stands from the Ph118 build.
  `yt-dlp` added to the companion venv (research tooling only).

## Soft Observations / Phase N+1 Candidates
- The **T1 felt-quality Pi-UX slice** — context/cost meter + auto-compact + thinking toggle + hosted
  `maxTokens` fix + gate legibility & "always allow" memory + prompt-template palette commands — is a
  strong Phase-N+1 candidate: small, cohesive, every item directly FELT in the GUI (joy/control north
  star). | phase framing: "Felt-Quality Pi-UX slice" | evidence: `companion/research/youtube/pi-nana-improvements.md`
- The **"gate is the unlock"** thesis is a reusable strategic frame: safely open Pi's ecosystem because
  the SDK-seam gate governs all tool calls. | evidence: [[pi-gui-setup-improvements]]
- `SessionManager.inMemory` never compacting is a latent quality+cost bug worth fixing first. |
  evidence: `pi-nana-improvements.md` §1
