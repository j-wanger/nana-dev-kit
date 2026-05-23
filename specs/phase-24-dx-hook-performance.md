# Spec: Phase 24 — DX + Hook Performance

## Objective

Migrate 6 hooks from python3 -c JSON parsing to jq for ~300ms latency reduction per write, improve install.sh onboarding output, and add platform requirements to README.

## Context

A multi-angle critique of v0.4.0 identified that 6 hooks spawn `python3 -c "import sys,json; ..."` for JSON field extraction, adding ~100-200ms per invocation. PostToolUse on Write/Edit fires 3 hooks (auto-ruff, scan-secrets, audit-log), totaling 300-600ms per file write. jq is already a hard dependency for the eval harness and is available on all major package managers. detect-loop.sh was intentionally kept as pure bash for <50ms PostToolUse budget (documented decision `pure-bash-loop-detection`). session-start.d/wk-prune.sh uses python3 for date math (not JSON parsing) and runs at session start, not per-write. install.sh outputs a path list but gives no guidance on the three usage paths. README has no platform requirements section.

## Scope

### In scope
- Migrate 6 hooks from python3 -c to jq: audit-log.sh, auto-ruff-format.sh, block-dangerous-bash.sh, scan-secrets.sh, enforce-spec.sh, check-tests-were-run.sh
- Add jq fail-open guard to each migrated hook (exit 0 with warning if jq missing)
- Add "Getting Started" section to install.sh output with 3 paths: `/dev-init` (lifecycle), `/py-init` (Python), `/wiki-init` (knowledge)
- Add "Requirements" section to README (bash, jq 1.5+, python3, macOS/Linux)
- Update tests

### Out of scope
- detect-loop.sh migration (pure bash decision, <50ms budget — `pure-bash-loop-detection`)
- session-start.d/wk-prune.sh (uses python3 for date math, not JSON parsing; session-start timing, not per-write latency)
- install.sh's own python3 -c usage (install-time cost, not per-write)
- session-start.sh tag prefix refactoring (agent handles output correctly as-is)
- Hook output format changes (jq migration only affects INPUT parsing)
- New eval scenarios (existing scenarios provide functional coverage)

## Approach

**jq migration pattern:** Each hook already captures stdin with `INPUT=$(cat)`. Replace `echo "$INPUT" | python3 -c "..." 2>/dev/null || echo ""` with `echo "$INPUT" | jq -r '.input.file_path // empty' 2>/dev/null || echo ""`. Add jq guard at top: `command -v jq >/dev/null 2>&1 || { echo "[warn] jq not found, hook skipped" >&2; exit 0; }`. For check-tests-were-run.sh (array iteration), use `echo "$INPUT" | jq -r '.tool_uses[].input | (.file_path // .command // "")' 2>/dev/null | while IFS= read -r line` pattern. Restrict to jq 1.5-compatible features (no try-catch).

**install.sh output:** After "Installed:" list and before "Next:", add:
```
Getting started:
  /dev-init     — bootstrap dev-wiki lifecycle tracking
  /py-init      — scaffold Python project with full toolchain
  /wiki-init    — start a knowledge wiki for your domain
```

**README requirements:** Add before Quick Start: "Requires: bash, jq 1.5+, python3 (for memory server). macOS or Linux (Claude Code hooks are bash-only)."

## Constraints (CRITICAL)

- **jq fail-open guard in every hook:** If jq is not installed, hooks must exit 0 (allow) with stderr warning, never exit 2 (block). Prevents: jq absence silently blocking all file writes.
- **Error handling matches python3 pattern:** Use `echo "$INPUT" | jq -r '...' 2>/dev/null || echo ""` to match existing fallback behavior under `set -euo pipefail`. Prevents: jq non-zero exit on malformed JSON killing the hook.
- **Stdin consumed exactly once:** Use `INPUT=$(cat)` then `echo "$INPUT" | jq ...` for each extraction. Never pipe stdin directly to jq twice. Prevents: second jq read getting empty input.
- **check-tests-were-run.sh must use `while IFS= read -r`:** Not `for item in $(jq ...)`. Prevents: word-splitting on tool arguments with spaces.
- **jq 1.5 feature baseline:** Only use `//` (alternative), `-r` (raw output), basic path selectors. No `try-catch`. Prevents: breakage on older systems.
- **detect-loop.sh excluded:** Pure bash, <50ms budget. Do not migrate. Prevents: latency regression on PostToolUse.
- **Hook output format unchanged:** jq migration affects INPUT parsing only. audit-log.sh's jsonl OUTPUT must remain identical. Prevents: downstream consumers breaking.

## Deliverables

1. Modified `templates/.claude/hooks/audit-log.sh` — jq migration (2 fields: file_path, tool_name)
2. Modified `templates/.claude/hooks/auto-ruff-format.sh` — jq migration (1 field: file_path)
3. Modified `templates/.claude/hooks/block-dangerous-bash.sh` — jq migration (1 field: command)
4. Modified `templates/.claude/hooks/scan-secrets.sh` — jq migration (1 field: file_path)
5. Modified `templates/.claude/hooks/enforce-spec.sh` — jq migration (1 field: file_path)
6. Modified `templates/.claude/hooks/check-tests-were-run.sh` — jq migration (array iteration)
7. Modified `install.sh` — "Getting Started" output section
8. Modified `README.md` — "Requirements" section
9. Updated `tests/test_templates.sh` — jq presence assertions

## Exit Criteria (machine-checkable)

- [ ] `! grep -q 'python3 -c' templates/.claude/hooks/audit-log.sh`
- [ ] `! grep -q 'python3 -c' templates/.claude/hooks/auto-ruff-format.sh`
- [ ] `! grep -q 'python3 -c' templates/.claude/hooks/block-dangerous-bash.sh`
- [ ] `! grep -q 'python3 -c' templates/.claude/hooks/scan-secrets.sh`
- [ ] `! grep -q 'python3 -c' templates/.claude/hooks/enforce-spec.sh`
- [ ] `! grep -q 'python3 -c' templates/.claude/hooks/check-tests-were-run.sh`
- [ ] `grep -q 'jq' templates/.claude/hooks/audit-log.sh && grep -q 'command -v jq' templates/.claude/hooks/audit-log.sh`
- [ ] `grep -qi 'requirements' README.md && grep -qi 'jq' README.md`
- [ ] `bash install.sh --dry-run 2>&1 | grep -q '/dev-init'`
- [ ] `make test`
- [ ] `make eval 2>&1 | grep -qE 'Score.*100'`

## Checkpoints

- After migrating first hook (audit-log.sh): run its eval scenarios to verify jq extraction matches python3 behavior
- After migrating check-tests-were-run.sh (most complex): verify array iteration pattern works with Stop hook eval scenarios
- After all 6 hooks migrated: run full `make eval` to verify functional correctness
- If any hook's jq extraction produces different output than the python3 version: STOP and compare field-by-field

## Assumptions

- jq is available on the development machine. If false: hooks fall back to exit 0 with warning (fail-open).
- jq 1.5+ is the baseline on all target platforms (macOS Homebrew, Ubuntu 20.04+). If false: rewrite incompatible feature using 1.5-compatible syntax.
- Hook stdin JSON schema has not changed since python3 parsers were written. If false: update jq extraction and eval fixtures.
- Existing eval scenarios (hook-audit-log-*, hook-scan-secrets-*, hook-enforce-spec-*, hook-block-*, hook-check-tests-*) provide functional coverage for jq correctness. If false: add targeted scenarios for the specific extraction pattern that lacks coverage.
