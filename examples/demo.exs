# Demo Script for Concurrent AI Chat with OpenRouter
#
# Usage:
#   1. Set your OpenRouter API key:
#      export OPENROUTER_API_KEY="sk-or-v1-..."
#
#   2. Run this script:
#      elixir examples/demo.exs
#
#   Or from IEx:
#      iex -S mix
#      Code.eval_file("examples/demo.exs")

require Logger

IO.puts """
================================================================================
  Elixir Concurrent AI Chat - OpenRouter Demo
================================================================================
"""

# Check if API key is set
api_key = System.get_env("OPENROUTER_API_KEY")

if !api_key || String.starts_with?(api_key, "sk-or-") == false do
  IO.puts """
  ⚠️  ERROR: OPENROUTER_API_KEY not set or invalid!

  Please set your OpenRouter API key:
    export OPENROUTER_API_KEY="sk-or-v1-your-key-here"

  Get your API key at: https://openrouter.ai/keys
  """
  System.halt(1)
end

IO.puts "✅ API key found: #{String.slice(api_key, 0, 15)}...\n"

# Demo 1: Single Conversation
IO.puts """
Demo 1: Single Conversation
----------------------------
Starting a conversation and sending a message...
"""

{:ok, conv_id} = ConcurrentAiChat.start_conversation()
IO.puts "Started conversation: #{conv_id}"

case ConcurrentAiChat.send_message(conv_id, "Hello! What's 2+2?") do
  {:ok, response} ->
    IO.puts "\n📩 User: Hello! What's 2+2?"
    IO.puts "🤖 AI: #{response}\n"

  {:error, reason} ->
    IO.puts "❌ Error: #{inspect(reason)}\n"
end

# Demo 2: Conversation with history
IO.puts """
Demo 2: Multi-turn Conversation
--------------------------------
Having a multi-turn conversation...
"""

{:ok, response2} = ConcurrentAiChat.send_message(conv_id, "And what's 2+3?")
IO.puts "📩 User: And what's 2+3?"
IO.puts "🤖 AI: #{response2}\n"

history = ConcurrentAiChat.get_history(conv_id)
IO.puts "Conversation history has #{length(history)} messages\n"

# Demo 3: Multiple Concurrent Conversations
IO.puts """
Demo 3: Concurrent Conversations
---------------------------------
Starting 5 conversations and messaging them all concurrently...
"""

{:ok, conv_ids} = ConcurrentAiChat.start_conversations(5)
IO.puts "Started #{length(conv_ids)} conversations"

questions = [
  "What is the capital of France?",
  "What is 10 factorial?",
  "What is the speed of light?",
  "What is the largest planet?",
  "What is the meaning of life?"
]

# Send different questions to each conversation concurrently
results = conv_ids
  |> Enum.zip(questions)
  |> Enum.map(fn {id, question} ->
    Task.async(fn ->
      {question, ConcurrentAiChat.send_message(id, question)}
    end)
  end)
  |> Task.await_many(60_000)

IO.puts "\nResults:"
Enum.each(results, fn {question, result} ->
  case result do
    {:ok, response} ->
      IO.puts "\n📩 Q: #{question}"
      IO.puts "🤖 A: #{String.slice(response, 0, 100)}#{if String.length(response) > 100, do: "...", else: ""}"

    {:error, reason} ->
      IO.puts "\n📩 Q: #{question}"
      IO.puts "❌ Error: #{inspect(reason)}"
  end
end)

# Demo 4: Broadcasting
IO.puts """

Demo 4: Broadcasting
--------------------
Broadcasting the same message to all conversations...
"""

broadcast_results = ConcurrentAiChat.broadcast_message(
  conv_ids,
  "In one word, what is your favorite color?"
)

IO.puts "\nBroadcast results:"
Enum.each(broadcast_results, fn {id, result} ->
  case result do
    {:ok, response} ->
      IO.puts "  #{id}: #{response}"

    {:error, reason} ->
      IO.puts "  #{id}: Error - #{inspect(reason)}"
  end
end)

# Show stats
IO.puts """

================================================================================
  Statistics
================================================================================
"""

total_active = ConcurrentAiChat.conversation_count()
IO.puts "Total active conversations: #{total_active}"

all_conversations = ConcurrentAiChat.list_conversations()
IO.puts "\nActive conversation IDs:"
Enum.each(all_conversations, fn id ->
  stats = ConcurrentAiChat.get_stats(id)
  IO.puts "  • #{id} - #{stats.message_count} messages (#{stats.model})"
end)

IO.puts """

✅ Demo complete!

Try these commands in IEx:
  # Start more conversations
  {:ok, ids} = ConcurrentAiChat.start_conversations(100)

  # Broadcast to all
  ConcurrentAiChat.broadcast_message(ids, "Hello everyone!")

  # Monitor with Observer
  :observer.start()
"""
