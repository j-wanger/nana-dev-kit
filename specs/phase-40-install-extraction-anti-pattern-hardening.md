<!-- nana:approved -->
# Spec: Phase 40 — install.sh Extraction & Anti-Pattern Hardening

## 1. Objective

Decompose install.sh (542 lines, #1 source of silent regressions) into a declarative manifest + extracted Python registration script. Fix residual Phase 39 bugs (PostToolUse normalization). Codify anti-pattern prevention rules (functional smoke invariant, integration checklist). Clean up stale phase articles.

## 2. Scope

### In-scope
- `install.sh` refactoring: inline Python → `scripts/register-settings.py`, bash arrays → `modules.json`
- `modules.json` creation: skill lists, hook registrations, MCP config per module group
- PostToolUse normalization: `stale-queue.sh`, `post-commit.sh` dual-field fallback
- Phase article housekeeping: delete Phase 12 duplicate, merge Phase 22 duplicates, fix Phase 24 status
- README: add `/init` to Getting Started, update install.sh line count reference
- Functional smoke invariant: rule in spec skill + dev-plan integration checklist
- Tests: register-settings.py unit tests, modules.json consistency, install.sh functional equivalence

### Out-of-scope
- install.sh flag changes or new modules
- New skills or hooks
- Module-group architecture changes (just data/logic extraction)
- Version bump (defer to next phase)
- Companion file frontmatter (lower priority, defer)
- Phase cooldown mechanism (defer — 2-gate model is sufficient for now)

## 3. Constraints

- install.sh must remain idempotent (run twice → identical results)
- All existing tests must pass after refactor (functional equivalence)
- modules.json must be parseable by both jq (install.sh) and Python (register-settings.py)
- register-settings.py must handle all 3 existing JSON merge scenarios: project-local hooks, global hooks, MCP server
- No regressions in `make test` or `make eval`

## 4. Assumptions

- jq is available at install time (already a documented requirement since Phase 24)
- python3 is available at install time (already required for memory server)
- The upsert/flat-to-nested migration logic in inline Python is correct — extract, don't rewrite
- Existing functional tests from Phase 38 cover the critical install paths

## 5. Exit Criteria

1. `install.sh` < 320 lines, zero inline Python (all JSON merges via register-settings.py)
2. `modules.json` exists and defines all 5 module groups with skill lists + hook registrations
3. `scripts/register-settings.py` passes independent tests (upsert, migration, ghost cleanup, MCP)
4. `stale-queue.sh` and `post-commit.sh` have `.tool_input.X // .input.X // empty` fallback
5. No duplicate phase articles; Phase 24 status = completed
6. `make test && make eval` pass at 100%
7. Spec/dev-plan reference functional smoke invariant for new components

## 6. Checkpoints

- After modules.json + register-settings.py: verify `python3 scripts/register-settings.py --help` works
- After install.sh refactor: run full existing test suite to confirm functional equivalence
- After all tasks: `make test && make eval` at 100%

## 7. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| install.sh refactor breaks obscure path | Medium | High | Phase 38 functional tests catch it; run full suite after each change |
| modules.json schema too rigid for future modules | Low | Medium | Keep schema simple (skill list + hook list), extend later |
| register-settings.py Python version incompatibility | Low | Low | Target Python 3.8+ (same as memory server) |
