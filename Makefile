# Local verification loop for the CARTO Self-Hosted Helm chart.
#
#   make check    runs the same checks CI runs (lint, render matrix, schema,
#                 duplicate keys, unit tests, README drift, KOTS manifest checks)
#   make help     lists every target
#
# Rendered output lands in .render/ (git-ignored).

.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash
# Multi-command recipes start with `set -euo pipefail` instead of relying on
# .SHELLFLAGS, which GNU Make 3.81 (the macOS default) silently ignores.

CHART        := chart
RELEASE      := carto
RENDER_DIR   := .render
KUBE_VERSION ?= 1.31.0

# Pinned so local runs and CI produce byte-identical README output.
README_GENERATOR := npx -y @bitnami/readme-generator-for-helm@2.7.2

# One values file per install scenario; every file is rendered and checked.
SCENARIOS := $(sort $(wildcard $(CHART)/ci/*-values.yaml))

REQUIRED_TOOLS := helm yq kubeconform yamllint npx
HELM_UNITTEST_VERSION := 1.0.3

.PHONY: help tools deps lint template render-checks unittest readme readme-check kots secrets check clean

help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

tools: ## Verify the required CLI tools are installed
	@set -euo pipefail; missing=""; \
	for t in $(REQUIRED_TOOLS); do command -v "$$t" >/dev/null 2>&1 || missing="$$missing $$t"; done; \
	if [ -n "$$missing" ]; then \
	  echo "missing tools:$$missing"; \
	  echo "  macOS: brew install helm yq kubeconform yamllint node"; \
	  exit 1; \
	fi; \
	if ! helm plugin list 2>/dev/null | grep -q '^unittest'; then \
	  echo "missing helm plugin: unittest"; \
	  echo "  helm plugin install https://github.com/helm-unittest/helm-unittest.git --version $(HELM_UNITTEST_VERSION)"; \
	  exit 1; \
	fi

deps: ## Fetch chart dependencies (subcharts) into chart/charts
	@helm repo list 2>/dev/null | grep -q '^bitnami' || helm repo add bitnami https://charts.bitnami.com/bitnami
	helm dependency build $(CHART)
	@touch $(CHART)/charts

# Rebuild subcharts only when Chart.lock is newer than chart/charts (or missing).
$(CHART)/charts: $(CHART)/Chart.lock
	@$(MAKE) --no-print-directory deps

$(RENDER_DIR):
	@mkdir -p $@

lint: $(CHART)/charts ## helm lint with default values and with replicated.enabled=true
	helm lint $(CHART)
	helm lint $(CHART) --set replicated.enabled=true

template: $(CHART)/charts | $(RENDER_DIR) ## Render every chart/ci/*-values.yaml scenario into .render/
	@set -euo pipefail; for f in $(SCENARIOS); do \
	  name=$$(basename "$$f" -values.yaml); \
	  echo "render  $$name"; \
	  helm template $(RELEASE) $(CHART) -f "$$f" > "$(RENDER_DIR)/$$name.yaml"; \
	done

render-checks: template ## Duplicate-key (yamllint) and schema (kubeconform) checks on every rendered scenario
	@set -euo pipefail; for f in $(SCENARIOS); do \
	  name=$$(basename "$$f" -values.yaml); \
	  echo "check   $$name"; \
	  yamllint -d '{rules: {key-duplicates: enable}}' "$(RENDER_DIR)/$$name.yaml"; \
	  kubeconform -strict -ignore-missing-schemas -kubernetes-version $(KUBE_VERSION) -summary "$(RENDER_DIR)/$$name.yaml"; \
	done

unittest: $(CHART)/charts ## Run the helm-unittest suites in chart/tests
	helm unittest $(CHART) --with-subchart=false

readme: ## Regenerate chart/README.md from the @param comments in chart/values.yaml
	cd $(CHART) && $(README_GENERATOR) --readme README.md --values values.yaml

readme-check: | $(RENDER_DIR) ## Fail if chart/README.md is out of sync with chart/values.yaml
	@mkdir -p $(RENDER_DIR)/readme-check
	@cp $(CHART)/README.md $(CHART)/values.yaml $(RENDER_DIR)/readme-check/
	@cd $(RENDER_DIR)/readme-check && $(README_GENERATOR) --readme README.md --values values.yaml >/dev/null
	@diff -u $(CHART)/README.md $(RENDER_DIR)/readme-check/README.md \
	  || { echo; echo "chart/README.md is out of date: run 'make readme' and commit the result."; exit 1; }
	@echo "readme  in sync"

kots: ## Static checks for the KOTS manifests (scripts/test-kots-config.sh)
	scripts/test-kots-config.sh all

secrets: ## Scan the working tree for secrets with gitleaks (same config as CI and pre-commit)
	gitleaks detect --source . --no-banner --redact

check: tools lint render-checks unittest readme-check kots ## Run everything CI runs
	@echo; echo "all checks passed"

clean: ## Remove rendered output
	$(RM) -r $(RENDER_DIR)
