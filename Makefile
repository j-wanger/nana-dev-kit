# Nana Dev Kit — project-level targets
# These targets operate on the CWD (the project using the kit).

NANA_KIT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: sync-rules test

sync-rules:
	@bash "$(NANA_KIT_DIR)scripts/sync-rules.sh" . .

test:
	@echo "Running tests..."
	@bash "$(NANA_KIT_DIR)tests/test_install.sh"
	@bash "$(NANA_KIT_DIR)tests/test_sync_rules.sh"
	@bash "$(NANA_KIT_DIR)tests/test_templates.sh"
	@echo ""
	@echo "All tests passed."
