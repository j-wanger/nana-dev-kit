---
title: "Phase 65: Enforcement-Trace Instrumentation + Eval-Apparatus Disposition"
aliases: ["phase-65-enforcement-trace-instrumentation", "phase-65"]
category: phases
tags: [eval-validity, instrumentation, measurement-before-optimization, fail-open, enforcement-log, disposition, subtraction-test]
parents: [phase-63-remediation-roadmap]
created: 2026-05-29
updated: 2026-05-29
source: plan
status: active
scope: ["templates/.claude/hooks/**", ".gitignore", "templates/.claude/skills/py-init/**", "templates/.claude/skills/ts-init/**", "tests/test_firing_log.sh", "Makefile", "eval/comparison/**", "eval/reasoning/README.md", "eval/reasoning/with-self-dialogue-*/", ".claude/rules/**"]
entry_criteria: "Phase 64 complete + committed; spec specs/phase-65-enforcement-trace-instrumentation.md nana:approved 2026-05-29 (Tier-1 accept after C1-C4 fixes); direction confirmed 2026-05-29 (build eval substrate + disposition, after the approach-review reversed a scored-fixture-replay as corpus-duplication)"
exit_criteria: "log_firing pattern present + functional in all 6 instrumented hooks (jq-validated record); fail-open proven under chmod-000 AND stubbed jq/date; injection + exfiltration safe; enforcement.log untracked here + appended at all 4 py-init/ts-init gitignore sites; test_firing_log.sh green + in make test; test_enforce green (no decision regression); comparison A-vs-C retired (tombstone, A-vs-B kept); reasoning README calibration-only (ablation section kept) + test_templates green; with-self-dialogue dirs gone; make eval 52/52; make test + test_registration + test_settings_template green; referential integrity intact; no scorer shipped"
---

# Phase 65: Enforcement-Trace Instrumentation + Eval-Apparatus Disposition

## Objective

Build the missing measurement substrate for a future non-blind agentic eval — structured, fail-open firing records emitted by the lifecycle-enforcement hooks — so a Phase-66 scorer can ask "did a component fire and change an action?" from observed data, not a judge's opinion. Plus execute the eval-apparatus disposition the [[eval-validity-verdict]] prescribes. No scorer this phase: measurement + cleanup, not a new gate. See [[instrument-not-score-enforcement-firing-substrate]].

## Scope

Instrument the committed 6-hook lifecycle-enforcement set: harden + retrofit the 3 existing loggers (`enforce-spec`, `enforce-loop`, `enforce-memory`) and wire the 3 silent ones (`dev-wiki-scope-check`, `detect-loop`, `check-tests-were-run`). One shared hardened `log_firing` pattern → `.dev-wiki/enforcement.log` (`{schema_version,ts,hook,action,reason,phase}`). Untrack the log (gitignore + `git rm --cached` + py-init/ts-init append ×4). Disposition: retire `eval/comparison` A-vs-C arm, demote `eval/reasoning` to calibration-only, delete orphaned `with-self-dialogue-*` dirs. **Out:** the scorer (Phase 66), `block-dangerous-bash`/`post-commit`/`cognitive-readiness` instrumentation, the `audit-log`/`.nana/audit.jsonl` mechanism, reasoning-quality measurement.

## Exit Criteria

See the spec for the machine-checkable list. Headline gates: all 6 hooks emit a jq-valid record; fail-open proven (both chmod-000 + stubbed-jq/date variants); injection+exfiltration safe; `enforcement.log` untracked + ignored at all 4 scaffold sites; `make test` (incl new `test_firing_log.sh`) + `test_enforce` + `test_registration` + `test_settings_template` green; comparison retired + reasoning demoted + self-dialogue dirs gone; `make eval` 52/52; referential integrity intact; no scorer shipped.

## Constraints

Logging exit-code-neutral under `set -euo pipefail` (a log failure must not abort a hook before its decision — a full disk could let `rm -rf` through); `jq --arg` only, never raw user input (secret-exfiltration); atomic single `>>`, truncation off the hot path (the existing read-modify-write races); untrack the log (runtime state, not source); gate OR on `.dev-wiki`/`.claude/enforce`; template edits quarantine-first (modules.json SSOT, settings.json generated); `make eval` count must not move; demote ≠ delete ≠ retire (distinct checks); no deletion without a full-tree reference sweep.

## Checkpoints

After the hardened pattern + ONE pilot hook + the fail-open/injection tests pass (the riskiest unit, moved falsification checkpoint): report fail-open proof before propagating; if it can't be met, STOP. Before any `eval/` deletion: confirm `results/` empty + sweep clean (esp. `test_templates.sh` + working/active-knowledge). If instrumenting a hook needs a decision-logic change (not an additive log call): STOP.

## Abort Rule

If T1's fail-open contract can't be met cleanly → STOP, report (the substrate would be unsafe). If a deletion would dangle a `source:`/`[[…]]` link in working/active-knowledge, or a test depends on a deletion target → STOP, reconcile. If instrumentation moves `make eval` off 52 or regresses `test_enforce` decisions → revert that change. The fixture-replay-equals-corpus finding is settled — do NOT reintroduce a scored fixture eval. Blocked >3 attempts → mark [blocked:], report, ask skip-or-abort.
