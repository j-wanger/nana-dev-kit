---
id: HEU-007
trigger: "a single detection signal produces too many false positives"
domain: architecture
source_phase: 26
confidence: high
helpful: 0
harmful: 0
status: active
---

# Heuristic: Dual-Condition Gates Reduce False Positives

## When this applies
You're building a detection system (crash recovery, anomaly detection, drift
alert) and a single signal fires too often during normal operation.

## Always
- Require the conjunction of two independent signals before triggering an alert
- Choose signals from different information sources (filesystem + git, time + state, config + runtime)
- Make the gate advisory (warn) not blocking (error) unless you're confident in zero false positives
- Include the individual signal values in the alert for debugging

## Never
- Trigger alerts on a single noisy signal without a confirming condition
- Use two signals from the same source (they'll correlate in false positives too)
- Make a noisy gate blocking — users will disable it entirely

## Why
Single conditions often fire during normal workflow. "Commits newer than
state file" fires every mid-phase commit. Adding a second, independent
condition — "AND no debrief commit in history" — dramatically reduces false
positives because both conditions must simultaneously hold. This is the
engineering equivalent of requiring two independent confirmations before
acting.

## Anti-pattern
"Just raise the threshold" → Raising the threshold for one signal trades
false positives for false negatives. Dual conditions reduce false positives
without raising false negatives because the second signal is orthogonal to
the first.

## Source
Phase 26: Crash recovery used dual condition (commits newer than mtime AND
no debrief commit). Single condition (commits > mtime) fired on every
mid-phase commit. Adding the debrief check eliminated all false positives
while preserving detection of actual crashes.
