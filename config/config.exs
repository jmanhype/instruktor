import Config

# Configure LLM client settings
config :instruktor, :llm,
  url: "http://127.0.0.1:8090",
  model: "qwen2.5-7b-instruct",
  temperature: 0.2,
  max_tokens: 2000

# Configure web automation settings
config :instruktor, :web_automation,
  headless: true,
  timeout: 30_000,
  screenshots: true

# Configure Oban for background jobs
config :instruktor, Oban,
  repo: Instruktor.Repo,
  plugins: [
    Oban.Plugins.Pruner
  ],
  queues: [
    web_automation: 2,
    llm_processing: 3,
    data_extraction: 5
  ]

# Configure Ecto Repo
config :instruktor, Instruktor.Repo,
  database: "instruktor_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Import environment specific config
import_config "#{config_env()}.exs" 