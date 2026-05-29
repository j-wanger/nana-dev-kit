---
title: "Phase 63 remediation roadmap — deferred harness-assessment actions (each with a decidable-when)"
aliases: ["phase-63-remediation-roadmap", "harness-remediation-roadmap"]
category: phases
tags: [roadmap, harness-assessment, deadweight, decidable-when, phase-64]
parents: [phase-63-harness-assessment-eval-validity]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

Deferred actions from the Phase 63 harness assessment. Each item is gated by a decidable-when observable (the `decidable-when` line below it) — it converts to a clear cut/fix only when that observable holds. This deliberately breaks the "measured, ambiguous, deferred" cycle ([[eval-validity-verdict]]): an item without a decidable-when is not roadmap-ready. Ordered by leverage. Slam-dunks already executed in Phase 63 (session-start.d cp-fix, wiki-query flip-flop, /dev-context actionable phantom, wiki-consolidate quarantine) are NOT listed here.

- **Heuristic SCORING machinery cut (keep the 17 articles)** — remove `heuristic-matcher.md`, `heuristic-judge-prompt.md`, `heuristic-counter-update.md`, `heuristic-lifecycle.md`, `heuristic-dashboard.py`, dev-plan Step 13 sub-items 6-7, dev-debrief `heuristic-capture.md`. The scoring loop is genuine ceremony (18 counters at 0/0, `git log -S 'helpful: 1'` empty across 13 phases) but the articles are live test fixtures + feed the eval/reasoning injection experiment, so it is a coupled removal: cut 2 of 54 make-eval scenarios (→52), curate 5 hot-cache entries, clean test_companions frontmatter.
  decidable-when: a scoped removal plan separates machinery from articles AND `make test` stays green AND `make eval` = 52/52 — proving the cut touched only the unexercised scoring loop, not the fixture articles or the eval-reasoning injection path.
- **Self-dialogue Step 11 removal (BATCHED with the heuristic cut above)** — Step 11 is net-neutral (subagent variant, Phase 47) with a dangling unshipped injection source (`iron-rules-injection-v2.md`). Removal forces a dev-plan Steps 12-18→11-17 renumber that ripples across ~20 cross-references in 8 companion files — the SAME renumber surface the heuristic cut touches (Step 13 + its companions). Doing them in one renumber pass avoids a wasteful double-renumber.
  decidable-when: the heuristic-cut renumber pass is scheduled AND `test_step_numbering.sh` is green after a combined Step-11+Step-13 removal renumber AND the `test_templates.sh` self-dialogue assertions (lines ~876-887) are removed in the same change.
- **Build the real-agentic-workflow eval** — the non-blind replacement proposed in [[eval-validity-verdict]] (did-a-component-fire-and-change-an-action, off enforcement.log + git-cadence + detect-loop substrate, no LLM judge in scoring).
  decidable-when: the maintainer approves the proposed eval design — the spec governing Phase 63 is propose-not-build, so this is unblocked only once the design is accepted (the `mixed` verdict already satisfied the sensitivity precondition).
- **Execute the eval-apparatus disposition the verdict prescribes** — retire `eval/comparison/`'s confounded A-vs-C arm and demote `eval/reasoning/` (LLM-judge) to a calibration tool only (never a feature gate) per [[eval-validity-verdict]].
  decidable-when: the real-agentic eval lands as the replacement feature-gate (above) — until a non-blind gate exists, the confounded arm is retired but the binary corpus (c) remains the sole trusted gate, so no gate-coverage is lost at retirement time.
- **session-start.d author-global drift** — the author's global `~/.claude/hooks/session-start.sh` is a stale pre-Phase-54 version with no session-start.d sourcing, so the Phase-62 curator has likely never fired in the author's own sessions. Fix via `install.sh --project-local` (NOT a hand-copy — session-start.sh is scope=project; a naive ~/.claude re-sync repeats the design error).
  decidable-when: after running the project-local installer in nana-dev-kit, `ls .claude/hooks/session-start.d/wk-prune.sh` resolves AND a SessionStart event produces curator output — confirming the curator fires in the dogfood environment.
- **audit-log hook: wire-or-cut** — the `audit-log` PostToolUse hook advertises `.nana/audit.jsonl` (file-lifecycle.md) but produces no output in the live repo (no `.nana/` dir); it is a `--project-local` opt-in not installed here.
  decidable-when: a synthesized PostToolUse Write event piped into `audit-log.sh` in a `--project-local` sandbox either produces a `.nana/audit.jsonl` line (→ KEEP, it works, just not installed here) or does not (→ CUT the advertised side-effect from file-lifecycle.md).
- **long-cadence hooks firing tests** — `pre-compact.sh`, `post-compact.sh`, `session-stop.sh`, `check-tests-were-run.sh` are registered, fire rarely, and write nothing to enforcement.log by construction, so log-silence is not deadweight evidence.
  decidable-when: a synthesized-trigger firing test (pipe a real PreCompact/Stop event, assert behavior) for each, in a --project-local sandbox for the project-scoped ones — fires-and-changes-an-action → KEEP, structurally-passes-but-no-effect → reclassify.
- **MCP-memory ⊂ hot-cache redundancy** — the bridge DECISION write path duplicates the always-loaded cache (Phase 61 read-path delta=0.00, CUT), but the harvest CORRECTION/PREFERENCE path is UNIQUE to MCP (no hot-cache representation, grep-confirmed), so a clean cut loses that content.
  decidable-when: the D2 re-test trigger fires (MCP store grows past the cache cap with distinct, non-decision harvest entries) AND an A/B shows the harvest read-path adds trajectory value the cache cannot — until then the write path stays (fail-open, cheap).
- **eval/reasoning committed .venv hygiene** — a committed virtualenv bloats the repo; `run-eval.py` is a pure analysis utility (no LLM calls) and the corpus are live test deps, so only the `.venv` is removable.
  decidable-when: decidable now — `git rm -r --cached eval/reasoning/.venv` + gitignore; independent of the manual-only eval/reasoning disposition.
- **/dev-context descriptive-reference cleanup** — ~8 SSOT companion specs still name the phantom `/dev-context` as a data-flow actor ("Consumed by dev-context", "Read by /dev-context") — stale-naming debt, not a functional bug (the Phase-63 slam-dunk already fixed every *actionable* "Run /dev-context" instruction + router description). Coupled to the broader "/dev <subcommand>" vs "/dev-<skill>" naming-convention question.
  decidable-when: a naming-convention decision fixes whether dev-* commands are written `/dev-plan` or `/dev plan`, AND a single sweep updates the descriptive references to the real loader (the dev-wiki session-start protocol) in the same pass.
