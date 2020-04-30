defmodule Peasant.Collection.Supervisor do
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
        start: {Cachex, :start_link, [Peasant.Tool.domain() |> String.to_atom(), []]}
      },
      %{
        id: Peasant.Automations,
        start: {Cachex, :start_link, [Peasant.Automation.domain() |> String.to_atom(), []]}
      },
      %{
        id: Peasant.ToolTypeToAutomations,
        start: {Cachex, :start_link, [:tta, []]}
      },
      %{
        id: Peasant.AutomationToTools,
        start: {Cachex, :start_link, [:att, []]}
      },

      # Collection Adapter
      Peasant.Collection.Keeper,

      # Tools observer
      Peasant.Collection.Observer.Tools,

      # Tools observer
      Peasant.Collection.Observer.Automations,

      # Collection Observer
      Peasant.Collection.Observer
    ]
end
