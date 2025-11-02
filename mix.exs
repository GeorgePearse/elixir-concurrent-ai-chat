defmodule ConcurrentAiChat.MixProject do
  use Mix.Project

  def project do
    [
      app: :concurrent_ai_chat,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ConcurrentAiChat.Application, []}
    ]
  end

  defp deps do
    [
      {:req, "~> 0.4.0"},
      {:jason, "~> 1.4"}
    ]
  end
end
