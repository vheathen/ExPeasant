defmodule Peasant.Tool.Handler do
  @moduledoc false

  use GenServer

  import Peasant.Helper

  ###
  # Internal Public API
  #

  def start_link(%{uuid: tool_uuid} = tool),
    do: GenServer.start_link(__MODULE__, tool, name: via_tuple(tool_uuid))

  def register(tool),
    do: __MODULE__ |> handler_child_spec(tool) |> Peasant.Toolbox.add()

  ####
  # Implementation

  def init(tool) do
    {:ok, tool, {:continue, :registered}}
  end

  def handle_continue(:registered, %handler{} = tool) do
    registered = Module.concat(handler, Registered).new(tool)
    Peasant.broadcast("tools", registered)

    {:noreply, tool}
  end
end
