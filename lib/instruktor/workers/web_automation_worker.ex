defmodule Instruktor.Workers.WebAutomationWorker do
  @moduledoc """
  Oban worker for handling web automation tasks.

  This worker processes web automation jobs including:
  - Navigating to URLs
  - Performing searches on web pages
  - Chaining multiple automation steps
  - Integrating with LLM processing

  Jobs are retried up to 3 times on failure.
  """
  use Oban.Worker, queue: :web_automation, max_attempts: 3

  require Logger
  alias Instruktor.WebAutomation.Client

  @impl Oban.Worker
  def perform(%{args: %{"url" => url, "action" => "navigate"} = args}) when is_binary(url) do
    Logger.info("WebAutomationWorker: Navigating to #{url}")
    options = [
      timeout: args["timeout"] || 30_000,
      screenshot: args["screenshot"] != false,
      wait_until: args["wait_until"] || "load"
    ]
    
    case Client.navigate(url, options) do
      {:ok, result} ->
        # If there's a next step defined, queue it
        if args["next_step"] do
          next_step_args = %{
            "session_id" => result["session_id"],
            "action" => args["next_step"]["action"]
          }

          next_step_args = if args["next_step"]["query"] do
            Map.put(next_step_args, "query", args["next_step"]["query"])
          else
            next_step_args
          end

          case %{args: next_step_args}
               |> Instruktor.Workers.WebAutomationWorker.new()
               |> Oban.insert() do
            {:ok, _job} -> Logger.debug("Queued next step: #{args["next_step"]["action"]}")
            {:error, reason} -> Logger.error("Failed to queue next step: #{inspect(reason)}")
          end
        end

        # If LLM processing is requested, queue it
        if args["process_with_llm"] && result["html"] do
          llm_args = %{
            "html" => result["html"],
            "url" => url,
            "query" => args["llm_query"] || args["query"],
            "schema" => args["schema"]
          }

          case %{args: llm_args}
               |> Instruktor.Workers.LLMProcessingWorker.new()
               |> Oban.insert() do
            {:ok, _job} -> Logger.debug("Queued LLM processing")
            {:error, reason} -> Logger.error("Failed to queue LLM processing: #{inspect(reason)}")
          end
        end

        {:ok, result}

      {:error, reason} ->
        Logger.error("Navigation failed for #{url}: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  @impl Oban.Worker
  def perform(%{args: %{"session_id" => session_id, "action" => "search", "query" => query} = args})
    when is_binary(session_id) and is_binary(query) do
    Logger.info("WebAutomationWorker: Searching for '#{query}' in session #{session_id}")
    options = [
      timeout: args["timeout"] || 30_000,
      screenshot: args["screenshot"] != false
    ]
    
    case Client.search(session_id, query, options) do
      {:ok, result} ->
        # If LLM processing is requested, queue it
        if args["process_with_llm"] && result["html"] do
          llm_args = %{
            "html" => result["html"],
            "url" => result["url"],
            "query" => args["llm_query"] || query,
            "schema" => args["schema"]
          }

          case %{args: llm_args}
               |> Instruktor.Workers.LLMProcessingWorker.new()
               |> Oban.insert() do
            {:ok, _job} -> Logger.debug("Queued LLM processing for search results")
            {:error, reason} -> Logger.error("Failed to queue LLM processing: #{inspect(reason)}")
          end
        end

        {:ok, result}

      {:error, reason} ->
        Logger.error("Search failed for query '#{query}': #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  @impl Oban.Worker
  def perform(%{args: %{"action" => action} = _args}) do
    Logger.error("Unsupported action: #{action}")
    {:error, "Unsupported action: #{action}"}
  end

  @impl Oban.Worker
  def perform(%{args: args}) do
    Logger.error("Invalid job arguments: #{inspect(args)}")
    {:error, "Invalid job arguments: missing required fields (url/session_id, action)"}
  end
end 