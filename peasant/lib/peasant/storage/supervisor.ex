defmodule Peasant.Storage.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_arg) do
    Supervisor.init(
      children(),
      strategy: :one_for_one
    )
  end

  def children,
    do: [
      # Cachex collection store
      %{
        id: Peasant.Tools,
        start: {Cachex, :start_link, [:tools, []]}
      },
      %{
        id: Peasant.Automations,
        start: {Cachex, :start_link, [:automations, []]}
      },
      %{
        id: Peasant.ToolTypeToAutomations,
        start: {Cachex, :start_link, [:tta, []]}
      },
      %{
        id: Peasant.AutomationToTools,
        start: {Cachex, :start_link, [:att, []]}
      },

      # Storage Adapter
      Peasant.Storage.Keeper,

      # Storage Observer
      Peasant.Storage.Observer
    ]
end
