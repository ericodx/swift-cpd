# swift-cpd Makefile
#
# Local equivalents of the CI test-and-coverage and publish-code-analysis jobs.
# Mirrors `.github/workflows/main-analysis.yml` so local results match CI.

SHELL := /bin/bash

COVERAGE_DIR  := coverage
COVERAGE_LCOV := $(COVERAGE_DIR)/lcov.info
COVERAGE_XML  := $(COVERAGE_DIR)/code-coverage-report.xml

SONAR_HOST_URL ?= https://sonarcloud.io
SONAR_SCRIPT   := Scripts/lcov-to-sonar.awk

.PHONY: help test coverage sonar clean

help:
	@echo "Available targets:"
	@echo "  test       Run unit tests"
	@echo "  coverage   Run tests with coverage and produce $(COVERAGE_XML)"
	@echo "  sonar      Build coverage then upload to SonarCloud"
	@echo "             (requires SONAR_TOKEN env var and sonar-scanner installed)"
	@echo "  clean      Remove .build and coverage artifacts"
	@echo ""
	@echo "Optional environment:"
	@echo "  SONAR_HOST_URL  Override SonarCloud URL (default: $(SONAR_HOST_URL))"

test:
	swift test

coverage: $(COVERAGE_XML)

$(COVERAGE_XML): $(SONAR_SCRIPT)
	@set -e; \
	mkdir -p $(COVERAGE_DIR); \
	swift test --enable-code-coverage --quiet; \
	BIN_PATH=$$(swift build --show-bin-path); \
	TEST_BINARY=$$(find "$$BIN_PATH" -type f \
	    -path "*Tests.xctest/Contents/MacOS/*" \
	    ! -path "*.dSYM/*" \
	    | head -n 1); \
	if [ -z "$$TEST_BINARY" ]; then \
	    echo "Error: test binary not found under $$BIN_PATH"; \
	    exit 1; \
	fi; \
	PROFDATA="$$BIN_PATH/codecov/default.profdata"; \
	if [ ! -f "$$PROFDATA" ]; then \
	    echo "Error: profdata not found at $$PROFDATA"; \
	    exit 1; \
	fi; \
	xcrun llvm-cov export \
	    "$$TEST_BINARY" \
	    -instr-profile "$$PROFDATA" \
	    --sources "$$(pwd)/Sources" \
	    --format=lcov \
	    | sed "s|$$(pwd)/||g" \
	    > $(COVERAGE_LCOV); \
	awk -f $(SONAR_SCRIPT) $(COVERAGE_LCOV) > $(COVERAGE_XML); \
	echo "Coverage report written to $(COVERAGE_XML)"

sonar: coverage
	@if [ -z "$$SONAR_TOKEN" ]; then \
	    echo "Error: SONAR_TOKEN is required (export SONAR_TOKEN=...)"; \
	    exit 1; \
	fi
	@command -v sonar-scanner >/dev/null 2>&1 || { \
	    echo "Error: sonar-scanner not found in PATH"; \
	    echo "Install with: brew install sonar-scanner"; \
	    exit 1; \
	}
	@VERSION=$$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0"); \
	echo "Publishing to $(SONAR_HOST_URL) as version $$VERSION"; \
	sonar-scanner \
	    -Dsonar.projectVersion=$$VERSION \
	    -Dsonar.host.url=$(SONAR_HOST_URL) \
	    -Dsonar.token=$$SONAR_TOKEN

clean:
	rm -rf .build $(COVERAGE_DIR)
