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
      # Cachex collection store: TODO
      # %{
      #   id: Peasant.Tools,
      #   start: {Cachex, :start_link, [Peasant.Tools, []]}
      # },
      # %{
      #   id: Peasant.Automations,
      #   start: {Cachex, :start_link, [Peasant.Automations, []]}
      # },

      # Storage Adapter
      Peasant.Storage.Keeper,

      # Storage Observer
      Peasant.Storage.Observer
    ]
end
