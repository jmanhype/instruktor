#!/usr/bin/env python3
"""
Web automation script using Playwright.
This script is called by the Elixir code to perform web automation tasks.
"""

import argparse
import json
import os
import sys
import uuid
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Union, Any

try:
    from playwright.sync_api import sync_playwright, Page, Browser
except ImportError:
    print(json.dumps({"error": "Playwright is not installed. Please run: pip install playwright"}))
    sys.exit(1)

# Define global settings
DEFAULT_TIMEOUT = 30000  # 30 seconds
DEFAULT_WAIT_UNTIL = "load"  # "load", "domcontentloaded", "networkidle"
SESSION_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sessions")


class WebAutomator:
    """Web automation class using Playwright."""

    def __init__(self, headless: bool = True, debug: bool = False):
        """Initialize the web automator.
        
        Args:
            headless: Whether to run the browser in headless mode
            debug: Whether to enable debug mode
        """
        self.headless = headless
        self.debug = debug
        self.playwright = None
        self.browser = None
        self.session_id = str(uuid.uuid4())
        
        # Create session directory if it doesn't exist
        os.makedirs(SESSION_DIR, exist_ok=True)
        
        # The browser context
        self.context = None
        
        # The current page
        self.page = None
        
    def __enter__(self):
        """Start the browser when entering the context."""
        self.start_browser()
        return self
        
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Close the browser when exiting the context."""
        self.close()
        
    def start_browser(self):
        """Start the browser."""
        self.playwright = sync_playwright().start()
        self.browser = self.playwright.chromium.launch(headless=self.headless)
        self.context = self.browser.new_context()
        self.page = self.context.new_page()
        
        if self.debug:
            self.page.on("console", lambda msg: print(f"BROWSER CONSOLE: {msg.text}"))
            
        return self.page
    
    def save_session(self) -> str:
        """Save the current session state.
        
        Returns:
            str: The session ID
        """
        state_path = os.path.join(SESSION_DIR, f"{self.session_id}.json")
        
        # Save browser state
        storage_state = self.context.storage_state()
        with open(state_path, "w") as f:
            json.dump(storage_state, f)
            
        return self.session_id
    
    def load_session(self, session_id: str) -> bool:
        """Load a previous session state.
        
        Args:
            session_id: The session ID to load
            
        Returns:
            bool: Whether the session was loaded successfully
        """
        state_path = os.path.join(SESSION_DIR, f"{session_id}.json")
        
        if not os.path.exists(state_path):
            return False
            
        # Close existing context if it exists
        if self.context:
            self.context.close()
            
        # Create a new context with the saved state
        with open(state_path, "r") as f:
            storage_state = json.load(f)
            
        self.context = self.browser.new_context(storage_state=storage_state)
        self.page = self.context.new_page()
        self.session_id = session_id
        
        return True
    
    def navigate(self, url: str, timeout: int = DEFAULT_TIMEOUT, 
                 wait_until: str = DEFAULT_WAIT_UNTIL) -> Dict[str, Any]:
        """Navigate to a URL.
        
        Args:
            url: The URL to navigate to
            timeout: Maximum time to wait for navigation in milliseconds
            wait_until: When to consider navigation succeeded
            
        Returns:
            Dict: Result containing HTML content, title, etc.
        """
        try:
            self.page.goto(url, timeout=timeout, wait_until=wait_until)
            
            # Wait for page to be fully loaded
            self.page.wait_for_load_state("networkidle", timeout=timeout)
            
            # Get page content and title
            html = self.page.content()
            title = self.page.title()
            
            # Take a screenshot
            screenshot_path = os.path.join(SESSION_DIR, f"{self.session_id}.png")
            self.page.screenshot(path=screenshot_path)
            
            # Read the screenshot as base64 for JSON response
            with open(screenshot_path, "rb") as f:
                import base64
                screenshot_base64 = base64.b64encode(f.read()).decode("utf-8")
                
            # Save session state
            session_id = self.save_session()
            
            return {
                "success": True,
                "url": url,
                "title": title,
                "html": html,
                "screenshot": screenshot_base64,
                "session_id": session_id,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            if self.debug:
                import traceback
                traceback.print_exc()
                
            return {
                "success": False,
                "error": str(e),
                "url": url
            }
    
    def search(self, query: str, timeout: int = DEFAULT_TIMEOUT) -> Dict[str, Any]:
        """Perform a search on the current page.
        
        Args:
            query: The search query
            timeout: Maximum time to wait in milliseconds
            
        Returns:
            Dict: Result containing search results
        """
        try:
            # Find search input element (using common selectors)
            search_input_selectors = [
                "input[type='search']",
                "input[name='q']",
                "input[name='query']",
                "input[name='search']",
                "input.search",
                "#search-input",
                ".search-input"
            ]
            
            search_input = None
            for selector in search_input_selectors:
                try:
                    search_input = self.page.query_selector(selector)
                    if search_input:
                        break
                except:
                    continue
                    
            if not search_input:
                return {
                    "success": False,
                    "error": "Could not find search input element",
                }
                
            # Clear the search input and type the query
            search_input.click()
            search_input.fill("")
            search_input.type(query, delay=100)  # Type slower to simulate human
            search_input.press("Enter")
            
            # Wait for results to load
            self.page.wait_for_load_state("networkidle", timeout=timeout)
            
            # Get page content and title
            html = self.page.content()
            title = self.page.title()
            current_url = self.page.url
            
            # Take a screenshot
            screenshot_path = os.path.join(SESSION_DIR, f"{self.session_id}_search.png")
            self.page.screenshot(path=screenshot_path)
            
            # Read the screenshot as base64 for JSON response
            with open(screenshot_path, "rb") as f:
                import base64
                screenshot_base64 = base64.b64encode(f.read()).decode("utf-8")
                
            # Save session state
            session_id = self.save_session()
            
            return {
                "success": True,
                "url": current_url,
                "title": title,
                "html": html,
                "query": query,
                "screenshot": screenshot_base64,
                "session_id": session_id,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            if self.debug:
                import traceback
                traceback.print_exc()
                
            return {
                "success": False,
                "error": str(e),
                "query": query
            }
    
    def close(self):
        """Close the browser and clean up resources."""
        if self.context:
            self.context.close()
            
        if self.browser:
            self.browser.close()
            
        if self.playwright:
            self.playwright.stop()


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Web automation script using Playwright")
    
    # Required arguments for all actions
    parser.add_argument("--action", choices=["navigate", "search", "screenshot"],
                        default="navigate", help="The action to perform")
                        
    # URL to navigate to
    parser.add_argument("--url", type=str, help="The URL to navigate to")
    
    # Session ID for continuing a previous session
    parser.add_argument("--session", type=str, help="Session ID to continue a previous session")
    
    # Query for search
    parser.add_argument("--query", type=str, help="Search query")
    
    # Options
    parser.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT,
                        help="Maximum time to wait in milliseconds")
    parser.add_argument("--wait-until", type=str, default=DEFAULT_WAIT_UNTIL,
                        choices=["load", "domcontentloaded", "networkidle"],
                        help="When to consider navigation succeeded")
    parser.add_argument("--headless", type=str, default="true",
                        choices=["true", "false"],
                        help="Whether to run the browser in headless mode")
    parser.add_argument("--screenshot", type=str, default="true",
                        choices=["true", "false"],
                        help="Whether to take a screenshot")
    parser.add_argument("--debug", type=str, default="false",
                        choices=["true", "false"],
                        help="Whether to enable debug mode")
                        
    return parser.parse_args()


def main():
    """Main entry point."""
    args = parse_args()
    
    # Convert string arguments to appropriate types
    headless = args.headless.lower() == "true"
    debug = args.debug.lower() == "true"
    
    try:
        with WebAutomator(headless=headless, debug=debug) as automator:
            # If a session ID is provided, load it
            if args.session:
                if not automator.load_session(args.session):
                    result = {
                        "success": False,
                        "error": f"Could not load session {args.session}"
                    }
                    print(json.dumps(result))
                    return
            
            # Perform the requested action
            if args.action == "navigate" and args.url:
                result = automator.navigate(
                    args.url,
                    timeout=args.timeout,
                    wait_until=args.wait_until
                )
                
            elif args.action == "search" and args.query:
                result = automator.search(
                    args.query,
                    timeout=args.timeout
                )
                
            else:
                result = {
                    "success": False,
                    "error": f"Invalid action or missing required arguments. Action: {args.action}"
                }
                
            # Print the result as JSON to stdout for the Elixir code to parse
            print(json.dumps(result))
            
    except Exception as e:
        import traceback
        result = {
            "success": False,
            "error": str(e),
            "traceback": traceback.format_exc() if debug else None
        }
        print(json.dumps(result))


if __name__ == "__main__":
    main() 