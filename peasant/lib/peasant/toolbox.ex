defmodule Peasant.Toolbox do
  @moduledoc """
  A supervisor for tools handlers
  """

  use DynamicSupervisor

  def start_link(init_arg),
    do: DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

  @impl true
  def init(_init_arg), do: DynamicSupervisor.init(strategy: :one_for_one)

  def add(tool_handler_spec),
    do: DynamicSupervisor.start_child(__MODULE__, tool_handler_spec)
end
