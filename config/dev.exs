import Config

# Configure Ecto Repo
config :instruktor, Instruktor.Repo,
  database: "instruktor_dev",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Configure Oban for development
config :instruktor, Oban,
  queues: [
    web_automation: 1,
    llm_processing: 2,
    data_extraction: 2
  ],
  testing: :inline

# Enable debugging for web automation in development
config :instruktor, :web_automation,
  headless: false,  # Show browser for development
  screenshots_dir: "priv/screenshots",
  debug: true 