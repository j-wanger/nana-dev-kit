---
title: "Phase 74 — Harden the Consuming-Project Scaffold Path (the dogfood→harden loop pays off)"
date: 2026-05-30
category: journal
tags: [phase-74, engineering, scaffold, py-init, ts-init, hooks, templates, dogfood, firing-coverage]
phase: 74
---

# Phase 74 — Harden the Consuming-Project Scaffold Path

## Summary

The first real consuming-project dogfood (edge-screener, Phase 73) surfaced concrete scaffold
defects — most severely a **py-review Stop hook that looped during planning** (Jake hit it live).
Phase 74 fixed all four at the **source** (kit templates/skills) so future consuming projects boot
clean. Jake approved directly ("yes, do Phase 74 now"); kit `make test` was the quality gate; the
edge-screener fix (`4236135`) was the immediate unblock, T1 ports it to the template.

## What was done

- **T1 [L] — py-review Stop hook: `prompt` → gated command hook.** Added
  `templates/.claude/hooks/py-review-stop.sh` (jq fail-open + `stop_hook_active` loop-guard +
  `.py`-change planning-guard + exit-2 review checklist, mirroring `check-tests-were-run.sh`),
  removed `py-review-stop-prompt.md`, flipped the `modules.json` Stop entry prompt→command,
  regenerated `settings.json` via `make template`. RED-first firing test (3 paths) added to
  `test_long_cadence_hooks.sh` with a `# fires:` declaration; firing-coverage floor bumped 20→21.
- **T2 [S] — py-init + ts-init recursive hook copy.** Both Step 4 blocks collapsed to
  `cp -R "$KIT/.../hooks/." .claude/hooks/` + recursive chmod.
- **T3 [S] — pyproject out-of-box.** Template ships ruff `extend-exclude=[".claude","data"]` +
  mypy `files=["src","tests"]`.
- **T4 [M] — AGENTS.md domain-neutralized.** Dropped web-stack mandates; kept toolchain/testing/
  commit discipline + placeholders + a cue to substitute real domain rules.
- **T5 [S] — regression + deferred #5.** make test green, make eval 52/52, eval/ git-diff-clean;
  dev-init/dev-plan CWD-coupling recorded as DEFERRED.

## Decisions

- [[harden-consuming-project-scaffold]] (high) — fix the 4 defects at the source; defer #5 (CWD-coupling).

## Discoveries / deviations

- **T1 created a cross-coupling that T2 had to fix:** removing the *only* `.md` hook
  (py-review-stop-prompt.md) left a **dangling `cp .../hooks/*.md`** glob in BOTH py-init and
  ts-init Step 4 (the literal step would error with no matches). The recursive copy fixes it.
- **The curator gap (#2) was already fixed in the SOURCE template** (it copied `session-start.d/`
  explicitly) — the gap I recorded in Phase 73 was in the **stale INSTALLED `~/.claude` copy**. The
  honest fix: collapse to a recursive copy (future-proof vs the brittle explicit-subdir line) and
  note that a re-install resolves the installed-copy staleness.
- **Eval unaffected:** `eval/corpus/skill-prompt-valid/` validates its OWN `prompt.md` fixture, not
  the template hook — so removing the template prompt left `make eval` at 52/52.

## Health Delta (kit)

- Hooks: 18 entries unchanged; command hooks 17→18, prompt hooks 1→0 (`.sh` +1, `.md` −1 in templates/.claude/hooks).
- Tests: +3 firing tests (py-review paths) in test_long_cadence_hooks.sh; +8 assertions in test_templates.sh; firing-coverage floor 20→21 (now 21/21 covered).
- `make test` All tests passed; `make eval` 52/52 (unchanged); registration 41/41; settings-template no-drift.

## Review Gate

Independent adversarial reviewer (general-purpose subagent) on the Phase-74 diff → **VERDICT: SHIP**.
Falsification attempts that PASSED (no bug): py-review-stop.sh loop-proofing + gating edge cases
(null/absent/empty `tool_uses`, malformed JSON, missing jq all fail-open to exit 0), byte-parity with
check-tests-were-run.sh, recursive `cp -R hooks/.` captures all 21 .sh + session-start.d (POSIX/bash-3.2
portable), modules.json↔settings.json zero drift, firing floor 20→21 correct, AGENTS.md placeholders intact +
sync-rules unaffected, pyproject TOML valid, no shipped/active code references the removed prompt file.

- **[SHOULD-FIX] FIXED:** `scripts/generate-workflow.py:477,827` still described the removed prompt hook →
  updated both to `py-review-stop.sh` / command / `0=allow,2=force-continue`; regenerated `docs/workflow.html`
  via `make workflow`.
- **[NIT] no action:** `eval/corpus/skill-prompt-valid/` scenario name references the old hook but uses its own
  scenario-local `prompt.md` fixture (not the template) → eval stays 52/52. Intentional; left as-is.
- `docs/report.html` (a prior-phase delivery-report snapshot) still names the old hook — a frozen historical
  artifact, regenerated per-delivery; left as-is.

## Soft Observations / Phase N+1 Candidates

- The **installed `~/.claude/skills/` copies can drift from the `templates/` source** (the curator
  line existed in source but not in the installed py-init). There is no guard that the installed kit
  matches the template source. Candidate: an `install.sh --verify` / drift check, or surface kit
  version on session-start. (evidence: the Phase-73 "curator gap" was an installed-copy artifact.)
- The kit has **no fresh-scaffold smoke test** that actually runs `py-init`'s steps end-to-end and
  asserts the result lints/types clean — the defects here were only caught by manual dogfooding.
  Candidate: a sandboxed scaffold-and-verify test.
- **Process lesson (not a kit defect):** the review subagent was dispatched WITHOUT `isolation: worktree`,
  so it ran in the live working tree and a git/make operation it ran reverted the *uncommitted* `settings.json`
  to HEAD (re-introducing the prompt entry) — caught by the next `make test`, resynced via `make template`.
  Review/explore agents that run `make`/`git` against uncommitted work must use `isolation: worktree`.

## Gate Compliance

Phase 74: `direction=approved` ("yes, do Phase 74 now", 2026-05-30), `delivery=accepted` (this debrief). Both present.

## Next

nana-dev-kit → active phase NONE. The screener build continues in `/Users/jwang/edge-screener`
(Phase 1 Data Foundation). Standing nana-dev-kit options: the deferred cross-session measurement,
the two soft-observation candidates above (installed-copy drift guard; fresh-scaffold smoke test).
