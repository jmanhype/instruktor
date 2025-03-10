# Instruktor

Instruktor is a powerful web automation and structured data extraction platform that combines the strengths of Elixir and Python to provide a robust system for browser automation, data processing, and LLM-powered extraction.

## Overview

This project provides a unified system for:

- Web automation using Playwright
- Structured data extraction using LLMs
- Integration with local LLM models via Llama.cpp
- Background job processing with Oban
- A clean Elixir interface to Python functionality

## Architecture

The architecture consists of two main components:

1. **Elixir Core** - Provides the API, job scheduling, data validation, and coordination
2. **Python Workers** - Handle browser automation, LLM interaction, and data extraction

```
┌────────────────────────┐         ┌────────────────────────┐
│                        │         │                        │
│    Elixir Core         │         │    Python Workers      │
│                        │         │                        │
│  ┌─────────────────┐   │         │  ┌─────────────────┐   │
│  │                 │   │         │  │                 │   │
│  │   API Layer     │   │         │  │  Web Automation │   │
│  │                 │   │         │  │                 │   │
│  └────────┬────────┘   │         │  └────────┬────────┘   │
│           │            │         │           │            │
│  ┌────────▼────────┐   │         │  ┌────────▼────────┐   │
│  │                 │   │         │  │                 │   │
│  │   Job Queue     │ ──┼─────────┼─▶│  LLM Interface  │   │
│  │                 │   │         │  │                 │   │
│  └────────┬────────┘   │         │  └────────┬────────┘   │
│           │            │         │           │            │
│  ┌────────▼────────┐   │         │  ┌────────▼────────┐   │
│  │                 │   │         │  │                 │   │
│  │ Data Validation │   │         │  │ Data Extraction │   │
│  │                 │   │         │  │                 │   │
│  └─────────────────┘   │         │  └─────────────────┘   │
│                        │         │                        │
└────────────────────────┘         └────────────────────────┘
```

## Installation

### Prerequisites

- Elixir 1.14+
- Python 3.8+
- [Llama.cpp](https://github.com/ggerganov/llama.cpp) (optional)
- LLM models (either local or via API)

### Setup

1. Clone the repository

```bash
git clone https://github.com/yourusername/instruktor.git
cd instruktor
```

2. Install Elixir dependencies

```bash
mix deps.get
```

3. Set up the Python environment

```bash
cd priv/python
./setup.sh
```

4. Configure your environment (see Configuration section)

5. Start the application

```bash
mix run --no-halt
```

## Configuration

Configuration is managed through environment variables and application config:

### Elixir Config

Configure your application in `config/config.exs` or use environment-specific configs.

### Python Config

Python configuration uses environment variables:

- `LLAMA_CPP_DIR` - Path to the Llama.cpp installation
- `LLAMA_MODELS_DIR` - Path to the directory containing LLM models
- `LLAMA_DEFAULT_MODEL` - Default model to use
- `LLAMA_HOST` - Host for the Llama.cpp server
- `LLAMA_PORT` - Port for the Llama.cpp server

## Features

### Web Automation

- Browser session management
- Navigation and interaction
- Screenshot capture
- Content extraction
- Headless or visible mode

### Structured Data Extraction

- Extract structured data using LLMs
- Define custom Pydantic models for extraction
- Support for multiple LLM providers

### LLM Integration

- Support for local Llama.cpp models
- Configurable model parameters
- Extensible for other LLM providers

## Components

### Elixir Components

- `Instruktor.WebAutomation` - Interface to the Python web automation functionality
- `Instruktor.LLM` - Interface to the LLM capabilities
- `Instruktor.Schemas` - Data structures and validations
- `Instruktor.Workers` - Background job processing

### Python Components

- `web_automation.py` - Browser automation using Playwright
- `structured_extraction.py` - Structured data extraction using LLMs
- `llama_server.py` - Llama.cpp server management

## Documentation

Additional documentation:

- [Python Components](priv/python/README.md)
- [API Documentation](docs/api.md)
- [Configuration Guide](docs/configuration.md)

## Development

### Running Tests

```bash
mix test
```

### Adding New Extractors

Define your extraction schemas in `lib/instruktor/schemas/` and implement any necessary extraction logic in the Python components.

## License

[Include license information here] 