defmodule Instruktor.MixProject do
  use Mix.Project

  def project do
    [
      app: :instruktor,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      preferred_cli_env: [
        test: :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Instruktor.Application, []}
    ]
  end

  defp deps do
    [
      # Core dependencies
      {:instructor, github: "thmsmlr/instructor_ex"}, # Structured data extraction
      {:ecto, "~> 3.12"},  # For schemas and validations
      {:jason, "~> 1.4"},  # JSON parsing
      {:httpoison, "~> 2.0"},  # HTTP client
      
      # Background job processing
      {:oban, "~> 2.19"},  # Background job processing
      
      # Development and testing
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end 