---
title: "Decision: Harden the consuming-project scaffold path (fix dogfood defects at the source)"
slug: harden-consuming-project-scaffold
type: decision
status: accepted
confidence: high
source: plan
phase: 74
created: 2026-05-30
updated: 2026-05-30
tags: [engineering, scaffold, py-init, hooks, templates, dogfood]
---

# Decision: Harden the consuming-project scaffold path

## Context

Phase 73 made edge-screener the first **real consuming project** of the kit. Dogfooding it
surfaced concrete scaffold defects — most severely a **py-review Stop hook that loops during
planning**: the template registers it as a `prompt`-type Stop hook that injects unconditionally
on every stop, so with no code written yet it re-fired endlessly (Jake hit this live). Plus:
py-init's literal steps miss the `session-start.d/` curators; the bare pyproject fails
ruff/mypy out of the box on vendored `.claude/` code; the AGENTS.md template is a web-app stub.

## Decision

Fix the four defects **at the source** (kit templates/skills), in one phase:

1. **py-review Stop hook: `prompt` → gated command hook** (`py-review-stop.sh`, mirroring
   `check-tests-were-run.sh`): exits 0 when no `.py` changed (planning guard) or
   `stop_hook_active=true` (loop guard); blocks once with the review checklist only when code
   changed. Re-point `modules.json`, regenerate `settings.json`, add a `# fires:` firing test,
   fix the count/drift guards.
2. **py-init Step 4:** recursive hook copy so `session-start.d/` curators survive.
3. **pyproject template:** ship ruff `extend-exclude=[".claude","data"]` + mypy `files=["src","tests"]`.
4. **AGENTS.md template:** domain-neutralize (drop SQLAlchemy/FastAPI/repositories/Pydantic-mandatory defaults).

**Deferred (documented):** dev-init/dev-plan CWD-coupling (can't target a sibling project) —
a skill-architecture change, not scaffold content; the manual drive worked; YAGNI until it recurs.

## Why (alternatives considered)

- **Fix only edge-screener** (already done as the unblock, `4236135`) — rejected as the
  permanent fix: leaves the landmine for every future consuming project.
- **Hand-edit the kit settings.json** — rejected: it is a generated artifact; hand-editing
  drifts from `modules.json` and trips `test_settings_template.sh`. Regenerate via `make template`.
- **Convert py-review to a non-blocking advisory** — rejected: the review-when-code-changed
  value is real; the gated command hook preserves it without the loop.

## Consequence

A correct out-of-the-box consuming-project scaffold. The conversion shifts the firing-coverage
denominator (+1 command hook) and the *.sh/*.md counts, handled via the kit's RED-first test
guards. No eval surface touched (`make eval` unchanged). The dogfood→harden loop is the
intended payoff of Phase 73's "build a real consuming project."

## Source

Phase 74 plan; spec `specs/phase-74-harden-consuming-scaffold.md` (nana:approved). Evidence:
Phase 73 journal Soft Observations ([[2026-05-30-phase-73-cross-session-substrate-bootstrap]]),
edge-screener fix `4236135`.
