# Eval Harness

Benchmark corpus and eval runner for validating nana-dev-kit's hooks, skill contracts, and lifecycle compliance.

## Quick Start

```bash
make eval           # run full corpus
make eval --quick   # hook scenarios only
```

Requires: `jq`

## Corpus Structure

```
eval/
  corpus/           # one dir per scenario
    hook-*/         # hook fidelity scenarios
    skill-*/        # skill contract compliance
    lifecycle-*/    # multi-step lifecycle flows
    context-*/      # rule-file context injection validation
  schemas/          # JSON schemas for hook input contracts
  validators/       # bash validators for skill artifacts
```

Each scenario has a `scenario.json` manifest:

```json
{
  "name": "human-readable description",
  "category": "hook|skill|lifecycle|context",
  "hook": "hook-script.sh",
  "scoring": "binary",
  "setup": {
    "cwd_files": {"dest/path": "fixture-file"},
    "home_files": {"dest/path": "fixture-file"}
  },
  "input": "JSON string piped to hook stdin",
  "expected": {
    "exit_code": 0,
    "stdout_contains": ["pattern"],
    "stderr_contains": ["pattern"]
  }
}
```

## Categories

**Hook fidelity** — Feeds realistic JSON inputs to hooks and validates exit codes, stdout/stderr. Tests enforcement (block/allow), loop detection, session state loading.

**Skill contract compliance** — Validates skill output artifacts (specs, phase articles, decision articles) against their template contracts using `eval/validators/`.

**Lifecycle compliance** — Multi-step scenarios testing hook chains with persistent state. E.g., enforce-spec blocks then allows after spec added.

**Context injection** — Validates that rule files (nana-soul.md, file-lifecycle.md, nana-personal.md) are installed with required sections and get surfaced by session-start.sh. Uses a `checks` array with three check types: `file_exists`, `section_present`, `hook_output`.

## Scoring

Binary pass/fail per scenario. Category averages reported. Overall score is total pass rate.

## Adding a Scenario

1. Create a directory under `eval/corpus/` with prefix matching its category (`hook-`, `skill-`, `lifecycle-`, `context-`)
2. Write `scenario.json` manifest
3. Add fixture files referenced by the manifest
4. Run `make eval` to verify

## Schemas

`eval/schemas/` pins the expected JSON shapes for hook inputs (PreToolUse, PostToolUse, Stop, SessionStart), derived from field-access patterns in `templates/.claude/hooks/`.

## Hook Stdin Contracts

| Hook | Type | Stdin Shape |
|------|------|-------------|
| enforce-spec.sh | PreToolUse | `{"tool_name":"...","input":{"file_path":"..."}}` |
| block-dangerous-bash.sh | PreToolUse | `{"tool_name":"Bash","input":{"command":"..."}}` |
| audit-log.sh | PostToolUse | `{"tool_name":"...","input":{"file_path":"..."}}` |
| auto-ruff-format.sh | PostToolUse | `{"tool_name":"...","input":{"file_path":"..."}}` |
| scan-secrets.sh | PostToolUse | `{"tool_name":"...","input":{"file_path":"..."}}` |
| detect-loop.sh | PostToolUse | `{"tool_name":"...","tool_input":{"command":"..."},"exit_code":N}` |
| check-tests-were-run.sh | Stop | `{"tool_uses":[{"input":{"file_path":"...","command":"..."}}]}` |
| enforce-loop.sh | Stop | `{}` |
| session-start.sh | SessionStart | `""` |
| pre-compact.sh | PreCompact | (reads files from CWD, no stdin) |
