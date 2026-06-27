---
title: "Phase 111 — Typed Artifact Fidelity + host-gate out-of-workspace hardening: BUILT + adversarially reviewed (READY FOR COMPLETION)"
aliases: []
category: journal
tags: [gui-harness, artifacts, diff, typed-details, pi-adapter, security, host-gate, engine-neutral, dogfood]
parents: [phase-111-typed-artifact-fidelity]
created: 2026-06-27
updated: 2026-06-27
source: debrief
duration: long session (full /dev-plan → security-finding detour → /dev-plan replan → full T1-T5 implementation → adversarial review → fixes → debrief)
---

# Phase 111 — Typed Artifact Fidelity + host-gate out-of-workspace hardening: BUILT + adversarially reviewed

## What Happened

The de-risked Ph110 follow-on, planned + implemented + reviewed in one long session. Ph110 threaded real tool args/output through the engine-neutral layers but the artifact panel still routed via the `looksLikeDiff` SHAPE heuristic + generic-text fallback because Pi's typed `details` were deferred. Phase 111 threads Pi's typed `details` (normalized to a neutral `{diff?: string}` at the adapter) ADDITIVELY through the EXISTING layers — `types.ts` `tool-result` EngineEvent → `runtime.ts` `SurfaceToolCall` → `artifact-feed.ts` `toArtifact` — so an edit renders a STRUCTURED canonical DiffView. A single vertical thread source→surface, no engine-type reshape (same Ph108/109/110 invariant).

**The session pivoted on a security finding.** Capturing the regression baseline exposed a REAL host-gate coverage gap: the workspace boundary was enforced ONLY for `write`/`edit` with an `args.path` key — bash file-writes (`echo>`/`tee`/`cp`/`mv`/`dd`) and alt-named write tools BYPASSED it (deterministically confirmed at the gate, no model). Ph108's "empirically un-bypassable" claim was happy-path-only. The flaky `provider-roundtrip` e2e was intermittently catching this; the as-planned T4 ("soften the assertion") would have MASKED it. The maintainer directed (AskUserQuestion) "fold a gate fix into Phase 111" — a SECURITY escape-hatch scope amendment (ledger A5); T4 reshaped from "pin the flaky e2e" → "close the gate gap" and reordered FIRST.

All 5 tasks RED→GREEN→VERIFY with a full-suite regression each: **T4** host-gate hardening (default-branch `PATH_ARG_KEYS` check + bash-branch `extractBashWriteTargets` + `DEV_SINK` exemption; verdict-loop core untouched) → **T1** `extractToolDetails` normalization seam + the A1 live spike → **T2** reduction threads `details` (additive, JSON round-trip) → **T3** router: typed-diff branch WINS over the heuristic → **T5** deterministic integration e2e + adversarial review + full gate.

**A1 spike HELD (live local edit):** `tool_execution_end.result.details.diff` IS on the subscribe path — emitted `{diff:'-1 hello world / +1 goodbye world / 2 second line'}`, file really edited; the `pi.on('tool_result')` fallback was NOT needed. The header-less `+`/`-`/space diff format (no `---`/`+++`/`@@`) means Ph110's `looksLikeDiff` would MISS it — so the typed path is strictly BETTER, not just a refactor.

## Decisions Made

- [[host-gate-out-of-workspace-hardening]] (high, NEW) — extend base-policy coverage (bash write-target gating + alt-named-write default-branch check + DEV_SINK exemption), confirmable not hard-deny, verdict-loop core unchanged; honest residual = string-gating bash is incomplete by nature → OS-sandbox follow-on.
- [[typed-artifact-fidelity]] (high, updated BUILT + DELIVERED) — A1 resolved HELD; typed-diff branch wins over the heuristic; TestResults stayed descoped.

## Problems Solved

- **Host-gate out-of-workspace gap** — closed the demonstrated + common vectors deterministically (`tests/gate/host-gate-coverage.test.ts`, 24 cases); the e2e out-of-workspace assertion is now ship-blocking-true for ALL vectors (it FAILED at this session's baseline, now passes for real).
- **Adversarial finder×refuter Workflow review** (6 finders × 2 refuters, 22 agents): 8 raised → 2 confirmed + 1 self-verified → fixed, 6 dismissed. CONFIRMED: a `/dev/null` + `/dev/std*` redirect over-block (`2>/dev/null` was forcing a confirm-hold — harmless/fails-safe but a rubber-stamp/alert-fatigue regression) → DEV_SINK exemption. SELF-VERIFIED (a dismissed LOW traced to a real false-negative): the force-clobber `>|` operator evaded `extractBashWriteTargets` → `echo x >| /outside` wrote outside un-gated → regex `>>?\|?`. 4 review-regression tests added.

## Open Questions

- OS-sandbox bash filesystem isolation to the workspace = the COMPLETE fix for the string-gating residual (the host-gate hardening closed common vectors but is incomplete by nature). High-value security follow-on (Phase-112 candidate).

## Artifacts Changed

- `app/src/gate/host-gate.ts` (base-policy COVERAGE: `PATH_ARG_KEYS` default-branch check + `extractBashWriteTargets` bash-branch check + `DEV_SINK` exemption; verdict-loop core untouched)
- `app/src/engine/types.ts` (additive optional `details?: { diff?: string }` on the `tool-result` EngineEvent variant — HIGHEST blast radius, all consumers additive-clean)
- `app/src/engine/pi/pi-adapter.ts` (`extractToolDetails` normalization seam — lifts only the whitelisted `diff` string, redact-then-cap)
- `app/src/ui/runtime.ts` (`SurfaceToolCall` gains `details?: { diff?: string }`; reduction threads it)
- `app/src/ui/artifact-feed.ts` (typed-diff branch FIRST + `capArtifact` redact+cap helper; heuristic preserved as fallback)
- `app/tests/{gate/host-gate-coverage,adapters/pi-event-mapping,ui/artifact-feed,ui/typed-diff-pipeline,e2e/typed-details-roundtrip,e2e/provider-roundtrip}.test.ts`

## Related

- [[phase-111-typed-artifact-fidelity|Phase 111: Typed Artifact Fidelity]] -- parent phase

## Soft Observations / Phase 112 Candidates

- OS-sandbox bash filesystem isolation = the complete gate fix (the string-gating residual). High-value security follow-on → Phase 112. | evidence: [[host-gate-out-of-workspace-hardening]] residual.
- Gate-design principle (banked to memory): hardening a confirmation gate must measure the FALSE-POSITIVE rate on common idioms — an over-broad deny is a security regression via desensitization (alert fatigue), not just a UX nit.
- The adversarial finder×refuter review keeps earning its keep on security-boundary / cross-boundary changes (caught the `/dev/null` over-block + the `>|` evasion that 24 passing gate tests missed) — apply to future gate/boundary phases.
- The live window-drive felt-quality check remains the maintainer's deferred call (Ph109/110 precedent).

### Retro Check (Phases 102-111)

| Dimension | Findings | Signal |
|-----------|----------|--------|
| 1. Recurring Blockers | 1 — the "convenient-fixture / happy-path verification masks a real gap" class (Ph110 string fixtures masked the live wrapper shape; Ph111 happy-path write+path masked the bash/alt-name host-gate gap) — each caught PRE-COMMIT by the adversarial review + the regression baseline | low |
| 2. Decision Reversals | 1 — the Ph108 "empirically un-bypassable" over-claim corrected (a confidence-honesty correction, not a design reversal) | low |
| 3. User Corrections | 1 — maintainer-directed scope fold-in (the gate hardening), the direction gate working as intended | low |

Recommendations:
- Keep the adversarial finder×refuter review on security/boundary phases — it caught defects 24 passing gate tests missed; cheap relative to a shipped security hole.
- Route the OS-sandbox bash-fs isolation as the next security phase — it closes the documented string-gating residual the heuristic gate cannot.

No systemic issue (no 2+ high-signal dimensions). The recurring low-signal theme is healthy: convenient-fixture gaps are being caught pre-commit by adversarial review + regression baselines rather than shipped.
