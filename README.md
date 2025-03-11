# Instruktor

A toolkit for automating web browsing and data extraction with AI assistants.

## Overview

Instruktor combines Elixir and Python to provide a powerful framework for web automation, data extraction, and AI-guided browsing. It integrates with llama.cpp for local LLM inference and uses browser automation to navigate the web.

## Features

- Web automation using Playwright
- Structured data extraction with LLMs
- Proxy-based architecture for clean API
- Local LLM inference with llama.cpp
- Easy-to-use CLI utility

## Quick Start

### Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/instruktor.git
cd instruktor
```

2. Run the installation script:
```bash
./install.sh
```

This will:
- Install the Instruktor CLI to your system (either system-wide or user-level)
- Make it available in your PATH
- Optionally run the setup command to install all required dependencies

To uninstall the CLI:
```bash
./install.sh --uninstall
```

Alternatively, you can manually set up dependencies:
```bash
./instruktor setup
```

This will install all Elixir and Python dependencies, including Playwright.

### Using the CLI

Instruktor comes with a convenient command-line interface:

```bash
# Show help
./instruktor help

# Check status of servers
./instruktor status

# Start the llama.cpp server
./instruktor server

# Start only the proxy server
./instruktor proxy

# Start the full application in IEx
./instruktor start

# Run tests
./instruktor test

# Run a web search query
./instruktor search "capital of Japan"

# Run a search with a specific homepage
./instruktor search "population of Tokyo" --homepage https://www.cia.gov/the-world-factbook/

# Take a screenshot of a website
./instruktor screenshot https://example.com --output example.png

# Extract structured data from a website
./instruktor extract https://example.com --schema Article --output result.json

# Show version information
./instruktor version

# Generate shell completion
./instruktor completion bash  # or zsh, fish
```

### Using the Makefile

For those who prefer using `make` commands, Instruktor also provides a comprehensive Makefile:

```bash
# Show available targets
make help

# Install all dependencies
make setup

# Start the application
make start

# Run a web search query
make search QUERY="capital of Japan"

# Run a search with a specific homepage
make search QUERY="population of Tokyo" HOMEPAGE="https://www.cia.gov/the-world-factbook/"

# Take a screenshot of a website
make screenshot URL="https://example.com" OUTPUT="example.png"

# Take a full-page screenshot with custom dimensions
make screenshot URL="https://example.com" FULLPAGE=true WIDTH=1920 HEIGHT=1080

# Extract structured data from a website
make extract URL="https://example.com" SCHEMA=Article OUTPUT="result.json"

# Check server status
make status

# Build the Elixir application
make build

# Install the CLI globally
make install

# Clean up temporary files
make clean
```

The Makefile provides a consistent interface across different environments and simplifies common development tasks.

### Docker Integration

Instruktor can also be run in containers using Docker, which simplifies deployment and ensures consistent environments:

#### Using Docker Directly

```bash
# Build the Docker image
make docker-build

# Run a search query in Docker
make docker-search QUERY="capital of Japan"

# Take a screenshot in Docker
make docker-screenshot URL="https://example.com" OUTPUT="screenshot.png"

# Extract data in Docker
make docker-extract URL="https://example.com" SCHEMA=Article OUTPUT="result.json"
```

#### Using Docker Compose

```bash
# Start all services with docker-compose
make docker-up

# Stop all services
make docker-down

# Clean up Docker resources
make docker-clean
```

#### Docker Configuration

The Docker setup includes:

- Elixir and Python environments with all dependencies
- Playwright with Chromium browser
- Volume mounts for models and output files
- Port mappings for all services (8090, 8765, 4000)
- Health checks to ensure services are running properly

You can customize the Docker environment by modifying:

- `Dockerfile` - Container build instructions
- `docker-compose.yml` - Service configuration
- Environment variables:
  - `LLAMA_MODELS_DIR` - Directory for LLM models
  - `LLAMA_DEFAULT_MODEL` - Default model name
  - `OUTPUT_DIR` - Directory for output files

### Running the Server Manually

If you prefer to run components individually:

Start the llama.cpp server:
```bash
./scripts/start_llama_server.sh
```

Start the Elixir application:
```bash
iex -S mix
```

### Running Tests

We provide a simple test script that verifies the entire system works correctly:

```bash
./scripts/run_test.sh
```

This will:
1. Start the llama.cpp server (if not already running)
2. Start the proxy server
3. Run test queries to verify everything works

See `scripts/README.md` for detailed information about all available scripts.

## Usage Examples in Elixir

```elixir
# Search for information
Instruktor.WebAutomation.search("capital of Japan")

# Run the proxy lite with options
Instruktor.WebAutomation.run_proxy_lite("population of France", %{headless: true})
```

## Project Structure

- `lib/` - Elixir code
  - `lib/instruktor/web_automation.ex` - Web automation interface
  - `lib/instruktor/services/` - Server management
- `priv/python/` - Python code
  - `proxy_lite_example.py` - Main proxy implementation
- `scripts/` - Helper scripts for running and testing
- `instruktor` - CLI utility for easy interaction with the application

## Development

See the [contributing guide](CONTRIBUTING.md) for details on how to contribute to Instruktor.

## License

This project is licensed under the [MIT License](LICENSE). 