# Nana Dev Kit — project-level targets
# These targets operate on the CWD (the project using the kit).

NANA_KIT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: sync-rules

sync-rules:
	@bash "$(NANA_KIT_DIR)scripts/sync-rules.sh" . .
