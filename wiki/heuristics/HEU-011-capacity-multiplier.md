---
id: HEU-011
trigger: "prioritizing between multiple competing initiatives where one enables or reduces the cost of the others"
domain: architecture
source_phase: 53
confidence: medium
helpful: 0
harmful: 0
status: active
---

# Heuristic: Choose the Capacity Multiplier

## When this applies
Choosing between two or more competing initiatives, projects, or technical debt items when the team can only execute a subset. At least one option has a unique property: completing it first makes the remaining options cheaper, faster, or more likely to succeed.

## Always
- Before comparing visible impact, check: does any option reduce the cost or increase the velocity of doing the others?
- Quantify the capacity gain: how many engineer-hours per week does this return? Over what remaining timeframe?
- Prefer the option that maximizes future throughput over the option with the most immediate user-visible impact
- Check for strict prerequisites (blocks others entirely) vs enablers (makes others cheaper) — prerequisites win unconditionally

## Never
- Choose the most urgent or most visible option without checking for capacity multipliers
- Optimize for the single metric with the most executive attention when a systemic bottleneck exists
- Dismiss capacity gains because they are harder to measure than feature delivery
- Treat all technical debt items as interchangeable — some create leverage, most do not

## Why
Capacity-multiplier choices compound. An initiative that returns 10% of the team's time every week creates more total value than a one-time improvement with higher visible impact, because every subsequent week benefits from the recovered capacity. The most common failure mode is metric-driven prioritization: choosing the option with the most measurable user impact while ignoring systemic drag that slows ALL future work. Teams that consistently choose leverage over visibility ship more total value over a quarter than teams that chase the biggest metric each sprint.

## Anti-pattern
"Database optimization has the most measurable user impact (800ms → 400ms on 60% of traffic)" → The metric-driven choice optimizes for the most visible number while ignoring that 15% flaky CI costs the team 8 engineer-hours per week in triage. Fixing CI reliability returns ~80 hours over the quarter — equivalent to 2 engineer-weeks of recovered capacity that can fund the database optimization AND more.

| Failure Mode | Detection Signal | Why It Fails |
|---|---|---|
| Urgency-driven prioritization | Rationale cites deadlines or CVEs as primary driver when mitigations exist | Urgency signals trigger action bias; mitigated risks can wait one iteration while capacity improvements cannot retroactively reclaim lost velocity |
| Visible-metric maximization | Prioritization doc ranks options by user-facing metric improvement with no capacity analysis | Optimizes for what is easiest to measure, not what creates the most total value; systemic bottlenecks are invisible in user metrics |
| Treating debt items as fungible | Triage assigns equal priority to all "high" debt items without checking dependency relationships | Ignores that some debt creates leverage (enables future work) while most debt is merely maintenance; flat prioritization misses compounding |

## Source
Scenario 020 (tech debt triage): model consistently chooses dependency upgrade (most urgent/visible) over test reliability (capacity multiplier that returns 8 engineer-hours/week). 8/9 eval runs chose wrong. Pattern recognized in Phase 53 investigation.
