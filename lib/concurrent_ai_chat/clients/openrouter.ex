defmodule ConcurrentAiChat.Clients.OpenRouter do
  @moduledoc """
  OpenRouter API client for AI chat completions.

  Uses the OpenAI-compatible API format with fast models like DeepSeek.
  Supports routing hints like :nitro for fastest throughput.
  """
  require Logger

  @base_url Application.compile_env(:concurrent_ai_chat, :openrouter_base_url, "https://openrouter.ai/api/v1")

  @doc """
  Sends a chat completion request to OpenRouter.

  ## Parameters
    - messages: List of message maps with :role and :content
    - opts: Optional configuration
      - :model - Override default model
      - :temperature - Sampling temperature (0.0-2.0)
      - :max_tokens - Maximum response length

  ## Examples

      iex> messages = [%{role: "user", content: "Hello!"}]
      iex> OpenRouter.chat_completion(messages)
      {:ok, "Hello! How can I help you today?"}
  """
  def chat_completion(messages, opts \\ []) do
    model = Keyword.get(opts, :model, get_default_model())
    temperature = Keyword.get(opts, :temperature, 0.7)
    max_tokens = Keyword.get(opts, :max_tokens, 500)

    request_body = %{
      model: model,
      messages: messages,
      temperature: temperature,
      max_tokens: max_tokens
    }

    headers = [
      {"Authorization", "Bearer #{get_api_key()}"},
      {"Content-Type", "application/json"},
      {"HTTP-Referer", "https://github.com/elixir-concurrent-ai-chat"},
      {"X-Title", "Elixir Concurrent AI Chat"}
    ]

    case Req.post("#{@base_url}/chat/completions",
           json: request_body,
           headers: headers,
           receive_timeout: 30_000
         ) do
      {:ok, %{status: 200, body: body}} ->
        parse_response(body)

      {:ok, %{status: status, body: body}} ->
        Logger.error("OpenRouter API error: #{status} - #{inspect(body)}")
        {:error, "API returned status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        Logger.error("OpenRouter request failed: #{inspect(reason)}")
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Streams a chat completion from OpenRouter.

  Returns a stream of message chunks.
  """
  def stream_chat_completion(messages, opts \\ []) do
    model = Keyword.get(opts, :model, get_default_model())
    temperature = Keyword.get(opts, :temperature, 0.7)
    max_tokens = Keyword.get(opts, :max_tokens, 500)

    request_body = %{
      model: model,
      messages: messages,
      temperature: temperature,
      max_tokens: max_tokens,
      stream: true
    }

    headers = [
      {"Authorization", "Bearer #{get_api_key()}"},
      {"Content-Type", "application/json"},
      {"HTTP-Referer", "https://github.com/elixir-concurrent-ai-chat"},
      {"X-Title", "Elixir Concurrent AI Chat"}
    ]

    # For now, return non-streaming version
    # Streaming implementation would require SSE parsing
    chat_completion(messages, opts)
  end

  ## Private Functions

  defp parse_response(%{"choices" => [choice | _]}) do
    case choice do
      %{"message" => %{"content" => content}} ->
        {:ok, content}

      _ ->
        {:error, "Unexpected response format: #{inspect(choice)}"}
    end
  end

  defp parse_response(body) do
    {:error, "Unexpected response structure: #{inspect(body)}"}
  end

  defp get_api_key do
    Application.get_env(:concurrent_ai_chat, :openrouter_api_key) ||
      System.get_env("OPENROUTER_API_KEY") ||
      raise """
      OpenRouter API key not configured!

      Set the OPENROUTER_API_KEY environment variable:
        export OPENROUTER_API_KEY="your-key-here"

      Or configure it in config/config.exs:
        config :concurrent_ai_chat, openrouter_api_key: "your-key-here"
      """
  end

  defp get_default_model do
    Application.get_env(:concurrent_ai_chat, :default_model, "deepseek/deepseek-chat")
  end
end
