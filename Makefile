# Nana Dev Kit — project-level targets
# These targets operate on the CWD (the project using the kit).

NANA_KIT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: sync-rules test eval report workflow template

sync-rules:
	@bash "$(NANA_KIT_DIR)scripts/sync-rules.sh" . .

template:
	@python3 "$(NANA_KIT_DIR)scripts/register-settings.py" hooks "$(NANA_KIT_DIR)templates/.claude/settings.json" "$(NANA_KIT_DIR)modules.json" --scope project-local --hooks-dir .claude/hooks --regenerate
	@echo "Regenerated templates/.claude/settings.json from modules.json"

test:
	@echo "Running tests..."
	@bash "$(NANA_KIT_DIR)tests/test_install.sh"
	@bash "$(NANA_KIT_DIR)tests/test_sync_rules.sh"
	@bash "$(NANA_KIT_DIR)tests/test_templates.sh"
	@bash "$(NANA_KIT_DIR)tests/test_enforce.sh"
	@bash "$(NANA_KIT_DIR)tests/test_firing_log.sh"
	@bash "$(NANA_KIT_DIR)tests/test_harden.sh"
	@bash "$(NANA_KIT_DIR)tests/test_memory.sh"
	@bash "$(NANA_KIT_DIR)tests/test_companions.sh"
	@bash "$(NANA_KIT_DIR)tests/test_registration.sh"
	@bash "$(NANA_KIT_DIR)tests/test_settings_template.sh"
	@bash "$(NANA_KIT_DIR)tests/test_cognitive_readiness.sh"
	@bash "$(NANA_KIT_DIR)tests/test_step_numbering.sh"
	@bash "$(NANA_KIT_DIR)tests/test_working_knowledge_curation.sh"
	@echo ""
	@echo "All tests passed."

eval:
	@bash "$(NANA_KIT_DIR)scripts/eval-runner.sh"

report:
	@python3 "$(NANA_KIT_DIR)scripts/generate-report.py"

workflow:
	@python3 "$(NANA_KIT_DIR)scripts/generate-workflow.py"
