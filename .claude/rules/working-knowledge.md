# Working Knowledge
<!-- Cross-phase knowledge. Auto-managed by dev-debrief and wiki-query. -->

- [uses: 2] Eval design: binary scoring only (pass=1.0, fail=0.0), jq hard dependency, eval/ top-level directory separate from tests/; make eval never called by make test; 38 scenarios in 4 categories (hook, skill, context, lifecycle)
  source: [[decision:eval-binary-scoring-only]] + [[decision:eval-jq-hard-dependency]] + [[decision:eval-top-level-directory]] | activated: 2026-05-22
- [uses: 1] Context eval is a new runner category (not folded into hook/skill); eval report shows "context 4/4" directly answering "do rules reach the model?"; checks array with file_exists, section_present, hook_output types
  source: [[decision:context-eval-new-category]] | activated: 2026-05-22
- [uses: 1] Fixture JSON must match per-hook stdin field paths: audit-log/auto-ruff/scan-secrets use {"input":{"file_path":"..."}}, block-dangerous-bash uses {"input":{"command":"..."}}, check-tests-were-run uses {"tool_uses":[...]}
  source: [[decision:hook-stdin-per-hook-contracts]] | activated: 2026-05-22
- [uses: 1] scan-secrets.sh has macOS BSD grep compatibility bug: \x27 in pattern doesn't match single quotes; eval fixture uses double quotes as workaround
  source: [[journal:2026-05-22-phase-21-eval-expansion-complete]] | activated: 2026-05-22
- [uses: 1] Eval harnesses should measure 3 layers: outcome (did it work), trajectory (was path efficient), system metrics (cost/latency); for dev-kit self-eval, focus on outcome + trajectory, defer system metrics
  source: [[wiki:agentic-eval-3-layer-model]] | activated: 2026-05-22
- [uses: 1] Scenario-based eval needs 4 components per case: initial context (fixture), interaction script (input), oracle assertions (expected), timeouts; structured JSON manifest per scenario
  source: [[wiki:scenario-eval-structure]] | activated: 2026-05-22
- [uses: 1] Memory store Category enum: fact/preference/correction/entity/custom -- no "decision" category; use category="custom" with tags=["bridge-decision"] for all bridge entries
  source: [[decision:memory-bridge-category-custom]] | activated: 2026-05-22
- [uses: 1] Budget guard for memory entries uses memory_stats MCP tool (not empty-query memory_search which returns 0 after FTS sanitization); fallback: memory_search("bridge-decision", limit=50) count
  source: [[decision:memory-bridge-budget-guard-stats]] | activated: 2026-05-22
- [uses: 1] Memory bridge runs inline in dev-plan orchestrator after artifact-writer subagent returns -- Agent subagents cannot access MCP tools (memory_store/memory_stats)
  source: [[decision:memory-bridge-inline-orchestrator]] | activated: 2026-05-22
- [uses: 2] Skill tool `Skill(skill="spec", args=...)` is the established pattern for cross-skill calls; companion files isolate orchestration logic from main SKILL.md; cp -r auto-distributes new companions without install.sh changes
  source: [[wiki:skill-tool-invocation-pattern]] | activated: 2026-05-22
- [uses: 1] spec SKILL.md pre-check blocks when dev-wiki has uncompleted tasks; between phases (all tasks done) the guard does NOT fire -- auto-invocation is safe
  source: [[wiki:spec-precheck-between-phases]] | activated: 2026-05-22
- [uses: 1] install.sh directory-based copy (`cp -r`) means new companion files in existing skill dirs auto-distribute without install.sh changes
  source: [[journal:2026-05-22-phase-18-spec-devplan-ux-complete]] | activated: 2026-05-22

- [uses: 1] install.sh performs 6 actions: copies py-init + spec skills, nana-soul + nana-personal + file-lifecycle rules, kit path marker, memory_server/ + registers MCP server in settings.json
  source: [[decision:install-sh-scope-expansion]] | activated: 2026-05-19
- [uses: 1] README targets ~58 lines with install + usage + 5-layer table + memory/dev-wiki section; self-test.md is the detailed reference
  source: [[wiki:readme-concise-format]] | activated: 2026-05-15
- [uses: 1] .dev-wiki/ is committed as project lifecycle artifact; .claude/settings.local.json is excluded via .gitignore
  source: [[wiki:commit-dev-wiki-in-initial-commit]] | activated: 2026-05-15
- [uses: 1] install.sh is idempotent: copies 6 items + memory_server + JSON merge; running twice produces identical results
  source: [[file:install]] | activated: 2026-05-19
- [uses: 1] sync-rules.sh writes 4 outputs (CLAUDE.md, GEMINI.md, copilot-instructions.md, .cursor/rules/main.mdc) with AUTO-GENERATED headers; missing AGENTS.md exits non-zero
  source: [[file:scripts-sync-rules]] | activated: 2026-05-15
- [uses: 1] Templates use {{PACKAGE_NAME}}, {{PROJECT_DESCRIPTION}}, {{PROJECT_NAME}} placeholders; tests verify presence via grep, not substitution
  source: [[decision:structural-placeholder-verification]] | activated: 2026-05-15
- [uses: 1] install.sh has upfront source validation; asymmetric error handling (2>/dev/null || true) removed in Phase 3
  source: [[journal:2026-05-15-phase-3-distribution-and-polish-complete]] | activated: 2026-05-15
- [uses: 1] sync-rules.sh has writability pre-check; exits non-zero with clear error if target dir is unwritable
  source: [[journal:2026-05-15-phase-3-distribution-and-polish-complete]] | activated: 2026-05-15
- [uses: 1] VERSION file at repo root is single source of truth for semantic versioning; install.sh has no version-awareness at v0.x
  source: [[decision:v0-versioning-strategy]] | activated: 2026-05-15
- [uses: 1] Kit CI at .github/workflows/kit-ci.yml is distinct from templates/.github/workflows/ci.yml; shellcheck is CI-only
  source: [[decision:kit-ci-separate-from-template]] | activated: 2026-05-15
- [uses: 1] memory_server/ vendored from nanaclaw (12 .py, 2,373 LOC); runs via MCP stdio (python -m memory_server)
  source: [[decision:vendor-memory-server]] | activated: 2026-05-15
- [uses: 1] session-start.sh reads 2 sources: py-session-state.md, dev-wiki/_CURRENT_STATE.md; memory access is MCP-only (memory_search); MEMORY.md removed in Phase 10
  source: [[decision:memory-convergence-mcp-only]] | activated: 2026-05-19
- [uses: 1] MCP registration uses idempotent python3 JSON merge; handles 3 cases: no settings.json, existing without mcpServers, existing with mcpServers
  source: [[decision:install-sh-scope-expansion]] | activated: 2026-05-15
- [uses: 1] memory_server pip deps auto-installed by install.sh in venv at ~/.claude/memory_server/.venv/ (updated Phase 5)
  source: [[journal:2026-05-19-phase-5-and-6-complete]] | activated: 2026-05-19
- [uses: 1] scripts/generate-workflow.py (738 lines) generates docs/workflow.html; distinct from generate-report.py (package inventory)
  source: [[journal:2026-05-19-phase-5-and-6-complete]] | activated: 2026-05-19
- [uses: 1] Venv bootstrap at ~/.claude/memory_server/.venv/ with graceful fallback; MCP config uses venv Python after deps installed
  source: [[decision:venv-isolated-memory-deps]] | activated: 2026-05-19
- [uses: 1] VERSION bumped to 0.3.0; Makefile has 4 targets: sync-rules, test, report, workflow
  source: [[journal:2026-05-20-phase-13-final-polish-and-ship-complete]] | activated: 2026-05-20
- [uses: 1] GitHub remote: origin -> https://github.com/j-wanger/nana-dev-kit.git; v0.2.0 tagged and pushed
  source: [[journal:2026-05-19-phase-5-and-6-complete]] | activated: 2026-05-19
- [uses: 1] Soul vs AGENTS.md delineation: soul = cognitive identity (universal, all projects/languages), AGENTS.md = operational contract (project-specific). Litmus: "would this apply in a Rust project?" Yes → soul, No → AGENTS.md
  source: [[decision:soul-vs-agents-delineation]] | activated: 2026-05-19
- [uses: 1] nana-soul.md Thinking protocol has trigger clause (trade-offs/design/advisory), cost-of-error proportionality, 5 moves (read subtext, challenge frame, delay commitment, informed search H8, lateral scope H9); 59 lines total. T0 in dev-plan SKILL.md uses output-format forcing (not abstract checks).
  source: [[journal:2026-05-21-phase-14-adversarial-thinking-and-review-complete]] | activated: 2026-05-21
- [uses: 1] Instruction budget: soul (59) + personal + lifecycle + AGENTS.md + nana.instructions.md = 245/300 lines; regression test in test_templates.sh enforces ceiling + soul <=60 assertion
  source: [[journal:2026-05-20-phase-13-final-polish-and-ship-complete]] | activated: 2026-05-20
- [uses: 1] install.sh copies 6 items: py-init SKILL.md, spec/ skill, nana-soul.md, nana-personal.md, file-lifecycle.md, kit path marker + memory_server/ + MCP registration
  source: [[journal:2026-05-19-phase-9-file-lifecycle-reference-complete]] | activated: 2026-05-19
- [uses: 1] /spec skill has two-tier review gate: Tier 0 structural lint (inline, deterministic) + Tier 1 semantic subagent (6 dimensions); adaptive persistence (dev-wiki -> /dev-plan, standalone -> specs/)
  source: [[decision:spec-two-tier-review-gate]] | activated: 2026-05-19
- [uses: 1] specs/ directory at project root for standalone spec persistence; phase-08-spec-skill.md is the exemplar (Opus-reviewed 8/10)
  source: [[decision:spec-persistence-adaptive]] | activated: 2026-05-19
- [uses: 1] Phase template has 3 optional sections (Constraints, Checkpoints, Assumptions) backported from /spec; dev-plan Step 6 has spec-field coverage note
  source: [[journal:2026-05-19-phase-8-spec-skill-complete]] | activated: 2026-05-19
- [uses: 1] templates/.claude/rules/file-lifecycle.md (32 lines) is a routing table with 4 categories (user, agent, skill, hook) + decision routing section
  source: [[journal:2026-05-19-phase-9-file-lifecycle-reference-complete]] | activated: 2026-05-19
- [uses: 1] specs/phase-09-file-lifecycle-reference.md is the second formal spec (Opus 9/10); first was phase-08-spec-skill.md (8/10)
  source: [[journal:2026-05-19-phase-9-file-lifecycle-reference-complete]] | activated: 2026-05-19
- [uses: 3] Gate enforcement uses two layers: active-phase.md Gates section (5 checkpoints, preventive) + tasks.md gate log HTML comments (detective, auditable)
  source: [[decision:gate-enforcement-checklist-plus-log]] | activated: 2026-05-19
- [uses: 1] Memory access is MCP-only: memory_store to write, memory_search to read; .memory/MEMORY.md files are inert legacy (not deleted, just not read)
  source: [[decision:memory-convergence-mcp-only]] | activated: 2026-05-19
- [uses: 1] nana-soul.md now 59 lines (Phase 13: added H8+H9 thinking heuristics); ceiling is 60 lines
  source: [[journal:2026-05-20-phase-13-final-polish-and-ship-complete]] | activated: 2026-05-20
- [uses: 1] Layered gate enforcement: preventive (implementation-guide.md pre-flight refusal) + detective (dev-debrief gate-compliance audit) + template (session-start.sh gate-check warning); mirrors Tier 0/1 review pattern
  source: [[decision:layered-gate-enforcement-automated]] | activated: 2026-05-19
- [uses: 1] Standard ceremony expects 4 gates (spec, approach, plan-review, tasks); Lite expects 2 (approach, tasks); n/a with justification is valid; SKIPPED without justification is flagged
  source: [[journal:2026-05-19-phase-11-process-hardening-complete]] | activated: 2026-05-19
- [uses: 1] Soul compression: 3 "What to avoid" bullets are redundant (sycophantic=Thinking protocol, more code=Work habits+CQL#1, over-broad exceptions=CQL#2); compress before adding new content
  source: [[decision:soul-warmth-via-compression]] | activated: 2026-05-20
- [uses: 1] Memory-harvest is a dev-debrief companion (Step 1.5/4.7), not a standalone skill; routes corrections/preferences/lessons to memory_store, decisions to wiki articles
  source: [[decision:memory-harvest-in-debrief]] | activated: 2026-05-20
- [uses: 1] dev-plan Step 0.6 spec-existence check (standard ceremony only): requires specs/<phase-slug>.md or phase article ## Formal Spec before planning proceeds
  source: [[decision:spec-and-thinking-enforcement-in-devplan]] | activated: 2026-05-20
- [uses: 1] dev-plan Step 6 has thinking-protocol T0: challenge frame, read subtext, delay commitment before approach formulation (conversational only, no artifacts)
  source: [[decision:spec-and-thinking-enforcement-in-devplan]] | activated: 2026-05-20
- [uses: 1] nana.instructions.md must byte-match nana-soul.md minus 4-line YAML frontmatter; verified by diff <(tail -n +5 ...) in test suite
  source: [[decision:soul-vs-agents-delineation]] | activated: 2026-05-20
- [uses: 1] install.sh conditionally copies nana-personal.md (skips if ~/.claude/rules/nana-personal.md already exists); template has no user-specific content
  source: [[decision:personal-profile-template-for-shipping]] | activated: 2026-05-20
- [uses: 1] SKILL.md complex-orchestration ceiling is 350 lines (raised from 250 in Phase 13); enforced in self-check-checklist.md, not size-budgets.md
  source: [[decision:skill-ceiling-250-to-350]] | activated: 2026-05-20
- [uses: 1] v0.3.0 tagged and pushed; first release ready for corporate project testing; 13 phases complete, 65 tests
  source: [[journal:2026-05-20-phase-13-final-polish-and-ship-complete]] | activated: 2026-05-20
- [uses: 1] AgentCoder 3-agent separation: same-context confirmation bias breaks when adversarial constraints generated by clean-context subagent (only objective+context, no approach/decisions)
  source: [[decision:adversarial-constraint-generation-as-spec-step]] | activated: 2026-05-21
- [uses: 1] T0 thinking protocol rewritten from abstract checks to output-format forcing: must name weakest assumption + what breaks, identify alternative framing, state what info would change recommendation; non-vacuity gate retries once
  source: [[decision:t0-wording-over-structural-subagent]] | activated: 2026-05-21
- [uses: 1] Spec SKILL.md Step 2.5 adversarial constraint generation with companion adversarial-constraints-prompt.md (41 lines); install.sh copies it; 124/350 lines
  source: [[decision:adversarial-constraint-generation-as-spec-step]] | activated: 2026-05-21
- [uses: 1] install.sh refactored to module-group architecture (~240 lines) with --all/--core-only/--no-python/--dry-run flags; modules: core (rules + memory), python (py-init + spec), dev-wiki (6 dirs), knowledge-wiki (11 dirs)
  source: [[decision:monorepo-skill-distribution]] | activated: 2026-05-22
- [uses: 1] templates/.claude/skills/ contains 22 skill dirs + MANIFEST (115 files, ~630KB); source repos (~/dev-wiki, ~/knowledge-wiki) are historical — monorepo is canonical
  source: [[decision:import-source-canonical-installed]] | activated: 2026-05-22
- [uses: 1] SIGPIPE race: grep -q in pipefail mode causes premature pipe closure; fix by capturing output to variable first, then grep the variable
  source: [[journal:2026-05-22-phase-15-wire-the-lifecycle-complete]] | activated: 2026-05-22
- [uses: 1] PreCompact hook at templates/.claude/hooks/pre-compact.sh: pure bash, reads committed _CURRENT_STATE.md + tasks.md + active-phase.md, outputs structured summary
  source: [[journal:2026-05-22-phase-15-wire-the-lifecycle-complete]] | activated: 2026-05-22
- [uses: 1] session-start.sh enhanced with memory_search topic guidance (extracts active task topic from dev-wiki state); reads 2 sources + gate-check + memory guidance
  source: [[journal:2026-05-22-phase-15-wire-the-lifecycle-complete]] | activated: 2026-05-22
- [uses: 1] wiki-index ships Python files (indexer.py, search.py, wikilib.py, convert.py) — needs language-neutrality accounting in future phase
  source: [[journal:2026-05-22-phase-15-wire-the-lifecycle-complete]] | activated: 2026-05-22
- [uses: 3] Hook exit codes: 0 = allow (tool use proceeds), 2 = block (stderr shown to Claude); PreToolUse receives JSON on stdin with input.file_path; PostToolUse receives tool_name, tool_input, stdout, stderr, exit_code; advisory hooks MUST exit 0
  source: [[wiki:hook-exit-codes]] | activated: 2026-05-22
- [uses: 3] Enforcement hooks (enforce-spec.sh, enforce-loop.sh, detect-loop.sh) install globally to ~/.claude/hooks/; check CWD .claude/enforce marker (fail-open); install.sh JSON merges hooks into settings.json
  source: [[decision:global-hooks-project-opt-in]] | activated: 2026-05-22
- [uses: 1] Stop hook (enforce-loop.sh) runs only file-existence exit criteria (test -f, test -d) from specs/<slug>.md; open tasks and debrief status are advisory (stdout), not blocking (exit 2)
  source: [[decision:lightweight-deliverable-check-stop]] | activated: 2026-05-22
- [uses: 1] Subshell variable propagation: $(setup_fixture) doesn't export HOME to parent; use inline HOME=... before command instead of export in subshell for test fixtures
  source: [[journal:2026-05-22-phase-16-enforce-the-loop-complete]] | activated: 2026-05-22
- [uses: 1] detect-loop.sh is pure bash exception to python-json-parsing-hooks convention; <50ms PostToolUse budget precludes Python subprocess (~20ms overhead)
  source: [[decision:pure-bash-loop-detection]] | activated: 2026-05-22
- [uses: 1] Working-knowledge entries use [uses: N] format with activated: YYYY-MM-DD; [pinned] tag prevents auto-pruning; sort by activation date (newest first)
  source: [[wiki:working-knowledge-spec]] | activated: 2026-05-22
