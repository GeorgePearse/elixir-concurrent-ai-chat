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

## Frontend Options for Elixir/Phoenix

When building a web interface for this concurrent chat system, consider these approaches ranked by synergy with Elixir:

### 1. Phoenix LiveView (Native Solution) - 95% Synergy

**The "No JavaScript" Approach** - Best integration with Elixir's concurrency model

```elixir
defmodule ConcurrentAiChatWeb.DashboardLive do
  use ConcurrentAiChatWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, conversations: [], count: 0)}
  end

  def render(assigns) do
    ~H"""
    <div class="dashboard">
      <!-- Reactive UI without writing JavaScript -->
      <button phx-click="start_conversations" phx-value-count="100">
        Start 100 Conversations
      </button>
      <p>Active: <%= @count %></p>

      <!-- Real-time conversation updates -->
      <%= for conv <- @conversations do %>
        <div class="conversation-card">
          <h3><%= conv.id %></h3>
          <span class={"status-#{conv.status}"}>●</span>

          <!-- Send message to specific conversation -->
          <form phx-submit="send_message" phx-value-conv-id={conv.id}>
            <input type="text" name="message" placeholder="Send message..." />
            <button>Send</button>
          </form>

          <!-- Live message history -->
          <div class="messages">
            <%= for msg <- conv.messages do %>
              <div class={"message-#{msg.role}"}>
                <%= msg.content %>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- Broadcast to all conversations -->
      <.form for={@broadcast_form} phx-submit="broadcast">
        <.input field={@broadcast_form[:message]}
                type="text"
                placeholder="Broadcast to all..." />
        <.button>Broadcast to <%= @count %> conversations</.button>
      </.form>
    </div>
    """
  end

  # Server handles all interactions
  def handle_event("start_conversations", %{"count" => count}, socket) do
    count = String.to_integer(count)
    {:ok, conv_ids} = ConcurrentAiChat.start_conversations(count)

    # Subscribe to conversation updates
    Enum.each(conv_ids, &Phoenix.PubSub.subscribe(MyApp.PubSub, "conversation:#{&1}"))

    {:noreply, socket
     |> update(:conversations, fn convs -> convs ++ load_conversations(conv_ids) end)
     |> assign(:count, socket.assigns.count + count)}
  end

  def handle_event("send_message", %{"conv-id" => id, "message" => msg}, socket) do
    # This happens concurrently - no blocking
    Task.async(fn -> ConcurrentAiChat.send_message(id, msg) end)
    {:noreply, socket}
  end

  def handle_event("broadcast", %{"message" => message}, socket) do
    # Broadcast to thousands concurrently
    conv_ids = Enum.map(socket.assigns.conversations, & &1.id)

    # Non-blocking concurrent broadcast
    Task.async(fn ->
      ConcurrentAiChat.broadcast_message(conv_ids, message)
    end)

    {:noreply, put_flash(socket, :info, "Broadcasting to #{length(conv_ids)} conversations")}
  end

  # Real-time updates from conversations
  def handle_info({:conversation_update, conv_id, new_message}, socket) do
    conversations = update_conversation(socket.assigns.conversations, conv_id, new_message)
    {:noreply, assign(socket, conversations: conversations)}
  end
end
```

**Why LiveView is Perfect:**

- ✅ **Zero API endpoints needed** - Direct function calls to your GenServers
- ✅ **No state synchronization issues** - Server is the source of truth
- ✅ **Sub-millisecond latency** - WebSocket connection with delta updates
- ✅ **Perfect for real-time** - Native PubSub integration
- ✅ **SEO friendly** - Server-rendered HTML
- ✅ **Tiny JavaScript payload** - ~30KB total
- ✅ **Leverages Elixir concurrency** - Each LiveView is a process
- ✅ **Fault tolerant** - LiveView crashes are handled gracefully

**Ideal for:**
- Admin dashboards
- Real-time monitoring
- Chat interfaces
- Analytics dashboards
- Any app where UX trumps complex animations

### 2. Alpine.js + LiveView - 90% Synergy

**Sprinkle JavaScript where needed** - Best of both worlds

```heex
<!-- Mix LiveView reactivity with Alpine local state -->
<div x-data="{
  selectedConv: null,
  showSettings: false,
  expandedMessages: new Set()
}" phx-hook="ConversationManager">

  <!-- Alpine handles UI state -->
  <button @click="showSettings = !showSettings">
    Settings
  </button>

  <div x-show="showSettings"
       x-transition:enter="transition ease-out duration-200"
       x-transition:leave="transition ease-in duration-150">
    <!-- LiveView still manages the data -->
    <.form for={@settings_form} phx-change="update_settings">
      <.input field={@settings_form[:model]} type="select" options={@available_models} />
      <.input field={@settings_form[:temperature]} type="range" min="0" max="1" step="0.1" />
    </.form>
  </div>

  <!-- Conversation list with Alpine interactions -->
  <div class="conversation-grid">
    <%= for conv <- @conversations do %>
      <div class="conversation-card"
           :class="selectedConv === '<%= conv.id %>' ? 'selected' : ''"
           @click="selectedConv = '<%= conv.id %>'">

        <!-- LiveView reactive data -->
        <div class="header">
          <span><%= conv.id %></span>
          <span class={"status-#{conv.status}"}
                x-data="{ pulse: true }"
                x-init="setInterval(() => pulse = !pulse, 1000)">
            <span :class="pulse ? 'scale-110' : ''">●</span>
          </span>
        </div>

        <!-- Expandable messages with Alpine -->
        <%= for {msg, idx} <- Enum.with_index(conv.messages) do %>
          <div class="message"
               x-data="{ expanded: false }"
               @click.stop="expanded = !expanded">
            <div class="message-preview" x-show="!expanded">
              <%= String.slice(msg.content, 0, 50) %>...
            </div>
            <div class="message-full" x-show="expanded" x-transition>
              <%= msg.content %>
            </div>
          </div>
        <% end %>

        <!-- Quick actions with Alpine -->
        <div class="actions" @click.stop>
          <button phx-click="duplicate_conversation"
                  phx-value-id={conv.id}
                  @click="$dispatch('conversation-duplicated')">
            Duplicate
          </button>
        </div>
      </div>
    <% end %>
  </div>
</div>

<script>
// Minimal JS for enhanced UX
window.Hooks = window.Hooks || {}

Hooks.ConversationManager = {
  mounted() {
    // Listen for LiveView events
    this.handleEvent("conversation-added", ({id}) => {
      // Scroll to new conversation with smooth animation
      this.el.querySelector(`[data-conv-id="${id}"]`)?.scrollIntoView({
        behavior: 'smooth',
        block: 'nearest'
      })
    })

    // Keyboard shortcuts
    document.addEventListener('keydown', (e) => {
      if (e.key === 'b' && e.metaKey) {
        this.pushEvent("broadcast-mode-toggle")
      }
    })

    // Optional: Alpine store for cross-component state
    Alpine.store('chat', {
      selectedConversations: new Set(),

      toggleSelect(id) {
        this.selectedConversations.has(id)
          ? this.selectedConversations.delete(id)
          : this.selectedConversations.add(id)
      }
    })
  },

  updated() {
    // Smooth scroll on new messages
    const messages = this.el.querySelectorAll('.message:last-child')
    messages.forEach(msg => {
      if (msg.dataset.new === 'true') {
        msg.scrollIntoView({ behavior: 'smooth' })
      }
    })
  }
}
</script>
```

**Perfect for:**
- ✅ Animations and transitions
- ✅ Complex UI interactions (drag-drop, resize)
- ✅ Dropdown menus, modals, tooltips
- ✅ Client-side filtering/sorting
- ✅ Keyboard shortcuts
- ✅ Maintaining LiveView benefits with JS enhancements

### 3. React/Vue/Svelte SPA + Phoenix JSON API - 70% Synergy

**Traditional approach** - Use when you need heavy client-side logic

```javascript
// React example with concurrent updates
import { useState, useEffect } from 'react'

function ConversationDashboard() {
  const [conversations, setConversations] = useState([])
  const [socket, setSocket] = useState(null)

  useEffect(() => {
    // Phoenix Channels for real-time updates
    const socket = new Socket("/socket")
    socket.connect()

    const channel = socket.channel("conversations:lobby")

    channel.on("conversation_update", ({conv_id, message}) => {
      setConversations(prev =>
        prev.map(c => c.id === conv_id
          ? {...c, messages: [...c.messages, message]}
          : c
        )
      )
    })

    channel.join()
    setSocket(socket)

    return () => socket.disconnect()
  }, [])

  const startConversations = async (count) => {
    const response = await fetch('/api/conversations/batch', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({ count })
    })
    const { conversation_ids } = await response.json()
    // Subscribe to all new conversations
    conversation_ids.forEach(id => {
      socket.channel(`conversation:${id}`).join()
    })
  }

  const broadcastMessage = async (message) => {
    // This still leverages Elixir's concurrency on the backend
    await fetch('/api/conversations/broadcast', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        conversation_ids: conversations.map(c => c.id),
        message
      })
    })
  }

  return (
    <div className="dashboard">
      <button onClick={() => startConversations(100)}>
        Start 100 Conversations
      </button>

      <button onClick={() => broadcastMessage("Hello all!")}>
        Broadcast to {conversations.length}
      </button>

      {/* Heavy client-side rendering */}
      <VirtualList items={conversations} renderItem={ConversationCard} />
    </div>
  )
}
```

**Backend API (Phoenix):**

```elixir
defmodule ConcurrentAiChatWeb.ConversationController do
  use ConcurrentAiChatWeb, :controller

  def create_batch(conn, %{"count" => count}) do
    {:ok, conversation_ids} = ConcurrentAiChat.start_conversations(count)

    # Still leveraging Elixir concurrency
    json(conn, %{conversation_ids: conversation_ids})
  end

  def broadcast(conn, %{"conversation_ids" => ids, "message" => message}) do
    # Elixir handles concurrency - React just triggers it
    Task.async(fn ->
      ConcurrentAiChat.broadcast_message(ids, message)
    end)

    json(conn, %{status: "broadcasting"})
  end
end
```

**Use when:**
- ⚠️ You need complex animations (Framer Motion, etc.)
- ⚠️ Heavy client-side data manipulation
- ⚠️ Reusing existing React component library
- ⚠️ Team expertise is heavily JS-focused

**Trade-offs:**
- ❌ More code to maintain (frontend + backend)
- ❌ State synchronization complexity
- ❌ Larger bundle sizes
- ❌ Need to implement your own real-time updates
- ✅ Still benefits from Elixir's concurrent backend

### 4. Phoenix + HTMX - 85% Synergy

**The "HTML Over The Wire" approach** - Minimal JavaScript

```html
<!-- Backend renders HTML fragments -->
<div id="conversations" hx-get="/conversations" hx-trigger="every 2s">
  <!-- Server-rendered conversation list -->
</div>

<!-- Start conversations -->
<form hx-post="/conversations/batch"
      hx-vals='{"count": 100}'
      hx-target="#conversations"
      hx-swap="beforeend">
  <button>Start 100 Conversations</button>
</form>

<!-- Broadcast form -->
<form hx-post="/conversations/broadcast"
      hx-include="[name='conversation_ids']">
  <input type="text" name="message" />
  <button>Broadcast to All</button>
</form>

<!-- Each conversation card -->
<div class="conversation" hx-get="/conversations/{id}" hx-trigger="revealed">
  <!-- Lazy loaded when scrolled into view -->
</div>
```

**Backend:**

```elixir
def batch_create(conn, %{"count" => count}) do
  {:ok, conv_ids} = ConcurrentAiChat.start_conversations(count)

  # Return HTML fragment, not JSON
  render(conn, "conversation_cards.html", conversations: load_conversations(conv_ids))
end
```

**Benefits:**
- ✅ Simple mental model
- ✅ Server renders everything
- ✅ Progressive enhancement
- ✅ Works without JavaScript
- ⚠️ Less dynamic than LiveView
- ⚠️ Polling instead of WebSocket (but can combine with Phoenix Channels)

### Recommendation

**For this concurrent AI chat project, use Phoenix LiveView (#1)** because:

1. **Perfect match**: Each LiveView is a process, just like each conversation
2. **Real-time native**: Built-in PubSub for conversation updates
3. **No impedance mismatch**: Direct access to GenServers
4. **Observability**: Can use LiveView to visualize 10,000+ concurrent conversations
5. **Less code**: No need to maintain API contracts

**Add Alpine.js (#2)** later if you need:
- Complex animations
- Client-side interactions (drag-drop, resizing panels)
- Keyboard shortcuts

**Avoid SPA frameworks (#3)** unless:
- You're building a mobile app (React Native)
- You need offline-first functionality
- Your team has zero Elixir frontend experience

The beauty of this architecture: **Elixir processes handle AI conversations, LiveView processes handle user sessions** - it's processes all the way down!

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
