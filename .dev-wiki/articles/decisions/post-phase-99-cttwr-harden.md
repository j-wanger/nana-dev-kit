---
title: "Post-Phase-99: check-tests-were-run hardening (adversarial-workflow-found false-blocks)"
aliases: [cttwr-harden, check-tests-were-run-harden, post-phase-99-hook-hardening]
category: decisions
tags: [hook, check-tests-were-run, false-block, adversarial-verify, jq-tolerance, heu-012, dogfood]
parents: [direction-dashboard]
created: 2026-06-22
updated: 2026-06-22
source: plan
confidence: high
---

## Context

`check-tests-were-run.sh` (a project-local Stop hook) blocked the maintainer three times in the kit's
OWN tree during Phase 99: it hard-required the literal string `pytest`, but the kit has **no pytest** —
its suite is `make test` (shell). The original ask was minimal: accept `make test`/`make eval`. Under
ultracode, after the minimal fix I ran an **adversarial-verification workflow** (5 parallel lenses
hunting false-allow/false-block across event shapes), which surfaced **9 false-BLOCKS (5 HIGH)** — the
*harmful* class that traps a developer who actually ran their tests. The fix expanded accordingly.

## Decision

Comprehensive harden of the hook (the original `make test` acceptance plus 4 correctness fixes), each
verified controls-first (`tests/test_check_tests_were_run.sh`, 18/18 — block AND allow paths):

- **A — `make` target detection.** Accept `make test`/`make eval` AND tolerate flags/vars before the
  target (`make -j4 test`, `make -C dir test`, `make BAR=1 test`) by anchoring `make` to a command
  position and matching `test|eval` as a word after optional args. The anchor also kills the
  `git commit -m "make test"` false-*allow* (a quoted mention is not preceded by a command boundary).
- **B — jq line-tolerance.** Transcript JSONL is parsed with `jq -rR 'fromjson? | …'` so a malformed /
  truncated line (partial flush) is SKIPPED, not aborted. Naive `jq -r 'filter' file` aborts at the
  first bad line, dropping every later event → a test run after the bad line was lost → false-block.
- **C — `.py` extension anchor.** Condition-1 matches `\.py$` (not the substring `.py`), so editing
  `app.py.bak`, `mod.pyc`, or `notes.python-setup.md` no longer false-blocks.
- **D — legacy `.tool_uses` path split.** File paths and commands are separated in the legacy/eval
  shape too (was conflated), so a filename can't satisfy the command check and a command string can't
  satisfy the `.py` check. (Real Stop events use `transcript_path`; the legacy path is eval/test-only.)

## Why this scope

The triggering false-allow was advisory (a nudge under-fires). The workflow showed the bigger risk was
**false-blocks** (a nudge over-fires and traps you). Fixing only the ask would have left 5 HIGH
false-blocks live. Each finding was **orchestrator-confirmed** (I re-ran every repro deterministically;
subagent prose is not verdict evidence — [[qa-verification-sweep]]) before fixing.

## Acknowledged residual (deliberately NOT fixed)

`pytest` is matched as a plain substring, so `echo pytest`, `pip install pytest`, `cat pytest.ini`
false-*allow*. This is inherent to a grep heuristic and **pre-existing**; anchoring `pytest` like `make`
would break the legitimate mid-command forms `uv run pytest` / `python -m pytest` / `poetry run pytest`.
For an advisory nudge, a rare missed-fire is acceptable; a false-block is not. Status quo kept.

## Scope: kit-specific, not propagated

All 7 consuming projects are **pytest-only (no Makefile)** — the old hook works for them, so this bug is
genuinely kit-specific. Consumer propagation would be pure currency-hygiene with zero functional benefit
(filed, not done). signal-watch's copy was already separately divergent — a pre-existing consumer-drift
item, unrelated.

## Generalization (harden-candidate)

The jq non-tolerance (B) is a **general** pattern: any hook parsing transcript JSONL with
`jq -r 'filter' "$TRANSCRIPT"` shares the truncated-line false-block. Filed: audit the other
transcript-parsing hooks for `-R 'fromjson?'` tolerance.

## Source

Post-Phase-99 follow-on (the dashboard phase, [[direction-dashboard]], is complete). Adversarial
workflow `verify-cttwr-harden` (5 lenses, 23 findings). Controls-first per [[HEU-012]]; method is
implement → adversarial-verify → orchestrator-confirm → fix.
