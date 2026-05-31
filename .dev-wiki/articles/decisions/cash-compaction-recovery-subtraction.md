---
title: "Decision: Cash the P70/71 conclusion — subtract the dead .session-anchor recovery machinery"
slug: cash-compaction-recovery-subtraction
type: decision
status: accepted
confidence: high
source: plan
phase: 72
created: 2026-05-30
updated: 2026-05-30
tags: [harness-right-sizing, subtraction, compaction, post-compact, amplifier-vision, engineering]
supersedes_claim_in: hook-reconciliation
---

# Decision: Subtract the dead `.session-anchor` recovery machinery

## Context

The Phase 58–71 amplifier-measurement campaign returned 14 consecutive CUT/TERMINATE
verdicts. The robust, repeated finding: a strong frontier base model (claude-opus-4-8)
already does, unprompted, almost everything the harness was hypothesized to add.
[[amplifier-anchor-headroom-screen]] (Phase 70) closed the single-decision-reasoning line;
[[cross-boundary-retention-headroom-screen]] (Phase 71) closed the single-compaction
retention line — finding that Claude Code's **native compaction summary is
decision-comprehensive**, so the harness compaction-*recovery* pathway has no measured
headroom.

During Phase 71 a latent finding was recorded but deliberately NOT fixed (freeze-the-subject:
editing the machinery under measurement would invalidate the screen):
`post-compact.sh` READS `.claude/.session-anchor` but **nothing in the repo ever WRITES it**.
`pre-compact.sh` emits its state snapshot to **stdout** for context injection, never to a file.
The read-branch is dead recovery machinery for exactly the pathway the measurement just showed inert.

Jake paused the measurement program (Engineering → "Tight subtraction", AskUserQuestion 2026-05-30),
which unfreezes the machinery for this one removal.

## Decision

**Delete the dead branch; do not wire it up.** Remove the
`if [ -f "$ROOT/.claude/.session-anchor" ]; then … fi` block from
`templates/.claude/hooks/post-compact.sh` and the `.claude/.session-anchor` line from `.gitignore`.

## Why (subtraction over construction)

The alternative was to **implement the missing writer** (a pre-compact hook that writes
`.session-anchor`), making recovery live. Rejected: Phase 70/71 measured the recovery pathway and
found no headroom — the native summary already retains decisions. Building the writer would add
precisely the complexity the campaign proved inert. The subtraction test (does this earn its
complexity?) is decisive: a recovery mechanism with no measured value is cruft.

This is the first concrete **"cash the conclusion"** move: harness components are right-sized
*from measurement*, not from intuition. It sets the precedent for future harness right-sizing —
remove what the eval program demonstrates the base model already covers.

## Verification (confirm-truly-dead, load-bearing)

Exhaustive `grep -rn "session-anchor"` across the whole repo: the **only live references** were
`post-compact.sh:11-13` and `.gitignore:16`. No `install.sh` / `SKILL.md` / `AGENTS.md` / rules
reference. Every other hit is a historical dev-wiki record (decision articles, journal,
screen-record, working-knowledge) — history, not a writer. The post-compact firing test
(`tests/test_long_cadence_hooks.sh`) asserts the `.context-warned` removal and the recovery
banner — **not** the anchor branch — so removal does not break it.

## Scope discipline

- Historical record [[hook-reconciliation]] (line 26) still describes post-compact as
  "Reads `.claude/.session-anchor` if present." That is an **append-only history** record of the
  backport decision; it is **not rewritten** — this article supersedes its now-stale implication.
- `.memory/*.db*` repo-hygiene was already gitignored (line 20) — not touched.
- Gap 4.1 (language-agnostic core) DEFERRED as YAGNI: open since Phase 25 / ~46 phases with zero
  consuming-project demand. Re-trigger: the first non-Python/non-TS consuming project.

## Consequence

A smaller, more honest harness. post-compact.sh stays registered (only an internal branch removed),
so no registration / settings-template / README-script-count drift; `make test` unchanged-count,
`make eval` 52/52. The cross-compaction machinery (`pre-compact.sh`, `session-start.sh`) is untouched.

## Source

Phase 72 plan; spec `specs/phase-72-compaction-recovery-subtraction.md` (nana:approved).
Evidence chain: [[amplifier-anchor-headroom-screen]], [[cross-boundary-retention-headroom-screen]].
