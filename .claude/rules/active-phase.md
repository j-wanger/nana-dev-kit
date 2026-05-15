# Active Phase Context

Phase: 1 - Foundation & Packaging
Objective: Harden existing scripts, add .gitignore + README, clean initial commit.
Scope: .gitignore, install.sh, scripts/sync-rules.sh, Makefile, README.md
Key constraints:
- install.sh is minimal: py-init skill + nana-soul rule + kit path marker only
- README ~40-50 lines: install + usage + 5-layer table
- .dev-wiki/ included in initial commit; settings.local.json excluded
Exit criteria:
- install.sh idempotent on fresh machine
- sync-rules produces CLAUDE.md, GEMINI.md, copilot-instructions.md, .cursor/rules/main.mdc
- README documents 5 layers, install steps, usage
- Clean initial git commit
Abort: if blocked >3 attempts on any task, ask user: skip or abort
