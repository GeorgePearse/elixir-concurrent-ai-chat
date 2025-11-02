defmodule ConcurrentAiChatTest do
  use ExUnit.Case
  doctest ConcurrentAiChat

  setup do
    # Ensure a clean state for each test
    :ok
  end

  # Use mock mode for all tests to avoid API calls
  defp start_mock_conversation(opts \\ []) do
    ConcurrentAiChat.start_conversation([use_mock: true] ++ opts)
  end

  test "can start a conversation" do
    {:ok, conv_id} = start_mock_conversation()
    assert is_binary(conv_id)
    assert String.starts_with?(conv_id, "conv-")
  end

  test "can send a message to a conversation" do
    {:ok, conv_id} = start_mock_conversation()
    {:ok, response} = ConcurrentAiChat.send_message(conv_id, "Hello")

    assert is_binary(response)
    assert response =~ "You said 'Hello'"
  end

  test "maintains conversation history" do
    {:ok, conv_id} = start_mock_conversation()

    ConcurrentAiChat.send_message(conv_id, "First message")
    ConcurrentAiChat.send_message(conv_id, "Second message")

    history = ConcurrentAiChat.get_history(conv_id)
    assert length(history) == 4  # 2 user messages + 2 AI responses
  end

  test "can start multiple concurrent conversations" do
    # Start with mock mode
    mock_ids = Enum.map(1..10, fn _ ->
      {:ok, id} = start_mock_conversation()
      id
    end)

    assert length(mock_ids) == 10
    assert Enum.all?(mock_ids, &String.starts_with?(&1, "conv-"))
  end

  test "can broadcast to multiple conversations" do
    # Create mock conversations
    mock_ids = Enum.map(1..5, fn _ ->
      {:ok, id} = start_mock_conversation()
      id
    end)

    results = ConcurrentAiChat.broadcast_message(mock_ids, "Broadcast test")

    assert length(results) == 5
    assert Enum.all?(results, fn {_id, result} -> match?({:ok, _}, result) end)
  end

  test "tracks conversation count" do
    initial_count = ConcurrentAiChat.conversation_count()

    Enum.each(1..3, fn _ -> start_mock_conversation() end)

    assert ConcurrentAiChat.conversation_count() == initial_count + 3
  end

  test "returns conversation stats" do
    {:ok, conv_id} = start_mock_conversation()
    ConcurrentAiChat.send_message(conv_id, "Test")

    stats = ConcurrentAiChat.get_stats(conv_id)

    assert stats.id == conv_id
    assert stats.message_count == 2  # 1 user + 1 AI
    assert %DateTime{} = stats.created_at
    assert %DateTime{} = stats.last_active
  end
end
