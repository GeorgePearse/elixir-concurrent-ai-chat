defmodule ConcurrentAiChat do
  @moduledoc """
  ConcurrentAiChat - Massively Concurrent AI Chat Experiment

  This application demonstrates Elixir's capability to handle massive
  concurrency by spawning thousands of independent AI conversation processes.

  Each conversation runs in its own lightweight process (actor), showcasing
  the power of the BEAM VM's actor model for concurrent operations.
  """

  alias ConcurrentAiChat.Conversation

  @doc """
  Starts a new AI conversation.

  Returns `{:ok, conversation_id}` on success.

  ## Examples

      iex> ConcurrentAiChat.start_conversation()
      {:ok, "conv-123-456"}

      iex> ConcurrentAiChat.start_conversation(model: "gpt-4")
      {:ok, "conv-789-012"}
  """
  def start_conversation(opts \\ []) do
    id = Keyword.get(opts, :id, generate_id())

    child_spec = %{
      id: {Conversation, id},
      start: {Conversation, :start_link, [[{:id, id} | opts]]},
      restart: :temporary
    }

    case DynamicSupervisor.start_child(ConcurrentAiChat.ChatSupervisor, child_spec) do
      {:ok, _pid} -> {:ok, id}
      {:error, {:already_started, _pid}} -> {:error, :already_exists}
      error -> error
    end
  end

  @doc """
  Starts multiple concurrent conversations.

  Returns a list of conversation IDs.

  ## Examples

      iex> ConcurrentAiChat.start_conversations(100)
      {:ok, ["conv-1", "conv-2", ...]}
  """
  def start_conversations(count) when is_integer(count) and count > 0 do
    tasks =
      1..count
      |> Enum.map(fn _ ->
        Task.async(fn -> start_conversation() end)
      end)

    results = Task.await_many(tasks, 30_000)

    conversation_ids =
      results
      |> Enum.filter(&match?({:ok, _}, &1))
      |> Enum.map(fn {:ok, id} -> id end)

    {:ok, conversation_ids}
  end

  @doc """
  Sends a message to a conversation.
  """
  def send_message(conversation_id, message) do
    Conversation.send_message(conversation_id, message)
  end

  @doc """
  Broadcasts a message to multiple conversations concurrently.
  """
  def broadcast_message(conversation_ids, message) do
    tasks =
      conversation_ids
      |> Enum.map(fn id ->
        Task.async(fn ->
          {id, Conversation.send_message(id, message)}
        end)
      end)

    Task.await_many(tasks, 60_000)
  end

  @doc """
  Gets the history of a conversation.
  """
  def get_history(conversation_id) do
    Conversation.get_history(conversation_id)
  end

  @doc """
  Gets stats for a conversation.
  """
  def get_stats(conversation_id) do
    Conversation.get_stats(conversation_id)
  end

  @doc """
  Lists all active conversations.
  """
  def list_conversations do
    Registry.select(ConcurrentAiChat.ConversationRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  @doc """
  Returns the count of active conversations.
  """
  def conversation_count do
    Registry.count(ConcurrentAiChat.ConversationRegistry)
  end

  ## Private Functions

  defp generate_id do
    "conv-#{System.unique_integer([:positive])}-#{:rand.uniform(999_999)}"
  end
end
