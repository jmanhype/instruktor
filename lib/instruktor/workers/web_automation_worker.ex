defmodule Instruktor.Workers.WebAutomationWorker do
  @moduledoc """
  Oban worker for handling web automation tasks.
  """
  use Oban.Worker, queue: :web_automation, max_attempts: 3

  alias Instruktor.WebAutomation.Client

  @impl Oban.Worker
  def perform(%{args: %{"url" => url, "action" => "navigate"} = args}) do
    options = [
      timeout: args["timeout"] || 30_000,
      screenshot: args["screenshot"] != false,
      wait_until: args["wait_until"] || "load"
    ]
    
    case Client.navigate(url, options) do
      {:ok, result} ->
        # If there's a next step defined, queue it
        if args["next_step"] do
          args = %{
            "session_id" => result["session_id"],
            "action" => args["next_step"]["action"],
            "query" => args["next_step"]["query"]
          }
          
          if args["next_step"]["query"] do
            args = Map.put(args, "query", args["next_step"]["query"])
          end
          
          %{args: args}
          |> Instruktor.Workers.WebAutomationWorker.new()
          |> Oban.insert()
        end
        
        # If LLM processing is requested, queue it
        if args["process_with_llm"] do
          %{
            args: %{
              "html" => result["html"],
              "url" => url,
              "query" => args["llm_query"] || args["query"],
              "schema" => args["schema"]
            }
          }
          |> Instruktor.Workers.LLMProcessingWorker.new()
          |> Oban.insert()
        end
        
        {:ok, result}
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @impl Oban.Worker
  def perform(%{args: %{"session_id" => session_id, "action" => "search", "query" => query} = args}) do
    options = [
      timeout: args["timeout"] || 30_000,
      screenshot: args["screenshot"] != false
    ]
    
    case Client.search(session_id, query, options) do
      {:ok, result} ->
        # If LLM processing is requested, queue it
        if args["process_with_llm"] do
          %{
            args: %{
              "html" => result["html"],
              "url" => result["url"],
              "query" => args["llm_query"] || query,
              "schema" => args["schema"]
            }
          }
          |> Instruktor.Workers.LLMProcessingWorker.new()
          |> Oban.insert()
        end
        
        {:ok, result}
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @impl Oban.Worker
  def perform(%{args: %{"action" => action} = _args}) do
    {:error, "Unsupported action: #{action}"}
  end
end 