defmodule ConcurrentAiChat.Conversation do
  @moduledoc """
  A GenServer representing a single AI conversation.

  Each conversation runs in its own lightweight process, allowing for
  massive concurrency. Conversations maintain their own state and message
  history independently.
  """
  use GenServer
  require Logger

  defstruct [:id, :messages, :model, :created_at, :last_active]

  ## Client API

  @doc """
  Starts a new conversation process.
  """
  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    GenServer.start_link(__MODULE__, opts, name: via_tuple(id))
  end

  @doc """
  Sends a message to the AI in this conversation.
  """
  def send_message(conversation_id, message) do
    GenServer.call(via_tuple(conversation_id), {:send_message, message})
  end

  @doc """
  Gets the conversation history.
  """
  def get_history(conversation_id) do
    GenServer.call(via_tuple(conversation_id), :get_history)
  end

  @doc """
  Gets conversation stats.
  """
  def get_stats(conversation_id) do
    GenServer.call(via_tuple(conversation_id), :get_stats)
  end

  ## Server Callbacks

  @impl true
  def init(opts) do
    id = Keyword.fetch!(opts, :id)
    model = Keyword.get(opts, :model, "gpt-3.5-turbo")

    state = %__MODULE__{
      id: id,
      messages: [],
      model: model,
      created_at: DateTime.utc_now(),
      last_active: DateTime.utc_now()
    }

    Logger.info("Started conversation #{id}")
    {:ok, state}
  end

  @impl true
  def handle_call({:send_message, user_message}, _from, state) do
    # Add user message to history
    messages = state.messages ++ [%{role: "user", content: user_message}]

    # TODO: Make actual API call to AI service
    # For now, simulate with a simple response
    ai_response = simulate_ai_response(user_message, state.id)

    updated_messages = messages ++ [%{role: "assistant", content: ai_response}]

    new_state = %{state |
      messages: updated_messages,
      last_active: DateTime.utc_now()
    }

    {:reply, {:ok, ai_response}, new_state}
  end

  @impl true
  def handle_call(:get_history, _from, state) do
    {:reply, state.messages, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      id: state.id,
      message_count: length(state.messages),
      created_at: state.created_at,
      last_active: state.last_active,
      model: state.model
    }
    {:reply, stats, state}
  end

  ## Private Functions

  defp via_tuple(id) do
    {:via, Registry, {ConcurrentAiChat.ConversationRegistry, id}}
  end

  defp simulate_ai_response(message, conversation_id) do
    # Simulate processing time
    Process.sleep(:rand.uniform(100))

    "Response from conversation #{conversation_id}: You said '#{message}'"
  end
end
