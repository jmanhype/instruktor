defmodule Instruktor.Workers.LLMProcessingWorker do
  @moduledoc """
  Oban worker for handling LLM processing tasks.
  """
  use Oban.Worker, queue: :llm_processing, max_attempts: 2

  alias Instruktor.LLM.Client
  alias Instructor.Ecto.Schema

  @impl Oban.Worker
  def perform(%{args: %{"html" => html, "query" => query} = args}) do
    schema_module = get_schema_module(args["schema"])
    
    prompt = """
    Based on the following HTML content from a webpage, #{query}
    
    HTML Content:
    #{html}
    """
    
    case Client.extract_structured_data(prompt, schema_module) do
      {:ok, result} ->
        # If we need to store the result, queue a storage job
        if args["store_result"] do
          %{
            args: %{
              "result" => result,
              "metadata" => %{
                "url" => args["url"],
                "query" => query,
                "timestamp" => DateTime.utc_now()
              }
            }
          }
          |> Instruktor.Workers.StorageWorker.new()
          |> Oban.insert()
        end
        
        {:ok, result}
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Helper function to determine schema module based on configuration
  defp get_schema_module(nil) do
    # Default schema if none specified
    Instruktor.Schemas.WebAutomationResult
  end
  
  defp get_schema_module(schema_name) when is_binary(schema_name) do
    case schema_name do
      "WebSearchResult" -> Instruktor.Schemas.WebSearchResult
      "WebAutomationSummary" -> Instruktor.Schemas.WebAutomationSummary
      "ArticleContent" -> Instruktor.Schemas.ArticleContent
      _ -> Instruktor.Schemas.WebAutomationResult
    end
  end
  
  defp get_schema_module(schema_module) when is_atom(schema_module) do
    schema_module
  end
end 