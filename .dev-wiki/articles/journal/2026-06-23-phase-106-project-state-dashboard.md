---
title: "Phase 106 — Project-State Dashboard + Act-from-Page Decision Gate: plan + implement + review in one pass"
date: 2026-06-23
category: journal
tags: [dashboard, direction-dashboard, rung-c, act-from-page, ephemeral-server, decision-boundary-validator, html-generator, heu-012, dev-plan, phase-106]
phase: phase-106-project-state-dashboard
---

## Summary

Planned AND implemented Phase 106 in one session (ultracode). The maintainer chose a NEW direction over
the three Ph105 NEXT candidates: extend Ph99's render-only direction dashboard into (1) an on-demand
`make dashboard` PROJECT-STATE monitoring page and (2) an OPT-IN **act-from-page** direction gate — the
maintainer decides ON a served dashboard that drives `/dev-plan`, pulling forward Ph99's deferred A2
(served surface) and A3 (general project-state). Direction locked across **4 AskUserQuestion gates**:
build-dashboard → on-demand persistence → act-from-page drive → ephemeral-server write-channel → "Continue".

The load-bearing constraint that shaped everything: a `file://` page is sandboxed and cannot write a repo
file (the "browser→session channel the harness lacks" Ph99 cited). Resolution: at the gate, spin up a tiny
**127.0.0.1 ephemeral server** that *serves* the live dashboard (same-origin POST trivial), accepts ONE
`POST /decision`, atomically writes `.dev-wiki/decision-response.json`, then exits; the orchestrator blocks
on a `run_in_background` watch and ingests through ONE deterministic validator. Three stdlib-only scripts;
Architecture/Decisions panes CUT to a STATUS+DIRECTION floor; no daemon; ONE gitignored write; eval 50/50.

## Decisions

- [[project-state-dashboard]] (high) — opt-in ephemeral-server act-from-page gate + render-only monitoring
  floor. Ledger Phase-106 all_accept:true (4 direction forks + 6 build-assumptions under "Continue"; A1
  round-trip-removes-friction flagged weakest + cheaply reversible via the opt-in marker + AskUserQuestion
  fallback).

## Method notes

- **Design hardened by a 13-agent ground+adversarial-stress workflow BEFORE any code** (6 failure-mode
  lenses). It tightened the design materially: the single-accept latch, atomic `mkstemp→fsync→os.replace`,
  off-thread shutdown (the serve_forever deadlock), the server-owned watchdog sentinel, the opt-in marker
  (safe-by-default, no gate self-brick — Ph82), and the deterministic boundary validator shared by
  server+ingest (the soul's "deterministic validators at boundaries, not neural judges").
- **Deterministic validator FIRST (T1).** `validate-decision-response.py` is the contract everything
  depends on (server POST + dev-plan ingest both RUN it). Controls-first: 4 seeded-defect fixtures
  (stale-nonce / partial-coverage / phantom-option / bad-position) each REJECTED; legacy nonce-less brief
  fails open.
- **Anti-drift import, not copy.** `generate-dashboard.py` imports `render_options`/`render_assumptions`/
  `esc`/`load_brief`/`validate_brief` from `generate-direction.py` via `importlib` (hyphenated filename →
  no plain import). The original task success-grep assumed a plain `import` and was corrected (DISCOVERY).
- **A post-implementation adversarial review (12-agent workflow, find→verify-each) caught 5 real defects;
  all fixed inline + re-verified.** See below — the MEDIUM one was a dead control.

## Health Delta

- +3 stdlib scripts (`validate-decision-response.py`, `generate-dashboard.py`, `decision-server.py`),
  +3 controls-first test scripts (+10 fixtures), +1 `make dashboard` target, +3 dev-plan companion edits.
- README 30→33 scripts; MANIFEST md5 refreshed for the 3 edited dev-plan companions; ~3 files synced to
  `~/.claude` (drift 0).
- `make test` ALL-PASS (33 registered scripts), `make eval` 50/50 (no scenarios added), drift 0, ZERO
  settings.json change, ONE gitignored runtime artifact.

## Adversarial review — confirmed findings (5/6, 1 refuted) + fixes

- **MEDIUM — S4lat was a DEAD INSTRUMENT** (`test_decision_server.sh`). Mutation-verified: deleting the
  `self.server.accepted = True` latch left all 13 tests green. Root cause: after the first valid POST the
  server shuts down, so a 2nd *network* POST always gets connection-refused (ERR), never the 409 the latch
  emits — and the `409 || ERR` check swallowed exactly the defect it existed to catch. FIX: replaced with an
  in-process latch test that suppresses post-accept shutdown so the 409 path is reachable; asserts EXACTLY
  409. Re-mutated to confirm it now goes RED on a removed latch (latch→409, no-latch→200).
- **LOW — slow-loris / no per-connection socket timeout** (`decision-server.py`). A stalled body read blocks
  the single-threaded server WHILE HOLDING the lock → the watchdog `_on_timeout` contends on the SAME lock
  → the sentinel never gets written, defeating the "server owns the single timeout" invariant + leaking the
  process. FIX: `DecisionHandler.timeout = 30` (socketserver sets `connection.settimeout`); a stalled read
  raises `socket.timeout`, releases the lock, lets the watchdog fire.
- **LOW — timeout sentinel was nonce-blind** (`watcher_ready`). The decision branch required a fresh nonce
  but the timeout branch released on ANY `{status:timeout}` file → a leftover prior-gate sentinel could
  release the next gate (fail-open, so safe, but spurious). FIX: the server stamps `brief_nonce` into the
  sentinel; the watcher (+ companion prose) require a nonce match on the timeout branch too; +2 controls.
- **LOW — double-escaped `&hellip;`** (`generate-dashboard._digest`): the entity was appended then
  `html.escape`d → `&amp;hellip;` (rendered as literal text). FIX: escape the text BEFORE appending the raw
  entity.
- **LOW — atomic-write duplication** (`_atomic_write` vs `handle_decision`): DEFERRED — pure DRY,
  both copies correct, the finding itself rated "only when next touching the atomic-write path" (my edits
  changed the sentinel *content*, not the write mechanism). Logged as a follow-on.
- REFUTED: 1 finding.

## Escape hatches / DISCOVERY

- **DISCOVERY ×2 (portability):** macOS has no GNU `timeout` (the server tests carry their own self-watchdog
  instead); and `helpers.sh` does `set -euo pipefail`, so a test that checks exit codes manually must
  `set +e` AFTER the source (an inherited errexit otherwise aborts the run on the first expected non-zero —
  cost me real debugging time before I traced it).
- **Re-bit the Ph84 zsh word-split lesson:** an unquoted `$FILES` list in a `for` loop did NOT split in zsh
  (the sed loop silently ran once on a bogus arg, fixing nothing). Caught it, redid with a literal list —
  my own working-knowledge entry warned about exactly this.
- Corrected the eval denominator in the planning docs (52→50; Ph88's detect-loop cut dropped it to 50, the
  design workflow inherited the stale 52).

### Gate Compliance

Direction gate confirmed 2026-06-23 (4 AskUserQuestion rounds → "Continue"; ledger Phase-106, all_accept:true).
Delivery gate accepted this session (autonomous run per the maintainer's standing waiver for clear-direction
phases) → commit closes it.

## Soft Observations / Phase N+1 Candidates

- **First real-world use of the act-from-page channel:** the next `/dev-plan` direction gate, with
  `.dev-wiki/act-from-page` present, will exercise the server→watch→ingest loop for real — confirm it lands
  for the maintainer (A1 is the weakest assumption; one real use settles whether the round-trip removes
  friction or just swaps it).
- **DRY the atomic-write helper** in `decision-server.py` (deferred review finding) — only when that path is
  next edited.
- **Pillars 1–2** (contract-fidelity spine + downstream workers) remain the other rung-C direction.
