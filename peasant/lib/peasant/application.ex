defmodule Peasant.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PeasantWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Peasant.PubSub},

      # Application Registry
      {Registry, keys: :unique, name: Peasant.Registry},

      # Toolbox dynamic supervisor
      Peasant.Toolbox,

      # ActivityMaster: automations supervisor
      Peasant.ActivityMaster,

      # Storage Repo
      Peasant.Storage.Keeper,

      # Storage Observer
      Peasant.Storage.Observer,

      # Start the Endpoint (http/https)
      PeasantWeb.Endpoint
      # Start a worker by calling: Peasant.Worker.start_link(arg)
      # {Peasant.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Peasant.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PeasantWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
