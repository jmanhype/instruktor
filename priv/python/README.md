# Web Automation and Structured Data Extraction

A Python-based system for web automation, data extraction, and LLM-powered parsing, designed to be called from Elixir applications.

## Overview

This package provides three main components:

1. **Web Automation** - Browser automation using Playwright for navigating websites, taking screenshots, and extracting content
2. **Structured Data Extraction** - Extract structured data from web content using LLMs with Pydantic models
3. **Llama.cpp Server Management** - Utilities for managing a local Llama.cpp server for LLM inference

## Prerequisites

- Python 3.8+
- [Llama.cpp](https://github.com/ggerganov/llama.cpp) (optional, for local LLM inference)
- Access to LLM models (local or API-based)

## Installation

Run the setup script to install all dependencies and initialize the system:

```bash
./setup.sh
```

This will:
- Create a Python virtual environment
- Install required packages from requirements.txt
- Initialize Playwright browsers
- Verify Llama.cpp availability (if configured)

## Configuration

The system can be configured through environment variables:

- `LLAMA_CPP_DIR` - Path to the Llama.cpp installation (default: ~/llama.cpp)
- `LLAMA_MODELS_DIR` - Path to the directory containing LLM models (default: ~/llama_models)
- `LLAMA_DEFAULT_MODEL` - Default model to use (default: qwen2.5-7b-instruct.Q4_K_M.gguf)
- `LLAMA_HOST` - Host for the Llama.cpp server (default: 127.0.0.1)
- `LLAMA_PORT` - Port for the Llama.cpp server (default: 8090)

## Usage Examples

### Web Automation

```python
from web_automation import WebAutomator

# Initialize the automator
automator = WebAutomator(headless=True)

# Navigate to a URL
response = automator.navigate("https://example.com")

# Take a screenshot
automator.screenshot("example.png")

# Extract HTML content
html = automator.get_content()

# Clean up
automator.close()
```

### Structured Data Extraction

```python
from structured_extraction import ExtractorClient, Product
from pydantic import BaseModel, Field

# Define a custom model
class JobPosting(BaseModel):
    title: str
    company: str
    location: str
    salary: str = Field(default="Not specified")
    
# Extract structured data
client = ExtractorClient()
results = client.extract_from_html(html, JobPosting)
```

### Running the Llama Server

```python
from llama_server import ensure_server_running, stop_server

# Start the server with default settings
server_info = ensure_server_running()

# Or with custom settings
server_info = ensure_server_running(
    model="mistral-7b.Q4_K_M.gguf",
    host="127.0.0.1", 
    port=8090,
    context_size=8192
)

# Stop the server when done
stop_server(server_info["pid"])
```

## Component Descriptions

### web_automation.py
Provides web automation capabilities using Playwright, including browser session management, navigation, screenshots, and content extraction.

### structured_extraction.py
Extracts structured data from HTML content using LLMs, with support for custom Pydantic models.

### llama_server.py
Manages a local Llama.cpp server for LLM inference, providing functions to start, stop, and check server status.

### Example Scripts

- **extract_example.py**: Demonstrates combining web automation and structured extraction
- **proxy_lite_example.py**: Shows how to use the proxy-lite library for data extraction

## Troubleshooting

- **Missing dependencies**: Run `./setup.sh` to ensure all dependencies are installed
- **Browser issues**: Run `playwright install` to reinstall browser binaries
- **LLM server errors**: Check the Llama.cpp installation and model paths

## License

[Include license information here] 