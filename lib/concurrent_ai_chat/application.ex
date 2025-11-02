defmodule ConcurrentAiChat.Application do
  @moduledoc """
  The ConcurrentAiChat Application.

  Starts the supervision tree for managing massively concurrent AI conversations.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: ConcurrentAiChat.ConversationRegistry},
      {DynamicSupervisor, name: ConcurrentAiChat.ChatSupervisor, strategy: :one_for_one}
    ]

    opts = [strategy: :one_for_one, name: ConcurrentAiChat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
