<!-- nana:approved -->
# Spec: Phase 74 — Harden the Consuming-Project Scaffold Path

## Objective

Fix the concrete scaffold defects surfaced by the first real consuming-project dogfood
(edge-screener, Phase 73), at the **source** (kit templates/skills), so future consuming
projects boot with a correct, non-looping, lint-clean harness and domain-neutral conventions.

## Success Vision

A fresh `py-init` + `dev-init` consuming project: (1) its `py-review` Stop hook never loops
during planning and fires once when code changed; (2) ships with the `session-start.d/`
curators; (3) passes `ruff`/`mypy` out of the box; (4) inherits a domain-neutral AGENTS.md.
nana-dev-kit's own `make test` stays green throughout (registration, settings-drift,
firing-coverage, README count guard).

## Scope

IN:
- `templates/.claude/hooks/py-review-stop.sh` (new, gated command hook); remove `py-review-stop-prompt.md`.
- `modules.json` (py-review Stop hook: prompt → command); regenerated `templates/.claude/settings.json`.
- `templates/pyproject.toml` (ruff `extend-exclude`, mypy `files`).
- `templates/AGENTS.md` (domain-neutralize).
- `.claude/skills/py-init/SKILL.md` Step 4 (recursive hook copy).
- Tests: firing test for `py-review-stop.sh`; updates to firing-coverage / registration / settings-template / README-count guards as the conversion requires.

OUT (deferred, documented):
- dev-init/dev-plan CWD-coupling (target a sibling project) — skill-architecture change, not scaffold content; YAGNI until it recurs.

## Constraints

- `modules.json` is the single source; `templates/.claude/settings.json` is GENERATED — regenerate via `make template`, never hand-edit (prevents settings drift, [[decision:single-source-scope-tagged-hook-registration]]).
- The new hook must satisfy the firing-coverage gate: a `# fires:` declaration anchored to a real invocation (prevents the silent-breakage class the gate exists to stop).
- `py-review-stop.sh` must fail-open (jq guard), guard the stop-loop (`stop_hook_active`), and gate on `.py` changes — mirrors `check-tests-were-run.sh`.
- Surgical: every changed line traces to one of the 4 findings. No unrelated cleanup.

## Assumptions

- The edge-screener `py-review-stop.sh` (already proven by firing tests) is the correct shape to port. If a kit-template difference surfaces (e.g., scope/install path), reconcile before copying.
- Converting prompt→command keeps the total hook entry count at 18 (one entry retyped), but shifts the *.sh/*.md file counts and the firing denominator by 1. README/count guards updated accordingly.

## Exit Criteria

- [ ] `make test` green (registration 41/41 or updated, settings-template no-drift, firing-coverage green incl. the new hook, README count guard green).
- [ ] `make eval` 52/52 unchanged (no eval surface touched).
- [ ] py-review-stop.sh firing test passes all three paths (no-py→0, py+first→2, stop_hook_active→0).
- [ ] A fresh-scaffold smoke (or template-content assertions) confirms ruff/mypy guards + curator copy + domain-neutral AGENTS.md.
- [ ] Deferred #5 recorded in the roadmap/state.
