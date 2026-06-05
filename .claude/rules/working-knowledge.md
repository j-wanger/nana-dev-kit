# Working Knowledge
<!-- Cross-phase knowledge. Auto-managed by dev-debrief and wiki-query. -->

- [uses: 2] The amplifier program (Ph70/71/77/78) measured whether the harness adds value by re-presenting what a frontier model could otherwise recover — NULL in every regime: single-decision recall (Ph70 DEGENERATE 5/5, bare opus reasons unprompted), single-session/compaction retention (Ph71 TERMINATE-by-summary-robustness, native summary is decision-comprehensive), cross-session decision retention (Ph77 residual 0/14, every decision recoverable from code+tests), capability/tooling-correctness (Ph78 DEGENERATE, the bare model re-derives a tooling artifact's correctness from its GOAL — even subtle PIT-survivorship inclusive-through-d). GENERALIZES: harness headroom does NOT live in re-presenting decisions OR tooling-correctness the model can recover from artifacts/goals it already has. Reusable method: deterministic NO-LLM consensus-by-clause screen (n=5/threshold=4), controls-first, pre-registration committed BEFORE runs (anti-retrofit ancestor guard), apparatus frozen repo-only under eval/amplifier/. Surviving untested avenue (all four): retrieval of genuinely PROPRIETARY/POST-CUTOFF correctness derivable from NO fair corpus (Ph78's positive-unknowable control proves the rig flags it). Detail in the four decision articles (NOT always-loaded).
  source: [[decision:amplifier-anchor-headroom-screen]] (Ph70) + [[decision:cross-boundary-retention-headroom-screen]] (Ph71) + [[decision:cross-session-retention-headroom-screen]] (Ph77) + [[decision:skill-crystallization-headroom-screen]] (Ph78) | activated: 2026-06-04
- [uses: 1] Active web-research injection into planning was CUT (Phase 59 — measured net-negative; reverses Phase 58's Step 2.7). On well-documented software-engineering topics a strong baseline model already holds the knowledge in-parameter, so injecting researched findings yields ~0 lift where research should help most (retry/backoff Δ=0.0, ledger-isolation Δ=−0.4, both variance-dominated at n=5) and ACTIVELY HARMS on commodity topics (commit-convention Δ=−1.0, real: findings anchor the design to the generic answer and crowd out the context-specific reasoning the baseline produces unprompted). Phase 58's lone +0.5 (n=1) sits inside the n=5 noise band — a noise draw, not a banked effect. Burden-of-proof-on-the-feature + subtraction test ⇒ CUT (removed the Step 2.7 web-research + injection from the template; reverts dev-plan to Phase-55 behavior). UNTESTED caveat: value on genuinely novel / post-training-cutoff / proprietary topics (weak parametric knowledge — research's theoretical sweet spot) was not measured. Generalizes: "retrieval over parametric knowledge" does NOT pay when the model's parametric knowledge is already strong.
  source: eval/research-measurement/results.md (Phase 59) | activated: 2026-05-28
- [uses: 1] Residual-delta measurement (not the headline +1.75): isolate active-research as the SOLE changed variable vs the Phase-55 baseline; part of +1.75 was already banked by Phase 55's spec reform (double-count guard). Subtraction test: ~0/negative residual is acceptable → keep/trim/cut. An LLM-executed skill step can't be scored by the binary eval runner, so a with-vs-without measurement artifact IS its functional test. Phase 58 result: +0.5 composite n=1 (reasoning 3→4), on a research-favorable topic — at the significance threshold with unknown variance; directional, not banked. Phase 59 strengthened it (3 new topics, 13 paired runs at n≥3, escalation + variance gate): the +0.5 did NOT replicate — all n≥3 deltas were ≤0 (poor −1.0 real, rich 0.0/−0.4 variance-dominated) ⇒ feature CUT. Method validated itself: the pre-registered poor-topic veto + variance gate turned an n=1 false-positive into an honest negative.
  source: [[decision:measure-residual-research-delta]] | activated: 2026-05-28
- [uses: 1] Hook registration single source of truth: one scope-tagged `hooks` array in modules.json (scope: project|global). templates/.claude/settings.json is a GENERATED artifact (`make template` → register-settings.py --scope project-local --regenerate); NEVER hand-edit it. Drift test in tests/test_settings_template.sh fails if modules.json changes without regenerating. Project-scoped hooks (17) install per-project (py-init/ts-init template copy, or install.sh --project-local); global-scoped (1: context-size-check) installs to ~/.claude.
  source: [[decision:single-source-scope-tagged-hook-registration]] | activated: 2026-05-28
- [uses: 1] Enforcement is per-project + project-reachable: enforce hooks check `.claude/enforce` (project) OR `$HOME/.claude/enforce` (global). Template ships the marker; py-init/ts-init + install.sh --project-local create it. enforce-memory is OPT-IN (separate `.claude/enforce-memory`, NOT shipped — needs a working memory MCP a bare scaffold lacks). Verify firing (pipe a real event, assert exit 2), never just file presence — a registered-but-dormant hook passes a presence test and ships broken.
  source: [[HEU-012]] + [[decision:single-source-scope-tagged-hook-registration]] | activated: 2026-05-28
- [uses: 1] Memory architecture 5-layer classification: working-knowledge=mandatory (.claude/rules/), active-knowledge=mandatory (.claude/rules/), dev-wiki=automatic (session-start + dev-plan), knowledge-wiki=automatic (dev-plan Step 2 + spec), MCP memory=voluntary (nudges only). Key insight: strengthen existing activation points (.claude/rules/ files always loaded), don't add hooks (can be unwired -- 3 cascade failures across project history).
  source: [[decision:memory-architecture-classification]] | activated: 2026-05-28
- [uses: 1] Cascade failure anti-pattern: nana-init not installed -> enforce marker missing -> all enforcement silently disabled. Third instance of same class (pre-compact.sh Phase 15-23, MCP CWD Phase 4-38, nana-init Phase 43-55). Root cause: install.sh cp -r needs YAML frontmatter in SKILL.md.
  source: [[decision:cascade-failure-diagnosis]] | activated: 2026-05-28
- [uses: 1] Open-ended prompts outperform prescriptive specs: +1.75 composite quality delta in 5-implementation experiment. Best implementation (bare Claude, open-ended prompt) produced academic citations and honest backtesting. Spec reform: Deliverables -> Success Vision, added Domain Research Questions, Reasoning Enablement reviewer dimension.
  source: [[decision:spec-reform-reasoning-over-compliance]] | activated: 2026-05-28
- [uses: 1] Bidirectional registration invariant: filesystem -> modules.json AND modules.json -> filesystem. Complements functional smoke invariant (Phase 41) which only checks "does registered stuff work?" but not "is stuff registered?". test_registration.sh, 40 assertions.
  source: [[decision:bidirectional-registration-invariant]] | activated: 2026-05-28
- [uses: 1] Session-start.sh line cap (70 lines, Phase 22) eroded to 137 lines over Phases 23-54 without any test catching it. Cognitive-readiness.sh extraction fixed it. Pattern: caps need test assertions, not just documentation.
  source: [[journal:2026-05-28-phase-55-harness-activation-overhaul-complete]] | activated: 2026-05-28
- [uses: 1] Clean baseline solves scenario 020 correctly (5/5/5). The "8/9 wrong" finding (Phase 50) was from IRON-RULES-injected conditions — IRON-005 biases toward dependency upgrade over capacity multiplier. HEU-011's value is as IRON-005 counterweight, not standalone improvement. IRON-RULES-condition eval deferred.
  source: [[active-knowledge:phase-53]] | activated: 2026-05-27
- [uses: 1] MCP memory CWD mismatch: Claude Code ignores settings.json cwd, uses project directory. DB at <project_root>/.memory/memory.db, not ~/.claude/.memory/. Health probe (memory-nudge.sh) checks wrong path + wrong column (is_active vs active). Phase 19-48 entries irrecoverable. 11 current entries from Phase 49+.
  source: [[active-knowledge:phase-53]] | activated: 2026-05-27
- [uses: 1] IRON-004/015 concern resolved by selective injection (Phase 51). Ground-truth maps 015 to IRON-005 only. IRON-004 would give correct answer on 015 anyway (reasoning framing issue, not decision quality). No IRON-004 content change needed.
  source: [[active-knowledge:phase-53]] | activated: 2026-05-27
- [uses: 1] Verification-first pattern: run cheapest check before committing to expensive work. Phase 53: matcher check (~1 call) before 6 eval runs (~30 min). Closed IRON-004 question without any eval runs. Generalizes early-falsification-checkpoint (Phase 49).
  source: [[active-knowledge:phase-53]] | activated: 2026-05-27
- [uses: 1] Cognitive Enhancement Roadmap complete (7/7 phases): foundation (44) -> capture (46) -> IRON RULES (45+46) -> self-dialogue (47, negative) -> trace collection (48, negative) -> prompt-type hooks (51) -> evolution (52). Future heuristic work is ad-hoc.
  source: [[active-knowledge:phase-52]] | activated: 2026-05-27
- [uses: 1] Ground-truth heuristic mapping: 84% scenario coverage (21/25 have at least 1 matching heuristic). 4 blind-spot scenarios (011, 019, 020, 023) in organizational/distributed-systems domains. IRON-004 most broadly applicable (6/25) but known harmful on 018.
  source: [[active-knowledge:phase-51]] | activated: 2026-05-27
- [uses: 1] Two-phase eval methodology: single-call eval (agent sees expert answers) produces 100% ceiling (20/20 at 5/5/5). Two-phase (agent blind, separate judge) produces meaningful differentiation. Essential for all future eval runs.
  source: [[decision:two-phase-eval-methodology]] | activated: 2026-05-27
- [uses: 1] Filler text actively discarded by model: irrelevant content (cooking/gardening) is judged for content-relevance before application. Length-sensitivity experiment doesn't cleanly isolate length variable. NEGATIVE RESULT for length-as-driver hypothesis.
  source: [[active-knowledge:phase-50]] | activated: 2026-05-27
- [uses: 1] Haiku judge passes calibration: mean=4.07, 37.8% below 5 (self-judge: mean 4.83, fails). High inter-run variance (mean ranges 2.97-4.85) needs investigation. Sonnet not tested (jumped to Haiku per fallback sequence).
  source: [[active-knowledge:phase-50]] | activated: 2026-05-27
- [uses: 1] Harder scenarios don't reduce ceiling if model gets them right. Ceiling is about correct-answer frequency, not scenario difficulty. 5 new scenarios (021-025) scored 15/15 with self-judge. Ceiling reduction requires wrong answers OR stricter judge.
  source: [[active-knowledge:phase-50]] | activated: 2026-05-27
- [uses: 1] Conditional injection negative result: scenario-type classification (suppress IRON RULES for risk-dominant) provides zero delta vs always-inject. Stochastic interference from Phase 48 did not reproduce in fresh runs. Baseline divergence, not rule-induced interference.
  source: [[journal:2026-05-27-phase-49-conditional-heuristic-injection-complete]] | activated: 2026-05-27
- [uses: 1] Fresh runs methodology: cross-round absolute scores diverge (baseline variance). All conditions for a comparison must run fresh in the same evaluation round. Within-round deltas valid, cross-round comparisons invalid.
  source: [[decision:fresh-runs-deviation]] | activated: 2026-05-27
- [uses: 1] Early falsification checkpoint: run cheapest falsification test first before committing to expensive eval. Phase 49: 3 no-inject runs on 015 before 180 full-eval invocations. Saved nothing here (passed), but design pattern is sound.
  source: [[decision:early-falsification-checkpoint]] | activated: 2026-05-27
- [uses: 1] Three-type scenario taxonomy: risk-dominant, capacity-constraint, domain-nuance. Property-based (transferable to new scenarios), not outcome-based (ceiling is an eval property, not a scenario property). No 4th type.
  source: [[decision:three-type-taxonomy-only]] | activated: 2026-05-27
- [uses: 1] Conditional injection template: gates on scenario_type field in JSON metadata. risk-dominant suppresses IRON RULES, all others inject. Metadata-based lookup, not runtime inference.
  source: [[active-knowledge:phase-49]] | activated: 2026-05-27
- [uses: 2] Stochastic heuristic interference (negative result): LOO ablation showed scenario 015 interference is stochastic (~1/3 of runs), not attributable to any specific IRON RULE. Removing IRON-004 does NOT fix it. IRON-001 is load-bearing for scenario 020. Per-rule selection not viable; scenario-type classification (all-or-nothing injection) is the right framing.
  source: [[decision:stochastic-heuristic-interference]] | activated: 2026-05-27
- [uses: 1] LOO ablation methodology: remove one IRON RULE at a time, compare to full-set across training scenarios x 3 runs. Classification: delta >= 0.5 with variance < 0.5 = helped/hurt; else "uncertain". Baseline-first checkpoint required. Judge v2 (exemplar-based), same judge for all conditions.
  source: [[decision:full-spec-ablation-scope]] + [[decision:sequential-baseline-verification]] | activated: 2026-05-27
- [uses: 2] Scenario-type selection criteria: attribution matrix per-dimension (heuristic x scenario x dimension). Selection operates at scenario-type level (risk-dominant, capacity-constraint, domain-nuance). Train on 015/018/020, validate on held-out 012/014.
  source: [[decision:scenario-type-selection-criteria]] | activated: 2026-05-27
- [uses: 1] Prompt-length confound control: no padding text (padding introduces its own confound). Scenario 012 as diagnostic: uniform improvement when ANY rule removed = length effect; specific = content attribution.
  source: [[decision:no-prompt-length-padding]] | activated: 2026-05-27
- [uses: 1] Self-dialogue negative result: devil's advocate with IRON RULE citations does not improve reasoning quality. Inline is net negative (adds hedging), subagent is net neutral. Technique generates shallow counterarguments without novel insights when same-context agent plays both sides.
  source: [[journal:2026-05-27-phase-47-self-dialogue-in-dev-plan-complete]] | activated: 2026-05-27
- [uses: 1] Adversarial subagent pattern (prior art): adversarial-constraints-prompt.md (spec skill) is the established clean-context subagent pattern. Subagent receives only objective + context (no approach/decisions).
  source: [[active-knowledge:phase-47]] | activated: 2026-05-27
- [uses: 1] Context dilution checkpoint protocol: 200-word cap on self-dialogue output, checkpoint after condition A run 1 — if scenario 012 mean < 4.0, compress injection before continuing. Applied successfully in Phase 47 eval.
  source: [[active-knowledge:phase-47]] | activated: 2026-05-27
- [uses: 1] One-variable-at-a-time eval methodology: condition A (inline) measures technique alone, condition B (subagent) adds clean-context isolation. Delta between A and B directly answers whether subagent separation adds value. Both use same judge-v2, same 20 scenarios, same 3-run protocol.
  source: [[active-knowledge:phase-47]] | activated: 2026-05-27
- [uses: 1] IRON RULES "surface reading" failure: IRON-004/005 override domain reasoning on scenarios 015/020. Next lever is heuristic selection (matching right rule to right scenario type), not heuristic application (forcing rules as counterargument ammunition).
  source: [[journal:2026-05-27-phase-47-self-dialogue-in-dev-plan-complete]] | activated: 2026-05-27
- [uses: 1] Anti-pattern table format: structured table (Failure Mode | Detection Signal | Why It Fails) within existing ## Anti-pattern H2 header. 3-5 rows per heuristic. SCHEMA.md defines format. H2 header preserved for wiki-query compatibility.
  source: [[active-knowledge:phase-46]] | activated: 2026-05-27
- [uses: 1] IRON-004 regression fix: Never clause distinguishing "less effort now" from "simpler system" via total lifecycle complexity. Must stay domain-agnostic (transferability test). Scenario 018 improved +2.67 after fix.
  source: [[decision:iron-004-lifecycle-complexity-fix]] | activated: 2026-05-27
- [uses: 1] Dev-debrief companion file pattern: at 315/350 lines, new features require companion files (not inline); e.g. memory-harvest.md. Companions read standalone.
  source: [[active-knowledge:phase-46]] | activated: 2026-05-27
- [uses: 1] Context dilution from expanded injection payload: scenario 012 consistently dropped from 5/5/5 to 5/4/4 across 3 runs when anti-pattern tables added. Detection signal: when injection text grows, check for non-target scenario regressions.
  source: [[active-knowledge:phase-46]] | activated: 2026-05-27
- [uses: 1] Exemplar-based judge anchoring breaks self-grading ceiling: concrete response examples at score levels 3 and 5 per dimension. Same judge prompt for both baselines. Descriptive rubrics alone allow score inflation.
  source: [[decision:eval-calibration-exemplar-based-judge-anchoring]] | activated: 2026-05-27
- [uses: 1] IRON RULES reuse heuristic format with status: iron, confidence: absolute. Selection: universal (every decision), unconditional (no exceptions), prevents known failure mode. Discoverable via same wiki-query/indexing.
  source: [[decision:iron-rules-as-iron-status-heuristics]] | activated: 2026-05-27
- [uses: 1] Reasoning eval self-grading bias: same LLM writing + evaluating inflates scores. Bias constant across conditions, so relative comparisons valid. Cross-model judging is the next lever if calibration insufficient.
  source: [[active-knowledge:phase-45]] | activated: 2026-05-27
- [uses: 1] Reasoning eval protocol: 3 runs, delta >= 0.5 meaningful, variance < 0.5. run-eval.py --compare for delta. Calibration criterion: mean < 4.5 (strict), >=15% below 5 (exit). Judge v2 achieved 19.4% below 5.
  source: [[active-knowledge:phase-45]] | activated: 2026-05-27
- [uses: 1] SCHEMA.md status enum: active | deprecated | under-review | iron. Iron status for unconditional universal rules. IRON RULES use IRON-NNN ID prefix (vs HEU-NNN for regular heuristics).
  source: [[active-knowledge:phase-45]] | activated: 2026-05-27
- [uses: 1] Heuristic rules can have unintended negative effects: IRON-004 (simpler system) caused regression on scenario 018 (pushed toward incremental cleanup when expert recommends dedicated sprint). Per-rule regression analysis should be standard eval practice.
  source: [[active-knowledge:phase-45]] | activated: 2026-05-27
- [uses: 1] Harder reasoning scenarios need genuine ambiguity (multi-stakeholder tradeoffs, no single right answer) to differentiate quality. Easy scenarios with clear answers score at ceiling regardless of judge calibration.
  source: [[active-knowledge:phase-45]] | activated: 2026-05-27
- [uses: 1] Conflict detection between heuristic rules: systematic clause-by-clause comparison of Always/Never sections. No prior art found — developed from first principles in Phase 45 crossref methodology.
  source: [[active-knowledge:phase-45]] | activated: 2026-05-27
- [uses: 2] Heuristic article format requires 6 sections: When this applies, Always, Never, Why, Anti-pattern, Source. YAML frontmatter carries: id, trigger, domain, source_phase, confidence, helpful (counter), harmful (counter), status.
  source: [[active-knowledge:phase-44]] | activated: 2026-05-26
- [uses: 1] Transferability test for seed heuristics: "Would this apply to a web app, data pipeline, or CLI tool?" If no, rewrite the trigger to be more general. At least 6/10 must pass.
  source: [[active-knowledge:phase-44]] | activated: 2026-05-26
- [uses: 1] Reasoning eval uses LLM-as-judge with 3 dimensions (1-5 each): decision quality (right conclusion), reasoning quality (right tradeoffs considered), anti-pattern avoidance (known failure modes avoided). Judge must score consistently (variance < 0.5 across 3 runs).
  source: [[active-knowledge:phase-44]] | activated: 2026-05-26
- [uses: 1] Source material for seed heuristics: .dev-wiki/articles/decisions/ (30+ articles), .claude/rules/working-knowledge.md (60+ entries), specs/ (10+ specs), git log (43 phase commits). Mine for REASONING PATTERNS, not implementation details.
  source: [[active-knowledge:phase-44]] | activated: 2026-05-26
- [uses: 1] Knowledge wiki prerequisite: /wiki-init must scaffold wiki/ before heuristic content can be written. "heuristic" must be a recognized category in wiki/schema.md.
  source: [[active-knowledge:phase-44]] | activated: 2026-05-26
- [uses: 1] /nana-init (86 lines) is a multi-stage orchestrator replacing the old /init (44 lines). Detects component states (language markers, .dev-wiki/, wiki/), then dispatches to py-init/ts-init, dev-init, wiki-init via Skill(). Each step independently skippable. Renamed from init/ to resolve Claude Code built-in /init collision.
  source: [[decision:nana-init-rename-and-expand]] | activated: 2026-05-26
- [uses: 1] modules.json core skills array lists "nana-init" (not "init"). install.sh cp -r copies whatever modules.json lists. MANIFEST description line uses `# nana-init:` prefix.
  source: [[active-knowledge:phase-43]] | activated: 2026-05-26
- [uses: 1] Three-condition comparison design: A (bare baseline subagent) vs B (context-injection subagent with .claude/rules/ + AGENTS.md) vs C (full harness manual session). A+B automatable via parallel subagents; C requires manual user session. Subagents naturally lack hooks/skills/memory — valid clean-room baseline. Results: A 3/4, B 3/4, C 4/4 (acceptance test confound).
  source: [[decision:three-condition-comparison-design]] | activated: 2026-05-26
- [uses: 1] Python task choice for comparison: tasks are Python to exercise py-lint, py-review, py-test, py-init skills. Maximizes measurable difference in condition C. TypeScript comparison would be natural follow-up.
  source: [[decision:python-task-language-choice]] | activated: 2026-05-26
- [uses: 1] install.sh uses fail-STOP (exit 1) for missing jq, unlike hooks which use fail-open (exit 0). Different pattern for different contexts: install runs once explicitly, hooks run continuously. Multi-platform hint (brew/apt) on failure.
  source: [[decision:jq-guard-fail-stop]] | activated: 2026-05-25
- [uses: 1] Companion metadata: every companion .md file has YAML frontmatter with parent (owning skill dir name) + referenced_at (step in parent SKILL.md). 92 files covered. test_companions.sh validates bidirectionally: Direction A (parent matches dir) + Direction B (SKILL.md Read paths resolve). Future companions must include frontmatter.
  source: [[decision:companion-metadata-format]] | activated: 2026-05-25
- [uses: 1] Cooldown advisory in debrief: fires when >=2 Phase commits since .session-start-ts (written by session-start.sh). Falls back to "last 4 hours" if timestamp missing. Advisory only (never blocks). Placed in debrief SKILL.md after executor returns, outside delivery-flow.md.
  source: [[decision:cooldown-advisory-placement]] | activated: 2026-05-25
- [uses: 1] Session timestamp: session-start.sh writes `date +%s` to $HOME/.claude/.session-start-ts in init block. Consumed by cooldown advisory in debrief SKILL.md.
  source: [[active-knowledge:phase-41]] | activated: 2026-05-25
- [uses: 1] modules.json is single source of truth for 5 module groups (core, python, typescript, dev-wiki, knowledge-wiki). Defines skill lists, hook registrations, MCP config. Consumed by install.sh (jq), register-settings.py (Python), tests (filesystem consistency), MANIFEST, README.
  source: [[decision:install-sh-extraction-approach]] | activated: 2026-05-25
- [uses: 1] Functional smoke invariant: every component registered in settings.json or install.sh must have at least one functional test (pipe input, check output). Codified in spec SKILL.md Step 2.6 + dev-plan implementation-guide.md integration checklist. Evidence: 4 silent breakages lasting 8-33 phases.
  source: [[decision:functional-smoke-invariant-rule]] | activated: 2026-05-25
- [uses: 1] install.sh CORE_SKILLS: nana + memory-consolidate + init (language-agnostic). PYTHON_SKILLS: py-lint + py-review + py-test (excluded by --no-python, --core-only). Module assignment determines which skills install under each flag combination. 26 total skill dirs.
  source: [[decision:install-skill-module-assignment]] + [[decision:init-router-in-core]] | activated: 2026-05-25
- [uses: 1] session-start.sh MCP health probe uses 3 layers: jq config read (settings.json .mcpServers.memory), $MCP_CMD import check, sqlite3 entry count. Emits 3-state output: healthy (N entries) / broken (reason) / not configured. All hooks now use jq for JSON parsing (python3 eliminated).
  source: [[decision:health-probe-3-layer]] | activated: 2026-05-25
- [uses: 1] /init router skill (44 lines) in CORE_SKILLS: detects pyproject.toml/setup.py → Python, package.json/tsconfig.json → TypeScript. Handles polyglot (both → user choice) and empty (no markers → prompt). Dispatches via Skill(skill="py-init") or Skill(skill="ts-init").
  source: [[decision:init-router-in-core]] | activated: 2026-05-25
- [uses: 1] MCP memory server CWD must point to ~/.claude (parent), not ~/.claude/memory_server (package dir). Was broken since Phase 4. install.sh now has import-check verification after MCP registration.
  source: [[decision:mcp-memory-server-cwd-fix]] | activated: 2026-05-25
- [uses: 2] PostToolUse canonical field path is .tool_input (verified via live stale-queue.sh production evidence). All 5 PostToolUse Edit/Write hooks normalized to .tool_input.file_path // .input.file_path defensive fallback. PreToolUse uses .input.file_path. 6 eval fixtures updated.
  source: [[decision:posttooluse-normalize-after-verification]] | activated: 2026-05-25
- [uses: 1] 2-gate ceremony model: direction gate (Step 7, user confirms intent/scope) + delivery gate (HTML report before commit, user accepts/rejects). Agent operates autonomously between gates. Subagent reviewers still execute but findings auto-incorporated.
  source: [[decision:ceremony-streamlining-2-gate-model]] | activated: 2026-05-25
- [uses: 1] Spec --internal mode: when invoked with --internal, auto-runs Steps 2-4 + Tier 0/1, incorporates findings, persists with marker, skips Step 5 user approval. Direct /spec unchanged. Honors spec-always-mandatory.
  source: [[decision:spec-internal-mode]] | activated: 2026-05-25
- [uses: 1] Delivery report generated BEFORE commit via scripts/generate-delivery-report.py (196 lines). Reads git diff + tasks.md + decisions, runs make test/eval, produces HTML. Auto-commit + push only after user acceptance.
  source: [[decision:delivery-report-before-commit]] | activated: 2026-05-25
- [uses: 1] install.sh hook schema uses nested format: {matcher, hooks:[{type:"command", command:"..."}]} per Claude Code /doctor validation. Legacy flat {matcher, command} triggers /doctor errors. Flat-to-nested migration logic in install.sh Python JSON merge block.
  source: [[decision:hook-error-evidence]] + [[decision:hook-reconciliation]] | activated: 2026-05-25
- [uses: 1] Kit hooks: 17 scripts in templates/.claude/hooks/; 11 installed globally by install.sh (enforce-spec, enforce-loop, enforce-memory, detect-loop, post-commit, pre-compact, context-size-check, dev-wiki-scope-check, post-compact, session-stop, stale-queue); 6 available via --project-local (audit-log, auto-ruff-format, block-dangerous-bash, check-tests-were-run, scan-secrets, session-start).
  source: [[decision:hook-reconciliation]] | activated: 2026-05-25
- [uses: 1] Hook fixes require tmpdir testing (mktemp -d) before touching live state — prevents self-lockout via enforce-spec.sh regression. Evidence-pinned: every fix needs quoted error string or lint finding in commit message.
  source: [[decision:hook-reconciliation-approach]] | activated: 2026-05-25
- [uses: 2] install.sh 318 lines (refactored Phase 40), zero inline Python. Reads modules.json via jq for skill lists, delegates JSON merges to scripts/register-settings.py. Flags: --all/--core-only/--no-python/--no-typescript/--project-local/--dry-run/--status. --project-local copies 6 per-project hooks.
  source: [[decision:install-sh-extraction-approach]] + [[decision:hook-reconciliation]] | activated: 2026-05-25
- [uses: 1] store() dedup is a hygiene mechanism with 7 corruption modes. _find_near_duplicate is the core dedup gate — threshold changes must preserve exact semantics (cosine >0.90 reinforce, >0.85 warn; word overlap >0.90 warn). Word-overlap is the production fallback when embeddings unavailable.
  source: [[decision:store-opt-indexed-lookups]] + [[active-knowledge:phase-34]] | activated: 2026-05-24
- [uses: 1] server.py:74 auto-embeds when embedding provider available. Word-overlap path is the fallback dedup mechanism when _vec_available=False.
  source: [[active-knowledge:phase-34]] | activated: 2026-05-24
- [uses: 1] _find_near_duplicate uses indexed lookups: vec0 KNN LIMIT 50 for cosine path (when _vec_available), FTS5 MATCH LIMIT 50 for word-overlap path. Both apply existing threshold logic (_cosine_similarity >0.90 reinforce, >0.85 warn; word overlap >0.90 warn) on candidates only. Replaces O(n^2) full table scans.
  source: [[decision:store-opt-indexed-lookups]] | activated: 2026-05-24
- [uses: 1] _sanitize_fts_query uses re.sub(r'[^\w\s]', ' ', query) + FTS5 keyword stripping (AND/NOT/NEAR). Aligns query preprocessing with index-time tokenization. Known limitation: C++ becomes C. OR-join semantics preserved.
  source: [[decision:char-level-sanitizer-fts5]] | activated: 2026-05-24
- [uses: 1] search_hybrid() uses RRF fusion (alpha=0.4, k=60); nomic-embed-text-v1.5 produces 768d vectors matching vec0 table. Turn-level hybrid RRF is winning strategy (+27.6% lift on FTS5-failure questions, no degradation). fastembed + sqlite-vec are benchmark-only deps, NOT in install.sh.
  source: [[decision:turn-level-hybrid-recommended]] + [[decision:benchmark-only-hybrid-deps]] | activated: 2026-05-24
- [uses: 1] enforce-spec.sh uses OR logic: `<!-- nana:approved -->` HTML comment marker OR exit-criteria presence. Backward compat for ~20 existing marker-less specs. New specs get marker via /spec Step 6. Both enforcement hooks write JSONL to .dev-wiki/enforcement.log with tail -n 500 truncation.
  source: [[decision:spec-provenance-html-comment]] + [[journal:2026-05-23-phase-29-grade-push-complete]] | activated: 2026-05-23
- [uses: 1] dev-plan SKILL.md at 330/350 lines after Step 3 extraction to scope-exploration-spec.md companion. Next feature addition needs another extraction or ceiling raise. Companion pattern: 2-line Read pointer replaces inline content, cp -r auto-distributes.
  source: [[decision:dev-plan-scope-extraction]] | activated: 2026-05-23
- [uses: 1] /nana skill (37 lines) reads MANIFEST via kit path marker (~/.claude/.nana-dev-kit-path), parses description comments, groups by module. /memory-consolidate (45 lines) uses Claude MCP tools for memory dedup.
  source: [[journal:2026-05-23-phase-29-grade-push-complete]] | activated: 2026-05-23
- [uses: 1] /memory-consolidate is a skill-based alternative to vendored Qwen sidecar consolidator.py; uses memory_search/memory_store/memory_forget MCP tools with 10-merge budget cap. No Python changes to memory_server/ — skill-level solution avoids fork divergence.
  source: [[decision:skill-based-memory-consolidation]] | activated: 2026-05-23
- [uses: 1] All hooks use [nana:<hook-name>] prefix for messages; exception: [dev-wiki:post-commit] kept as semantic trigger. session-start uses sub-prefixes: [nana:gate], [nana:memory], [nana:recovery], [nana:pending], [nana:enforce], [nana:kit]. Future hooks must follow convention.
  source: [[decision:hook-prefix-nana-namespace]] | activated: 2026-05-23
- [uses: 1] install.sh --status shows runtime inventory: counts skills, hooks, rules, checks memory venv, reads VERSION, checks enforcement marker. Grouped by module category. No separate nana-status.sh script.
  source: [[decision:status-in-install-sh]] | activated: 2026-05-23
- [uses: 1] MANIFEST descriptions are additive comment section (# <skill-dir>: <first sentence from SKILL.md>) after existing md5+path checksums. Manually maintained -- no automation.
  source: [[journal:2026-05-23-phase-28-dx-discoverability-complete]] | activated: 2026-05-23
- [uses: 1] memory_forget(memory_id, superseded_by="", scope="project") for soft delete with optional supersession chain; memory_prune only targets trust='low' + strength=1 so is dead code for bridge/harvest entries (trust='medium'/'high')
  source: [[decision:memory-supersede-harness-layer]] + [[wiki:memory-mcp-api]] | activated: 2026-05-23
- [uses: 1] Crash recovery dual condition: commits newer than _CURRENT_STATE.md mtime AND no debrief commit in recent history. Advisory only (exit 0). Guarded by test -f .dev-wiki/_CURRENT_STATE.md. Case-insensitive Debrief grep on git log.
  source: [[decision:crash-recovery-dual-condition]] | activated: 2026-05-23
- [uses: 1] Memory-bridge auto-supersede: search existing bridge-decisions for same phase-slug, store new, memory_forget highest-scoring conflict with superseded_by. 10-call cap per bridge run, 1 supersede per decision max. Ceiling 500.
  source: [[decision:memory-supersede-harness-layer]] | activated: 2026-05-23
- [uses: 3] Eval design: binary scoring only (pass=1.0, fail=0.0), jq hard dependency, eval/ top-level directory separate from tests/; make eval never called by make test; 50 scenarios in 4 categories (hook, skill, context, lifecycle); eval/comparison/ for harness effectiveness
  source: [[decision:eval-binary-scoring-only]] + [[decision:eval-jq-hard-dependency]] + [[decision:eval-top-level-directory]] | activated: 2026-05-22
- [uses: 2] Eval harnesses should measure 3 layers: outcome (did it work), trajectory (was path efficient), system metrics (cost/latency); for dev-kit self-eval, focus on outcome + trajectory, defer system metrics. Self-grading bias: same LLM writing + evaluating inflates pass rates — methodology must acknowledge.
  source: [[wiki:agentic-eval-3-layer-model]] | activated: 2026-05-22
- [uses: 2] Skill tool `Skill(skill="spec", args=...)` is the established pattern for cross-skill calls; companion files isolate orchestration logic from main SKILL.md; cp -r auto-distributes new companions without install.sh changes
  source: [[wiki:skill-tool-invocation-pattern]] | activated: 2026-05-22
- [uses: 2] memory_server/ vendored from nanaclaw (12 .py, 2,376 LOC); runs via MCP stdio (python -m memory_server). Near-zero divergence from upstream (900 vs 903 lines, only _sanitize_fts_query differs). Patch at patches/nanaclaw-sanitize-fts.patch.
  source: [[decision:vendor-memory-server]] + [[decision:nanaclaw-divergence-inventory]] | activated: 2026-05-24
- [uses: 2] MCP registration uses idempotent JSON merge via scripts/register-settings.py (was inline python3, extracted Phase 40); handles 3 cases: no settings.json, existing without mcpServers, existing with mcpServers
  source: [[decision:install-sh-scope-expansion]] + [[decision:install-sh-extraction-approach]] | activated: 2026-05-25
- [uses: 3] Gate enforcement uses two layers: active-phase.md Gates section (5 checkpoints, preventive) + tasks.md gate log HTML comments (detective, auditable)
  source: [[decision:gate-enforcement-checklist-plus-log]] | activated: 2026-05-19
- [uses: 3] Hook exit codes: 0 = allow (tool use proceeds), 2 = block (stderr shown to Claude); PreToolUse receives JSON on stdin with input.file_path; PostToolUse receives tool_name, tool_input, stdout, stderr, exit_code; advisory hooks MUST exit 0
  source: [[wiki:hook-exit-codes]] | activated: 2026-05-22
- [uses: 3] Enforcement hooks (enforce-spec.sh, enforce-loop.sh, detect-loop.sh) install globally to ~/.claude/hooks/; check CWD .claude/enforce marker (fail-open); install.sh JSON merges hooks into settings.json
  source: [[decision:global-hooks-project-opt-in]] | activated: 2026-05-22
