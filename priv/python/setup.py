#!/usr/bin/env python3
"""
Setup script for the web automation component.
This script installs the required dependencies, initializes Playwright, and ensures the Llama server is running.
"""

import os
import subprocess
import sys
import json
from typing import List, Dict, Any, Optional, Tuple

# Add the current directory to the Python path
script_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, script_dir)

# Try to import the llama_server module
try:
    from llama_server import ensure_server_running, DEFAULT_MODEL, DEFAULT_HOST, DEFAULT_PORT
except ImportError:
    print("Warning: Could not import llama_server module. Llama.cpp server management will not be available.")
    # Define the defaults here as fallbacks
    DEFAULT_MODEL = "qwen2.5-7b-instruct.Q4_K_M.gguf"
    DEFAULT_HOST = "127.0.0.1"
    DEFAULT_PORT = 8090


def run_command(command: List[str], env: Optional[Dict[str, Any]] = None) -> int:
    """Run a command and return its exit code.
    
    Args:
        command: Command as a list of strings
        env: Environment variables to pass to the command
        
    Returns:
        int: Exit code of the command
    """
    process_env = os.environ.copy()
    if env:
        process_env.update(env)
        
    print(f"Running command: {' '.join(command)}")
    process = subprocess.run(command, env=process_env)
    return process.returncode


def setup_python_env() -> bool:
    """Set up the Python environment.
    
    Returns:
        bool: Whether the setup was successful
    """
    # Get the current directory
    current_dir = os.path.dirname(os.path.abspath(__file__))
    requirements_path = os.path.join(current_dir, "requirements.txt")
    
    try:
        # Install dependencies
        print("Installing Python dependencies...")
        exit_code = run_command([sys.executable, "-m", "pip", "install", "-r", requirements_path])
        if exit_code != 0:
            print(f"Error installing dependencies: exit code {exit_code}")
            return False
            
        # Install Playwright browsers
        print("Installing Playwright browsers...")
        exit_code = run_command([sys.executable, "-m", "playwright", "install", "chromium"])
        if exit_code != 0:
            print(f"Error installing Playwright browsers: exit code {exit_code}")
            return False
            
        # Create the sessions directory
        sessions_dir = os.path.join(current_dir, "sessions")
        os.makedirs(sessions_dir, exist_ok=True)
        
        print("Python environment setup complete!")
        return True
        
    except Exception as e:
        print(f"Error setting up Python environment: {str(e)}")
        return False


def ensure_llama_server() -> bool:
    """Ensure the Llama.cpp server is running.
    
    Returns:
        bool: Whether the server is running
    """
    try:
        # Check if the llama_server module was imported
        if 'ensure_server_running' not in globals():
            print("Warning: Llama.cpp server management not available.")
            return False
            
        print("Checking Llama.cpp server status...")
        
        # Try to import the required modules
        try:
            import requests
        except ImportError:
            print("Warning: requests module not available. Cannot check server status.")
            return False
            
        # Set environment variables for the Llama.cpp server if they exist
        model = os.environ.get("LLAMA_MODEL", DEFAULT_MODEL)
        host = os.environ.get("LLAMA_HOST", DEFAULT_HOST)
        port = int(os.environ.get("LLAMA_PORT", DEFAULT_PORT))
        
        # Ensure the server is running
        result = ensure_server_running(
            model_name=model,
            host=host,
            port=port
        )
        
        print("Llama.cpp server status:")
        print(json.dumps(result, indent=2))
        
        return result.get("running", False)
        
    except Exception as e:
        print(f"Error ensuring Llama.cpp server: {str(e)}")
        return False


def check_and_setup_proxy_lite() -> bool:
    """Check and set up the proxy-lite configuration.
    
    Returns:
        bool: Whether the setup was successful
    """
    try:
        # Check if the proxy_lite module is importable
        try:
            # Try to import ProxyLite3B first - this is what we need from PR #94
            try:
                from proxy_lite import ProxyLite3B
                print("proxy-lite with ProxyLite3B support is available.")
                
                # Check for API key
                api_key = os.environ.get("PROXY_API_KEY")
                if not api_key:
                    print("Warning: PROXY_API_KEY environment variable not set. Some features may not work.")
                    print("To use proxy-lite-3b, please set your API key from getproxy.ai")
                else:
                    print("Proxy API key is set.")
                    
                return True
            except (ImportError, AttributeError):
                # Try regular Ollama interface as fallback
                from proxy_lite import Ollama
                print("proxy-lite with Ollama support is available.")
                
                # Check if Ollama is running (if we're using it)
                ollama_url = os.environ.get("OLLAMA_BASE_URL", "http://localhost:11434")
                try:
                    import requests
                    response = requests.get(f"{ollama_url}/api/version")
                    if response.status_code == 200:
                        print(f"Ollama is available at {ollama_url}")
                    else:
                        print(f"Warning: Ollama may not be running at {ollama_url}")
                except:
                    print(f"Warning: Couldn't connect to Ollama at {ollama_url}")
                    
                return True
                
        except ImportError:
            print("Warning: proxy_lite module not available.")
            print("To use proxy-lite features, please install it from:")
            print("  pip install proxy-lite")
            print("Or if you need the ProxyLite3B features mentioned in PR #94:")
            print("  pip install git+https://github.com/jmanhype/proxy-lite.git")
            return False
            
    except Exception as e:
        print(f"Error checking proxy-lite configuration: {str(e)}")
        return False


def main():
    """Main entry point."""
    success = True
    
    # Setup Python environment
    env_success = setup_python_env()
    success = success and env_success
    
    # Ensure Llama.cpp server is running
    llama_success = ensure_llama_server()
    # Don't fail the setup if Llama server isn't available, just warn
    if not llama_success:
        print("Warning: Llama.cpp server is not running. Some features may not work.")
    
    # Check and setup proxy-lite
    proxy_success = check_and_setup_proxy_lite()
    # Don't fail the setup if proxy-lite isn't available, just warn
    if not proxy_success:
        print("Warning: Proxy-lite configuration check failed. Some features may not work.")
    
    # Make the scripts executable
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        for script in ["web_automation.py", "structured_extraction.py", "extract_example.py", 
                     "llama_server.py", "proxy_lite_example.py"]:
            script_path = os.path.join(script_dir, script)
            if os.path.exists(script_path):
                os.chmod(script_path, 0o755)
                print(f"Made {script} executable.")
    except Exception as e:
        print(f"Warning: Could not make scripts executable: {str(e)}")
    
    if success:
        print("\n✅ Setup completed successfully!")
        print("\nYou can now use the following components:")
        print("- Web automation (web_automation.py)")
        print("- Structured data extraction (structured_extraction.py)")
        print("- Combined extraction example (extract_example.py)")
        print("- Llama.cpp server management (llama_server.py)")
        print("- Proxy-lite-3b integration (proxy_lite_example.py)")
        
        if not proxy_success:
            print("\n⚠️ To use the proxy-lite features:")
            print("1. Install the proxy-lite package:")
            print("  pip install git+https://github.com/jmanhype/proxy-lite.git")
            print("2. Set your API key in the environment:")
            print("  export PROXY_API_KEY=your_api_key_here")
    else:
        print("\n⚠️ Setup completed with warnings or errors.")
        print("Please review the output above for details.")
    
    print("\nTo run the Llama.cpp server manually:")
    print("  python llama_server.py ensure")
    
    print("\nTo run the proxy-lite-3b example:")
    print("  python proxy_lite_example.py \"your search query\" --homepage https://example.com")
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main() 