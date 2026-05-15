---
title: "Phase 1: Foundation & Packaging"
aliases: []
category: phases
tags: [foundation, packaging, install, readme]
parents: []
created: 2026-05-15
updated: 2026-05-15
source: plan
status: active
scope: [".gitignore", "install.sh", "scripts/sync-rules.sh", "Makefile", "README.md"]
entry_criteria: "Dev wiki bootstrapped, code scan complete"
exit_criteria: "install.sh idempotent, sync-rules produces 4 files, README documents 5 layers, clean initial commit"
---

# Phase 1: Foundation & Packaging

## Objective

Light-touch hardening of existing scripts, creation of .gitignore and README, and clean initial commit. install.sh stays minimal (py-init skill + nana-soul rule + kit path marker, no hooks).

## Scope

Files and modules affected:
- `.gitignore` — new, exclude settings.local.json, .nana/, .DS_Store, etc.
- `install.sh` — verify idempotency, fix error handling
- `scripts/sync-rules.sh` — verify correctness of 4 output files
- `Makefile` — sync-rules target
- `README.md` — new, concise format (~40-50 lines)

## Exit Criteria

- [ ] `install.sh` runs clean on a fresh machine (no errors, idempotent)
- [ ] `make sync-rules` produces correct output files (CLAUDE.md, copilot-instructions.md, .cursor/rules/main.mdc, GEMINI.md)
- [ ] README documents all 5 layers, installation steps, and usage workflow
- [ ] Initial git commit with clean project structure

## Notes

- Approach: light-touch hardening, not rewriting
- install.sh stays minimal — hooks are per-project (deployed by /py-init)
- README uses concise format; self-test.md is the detailed reference
- .dev-wiki/ committed as part of project lifecycle management
