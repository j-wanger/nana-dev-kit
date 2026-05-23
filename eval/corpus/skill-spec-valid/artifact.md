# Spec: Acme Widget Builder

## Objective

Build a widget builder that compiles widget definitions into deployable artifacts.

## Context

The Acme project needs automated widget compilation. Currently done manually, taking 2 hours per release.

## Scope

### In scope
- Widget definition parser
- Compilation pipeline
- Output artifact generation

### Out of scope
- Widget runtime
- Deployment automation
- Visual editor

## Approach

Parse YAML widget definitions, validate schema, compile to JavaScript bundles using the existing build system.

## Constraints (CRITICAL)

- Output bundles must be under 100KB each: prevents performance degradation in production.
- Widget definitions must be validated before compilation: prevents malformed output.
- Build must complete in under 30 seconds: CI timeout constraint.

## Deliverables

1. `src/parser.py` — YAML parser for widget definitions
2. `src/compiler.py` — Compilation pipeline
3. `tests/test_compiler.py` — Unit tests

## Exit Criteria (machine-checkable)

- [ ] `test -f src/parser.py`
- [ ] `test -f src/compiler.py`
- [ ] `python -m pytest tests/test_compiler.py`

## Checkpoints

- After parser implementation: report test coverage
- After compiler pipeline: run full build, verify output size

## Assumptions

- YAML library is available in the project virtualenv. If false: add PyYAML to requirements.txt.
- Widget definitions follow the schema documented in docs/widget-spec.md. If false: create the schema first.
