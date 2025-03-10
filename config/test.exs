import Config

# Configure Oban for testing (disabled)
config :instruktor, Oban,
  queues: false,
  plugins: false

# Configure Ecto Repo for tests
config :instruktor, Instruktor.Repo,
  database: "instruktor_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# Configure web automation for testing
config :instruktor, :web_automation,
  headless: true,  # Always headless in tests
  mock_mode: true, # Use mock responses in tests
  timeout: 5_000   # Shorter timeouts for tests 