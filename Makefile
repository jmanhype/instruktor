# Instruktor Makefile
# A comprehensive build system for the Instruktor project

# Define the shell to use
SHELL := /bin/bash

# Define paths
PROJ_ROOT := $(shell pwd)
SCRIPTS_DIR := $(PROJ_ROOT)/scripts
PYTHON_DIR := $(PROJ_ROOT)/priv/python

# Define CLI commands
INSTRUKTOR := $(PROJ_ROOT)/instruktor

# Define Docker variables
DOCKER_IMAGE := instruktor
DOCKER_TAG := latest
DOCKER_CONTAINER := instruktor
DOCKER_MODELS_DIR := $(PROJ_ROOT)/models
DOCKER_OUTPUT_DIR := $(PROJ_ROOT)/output

# Define colors for output
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m  # No Color

# Default target
.PHONY: help
help:
	@echo -e "$(BLUE)Instruktor Makefile$(NC)"
	@echo -e "Available targets:"
	@echo -e "  $(GREEN)setup$(NC)       - Install all dependencies"
	@echo -e "  $(GREEN)start$(NC)       - Start the Instruktor application with IEx shell"
	@echo -e "  $(GREEN)server$(NC)      - Start the llama.cpp server"
	@echo -e "  $(GREEN)proxy$(NC)       - Start only the proxy server"
	@echo -e "  $(GREEN)test$(NC)        - Run the test suite"
	@echo -e "  $(GREEN)search$(NC)      - Run a web search query"
	@echo -e "  $(GREEN)screenshot$(NC)  - Take a screenshot of a website"
	@echo -e "  $(GREEN)extract$(NC)     - Extract structured data from a website"
	@echo -e "  $(GREEN)status$(NC)      - Check status of llama and proxy servers"
	@echo -e "  $(GREEN)install$(NC)     - Install the CLI globally"
	@echo -e "  $(GREEN)uninstall$(NC)   - Uninstall the CLI"
	@echo -e "  $(GREEN)clean$(NC)       - Clean up temporary files"
	@echo -e "  $(GREEN)build$(NC)       - Build the Elixir application"
	@echo -e ""
	@echo -e "Docker commands:"
	@echo -e "  $(GREEN)docker-build$(NC)    - Build the Docker image"
	@echo -e "  $(GREEN)docker-run$(NC)      - Run the Docker container"
	@echo -e "  $(GREEN)docker-up$(NC)       - Start with docker-compose"
	@echo -e "  $(GREEN)docker-down$(NC)     - Stop with docker-compose"
	@echo -e "  $(GREEN)docker-clean$(NC)    - Remove Docker container and image"
	@echo -e "  $(GREEN)docker-search$(NC)   - Run search in Docker container"
	@echo -e "  $(GREEN)docker-screenshot$(NC) - Take screenshot in Docker container"
	@echo -e "  $(GREEN)docker-extract$(NC)  - Extract data in Docker container"
	@echo -e ""
	@echo -e "Examples:"
	@echo -e "  make setup"
	@echo -e "  make search QUERY=\"capital of Japan\""
	@echo -e "  make screenshot URL=\"https://example.com\" OUTPUT=\"screenshot.png\""
	@echo -e "  make docker-build"
	@echo -e "  make docker-search QUERY=\"population of France\""

# Setup target
.PHONY: setup
setup:
	@echo -e "$(BLUE)Setting up Instruktor dependencies...$(NC)"
	@$(INSTRUKTOR) setup

# Build target
.PHONY: build
build:
	@echo -e "$(BLUE)Building Elixir application...$(NC)"
	@cd $(PROJ_ROOT) && mix compile

# Start target
.PHONY: start
start:
	@echo -e "$(BLUE)Starting Instruktor application...$(NC)"
	@$(INSTRUKTOR) start

# Server target
.PHONY: server
server:
	@echo -e "$(BLUE)Starting llama.cpp server...$(NC)"
	@$(INSTRUKTOR) server $(MODEL)

# Proxy target
.PHONY: proxy
proxy:
	@echo -e "$(BLUE)Starting proxy server...$(NC)"
	@$(INSTRUKTOR) proxy

# Test target
.PHONY: test
test:
	@echo -e "$(BLUE)Running tests...$(NC)"
	@$(INSTRUKTOR) test

# Search target
.PHONY: search
search:
	@if [ -z "$(QUERY)" ]; then \
		echo -e "$(RED)Error: No query specified$(NC)"; \
		echo -e "Usage: make search QUERY=\"your query\" [HOMEPAGE=\"https://example.com\"]"; \
		exit 1; \
	fi
	@if [ -n "$(HOMEPAGE)" ]; then \
		echo -e "$(BLUE)Running search query with custom homepage...$(NC)"; \
		$(INSTRUKTOR) search "$(QUERY)" --homepage "$(HOMEPAGE)"; \
	else \
		echo -e "$(BLUE)Running search query...$(NC)"; \
		$(INSTRUKTOR) search "$(QUERY)"; \
	fi

# Screenshot target
.PHONY: screenshot
screenshot:
	@if [ -z "$(URL)" ]; then \
		echo -e "$(RED)Error: No URL specified$(NC)"; \
		echo -e "Usage: make screenshot URL=\"https://example.com\" [OUTPUT=\"screenshot.png\"] [FULLPAGE=true] [WIDTH=1920] [HEIGHT=1080]"; \
		exit 1; \
	fi
	
	@CMD="$(INSTRUKTOR) screenshot \"$(URL)\""; \
	if [ -n "$(OUTPUT)" ]; then \
		CMD="$$CMD --output \"$(OUTPUT)\""; \
	fi; \
	if [ "$(FULLPAGE)" = "true" ]; then \
		CMD="$$CMD --fullpage"; \
	fi; \
	if [ -n "$(WIDTH)" ]; then \
		CMD="$$CMD --width $(WIDTH)"; \
	fi; \
	if [ -n "$(HEIGHT)" ]; then \
		CMD="$$CMD --height $(HEIGHT)"; \
	fi; \
	echo -e "$(BLUE)Taking screenshot...$(NC)"; \
	eval $$CMD

# Extract target
.PHONY: extract
extract:
	@if [ -z "$(URL)" ]; then \
		echo -e "$(RED)Error: No URL specified$(NC)"; \
		echo -e "Usage: make extract URL=\"https://example.com\" [SCHEMA=Article] [OUTPUT=\"result.json\"]"; \
		exit 1; \
	fi
	
	@CMD="$(INSTRUKTOR) extract \"$(URL)\""; \
	if [ -n "$(SCHEMA)" ]; then \
		CMD="$$CMD --schema \"$(SCHEMA)\""; \
	fi; \
	if [ -n "$(OUTPUT)" ]; then \
		CMD="$$CMD --output \"$(OUTPUT)\""; \
	fi; \
	echo -e "$(BLUE)Extracting data...$(NC)"; \
	eval $$CMD

# Status target
.PHONY: status
status:
	@echo -e "$(BLUE)Checking server status...$(NC)"
	@$(INSTRUKTOR) status

# Install target
.PHONY: install
install:
	@echo -e "$(BLUE)Installing Instruktor CLI...$(NC)"
	@$(PROJ_ROOT)/install.sh

# Uninstall target
.PHONY: uninstall
uninstall:
	@echo -e "$(BLUE)Uninstalling Instruktor CLI...$(NC)"
	@$(PROJ_ROOT)/install.sh --uninstall

# Clean target
.PHONY: clean
clean:
	@echo -e "$(BLUE)Cleaning up temporary files...$(NC)"
	@rm -f tmp_*.exs
	@rm -f screenshot_*.png
	@echo -e "$(GREEN)Clean up complete.$(NC)"

# Version target
.PHONY: version
version:
	@$(INSTRUKTOR) version

# Completion target
.PHONY: completion
completion:
	@if [ -z "$(SHELL_TYPE)" ]; then \
		echo -e "$(RED)Error: No shell type specified$(NC)"; \
		echo -e "Usage: make completion SHELL_TYPE=[bash|zsh|fish]"; \
		exit 1; \
	fi
	@$(INSTRUKTOR) completion $(SHELL_TYPE)

# Docker build target
.PHONY: docker-build
docker-build:
	@echo -e "$(BLUE)Building Docker image...$(NC)"
	@docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	@echo -e "$(GREEN)Docker image $(DOCKER_IMAGE):$(DOCKER_TAG) built successfully$(NC)"

# Docker run target
.PHONY: docker-run
docker-run:
	@echo -e "$(BLUE)Running Docker container...$(NC)"
	@mkdir -p $(DOCKER_MODELS_DIR) $(DOCKER_OUTPUT_DIR)
	@docker run -it --rm \
		--name $(DOCKER_CONTAINER) \
		-v $(DOCKER_MODELS_DIR):/app/models \
		-v $(DOCKER_OUTPUT_DIR):/app/output \
		-p 8090:8090 -p 8765:8765 -p 4000:4000 \
		-e LLAMA_MODELS_DIR=/app/models \
		$(DOCKER_IMAGE):$(DOCKER_TAG) $(CMD)

# Docker compose up target
.PHONY: docker-up
docker-up:
	@echo -e "$(BLUE)Starting services with docker-compose...$(NC)"
	@mkdir -p $(DOCKER_MODELS_DIR) $(DOCKER_OUTPUT_DIR)
	@LLAMA_MODELS_DIR=$(DOCKER_MODELS_DIR) OUTPUT_DIR=$(DOCKER_OUTPUT_DIR) docker-compose up -d
	@echo -e "$(GREEN)Services started successfully$(NC)"

# Docker compose down target
.PHONY: docker-down
docker-down:
	@echo -e "$(BLUE)Stopping services...$(NC)"
	@docker-compose down
	@echo -e "$(GREEN)Services stopped successfully$(NC)"

# Docker clean target
.PHONY: docker-clean
docker-clean:
	@echo -e "$(BLUE)Cleaning Docker resources...$(NC)"
	@docker-compose down -v
	@docker rm -f $(DOCKER_CONTAINER) 2>/dev/null || true
	@docker rmi $(DOCKER_IMAGE):$(DOCKER_TAG) 2>/dev/null || true
	@echo -e "$(GREEN)Docker resources cleaned successfully$(NC)"

# Docker search target
.PHONY: docker-search
docker-search:
	@if [ -z "$(QUERY)" ]; then \
		echo -e "$(RED)Error: No query specified$(NC)"; \
		echo -e "Usage: make docker-search QUERY=\"your query\" [HOMEPAGE=\"https://example.com\"]"; \
		exit 1; \
	fi
	
	@CMD="search \"$(QUERY)\""; \
	if [ -n "$(HOMEPAGE)" ]; then \
		CMD="$$CMD --homepage \"$(HOMEPAGE)\""; \
	fi; \
	echo -e "$(BLUE)Running search query in Docker...$(NC)"; \
	make docker-run CMD="$$CMD"

# Docker screenshot target
.PHONY: docker-screenshot
docker-screenshot:
	@if [ -z "$(URL)" ]; then \
		echo -e "$(RED)Error: No URL specified$(NC)"; \
		echo -e "Usage: make docker-screenshot URL=\"https://example.com\" [OUTPUT=\"screenshot.png\"] [FULLPAGE=true] [WIDTH=1920] [HEIGHT=1080]"; \
		exit 1; \
	fi
	
	@CMD="screenshot \"$(URL)\""; \
	if [ -n "$(OUTPUT)" ]; then \
		CMD="$$CMD --output \"/app/output/$(OUTPUT)\""; \
	else \
		CMD="$$CMD --output \"/app/output/screenshot_$$(date +%s).png\""; \
	fi; \
	if [ "$(FULLPAGE)" = "true" ]; then \
		CMD="$$CMD --fullpage"; \
	fi; \
	if [ -n "$(WIDTH)" ]; then \
		CMD="$$CMD --width $(WIDTH)"; \
	fi; \
	if [ -n "$(HEIGHT)" ]; then \
		CMD="$$CMD --height $(HEIGHT)"; \
	fi; \
	echo -e "$(BLUE)Taking screenshot in Docker...$(NC)"; \
	make docker-run CMD="$$CMD"
	@echo -e "$(GREEN)Screenshot saved to output directory$(NC)"

# Docker extract target
.PHONY: docker-extract
docker-extract:
	@if [ -z "$(URL)" ]; then \
		echo -e "$(RED)Error: No URL specified$(NC)"; \
		echo -e "Usage: make docker-extract URL=\"https://example.com\" [SCHEMA=Article] [OUTPUT=\"result.json\"]"; \
		exit 1; \
	fi
	
	@CMD="extract \"$(URL)\""; \
	if [ -n "$(SCHEMA)" ]; then \
		CMD="$$CMD --schema \"$(SCHEMA)\""; \
	fi; \
	if [ -n "$(OUTPUT)" ]; then \
		CMD="$$CMD --output \"/app/output/$(OUTPUT)\""; \
	else \
		CMD="$$CMD --output \"/app/output/extract_$$(date +%s).json\""; \
	fi; \
	echo -e "$(BLUE)Extracting data in Docker...$(NC)"; \
	make docker-run CMD="$$CMD"
	@echo -e "$(GREEN)Extracted data saved to output directory$(NC)"

# Define file targets
$(INSTRUKTOR):
	@echo -e "$(RED)Error: Instruktor CLI not found at $(INSTRUKTOR)$(NC)"
	@echo -e "Make sure you are in the root directory of the Instruktor project"
	@exit 1

# Variable check helper functions
check_var = $(if $($(1)),,$(error $(2))) 