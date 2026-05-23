# Spec: Phase 28 — DX Discoverability

## Objective

Normalize hook message format across 11 hooks, add a runtime status command (`install.sh --status`), and enrich the MANIFEST with skill descriptions — so users and Claude can discover what's installed, what's active, and what each piece does.

## Context

After 27 phases (v0.5.0), nana-dev-kit has 22 skills, 11 hooks, and 163 tests. A multi-angle critique of v0.4.0 identified DX discoverability as the largest unaddressed cluster: hook messages use inconsistent prefixes (`[warn]`, `[enforce-loop]`, `[recovery]`, unprefixed "Warning:", unprefixed "No approved spec..."), there's no runtime way to check installation health, and the MANIFEST at `templates/.claude/skills/MANIFEST` lists files with md5 checksums but no descriptions. Claude Code's system-reminder already lists available skill names during sessions, but without descriptions or grouping — an enriched MANIFEST could serve as a quick-reference for Claude.

The main audience for improved messages is Claude (hooks communicate via stdout/stderr to Claude's context), but consistent formatting also helps users reading logs or debugging hook behavior.

The 11 hooks are: `audit-log.sh`, `auto-ruff-format.sh`, `block-dangerous-bash.sh`, `check-tests-were-run.sh`, `detect-loop.sh`, `enforce-loop.sh`, `enforce-spec.sh`, `post-commit.sh`, `pre-compact.sh`, `scan-secrets.sh`, `session-start.sh`. The `session-start.d/` modules (`wk-prune.sh`, `memory-nudge.sh`) are sourced by session-start.sh, not standalone hooks.

## Scope

### In scope
- **Hook message prefix normalization** — all 11 hooks adopt `[nana:<hook-name>]` prefix format on every echo/stderr line (except the jq fail-open guard which keeps `[warn]`)
- **`install.sh --status`** — dynamic check of what's installed: file existence for rules/skills/hooks, settings.json registration, memory server venv, VERSION, enforcement marker. No new dependencies.
- **MANIFEST enrichment** — add one-line description per skill directory, keeping the existing `<md5>  <path>` checksum lines intact
- **Session-start kit summary** — one summary line at end of session-start output showing installed counts
- **Tests + eval updates** — update all assertions affected by prefix changes; add tests for --status flag and MANIFEST descriptions

### Out of scope
- `/nana-help` skill (system-reminder already lists skills; --status covers runtime health)
- Changing hook behavior or exit codes (prefix format only)
- Hook audience rearchitecture (stdout=advisory/Claude, stderr=blocking/Claude is already correct; this phase normalizes format, not routing)
- Language-agnostic mode (Gap 4.1 — remains deferred)
- New hooks or new skills
- Memory server health checks beyond venv existence (MCP stdio has no PID to check)

## Approach

**Hook prefix normalization**: Adopt `[nana:<hook-name>]` as the universal prefix. Complete mapping:

| Hook script | Prefix |
|------------|--------|
| `audit-log.sh` | `[nana:audit]` |
| `auto-ruff-format.sh` | `[nana:ruff]` |
| `block-dangerous-bash.sh` | `[nana:block]` |
| `check-tests-were-run.sh` | `[nana:tests]` |
| `detect-loop.sh` | `[nana:loop]` |
| `enforce-loop.sh` | `[nana:enforce-loop]` |
| `enforce-spec.sh` | `[nana:enforce-spec]` |
| `post-commit.sh` | `[nana:post-commit]` |
| `pre-compact.sh` | `[nana:compact]` |
| `scan-secrets.sh` | `[nana:secrets]` |
| `session-start.sh` | `[nana:session]` |

Exception: the jq fail-open guard (`[warn] jq not found, hook skipped`) is cross-cutting and keeps its existing `[warn]` prefix — it's a dependency warning, not a hook-specific message.

Build a change manifest before modifying: grep all test/eval assertions on current message strings, update atomically.

**install.sh --status**: Add a `--status` flag to the existing flag parser. Check filesystem state dynamically: count `~/.claude/skills/*/SKILL.md` files, count `~/.claude/hooks/*.sh` files, check `~/.claude/rules/nana-soul.md` existence, read VERSION from kit path marker, check `~/.claude/memory_server/.venv/` existence, check `~/.claude/enforce` marker. Output a grouped summary. No new files — the handler lives in install.sh alongside the existing flag logic (~40-60 lines).

**MANIFEST enrichment**: The MANIFEST is manually generated (no Makefile target). Add a `# descriptions` section after the existing checksum lines with format: `# <skill-dir>: <one-line description>`. Descriptions are extracted from each SKILL.md: the first line after YAML frontmatter (if any) and markdown headers that contains alphabetic text, truncated at the first period. If no suitable line found, use "No description". The existing `<md5>  <path>` lines remain untouched above the descriptions section.

**Session-start summary**: Add a final line before `exit 0` that counts installed skills and hooks dynamically. Format: `[nana:kit] N skills, M hooks, memory <active|absent>, v<VERSION>`. Budget: ≤ 120 chars.

## Constraints (CRITICAL)

- **Atomic message changes.** Every hook message prefix change must be accompanied by updates to ALL test and eval assertions that match on the old string. Build the change manifest first (grep all affected files), then apply changes. Prevents: green tests masking broken eval, or vice versa.
- **No hook behavior changes.** Exit codes, branching logic, and audience routing (stdout vs stderr) must remain identical. Only the text content of echo/printf lines changes. Prevents: accidental regression in enforcement behavior.
- **Dynamic --status, not hardcoded.** The status command must derive all counts and paths from filesystem checks, never from hardcoded lists. Prevents: --status going stale as the kit evolves.
- **Session-start context budget.** The new summary line must be ≤ 120 chars. Total session-start output must not grow by more than 2 lines. Prevents: context window bloat for Claude.
- **MANIFEST backwards compatibility.** The existing `<md5>  <path>` checksum lines must remain unchanged. Descriptions are appended as comment lines below. Prevents: breaking any tool that reads checksum lines.

## Deliverables

1. Modified 11 hook scripts — consistent `[nana:<hook-name>]` prefix format per the mapping table
2. Modified `install.sh` — `--status` flag handler (~40-60 lines)
3. Modified `templates/.claude/skills/MANIFEST` — `# descriptions` section added
4. Modified `templates/.claude/hooks/session-start.sh` — kit summary line
5. Modified `tests/` — updated assertions for new prefixes + new --status tests + MANIFEST description test
6. Modified `eval/corpus/` — updated assertions for new prefixes (8 assertions across 7 scenarios)

## Exit Criteria (machine-checkable)

- [ ] `make test`
- [ ] `make eval`
- [ ] `bash install.sh --status 2>&1 | grep -q 'skills'`
- [ ] `grep -rL '\[nana:' templates/.claude/hooks/*.sh | wc -l | grep -q '^0$'` (all 11 hooks have nana: prefix)
- [ ] `grep -c '^# [a-z]' templates/.claude/skills/MANIFEST | grep -qE '^[1-9][0-9]'` (10+ skill description lines)
- [ ] `grep -q '\[nana:kit\]' templates/.claude/hooks/session-start.sh`

## Checkpoints

- After hook prefix changes + test/eval updates: run `make test && make eval` before proceeding to --status
- After --status implementation: verify with `install.sh --status` (reads filesystem, no writes) and report before proceeding to MANIFEST
- If any existing test breaks unexpectedly: STOP and investigate — likely a missed assertion in the change manifest

## Assumptions

- All 11 hooks use echo or printf for output (no other output mechanisms). If false: audit and adapt the prefix application approach.
- `install.sh --status` can reuse the existing flag parsing case statement. If false: extend the flag parser minimally.
- Eval scenario assertions use `stderr_contains`/`stdout_contains` with substring matching, so prefix changes only require updating the matched substring. If false: check the eval-runner assertion mechanism first.
- The `[warn]` prefix for jq guards does not conflict with any `[nana:]` prefix. If false: rename the jq guard to `[nana:warn]` for consistency.
