import Config

# OpenRouter API configuration
config :concurrent_ai_chat,
  openrouter_api_key: System.get_env("OPENROUTER_API_KEY"),
  openrouter_base_url: "https://openrouter.ai/api/v1",
  # Using DeepSeek for speed, or use "auto:nitro" for automatic fastest routing
  default_model: "deepseek/deepseek-chat"

# Import environment-specific config
if config_env() == :test do
  import_config "test.exs"
end
