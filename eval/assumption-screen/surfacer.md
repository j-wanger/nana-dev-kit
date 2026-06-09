# Surfacer Spec (Phase 80, T3) — frozen prompts for the two conditions

Both conditions run clean-context on the SAME reconstructed plan-as-of-then per case (no repo/tool access).
Frozen here so the runs (T5) cannot be tuned post-hoc.

---

## Condition NAIVE (the strong baseline — the spike's prompt)

> You are given a software-project plan as it stood at planning time. List the load-bearing assumptions it
> makes — an assumption is load-bearing if the plan's outcome would change were it false. Output 3–6
> assumptions, one short sentence each, ranked by cost-of-error (worst-if-wrong first). Work ONLY from the
> plan text below; do not read files, do not search, do not use any tool.
>
> PLAN:
> <plan-as-of-then>

This is a worthy opponent: in the T1 spike it recovered all three TRACED load-bearing assumptions,
top-ranked. The SURFACER must beat THIS, not a strawman.

---

## Condition SURFACER (scope-anchored + framing)

> You are given a software-project plan as it stood at planning time. Surface its load-bearing assumptions
> in TWO passes. Work ONLY from the plan text below; do not read files, search, or use tools.
>
> PASS 1 — SCOPE-ANCHORED (completeness-by-construction):
>   (a) Enumerate every scope item the plan TOUCHES or DEPENDS ON — files, components, and INFRASTRUCTURE
>       it relies on (hooks, installers, config paths, data stores, budgets/limits, CI). Include the
>       infrastructure the plan silently assumes already works, not just what it changes.
>   (b) For each item, state its cost-of-error in one clause: what breaks if this item does NOT behave as
>       the plan assumes. This cost ranking is an explicit judgment — make it visible.
>   (c) For each HIGH-cost item, write ≥1 assumption of the form "X must be true about <item>", INCLUDING
>       the is-it-actually-so assumptions: is this hook installed and firing? does this store persist at the
>       path we think? is this file within its budget? is this dependency wired? Tag each `[scope:<item>]`.
>
> PASS 2 — FRAMING: list load-bearing assumptions that map to NO scope item — about the framing itself
>   ("is this problem worth solving?", "is this the right substrate/approach?", "will the measured effect
>   replicate?"). Tag each `[framing]`.
>
> OUTPUT: the union of both passes, ranked by cost-of-error (worst first), each line tagged `[scope:<item>]`
> or `[framing]`.
>
> PLAN:
> <plan-as-of-then>

### Headroom hypothesis (what would make SURFACER beat NAIVE on the silent class)
The naive prompt surfaces SALIENT design assumptions but tends not to interrogate infrastructure it takes
for granted. PASS-1(c)'s forced "is-it-actually-so" enumeration over infrastructure scope items is the
mechanism by which SURFACER might recover a silently-buried assumption (e.g., "the enforcement hook is
actually firing", "memory persists at this path") that NAIVE misses. If it does not, the machinery does not
earn its keep (DEGENERATE or BLIND per the pre-registration).

### Coverage property (deterministically checked — `coverage-check.sh`)
A SURFACER output is COVERAGE-COMPLETE iff every high-cost scope item declared in PASS-1(b) carries ≥1
`[scope:<item>]` assumption in PASS-1(c). This is the scope track's completeness-by-construction guarantee;
it is checkable without an LLM. (It does NOT guarantee recovery — that is the screen's job — only that no
declared high-cost item was left without an assumption.)
