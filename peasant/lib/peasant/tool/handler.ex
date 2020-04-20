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

  def init(args) do
    {:ok, args}
  end
end
