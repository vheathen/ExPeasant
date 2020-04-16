defmodule Panel.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    cubdb = Application.get_env(:panel, :paneldb, "data/paneldb")

    # List all child processes to be supervised
    children = [
      # Start CubDB
      %{
        id: CubDB,
        start: {CubDB, :start_link, [cubdb]}
      },

      # Start the endpoint when the application starts
      PanelWeb.Endpoint
      # Starts a worker by calling: Panel.Worker.start_link(arg)
      # {Panel.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Panel.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PanelWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
