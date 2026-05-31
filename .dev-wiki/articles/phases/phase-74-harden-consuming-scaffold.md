---
title: "Phase 74: Harden the Consuming-Project Scaffold Path"
aliases: ["harden-consuming-scaffold"]
category: phases
tags: [engineering, scaffold, py-init, hooks, templates, dogfood, consuming-project]
parents: []
created: 2026-05-30
updated: 2026-05-30
source: plan
status: completed
scope: ["templates/.claude/hooks/*", "templates/pyproject.toml", "templates/AGENTS.md", "modules.json", "templates/.claude/settings.json", ".claude/skills/py-init/SKILL.md", "tests/*", "README.md"]
entry_criteria: "Phase 73 closed; first consuming-project dogfood (edge-screener) surfaced concrete scaffold defects."
exit_criteria: "py-review Stop hook is a gated command hook (no planning loop); py-init copies session-start.d curators; template pyproject lints/types clean out of the box; AGENTS.md template is domain-neutral. make test + make eval green."
---

# Phase 74: Harden the Consuming-Project Scaffold Path

## Objective

Fix at the source the scaffold defects the first real consuming-project dogfood
(edge-screener, Phase 73 — [[cross-session-substrate-stock-screener]]) surfaced, so future
consuming projects boot with a correct, non-looping, lint-clean, domain-neutral harness.

## Scope

- `templates/.claude/hooks/py-review-stop.sh` (new) + remove `py-review-stop-prompt.md`
- `modules.json` (py-review Stop hook prompt→command) + regenerated `templates/.claude/settings.json`
- `templates/pyproject.toml` (ruff `extend-exclude`, mypy `files`)
- `templates/AGENTS.md` (domain-neutralize)
- `.claude/skills/py-init/SKILL.md` Step 4 (recursive hook copy)
- `tests/*`, `README.md` (firing test + count/drift guards)

## Exit Criteria

- [ ] T1: py-review Stop hook converted to a gated command hook; firing test green; make test green (registration/settings-drift/firing-coverage/README).
- [ ] T2: py-init Step 4 copies the hook tree recursively (curators survive).
- [ ] T3: template pyproject ships ruff `.claude`/`data` exclude + mypy `files`.
- [ ] T4: template AGENTS.md domain-neutralized.
- [ ] T5 deferred (dev-init/dev-plan CWD-coupling) recorded in state/roadmap.
- [ ] make test + make eval 52/52 green.

## Constraints

- Constraint: `modules.json` single source; regenerate `settings.json` via `make template`, never hand-edit — prevents settings drift.
- Constraint: the new command hook needs a `# fires:` firing test — prevents the silent-breakage class the firing-coverage gate exists to stop.
- Constraint: surgical — every changed line traces to one of the 4 findings.

## Notes

The most severe item (py-review loop) was already fixed in edge-screener (`4236135`) as the
immediate unblock; T1 ports that fix to the kit template so it stops recurring. Source:
Phase 73 journal Soft Observations + the live edge-screener loop report.
