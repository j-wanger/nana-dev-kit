# Nana Dev Kit — project-level targets
# These targets operate on the CWD (the project using the kit).

NANA_KIT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: sync-rules test eval report workflow direction dashboard check-fidelity template audit

sync-rules:
	@bash "$(NANA_KIT_DIR)scripts/sync-rules.sh" . .

audit:
	@bash "$(NANA_KIT_DIR)scripts/harness-audit.sh" || true

template:
	@python3 "$(NANA_KIT_DIR)scripts/register-settings.py" hooks "$(NANA_KIT_DIR)templates/.claude/settings.json" "$(NANA_KIT_DIR)modules.json" --scope project-local --regenerate
	@echo "Regenerated templates/.claude/settings.json from modules.json"

test:
	@echo "Running tests..."
	@bash "$(NANA_KIT_DIR)tests/test_install.sh"
	@bash "$(NANA_KIT_DIR)tests/test_sync_rules.sh"
	@bash "$(NANA_KIT_DIR)tests/test_templates.sh"
	@bash "$(NANA_KIT_DIR)tests/test_enforce.sh"
	@bash "$(NANA_KIT_DIR)tests/test_firing_log.sh"
	@bash "$(NANA_KIT_DIR)tests/test_harden.sh"
	@bash "$(NANA_KIT_DIR)tests/test_check_tests_were_run.sh"
	@bash "$(NANA_KIT_DIR)tests/test_memory.sh"
	@bash "$(NANA_KIT_DIR)tests/test_companions.sh"
	@bash "$(NANA_KIT_DIR)tests/test_registration.sh"
	@bash "$(NANA_KIT_DIR)tests/test_settings_template.sh"
	@bash "$(NANA_KIT_DIR)tests/test_cognitive_readiness.sh"
	@bash "$(NANA_KIT_DIR)tests/test_step_numbering.sh"
	@bash "$(NANA_KIT_DIR)tests/test_working_knowledge_curation.sh"
	@bash "$(NANA_KIT_DIR)tests/test_signal_richness_probe.sh"
	@bash "$(NANA_KIT_DIR)tests/test_audit_log.sh"
	@bash "$(NANA_KIT_DIR)tests/test_long_cadence_hooks.sh"
	@bash "$(NANA_KIT_DIR)tests/test_tooluse_hooks.sh"
	@bash "$(NANA_KIT_DIR)tests/test_hook_firing_coverage.sh"
	@bash "$(NANA_KIT_DIR)tests/test_amplifier_emitter.sh"
	@bash "$(NANA_KIT_DIR)tests/test_assumption_ledger.sh"
	@bash "$(NANA_KIT_DIR)tests/test_manifest_freshness.sh"
	@bash "$(NANA_KIT_DIR)tests/test_scripts_smoke.sh"
	@bash "$(NANA_KIT_DIR)tests/test_direction_dashboard.sh"
	@bash "$(NANA_KIT_DIR)tests/test_dashboard.sh"
	@bash "$(NANA_KIT_DIR)tests/test_decision_server.sh"
	@bash "$(NANA_KIT_DIR)tests/test_dashboard_roundtrip.sh"
	@bash "$(NANA_KIT_DIR)tests/test_contract_fidelity.sh"
	@bash "$(NANA_KIT_DIR)tests/test_eval_hermeticity.sh"
	@bash "$(NANA_KIT_DIR)tests/test_fixture_provenance.sh"
	@bash "$(NANA_KIT_DIR)tests/test_lifecycle_hooks_firing.sh"
	@bash "$(NANA_KIT_DIR)tests/test_install_drift_dircurrency.sh"
	@bash "$(NANA_KIT_DIR)tests/test_install_update.sh"
	@echo ""
	@echo "All tests passed."

eval:
	@bash "$(NANA_KIT_DIR)scripts/eval-runner.sh"

report:
	@python3 "$(NANA_KIT_DIR)scripts/generate-report.py"

workflow:
	@python3 "$(NANA_KIT_DIR)scripts/generate-workflow.py"

direction:
	@python3 "$(NANA_KIT_DIR)scripts/generate-direction.py"

dashboard:
	@python3 "$(NANA_KIT_DIR)scripts/generate-dashboard.py"

# Deterministic contract fidelity-check (rung-C pillar-1).
# Usage: make check-fidelity CONTRACT=path/to/contract.json WORKDIR=path/to/worker-output
check-fidelity:
	@python3 "$(NANA_KIT_DIR)scripts/check-fidelity.py" --contract "$(CONTRACT)" --workdir "$(WORKDIR)"
