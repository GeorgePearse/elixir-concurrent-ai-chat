# Concurrent AI Chat

> Massively concurrent AI chat experiment using Elixir's actor model

## Concept

This project demonstrates Elixir's capability to handle massive concurrency by managing thousands of independent AI conversation processes simultaneously. Each conversation runs in its own lightweight process (actor), showcasing the power of the BEAM VM's concurrency model.

### Why Elixir?

- **Lightweight Processes**: BEAM VM processes are extremely lightweight (~2KB initial memory)
- **Isolation**: Each conversation is isolated - if one crashes, others continue running
- **Scalability**: Can handle millions of concurrent processes on a single machine
- **Fault Tolerance**: Built-in supervision trees automatically restart failed conversations
- **Distribution**: Easy to scale across multiple nodes/machines

## Architecture

```
Application
├── ConversationRegistry (Registry)
├── ChatSupervisor (DynamicSupervisor)
    └── Conversation (GenServer) × N
        ├── Message History
        ├── AI Model State
        └── Conversation Metadata
```

### Key Components

- **Application**: Starts the supervision tree and registry
- **ConversationRegistry**: Tracks all active conversations by ID
- **ChatSupervisor**: Dynamically supervises conversation processes
- **Conversation**: GenServer managing individual chat state and AI interactions

## Installation

1. Install Elixir (if not already installed):
   ```bash
   brew install elixir  # macOS
   # or visit https://elixir-lang.org/install.html
   ```

2. Install dependencies:
   ```bash
   mix deps.get
   ```

3. Set up your AI API key (e.g., OpenAI):
   ```bash
   export OPENAI_API_KEY="your-api-key"
   ```

## Usage

### Interactive Shell

Start the application in interactive mode:

```bash
iex -S mix
```

### Basic Examples

```elixir
# Start a single conversation
{:ok, conv_id} = ConcurrentAiChat.start_conversation()

# Send a message
{:ok, response} = ConcurrentAiChat.send_message(conv_id, "Hello!")

# Get conversation history
history = ConcurrentAiChat.get_history(conv_id)

# Get conversation stats
stats = ConcurrentAiChat.get_stats(conv_id)
```

### Concurrent Operations

```elixir
# Start 1,000 concurrent conversations
{:ok, conversation_ids} = ConcurrentAiChat.start_conversations(1000)

# Broadcast a message to all conversations concurrently
results = ConcurrentAiChat.broadcast_message(
  conversation_ids,
  "What's the meaning of life?"
)

# Check active conversation count
count = ConcurrentAiChat.conversation_count()
```

### Stress Testing

```elixir
# Start 10,000 conversations
{:ok, ids} = ConcurrentAiChat.start_conversations(10_000)

# Send messages concurrently to all of them
ConcurrentAiChat.broadcast_message(ids, "Tell me a joke")

# Monitor system with :observer
:observer.start()
```

## Experiments to Try

1. **Scalability Test**: How many concurrent conversations can your system handle?
2. **Message Throughput**: Broadcast messages to thousands of conversations and measure latency
3. **Fault Tolerance**: Kill random conversation processes and observe supervisor recovery
4. **Distribution**: Run conversations across multiple nodes
5. **Different AI Models**: Compare performance with different model backends

## TODO

- [ ] Integrate with actual AI API (OpenAI, Anthropic, etc.)
- [ ] Add conversation persistence (database)
- [ ] Implement conversation cleanup/timeout
- [ ] Add metrics and observability (Telemetry)
- [ ] Create web interface (Phoenix LiveView)
- [ ] Add conversation pools for different AI models
- [ ] Implement conversation routing and load balancing
- [ ] Add support for streaming responses
- [ ] Create benchmarking suite
- [ ] Multi-node deployment example

## Performance Characteristics

With the BEAM VM, you can expect:

- **Process creation**: ~1-2 microseconds per process
- **Memory per conversation**: ~2-10 KB initial (grows with message history)
- **Theoretical limit**: Millions of concurrent conversations
- **Practical limit**: Depends on your hardware and AI API rate limits

## Development

```bash
# Run tests
mix test

# Format code
mix format

# Start with console
iex -S mix

# Build release
mix release
```

## License

MIT

## Contributing

This is an experimental project for exploring Elixir's concurrency model. Contributions and ideas welcome!
