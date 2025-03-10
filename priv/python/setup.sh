#!/bin/bash

# Setup script for the Python web automation component
# This script installs the required dependencies, initializes Playwright, and ensures the Llama server is running

# Exit on error
set -e

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Please install Python 3 and try again."
    exit 1
fi

# Create a virtual environment if it doesn't exist
VENV_DIR="$SCRIPT_DIR/venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

# Activate the virtual environment
source "$VENV_DIR/bin/activate"

# Install dependencies
echo "Installing Python dependencies..."
pip install -r "$SCRIPT_DIR/requirements.txt"

# Install Playwright browsers
echo "Installing Playwright browsers..."
python -m playwright install chromium

# Create the sessions directory
mkdir -p "$SCRIPT_DIR/sessions"

# Make scripts executable
echo "Making scripts executable..."
find "$SCRIPT_DIR" -name "*.py" -exec chmod +x {} \;

# Check for Llama.cpp server
echo "Checking Llama.cpp server configuration..."

# Set environment variables for Llama.cpp server
if [ -z "$LLAMA_CPP_DIR" ]; then
    echo "LLAMA_CPP_DIR environment variable not set. Using default: ~/llama.cpp"
    export LLAMA_CPP_DIR="$HOME/llama.cpp"
fi

if [ -z "$LLAMA_MODELS_DIR" ]; then
    echo "LLAMA_MODELS_DIR environment variable not set. Using default: ~/llama_models"
    export LLAMA_MODELS_DIR="$HOME/llama_models"
fi

if [ -z "$LLAMA_MODEL" ]; then
    echo "LLAMA_MODEL environment variable not set. Using default: qwen2.5-7b-instruct.Q4_K_M.gguf"
    export LLAMA_MODEL="qwen2.5-7b-instruct.Q4_K_M.gguf"
fi

# Create the models directory if it doesn't exist
mkdir -p "$LLAMA_MODELS_DIR"

# Check if the Llama.cpp server executable exists
if [ -f "$LLAMA_CPP_DIR/server" ]; then
    echo "Found Llama.cpp server executable: $LLAMA_CPP_DIR/server"
elif [ -f "$LLAMA_CPP_DIR/build/bin/server" ]; then
    echo "Found Llama.cpp server executable: $LLAMA_CPP_DIR/build/bin/server"
elif [ -f "$LLAMA_CPP_DIR/build/server" ]; then
    echo "Found Llama.cpp server executable: $LLAMA_CPP_DIR/build/server"
else
    echo "Warning: Could not find Llama.cpp server executable."
    echo "If you want to use the Llama.cpp server, please install it from:"
    echo "https://github.com/ggerganov/llama.cpp"
    echo "Then set the LLAMA_CPP_DIR environment variable to the installation directory."
fi

# Check if the model file exists
if [ -f "$LLAMA_MODELS_DIR/$LLAMA_MODEL" ]; then
    echo "Found model file: $LLAMA_MODELS_DIR/$LLAMA_MODEL"
else
    echo "Warning: Could not find model file: $LLAMA_MODELS_DIR/$LLAMA_MODEL"
    echo "If you want to use the Llama.cpp server, please download the model file and place it in the models directory."
fi

# Ensure Llama.cpp server is running
echo "Ensuring Llama.cpp server is running..."
python "$SCRIPT_DIR/llama_server.py" ensure || true

# Check proxy-lite configuration
echo "Checking proxy-lite configuration..."
if [ -z "$PROXY_API_KEY" ]; then
    echo "Warning: PROXY_API_KEY environment variable not set."
    echo "If you want to use proxy-lite-3b, please set your API key from getproxy.ai"
else
    echo "Proxy API key is set."
fi

# Check Ollama
echo "Checking Ollama..."
OLLAMA_URL=${OLLAMA_BASE_URL:-http://localhost:11434}
if curl -s "$OLLAMA_URL/api/version" > /dev/null; then
    echo "Ollama is available at $OLLAMA_URL"
else
    echo "Warning: Ollama may not be running at $OLLAMA_URL"
    echo "If you want to use Ollama models, please install and start Ollama from:"
    echo "https://ollama.com"
fi

echo "Python environment setup complete!"
echo "To activate the virtual environment manually, run:"
echo "source $VENV_DIR/bin/activate"

echo "Setup complete! The Python web automation components are ready to use."
echo ""
echo "You can now use the following components:"
echo "- Web automation (web_automation.py)"
echo "- Structured data extraction (structured_extraction.py)"
echo "- Combined extraction example (extract_example.py)"
echo "- Llama.cpp server management (llama_server.py)"
echo "- Proxy-lite-3b integration (proxy_lite_example.py)"
echo ""
echo "To run the Llama.cpp server manually:"
echo "  python llama_server.py ensure"
echo ""
echo "To run the proxy-lite-3b example:"
echo "  python proxy_lite_example.py \"your search query\" --homepage https://example.com" 