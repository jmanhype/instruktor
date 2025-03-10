defmodule Instruktor.WebAutomation do
  @moduledoc """
  Public API for web automation and data extraction.
  """
  
  alias Instruktor.Workers.WebAutomationWorker
  alias Instruktor.Workers.LLMProcessingWorker
  
  @doc """
  Extracts data from a URL with optional LLM processing.
  
  ## Parameters
    * `url` - The URL to extract data from
    * `options` - Additional options for extraction
      * `:query` - Query for search or LLM processing
      * `:schema` - Schema to use for structured data extraction
      * `:process_with_llm` - Whether to process with LLM (boolean)
      * `:wait` - Whether to wait for the job to complete (boolean)
      * `:timeout` - Timeout for navigation (milliseconds)
  
  ## Returns
    * `{:ok, job}` - The Oban job for async processing
    * `{:ok, result}` - The result if `:wait` is true
    * `{:error, reason}` - If extraction fails
  """
  @spec extract_data_from(String.t(), keyword()) :: {:ok, map()} | {:error, any()}
  def extract_data_from(url, options \\ []) do
    process_with_llm = Keyword.get(options, :process_with_llm, false)
    wait = Keyword.get(options, :wait, false)
    
    args = %{
      "url" => url,
      "action" => "navigate",
      "process_with_llm" => process_with_llm
    }
    
    # Add query if provided
    args = if query = Keyword.get(options, :query) do
      Map.put(args, "query", query)
    else
      args
    end
    
    # Add schema if provided
    args = if schema = Keyword.get(options, :schema) do
      Map.put(args, "schema", schema)
    else
      args
    end
    
    # Add timeout if provided
    args = if timeout = Keyword.get(options, :timeout) do
      Map.put(args, "timeout", timeout)
    else
      args
    end
    
    # Create and insert the job
    %{args: args}
    |> WebAutomationWorker.new()
    |> Oban.insert()
    |> case do
      {:ok, job} ->
        if wait do
          # Poll for job completion
          wait_for_job_completion(job.id)
        else
          {:ok, job}
        end
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Searches a website and extracts structured data.
  
  ## Parameters
    * `url` - The base URL to visit
    * `query` - The search query
    * `options` - Additional options for extraction
  
  ## Returns
    * `{:ok, job}` - The Oban job for async processing
    * `{:ok, result}` - The result if `:wait` is true
    * `{:error, reason}` - If extraction fails
  """
  @spec search_website(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, any()}
  def search_website(url, query, options \\ []) do
    process_with_llm = Keyword.get(options, :process_with_llm, true)
    wait = Keyword.get(options, :wait, false)
    
    # Configure a multi-step workflow
    args = %{
      "url" => url,
      "action" => "navigate",
      "next_step" => %{
        "action" => "search",
        "query" => query
      },
      "process_with_llm" => process_with_llm,
      "schema" => Keyword.get(options, :schema, "WebSearchResult")
    }
    
    # Create and insert the job
    %{args: args}
    |> WebAutomationWorker.new()
    |> Oban.insert()
    |> case do
      {:ok, job} ->
        if wait do
          # Poll for job completion
          wait_for_job_completion(job.id)
        else
          {:ok, job}
        end
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Gets the result of a completed job.
  
  ## Parameters
    * `job_id` - The ID of the job to check
  
  ## Returns
    * `{:ok, result}` - The result if the job completed successfully
    * `{:error, reason}` - If the job failed or is still running
  """
  @spec get_job_result(integer()) :: {:ok, map()} | {:error, any()}
  def get_job_result(job_id) do
    case Oban.fetch_job(job_id) do
      {:ok, %{state: "completed", meta: %{"result" => result}}} ->
        {:ok, result}
        
      {:ok, %{state: "completed"}} ->
        {:error, :no_result}
        
      {:ok, %{state: "executing"}} ->
        {:error, :job_in_progress}
        
      {:ok, %{state: "retryable", errors: errors}} ->
        {:error, {:job_failed, errors}}
        
      {:ok, %{state: state}} ->
        {:error, {:job_state, state}}
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Wait for job completion with timeout
  defp wait_for_job_completion(job_id, timeout \\ 60_000) do
    # Poll every 500ms
    poll_interval = 500
    max_attempts = div(timeout, poll_interval)
    
    wait_for_job_completion_recursive(job_id, max_attempts, poll_interval)
  end
  
  defp wait_for_job_completion_recursive(_job_id, 0, _poll_interval) do
    {:error, :timeout}
  end
  
  defp wait_for_job_completion_recursive(job_id, attempts_left, poll_interval) do
    case get_job_result(job_id) do
      {:ok, result} ->
        {:ok, result}
        
      {:error, :job_in_progress} ->
        Process.sleep(poll_interval)
        wait_for_job_completion_recursive(job_id, attempts_left - 1, poll_interval)
        
      {:error, reason} ->
        {:error, reason}
    end
  end
end 