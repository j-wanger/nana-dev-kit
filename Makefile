# Nana Dev Kit — project-level targets
# These targets operate on the CWD (the project using the kit).

NANA_KIT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: sync-rules test eval report workflow

sync-rules:
	@bash "$(NANA_KIT_DIR)scripts/sync-rules.sh" . .

test:
	@echo "Running tests..."
	@bash "$(NANA_KIT_DIR)tests/test_install.sh"
	@bash "$(NANA_KIT_DIR)tests/test_sync_rules.sh"
	@bash "$(NANA_KIT_DIR)tests/test_templates.sh"
	@bash "$(NANA_KIT_DIR)tests/test_enforce.sh"
	@bash "$(NANA_KIT_DIR)tests/test_harden.sh"
	@bash "$(NANA_KIT_DIR)tests/test_memory.sh"
	@echo ""
	@echo "All tests passed."

eval:
	@bash "$(NANA_KIT_DIR)scripts/eval-runner.sh"

report:
	@python3 "$(NANA_KIT_DIR)scripts/generate-report.py"

workflow:
	@python3 "$(NANA_KIT_DIR)scripts/generate-workflow.py"
