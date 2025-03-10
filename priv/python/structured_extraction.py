#!/usr/bin/env python3
"""
Structured data extraction using the proxy-lite library.
This module extracts structured data from web pages using LLMs and Pydantic models.
"""

import argparse
import json
import os
import sys
from typing import Dict, Any, List, Optional, Type, Union, TypeVar

try:
    from proxy_lite import Ollama
    from pydantic import BaseModel, Field
except ImportError:
    print(json.dumps({"error": "Required libraries not installed. Please run: pip install proxy-lite pydantic"}))
    sys.exit(1)


# Type variable for generic model types
T = TypeVar('T', bound=BaseModel)


class WebPage(BaseModel):
    """A simple model for a web page."""
    url: str
    title: str
    html: str


class ExtractorClient:
    """Client for extracting structured data from web pages using LLMs."""
    
    def __init__(self, model_name: str = "qwen2:7b", base_url: str = "http://localhost:11434"):
        """Initialize the extractor client.
        
        Args:
            model_name: Name of the Ollama model to use
            base_url: Base URL of the Ollama API
        """
        self.client = Ollama(model=model_name, base_url=base_url)
        
    def extract_data(self, webpage: WebPage, schema: Type[T], 
                     instructions: Optional[str] = None) -> Dict[str, Any]:
        """Extract structured data from a web page.
        
        Args:
            webpage: WebPage object containing the HTML content
            schema: Pydantic model schema to extract
            instructions: Optional specific instructions for extraction
            
        Returns:
            Dict: Result containing structured data or error
        """
        try:
            # Generate a prompt for the LLM
            prompt = self._generate_extraction_prompt(webpage, schema, instructions)
            
            # Call the LLM for structured extraction
            response = self.client.extract(schema, prompt)
            
            # Convert the Pydantic model to a dict
            result_dict = response.model_dump()
            
            return {
                "success": True,
                "data": result_dict,
                "model": schema.__name__,
                "url": webpage.url
            }
            
        except Exception as e:
            import traceback
            return {
                "success": False,
                "error": str(e),
                "traceback": traceback.format_exc(),
                "model": schema.__name__ if schema else None,
                "url": webpage.url if webpage else None
            }
            
    def _generate_extraction_prompt(self, webpage: WebPage, schema: Type[BaseModel],
                                   instructions: Optional[str] = None) -> str:
        """Generate a prompt for structured data extraction.
        
        Args:
            webpage: WebPage object containing the HTML content
            schema: Pydantic model schema to extract
            instructions: Optional specific instructions for extraction
            
        Returns:
            str: Prompt for the LLM
        """
        # Get the schema documentation from the model
        schema_info = self._get_schema_info(schema)
        
        # Build the prompt
        prompt = f"""
        I need to extract structured information from the following webpage:
        
        URL: {webpage.url}
        Title: {webpage.title}
        
        I need to extract data according to this schema:
        {schema_info}
        
        """
        
        if instructions:
            prompt += f"\nAdditional instructions: {instructions}\n"
            
        # Add a portion of the HTML content (to avoid token limits)
        html_preview = webpage.html[:10000] + ("..." if len(webpage.html) > 10000 else "")
        prompt += f"\nHTML Content:\n{html_preview}"
        
        return prompt
        
    def _get_schema_info(self, schema: Type[BaseModel]) -> str:
        """Get schema information from a Pydantic model.
        
        Args:
            schema: Pydantic model schema
            
        Returns:
            str: Schema information
        """
        schema_info = f"Schema: {schema.__name__}\n\n"
        
        for field_name, field in schema.model_fields.items():
            field_type = field.annotation
            description = field.description or "No description"
            required = "Required" if field.is_required() else "Optional"
            
            schema_info += f"- {field_name}: {field_type}\n"
            schema_info += f"  Description: {description}\n"
            schema_info += f"  {required}\n\n"
            
        return schema_info


# Example models for extraction
class Product(BaseModel):
    """A product on an e-commerce website."""
    name: str = Field(..., description="The name of the product")
    price: str = Field(..., description="The price of the product as a string, including currency symbol")
    description: str = Field(..., description="A short description of the product")
    rating: Optional[float] = Field(None, description="The product rating as a number from 0-5")
    reviews_count: Optional[int] = Field(None, description="The number of reviews for this product")
    
    
class Article(BaseModel):
    """An article or blog post."""
    title: str = Field(..., description="The title of the article")
    author: Optional[str] = Field(None, description="The name of the author if available")
    date_published: Optional[str] = Field(None, description="The publication date of the article")
    content_summary: str = Field(..., description="A summary of the article content (max 200 words)")
    categories: List[str] = Field(default_factory=list, description="List of categories or tags for this article")
    
    
class SearchResult(BaseModel):
    """A search result item."""
    title: str = Field(..., description="The title of the search result")
    url: str = Field(..., description="The URL of the search result")
    description: str = Field(..., description="The description or snippet of the search result")
    

def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Extract structured data from web pages using LLMs")
    
    # Required arguments
    parser.add_argument("--html", type=str, help="Path to HTML file or HTML content string")
    parser.add_argument("--url", type=str, help="URL of the web page")
    parser.add_argument("--title", type=str, help="Title of the web page")
    
    # Schema to extract
    parser.add_argument("--schema", type=str, choices=["product", "article", "search_result"],
                       default="article", help="Schema to extract")
                       
    # Model options
    parser.add_argument("--model", type=str, default="qwen2:7b", help="Ollama model to use")
    parser.add_argument("--base-url", type=str, default="http://localhost:11434", 
                       help="Base URL of the Ollama API")
                       
    # Additional instructions
    parser.add_argument("--instructions", type=str, help="Additional instructions for extraction")
    
    return parser.parse_args()


def main():
    """Main entry point."""
    args = parse_args()
    
    # Get HTML content
    html_content = ""
    if args.html:
        if os.path.exists(args.html):
            with open(args.html, "r", encoding="utf-8") as f:
                html_content = f.read()
        else:
            html_content = args.html
            
    # Create WebPage object
    webpage = WebPage(
        url=args.url or "unknown",
        title=args.title or "Unknown Title",
        html=html_content
    )
    
    # Get schema
    schema_map = {
        "product": Product,
        "article": Article,
        "search_result": SearchResult
    }
    schema = schema_map.get(args.schema)
    
    # Create extractor client
    client = ExtractorClient(model_name=args.model, base_url=args.base_url)
    
    # Extract data
    result = client.extract_data(webpage, schema, instructions=args.instructions)
    
    # Print result as JSON
    print(json.dumps(result))


if __name__ == "__main__":
    main() 