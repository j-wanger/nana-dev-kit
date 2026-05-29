<!-- nana:approved 2026-05-29 -->
# Spec: Phase 63 — Harness Assessment & Eval-Validity

## Objective

Assess the nana-dev-kit harness as a whole from multiple angles — producing an evidence-backed verdict on what is USED / LATENT-but-never-triggered / DEADWEIGHT, whether the parts compose coherently, and (the spine) whether the current evaluation apparatus can even *detect* whether the harness helps a real agentic workflow — then execute the evidence-confirmed clear-cut subtractions in-phase and leave a remediation roadmap for the rest.

## Context

Recent phases (58, 59, 61) each proposed a feature, measured it against the existing apparatus (the stock-screener / task-tracker clean-room A/B/C in `eval/comparison/` plus the 25-scenario LLM-as-judge reasoning eval), found net-zero/negative deltas, and CUT the feature. The maintainer no longer trusts that setup and suspects net-zero is *ambiguous*: worthless feature vs. blind instrument — and you cannot tell which from the number alone. `eval/comparison/methodology.md` itself admits the A-vs-C comparison (the only one exercising the full harness) is confounded by the subagent capability gap, is N=1 "directional not significant," self-graded, and Python-only.

Hard evidence already gathered: all 12 heuristics + 5 IRON RULES (17 total) sit at `helpful:0 harmful:0` — the Cognitive Enhancement system (Phases 44–52, "7/7 complete") has never once recorded firing/updating in production. The `audit-log` PostToolUse hook produces no `.nana/audit.jsonl` in the live repo. `enforcement.log` has 242 lines (enforce hooks genuinely used). MCP memory store ⊂ the always-loaded hot cache (Phase 61 redundancy). This phase is a self-assessment: the harness is the artifact under test AND the tool doing the test — there is no separate production system. Direction approved via dev-plan direction gate 2026-05-29: deliverable = diagnose + cut slam-dunks; execution = multi-agent workflow (one assessor per angle, adversarial verification, synthesis).

## Scope

### In scope
- Four assessment angles, executed as a multi-agent workflow with per-finding adversarial verification then synthesis:
  1. **Utilization audit** → a re-runnable script (`scripts/harness-audit.{sh,py}`) inventorying every component (skills, hook scripts, rules files, heuristics+IRON rules, test scripts, eval sub-systems) and classifying each USED / LATENT / DEADWEIGHT by hard evidence, resolving the *transitive* reach graph (hook→hook `source`, skill→`Skill()`, modules.json→`cp -r`) before declaring anything orphaned.
  2. **Coherence map** → named redundancies/overlaps/conflicts across the 5 memory layers, skill routing, and hook ordering (extends the MCP ⊂ hot-cache finding).
  3. **Eval-validity (the spine)** → characterize the existing apparatus with an *instrument-sensitivity probe*, explain why the 58/59/61 net-zeros are uninformative-or-not, and propose (not build) a concrete real-agentic-workflow eval.
  4. **Synthesis** → verdict + prioritized remediation roadmap, each item carrying a decidability criterion.
- Executing CLEAR-CUT, evidence-confirmed, low-blast-radius subtractions in-phase (e.g. quarantine/remove the never-fired cognitive scaffolding, wire-or-remove `audit-log`, prune frozen dead eval records), batched at the end of the assessment pass.
- Repo-hygiene prerequisite: gitignore `.memory/*.db*` so the phase diff is a clean record of intentional edits (measurement hygiene, done first).

### Out of scope (defer to Phases 64+, named in the roadmap with a decidability criterion)
- *Building* the new real-agentic eval (this phase critiques and proposes it only).
- Consolidating the 5 memory layers into fewer.
- Any high-blast-radius rewrite or a cut that breaks a test/eval scenario.
- Re-litigating already-decided cuts from Phases 58/59/61.

## Approach

Run the four angles over a **frozen harness state** (assessor=assessed: findings generated mid-pass must not be measured against a world that still contains the thing being removed). Batch all cuts to the end of the pass; re-baseline `make test`/`make eval` after the batch.

Treat the eval-validity angle as the higher-order deliverable: a pile of component verdicts produced by an instrument the maintainer already distrusts is process theatre. The instrument-sensitivity probe is the lever — inject a deliberately known-good and a deliberately known-broken variant of some component into the apparatus and observe whether it produces a non-zero delta. An instrument that cannot separate broken-from-baseline cannot inform cuts; that finding is itself the verdict on the apparatus and is independent of any feature.

Classification rigor: separate *activation* (did it fire / get loaded) from *causal influence* (did removing it change an outcome). DEADWEIGHT requires affirmative evidence — a firing test (synthesize the triggering event) confirming it never activates, OR an ablation showing delta ≈ 0 — never "it's loaded every session" and never log-absence alone. When a layer is down to its last member, apply the subtraction test to the *scaffolding* (matcher/judge/dashboard/lifecycle/schema), not the surviving leaf.

Treat every template deletion as a migration, not an edit: quarantine (disable in modules.json / move out of the install path) before hard-delete for anything non-trivial; hard-delete only frozen dead records.

### Domain Research Questions
1. What is the minimal *observable* a real-agentic eval must capture to be non-blind — task completion? rework/retry count? time-to-green? did-the-component-actually-fire-and-change-an-action? — and which of these are cheaply instrumentable from existing logs (`enforcement.log`, hook events, git history) vs. require new instrumentation?
2. For the never-fired cognitive system: is there a *cheap wired path to it ever firing* (e.g. the counter-update path is simply broken and a one-line fix activates it), or is it structurally never-reached? The cut-vs-fix decision turns on this.
3. What is the right unit of the new eval — a held-out real task replayed with/without the harness, or passive telemetry over real usage — given the self-grading and capability-gap confounds the current apparatus already documents?

## Constraints (CRITICAL)

- **No cut on log-absence or loadedness.** A "never-triggered" verdict must be backed by an affirmative firing test (pipe the synthesized trigger event, assert exit code + side effect). — Guard: long-cadence hooks (pre-compact, session-stop, crash-recovery, memory-bridge) get a synthesized-trigger test before any cut; absence in recent logs is not evidence.
- **No cut on the distrusted instrument's net-zero** until the instrument-sensitivity probe shows it can produce a non-zero delta on a known-broken variant. — Guard: if the probe shows the instrument is blind, net-zeros do not drive cuts; that is logged as the apparatus verdict.
- **Every template deletion is a migration.** — Guard: prefer quarantine for ≥1 phase; after any cut, `tests/test_registration.sh` (bidirectional registration invariant) and a referential-integrity check (every `source:`/`[[...]]` in working-knowledge.md + active-knowledge.md resolves to an existing file) must both pass; a cut that breaks either is reverted and kicked to the roadmap.
- **Cuts are batched at the end of a frozen-state pass.** — Guard: name the mode in the synthesis; do not interleave cuts with assessment such that later findings run on a mutated harness.
- **A subtraction that breaks `make test` (13 scripts) or moves `make eval` off baseline is not slam-dunk.** — Guard: re-run both after the batched cuts; any regression reverts that cut.
- **Roadmap items are not a backlog of the same stuck decision.** — Guard: each deferred item carries a canonical `decidable-when:` line stating the observable that resolves it ("becomes a clear cut when X observable holds"); an item without a `decidable-when:` line is not roadmap-ready.
- **`uses` counter is not the cut signal.** — Guard: the audit must not rank least-`uses`→cut (87/100 tied at the floor; the counter is inert).

## Success Vision

A maintainer runs one script and sees, with cited evidence, what's used vs. latent vs. dead across the whole harness. The never-fired cognitive machinery is either cut (with its scaffolding) or has a verified wired path to actually firing. There is a written, defensible answer to "is our eval valid, and if not, what replaces it" — grounded in a concrete instrument-sensitivity result, not opinion. The harness is measurably leaner, every surviving component has affirmative evidence it earns its keep, and Phases 64+ have a prioritized roadmap where each item states the observation that will make it decidable. The recurring "measured, ambiguous, deferred" cycle is broken because the phase characterized the *instrument* rather than producing more verdicts from a blind one.

## Exit Criteria (machine-checkable)

- [ ] `test -x scripts/harness-audit.sh && ./scripts/harness-audit.sh | grep -qE 'USED|LATENT|DEADWEIGHT'` — re-runnable audit script exists, runs, and emits classified output
- [ ] `./scripts/harness-audit.sh | grep -q 'MATCH=ok'` — the audit reconciles its classified-line count against an INDEPENDENT inventory it computes from source (modules.json skill list + `templates/.claude/hooks/*.sh` + `wiki/heuristics/{HEU,IRON}-*.md` + `tests/test_*.sh`) and emits `INVENTORY=N CLASSIFIED=N MATCH=ok`; a mismatch (silently-dropped component) emits `MATCH=fail` and fails this gate
- [ ] Instrument-sensitivity probe executed and recorded with a verdict token: `grep -qE 'instrument: (sensitive|blind)'` in the eval-validity decision article — a known-broken variant either produced a non-zero apparatus delta (`sensitive`) or none (`blind`); a recorded delta value accompanies the token
- [ ] `make test` passes with ≥13 scripts green AFTER the batched cuts (`helpers.sh` is a shared library, not a counted test script)
- [ ] `make eval` at the Phase-61 baseline (54/54) AFTER the batched cuts
- [ ] `tests/test_registration.sh` passes after cuts (bidirectional registration invariant intact)
- [ ] Referential integrity: a check confirms every `source:`/`[[...]]` link in `.claude/rules/working-knowledge.md` and `active-knowledge.md` resolves to an existing target, before and after deletions
- [ ] `grep -qE '\.memory/.*\.db' .gitignore` — runtime DB churn is gitignored
- [ ] Eval-validity verdict persisted as a decision article AND a remediation roadmap exists where every deferred item carries a canonical `decidable-when:` line — the roadmap's `grep -c '^- '` item count equals its `grep -c 'decidable-when:'` count (every item has exactly one, none gamed by repetition)
- [ ] Every executed "never-fired" cut cites an affirmative firing test in its commit/decision rationale (not log-absence)

## Checkpoints

- After the utilization audit produces its first classification but BEFORE any cut: report the USED/LATENT/DEADWEIGHT table + the proposed cut list, and confirm the instrument-sensitivity result. Cuts proceed only on evidence-confirmed slam-dunks.
- If the instrument-sensitivity probe shows the apparatus is blind: STOP the cut-justification-by-eval path and report — pivot remaining effort to the eval proposal (the higher-order deliverable), not more verdicts.
- If any proposed cut would break `test_registration.sh`, a referential link, `make test`, or `make eval`: STOP that cut, revert, move it to the roadmap with its decidability criterion.
- If the cognitive-system counter turns out to be a one-line wiring bug (cheap path to firing exists): STOP the cut and surface fix-vs-cut as a decision rather than auto-cutting.

## Assumptions

- The multi-agent workflow tool is available for the assessment fan-out. If false: run the four angles sequentially as ordinary phase tasks (slower, single-perspective) and note the downgrade.
- `make test` (13 scripts) and `make eval` (54 scenarios) are green at phase entry, giving a clean regression baseline. If false: capture the pre-existing failures first and exclude them from the regression gate so they aren't attributed to this phase's cuts.
- The eval apparatus's own dependencies (`jq`, judge model, embedding provider) are available; if the instrument silently degrades to a weaker path (e.g. word-overlap fallback when embeddings absent), that degradation is announced in the eval-validity write-up — the assessment must not run on a different instrument than the one it characterizes without saying so.
- Quarantine (disable + move out of install path) is reversible within the repo's git history. If a component cannot be cleanly quarantined (load-bearing transitive dependency surfaces): keep it, record the dependency in the coherence map, and defer to the roadmap.
