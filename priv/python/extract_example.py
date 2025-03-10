#!/usr/bin/env python3
"""
Example script demonstrating web automation and structured data extraction together.
This script navigates to a webpage, extracts the HTML, and then uses an LLM to extract structured data.
"""

import argparse
import json
import os
import sys
import tempfile
from typing import Dict, Any, Optional

# Add the current directory to the Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import our modules
try:
    from web_automation import WebAutomator
    from structured_extraction import ExtractorClient, WebPage, Product, Article, SearchResult
except ImportError:
    print(json.dumps({"error": "Could not import required modules. Make sure you've run setup.sh"}))
    sys.exit(1)


def extract_from_url(url: str, schema_name: str, headless: bool = True, 
                    model_name: str = "qwen2:7b", instructions: Optional[str] = None) -> Dict[str, Any]:
    """Navigate to a URL and extract structured data.
    
    Args:
        url: The URL to navigate to
        schema_name: The schema to extract (product, article, search_result)
        headless: Whether to run the browser in headless mode
        model_name: The name of the LLM model to use
        instructions: Optional specific instructions for extraction
        
    Returns:
        Dict: Result containing structured data or error
    """
    try:
        # Step 1: Navigate to the URL and get the HTML
        with WebAutomator(headless=headless, debug=True) as automator:
            navigation_result = automator.navigate(url)
            
            if not navigation_result.get("success", False):
                return {
                    "success": False,
                    "error": navigation_result.get("error", "Navigation failed"),
                    "url": url
                }
                
            # Step 2: Create a WebPage object from the navigation result
            webpage = WebPage(
                url=navigation_result["url"],
                title=navigation_result["title"],
                html=navigation_result["html"]
            )
            
            # Step 3: Get the appropriate schema
            schema_map = {
                "product": Product,
                "article": Article,
                "search_result": SearchResult
            }
            schema = schema_map.get(schema_name)
            
            if not schema:
                return {
                    "success": False,
                    "error": f"Unknown schema: {schema_name}",
                    "url": url
                }
                
            # Step 4: Create an extractor client and extract the data
            extractor = ExtractorClient(model_name=model_name)
            extraction_result = extractor.extract_data(webpage, schema, instructions)
            
            # Step 5: Combine the results
            combined_result = {
                "success": extraction_result.get("success", False),
                "url": url,
                "title": navigation_result["title"],
                "schema": schema_name,
                "timestamp": navigation_result["timestamp"],
            }
            
            if extraction_result.get("success", False):
                combined_result["data"] = extraction_result["data"]
            else:
                combined_result["error"] = extraction_result.get("error", "Extraction failed")
                
            # Add screenshot if available
            if "screenshot" in navigation_result:
                combined_result["screenshot"] = navigation_result["screenshot"]
                
            return combined_result
            
    except Exception as e:
        import traceback
        return {
            "success": False,
            "error": str(e),
            "traceback": traceback.format_exc(),
            "url": url
        }


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Extract structured data from a URL")
    
    # Required arguments
    parser.add_argument("--url", type=str, required=True, help="URL to navigate to")
    
    # Schema to extract
    parser.add_argument("--schema", type=str, choices=["product", "article", "search_result"],
                       default="article", help="Schema to extract")
                       
    # Options
    parser.add_argument("--headless", type=str, default="true", choices=["true", "false"],
                       help="Whether to run the browser in headless mode")
    parser.add_argument("--model", type=str, default="qwen2:7b", help="LLM model to use")
    parser.add_argument("--instructions", type=str, help="Additional instructions for extraction")
    parser.add_argument("--output", type=str, help="Output file for the JSON result")
    
    return parser.parse_args()


def main():
    """Main entry point."""
    args = parse_args()
    
    # Convert string arguments to appropriate types
    headless = args.headless.lower() == "true"
    
    # Extract data from the URL
    result = extract_from_url(
        url=args.url,
        schema_name=args.schema,
        headless=headless,
        model_name=args.model,
        instructions=args.instructions
    )
    
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