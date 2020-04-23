defmodule Peasant.Tool.Handler do
  @moduledoc false

  use GenServer

  import Peasant.Helper

  alias Peasant.Tool.Event

  @domain "tools"

  ###
  # Internal Public API
  #

  def start_link(%{uuid: tool_uuid} = tool),
    do: GenServer.start_link(__MODULE__, tool, name: via_tuple(tool_uuid))

  def register(tool),
    do: __MODULE__ |> handler_child_spec(tool) |> Peasant.Toolbox.add()

  def commit(tool_uuid, action, action_config) do
    case Registry.lookup(Peasant.Registry, tool_uuid) do
      [] -> {:error, :no_tool_exists}
      [{pid, _}] -> GenServer.cast(pid, {:commit, action, action_config})
    end
  end

  ####
  # Implementation

  def init(tool) do
    {:ok, tool, {:continue, :registered}}
  end

  def handle_continue(:registered, %_{} = tool) do
    event = Peasant.Tool.Event.Registered.new(tool_uuid: tool.uuid, details: %{tool: tool})
    notify(event)

    {:noreply, tool}
  end

  def handle_cast({:commit, _action, action_ref}, %{attached: false} = tool) do
    event =
      Event.ActionFailed.new(
        tool_uuid: tool.uuid,
        action_ref: action_ref,
        details: %{error: :tool_must_be_attached}
      )

    notify(event)

    {:noreply, tool}
  end

  def handle_cast({:commit, action, action_ref}, tool) do
    {:ok, tool, events} = action.run(tool, action_ref)

    notify(events)

    {:noreply, tool}
  end

  defp notify(events) when is_list(events), do: Enum.each(events, &notify/1)
  defp notify(event), do: Peasant.broadcast(@domain, event)
end
