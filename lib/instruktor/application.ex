defmodule Instruktor.Application do
  @moduledoc """
  The Instruktor application.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Repo setup (uncomment when DB is configured)
      # Instruktor.Repo,
      
      # Oban setup for background job processing
      {Oban, oban_config()}
      
      # Add other supervisors or workers here
    ]

    opts = [strategy: :one_for_one, name: Instruktor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Conditionally configure Oban based on environment
  defp oban_config do
    Application.get_env(:instruktor, Oban, [])
  end
end 