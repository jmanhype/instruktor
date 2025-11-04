defmodule Instruktor.Workers.LLMProcessingWorker do
  @moduledoc """
  Oban worker for handling LLM processing tasks.

  This worker processes HTML content using LLMs to extract structured data.
  It supports various schemas for different types of data extraction.

  Jobs are retried up to 2 times on failure (lower than web automation
  since LLM failures are often non-recoverable).
  """
  use Oban.Worker, queue: :llm_processing, max_attempts: 2

  require Logger
  alias Instruktor.LLM.Client

  @impl Oban.Worker
  def perform(%{args: %{"html" => html, "query" => query} = args})
    when is_binary(html) and is_binary(query) do
    Logger.info("LLMProcessingWorker: Processing query '#{query}'")

    with {:ok, schema_module} <- get_schema_module(args["schema"]) do
      # Truncate HTML to avoid overwhelming the LLM
      truncated_html = truncate_html(html, 10_000)

      prompt = """
      Based on the following HTML content from a webpage, #{query}

      HTML Content:
      #{truncated_html}
      """

      case Client.extract_structured_data(prompt, schema_module) do
        {:ok, result} ->
          Logger.debug("LLM processing successful")

          # If we need to store the result, queue a storage job
          if args["store_result"] do
            Logger.info("Storage requested but StorageWorker not yet implemented")
          end

          {:ok, result}

        {:error, reason} ->
          Logger.error("LLM processing failed: #{inspect(reason)}")
          {:error, reason}
      end
    else
      {:error, reason} ->
        Logger.error("Schema resolution failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl Oban.Worker
  def perform(%{args: args}) do
    Logger.error("Invalid LLM job arguments: #{inspect(args)}")
    {:error, "Invalid job arguments: missing required fields (html, query)"}
  end

  # Truncate HTML to avoid overwhelming the LLM
  defp truncate_html(html, max_length) when byte_size(html) > max_length do
    Logger.debug("Truncating HTML from #{byte_size(html)} to #{max_length} bytes")
    binary_part(html, 0, max_length) <> "\n... [truncated]"
  end

  defp truncate_html(html, _max_length), do: html

  # Helper function to determine schema module based on configuration
  defp get_schema_module(nil) do
    # Default schema if none specified
    {:ok, Instruktor.Schemas.WebAutomationResult}
  end

  defp get_schema_module(schema_name) when is_binary(schema_name) do
    schema = case schema_name do
      "WebSearchResult" -> Instruktor.Schemas.WebSearchResult
      "WebAutomationResult" -> Instruktor.Schemas.WebAutomationResult
      _ ->
        Logger.warning("Unknown schema '#{schema_name}', using default WebAutomationResult")
        Instruktor.Schemas.WebAutomationResult
    end

    {:ok, schema}
  end

  defp get_schema_module(schema_module) when is_atom(schema_module) do
    {:ok, schema_module}
  end

  defp get_schema_module(invalid) do
    {:error, "Invalid schema type: #{inspect(invalid)}"}
  end
end
