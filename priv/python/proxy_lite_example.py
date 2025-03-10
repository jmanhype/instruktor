#!/usr/bin/env python3
"""
Proxy-Lite-3B integration for web automation.
This script demonstrates using the proxy-lite-3b model for web automation tasks.
"""

import argparse
import json
import os
import sys
import base64
from typing import Dict, List, Optional, Union, Any

try:
    import requests
    from proxy_lite import ProxyLite3B
    from pydantic import BaseModel, Field
except ImportError:
    print(json.dumps({"error": "Required libraries not installed. Please run: pip install proxy-lite pydantic requests"}))
    sys.exit(1)

# Import our other modules if they're in the same directory
script_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, script_dir)

try:
    from web_automation import WebAutomator
except ImportError:
    print(json.dumps({"error": "Could not import web_automation. Make sure it's in the same directory."}))
    sys.exit(1)


class SearchRequest(BaseModel):
    """Model for a search request."""
    query: str = Field(..., description="The search query")
    homepage: str = Field(..., description="The homepage URL")
    max_results: int = Field(5, description="Maximum number of results to return")


class SearchResult(BaseModel):
    """Model for a search result."""
    title: str = Field(..., description="The title of the search result")
    url: str = Field(..., description="The URL of the search result")
    snippet: str = Field(..., description="A brief snippet or description of the search result")


class SearchResponse(BaseModel):
    """Model for the search response."""
    query: str = Field(..., description="The original search query")
    results: List[SearchResult] = Field(..., description="List of search results")
    total_results_count: Optional[int] = Field(None, description="Total number of results found (if available)")


class ProxyLite3BAutomation:
    """Class for web automation using the proxy-lite-3b model."""

    def __init__(self, api_key: Optional[str] = None, 
                 api_base: str = "https://api.getproxy.ai",
                 debug: bool = False):
        """Initialize the proxy-lite-3b automation.
        
        Args:
            api_key: API key for the proxy-lite-3b service
            api_base: Base URL for the proxy-lite-3b API
            debug: Whether to enable debug mode
        """
        self.debug = debug
        self.client = ProxyLite3B(
            api_key=api_key,
            api_base=api_base
        )
        
    def _screenshot_to_base64(self, image_path: str) -> str:
        """Convert a screenshot to base64.
        
        Args:
            image_path: Path to the image file
            
        Returns:
            str: Base64-encoded image
        """
        with open(image_path, "rb") as f:
            return base64.b64encode(f.read()).decode("utf-8")
    
    def search(self, request: SearchRequest) -> Dict[str, Any]:
        """Perform a search on the web.
        
        Args:
            request: Search request parameters
            
        Returns:
            Dict: Search results
        """
        try:
            # Initialize WebAutomator
            with WebAutomator(headless=True, debug=self.debug) as automator:
                # Navigate to the homepage
                navigation_result = automator.navigate(request.homepage)
                
                if not navigation_result.get("success", False):
                    return {
                        "success": False,
                        "error": navigation_result.get("error", "Navigation failed"),
                        "query": request.query
                    }
                
                # Take a screenshot base64 from the result
                screenshot_base64 = navigation_result.get("screenshot", "")
                
                # Get the HTML
                html = navigation_result.get("html", "")
                
                # Perform the search
                search_result = automator.search(request.query)
                
                if not search_result.get("success", False):
                    return {
                        "success": False,
                        "error": search_result.get("error", "Search failed"),
                        "query": request.query
                    }
                
                # Get the updated screenshot and HTML after search
                search_screenshot = search_result.get("screenshot", "")
                search_html = search_result.get("html", "")
                
                # Use the proxy-lite-3b model to extract search results
                prompt = f"""
                I need you to extract search results from this web page. 
                
                The user searched for: {request.query}
                The website is: {request.homepage}
                
                Please extract up to {request.max_results} search results.
                Each result should have a title, URL, and a brief snippet or description.
                
                Focus only on actual search results, not ads or other elements.
                """
                
                # Call the model with both visual and HTML context
                response = self.client.extract(
                    model=SearchResponse,
                    prompt=prompt,
                    html=search_html,
                    image_data=search_screenshot
                )
                
                return {
                    "success": True,
                    "query": request.query,
                    "results": response.model_dump(),
                    "screenshot": search_screenshot
                }
                
        except Exception as e:
            import traceback
            return {
                "success": False,
                "error": str(e),
                "traceback": traceback.format_exc() if self.debug else None,
                "query": request.query
            }


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Web automation with proxy-lite-3b")
    
    parser.add_argument("query", type=str, help="Search query")
    parser.add_argument("--homepage", type=str, default="https://en.wikipedia.org",
                       help="Homepage URL")
    parser.add_argument("--max-results", type=int, default=5,
                       help="Maximum number of results to return")
    parser.add_argument("--api-key", type=str,
                       help="API key for the proxy-lite-3b service")
    parser.add_argument("--api-base", type=str, default="https://api.getproxy.ai",
                       help="Base URL for the proxy-lite-3b API")
    parser.add_argument("--debug", action="store_true",
                       help="Enable debug mode")
    parser.add_argument("--output", type=str,
                       help="Output file for the JSON result")
    
    return parser.parse_args()


def main():
    """Main entry point."""
    args = parse_args()
    
    # Create the search request
    request = SearchRequest(
        query=args.query,
        homepage=args.homepage,
        max_results=args.max_results
    )
    
    # Initialize the automation
    automation = ProxyLite3BAutomation(
        api_key=args.api_key,
        api_base=args.api_base,
        debug=args.debug
    )
    
    # Perform the search
    result = automation.search(request)
    
    # Format the result as JSON
    json_result = json.dumps(result, indent=2)
    
    # Output the result
    if args.output:
        with open(args.output, "w") as f:
            f.write(json_result)
        print(f"Result saved to {args.output}")
    else:
        print(json_result)


if __name__ == "__main__":
    main() 