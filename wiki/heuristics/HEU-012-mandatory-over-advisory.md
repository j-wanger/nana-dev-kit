---
id: HEU-012
trigger: "adding a feature, hook, or check intended to change agent behavior, enforce a rule, or improve reasoning"
domain: architecture
source_phase: 57
confidence: high
helpful: 0
harmful: 0
status: active
---

# Heuristic: Mandatory Over Advisory (Verify Firing, Not Presence)

## When this applies
You are adding any mechanism whose value depends on it actually running at the
right moment: an enforcement hook, a quality gate, a recommendation to consult
knowledge, a "consider doing X" nudge, or any check meant to shape the agent's
next action.

## Always
- Implement behavior-shaping as a hook that mechanically blocks (exit 2) or as
  content injected into the always-loaded path (rules files, session-start output
  that changes the next action).
- Verify the mechanism FIRES, not that its file exists: pipe a real event through
  it and assert the effect (e.g. exit 2 / a log `block` event), in a clean
  environment with no ambient state.
- Ensure every dependency the mechanism reads is reachable from where it runs —
  an opt-in marker, config, or registration must be distributed to the same scope
  as the hook that consumes it.
- Test the scenario where the agent would skip the mechanism if it could.

## Never
- Ship behavior-shaping as a voluntary skill/tool the agent must choose to invoke,
  then trust advisory text ("consider running X") as a behavioral guarantee.
- Treat "the file exists / is registered" as evidence that it works.
- Register a hook in one scope while its opt-in marker or dependency lives in another.
- Assume the agent will voluntarily invoke something that slows it down.

## Why
The C/D stock-screener experiment (Phase 54-56) proved voluntary cognitive tools
contributed zero measurable value — the agent never invoked wiki-bootstrap, never
wrote specs (enforce-spec was unwired), never consulted heuristics. Mandatory
engineering hooks (ruff, mypy, secrets) contributed the entire measured advantage.
Coding momentum overrides anything that does not mechanically block it, even when
a context doc explicitly names what to do (D scored LOWER than C despite being
told the bugs). And "wired" is not "fires": enforce-spec was globally registered
yet dormant because its opt-in marker had been wiped — the failure survived two
full runs because reviewers checked presence, not firing (Phase 57).

## Anti-pattern

| Failure Mode | Detection Signal | Why It Fails |
|---|---|---|
| Advisory recommendation ("consider X") | The recommended action is optional and the flow continues without it | The agent's default momentum skips anything non-blocking |
| Presence-only verification | Test asserts a file/registration exists, never pipes an event through it | A registered-but-dormant mechanism passes the test and ships broken |
| Split registration and opt-in | Hook registered in one scope, its marker/config in another | Mechanism is live but never activates; looks wired, never fires |
| "It's optional so it's fine if it doesn't fire" | The mechanism only matters when something goes wrong | The one time it was needed, it was silently off |
| LLM-executed step verified by presence | The step is a markdown procedure (no exit code to pipe) and the test only checks the file/pointer exists | You can't assert exit-2; instead exercise BOTH branches behaviorally — the no-op case must show zero side-effects (e.g. zero external calls) and the active case must produce a named, attributable effect (Phase 58 Step 2.7) |

## Source
Phase 54-56 C/D stock-screener A/B test; Phase 57 hook-consolidation (enforce
marker was global; per-project registration alone was insufficient; py-init shipped
hooks but not the marker → registered-but-never-fires, caught only by a firing test).
See [[decision:single-source-scope-tagged-hook-registration]], [[HEU-002]] (fail-loud
is the diagnostic complement: surface the silent failure this heuristic prevents).
