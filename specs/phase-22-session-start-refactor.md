# Spec: Phase 22 — Session-Start Refactor + v0.4.0 Ship

## Objective

Extract the two heaviest concerns from session-start.sh (working-knowledge pruning and memory consolidation nudge) into sourced modules, fix the scan-secrets.sh BSD grep bug, update the stale gap analysis, and ship v0.4.0.

## Context

session-start.sh grew organically across Phases 15-17 to 125 lines with 8 interleaved concerns. The two heaviest — working-knowledge pruning (44 lines with Python date math) and memory consolidation nudge (20 lines with sqlite3 + cooldown) — account for half the file. The remaining 6 concerns are 5-10 lines each and don't warrant extraction. scan-secrets.sh has a known BSD grep bug: `\x27` in an ERE pattern is treated literally on macOS instead of matching a single quote. The eval fixture works around this with double quotes, masking the bug. The gap analysis document hasn't been updated since Phase 18 but Phases 19-21 closed gaps 1.3, 3.3, 4.2, and 4.4. Project is at v0.3.0 with 128 tests and 38/38 eval scenarios after 8 phases of feature work since the last release.

## Scope

### In scope
- Extract working-knowledge pruning into `templates/.claude/hooks/session-start.d/wk-prune.sh` (sourced by session-start.sh)
- Extract memory consolidation nudge into `templates/.claude/hooks/session-start.d/memory-nudge.sh` (sourced by session-start.sh)
- Fix scan-secrets.sh grep pattern: replace `\x27` with shell quote-break pattern (`'"'"'`) for POSIX-portable single-quote matching
- Update eval fixture for scan-secrets to use single quotes (prove the fix works, not just that a workaround passes)
- Update gap analysis (roadmap-gap-analysis.md): close gaps verified by Phases 19-21, cite specific phase/evidence
- Update install.sh to copy `session-start.d/` directory alongside session-start.sh
- Bump VERSION to 0.4.0, update _ARCHITECTURE.md file counts, tag + push
- Update tests for new file structure

### Out of scope
- Changing session-start.sh behavior — output must be identical before and after refactor
- Refactoring the 6 lightweight concerns (5-10 lines each don't warrant extraction)
- Fixing the concurrent-session race in working-knowledge pruning (pre-existing, not introduced by this refactor)
- wiki-index Python language-neutrality (Gap 4.1 — separate phase)
- Report regeneration (generate-report.py, generate-workflow.py — ship what we have)

## Approach

**Modular sourcing pattern:** Create `templates/.claude/hooks/session-start.d/` with two modules. Each module defines a single function (no top-level side effects). session-start.sh sources both files and calls the functions at the appropriate point in its flow. The orchestrator (session-start.sh) shrinks from ~125 to ~60 lines.

**Module contract:** Each module file declares its expected inputs (env vars, file paths) in a one-line comment. Functions take arguments rather than reading globals. No module sets state that another module reads.

**scan-secrets fix:** Replace `\x27` with the shell quote-break pattern (`'"'"'`) in the grep ERE. This is POSIX-portable — works on both BSD grep (macOS) and GNU grep (Linux). Update the eval fixture `hook-scan-secrets-file` to use a single-quoted secret value instead of double quotes.

**Gap analysis:** For each gap marked as closed, cite the specific phase. Verify with file existence or grep, not memory alone.

## Constraints (CRITICAL)

- **Behavioral equivalence:** session-start.sh output must be byte-identical before and after refactor for any given project state. Prevents: silent regression in context injection that breaks every session.
- **No load-order dependencies between modules:** Each extracted module must be independently sourceable. No module may set global state that another module reads. Prevents: fragile implicit coupling that breaks when modules are reordered or removed.
- **install.sh must copy session-start.d/ directory:** Current hook install is file-by-file. Must add directory copy for the new module dir. Prevents: session-start.sh sourcing files that don't exist after install.
- **scan-secrets fix must be POSIX-portable:** The grep pattern must work on both BSD grep (macOS) and GNU grep (Linux CI). Use quote-break (`'"'"'`), not bash-only ANSI-C quoting (`$'\x27'`). Prevents: fixing macOS by breaking Linux.
- **Eval fixture update is atomic with grep fix:** The scan-secrets eval scenario must be updated in the same commit as the grep fix. Prevents: a passing eval that doesn't actually test the fixed behavior.
- **Gap closures cite evidence:** Each gap marked closed must reference the specific phase number. Prevents: stale claims about closed gaps.

## Deliverables

1. `templates/.claude/hooks/session-start.d/wk-prune.sh` — working-knowledge pruning function (~45 lines)
2. `templates/.claude/hooks/session-start.d/memory-nudge.sh` — memory consolidation nudge function (~25 lines)
3. Modified `templates/.claude/hooks/session-start.sh` — orchestrator sourcing modules (~60 lines)
4. Modified `templates/.claude/hooks/scan-secrets.sh` — fixed grep pattern (1-line change)
5. Modified `eval/corpus/hook-scan-secrets-file/` — fixture uses single-quote secret value
6. Modified `.dev-wiki/articles/roadmap-gap-analysis.md` — gaps 1.3, 3.3, 4.2, 4.4 closed with phase citations
7. Modified `install.sh` — copies session-start.d/ directory
8. Modified `VERSION` — 0.4.0
9. Updated tests in `tests/test_harden.sh` and `tests/test_install.sh`

## Exit Criteria (machine-checkable)

- [ ] `test -f templates/.claude/hooks/session-start.d/wk-prune.sh && bash -n templates/.claude/hooks/session-start.d/wk-prune.sh`
- [ ] `test -f templates/.claude/hooks/session-start.d/memory-nudge.sh && bash -n templates/.claude/hooks/session-start.d/memory-nudge.sh`
- [ ] `[ $(wc -l < templates/.claude/hooks/session-start.sh) -le 70 ]`
- [ ] `grep -c 'source.*session-start\.d/' templates/.claude/hooks/session-start.sh | grep -q '^2$'`
- [ ] `! grep -q '\\x27' templates/.claude/hooks/scan-secrets.sh`
- [ ] `test -d eval/corpus/hook-scan-secrets-file && grep -rq "'" eval/corpus/hook-scan-secrets-file/`
- [ ] `grep -c 'CLOSED.*Phase' .dev-wiki/articles/roadmap-gap-analysis.md | grep -qE '^[4-9]'`
- [ ] `grep -qx '0.4.0' VERSION`
- [ ] `make test`
- [ ] `make eval 2>&1 | grep -qE 'Score.*100'`

## Checkpoints

- After extracting modules + updating session-start.sh: run existing test_harden.sh tests to verify behavioral equivalence before any other changes
- After scan-secrets fix: verify the grep pattern works on the local macOS grep before updating the eval fixture
- If any existing test breaks after refactor: STOP and verify the module extraction preserved exact behavior

## Assumptions

- Claude Code invokes hooks as standalone scripts (`bash hook.sh`), never sources them. If false: module sourcing with `source` may leak variables into unexpected scopes — refactor modules to be standalone scripts called via `bash module.sh` with arguments.
- `session-start.d/` as a subdirectory of `hooks/` won't confuse Claude Code's hook discovery (it only reads files listed in settings.json, not directory contents). If false: move modules to a different path outside `hooks/`.
- The `\x27` pattern in scan-secrets.sh is the only BSD grep incompatibility in the hook suite. If false: audit other hooks for similar patterns but don't fix them in this phase.
- Gap analysis gaps 1.3, 3.3, 4.2, 4.4 were actually closed by Phases 19-21. If false: mark as PARTIAL with explanation instead of CLOSED.
