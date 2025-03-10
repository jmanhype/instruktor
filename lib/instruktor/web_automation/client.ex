defmodule Instruktor.WebAutomation.Client do
  @moduledoc """
  Client for interfacing with the Python Playwright-based web automation.
  """
  
  require Logger
  
  @doc """
  Navigates to a URL and returns the page content and screenshot.
  
  ## Parameters
    * `url` - The URL to navigate to
    * `options` - Additional options for the navigation
      * `:timeout` - Maximum time to wait for page load in milliseconds
      * `:wait_until` - When to consider navigation succeeded ("load", "domcontentloaded", "networkidle")
      * `:screenshot` - Whether to take a screenshot (boolean)
  
  ## Returns
    * `{:ok, result}` - A map with `:html`, `:title`, and optionally `:screenshot`
    * `{:error, reason}` - If navigation fails
  """
  @spec navigate(String.t(), keyword()) :: {:ok, map()} | {:error, any()}
  def navigate(url, options \\ []) do
    python_script_path = Path.join(:code.priv_dir(:instruktor), "python/web_automation.py")
    timeout = Keyword.get(options, :timeout, 30_000)
    headless = Application.get_env(:instruktor, :web_automation, [])[:headless] || true
    
    args = [
      python_script_path,
      "--url", url,
      "--timeout", "#{timeout}",
      "--headless", "#{headless}"
    ]
    
    args = if Keyword.get(options, :screenshot, true) do
      args ++ ["--screenshot", "true"]
    else
      args
    end
    
    case System.cmd("python3", args, stderr_to_stdout: true) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, result} ->
            {:ok, result}
          {:error, _} ->
            Logger.error("Failed to parse Python script output: #{output}")
            {:error, :invalid_output}
        end
      {error, _} ->
        Logger.error("Web automation failed: #{error}")
        {:error, :automation_failed}
    end
  end
  
  @doc """
  Searches on the current page using the provided query.
  
  ## Parameters
    * `session_id` - The session ID from a previous navigation
    * `query` - The search query
    * `options` - Additional options for the search
  
  ## Returns
    * `{:ok, result}` - A map with `:html`, `:title`, and optionally `:screenshot`
    * `{:error, reason}` - If search fails
  """
  @spec search(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, any()}
  def search(session_id, query, options \\ []) do
    python_script_path = Path.join(:code.priv_dir(:instruktor), "python/web_automation.py")
    
    args = [
      python_script_path,
      "--session", session_id,
      "--query", query,
      "--action", "search"
    ]
    
    args = if Keyword.get(options, :screenshot, true) do
      args ++ ["--screenshot", "true"]
    else
      args
    end
    
    case System.cmd("python3", args, stderr_to_stdout: true) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, result} ->
            {:ok, result}
          {:error, _} ->
            Logger.error("Failed to parse Python script output: #{output}")
            {:error, :invalid_output}
        end
      {error, _} ->
        Logger.error("Web automation search failed: #{error}")
        {:error, :search_failed}
    end
  end
end 