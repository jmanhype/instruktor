#!/usr/bin/env python3
"""
Llama.cpp server management script.
This script provides functionality to start, stop, and check the status of the Llama.cpp server.
"""

import argparse
import json
import os
import signal
import socket
import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Union, Any, Tuple

# Default settings
DEFAULT_MODEL = "qwen2.5-7b-instruct.Q4_K_M.gguf"
DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 8090
DEFAULT_CONTEXT_SIZE = 4096
DEFAULT_THREADS = 0  # 0 means auto-detect (use all available cores)

# Paths - these will need to be configured for your specific setup
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LLAMA_DIR = os.environ.get("LLAMA_CPP_DIR", os.path.expanduser("~/llama.cpp"))
MODELS_DIR = os.environ.get("LLAMA_MODELS_DIR", os.path.join(os.path.expanduser("~"), "llama_models"))


def is_port_in_use(host: str = DEFAULT_HOST, port: int = DEFAULT_PORT) -> bool:
    """Check if a port is in use.
    
    Args:
        host: Host address to check
        port: Port number to check
        
    Returns:
        bool: Whether the port is in use
    """
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex((host, port)) == 0


def find_llama_server_executable() -> Optional[str]:
    """Find the Llama.cpp server executable.
    
    Returns:
        Optional[str]: Path to the server executable, or None if not found
    """
    # Check common locations
    potential_paths = [
        os.path.join(LLAMA_DIR, "server"),
        os.path.join(LLAMA_DIR, "build", "bin", "server"),
        os.path.join(LLAMA_DIR, "build", "server"),
        # Add more potential paths if needed
    ]
    
    for path in potential_paths:
        if os.path.exists(path) and os.access(path, os.X_OK):
            return path
    
    return None


def find_model_path(model_name: str) -> Optional[str]:
    """Find the path to a model file.
    
    Args:
        model_name: Name of the model file
        
    Returns:
        Optional[str]: Path to the model file, or None if not found
    """
    # Check if model_name is already a full path
    if os.path.exists(model_name):
        return model_name
    
    # Check in the models directory
    model_path = os.path.join(MODELS_DIR, model_name)
    if os.path.exists(model_path):
        return model_path
    
    # Check for partial matches
    for root, _, files in os.walk(MODELS_DIR):
        for file in files:
            if model_name in file and file.endswith((".gguf", ".bin")):
                return os.path.join(root, file)
    
    return None


def start_server(model_name: str = DEFAULT_MODEL, 
                 host: str = DEFAULT_HOST,
                 port: int = DEFAULT_PORT,
                 n_ctx: int = DEFAULT_CONTEXT_SIZE,
                 n_threads: int = DEFAULT_THREADS) -> Tuple[Optional[subprocess.Popen], Optional[str]]:
    """Start the Llama.cpp server.
    
    Args:
        model_name: Name of the model file
        host: Host address to bind to
        port: Port number to bind to
        n_ctx: Context size
        n_threads: Number of threads to use
        
    Returns:
        Tuple[Optional[subprocess.Popen], Optional[str]]: Process object and error message if any
    """
    if is_port_in_use(host, port):
        return None, f"Port {port} is already in use. The server may already be running."
    
    server_executable = find_llama_server_executable()
    if not server_executable:
        return None, "Could not find the Llama.cpp server executable."
    
    model_path = find_model_path(model_name)
    if not model_path:
        return None, f"Could not find the model file: {model_name}"
    
    cmd = [
        server_executable,
        "--model", model_path,
        "--host", host,
        "--port", str(port),
        "--ctx-size", str(n_ctx)
    ]
    
    if n_threads > 0:
        cmd.extend(["--threads", str(n_threads)])
    
    try:
        # Start the server as a background process
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
            universal_newlines=True
        )
        
        # Give the server some time to start
        time.sleep(2)
        
        # Check if the process is still running
        if process.poll() is not None:
            # Process has terminated
            stderr = process.stderr.read() if process.stderr else ""
            return None, f"Server failed to start: {stderr}"
        
        return process, None
        
    except Exception as e:
        return None, f"Error starting server: {str(e)}"


def stop_server(host: str = DEFAULT_HOST, port: int = DEFAULT_PORT) -> Tuple[bool, Optional[str]]:
    """Stop the Llama.cpp server.
    
    Args:
        host: Host address of the server
        port: Port number of the server
        
    Returns:
        Tuple[bool, Optional[str]]: Success flag and error message if any
    """
    import psutil
    
    # Find processes listening on the specified port
    for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            connections = proc.connections(kind='inet')
            for conn in connections:
                if conn.laddr.port == port and (conn.laddr.ip == host or host == "0.0.0.0"):
                    # Found the process
                    proc.terminate()
                    try:
                        proc.wait(timeout=5)
                    except psutil.TimeoutExpired:
                        proc.kill()
                    return True, None
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass
    
    return False, f"No server found running on {host}:{port}"


def check_server_status(host: str = DEFAULT_HOST, port: int = DEFAULT_PORT) -> Dict[str, Any]:
    """Check the status of the Llama.cpp server.
    
    Args:
        host: Host address of the server
        port: Port number of the server
        
    Returns:
        Dict[str, Any]: Status information
    """
    if not is_port_in_use(host, port):
        return {
            "running": False,
            "message": f"No server running on {host}:{port}"
        }
    
    # Try to get server info through the API
    import requests
    
    try:
        response = requests.get(f"http://{host}:{port}/v1/models")
        if response.status_code == 200:
            models = response.json()
            return {
                "running": True,
                "message": "Server is running",
                "models": models,
                "url": f"http://{host}:{port}"
            }
    except:
        pass
    
    # If API check fails, port is in use but we can't confirm it's the Llama server
    return {
        "running": True,
        "message": f"Something is running on {host}:{port}, but could not confirm it's the Llama.cpp server"
    }


def ensure_server_running(model_name: str = DEFAULT_MODEL, 
                        host: str = DEFAULT_HOST,
                        port: int = DEFAULT_PORT,
                        n_ctx: int = DEFAULT_CONTEXT_SIZE,
                        n_threads: int = DEFAULT_THREADS) -> Dict[str, Any]:
    """Ensure the Llama.cpp server is running.
    
    Args:
        model_name: Name of the model file
        host: Host address to bind to
        port: Port number to bind to
        n_ctx: Context size
        n_threads: Number of threads to use
        
    Returns:
        Dict[str, Any]: Status information
    """
    # Check if server is already running
    status = check_server_status(host, port)
    
    if status["running"]:
        return status
    
    # Start the server
    process, error = start_server(model_name, host, port, n_ctx, n_threads)
    
    if error:
        return {
            "running": False,
            "message": error
        }
    
    # Give the server some time to initialize
    time.sleep(5)
    
    # Check status again
    return check_server_status(host, port)


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Llama.cpp server management script")
    
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")
    
    # Start command
    start_parser = subparsers.add_parser("start", help="Start the Llama.cpp server")
    start_parser.add_argument("--model", type=str, default=DEFAULT_MODEL,
                            help="Model file to load")
    start_parser.add_argument("--host", type=str, default=DEFAULT_HOST,
                            help="Host address to bind to")
    start_parser.add_argument("--port", type=int, default=DEFAULT_PORT,
                            help="Port number to bind to")
    start_parser.add_argument("--ctx-size", type=int, default=DEFAULT_CONTEXT_SIZE,
                            help="Context size")
    start_parser.add_argument("--threads", type=int, default=DEFAULT_THREADS,
                            help="Number of threads to use")
    
    # Stop command
    stop_parser = subparsers.add_parser("stop", help="Stop the Llama.cpp server")
    stop_parser.add_argument("--host", type=str, default=DEFAULT_HOST,
                           help="Host address of the server")
    stop_parser.add_argument("--port", type=int, default=DEFAULT_PORT,
                           help="Port number of the server")
    
    # Status command
    status_parser = subparsers.add_parser("status", help="Check the status of the Llama.cpp server")
    status_parser.add_argument("--host", type=str, default=DEFAULT_HOST,
                             help="Host address of the server")
    status_parser.add_argument("--port", type=int, default=DEFAULT_PORT,
                             help="Port number of the server")
    
    # Ensure command
    ensure_parser = subparsers.add_parser("ensure", help="Ensure the Llama.cpp server is running")
    ensure_parser.add_argument("--model", type=str, default=DEFAULT_MODEL,
                             help="Model file to load")
    ensure_parser.add_argument("--host", type=str, default=DEFAULT_HOST,
                             help="Host address to bind to")
    ensure_parser.add_argument("--port", type=int, default=DEFAULT_PORT,
                             help="Port number to bind to")
    ensure_parser.add_argument("--ctx-size", type=int, default=DEFAULT_CONTEXT_SIZE,
                             help="Context size")
    ensure_parser.add_argument("--threads", type=int, default=DEFAULT_THREADS,
                             help="Number of threads to use")
    
    return parser.parse_args()


def main():
    """Main entry point."""
    args = parse_args()
    
    if args.command == "start":
        process, error = start_server(
            args.model,
            args.host,
            args.port,
            args.ctx_size,
            args.threads
        )
        
        if error:
            print(f"Error: {error}")
            sys.exit(1)
        
        print(f"Server started with PID {process.pid}")
        
    elif args.command == "stop":
        success, error = stop_server(args.host, args.port)
        
        if not success:
            print(f"Error: {error}")
            sys.exit(1)
        
        print("Server stopped successfully")
        
    elif args.command == "status":
        status = check_server_status(args.host, args.port)
        print(json.dumps(status, indent=2))
        
    elif args.command == "ensure":
        status = ensure_server_running(
            args.model,
            args.host,
            args.port,
            args.ctx_size,
            args.threads
        )
        
        print(json.dumps(status, indent=2))
        
        if not status["running"]:
            sys.exit(1)
    
    else:
        print("Please specify a command: start, stop, status, or ensure")
        sys.exit(1)


if __name__ == "__main__":
    main() 