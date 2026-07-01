---
title: "Codebase Snapshot — 2026-07-01 (Phase 118 BUILT + twice-reviewed; live T9 RUN pending)"
aliases: [2026-07-01-snapshot]
category: status
tags: [snapshot, phase-118, youtube, frozen-measurement, anti-retrofit, companion-apparatus]
parents: [phase-118-youtube-frozen-live-measurement]
created: 2026-07-01
updated: 2026-07-01
source: debrief
---

# Codebase Snapshot — 2026-07-01

Captured at the Phase 118 (YouTube grounded-acquisition frozen live measurement) debrief. Implementation COMPLETE + twice-adversarially-reviewed (8/9 tasks [x]); the phase STAYS ACTIVE — the live manual-drive T9 RUN awaits the maintainer at the PREREG-commit checkpoint, so the delivery gate does NOT flip.

## YouTube research apparatus (`companion/research/youtube/`, gitignored, local-only — the focus of this phase)
- 19 Python modules total; Phase 118 added 8: `seal118` (rail + prereg SHA-256 self-seals), `select118` (deterministic templated-query corpus selection + corpus-freeze), `verify118` (two-stage tamper-evident anchor), `harness118` (rail-BLIND API-path Sonnet-4.6 batch runner, $10/batch cap, per-id accounting, non-optional-stopping resume, drift-proof `is_terminal`), `score118` (A1 audio rubric + A2 directional), `recovery118` (novelty bare-model recovery, outside-kit, out of the verdict), `verdict118` (4-way truth table + quote-agnostic ToS gate), `run118` (T9 orchestration scaffold + results writer + runbook).
- 19 pytest test modules; Phase 118 added 9 (`test_{prereg,select,anchor,harness,controls,scorers,novelty,verdict,run}118.py`). **companion pytest 78 → 169 (+91).** Hermetic (fixtures + mocked client, no network).
- **The grounding rail (`ground.py`/`normalize.py`/`consolidate.py`/`schema.py`) stayed BYTE-FROZEN** — `rail.sha256` recompute-and-MATCH verified at debrief (all 4 hashes identical); this SHA-256 seal REPLACES the vacuous `git diff` (`git ls-files companion/` empty).
- Tracked artifacts: `.dev-wiki/phase-118/{pre-registration.md, prereg.sha256, rail.sha256}` (params/aggregates/hashes ONLY — no verbatim). `run118/` is gitignored (nested `.gitignore`); `git check-ignore companion/research/youtube/run118` returns the path; ToS containment CLEAN (`git grep source_quote` over tracked non-companion files finds no VALUE-carrying match).

## Kit (host project)
- Shell/Markdown/Python scaffolding kit (260+ files). `make test` (28 scripts) + `make eval` (50 scenarios) UNAFFECTED by this phase (all changes are the gitignored companion apparatus + planning artifacts). v0.5.0.
- Toolchain unchanged: kit = GNU Make + bash + jq; app = Vite + Tauri 2 (Rust 1.96.0) + Vitest + TypeScript; companion apparatus = a local uv venv (youtube-transcript-api / yt-dlp / anthropic); Python MCP memory server mounted unchanged.

## Recent Commits (last 5)
- `876757f` Phase 117: YouTube apparatus first-contact — derisk mock-vs-real + harden (rung-B)
- `73be035` chore(wiki): auto-curate working-knowledge — prune 5 stale Ph45/46 eval-calibration entries
- `1fa9de4` Phase 116: YouTube→wiki grounded acquisition core (rung-B foundation)
- `a485706` Phase 115: Conversation memory — persist + restore the chat thread per-workspace
- `dbe4965` Phase 114: Pi as the default daily engine (good tools) + Rust-atomic workspace picker

## Notes
- Phase 118 work is NOT yet committed (this debrief precedes any commit; gate-log `delivery=pending`). The apparatus stays gitignored; a commit lands the dev-wiki record + the tracked `.dev-wiki/phase-118/` hashes only. Branch `main`.
- TWO ultracode adversarial-review Workflows (18+20 agents, ~2.05M subagent tokens) caught 22 confirmed findings (3 HIGH each): corpus.sha256 written-but-never-read-back; keystone bypassable by omitting a sidecar; is_terminal omitted 4 outcomes → resume-VOID — ALL fixed inline + regression-tested. Review gate SATISFIED by the two workflows (no third reviewer).
- The 4 Phase-118 assumptions (A1 value-signal / A2 rail-blind grounds / A3 non-gameable selection / A4 novelty affordability) resolve at the live run; the ledger revisit is deferred to the phase-close debrief.
- Detailed module/dependency maps: see `_ARCHITECTURE.md` (last refreshed 2026-06-30; the gitignored companion apparatus is acknowledged there since Ph97 — no rewrite this phase). This snapshot summarizes the apparatus delta only.
