defmodule Instruktor.LLM.Client do
  @moduledoc """
  Client for interfacing with the LLM server (llama.cpp).
  """
  
  require Logger
  
  @doc """
  Extracts structured data from text using an LLM and a schema.
  
  ## Parameters
    * `prompt` - The prompt to send to the LLM
    * `schema_module` - The Ecto schema module to use for validation
    * `options` - Additional options for extraction
      * `:temperature` - Controls randomness (0.0 to 1.0)
      * `:max_tokens` - Maximum number of tokens to generate
  
  ## Returns
    * `{:ok, data}` - The validated structured data
    * `{:error, reason}` - If extraction fails
  """
  @spec extract_structured_data(String.t(), module(), keyword()) :: {:ok, struct()} | {:error, any()}
  def extract_structured_data(prompt, schema_module, options \\ []) do
    llm_config = Application.get_env(:instruktor, :llm, [])
    url = llm_config[:url] || "http://127.0.0.1:8090"
    
    temperature = options[:temperature] || llm_config[:temperature] || 0.2
    max_tokens = options[:max_tokens] || llm_config[:max_tokens] || 2000
    
    request_body = %{
      "model" => llm_config[:model] || "qwen2.5-7b-instruct",
      "temperature" => temperature,
      "max_tokens" => max_tokens,
      "messages" => [
        %{"role" => "system", "content" => "You are a helpful assistant that extracts structured information from text."},
        %{"role" => "user", "content" => prompt}
      ]
    }
    
    headers = [{"Content-Type", "application/json"}]
    
    case HTTPoison.post("#{url}/v1/chat/completions", Jason.encode!(request_body), headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        handle_llm_response(body, schema_module)
      
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("LLM API error: HTTP #{status_code} - #{body}")
        {:error, {:api_error, status_code}}
      
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("LLM API request failed: #{inspect(reason)}")
        {:error, {:request_failed, reason}}
    end
  end
  
  # Handle the LLM API response
  defp handle_llm_response(body, schema_module) do
    with {:ok, response} <- Jason.decode(body),
         content when is_binary(content) <- get_content_from_response(response) do
      
      # Use Instructor to validate against schema
      Instructor.validate_struct(content, schema_module)
    else
      {:error, error} ->
        Logger.error("Failed to parse LLM response: #{inspect(error)}")
        {:error, {:parsing_error, error}}
      
      nil ->
        Logger.error("No content found in LLM response")
        {:error, :no_content}
    end
  end
  
  # Extract content from LLM API response
  defp get_content_from_response(%{"choices" => [%{"message" => %{"content" => content}} | _]}) 
    when is_binary(content), do: content
  
  defp get_content_from_response(_), do: nil
end 