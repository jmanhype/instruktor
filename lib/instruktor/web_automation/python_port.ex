defmodule Instruktor.WebAutomation.PythonPort do
  @moduledoc """
  Module for communicating with the Python web automation scripts via OS ports.
  This module provides a clean interface for executing the Python scripts and handling their outputs.
  """

  require Logger
  alias Instruktor.WebAutomation.Result

  @python_dir Path.join(:code.priv_dir(:instruktor), "python")
  @venv_dir Path.join(@python_dir, "venv")
  @venv_bin_dir Path.join(@venv_dir, "bin")
  @python Path.join(@venv_bin_dir, "python")

  @automation_script Path.join(@python_dir, "web_automation.py")
  @extraction_script Path.join(@python_dir, "structured_extraction.py")
  @example_script Path.join(@python_dir, "extract_example.py")
  @proxy_lite_script Path.join(@python_dir, "proxy_lite_example.py")
  @llama_server_script Path.join(@python_dir, "llama_server.py")

  @doc """
  Ensures the Python environment is set up and ready to use.
  
  Returns:
  * `:ok` - If the environment is set up
  * `{:error, reason}` - If the environment is not ready
  """
  @spec ensure_python_setup() :: :ok | {:error, String.t()}
  def ensure_python_setup do
    setup_script = Path.join(@python_dir, "setup.sh")

    if not File.exists?(@python) do
      Logger.info("Setting up Python environment...")
      
      case System.cmd("bash", [setup_script], cd: @python_dir) do
        {output, 0} ->
          Logger.info("Python environment set up successfully")
          Logger.debug(output)
          :ok
          
        {error, code} ->
          Logger.error("Failed to set up Python environment (exit code #{code}): #{error}")
          {:error, "Failed to set up Python environment"}
      end
    else
      :ok
    end
  end

  @doc """
  Ensures the Llama server is running.
  
  ## Parameters
  * `options` - Options for the Llama server
    * `:model` - Name of the model file (default: "qwen2.5-7b-instruct.Q4_K_M.gguf")
    * `:host` - Host address to bind to (default: "127.0.0.1")
    * `:port` - Port number to bind to (default: 8090)
    * `:ctx_size` - Context size (default: 4096)
    * `:threads` - Number of threads to use (default: 0 - auto)
  
  Returns:
  * `{:ok, status}` - If the server is running
  * `{:error, reason}` - If the server could not be started
  """
  @spec ensure_llama_server(Keyword.t()) :: {:ok, map()} | {:error, String.t()}
  def ensure_llama_server(options \\ []) do
    with :ok <- ensure_python_setup() do
      model = Keyword.get(options, :model, "qwen2.5-7b-instruct.Q4_K_M.gguf")
      host = Keyword.get(options, :host, "127.0.0.1")
      port = Keyword.get(options, :port, 8090)
      ctx_size = Keyword.get(options, :ctx_size, 4096)
      threads = Keyword.get(options, :threads, 0)
      
      args = [
        "ensure",
        "--model", model,
        "--host", host,
        "--port", to_string(port),
        "--ctx-size", to_string(ctx_size),
        "--threads", to_string(threads)
      ]
      
      case run_python_script(@llama_server_script, args) do
        {:ok, output} ->
          case Jason.decode(output) do
            {:ok, result} ->
              if result["running"] do
                {:ok, result}
              else
                {:error, result["message"] || "Unknown error"}
              end
              
            {:error, error} ->
              {:error, "Failed to parse JSON: #{inspect(error)}"}
          end
          
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Navigates to a URL and returns the HTML and other information.
  
  ## Parameters
  * `url` - The URL to navigate to
  * `options` - Options for navigation
    * `:headless` - Whether to run the browser in headless mode (default: true)
    * `:timeout` - Maximum time to wait for navigation in milliseconds (default: 30000)
    * `:wait_until` - When to consider navigation succeeded (default: "load")
    * `:debug` - Whether to enable debug mode (default: false)
    * `:session_id` - Session ID to continue a previous session
  
  ## Returns
  * `{:ok, result}` - If the navigation was successful
  * `{:error, reason}` - If the navigation failed
  """
  @spec navigate(String.t(), Keyword.t()) :: {:ok, map()} | {:error, String.t()}
  def navigate(url, options \\ []) do
    with :ok <- ensure_python_setup() do
      headless = Keyword.get(options, :headless, true)
      timeout = Keyword.get(options, :timeout, 30000)
      wait_until = Keyword.get(options, :wait_until, "load")
      debug = Keyword.get(options, :debug, false)
      session_id = Keyword.get(options, :session_id, nil)
      
      args = [
        "--action", "navigate",
        "--url", url,
        "--headless", to_string(headless),
        "--timeout", to_string(timeout),
        "--wait-until", wait_until,
        "--debug", to_string(debug)
      ]
      
      args = if session_id, do: args ++ ["--session", session_id], else: args
      
      case run_python_script(@automation_script, args) do
        {:ok, output} ->
          case Jason.decode(output) do
            {:ok, result} ->
              if result["success"] do
                {:ok, result}
              else
                {:error, result["error"] || "Unknown error"}
              end
              
            {:error, error} ->
              {:error, "Failed to parse JSON: #{inspect(error)}"}
          end
          
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Performs a search on a webpage.
  
  ## Parameters
  * `query` - The search query
  * `options` - Options for the search
    * `:session_id` - Session ID of a previous navigation (required)
    * `:headless` - Whether to run the browser in headless mode (default: true)
    * `:timeout` - Maximum time to wait in milliseconds (default: 30000)
    * `:debug` - Whether to enable debug mode (default: false)
  
  ## Returns
  * `{:ok, result}` - If the search was successful
  * `{:error, reason}` - If the search failed
  """
  @spec search(String.t(), Keyword.t()) :: {:ok, map()} | {:error, String.t()}
  def search(query, options \\ []) do
    with :ok <- ensure_python_setup() do
      session_id = Keyword.get(options, :session_id)
      
      unless session_id do
        {:error, "Session ID is required for search"}
      else
        headless = Keyword.get(options, :headless, true)
        timeout = Keyword.get(options, :timeout, 30000)
        debug = Keyword.get(options, :debug, false)
        
        args = [
          "--action", "search",
          "--query", query,
          "--session", session_id,
          "--headless", to_string(headless),
          "--timeout", to_string(timeout),
          "--debug", to_string(debug)
        ]
        
        case run_python_script(@automation_script, args) do
          {:ok, output} ->
            case Jason.decode(output) do
              {:ok, result} ->
                if result["success"] do
                  {:ok, result}
                else
                  {:error, result["error"] || "Unknown error"}
                end
                
              {:error, error} ->
                {:error, "Failed to parse JSON: #{inspect(error)}"}
            end
            
          {:error, reason} ->
            {:error, reason}
        end
      end
    end
  end

  @doc """
  Extracts structured data from a URL in one step.
  
  ## Parameters
  * `url` - The URL to navigate to
  * `schema` - The schema to extract (product, article, search_result)
  * `options` - Options for extraction
    * `:headless` - Whether to run the browser in headless mode (default: true)
    * `:model` - The LLM model to use (default: "qwen2:7b")
    * `:instructions` - Additional instructions for extraction
    * `:timeout` - Maximum time to wait in milliseconds (default: 30000)
    * `:debug` - Whether to enable debug mode (default: false)
  
  ## Returns
  * `{:ok, result}` - If the extraction was successful
  * `{:error, reason}` - If the extraction failed
  """
  @spec extract(String.t(), String.t(), Keyword.t()) :: {:ok, map()} | {:error, String.t()}
  def extract(url, schema, options \\ []) do
    with :ok <- ensure_python_setup() do
      headless = Keyword.get(options, :headless, true)
      model = Keyword.get(options, :model, "qwen2:7b")
      instructions = Keyword.get(options, :instructions, nil)
      timeout = Keyword.get(options, :timeout, 30000)
      debug = Keyword.get(options, :debug, false)
      
      args = [
        "--url", url,
        "--schema", schema,
        "--headless", to_string(headless),
        "--model", model,
        "--timeout", to_string(timeout)
      ]
      
      args = if instructions, do: args ++ ["--instructions", instructions], else: args
      
      case run_python_script(@example_script, args) do
        {:ok, output} ->
          case Jason.decode(output) do
            {:ok, result} ->
              if result["success"] do
                {:ok, result}
              else
                {:error, result["error"] || "Unknown error"}
              end
              
            {:error, error} ->
              {:error, "Failed to parse JSON: #{inspect(error)}"}
          end
          
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Extracts structured data from HTML content.
  
  ## Parameters
  * `html` - The HTML content or path to HTML file
  * `schema` - The schema to extract (product, article, search_result)
  * `options` - Options for extraction
    * `:url` - The URL of the web page
    * `:title` - The title of the web page
    * `:model` - The LLM model to use (default: "qwen2:7b")
    * `:instructions` - Additional instructions for extraction
  
  ## Returns
  * `{:ok, result}` - If the extraction was successful
  * `{:error, reason}` - If the extraction failed
  """
  @spec extract_from_html(String.t(), String.t(), Keyword.t()) :: {:ok, map()} | {:error, String.t()}
  def extract_from_html(html, schema, options \\ []) do
    with :ok <- ensure_python_setup() do
      url = Keyword.get(options, :url, "unknown")
      title = Keyword.get(options, :title, "Unknown Title")
      model = Keyword.get(options, :model, "qwen2:7b")
      instructions = Keyword.get(options, :instructions, nil)
      
      # If the HTML is too large, write it to a temporary file
      {html_arg, temp_file} = 
        if String.length(html) > 10000 do
          path = Path.join(System.tmp_dir!(), "instruktor_#{:rand.uniform(1000000)}.html")
          :ok = File.write!(path, html)
          {path, path}
        else
          {html, nil}
        end
        
      args = [
        "--html", html_arg,
        "--url", url,
        "--title", title,
        "--schema", schema,
        "--model", model
      ]
      
      args = if instructions, do: args ++ ["--instructions", instructions], else: args
      
      result = run_python_script(@extraction_script, args)
      
      # Clean up temporary file if created
      if temp_file, do: File.rm(temp_file)
      
      case result do
        {:ok, output} ->
          case Jason.decode(output) do
            {:ok, result} ->
              if result["success"] do
                {:ok, result}
              else
                {:error, result["error"] || "Unknown error"}
              end
              
            {:error, error} ->
              {:error, "Failed to parse JSON: #{inspect(error)}"}
          end
          
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Perform web search using the ProxyLite3B model.
  
  ## Parameters
  * `query` - The search query
  * `options` - Options for the search
    * `:homepage` - The homepage URL (default: "https://en.wikipedia.org")
    * `:max_results` - Maximum number of results to return (default: 5)
    * `:api_key` - API key for the ProxyLite3B service
    * `:api_base` - Base URL for the ProxyLite3B API (default: "https://api.getproxy.ai")
    * `:debug` - Whether to enable debug mode (default: false)
    * `:output` - Output file for the JSON result
  
  ## Returns
  * `{:ok, result}` - If the search was successful
  * `{:error, reason}` - If the search failed
  """
  @spec proxy_lite_search(String.t(), Keyword.t()) :: {:ok, map()} | {:error, String.t()}
  def proxy_lite_search(query, options \\ []) do
    with :ok <- ensure_python_setup() do
      homepage = Keyword.get(options, :homepage, "https://en.wikipedia.org")
      max_results = Keyword.get(options, :max_results, 5)
      api_key = Keyword.get(options, :api_key, System.get_env("PROXY_API_KEY"))
      api_base = Keyword.get(options, :api_base, "https://api.getproxy.ai")
      debug = Keyword.get(options, :debug, false)
      output = Keyword.get(options, :output, nil)
      
      args = [
        query,
        "--homepage", homepage,
        "--max-results", to_string(max_results)
      ]
      
      args = if api_key, do: args ++ ["--api-key", api_key], else: args
      args = args ++ ["--api-base", api_base]
      args = if debug, do: args ++ ["--debug"], else: args
      args = if output, do: args ++ ["--output", output], else: args
      
      case run_python_script(@proxy_lite_script, args) do
        {:ok, output} ->
          case Jason.decode(output) do
            {:ok, result} ->
              if result["success"] do
                {:ok, result}
              else
                {:error, result["error"] || "Unknown error"}
              end
              
            {:error, error} ->
              {:error, "Failed to parse JSON: #{inspect(error)}"}
          end
          
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # Private helper functions

  defp run_python_script(script, args) do
    Logger.debug("Running Python script: #{script} #{Enum.join(args, " ")}")
    
    cmd_args = [script | args]
    
    try do
      case System.cmd(@python, cmd_args, stderr_to_stdout: true) do
        {output, 0} ->
          # Trim the output to handle any extraneous output
          trimmed_output = String.trim(output)
          {:ok, trimmed_output}
          
        {error, code} ->
          Logger.error("Python script failed (exit code #{code}): #{error}")
          {:error, "Python script failed with exit code #{code}"}
      end
    rescue
      e ->
        Logger.error("Failed to run Python script: #{inspect(e)}")
        {:error, "Failed to run Python script: #{inspect(e)}"}
    end
  end
end 