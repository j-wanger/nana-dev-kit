# Spec: Spec/Dev-Plan UX Unification

## Objective

Eliminate the manual /spec → /dev-plan handoff by making dev-plan auto-invoke /spec when no spec exists for the target phase, and investigate the intermittent /spec routing failure.

## Context

nana-dev-kit's lifecycle is spec → plan → execute → debrief. Currently, dev-plan Step 0.6 (standard ceremony) checks for `specs/<slug>.md` and STOPs with "Run /spec first" when none exists. The user must manually invoke /spec, complete its full flow (context → thinking → adversarial constraints → draft → two-tier review → approval → persist), then re-run /dev-plan from scratch. This friction was flagged by the user as a persistent UX problem. Additionally, /spec routing (skill listed in available-skills but not recognized as a command) has been an open blocker across 4 phases — though the Skill tool invocation works in the current session. dev-plan SKILL.md is 338/350 lines, leaving 12 lines of headroom.

## Scope

### In scope
- dev-plan SKILL.md Step 0.6: replace STOP with auto-invocation of /spec via Skill tool
- Companion file for auto-invocation protocol (if Step 0.6 replacement exceeds line budget)
- /spec routing investigation: reproduce, root-cause, fix or document
- install.sh: copy companion file if created
- Tests for the auto-invocation flow and routing

### Out of scope
- Changes to spec SKILL.md content (review gates, template, etc.)
- Stale-spec content validation (file exists but wrong scope — future improvement)
- Lite ceremony reconciliation (lite skips Step 0.6 by design; the "never skip spec" feedback applies to standard ceremony agent behavior, not project ceremony config)
- enforce-spec.sh changes (operates at PreToolUse level, independent of dev-plan flow)
- Changes to the spec two-tier review process

## Approach

Replace dev-plan Step 0.6's STOP behavior with a reference to a new companion file `spec-auto-invoke.md` that defines the auto-invocation protocol. The companion file approach is the default (not a fallback) because 12 lines of headroom is too tight for inline auto-invocation logic with three terminal states, user notification, and restart instructions. Step 0.6 in SKILL.md becomes a 3-4 line pointer to the companion file (~2 net lines saved vs current STOP text).

The companion file defines: invoke /spec via Skill tool, handle three terminal states (approved → continue, rejected → abort, review failed → abort), and restart. "Restart" means the agent re-reads `_CURRENT_STATE.md`, `tasks.md`, and the newly-created spec within the same execution, then continues from Step 1 — NOT recursive self-invocation of /dev-plan.

For the routing issue: check installed skill file structure, test user-side `/spec` invocation vs agent-side `Skill(skill="spec")`, and document findings. If it's a Claude Code platform behavior, document the workaround (auto-invocation makes it moot for the primary use case).

## Constraints (CRITICAL)

- dev-plan SKILL.md must stay ≤350 lines: prevents exceeding the complex-orchestration ceiling. The current 338 lines leaves 12 for inline changes; if more is needed, extract to companion file.
- Auto-invocation must restart dev-plan from Step 1 after spec completes: prevents stale state from pre-spec context being carried forward (the spec process may surface scope changes). Do NOT resume mid-flow.
- Three terminal states only — approved (dev-plan continues at Step 1), rejected by user (dev-plan aborts), review gate failed after retries (dev-plan aborts): prevents silent continuation with a partial or rejected spec.
- No circular invocation — dev-plan invokes /spec, /spec must NOT trigger dev-plan: spec's pre-check already guards this (it STOPs if dev-wiki has uncompleted tasks), but verify the guard holds when invoked from dev-plan context where tasks.md has 0 open tasks.
- User must see "No spec found — invoking /spec now" before the spec flow begins: prevents surprise wall-time from a multi-minute process the user didn't expect inside dev-plan.

## Deliverables

1. Modified `~/.claude/skills/dev-plan/SKILL.md` Step 0.6 — pointer to companion file replacing STOP
2. New companion file `~/.claude/skills/dev-plan/spec-auto-invoke.md` — auto-invocation protocol with terminal states
3. Routing investigation findings documented in dev-wiki decision article
4. Updated `install.sh` — copy companion file in dev-wiki module
5. Updated `tests/test_install.sh` — companion file presence assertion
6. Updated `tests/test_templates.sh` — SKILL.md line-count + companion file cross-reference assertions

## Exit Criteria (machine-checkable)

- [ ] `test -f ~/.claude/skills/dev-plan/spec-auto-invoke.md`
- [ ] `grep -q 'spec-auto-invoke' ~/.claude/skills/dev-plan/SKILL.md`
- [ ] `! grep -q 'Run.*\/spec.*first.*STOP' ~/.claude/skills/dev-plan/SKILL.md`
- [ ] `[ $(wc -l < ~/.claude/skills/dev-plan/SKILL.md) -le 350 ]`
- [ ] `test -f .dev-wiki/articles/decisions/spec-routing-investigation.md`
- [ ] `grep -q 'spec.auto.invoke\|auto_invoke_spec' tests/test_templates.sh`
- [ ] `make test`

## Checkpoints

- After routing investigation (before any SKILL.md changes): report findings — is it platform-side or fixable in nana-dev-kit?
- After Step 0.6 replacement is drafted: report line count and whether companion file is needed

## Assumptions

- The Skill tool invocation path (`Skill(skill="spec")`) reliably invokes /spec from within dev-plan context. If false: the auto-invocation approach is not viable; fall back to documenting the manual flow with better UX messaging.
- spec SKILL.md's pre-check (STOP if dev-wiki has uncompleted tasks) prevents circular invocation when called from dev-plan. If false: add an explicit re-entry guard (marker file or argument flag).
- 12 lines of headroom in dev-plan SKILL.md is sufficient for inline auto-invocation. If false: extract to companion file.
