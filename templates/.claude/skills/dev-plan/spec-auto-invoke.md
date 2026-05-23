# Spec Auto-Invocation Protocol

When dev-plan Step 0.6 finds no spec for the target phase (standard ceremony), follow this protocol instead of stopping.

## 1. Notify User

Output: `"No spec found for Phase N. Invoking /spec now — this includes adversarial constraints and two-tier review."`

This sets expectations for wall time (~2-5 minutes for the full spec flow).

## 2. Invoke Spec

Use the Skill tool: `Skill(skill="spec", args="Phase N: <objective from phase article or user description>")`

The /spec skill runs its full process: gather context, thinking protocol, adversarial constraint generation (subagent), draft 9-section spec, Tier 0 structural lint, Tier 1 semantic review (subagent), user approval, persist to `specs/<slug>.md`.

## 3. Handle Terminal States

Exactly three outcomes — no silent continuation with partial or rejected specs.

### Approved

The spec was approved by the user and persisted at `specs/<slug>.md`.

1. Output: `"Spec approved. Resuming dev-plan from Step 1 (state loading)."`
2. Re-read `_CURRENT_STATE.md`, `tasks.md`, and the newly-created spec file
3. Continue dev-plan from **Step 1** — do NOT resume mid-flow (the spec process may have surfaced scope changes that invalidate earlier context)
4. Step 0.6 will pass on restart since the spec file now exists

### Rejected by User

The user explicitly rejected the spec during /spec Step 5.

1. Output: `"Spec rejected. Dev-plan aborted — refine the objective and re-run /dev-plan."`
2. **STOP.** Do not continue dev-plan.

### Invocation Failed

The Skill tool returned an error, timed out, or /spec hit an unexpected state.

1. Output: `"Spec invocation failed. Run /spec manually, then re-run /dev-plan."`
2. **STOP.** Do not continue dev-plan.

## Circular Invocation Safety

The /spec SKILL.md pre-check stops if dev-wiki has uncompleted tasks (`- [ ]` in tasks.md). Between phases — when all tasks are marked `[x]` — this guard does NOT fire. Auto-invocation is safe in the between-phases window where dev-plan operates.

If the pre-check is ever modified to block between-phase invocation, add an explicit `--from-devplan` argument or transient marker file to signal legitimate auto-invocation.
